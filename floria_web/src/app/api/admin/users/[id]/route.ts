import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminAuth, getAdminDb } from "@/lib/server/firebase-admin";
import { extractCity, extractUserAvatar, toIsoString } from "@/lib/server/firestore-utils";
import type { AccountStatus } from "@/types";

function cleanPredictionText(raw: unknown): string {
  let s = String(raw ?? "").trim();
  if (s.includes("___")) {
    s = s.split("___").pop() ?? s;
  }
  return s.replaceAll("_", " ").trim();
}

function normalizeConfidence(raw: unknown): number {
  const n = Number(raw ?? 0);
  if (!Number.isFinite(n) || n <= 0) return 0;
  return n > 1 ? Math.min(1, n / 100) : n;
}

export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    const db = getAdminDb();

    const [userGardensSnap, plantsSnap, scanSnap, ordersSnap, diarySnap] = await Promise.all([
      db.collection("UserGardens").where("userId", "==", id).get(),
      db.collection("MyGarden").where("userId", "==", id).get(),
      db.collection("ScanHistory").where("userId", "==", id).get(),
      db.collection("Orders").where("userId", "==", id).get(),
      db.collection("DiaryNotes").where("userId", "==", id).get(),
    ]);

    const addDaysIso = (baseIso: string, days: number) => {
      const t = Date.parse(baseIso);
      const base = Number.isNaN(t) ? Date.now() : t;
      return new Date(base + Math.max(1, days) * 86400000).toISOString();
    };

    const parsedPlants = plantsSnap.docs.map((doc) => {
      const d = doc.data();
      const createdAt = toIsoString(d.createdAt);
      const waterFrequencyDays = Number(d.waterFrequencyDays ?? 3);
      const lastWatered = toIsoString(d.lastWatered, createdAt);
      const nextWatering = toIsoString(d.nextWatering, addDaysIso(lastWatered, waterFrequencyDays));

      const fertilizeFrequencyDays = Number(d.fertilizeFrequencyDays ?? 20);
      const lastFertilized = toIsoString(d.lastFertilized, createdAt);
      const nextFertilizing = toIsoString(d.nextFertilizing, addDaysIso(lastFertilized, fertilizeFrequencyDays));

      const checkPestFrequencyDays = Number(d.checkPestFrequencyDays ?? 3);
      const lastCleaned = toIsoString(d.lastCleaned, createdAt);
      const nextCheckPest = toIsoString(d.nextCheckPest, addDaysIso(lastCleaned, checkPestFrequencyDays));

      const nowMs = Date.now();
      const TWELVE_HOURS_MS = 12 * 3600 * 1000;
      const isNeedsWater = Date.parse(nextWatering) - nowMs <= TWELVE_HOURS_MS;
      const isNeedsFertilizer =
        fertilizeFrequencyDays > 0 && Date.parse(nextFertilizing) - nowMs <= TWELVE_HOURS_MS;
      const isNeedsClean =
        checkPestFrequencyDays > 0 && Date.parse(nextCheckPest) - nowMs <= TWELVE_HOURS_MS;

      const rawStatus = String(d.healthStatus ?? "Khỏe mạnh").trim();
      const statusTags: string[] = [];
      if (
        rawStatus.startsWith("Bị") ||
        rawStatus === "Cần điều trị" ||
        rawStatus === "Đang phục hồi" ||
        rawStatus === "Cần chú ý"
      ) {
        statusTags.push(rawStatus);
      }
      if (isNeedsWater || rawStatus === "Cần tưới nước") {
        statusTags.push("Cần tưới nước");
      }
      if (isNeedsFertilizer) {
        statusTags.push("Cần bón phân");
      }
      if (isNeedsClean) {
        statusTags.push("Cần kiểm tra");
      }
      if (statusTags.length === 0) {
        statusTags.push("Khỏe mạnh");
      }

      return {
        id: doc.id,
        gardenId: String(d.gardenId ?? ""),
        nameVi: String(d.nameVi ?? "Cây cảnh"),
        scientificName: String(d.scientificName ?? ""),
        nickname: String(d.nickname ?? d.nameVi ?? "Cây của tôi"),
        zone: String(d.zone ?? "Chưa phân khu"),
        imageUrl: typeof d.imageUrl === "string" && d.imageUrl.trim() ? d.imageUrl.trim() : null,
        plantType: String(d.plantType ?? "Cây cảnh"),
        healthStatus: statusTags[0],
        statusTags,
        notes: String(d.notes ?? ""),
        waterFrequencyDays,
        reminderTime: String(d.reminderTime ?? "07:00"),
        lastWatered,
        nextWatering,
        fertilizeFrequencyDays,
        lastFertilized,
        nextFertilizing,
        checkPestFrequencyDays,
        lastCleaned,
        nextCheckPest,
        createdAt,
      };
    });

    const gardensList = userGardensSnap.docs
      .map((doc) => {
        const d = doc.data();
        return {
          id: doc.id,
          name: String(d.name ?? "Khu vườn của tôi"),
          environment: String(d.environment ?? "Trong nhà"),
          lightCondition: String(d.lightCondition ?? "Sáng gián tiếp"),
          createdAt: toIsoString(d.createdAt),
          plants: parsedPlants.filter((p) => p.gardenId === doc.id),
        };
      })
      .sort((a, b) => Date.parse(a.createdAt) - Date.parse(b.createdAt));

    const knownGardenIds = new Set(gardensList.map((g) => g.id));
    const unassignedPlants = parsedPlants.filter((p) => !p.gardenId || !knownGardenIds.has(p.gardenId));
    if (unassignedPlants.length > 0) {
      gardensList.push({
        id: "__default__",
        name: gardensList.length === 0 ? "Khu vườn của tôi" : "Cây chưa gán khu vườn",
        environment: "Tổng hợp",
        lightCondition: "Theo từng vị trí",
        createdAt: unassignedPlants[0]?.createdAt ?? new Date().toISOString(),
        plants: unassignedPlants,
      });
    }

    const speciesMap = new Map<string, number>();
    for (const p of parsedPlants) {
      speciesMap.set(p.nameVi, (speciesMap.get(p.nameVi) ?? 0) + 1);
    }
    const dist = Array.from(speciesMap.entries()).map(([name, count]) => ({ name, count }));

    // Lịch sử AI từ collection ScanHistory
    const recog: Array<{
      id: string;
      species: string;
      rawPrediction: string;
      conf: number;
      modelUsed: string;
      imageUrl: string | null;
      at: string;
    }> = [];

    const diag: Array<{
      id: string;
      disease: string;
      plantName: string;
      severity: string;
      severityVi: string;
      cause: string;
      treatmentSteps: string[];
      conf: number;
      modelUsed: string;
      imageUrl: string | null;
      at: string;
    }> = [];

    for (const doc of scanSnap.docs) {
      const d = doc.data();
      const rawType = String(d.type ?? "");
      const isDisease =
        rawType === "disease_diagnosis" ||
        (!rawType && (d.severity !== undefined || d.treatmentSteps !== undefined || d.plantName !== undefined));
      const labelVi = String(d.predictionVi ?? "").trim();
      const cleanRaw = cleanPredictionText(d.prediction);
      const displayLabel = labelVi || cleanRaw || "Chưa xác định";
      const conf = normalizeConfidence(d.confidence);
      const at = toIsoString(d.timestamp ?? d.createdAt);
      const imageUrl = typeof d.imageUrl === "string" && d.imageUrl.trim() ? d.imageUrl.trim() : null;
      const modelUsed = String(d.modelUsed ?? "");

      if (isDisease) {
        diag.push({
          id: doc.id,
          disease: displayLabel,
          plantName: String(d.plantName ?? ""),
          severity: String(d.severity ?? "warning"),
          severityVi: String(d.severityVi ?? ""),
          cause: String(d.cause ?? ""),
          treatmentSteps: Array.isArray(d.treatmentSteps) ? d.treatmentSteps.map((s) => String(s)) : [],
          conf,
          modelUsed,
          imageUrl,
          at,
        });
      } else {
        recog.push({
          id: doc.id,
          species: displayLabel,
          rawPrediction: cleanRaw,
          conf,
          modelUsed,
          imageUrl,
          at,
        });
      }
    }

    recog.sort((a, b) => Date.parse(b.at) - Date.parse(a.at));
    diag.sort((a, b) => Date.parse(b.at) - Date.parse(a.at));

    // Đơn hàng đầy đủ từ collection Orders
    const orders = ordersSnap.docs
      .map((doc) => {
        const d = doc.data();
        const rawItems = Array.isArray(d.items) ? d.items : [];
        const items = rawItems.map((it) => {
          const m = typeof it === "object" && it !== null ? (it as Record<string, unknown>) : {};
          return {
            productId: String(m.productId ?? ""),
            name: String(m.name ?? "Sản phẩm"),
            imageUrl: String(m.imageUrl ?? ""),
            category: String(m.category ?? "Vật tư"),
            price: Number(m.price ?? 0),
            quantity: Number(m.quantity ?? 1),
          };
        });
        const itemCount = items.reduce((s, it) => s + (it.quantity || 1), 0);

        return {
          id: doc.id,
          code: String(d.orderCode ?? d.code ?? doc.id.slice(0, 8).toUpperCase()),
          total: Number(d.totalAmount ?? d.total ?? 0),
          fulfillment: String(d.status ?? d.fulfillment ?? "pending"),
          createdAt: toIsoString(d.createdAt),
          itemCount: itemCount || items.length,
          items,
          recipientName: String(d.recipientName ?? ""),
          recipientPhone: String(d.recipientPhone ?? ""),
          shippingAddress: String(d.shippingAddress ?? ""),
          addressLabel: String(d.addressLabel ?? "Nhà riêng"),
          paymentMethod: String(d.paymentMethod ?? "cod"),
          paymentLabel: String(d.paymentLabel ?? "Thanh toán khi nhận hàng (COD)"),
          isReviewed: d.isReviewed === true,
          rating: typeof d.rating === "number" ? d.rating : null,
          reviewNote: typeof d.reviewNote === "string" ? d.reviewNote : null,
        };
      })
      .sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt));

    // Dòng thời gian hoạt động thật
    const activities: Array<{
      id: string;
      kind: "scan" | "disease" | "order" | "plant" | "diary";
      title: string;
      description: string;
      at: string;
    }> = [
      ...recog.slice(0, 5).map((r) => ({
        id: `scan_${r.id}`,
        kind: "scan" as const,
        title: "Quét nhận diện cây",
        description: `${r.species} (${(r.conf * 100).toFixed(1)}%)`,
        at: r.at,
      })),
      ...diag.slice(0, 5).map((r) => ({
        id: `diag_${r.id}`,
        kind: "disease" as const,
        title: "Chẩn đoán bệnh lá",
        description: r.plantName ? `${r.plantName}: ${r.disease}` : r.disease,
        at: r.at,
      })),
      ...orders.slice(0, 5).map((o) => ({
        id: `ord_${o.id}`,
        kind: "order" as const,
        title: `Đặt đơn hàng ${o.code}`,
        description: `${o.itemCount} sản phẩm · ${o.paymentLabel}`,
        at: o.createdAt,
      })),
      ...parsedPlants.slice(0, 5).map((p) => ({
        id: `plt_${p.id}`,
        kind: "plant" as const,
        title: "Thêm cây vào vườn",
        description: p.nickname && p.nickname !== p.nameVi ? `${p.nickname} (${p.nameVi})` : p.nameVi,
        at: p.createdAt,
      })),
    ].sort((a, b) => Date.parse(b.at) - Date.parse(a.at));

    return NextResponse.json({
      gardens: gardensList,
      totalPlants: parsedPlants.length,
      dist,
      recog: recog.slice(0, 30),
      diag: diag.slice(0, 30),
      orders: orders.slice(0, 20),
      diaryCount: diarySnap.size,
      activities: activities.slice(0, 12),
    });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const message = err instanceof Error ? err.message : "Không thể tải chi tiết người dùng";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    const body = (await req.json()) as { status?: AccountStatus };
    const nextStatus = body.status;
    if (nextStatus !== "active" && nextStatus !== "locked" && nextStatus !== "pending") {
      return NextResponse.json({ error: "Trạng thái không hợp lệ" }, { status: 400 });
    }

    const db = getAdminDb();
    const auth = getAdminAuth();

    let authUser;
    try {
      authUser = await auth.updateUser(id, { disabled: nextStatus === "locked" });
    } catch {
      // Bỏ qua nếu user chưa tồn tại trong Firebase Auth
    }

    const ref = db.collection("Users").doc(id);
    await ref.set(
      {
        status: nextStatus,
        updatedAt: new Date().toISOString(),
      },
      { merge: true },
    );

    const [updated, gardenSnap, ordersSnap, scanSnap] = await Promise.all([
      ref.get(),
      db.collection("MyGarden").where("userId", "==", id).get(),
      db.collection("Orders").where("userId", "==", id).get(),
      db.collection("ScanHistory").where("userId", "==", id).get(),
    ]);

    const d = updated.data() ?? {};
    let diseaseScans = 0;
    for (const doc of scanSnap.docs) {
      const sd = doc.data();
      const isDisease =
        sd.type === "disease_diagnosis" ||
        (!sd.type && (sd.severity !== undefined || sd.treatmentSteps !== undefined || sd.plantName !== undefined));
      if (isDisease) diseaseScans += 1;
    }

    const providerIds = authUser?.providerData.map((p) => p.providerId) ?? [];
    const provider = providerIds.includes("google.com") ? "google" : "email";

    return NextResponse.json({
      id,
      fullName: String(d.displayName ?? authUser?.displayName ?? "Người dùng Floria"),
      email: String(d.email ?? authUser?.email ?? ""),
      phone: String(d.phone ?? authUser?.phoneNumber ?? ""),
      avatar: extractUserAvatar(d, authUser?.photoURL),
      city: extractCity(d),
      provider,
      registeredAt: toIsoString(d.createdAt, authUser?.metadata.creationTime),
      lastActiveAt: toIsoString(d.updatedAt, authUser?.metadata.lastSignInTime),
      plants: gardenSnap.size,
      scans: scanSnap.size,
      diseaseScans,
      orders: ordersSnap.size,
      status: nextStatus,
    });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const message = err instanceof Error ? err.message : "Không thể cập nhật người dùng";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
