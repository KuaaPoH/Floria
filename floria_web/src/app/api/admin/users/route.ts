import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminAuth, getAdminDb } from "@/lib/server/firebase-admin";
import { extractCity, extractUserAvatar, extractUserPhone, toIsoString } from "@/lib/server/firestore-utils";
import { getUsersCache, setUsersCache } from "@/lib/server/users-cache";
import type { AccountStatus, AppUser, AuthProvider } from "@/types";

export const dynamic = "force-dynamic";

function mapProvider(providerIds: string[]): AuthProvider {
  if (providerIds.includes("google.com")) return "google";
  if (providerIds.includes("apple.com")) return "apple";
  if (providerIds.includes("facebook.com")) return "facebook";
  return "email";
}

const NO_STORE_HEADERS = { "Cache-Control": "no-store, max-age=0" };

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const cached = getUsersCache();
    if (cached) {
      return NextResponse.json(cached, { headers: NO_STORE_HEADERS });
    }
    const db = getAdminDb();
    const auth = getAdminAuth();

    const [usersSnap, authList, gardenSnap, ordersSnap, scanSnap] = await Promise.all([
      db.collection("Users").get(),
      auth.listUsers(1000),
      db.collection("MyGarden").get(),
      db.collection("Orders").get(),
      db.collection("ScanHistory").get(),
    ]);

    const plantCountByUser = new Map<string, number>();
    for (const doc of gardenSnap.docs) {
      const uid = String(doc.data().userId ?? "");
      if (uid) plantCountByUser.set(uid, (plantCountByUser.get(uid) ?? 0) + 1);
    }

    const orderCountByUser = new Map<string, number>();
    for (const doc of ordersSnap.docs) {
      const uid = String(doc.data().userId ?? "");
      if (uid) orderCountByUser.set(uid, (orderCountByUser.get(uid) ?? 0) + 1);
    }

    const scanStatsByUser = new Map<string, { total: number; disease: number }>();
    for (const doc of scanSnap.docs) {
      const d = doc.data();
      const uid = String(d.userId ?? "");
      if (!uid) continue;
      const cur = scanStatsByUser.get(uid) ?? { total: 0, disease: 0 };
      cur.total += 1;
      const isDisease =
        d.type === "disease_diagnosis" ||
        (!d.type && (d.severity !== undefined || d.treatmentSteps !== undefined || d.plantName !== undefined));
      if (isDisease) cur.disease += 1;
      scanStatsByUser.set(uid, cur);
    }

    const authByUid = new Map(authList.users.map((u) => [u.uid, u]));
    const users: AppUser[] = [];

    for (const doc of usersSnap.docs) {
      const d = doc.data();
      const uid = typeof d.uid === "string" && d.uid.trim() ? d.uid.trim() : doc.id;
      const authUser = authByUid.get(uid) ?? authByUid.get(doc.id);
      const isDisabled = authUser?.disabled === true || d.status === "locked" || d.isActive === false;
      const status: AccountStatus = isDisabled ? "locked" : d.status === "pending" ? "pending" : "active";

      const providerIds = authUser?.providerData.map((p) => p.providerId) ?? [];
      const registeredAt = toIsoString(d.createdAt, authUser?.metadata.creationTime ?? new Date().toISOString());
      const activeCandidates = [
        d.lastActiveAt ? toIsoString(d.lastActiveAt, "") : "",
        d.updatedAt ? toIsoString(d.updatedAt, "") : "",
        authUser?.metadata.lastSignInTime ? toIsoString(authUser.metadata.lastSignInTime, "") : "",
        authUser?.metadata.lastRefreshTime ? toIsoString(authUser.metadata.lastRefreshTime, "") : "",
      ]
        .map((iso) => (iso ? Date.parse(iso) : 0))
        .filter((t) => Number.isFinite(t) && t > 0);
      const lastActiveAt =
        activeCandidates.length > 0 ? new Date(Math.max(...activeCandidates)).toISOString() : registeredAt;
      const scanStats = scanStatsByUser.get(uid);

      users.push({
        id: uid,
        fullName: String(d.displayName ?? authUser?.displayName ?? "Người dùng Floria"),
        email: String(d.email ?? authUser?.email ?? ""),
        phone: extractUserPhone(d, authUser?.phoneNumber),
        avatar: extractUserAvatar(d, authUser?.photoURL),
        city: extractCity(d),
        provider: mapProvider(providerIds),
        registeredAt,
        lastActiveAt,
        plants: plantCountByUser.get(uid) ?? 0,
        scans: scanStats?.total ?? Number(d.scanCount ?? 0),
        diseaseScans: scanStats?.disease ?? Number(d.diseaseScanCount ?? 0),
        orders: orderCountByUser.get(uid) ?? 0,
        status,
      });
    }

    users.sort((a, b) => Date.parse(b.registeredAt) - Date.parse(a.registeredAt));
    setUsersCache(users);
    return NextResponse.json(users, { headers: NO_STORE_HEADERS });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const message = err instanceof Error ? err.message : "Không thể tải danh sách người dùng";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
