import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { mapOrderDoc } from "../route";
import type { Order } from "@/types";

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    const docId = decodeURIComponent(id);
    const patch = (await req.json()) as Partial<Order>;

    const update: Record<string, unknown> = { updatedAt: new Date().toISOString() };
    if (patch.fulfillment !== undefined) {
      // Đồng bộ trạng thái "completed" cho floria_app khi admin đánh dấu "delivered"
      update.status = patch.fulfillment === "delivered" ? "completed" : patch.fulfillment;
    }
    if (patch.paymentStatus !== undefined) update.paymentStatus = patch.paymentStatus;
    if (patch.timeline !== undefined) update.timeline = patch.timeline;
    if (patch.notes !== undefined) update.notes = patch.notes;

    const ref = getAdminDb().collection("Orders").doc(docId);
    await ref.set(update, { merge: true });
    const doc = await ref.get();
    return NextResponse.json(mapOrderDoc(doc.id, doc.data() ?? {}, new Map()));
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể cập nhật đơn hàng" }, { status: 500 });
  }
}
