import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminAuth, getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";

const OVERVIEW_CACHE_TTL_MS = 60_000;
const overviewCache = new Map<number, { data: unknown; expiresAt: number }>();

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const url = new URL(req.url);
    const days = Math.min(180, Math.max(7, Number(url.searchParams.get("days")) || 30));

    const cached = overviewCache.get(days);
    if (cached && cached.expiresAt > Date.now()) {
      return NextResponse.json(cached.data);
    }

    const db = getAdminDb();
    const auth = getAdminAuth();
    const [usersSnap, authList, gardenSnap, scanSnap, chatSnap, ordersSnap, plantsSnap, productsSnap, reviewsSnap] =
      await Promise.all([
        db.collection("Users").get(),
        auth.listUsers(1000),
        db.collection("MyGarden").get(),
        db.collection("ScanHistory").get(),
        db.collection("ChatSessions").get(),
        db.collection("Orders").get(),
        db.collection("plants_info").get(),
        db.collection("ShopProducts").get(),
        db.collection("ProductReviews").get(),
      ]);

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const dayBuckets = Array.from({ length: days }, (_, idx) => {
      const d = new Date(today);
      d.setDate(today.getDate() - (days - 1 - idx));
      const key = d.toISOString().slice(0, 10);
      return {
        date: key,
        users: 0,
        newUsers: 0,
        plantScans: 0,
        diseaseScans: 0,
        orders: 0,
        revenue: 0,
        sessions: 0,
      };
    });

    const bucketByDate = new Map(dayBuckets.map((b) => [b.date, b]));

    let cumulativeBaseUsers = 0;
    const firstDateKey = dayBuckets[0]?.date ?? "";
    for (const doc of usersSnap.docs) {
      const iso = toIsoString(doc.data().createdAt, "");
      const key = iso ? iso.slice(0, 10) : "";
      if (!key || key < firstDateKey) {
        cumulativeBaseUsers += 1;
      } else {
        const b = bucketByDate.get(key);
        if (b) {
          b.users += 1;
          b.newUsers += 1;
        }
      }
    }

    let runningUsers = cumulativeBaseUsers;
    for (const b of dayBuckets) {
      runningUsers += b.users;
      b.users = runningUsers;
    }

    let totalRevenue = 0;
    for (const doc of ordersSnap.docs) {
      const d = doc.data();
      const amount = Number(d.totalAmount ?? d.total ?? 0);
      const status = String(d.status ?? d.fulfillment ?? "");
      if (status !== "cancelled") {
        totalRevenue += amount;
      }
      const key = toIsoString(d.createdAt, "").slice(0, 10);
      const b = bucketByDate.get(key);
      if (b) {
        b.orders += 1;
        if (status !== "cancelled") b.revenue += amount;
      }
    }

    let totalPlantScans = 0;
    let totalDiseaseScans = 0;
    let confidentScans = 0;
    const diseaseCountMap = new Map<string, number>();

    for (const doc of scanSnap.docs) {
      const d = doc.data();
      const isDisease =
        d.type === "disease_diagnosis" ||
        (!d.type && (d.severity !== undefined || d.treatmentSteps !== undefined || d.plantName !== undefined));
      if (isDisease) {
        totalDiseaseScans += 1;
        const label = String(d.predictionVi ?? d.prediction ?? "Khác").trim();
        if (label) diseaseCountMap.set(label, (diseaseCountMap.get(label) ?? 0) + 1);
      } else {
        totalPlantScans += 1;
      }

      const rawConf = Number(d.confidence ?? 0);
      const pctConf = rawConf <= 1 ? rawConf * 100 : rawConf;
      if (pctConf >= 50) confidentScans += 1;

      const key = toIsoString(d.timestamp ?? d.createdAt, "").slice(0, 10);
      const b = bucketByDate.get(key);
      if (b) {
        if (isDisease) b.diseaseScans += 1;
        else b.plantScans += 1;
      }
    }

    for (const doc of chatSnap.docs) {
      const d = doc.data();
      const key = toIsoString(d.updatedAt ?? d.createdAt, "").slice(0, 10);
      const b = bucketByDate.get(key);
      if (b) b.sessions += 1;
    }

    const nowMs = Date.now();
    const DAY_MS = 86400 * 1000;
    const activeDau = new Set<string>();
    const activeMau = new Set<string>();
    for (const u of authList.users) {
      const t = Math.max(
        Date.parse(u.metadata.lastRefreshTime ?? "") || 0,
        Date.parse(u.metadata.lastSignInTime ?? "") || 0,
      );
      if (t > 0 && nowMs - t <= DAY_MS) activeDau.add(u.uid);
      if (t > 0 && nowMs - t <= 30 * DAY_MS) activeMau.add(u.uid);
    }

    const topDiseases = Array.from(diseaseCountMap.entries())
      .map(([name, value]) => ({ name, value }))
      .sort((a, b) => b.value - a.value)
      .slice(0, 5);

    const totalScans = totalPlantScans + totalDiseaseScans;
    const scanSuccessRate = totalScans > 0 ? Number(((confidentScans / totalScans) * 100).toFixed(1)) : 0;

    const payload = {
      totals: {
        users: usersSnap.size,
        dau: activeDau.size,
        mau: Math.max(activeMau.size, activeDau.size),
        gardenPlants: gardenSnap.size,
        plantScans: totalPlantScans,
        diseaseScans: totalDiseaseScans,
        scanSuccessRate,
        chatSessions: chatSnap.size,
        orders: ordersSnap.size,
        revenue: totalRevenue,
        catalogPlants: plantsSnap.size,
        products: productsSnap.size,
        reviews: reviewsSnap.size,
      },
      topDiseases,
      series: dayBuckets,
    };
    overviewCache.set(days, { data: payload, expiresAt: Date.now() + OVERVIEW_CACHE_TTL_MS });
    return NextResponse.json(payload);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const message = err instanceof Error ? err.message : "Không thể tải tổng quan hệ thống";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
