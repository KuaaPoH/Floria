"use client";

import { create } from "zustand";
import { persist } from "zustand/middleware";
import { signInWithEmailAndPassword, signInWithPopup, signOut } from "firebase/auth";
import { IS_MOCK } from "@/lib/config";
import { getFirebaseClientAuth, googleAuthProvider } from "@/lib/firebase-client";
import type { RoleId } from "@/types";

export interface AdminSession {
  id: string;
  name: string;
  email: string;
  role: RoleId;
}

export const DEMO_ACCOUNTS: (AdminSession & { password: string })[] = [
  { id: "adm_1", name: "Phạm Minh Đức", email: "admin@floria.vn", role: "super_admin", password: "floria123" },
  { id: "adm_2", name: "TS. Nguyễn Thảo", email: "botanist@floria.vn", role: "botanist", password: "floria123" },
  { id: "adm_4", name: "Ngô Thanh Tú", email: "support@floria.vn", role: "operations", password: "floria123" },
];

interface AuthState {
  session: AdminSession | null;
  login: (email: string, password: string) => AdminSession | null;
  loginWithFirebase: (email: string, password: string) => Promise<AdminSession>;
  loginWithGoogle: () => Promise<AdminSession>;
  refreshSession: () => Promise<AdminSession | null>;
  logout: () => Promise<void>;
  switchRole: (role: RoleId) => void;
}

async function verifyFirebaseSession(idToken: string): Promise<AdminSession> {
  const res = await fetch("/api/admin/auth/me", {
    headers: { Authorization: `Bearer ${idToken}` },
  });
  const data = (await res.json()) as AdminSession & { error?: string };
  if (!res.ok) {
    throw new Error(data.error ?? "Không thể xác thực quyền quản trị");
  }
  return { id: data.id, name: data.name, email: data.email, role: data.role };
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      session: null,
      login: (email, password) => {
        const acc = DEMO_ACCOUNTS.find((a) => a.email === email.trim().toLowerCase() && a.password === password);
        if (!acc) return null;
        const { password: _p, ...session } = acc;
        set({ session });
        return session;
      },
      loginWithFirebase: async (email, password) => {
        const auth = getFirebaseClientAuth();
        const cred = await signInWithEmailAndPassword(auth, email.trim(), password);
        const token = await cred.user.getIdToken(true);
        try {
          const session = await verifyFirebaseSession(token);
          set({ session });
          return session;
        } catch (err) {
          await signOut(auth);
          throw err;
        }
      },
      loginWithGoogle: async () => {
        const auth = getFirebaseClientAuth();
        const cred = await signInWithPopup(auth, googleAuthProvider);
        const token = await cred.user.getIdToken(true);
        try {
          const session = await verifyFirebaseSession(token);
          set({ session });
          return session;
        } catch (err) {
          await signOut(auth);
          throw err;
        }
      },
      refreshSession: async () => {
        if (IS_MOCK || typeof window === "undefined") return get().session;
        const auth = getFirebaseClientAuth();
        await auth.authStateReady();
        const user = auth.currentUser;
        if (!user) {
          set({ session: null });
          return null;
        }
        try {
          const token = await user.getIdToken();
          const newSession = await verifyFirebaseSession(token);
          const current = get().session;
          if (
            current &&
            current.id === newSession.id &&
            current.name === newSession.name &&
            current.email === newSession.email &&
            current.role === newSession.role
          ) {
            return current;
          }
          set({ session: newSession });
          return newSession;
        } catch {
          return get().session;
        }
      },
      logout: async () => {
        set({ session: null });
        if (!IS_MOCK && typeof window !== "undefined") {
          try {
            await signOut(getFirebaseClientAuth());
          } catch {
            // Bỏ qua lỗi signOut nếu chưa khởi tạo
          }
        }
      },
      switchRole: (role) => {
        if (!IS_MOCK) return;
        const acc = DEMO_ACCOUNTS.find((a) => a.role === role);
        if (!acc || !get().session) return;
        const { password: _p, ...session } = acc;
        set({ session });
      },
    }),
    { name: "floria.auth" },
  ),
);
