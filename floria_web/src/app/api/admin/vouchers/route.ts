import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import type { Voucher } from "@/types";

export function mapVoucherDoc(id: string, d: Record<string, unknown>): Voucher {
  return {
    id,
    code: String(d.code ?? id).toUpperCase(),
    type: d.type === "fixed" || d.discountType === "fixed" ? "fixed" : "percent",
    value: Number(d.value ?? d.discountValue ?? 0),
    minOrder: Number(d.minOrder ?? d.minOrderAmount ?? 0),
    maxUsage: Number(d.maxUsage ?? 100),
    used: Number(d.used ?? 0),
    expiresAt: toIsoString(d.expiresAt ?? d.expiryDate),
    active: d.active !== false && d.isActive !== false,
  };
}

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const snap = await getAdminDb().collection("Vouchers").get();
    const list = snap.docs.map((doc) => mapVoucherDoc(doc.id, doc.data()));
    return NextResponse.json(list);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải danh sách voucher" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    await verifyAdminRequest(req);
    const body = (await req.json()) as Partial<Voucher>;
    const code = (body.code ?? "").trim().toUpperCase();
    if (!code) {
      return NextResponse.json({ error: "Thiếu mã voucher" }, { status: 400 });
    }
    const payload = {
      code,
      type: body.type === "fixed" ? "fixed" : "percent",
      discountType: body.type === "fixed" ? "fixed" : "percent",
      value: Number(body.value ?? 0),
      discountValue: Number(body.value ?? 0),
      minOrder: Number(body.minOrder ?? 0),
      minOrderAmount: Number(body.minOrder ?? 0),
      maxUsage: Number(body.maxUsage ?? 100),
      used: Number(body.used ?? 0),
      expiresAt: body.expiresAt ?? new Date(Date.now() + 30 * 86400000).toISOString(),
      active: body.active !== false,
      isActive: body.active !== false,
    };
    await getAdminDb().collection("Vouchers").doc(code).set(payload, { merge: true });
    return NextResponse.json(mapVoucherDoc(code, payload), { status: 201 });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tạo voucher" }, { status: 500 });
  }
}
