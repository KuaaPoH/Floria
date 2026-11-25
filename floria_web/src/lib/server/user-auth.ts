import { getAdminAuth, isFirebaseAdminConfigured } from "./firebase-admin";

export class UserAuthError extends Error {
  status: number;
  constructor(message: string, status = 401) {
    super(message);
    this.status = status;
  }
}

export interface VerifiedUser {
  uid: string;
  email: string;
  name: string;
  picture?: string;
}

export async function verifyUserRequest(req: Request): Promise<VerifiedUser> {
  if (!isFirebaseAdminConfigured()) {
    throw new UserAuthError("Firebase Admin chưa được cấu hình.", 503);
  }
  const authHeader = req.headers.get("authorization") ?? "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7).trim() : "";
  if (!token) {
    throw new UserAuthError("Vui lòng đăng nhập để tiếp tục.", 401);
  }
  try {
    const decoded = await getAdminAuth().verifyIdToken(token);
    return {
      uid: decoded.uid,
      email: decoded.email ?? "",
      name: decoded.name ?? decoded.email?.split("@")[0] ?? "Người dùng Floria",
      picture: decoded.picture,
    };
  } catch {
    throw new UserAuthError("Phiên đăng nhập không hợp lệ hoặc đã hết hạn.", 401);
  }
}

export async function tryVerifyUserRequest(req: Request): Promise<VerifiedUser | null> {
  try {
    return await verifyUserRequest(req);
  } catch {
    return null;
  }
}
