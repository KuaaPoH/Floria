import { NextResponse } from "next/server";
import { AdminAuthError, invalidateAdminCache, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminAuth, getAdminDb } from "@/lib/server/firebase-admin";

export async function PATCH(req: Request) {
  try {
    const current = await verifyAdminRequest(req);
    const body = (await req.json()) as { name?: string; avatar?: string };

    const name = body.name?.trim();
    const avatar = body.avatar !== undefined ? body.avatar.trim() : undefined;

    if (name !== undefined && !name) {
      return NextResponse.json({ error: "Họ và tên không được để trống" }, { status: 400 });
    }

    const db = getAdminDb();
    const patch: Record<string, unknown> = {
      updatedAt: new Date().toISOString(),
    };
    if (name !== undefined) patch.name = name;
    if (avatar !== undefined) patch.avatar = avatar;

    // Cập nhật doc trong AdminAccounts theo uid (hoặc tìm theo email nếu doc id khác uid)
    const byUidRef = db.collection("AdminAccounts").doc(current.id);
    const byUidSnap = await byUidRef.get();
    if (byUidSnap.exists) {
      await byUidRef.set(patch, { merge: true });
    } else if (current.email) {
      const byEmail = await db.collection("AdminAccounts").where("email", "==", current.email).limit(1).get();
      if (!byEmail.empty) {
        await byEmail.docs[0].ref.set(patch, { merge: true });
      } else {
        await byUidRef.set(
          {
            name: name ?? current.name,
            email: current.email,
            role: current.role,
            active: true,
            status: "active",
            ...patch,
          },
          { merge: true },
        );
      }
    }

    // Đồng bộ sang Firebase Authentication
    try {
      const authPatch: { displayName?: string; photoURL?: string | null } = {};
      if (name !== undefined) authPatch.displayName = name;
      if (avatar !== undefined) authPatch.photoURL = avatar || null;
      if (Object.keys(authPatch).length > 0) {
        await getAdminAuth().updateUser(current.id, authPatch);
      }
    } catch {
      // Bỏ qua nếu không cập nhật được photoURL do định dạng
    }

    invalidateAdminCache(current.id);

    return NextResponse.json({
      id: current.id,
      name: name ?? current.name,
      email: current.email,
      role: current.role,
      avatar: avatar !== undefined ? avatar : current.avatar,
    });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể cập nhật hồ sơ quản trị" }, { status: 500 });
  }
}
