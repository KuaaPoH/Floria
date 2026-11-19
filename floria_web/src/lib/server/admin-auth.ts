import type { RoleId } from "@/types";
import { getAdminAuth, getAdminDb } from "./firebase-admin";

export interface VerifiedAdmin {
  id: string;
  name: string;
  email: string;
  role: RoleId;
}

const VALID_ROLES = new Set<RoleId>(["super_admin", "botanist", "operations"]);

function normalizeRole(raw: unknown): RoleId | null {
  if (typeof raw !== "string") return null;
  const v = raw.trim().toLowerCase();
  if (v === "admin") return "super_admin";
  if (VALID_ROLES.has(v as RoleId)) return v as RoleId;
  return null;
}

function getAllowlistedEmails(): Set<string> {
  const raw = process.env.ADMIN_EMAILS ?? "";
  return new Set(
    raw
      .split(",")
      .map((s) => s.trim().toLowerCase())
      .filter(Boolean),
  );
}

export class AdminAuthError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

const ADMIN_CACHE_TTL_MS = 2 * 60_000;
const adminProfileCache = new Map<string, { admin: VerifiedAdmin; expiresAt: number }>();

export async function verifyAdminRequest(req: Request): Promise<VerifiedAdmin> {
  const authHeader = req.headers.get("authorization") ?? "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7).trim() : "";
  if (!token) {
    throw new AdminAuthError("Thiếu token xác thực Firebase.", 401);
  }

  let decoded;
  try {
    decoded = await getAdminAuth().verifyIdToken(token);
  } catch {
    throw new AdminAuthError("Token xác thực không hợp lệ hoặc đã hết hạn.", 401);
  }

  const uid = decoded.uid;
  const cached = adminProfileCache.get(uid);
  if (cached && cached.expiresAt > Date.now()) {
    return cached.admin;
  }

  const admin = await resolveVerifiedAdmin(decoded);
  adminProfileCache.set(uid, { admin, expiresAt: Date.now() + ADMIN_CACHE_TTL_MS });
  return admin;
}

async function resolveVerifiedAdmin(decoded: {
  uid: string;
  email?: string;
  name?: string;
  [key: string]: unknown;
}): Promise<VerifiedAdmin> {

  const uid = decoded.uid;
  const email = (decoded.email ?? "").toLowerCase();
  const fallbackName = decoded.name || (email ? email.split("@")[0] : "Quản trị viên");

  // 1. Ưu tiên đọc từ collection AdminAccounts trên Firestore để nhận tên/role mới nhất
  const db = getAdminDb();
  const byUid = await db.collection("AdminAccounts").doc(uid).get();
  if (byUid.exists) {
    const data = byUid.data() ?? {};
    if (data.active === false) {
      throw new AdminAuthError("Tài khoản quản trị đã bị vô hiệu hóa.", 403);
    }
    const role = normalizeRole(data.role) ?? "operations";
    return {
      id: uid,
      name: typeof data.name === "string" && data.name.trim() ? data.name.trim() : fallbackName,
      email: typeof data.email === "string" && data.email.trim() ? data.email.trim() : email,
      role,
    };
  }

  if (email) {
    const byEmail = await db.collection("AdminAccounts").where("email", "==", email).limit(1).get();
    if (!byEmail.empty) {
      const doc = byEmail.docs[0];
      const data = doc.data();
      if (data.active === false) {
        throw new AdminAuthError("Tài khoản quản trị đã bị vô hiệu hóa.", 403);
      }
      const role = normalizeRole(data.role) ?? "operations";
      return {
        id: uid,
        name: typeof data.name === "string" && data.name.trim() ? data.name.trim() : fallbackName,
        email,
        role,
      };
    }
  }

  // 2. Kiểm tra custom claims trên Firebase Auth token
  const claimRole = normalizeRole((decoded as Record<string, unknown>).role);
  if (claimRole) {
    return { id: uid, name: fallbackName, email, role: claimRole };
  }
  if ((decoded as Record<string, unknown>).admin === true) {
    return { id: uid, name: fallbackName, email, role: "super_admin" };
  }

  // 3. Kiểm tra role trong collection Users (đồng bộ với floria_app)
  const userDoc = await db.collection("Users").doc(uid).get();
  if (userDoc.exists) {
    const userData = userDoc.data() ?? {};
    const userRole = normalizeRole(userData.role);
    if (userRole) {
      return {
        id: uid,
        name: typeof userData.displayName === "string" && userData.displayName.trim() ? userData.displayName.trim() : fallbackName,
        email,
        role: userRole,
      };
    }
  }

  // 4. Fallback allowlist từ biến môi trường ADMIN_EMAILS để bootstrap tài khoản admin đầu tiên
  if (email && getAllowlistedEmails().has(email)) {
    return { id: uid, name: fallbackName, email, role: "super_admin" };
  }

  throw new AdminAuthError("Tài khoản này chưa được cấp quyền truy cập trang quản trị.", 403);
}
