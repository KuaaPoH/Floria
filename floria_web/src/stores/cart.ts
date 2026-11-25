import { create } from "zustand";
import { persist } from "zustand/middleware";
import { removeOrderedItems } from "@/features/ecommerce/logic";
import type { CartItem } from "@/types/user";

interface CartState {
  items: CartItem[];
  add: (productId: string, quantity?: number) => void;
  setQuantity: (productId: string, quantity: number) => void;
  remove: (productId: string) => void;
  toggle: (productId: string) => void;
  setAllSelected: (selected: boolean) => void;
  /** Only remove items that were placed in a successful order. */
  removeOrdered: (productIds: string[]) => void;
  replace: (items: CartItem[]) => void;
  /** One-shot checkout selection (product ids + quantities) passed from cart or "Mua lại". */
  checkoutIds: string[];
  setCheckoutIds: (ids: string[]) => void;
}

export const useCart = create<CartState>()(
  persist(
    (set) => ({
      items: [],
      checkoutIds: [],
      add: (productId, quantity = 1) =>
        set((s) => {
          const existing = s.items.find((i) => i.productId === productId);
          if (existing) return { items: s.items.map((i) => (i.productId === productId ? { ...i, quantity: i.quantity + quantity, selected: true } : i)) };
          return { items: [...s.items, { productId, quantity, selected: true, addedAt: new Date().toISOString() }] };
        }),
      setQuantity: (productId, quantity) => set((s) => ({ items: s.items.map((i) => (i.productId === productId ? { ...i, quantity: Math.max(1, quantity) } : i)) })),
      remove: (productId) => set((s) => ({ items: s.items.filter((i) => i.productId !== productId) })),
      toggle: (productId) => set((s) => ({ items: s.items.map((i) => (i.productId === productId ? { ...i, selected: !i.selected } : i)) })),
      setAllSelected: (selected) => set((s) => ({ items: s.items.map((i) => ({ ...i, selected })) })),
      removeOrdered: (ids) => set((s) => ({ items: removeOrderedItems(s.items, ids), checkoutIds: [] })),
      replace: (items) => set({ items }),
      setCheckoutIds: (checkoutIds) => set({ checkoutIds }),
    }),
    { name: "floria:cart", skipHydration: true },
  ),
);

export const cartCount = (items: CartItem[]) => items.reduce((s, i) => s + i.quantity, 0);
