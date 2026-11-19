import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import type { Product } from "@/types";

function categoryToKey(cat: string): string {
  const s = cat.toLowerCase();
  if (s.includes("dụng cụ")) return "tools";
  if (s.includes("phân") || s.includes("dưỡng")) return "fertilizer";
  if (s.includes("đất") || s.includes("giá thể")) return "soil";
  if (s.includes("thuốc") || s.includes("bảo vệ") || s.includes("sinh học")) return "medicine";
  if (s.includes("chậu")) return "pots";
  return "other";
}

export function mapProductDoc(id: string, d: Record<string, unknown>): Product {
  const inStock = d.inStock !== false;
  const stock = typeof d.stock === "number" ? d.stock : inStock ? 25 : 0;

  return {
    id,
    name: String(d.name ?? "Sản phẩm Floria"),
    sku: String(d.sku ?? id.toUpperCase()),
    category: String(d.category ?? "Dụng cụ"),
    image: String(d.imageUrl ?? d.image ?? ""),
    originalPrice: Number(d.originalPrice ?? d.price ?? 0),
    price: Number(d.price ?? 0),
    stock,
    lowStockThreshold: Number(d.lowStockThreshold ?? 5),
    visible: d.visible !== false,
    sold: Number(d.soldCount ?? d.sold ?? 0),
    rating: Number(d.rating ?? 5),
    shortDesc: String(d.shortDesc ?? ""),
    description: String(d.description ?? d.shortDesc ?? ""),
    usageGuide: String(d.usageGuide ?? ""),
    indications: Array.isArray(d.indications) ? d.indications.map((x) => String(x)) : [],
    tag: String(d.tag ?? ""),
    updatedAt: toIsoString(d.updatedAt),
  };
}

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const snap = await getAdminDb().collection("ShopProducts").get();
    const products = snap.docs
      .map((doc) => mapProductDoc(doc.id, doc.data()))
      .sort((a, b) => a.name.localeCompare(b.name, "vi"));
    return NextResponse.json(products);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải danh sách sản phẩm" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    await verifyAdminRequest(req);
    const body = (await req.json()) as Partial<Product>;
    if (!body.name?.trim()) {
      return NextResponse.json({ error: "Thiếu tên sản phẩm" }, { status: 400 });
    }
    const docId =
      body.id?.trim() ||
      body.name
        .toLowerCase()
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "")
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-|-$/g, "");

    const stock = Number(body.stock ?? 20);
    const category = body.category?.trim() || "Dụng cụ";
    const now = new Date().toISOString();

    const payload = {
      id: docId,
      name: body.name.trim(),
      sku: body.sku?.trim() || docId.toUpperCase(),
      category,
      categoryKey: categoryToKey(category),
      imageUrl: body.image?.trim() || "",
      originalPrice: Number(body.originalPrice ?? body.price ?? 0),
      price: Number(body.price ?? 0),
      stock,
      lowStockThreshold: Number(body.lowStockThreshold ?? 5),
      inStock: stock > 0,
      visible: body.visible !== false,
      soldCount: Number(body.sold ?? 0),
      rating: Number(body.rating ?? 5),
      shortDesc: body.shortDesc?.trim() || (body.description?.trim() || "").slice(0, 120),
      description: body.description?.trim() || "",
      usageGuide: body.usageGuide?.trim() || "",
      indications: body.indications ?? [],
      tag: body.tag?.trim() || "",
      updatedAt: now,
    };

    await getAdminDb().collection("ShopProducts").doc(docId).set(payload, { merge: true });
    return NextResponse.json(mapProductDoc(docId, payload), { status: 201 });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tạo sản phẩm" }, { status: 500 });
  }
}
