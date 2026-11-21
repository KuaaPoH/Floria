import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import type { SupportArticle } from "../route";

export async function PATCH(req: Request, context: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await context.params;
    const body = (await req.json()) as Partial<SupportArticle>;

    const patch: Record<string, unknown> = {
      updatedAt: new Date().toISOString(),
    };
    if (body.category !== undefined) patch.category = body.category.trim();
    if (body.categoryVi !== undefined) patch.categoryVi = body.categoryVi.trim();
    if (body.categoryEn !== undefined) patch.categoryEn = body.categoryEn.trim();
    if (body.questionVi !== undefined) patch.questionVi = body.questionVi.trim();
    if (body.questionEn !== undefined) patch.questionEn = body.questionEn.trim();
    if (body.answerVi !== undefined) patch.answerVi = body.answerVi.trim();
    if (body.answerEn !== undefined) patch.answerEn = body.answerEn.trim();
    if (body.order !== undefined) patch.order = Number(body.order);
    if (body.visible !== undefined) patch.visible = Boolean(body.visible);

    const ref = getAdminDb().collection("SupportArticles").doc(id);
    await ref.set(patch, { merge: true });
    const updated = await ref.get();
    return NextResponse.json({ id, ...(updated.data() ?? patch) });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể cập nhật bài viết hỗ trợ" }, { status: 500 });
  }
}

export async function DELETE(req: Request, context: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await context.params;
    await getAdminDb().collection("SupportArticles").doc(id).delete();
    return NextResponse.json({ ok: true, id });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể xóa bài viết hỗ trợ" }, { status: 500 });
  }
}
