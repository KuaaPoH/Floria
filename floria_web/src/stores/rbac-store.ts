"use client";

import { create } from "zustand";
import { persist } from "zustand/middleware";
import { DEFAULT_PERMISSIONS, can, type ModuleId, type PermAction, type PermissionMatrix } from "@/lib/rbac";
import { apiRequest } from "@/lib/api-client";
import { IS_MOCK } from "@/lib/config";
import type { RoleId } from "@/types";
import { useAuthStore } from "./auth-store";

interface RbacState {
  matrix: PermissionMatrix;
  loaded: boolean;
  saving: boolean;
  loadMatrix: () => Promise<void>;
  toggle: (role: RoleId, module: ModuleId, action: PermAction) => Promise<void>;
  reset: () => Promise<void>;
}

export const useRbacStore = create<RbacState>()(
  persist(
    (set, get) => ({
      matrix: DEFAULT_PERMISSIONS,
      loaded: false,
      saving: false,
      loadMatrix: async () => {
        if (IS_MOCK || get().loaded) return;
        try {
          const remote = await apiRequest<PermissionMatrix>("/roles/matrix");
          set({ matrix: remote, loaded: true });
        } catch {
          set({ loaded: true });
        }
      },
      toggle: async (role, module, action) => {
        if (role === "super_admin") return;
        const s = get();
        const current = s.matrix[role]?.[module] ?? [];
        let next = current.includes(action) ? current.filter((a) => a !== action) : [...current, action];
        if (action === "view" && !next.includes("view")) next = [];
        if (action !== "view" && next.length && !next.includes("view")) next = ["view", ...next];

        const nextMatrix: PermissionMatrix = {
          ...s.matrix,
          [role]: { ...s.matrix[role], [module]: next },
        };
        set({ matrix: nextMatrix });

        if (!IS_MOCK) {
          set({ saving: true });
          try {
            const saved = await apiRequest<PermissionMatrix>("/roles/matrix", {
              method: "PUT",
              body: JSON.stringify({ matrix: nextMatrix }),
            });
            set({ matrix: saved });
          } finally {
            set({ saving: false });
          }
        }
      },
      reset: async () => {
        const defaultCopy = structuredClone(DEFAULT_PERMISSIONS);
        set({ matrix: defaultCopy });
        if (!IS_MOCK) {
          set({ saving: true });
          try {
            const saved = await apiRequest<PermissionMatrix>("/roles/matrix", {
              method: "PUT",
              body: JSON.stringify({ matrix: defaultCopy }),
            });
            set({ matrix: saved });
          } finally {
            set({ saving: false });
          }
        }
      },
    }),
    {
      name: "floria.rbac",
      partialize: (state) => ({ matrix: state.matrix }),
    },
  ),
);

/** Returns whether the signed-in admin may perform `action` on `module`. */
export function usePermission(module: ModuleId, action: PermAction = "view") {
  const role = useAuthStore((s) => s.session?.role);
  const matrix = useRbacStore((s) => s.matrix);
  return role ? can(matrix, role, module, action) : false;
}
