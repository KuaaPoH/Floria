import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { mapVoucherDoc } from "../route";
import type { Voucher } from "@/types";

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    const docId = decodeURIComponent(id);
    const patch = (await req.json()) as Partial<Voucher>;

    const update: Record<string, unknown> = {};
    if (patch.code !== undefined) update.code = patch.code.toUpperCase();
    if (patch.type !== undefined) {
      update.type = patch.type;
      update.discountType = patch.type;
    }
    if (patch.value !== undefined) {
      update.value = patch.value;
      update.discountValue = patch.value;
    }
    if (patch.minOrder !== undefined) {
      update.minOrder = patch.minOrder;
      update.minOrderAmount = patch.minOrder;
    }
    if (patch.maxUsage !== undefined) update.maxUsage = patch.maxUsage;
    if (patch.expiresAt !== undefined) update.expiresAt = patch.expiresAt;
    if (patch.active !== undefined) {
      update.active = patch.active;
      update.isActive = patch.active;
    }

    const ref = getAdminDb().collection("Vouchers").doc(docId);
    await ref.set(update, { merge: true });
    const doc = await ref.get();
    return NextResponse.json(mapVoucherDoc(doc.id, doc.data() ?? {}));
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể cập nhật voucher" }, { status: 500 });
  }
}

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    await getAdminDb().collection("Vouchers").doc(decodeURIComponent(id)).delete();
    return NextResponse.json({ ok: true });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể xoá voucher" }, { status: 500 });
  }
}
