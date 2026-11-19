import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { mapArticleDoc, mapBlocksToFirestore } from "../route";
import type { Article } from "@/types";

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    const docId = decodeURIComponent(id);
    const patch = (await req.json()) as Partial<Article>;

    const update: Record<string, unknown> = { updatedAt: new Date().toISOString() };
    if (patch.title !== undefined) update.title = patch.title;
    if (patch.category !== undefined) update.category = patch.category;
    if (patch.cover !== undefined) update.coverImage = patch.cover;
    if (patch.excerpt !== undefined) update.summary = patch.excerpt;
    if (patch.author !== undefined) update.author = patch.author;
    if (patch.status !== undefined) update.status = patch.status;
    if (patch.blocks !== undefined) update.blocks = mapBlocksToFirestore(patch.blocks);

    const ref = getAdminDb().collection("PlantHandbook").doc(docId);
    await ref.set(update, { merge: true });
    const doc = await ref.get();
    return NextResponse.json(mapArticleDoc(doc.id, doc.data() ?? {}));
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể cập nhật bài viết" }, { status: 500 });
  }
}

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    await getAdminDb().collection("PlantHandbook").doc(decodeURIComponent(id)).delete();
    return NextResponse.json({ ok: true });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể xoá bài viết" }, { status: 500 });
  }
}
