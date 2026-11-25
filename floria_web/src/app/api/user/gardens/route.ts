import { NextResponse } from "next/server";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import { UserAuthError, verifyUserRequest } from "@/lib/server/user-auth";
import { IMG } from "@/mocks/user/images";
import { findPlantInfoOrFallback, slugifySpecies } from "@/mocks/user/plants-info";
import type {
  CareLog,
  CareSchedule,
  CareType,
  DiaryCategory,
  DiaryNote,
  GardenEnvironment,
  HealthStatus,
  LightCondition,
  UserGarden,
  UserPlant,
} from "@/types/user";

const ENV_TO_VI: Record<GardenEnvironment, string> = {
  indoor: "Trong nhà",
  balcony: "Ngoài trời",
  yard: "Văn phòng",
  rooftop: "Nhà kính",
};

const LIGHT_TO_VI: Record<LightCondition, string> = {
  low: "Ánh sáng yếu",
  indirect: "Sáng gián tiếp",
  bright: "Ánh sáng trung bình",
  direct: "Sáng trực tiếp",
};

const DEFAULT_COVER: Record<GardenEnvironment, string> = {
  indoor: IMG.gardens.livingRoom,
  balcony: IMG.gardens.balcony,
  yard: IMG.heroGarden,
  rooftop: IMG.gardens.rooftop,
};

function mapEnvFromFirestore(raw: unknown): GardenEnvironment {
  const s = String(raw ?? "").toLowerCase();
  if (s === "indoor" || s.includes("trong nhà")) return "indoor";
  if (s === "yard" || s.includes("văn phòng") || s.includes("sân vườn")) return "yard";
  if (s === "rooftop" || s.includes("nhà kính") || s.includes("sân thượng")) return "rooftop";
  if (s === "balcony" || s.includes("ngoài trời") || s.includes("ban công")) return "balcony";
  return "indoor";
}

function mapLightFromFirestore(raw: unknown): LightCondition {
  const s = String(raw ?? "").toLowerCase();
  if (s === "low" || s.includes("yếu")) return "low";
  if (s === "direct" || s.includes("trực tiếp")) return "direct";
  if (s === "bright" || s.includes("trung bình") || s.includes("mạnh")) return "bright";
  return "indirect";
}

function mapHealthFromFirestore(raw: unknown): HealthStatus {
  const s = String(raw ?? "").trim().toLowerCase();
  if (s === "sick" || s.startsWith("bị") || s.includes("điều trị") || s.includes("bệnh")) return "sick";
  if (s === "recovering" || s.includes("phục hồi")) return "recovering";
  return "healthy";
}

function healthToFirestore(status: HealthStatus): string {
  if (status === "sick") return "Bị bệnh";
  if (status === "recovering") return "Đang phục hồi";
  return "Khỏe mạnh";
}

function mapDiaryCategory(raw: unknown): DiaryCategory {
  const s = String(raw ?? "").toLowerCase();
  if (s === "health" || s.includes("sức khỏe")) return "health";
  if (s === "growth" || s.includes("phát triển")) return "growth";
  if (s === "care" || s.includes("chăm")) return "care";
  return "general";
}

function parseCareHistory(raw: unknown): CareLog[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((x, i) => {
      if (typeof x === "string") return { id: `log_${i}`, doneAt: toIsoString(x) };
      if (typeof x === "object" && x !== null) {
        const r = x as Record<string, unknown>;
        return {
          id: String(r.id ?? `log_${i}`),
          doneAt: toIsoString(r.doneAt ?? r.timestamp),
          note: typeof r.note === "string" ? r.note : undefined,
        };
      }
      return null;
    })
    .filter((x): x is CareLog => !!x);
}

function buildNextDue(intervalDays: number, preferredTime: string, from = new Date()): Date {
  const next = new Date(from.getTime() + Math.max(1, intervalDays) * 86400000);
  const [h, m] = preferredTime.split(":").map(Number);
  next.setHours(Number.isFinite(h) ? h : 7, Number.isFinite(m) ? m : 0, 0, 0);
  return next;
}

function mapGardenDoc(id: string, d: Record<string, unknown>): UserGarden {
  const env = mapEnvFromFirestore(d.environment);
  return {
    id,
    userId: String(d.userId ?? ""),
    name: String(d.name ?? "Khu vườn của tôi"),
    coverImage: String(d.coverImage ?? "").trim() || DEFAULT_COVER[env],
    environment: env,
    light: mapLightFromFirestore(d.lightCondition ?? d.light),
    description: String(d.description ?? ""),
    createdAt: toIsoString(d.createdAt),
  };
}

