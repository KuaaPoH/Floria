import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { mapProductDoc } from "../route";
import type { Product } from "@/types";

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    const docId = decodeURIComponent(id);
    const patch = (await req.json()) as Partial<Product>;

    const update: Record<string, unknown> = { updatedAt: new Date().toISOString() };
    if (patch.name !== undefined) update.name = patch.name;
    if (patch.sku !== undefined) update.sku = patch.sku;
    if (patch.category !== undefined) update.category = patch.category;
    if (patch.image !== undefined) update.imageUrl = patch.image;
    if (patch.originalPrice !== undefined) update.originalPrice = patch.originalPrice;
    if (patch.price !== undefined) update.price = patch.price;
    if (patch.stock !== undefined) {
      update.stock = patch.stock;
      update.inStock = patch.stock > 0;
    }
    if (patch.lowStockThreshold !== undefined) update.lowStockThreshold = patch.lowStockThreshold;
    if (patch.visible !== undefined) update.visible = patch.visible;
    if (patch.shortDesc !== undefined) update.shortDesc = patch.shortDesc;
    if (patch.description !== undefined) update.description = patch.description;
    if (patch.usageGuide !== undefined) update.usageGuide = patch.usageGuide;
    if (patch.indications !== undefined) update.indications = patch.indications;
    if (patch.tag !== undefined) update.tag = patch.tag;

    const ref = getAdminDb().collection("ShopProducts").doc(docId);
    await ref.set(update, { merge: true });
    const doc = await ref.get();
    return NextResponse.json(mapProductDoc(doc.id, doc.data() ?? {}));
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể cập nhật sản phẩm" }, { status: 500 });
  }
}

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    await getAdminDb().collection("ShopProducts").doc(decodeURIComponent(id)).delete();
    return NextResponse.json({ ok: true });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể xoá sản phẩm" }, { status: 500 });
  }
}
