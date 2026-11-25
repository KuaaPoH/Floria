import { NextResponse } from "next/server";
import { getAdminAuth, getAdminDb, isFirebaseAdminConfigured } from "@/lib/server/firebase-admin";
import { extractUserAvatar, extractUserPhone, toIsoString } from "@/lib/server/firestore-utils";
import type { Address, CartItem, ReminderSettings, User } from "@/types/user";

function mapAddress(uid: string, raw: unknown, index: number): Address | null {
  if (!raw || typeof raw !== "object") return null;
  const a = raw as Record<string, unknown>;
  const fullAddr = String(a.address ?? "").trim();
  const parts = fullAddr ? fullAddr.split(",").map((s) => s.trim()).filter(Boolean) : [];
  return {
    id: String(a.id ?? `addr_${index}_${Date.now()}`),
    userId: uid,
    recipientName: String(a.recipientName ?? a.name ?? "Người nhận"),
    phone: String(a.phone ?? ""),
    provinceCode: String(a.provinceCode ?? ""),
    provinceName: String(a.provinceName ?? (parts.length >= 1 ? parts[parts.length - 1] : "")),
    wardCode: String(a.wardCode ?? ""),
    wardName: String(a.wardName ?? (parts.length >= 2 ? parts[parts.length - 2] : "")),
    street: String(a.street ?? (parts.length >= 3 ? parts.slice(0, -2).join(", ") : fullAddr)),
    latitude: typeof a.latitude === "number" ? a.latitude : null,
    longitude: typeof a.longitude === "number" ? a.longitude : null,
    isDefault: Boolean(a.isDefault),
    label: typeof a.label === "string" ? a.label : undefined,
  };
}

function serializeAddressForFirestore(a: Address): Record<string, unknown> {
  const fullAddress = [a.street, a.wardName, a.provinceName].filter(Boolean).join(", ");
  return {
    id: a.id,
    userId: a.userId,
    recipientName: a.recipientName,
    phone: a.phone,
    provinceCode: a.provinceCode,
    provinceName: a.provinceName,
    wardCode: a.wardCode,
    wardName: a.wardName,
    street: a.street,
    address: fullAddress,
    latitude: a.latitude,
    longitude: a.longitude,
    isDefault: a.isDefault,
    label: a.label ?? "",
  };
}

function mapFirestoreUser(
  uid: string,
  d: Record<string, unknown>,
  decoded: { email?: string; name?: string; picture?: string; firebase?: { sign_in_provider?: string } },
): User & { addresses: Address[]; reminderSettings: ReminderSettings } {
  const providerRaw = String(d.provider ?? decoded.firebase?.sign_in_provider ?? "password");
  const provider: User["provider"] = providerRaw.includes("google") ? "google" : "password";

  const customPhoto = typeof d.customPhotoUrl === "string" ? d.customPhotoUrl.trim() : "";
  const isPreset = customPhoto.startsWith("preset:");
  const avatarId = isPreset
    ? customPhoto.slice(7) || "sprout"
    : typeof d.avatarId === "string" && d.avatarId
      ? d.avatarId
      : "sprout";
  const avatarUrl = isPreset ? null : (extractUserAvatar(d, decoded.picture ?? null) ?? null);

  const addresses = Array.isArray(d.addresses)
    ? d.addresses.map((a, idx) => mapAddress(uid, a, idx)).filter((x): x is Address => !!x)
    : [];

  const remRaw = (typeof d.reminderSettings === "object" && d.reminderSettings !== null ? d.reminderSettings : {}) as Record<string, unknown>;
  const reminderSettings: ReminderSettings = {
    userId: uid,
    pushEnabled: Boolean(remRaw.pushEnabled ?? false),
    watering: remRaw.watering !== false,
    fertilizing: remRaw.fertilizing !== false,
    inspection: remRaw.inspection !== false,
    dndEnabled: Boolean(remRaw.dndEnabled ?? false),
    dndStart: String(remRaw.dndStart ?? "22:00"),
    dndEnd: String(remRaw.dndEnd ?? "06:30"),
  };

  return {
    uid,
    displayName: String(d.displayName ?? decoded.name ?? decoded.email?.split("@")[0] ?? "Người dùng Floria"),
    email: String(d.email ?? decoded.email ?? ""),
    avatarId,
    avatarUrl,
    phone: extractUserPhone(d),
    bio: typeof d.bio === "string" ? d.bio : "",
    joinedAt: toIsoString(d.createdAt ?? d.joinedAt),
    provider,
    cartItems: Array.isArray(d.cartItems) ? (d.cartItems as CartItem[]) : [],
    addresses,
    reminderSettings,
  };
}

async function handleSync(req: Request, patch?: Record<string, unknown>) {
  if (!isFirebaseAdminConfigured()) {
    return NextResponse.json({ error: "Firebase Admin chưa được cấu hình" }, { status: 503 });
  }
  const authHeader = req.headers.get("authorization") ?? "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7).trim() : "";
  if (!token) {
    return NextResponse.json({ error: "Thiếu token xác thực" }, { status: 401 });
  }

  const decoded = await getAdminAuth().verifyIdToken(token);
  const db = getAdminDb();
  const ref = db.collection("Users").doc(decoded.uid);
  const snap = await ref.get();
  const existing = (snap.exists ? snap.data() : {}) as Record<string, unknown>;
  const now = new Date().toISOString();

  const updatePayload: Record<string, unknown> = {
    uid: decoded.uid,
    email: String(existing.email ?? decoded.email ?? ""),
    updatedAt: now,
    lastActiveAt: now,
  };

  if (!snap.exists) {
    updatePayload.createdAt = now;
    updatePayload.joinedAt = now;
    updatePayload.displayName = decoded.name ?? decoded.email?.split("@")[0] ?? "Người dùng Floria";
    updatePayload.provider = decoded.firebase?.sign_in_provider?.includes("google") ? "google" : "password";
    updatePayload.avatarId = "sprout";
    if (decoded.picture) updatePayload.googlePhotoUrl = decoded.picture;
  }

  if (patch) {
    for (const k of ["displayName", "phone", "bio", "avatarId", "avatarUrl", "cartItems", "provider", "reminderSettings"] as const) {
      if (patch[k] !== undefined) {
        updatePayload[k] = patch[k];
      }
    }
    if (typeof patch.avatarUrl === "string" && patch.avatarUrl) {
      updatePayload.customPhotoUrl = patch.avatarUrl;
    } else if (patch.avatarUrl === null && typeof patch.avatarId === "string" && patch.avatarId) {
      updatePayload.customPhotoUrl = `preset:${patch.avatarId}`;
    }
    if (Array.isArray(patch.addresses)) {
      updatePayload.addresses = (patch.addresses as Address[]).map(serializeAddressForFirestore);
    }
  }

  await ref.set(updatePayload, { merge: true });
  const merged = { ...existing, ...updatePayload };
  return NextResponse.json(mapFirestoreUser(decoded.uid, merged, decoded));
}

export async function GET(req: Request) {
  try {
    return await handleSync(req);
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message || "Không thể đồng bộ người dùng" }, { status: 401 });
  }
}

export async function POST(req: Request) {
  try {
    const body = (await req.json().catch(() => ({}))) as Record<string, unknown>;
    return await handleSync(req, body);
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message || "Không thể đồng bộ người dùng" }, { status: 401 });
  }
}