function mapPlantDocAndSchedules(
  id: string,
  d: Record<string, unknown>,
  fallbackGardenId: string,
): { plant: UserPlant; schedules: CareSchedule[] } {
  const sci = String(d.scientificName ?? "");
  const nameVi = String(d.nameVi ?? d.nickname ?? "Cây cảnh");
  const info = findPlantInfoOrFallback(sci || nameVi, nameVi, typeof d.imageUrl === "string" ? d.imageUrl : undefined);
  const speciesId = String(d.speciesId ?? slugifySpecies(sci || nameVi)) || info.id;
  const addedAt = toIsoString(d.createdAt ?? d.addedAt);
  const createdMs = Date.parse(addedAt) || Date.now();

  const plant: UserPlant = {
    id,
    userId: String(d.userId ?? ""),
    gardenId: String(d.gardenId ?? "").trim() || fallbackGardenId,
    speciesId,
    nickname: String(d.nickname ?? nameVi ?? info.commonName),
    location: String(d.zone ?? d.location ?? "Phòng khách"),
    image: String(d.imageUrl ?? d.image ?? "").trim() || info.image || IMG.plants.monstera,
    healthStatus: mapHealthFromFirestore(d.healthStatus),
    activeDiseaseId: typeof d.activeDiseaseId === "string" && d.activeDiseaseId ? d.activeDiseaseId : null,
    addedAt,
  };

  const reminderTime = String(d.reminderTime ?? "07:00");
  const rawWater = d.waterFrequencyDays !== undefined ? Number(d.waterFrequencyDays) : undefined;
  const rawFert = d.fertilizeFrequencyDays !== undefined ? Number(d.fertilizeFrequencyDays) : undefined;
  const rawPest = d.checkPestFrequencyDays !== undefined ? Number(d.checkPestFrequencyDays) : undefined;

  const waterDays = rawWater !== undefined && !Number.isNaN(rawWater) && rawWater > 0 ? rawWater : Number(info.wateringDays ?? 5) || 5;
  const fertDays = rawFert !== undefined && !Number.isNaN(rawFert) && rawFert > 0 ? rawFert : Number(info.fertilizingDays ?? 20) || 20;
  const pestDays = rawPest !== undefined && !Number.isNaN(rawPest) && rawPest > 0 ? rawPest : Number(info.inspectionDays ?? 5) || 5;

  const waterEnabled = d.waterEnabled !== false && (rawWater === undefined || rawWater > 0);
  const fertilizeEnabled = d.fertilizeEnabled !== false && (rawFert === undefined || rawFert > 0);
  const inspectionEnabled = d.inspectionEnabled !== false && (rawPest === undefined || rawPest > 0);

  const lastWatered = d.lastWatered ? toIsoString(d.lastWatered) : null;
  const nextWatering = toIsoString(
    d.nextWatering,
    new Date(createdMs + waterDays * 86400000).toISOString(),
  );

  const lastFertilized = d.lastFertilized ? toIsoString(d.lastFertilized) : null;
  const nextFertilizing = toIsoString(
    d.nextFertilizing,
    new Date(createdMs + fertDays * 86400000).toISOString(),
  );

  const lastCleaned = d.lastCleaned ? toIsoString(d.lastCleaned) : null;
  const nextCheckPest = toIsoString(
    d.nextCheckPest,
    new Date(createdMs + pestDays * 86400000).toISOString(),
  );

  const schedules: CareSchedule[] = [
    {
      id: `${id}__watering`,
      plantId: id,
      type: "watering",
      intervalDays: waterDays,
      preferredTime: String(d.wateringTime ?? reminderTime),
      lastDoneAt: lastWatered,
      nextDueAt: nextWatering,
      enabled: waterEnabled,
      history: parseCareHistory(d.waterHistory),
    },
    {
      id: `${id}__fertilizing`,
      plantId: id,
      type: "fertilizing",
      intervalDays: fertDays,
      preferredTime: String(d.fertilizingTime ?? "08:30"),
      lastDoneAt: lastFertilized,
      nextDueAt: nextFertilizing,
      enabled: fertilizeEnabled,
      history: parseCareHistory(d.fertilizeHistory),
    },
    {
      id: `${id}__inspection`,
      plantId: id,
      type: "inspection",
      intervalDays: pestDays,
      preferredTime: String(d.inspectionTime ?? "18:00"),
      lastDoneAt: lastCleaned,
      nextDueAt: nextCheckPest,
      enabled: inspectionEnabled,
      history: parseCareHistory(d.inspectionHistory),
    },
  ];

  return { plant, schedules };
}

