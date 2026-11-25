"use client";

import { useEffect } from "react";
import { authService } from "@/services/auth.service";
import { useAuth } from "@/stores/auth";
import { useCart } from "@/stores/cart";
import { useSettings } from "@/stores/settings";

/** Client-only startup: rehydrate persisted stores, restore session, apply theme & language. */
export function AppBootstrap() {
  const theme = useSettings((s) => s.theme);
  const lang = useSettings((s) => s.lang);
  const user = useAuth((s) => s.user);
  const items = useCart((s) => s.items);

  useEffect(() => {
    void useSettings.persist.rehydrate();
    void useCart.persist.rehydrate();
    void useAuth.getState().init();
  }, []);

  useEffect(() => {
    document.documentElement.classList.toggle("dark", theme === "dark");
  }, [theme]);

  useEffect(() => {
    document.documentElement.lang = lang;
  }, [lang]);

  useEffect(() => {
    if (!user) return;
    const saved = user.cartItems ?? [];
    const local = useCart.getState().items;
    const merged = [...local];
    for (const s of saved) if (!merged.some((m) => m.productId === s.productId)) merged.push(s);
    useCart.getState().replace(merged);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user?.uid]);

  useEffect(() => {
    if (user) void authService.syncCart(user.uid, items);
  }, [user, items]);

  return null;
}
