import { create } from "zustand";
import { authService } from "@/services/auth.service";
import type { User } from "@/types/user";

type Status = "idle" | "loading" | "authenticated" | "anonymous";

interface AuthState {
  user: User | null;
  status: Status;
  init: () => Promise<void>;
  setUser: (u: User | null) => void;
  logout: () => Promise<void>;
}

export const useAuth = create<AuthState>((set, get) => ({
  user: null,
  status: "idle",
  async init() {
    if (get().status !== "idle") return;
    set({ status: "loading" });
    const user = await authService.currentUser().catch(() => null);
    set({ user, status: user ? "authenticated" : "anonymous" });
  },
  setUser(user) {
    set({ user, status: user ? "authenticated" : "anonymous" });
  },
  async logout() {
    await authService.logout();
    set({ user: null, status: "anonymous" });
  },
}));

/** Resolve auth status synchronously-ish for route guards (client only). */
export async function ensureAuth() {
  const s = useAuth.getState();
  if (typeof window !== "undefined" && localStorage.getItem("floria_portal_scope") === "admin") {
    await s.logout();
    return null;
  }
  if (s.status === "idle" || s.status === "loading") await s.init();
  // init may already be running — wait for it.
  while (useAuth.getState().status === "loading") await new Promise((r) => setTimeout(r, 20));
  return useAuth.getState().user;
}
