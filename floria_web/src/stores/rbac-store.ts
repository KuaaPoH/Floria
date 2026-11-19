"use client";

import { create } from "zustand";
import { persist } from "zustand/middleware";
import { DEFAULT_PERMISSIONS, can, type ModuleId, type PermAction, type PermissionMatrix } from "@/lib/rbac";
import type { RoleId } from "@/types";
import { useAuthStore } from "./auth-store";

interface RbacState {
  matrix: PermissionMatrix;
  toggle: (role: RoleId, module: ModuleId, action: PermAction) => void;
  reset: () => void;
}

export const useRbacStore = create<RbacState>()(
  persist(
    (set) => ({
      matrix: DEFAULT_PERMISSIONS,
      toggle: (role, module, action) =>
        set((s) => {
          if (role === "super_admin") return s; // Super Admin is always full access
          const current = s.matrix[role][module];
          let next = current.includes(action) ? current.filter((a) => a !== action) : [...current, action];
          if (action === "view" && !next.includes("view")) next = []; // no view => no other rights
          if (action !== "view" && next.length && !next.includes("view")) next = ["view", ...next];
          return { matrix: { ...s.matrix, [role]: { ...s.matrix[role], [module]: next } } };
        }),
      reset: () => set({ matrix: DEFAULT_PERMISSIONS }),
    }),
    { name: "floria.rbac" },
  ),
);

/** Returns whether the signed-in admin may perform `action` on `module`. */
export function usePermission(module: ModuleId, action: PermAction = "view") {
  const role = useAuthStore((s) => s.session?.role);
  const matrix = useRbacStore((s) => s.matrix);
  return role ? can(matrix, role, module, action) : false;
}
