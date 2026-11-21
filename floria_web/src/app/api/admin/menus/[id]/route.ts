import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import type { MenuItemDoc } from "@/lib/server/menu-seed";

export async function PATCH(req: Request, context: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await context.params;
    const body = (await req.json()) as Partial<MenuItemDoc>;

    const patch: Record<string, unknown> = {
      updatedAt: new Date().toISOString(),
    };
    if (body.target !== undefined) patch.target = body.target;
    if (body.parentId !== undefined) patch.parentId = body.parentId ? body.parentId.trim() : null;
    if (body.title !== undefined) patch.title = body.title.trim();
    if (body.titleEn !== undefined) patch.titleEn = body.titleEn.trim();
    if (body.route !== undefined) patch.route = body.route.trim();
    if (body.icon !== undefined) patch.icon = body.icon.trim();
    if (body.module !== undefined) patch.module = body.module.trim();
    if (body.badgeKey !== undefined) patch.badgeKey = body.badgeKey.trim();
    if (body.order !== undefined) patch.order = Number(body.order);
    if (body.visible !== undefined) patch.visible = Boolean(body.visible);

    const ref = getAdminDb().collection("MenuItems").doc(id);
    await ref.set(patch, { merge: true });
    const updated = await ref.get();
    return NextResponse.json({ id, ...(updated.data() ?? patch) });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể cập nhật mục menu" }, { status: 500 });
  }
}

export async function DELETE(req: Request, context: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await context.params;
    const db = getAdminDb();
    const col = db.collection("MenuItems");

    // Xóa đệ quy các mục con nếu xóa mục cha
    const allSnap = await col.get();
    const toDelete = new Set<string>([id]);
    let changed = true;
    while (changed) {
      changed = false;
      for (const doc of allSnap.docs) {
        const pId = doc.data().parentId;
        if (typeof pId === "string" && toDelete.has(pId) && !toDelete.has(doc.id)) {
          toDelete.add(doc.id);
          changed = true;
        }
      }
    }

    const batch = db.batch();
    for (const delId of toDelete) {
      batch.delete(col.doc(delId));
    }
    await batch.commit();

    return NextResponse.json({ ok: true, deletedIds: Array.from(toDelete) });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể xóa mục menu" }, { status: 500 });
  }
}
