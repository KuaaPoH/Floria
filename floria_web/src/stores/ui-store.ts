"use client";

import { create } from "zustand";
import { persist } from "zustand/middleware";

interface UiState {
  collapsed: boolean;
  mobileOpen: boolean;
  searchOpen: boolean;
  toggleCollapsed: () => void;
  setMobileOpen: (v: boolean) => void;
  setSearchOpen: (v: boolean) => void;
}

export const useUiStore = create<UiState>()(
  persist(
    (set) => ({
      collapsed: false,
      mobileOpen: false,
      searchOpen: false,
      toggleCollapsed: () => set((s) => ({ collapsed: !s.collapsed })),
      setMobileOpen: (mobileOpen) => set({ mobileOpen }),
      setSearchOpen: (searchOpen) => set({ searchOpen }),
    }),
    { name: "floria.ui", partialize: (s) => ({ collapsed: s.collapsed }) },
  ),
);
