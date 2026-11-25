import { create } from "zustand";
import { persist } from "zustand/middleware";
import type { Lang } from "@/types/user";

interface SettingsState {
  theme: "light" | "dark";
  lang: Lang;
  setTheme: (t: "light" | "dark") => void;
  setLang: (l: Lang) => void;
}

export const useSettings = create<SettingsState>()(
  persist(
    (set) => ({
      theme: "light",
      lang: "vi",
      setTheme: (theme) => set({ theme }),
      setLang: (lang) => set({ lang }),
    }),
    { name: "floria:settings", skipHydration: true },
  ),
);
