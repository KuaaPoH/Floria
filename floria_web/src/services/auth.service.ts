import {
  createUserWithEmailAndPassword,
  sendPasswordResetEmail,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut,
  updateProfile as updateFirebaseProfile,
  type User as FirebaseUser,
} from "firebase/auth";
import { isMock } from "@/config/env";
import { uid as makeId } from "@/lib/id";
import { getFirebaseClientAuth, googleAuthProvider } from "@/lib/firebase-client";
import { readDb, writeDb } from "@/mocks/user/db";
import type { CartItem, User } from "@/types/user";
import { http } from "./api/http";
import { latency, MockError } from "./mock/util";
import { session } from "./session";

export interface AuthService {
  currentUser(): Promise<User | null>;
  login(email: string, password: string, remember: boolean): Promise<User>;
  register(input: { displayName: string; email: string; password: string }): Promise<User>;
  loginWithGoogle(): Promise<User>;
  sendPasswordReset(email: string): Promise<void>;
  logout(): Promise<void>;
  updateProfile(uid: string, patch: Partial<Pick<User, "displayName" | "phone" | "bio" | "avatarId" | "avatarUrl">>): Promise<User>;
  syncCart(uid: string, items: CartItem[]): Promise<void>;
}

const strip = (u: User & { password?: string }): User => {
  const { password: _p, ...rest } = u;
  return rest;
};

function userFromFirebase(fbUser: FirebaseUser): User {
  const isGoogle = fbUser.providerData.some((p) => p.providerId === "google.com");
  return {
    uid: fbUser.uid,
    displayName: fbUser.displayName ?? fbUser.email?.split("@")[0] ?? "Người dùng Floria",
    email: fbUser.email ?? "",
    avatarId: "sprout",
    avatarUrl: fbUser.photoURL ?? null,
    phone: fbUser.phoneNumber ?? "",
    bio: "",
    joinedAt: fbUser.metadata.creationTime ? new Date(fbUser.metadata.creationTime).toISOString() : new Date().toISOString(),
    provider: isGoogle ? "google" : "password",
    cartItems: [],
  };
}

function translateFirebaseError(err: unknown): string {
  const code = (err as { code?: string })?.code ?? "";
  if (code === "auth/invalid-credential" || code === "auth/wrong-password" || code === "auth/user-not-found") {
    return "Email hoặc mật khẩu không đúng.";
  }
  if (code === "auth/email-already-in-use") return "Email này đã được đăng ký.";
  if (code === "auth/weak-password") return "Mật khẩu quá yếu (tối thiểu 6 ký tự).";
  if (code === "auth/popup-closed-by-user") return "Bạn đã đóng cửa sổ đăng nhập Google.";
  if (code === "auth/popup-blocked") return "Trình duyệt đã chặn cửa sổ bật lên (popup). Hãy cho phép popup và thử lại.";
  if (code === "auth/unauthorized-domain") return "Tên miền hiện tại chưa được cấp phép trong Firebase Console (Authorized domains).";
  if (code === "auth/too-many-requests") return "Thao tác quá nhiều lần, vui lòng thử lại sau ít phút.";
  return err instanceof Error ? err.message : "Đăng nhập thất bại.";
}

const mockAuth: AuthService = {
  async currentUser() {
    const id = session.get();
    if (!id) return null;
    const u = readDb().users.find((x) => x.uid === id);
    return u ? strip(u) : null;
  },
  async login(email, password, remember) {
    await latency(350, 650);
    const u = readDb().users.find((x) => x.email.toLowerCase() === email.trim().toLowerCase());
    if (!u || u.password !== password) throw new MockError("Email hoặc mật khẩu không đúng.", "invalid_credentials");
    session.set(u.uid, remember);
    return strip(u);
  },
  async register({ displayName, email, password }) {
    await latency(450, 800);
    const exists = readDb().users.some((x) => x.email.toLowerCase() === email.trim().toLowerCase());
    if (exists) throw new MockError("Email này đã được đăng ký.", "email_in_use");
    const user = writeDb((db) => {
      const u = {
        uid: makeId("u"),
        displayName: displayName.trim(),
        email: email.trim().toLowerCase(),
        password,
        avatarId: "fern",
        avatarUrl: null,
        joinedAt: new Date().toISOString(),
        provider: "password" as const,
        cartItems: [],
      };
      db.users.push(u);
      db.reminders.push({
        userId: u.uid,
        pushEnabled: true,
        watering: true,
        fertilizing: true,
        inspection: true,
        dndEnabled: false,
        dndStart: "22:00",
        dndEnd: "06:30",
      });
      return u;
    });
    session.set(user.uid, true);
    return strip(user);
  },
  async loginWithGoogle() {
    await latency(300, 500);
    throw new MockError("Đăng nhập Google cần chế độ API (NEXT_PUBLIC_DATA_MODE=api).", "provider_unavailable");
  },
  async sendPasswordReset(email) {
    await latency(500, 800);
    const exists = readDb().users.some((x) => x.email.toLowerCase() === email.trim().toLowerCase());
    if (!exists) throw new MockError("Không tìm thấy tài khoản với email này.", "user_not_found");
  },
  async logout() {
    session.clear();
  },
  async updateProfile(uid, patch) {
    await latency();
    return writeDb((db) => {
      const u = db.users.find((x) => x.uid === uid);
      if (!u) throw new MockError("Không tìm thấy người dùng.", "not_found");
      Object.assign(u, patch);
      return strip(u);
    });
  },
  async syncCart(uid, items) {
    writeDb((db) => {
      const u = db.users.find((x) => x.uid === uid);
      if (u) u.cartItems = items;
    });
  },
};

