import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import type { ProductReview } from "@/types";

export function mapReviewDoc(
  id: string,
  d: Record<string, unknown>,
  userNames: Map<string, string>,
): ProductReview {
  const uid = String(d.userId ?? "");
  const rawStatus = String(d.status ?? "approved");
  const status: ProductReview["status"] =
    rawStatus === "pending" || rawStatus === "approved" || rawStatus === "hidden" || rawStatus === "rejected"
      ? rawStatus
      : "approved";

  const rawImages = Array.isArray(d.images) ? d.images : Array.isArray(d.reviewImages) ? d.reviewImages : [];
  const images = rawImages.map((x) => String(x).trim()).filter(Boolean);

  return {
    id,
    productId: String(d.productId ?? ""),
    productName: String(d.productName ?? "Sản phẩm Floria"),
    customer: String(d.userName ?? d.customer ?? userNames.get(uid) ?? "Khách hàng"),
    rating: Number(d.rating ?? 5),
    content: String(d.comment ?? d.content ?? ""),
    images,
    createdAt: toIsoString(d.createdAt),
    status,
    reply: typeof d.reply === "string" && d.reply.trim() ? d.reply : undefined,
  };
}

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const db = getAdminDb();
    const [revSnap, usersSnap] = await Promise.all([
      db.collection("ProductReviews").get(),
      db.collection("Users").get(),
    ]);

    const userNames = new Map<string, string>();
    for (const doc of usersSnap.docs) {
      const name = doc.data().displayName;
      if (typeof name === "string" && name.trim()) userNames.set(doc.id, name.trim());
    }

    const reviews = revSnap.docs
      .map((doc) => mapReviewDoc(doc.id, doc.data(), userNames))
      .sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt));

    return NextResponse.json(reviews);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải danh sách đánh giá" }, { status: 500 });
  }
}
