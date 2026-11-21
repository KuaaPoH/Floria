import { NextResponse } from "next/server";
import { AdminAuthError, invalidateAdminCache, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminAuth, getAdminDb } from "@/lib/server/firebase-admin";
import type { AdminAccount, RoleId } from "@/types";

export async function PATCH(req: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const current = await verifyAdminRequest(req);
    if (current.role !== "super_admin") {
      return NextResponse.json({ error: "Chỉ Super Admin mới được chỉnh sửa quyền quản trị" }, { status: 403 });
    }

    const { id } = await context.params;
    const body = (await req.json()) as Partial<AdminAccount>;

    const patch: Record<string, unknown> = {
      updatedAt: new Date().toISOString(),
    };
    if (body.name !== undefined) patch.name = body.name.trim();
    if (body.role !== undefined) {
      const role: RoleId =
        body.role === "super_admin" || body.role === "botanist" || body.role === "operations"
          ? body.role
          : "operations";
      patch.role = role;
    }
    if (body.status !== undefined) {
      const isActive = body.status === "active";
      patch.status = isActive ? "active" : "disabled";
      patch.active = isActive;
      try {
        await getAdminAuth().updateUser(id, { disabled: !isActive });
      } catch {
        // Bỏ qua nếu doc id không trùng uid Auth
      }
    }

    const ref = getAdminDb().collection("AdminAccounts").doc(id);
    await ref.set(patch, { merge: true });
    invalidateAdminCache();

    const snap = await ref.get();
    return NextResponse.json({ id, ...(snap.data() ?? patch) });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể cập nhật tài khoản quản trị" }, { status: 500 });
  }
}

export async function DELETE(req: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const current = await verifyAdminRequest(req);
    if (current.role !== "super_admin") {
      return NextResponse.json({ error: "Chỉ Super Admin mới được xóa tài khoản quản trị" }, { status: 403 });
    }

    const { id } = await context.params;
    if (id === current.id) {
      return NextResponse.json({ error: "Không thể tự xóa tài khoản đang đăng nhập" }, { status: 400 });
    }

    await getAdminDb().collection("AdminAccounts").doc(id).delete();
    invalidateAdminCache();
    return NextResponse.json({ ok: true, id });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể xóa tài khoản quản trị" }, { status: 500 });
  }
}