function mapDiaryDoc(id: string, plantId: string, d: Record<string, unknown>): DiaryNote {
  const imgs: string[] = [];
  if (Array.isArray(d.imageUrls)) {
    for (const u of d.imageUrls) if (typeof u === "string" && u.trim()) imgs.push(u.trim());
  } else if (Array.isArray(d.images)) {
    for (const u of d.images) if (typeof u === "string" && u.trim()) imgs.push(u.trim());
  }
  if (typeof d.imageUrl === "string" && d.imageUrl.trim() && !imgs.includes(d.imageUrl.trim())) {
    imgs.unshift(d.imageUrl.trim());
  }
  const created = toIsoString(d.timestamp ?? d.createdAt);
  return {
    id,
    plantId,
    userId: String(d.userId ?? ""),
    category: mapDiaryCategory(d.category),
    title: typeof d.title === "string" ? d.title : "",
    content: String(d.content ?? d.title ?? ""),
    images: imgs,
    diagnosisId: typeof d.diagnosisId === "string" ? d.diagnosisId : null,
    createdAt: created,
    updatedAt: toIsoString(d.updatedAt, created),
  };
}

export async function GET(req: Request) {
  try {
    const user = await verifyUserRequest(req);
    const db = getAdminDb();
    const url = new URL(req.url);
    const plantIdFilter = url.searchParams.get("plantId");

    const [gardensSnap, plantsSnap] = await Promise.all([
      db.collection("UserGardens").where("userId", "==", user.uid).get(),
      db.collection("MyGarden").where("userId", "==", user.uid).get(),
    ]);

    const gardens: UserGarden[] = gardensSnap.docs
      .map((doc) => mapGardenDoc(doc.id, doc.data()))
      .sort((a, b) => a.createdAt.localeCompare(b.createdAt));

    // Nếu user đã có cây trong MyGarden (vd từ Flutter App) nhưng chưa có khu vườn nào, tự tạo khu vườn mặc định
    if (gardens.length === 0 && !plantsSnap.empty) {
      const now = new Date().toISOString();
      const defaultRef = await db.collection("UserGardens").add({
        userId: user.uid,
        name: "Khu vườn của tôi",
        environment: "Trong nhà",
        lightCondition: "Sáng gián tiếp",
        coverImage: IMG.gardens.livingRoom,
        description: "Khu vườn đồng bộ từ Floria.",
        createdAt: now,
      });
      gardens.push({
        id: defaultRef.id,
        userId: user.uid,
        name: "Khu vườn của tôi",
        coverImage: IMG.gardens.livingRoom,
        environment: "indoor",
        light: "indirect",
        description: "Khu vườn đồng bộ từ Floria.",
        createdAt: now,
      });
    }

    const fallbackGardenId = gardens[0]?.id ?? "";
    const gardenIdSet = new Set(gardens.map((g) => g.id));

    const plants: UserPlant[] = [];
    const schedules: CareSchedule[] = [];

    for (const doc of plantsSnap.docs) {
      const mapped = mapPlantDocAndSchedules(doc.id, doc.data(), fallbackGardenId);
      if (fallbackGardenId && !gardenIdSet.has(mapped.plant.gardenId)) {
        mapped.plant.gardenId = fallbackGardenId;
      }
      plants.push(mapped.plant);
      schedules.push(...mapped.schedules);
    }
    plants.sort((a, b) => b.addedAt.localeCompare(a.addedAt));

    // Đọc DiaryNotes subcollection cho các cây cần thiết
    const targetPlantIds = plantIdFilter
      ? plants.filter((p) => p.id === plantIdFilter).map((p) => p.id)
      : plants.map((p) => p.id);

    const diarySnaps = await Promise.all(
      targetPlantIds.map(async (pid) => {
        const snap = await db.collection("MyGarden").doc(pid).collection("DiaryNotes").get().catch(() => null);
        return { pid, snap };
      }),
    );

    const diary: DiaryNote[] = [];
    for (const { pid, snap } of diarySnaps) {
      for (const doc of snap?.docs ?? []) {
        diary.push(mapDiaryDoc(doc.id, pid, doc.data()));
      }
    }
    diary.sort((a, b) => b.createdAt.localeCompare(a.createdAt));

    return NextResponse.json({ gardens, plants, schedules, diary });
  } catch (err) {
    if (err instanceof UserAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: (err as Error).message || "Không thể tải dữ liệu khu vườn" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    const user = await verifyUserRequest(req);
    const db = getAdminDb();
    const body = (await req.json()) as Record<string, unknown>;
    const action = String(body.action ?? "");
    const now = new Date();
    const nowIso = now.toISOString();

    if (action === "createGarden") {
      const env = mapEnvFromFirestore(body.environment);
      const light = mapLightFromFirestore(body.light);
      const payload = {
        userId: user.uid,
        name: String(body.name ?? "Khu vườn mới").trim(),
        environment: ENV_TO_VI[env],
        lightCondition: LIGHT_TO_VI[light],
        coverImage: String(body.coverImage ?? "").trim() || DEFAULT_COVER[env],
        description: String(body.description ?? "").trim(),
        createdAt: nowIso,
      };
      const ref = await db.collection("UserGardens").add(payload);
      return NextResponse.json(mapGardenDoc(ref.id, payload), { status: 201 });
    }

    if (action === "updateGarden") {
      const id = String(body.id ?? "");
      const ref = db.collection("UserGardens").doc(id);
      const snap = await ref.get();
      if (!snap.exists || snap.data()?.userId !== user.uid) {
        return NextResponse.json({ error: "Không tìm thấy khu vườn." }, { status: 404 });
      }
      const patch = (body.patch ?? {}) as Record<string, unknown>;
      const update: Record<string, unknown> = { updatedAt: nowIso };
      if (typeof patch.name === "string") update.name = patch.name.trim();
      if (typeof patch.description === "string") update.description = patch.description.trim();
      if (typeof patch.coverImage === "string") update.coverImage = patch.coverImage.trim();
      if (typeof patch.environment === "string") {
        update.environment = ENV_TO_VI[mapEnvFromFirestore(patch.environment)];
      }
      if (typeof patch.light === "string") {
        update.lightCondition = LIGHT_TO_VI[mapLightFromFirestore(patch.light)];
      }
      await ref.set(update, { merge: true });
      return NextResponse.json(mapGardenDoc(id, { ...snap.data(), ...update }));
    }

    if (action === "deleteGarden") {
      const id = String(body.id ?? "");
      const ref = db.collection("UserGardens").doc(id);
      const snap = await ref.get();
      if (!snap.exists || snap.data()?.userId !== user.uid) {
        return NextResponse.json({ error: "Không tìm thấy khu vườn." }, { status: 404 });
      }
      const plantsSnap = await db.collection("MyGarden").where("userId", "==", user.uid).where("gardenId", "==", id).get();
      const batch = db.batch();
      batch.delete(ref);
      for (const pdoc of plantsSnap.docs) {
        batch.delete(pdoc.ref);
      }
      await batch.commit();
      return NextResponse.json({ deleted: true });
    }

    if (action === "addPlant") {
      const gardenId = String(body.gardenId ?? "");
      const gSnap = await db.collection("UserGardens").doc(gardenId).get();
      if (!gSnap.exists || gSnap.data()?.userId !== user.uid) {
        return NextResponse.json({ error: "Không tìm thấy khu vườn." }, { status: 404 });
      }

      const speciesInput = String(body.speciesId ?? "");
      // Tìm thông tin loài từ Firestore plants_info trước
      let speciesInfo = findPlantInfoOrFallback(speciesInput);
      const fsSpeciesSnap = await db.collection("plants_info").get().catch(() => null);
      if (fsSpeciesSnap) {
        const targetSlug = slugifySpecies(speciesInput);
        for (const sdoc of fsSpeciesSnap.docs) {
          const sd = sdoc.data();
          const sci = String(sd.scientific_name ?? sdoc.id);
          if (
            sdoc.id.toLowerCase() === speciesInput.toLowerCase() ||
            slugifySpecies(sci) === targetSlug ||
            slugifySpecies(sdoc.id) === targetSlug
          ) {
            speciesInfo = findPlantInfoOrFallback(sci, String(sd.name_vi ?? ""), String(sd.image ?? sd.imageUrl ?? ""));
            break;
          }
        }
      }

      const waterDays = Math.max(1, Number(body.waterFrequencyDays ?? speciesInfo.wateringDays) || 5);
      const fertDays = Math.max(1, Number(body.fertilizeFrequencyDays ?? speciesInfo.fertilizingDays) || 20);
      const fertEnabled = body.fertilizeEnabled !== false;
      const pestDays = Math.max(1, Number(body.checkPestFrequencyDays ?? speciesInfo.inspectionDays) || 5);
      const nextWater = buildNextDue(waterDays, "07:00", now).toISOString();
      const nextFert = buildNextDue(fertDays, "08:30", now).toISOString();
      const nextPest = buildNextDue(pestDays, "18:00", now).toISOString();

      const rawImg = String(body.image ?? "").trim();
      const resolvedImg =
        rawImg && (!rawImg.startsWith("/") || speciesInfo.image.startsWith("/"))
          ? rawImg
          : speciesInfo.image;

      const healthRaw = String(body.healthStatus ?? "Khỏe mạnh").trim();

      const payload: Record<string, unknown> = {
        userId: user.uid,
        gardenId,
        speciesId: slugifySpecies(speciesInfo.scientificName) || speciesInput,
        nameVi: speciesInfo.commonName,
        scientificName: speciesInfo.scientificName,
        nickname: String(body.nickname ?? speciesInfo.commonName).trim(),
        zone: String(body.location ?? "Phòng khách").trim(),
        imageUrl: resolvedImg,
        plantType: "Cây cảnh",
        waterFrequencyDays: waterDays,
        reminderTime: "07:00",
        wateringTime: "07:00",
        fertilizingTime: "08:30",
        inspectionTime: "18:00",
        lastWatered: nowIso,
        nextWatering: nextWater,
        fertilizeFrequencyDays: fertDays,
        fertilizeEnabled: fertEnabled,
        lastFertilized: nowIso,
        nextFertilizing: nextFert,
        checkPestFrequencyDays: pestDays,
        lastCleaned: nowIso,
        nextCheckPest: nextPest,
        healthStatus: healthRaw || "Khỏe mạnh",
        activeDiseaseId: null,
        notes: String(body.notes ?? "").trim(),
        createdAt: nowIso,
      };
      const ref = await db.collection("MyGarden").add(payload);
      return NextResponse.json(mapPlantDocAndSchedules(ref.id, payload, gardenId).plant, { status: 201 });
    }

    if (action === "updatePlant") {
      const id = String(body.id ?? "");
      const ref = db.collection("MyGarden").doc(id);
      const snap = await ref.get();
      if (!snap.exists || snap.data()?.userId !== user.uid) {
        return NextResponse.json({ error: "Không tìm thấy cây." }, { status: 404 });
      }
      const patch = (body.patch ?? {}) as Record<string, unknown>;
      const update: Record<string, unknown> = { updatedAt: nowIso };
      if (typeof patch.nickname === "string") update.nickname = patch.nickname.trim();
      if (typeof patch.location === "string") update.zone = patch.location.trim();
      if (typeof patch.gardenId === "string") update.gardenId = patch.gardenId.trim();
      if (typeof patch.image === "string") update.imageUrl = patch.image.trim();
      if (typeof patch.healthStatus === "string") {
        update.healthStatus = healthToFirestore(patch.healthStatus as HealthStatus);
      }
      if (patch.activeDiseaseId !== undefined) {
        update.activeDiseaseId = patch.activeDiseaseId;
      }
      await ref.set(update, { merge: true });
      const merged = { ...snap.data(), ...update };
      return NextResponse.json(mapPlantDocAndSchedules(id, merged, String(merged.gardenId ?? "")).plant);
    }

    if (action === "deletePlant") {
      const id = String(body.id ?? "");
      const ref = db.collection("MyGarden").doc(id);
      const snap = await ref.get();
      if (!snap.exists || snap.data()?.userId !== user.uid) {
        return NextResponse.json({ error: "Không tìm thấy cây." }, { status: 404 });
      }
      await ref.delete();
      return NextResponse.json({ deleted: true });
    }

    if (action === "completeSchedule" || action === "updateSchedule" || action === "applySuggestion") {
      let plantId = "";
      let careType: CareType = "watering";
      if (action === "applySuggestion") {
        plantId = String(body.plantId ?? "");
        const sug = (body.suggestion ?? {}) as Record<string, unknown>;
        careType = (sug.careType as CareType) ?? "watering";
      } else {
        const sid = String(body.id ?? "");
        const [pid, ct] = sid.split("__");
        plantId = pid ?? "";
        careType = (ct as CareType) ?? "watering";
      }

      const ref = db.collection("MyGarden").doc(plantId);
      const snap = await ref.get();
      if (!snap.exists || snap.data()?.userId !== user.uid) {
        return NextResponse.json({ error: "Không tìm thấy cây." }, { status: 404 });
      }
      const d = snap.data() ?? {};

      const fieldMap: Record<
        CareType,
        {
          freq: string;
          last: string;
          next: string;
          time: string;
          enabled: string;
          history: string;
          defaultFreq: number;
          defaultTime: string;
          labelVi: string;
        }
      > = {
        watering: {
          freq: "waterFrequencyDays",
          last: "lastWatered",
          next: "nextWatering",
          time: "wateringTime",
          enabled: "waterEnabled",
          history: "waterHistory",
          defaultFreq: 5,
          defaultTime: "07:00",
          labelVi: "Tưới nước",
        },
        fertilizing: {
          freq: "fertilizeFrequencyDays",
          last: "lastFertilized",
          next: "nextFertilizing",
          time: "fertilizingTime",
          enabled: "fertilizeEnabled",
          history: "fertilizeHistory",
          defaultFreq: 20,
          defaultTime: "08:30",
          labelVi: "Bón phân",
        },
        inspection: {
          freq: "checkPestFrequencyDays",
          last: "lastCleaned",
          next: "nextCheckPest",
          time: "inspectionTime",
          enabled: "inspectionEnabled",
          history: "inspectionHistory",
          defaultFreq: 5,
          defaultTime: "18:00",
          labelVi: "Kiểm tra sâu bệnh & lau lá",
        },
      };

      const cfg = fieldMap[careType];
      const update: Record<string, unknown> = { updatedAt: nowIso };
      let intervalDays = Number(d[cfg.freq] ?? cfg.defaultFreq) || cfg.defaultFreq;
      let preferredTime = String(d[cfg.time] ?? d.reminderTime ?? cfg.defaultTime);

      if (action === "completeSchedule") {
        const nextDue = buildNextDue(intervalDays, preferredTime, now).toISOString();
        const prevHist = parseCareHistory(d[cfg.history]);
        update[cfg.last] = nowIso;
        update[cfg.next] = nextDue;
        update[cfg.history] = [{ id: `log_${now.getTime()}`, doneAt: nowIso }, ...prevHist].slice(0, 30);

        // Ghi thêm nhật ký hệ thống giống Flutter App
        await ref.collection("DiaryNotes").add({
          plantId,
          userId: user.uid,
          type: "system",
          category: "care",
          title: `Đã ${cfg.labelVi.toLowerCase()}`,
          content: `Hoàn thành ${cfg.labelVi.toLowerCase()}. Lần tiếp theo dự kiến sau ${intervalDays} ngày.`,
          imageUrls: [],
          tag: cfg.labelVi,
          timestamp: nowIso,
          createdAt: nowIso,
          updatedAt: nowIso,
        });
      } else if (action === "updateSchedule") {
        const patch = (body.patch ?? {}) as Record<string, unknown>;
        if (typeof patch.intervalDays === "number" && patch.intervalDays >= 1) {
          intervalDays = Math.round(patch.intervalDays);
          update[cfg.freq] = intervalDays;
        }
        if (typeof patch.preferredTime === "string" && /^\d{2}:\d{2}$/.test(patch.preferredTime)) {
          preferredTime = patch.preferredTime;
          update[cfg.time] = preferredTime;
          if (careType === "watering") update.reminderTime = preferredTime;
        }
        if (typeof patch.enabled === "boolean") {
          update[cfg.enabled] = patch.enabled;
        }
        const base = d[cfg.last] ? new Date(toIsoString(d[cfg.last])) : now;
        update[cfg.next] = buildNextDue(intervalDays, preferredTime, base).toISOString();
      } else if (action === "applySuggestion") {
        const sug = (body.suggestion ?? {}) as Record<string, unknown>;
        intervalDays = Math.max(1, Math.round(Number(sug.intervalDays ?? intervalDays)));
        preferredTime =
          typeof sug.preferredTime === "string" && /^\d{2}:\d{2}$/.test(sug.preferredTime)
            ? sug.preferredTime
            : preferredTime;
        update[cfg.freq] = intervalDays;
        update[cfg.time] = preferredTime;
        update[cfg.enabled] = true;
        const base = d[cfg.last] ? new Date(toIsoString(d[cfg.last])) : now;
        update[cfg.next] = buildNextDue(intervalDays, preferredTime, base).toISOString();
      }

      await ref.set(update, { merge: true });
      const merged = { ...d, ...update };
      const mapped = mapPlantDocAndSchedules(plantId, merged, String(merged.gardenId ?? ""));
      const targetSchedule = mapped.schedules.find((s) => s.type === careType)!;
      return NextResponse.json(targetSchedule);
    }

    if (action === "createDiary") {
      const plantId = String(body.plantId ?? "");
      const plantRef = db.collection("MyGarden").doc(plantId);
      const plantSnap = await plantRef.get();
      if (!plantSnap.exists || plantSnap.data()?.userId !== user.uid) {
        return NextResponse.json({ error: "Không tìm thấy cây." }, { status: 404 });
      }
      const images = Array.isArray(body.images) ? body.images.map(String).filter(Boolean) : [];
      const cat = mapDiaryCategory(body.category);
      const payload = {
        plantId,
        userId: user.uid,
        type: "user",
        category: cat,
        title: String(body.title ?? "").trim() || String(body.category ?? "general"),
        content: String(body.content ?? "").trim(),
        imageUrl: images[0] ?? null,
        imageUrls: images,
        diagnosisId: typeof body.diagnosisId === "string" ? body.diagnosisId : null,
        timestamp: nowIso,
        createdAt: nowIso,
        updatedAt: nowIso,
      };
      const ref = await plantRef.collection("DiaryNotes").add(payload);
      return NextResponse.json(mapDiaryDoc(ref.id, plantId, payload), { status: 201 });
    }

    if (action === "updateDiary") {
      const id = String(body.id ?? "");
      const patch = (body.patch ?? {}) as Record<string, unknown>;
      // Tìm cây chứa DiaryNote này trong MyGarden của user
      const plantsSnap = await db.collection("MyGarden").where("userId", "==", user.uid).get();
      for (const pdoc of plantsSnap.docs) {
        const noteRef = pdoc.ref.collection("DiaryNotes").doc(id);
        const noteSnap = await noteRef.get();
        if (noteSnap.exists) {
          const update: Record<string, unknown> = { updatedAt: nowIso };
          if (typeof patch.title === "string") update.title = patch.title.trim();
          if (typeof patch.content === "string") update.content = patch.content.trim();
          if (typeof patch.category === "string") update.category = mapDiaryCategory(patch.category);
          if (Array.isArray(patch.images)) {
            const imgs = patch.images.map(String).filter(Boolean);
            update.imageUrls = imgs;
            update.imageUrl = imgs[0] ?? null;
          }
          await noteRef.set(update, { merge: true });
          return NextResponse.json(mapDiaryDoc(id, pdoc.id, { ...noteSnap.data(), ...update }));
        }
      }
      return NextResponse.json({ error: "Không tìm thấy nhật ký." }, { status: 404 });
    }

    if (action === "deleteDiary") {
      const id = String(body.id ?? "");
      const plantsSnap = await db.collection("MyGarden").where("userId", "==", user.uid).get();
      for (const pdoc of plantsSnap.docs) {
        const noteRef = pdoc.ref.collection("DiaryNotes").doc(id);
        const noteSnap = await noteRef.get();
        if (noteSnap.exists) {
          await noteRef.delete();
          return NextResponse.json({ deleted: true });
        }
      }
      return NextResponse.json({ error: "Không tìm thấy nhật ký." }, { status: 404 });
    }

    return NextResponse.json({ error: "Hành động không được hỗ trợ." }, { status: 400 });
  } catch (err) {
    if (err instanceof UserAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: (err as Error).message || "Lỗi xử lý dữ liệu khu vườn" }, { status: 500 });
  }
}
