import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import type { InventoryTx } from "@/types";

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const snap = await getAdminDb().collection("InventoryTransactions").get();
    const list: InventoryTx[] = snap.docs
      .map((doc) => {
        const d = doc.data();
        const type: InventoryTx["type"] = d.type === "out" || d.type === "adjust" ? d.type : "in";
        return {
          id: doc.id,
          productId: String(d.productId ?? ""),
          productName: String(d.productName ?? "Sản phẩm"),
          type,
          qty: Number(d.qty ?? 0),
          note: String(d.note ?? d.reason ?? ""),
          by: String(d.by ?? "Quản trị viên"),
          at: toIsoString(d.at ?? d.createdAt),
        };
      })
      .sort((a, b) => Date.parse(b.at) - Date.parse(a.at));

    return NextResponse.json(list);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải lịch sử kho hàng" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    const admin = await verifyAdminRequest(req);
    const body = (await req.json()) as Partial<InventoryTx>;
    if (!body.productId || !body.qty) {
      return NextResponse.json({ error: "Thiếu thông tin sản phẩm hoặc số lượng" }, { status: 400 });
    }

    const db = getAdminDb();
    const now = new Date().toISOString();
    const txPayload: Omit<InventoryTx, "id"> = {
      productId: body.productId,
      productName: body.productName ?? "Sản phẩm",
      type: body.type === "out" || body.type === "adjust" ? body.type : "in",
      qty: Number(body.qty),
      note: body.note?.trim() || "Cập nhật tồn kho",
      by: body.by ?? admin.name,
      at: body.at ?? now,
    };

    const docRef = await db.collection("InventoryTransactions").add(txPayload);
    return NextResponse.json({ id: docRef.id, ...txPayload }, { status: 201 });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể lưu giao dịch kho" }, { status: 500 });
  }
}
