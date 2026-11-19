import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import type { FulfillmentStatus, Order, PaymentMethod, PaymentStatus } from "@/types";

export function mapFulfillment(raw: unknown): FulfillmentStatus {
  const s = String(raw ?? "pending").toLowerCase();
  if (s === "completed" || s === "delivered") return "delivered";
  if (s === "confirmed") return "confirmed";
  if (s === "shipping") return "shipping";
  if (s === "cancelled") return "cancelled";
  return "pending";
}

export function mapOrderDoc(
  id: string,
  d: Record<string, unknown>,
  userEmails: Map<string, string>,
): Order {
  const rawItems = Array.isArray(d.items) ? d.items : [];
  const items = rawItems.map((it) => {
    const m = typeof it === "object" && it !== null ? (it as Record<string, unknown>) : {};
    return {
      productId: String(m.productId ?? ""),
      name: String(m.name ?? "Sản phẩm"),
      qty: Number(m.quantity ?? m.qty ?? 1),
      price: Number(m.price ?? 0),
    };
  });

  const rawMethod = String(d.paymentMethod ?? "cod").toLowerCase();
  const paymentMethod: PaymentMethod = rawMethod === "zalopay" || rawMethod === "card" ? "ZALOPAY" : "COD";
  const fulfillment = mapFulfillment(d.status ?? d.fulfillment);

  let paymentStatus: PaymentStatus = "unpaid";
  if (typeof d.paymentStatus === "string" && ["unpaid", "paid", "refund_requested", "refunded", "failed"].includes(d.paymentStatus)) {
    paymentStatus = d.paymentStatus as PaymentStatus;
  } else if (paymentMethod === "ZALOPAY") {
    paymentStatus = fulfillment === "cancelled" ? "refunded" : "paid";
  } else if (fulfillment === "delivered") {
    paymentStatus = "paid";
  }

  const createdAt = toIsoString(d.createdAt);
  const updatedAt = toIsoString(d.updatedAt, createdAt);
  const uid = String(d.userId ?? "");

  const timeline = Array.isArray(d.timeline) && d.timeline.length > 0
    ? (d.timeline as Array<{ status: FulfillmentStatus; at: string; by: string }>)
    : [
        { status: "pending" as FulfillmentStatus, at: createdAt, by: "Khách hàng" },
        ...(fulfillment !== "pending" ? [{ status: fulfillment, at: updatedAt, by: "Hệ thống" }] : []),
      ];

  return {
    id,
    code: String(d.orderCode ?? d.code ?? id.slice(0, 8).toUpperCase()),
    customerName: String(d.recipientName ?? d.customerName ?? "Khách hàng Floria"),
    customerEmail: String(d.customerEmail ?? userEmails.get(uid) ?? ""),
    phone: String(d.recipientPhone ?? d.phone ?? ""),
    address: String(d.shippingAddress ?? d.address ?? ""),
    createdAt,
    items,
    shippingFee: Number(d.shippingFee ?? 0),
    discount: Number(d.discount ?? 0),
    voucherCode: typeof d.voucherCode === "string" ? d.voucherCode : undefined,
    total: Number(d.totalAmount ?? d.total ?? 0),
    paymentMethod,
    paymentStatus,
    fulfillment,
    timeline,
    transaction:
      paymentMethod === "ZALOPAY"
        ? { id: String(d.zpTransToken ?? d.appTransId ?? `ZLP-${id.slice(0, 6).toUpperCase()}`), at: createdAt, sandbox: true }
        : undefined,
    notes: String(d.notes ?? d.paymentLabel ?? ""),
  };
}

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const db = getAdminDb();
    const [ordersSnap, usersSnap] = await Promise.all([
      db.collection("Orders").get(),
      db.collection("Users").get(),
    ]);

    const userEmails = new Map<string, string>();
    for (const doc of usersSnap.docs) {
      const email = doc.data().email;
      if (typeof email === "string" && email) userEmails.set(doc.id, email);
    }

    const orders = ordersSnap.docs
      .map((doc) => mapOrderDoc(doc.id, doc.data(), userEmails))
      .sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt));

    return NextResponse.json(orders);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải danh sách đơn hàng" }, { status: 500 });
  }
}
