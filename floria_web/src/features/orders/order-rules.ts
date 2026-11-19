import type { FulfillmentStatus, Order } from "@/types";

const NEXT: Record<FulfillmentStatus, FulfillmentStatus[]> = {
  pending: ["confirmed", "cancelled"],
  confirmed: ["shipping", "cancelled"],
  shipping: ["delivered"],
  delivered: [],
  cancelled: [],
};

/** Allowed fulfillment transitions; delivered and cancelled are final. */
export function nextStatuses(s: FulfillmentStatus): FulfillmentStatus[] {
  return NEXT[s];
}

/** COD cash can only be confirmed once the parcel is delivered and not yet paid. */
export function canConfirmCod(o: Order) {
  return o.paymentMethod === "COD" && o.fulfillment === "delivered" && o.paymentStatus === "unpaid";
}

/** Refunds apply to paid orders or ZaloPay orders cancelled after payment. */
export function canRequestRefund(o: Order) {
  return o.paymentStatus === "paid" && o.paymentMethod === "ZALOPAY";
}

/** Sandbox/simulated ZaloPay transactions must never be shown as verified. */
export function isVerifiedTransaction(o: Order) {
  return !!o.transaction && !o.transaction.sandbox;
}

export function orderSubtotal(o: Order) {
  return o.items.reduce((s, it) => s + it.qty * it.price, 0);
}
