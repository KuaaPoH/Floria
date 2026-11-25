import type { CartItem, Order, ShopProduct, Voucher } from "@/types/user";

export const unitPrice = (p: Pick<ShopProduct, "price" | "salePrice">) => p.salePrice ?? p.price;

export function cartLines(items: CartItem[], products: ShopProduct[]) {
  return items
    .map((item) => {
      const product = products.find((p) => p.id === item.productId);
      return product ? { item, product, lineTotal: unitPrice(product) * item.quantity } : null;
    })
    .filter((x): x is NonNullable<typeof x> => x !== null);
}

/** Subtotal of selected lines only. */
export function selectedSubtotal(items: CartItem[], products: ShopProduct[]) {
  return cartLines(items, products)
    .filter((l) => l.item.selected)
    .reduce((sum, l) => sum + l.lineTotal, 0);
}

export type VoucherCheck =
  | { ok: true; discount: number }
  | { ok: false; reason: "not_found" | "expired" | "inactive" | "min_order"; minOrder?: number };

export function evaluateVoucher(voucher: Voucher | undefined, subtotal: number, _shippingFee = 0, now = new Date()): VoucherCheck {
  if (!voucher) return { ok: false, reason: "not_found" };
  if (!voucher.active) return { ok: false, reason: "inactive" };
  if (new Date(voucher.expiresAt).getTime() < now.getTime()) return { ok: false, reason: "expired" };
  if (subtotal < voucher.minOrder) return { ok: false, reason: "min_order", minOrder: voucher.minOrder };
  if (voucher.type === "fixed") return { ok: true, discount: Math.min(voucher.value, subtotal) };
  const raw = Math.round((subtotal * voucher.value) / 100);
  return { ok: true, discount: Math.min(raw, voucher.maxDiscount ?? raw, subtotal) };
}

export function orderTotals(subtotal: number, _shippingFee: number, check: VoucherCheck | null) {
  const discount = check?.ok ? check.discount : 0;
  return { subtotal, shippingFee: 0, discount, total: Math.max(0, subtotal - discount) };
}

/** After a successful order only the ordered product ids leave the cart. */
export function removeOrderedItems(items: CartItem[], orderedProductIds: string[]) {
  const set = new Set(orderedProductIds);
  return items.filter((i) => !set.has(i.productId));
}


/** Which order actions are valid for a given backend status. */
export function orderActions(o: Pick<Order, "status" | "items">) {
  return {
    cancel: o.status === "pending",
    receive: o.status === "pending" || o.status === "processing" || o.status === "shipping",
    rebuy: o.status === "delivered" || o.status === "cancelled",
    review: o.status === "delivered" && o.items.some((i) => !i.reviewed),
  };
}