async function syncFirebaseUser(fbUser: FirebaseUser, patch?: Record<string, unknown>): Promise<User> {
  const fallback = userFromFirebase(fbUser);
  try {
    const token = await fbUser.getIdToken();
    return await http<User>("/auth/sync", {
      method: "POST",
      headers: { Authorization: `Bearer ${token}` },
      json: patch ?? {},
    });
  } catch {
    return fallback;
  }
}

function getPortalScope(): "user" | "admin" | null {
  if (typeof window === "undefined") return null;
  const v = localStorage.getItem("floria_portal_scope");
  return v === "user" || v === "admin" ? v : null;
}

function setPortalScope(scope: "user" | "admin" | null) {
  if (typeof window === "undefined") return;
  if (!scope) {
    localStorage.removeItem("floria_portal_scope");
    return;
  }
  localStorage.setItem("floria_portal_scope", scope);
  if (scope === "user") {
    localStorage.removeItem("floria-admin-auth");
  }
}

const apiAuth: AuthService = {
  async currentUser() {
    if (typeof window === "undefined") return null;
    try {
      const auth = getFirebaseClientAuth();
      await auth.authStateReady();
      if (getPortalScope() === "admin") {
        // Khi quay từ trang Admin sang trang User, bắt buộc đăng xuất khỏi phiên Admin để yêu cầu đăng nhập User
        await signOut(auth).catch(() => {});
        session.clear();
        localStorage.removeItem("floria-admin-auth");
        setPortalScope(null);
        return null;
      }
      if (!auth.currentUser) {
        session.clear();
        return null;
      }
      const user = await syncFirebaseUser(auth.currentUser);
      session.set(user.uid, true);
      setPortalScope("user");
      return user;
    } catch {
      return null;
    }
  },
  async login(email, password, remember) {
    try {
      const auth = getFirebaseClientAuth();
      const cred = await signInWithEmailAndPassword(auth, email.trim(), password);
      const user = await syncFirebaseUser(cred.user);
      session.set(user.uid, remember);
      setPortalScope("user");
      return user;
    } catch (err) {
      throw new Error(translateFirebaseError(err));
    }
  },
  async register({ displayName, email, password }) {
    try {
      const auth = getFirebaseClientAuth();
      const cred = await createUserWithEmailAndPassword(auth, email.trim(), password);
      await updateFirebaseProfile(cred.user, { displayName: displayName.trim() });
      const user = await syncFirebaseUser(cred.user, { displayName: displayName.trim(), provider: "password" });
      session.set(user.uid, true);
      setPortalScope("user");
      return user;
    } catch (err) {
      throw new Error(translateFirebaseError(err));
    }
  },
  async loginWithGoogle() {
    try {
      const auth = getFirebaseClientAuth();
      const cred = await signInWithPopup(auth, googleAuthProvider);
      const user = await syncFirebaseUser(cred.user, {
        displayName: cred.user.displayName ?? undefined,
        avatarUrl: cred.user.photoURL ?? undefined,
        provider: "google",
      });
      session.set(user.uid, true);
      setPortalScope("user");
      return user;
    } catch (err) {
      throw new Error(translateFirebaseError(err));
    }
  },
  async sendPasswordReset(email) {
    try {
      const auth = getFirebaseClientAuth();
      auth.languageCode = "vi";
      await sendPasswordResetEmail(auth, email.trim());
    } catch (err) {
      throw new Error(translateFirebaseError(err));
    }
  },
  async logout() {
    session.clear();
    setPortalScope(null);
    if (typeof window !== "undefined") {
      await signOut(getFirebaseClientAuth()).catch(() => {});
    }
  },
  async updateProfile(uid, patch) {
    return http<User>("/auth/sync", { method: "POST", json: patch });
  },
  async syncCart(_uid, items) {
    void http("/auth/sync", { method: "POST", json: { cartItems: items } }).catch(() => {});
  },
};

export const authService: AuthService = isMock() ? mockAuth : apiAuth;
