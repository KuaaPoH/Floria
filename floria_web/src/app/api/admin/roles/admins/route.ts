import { NextResponse } from "next/server";
import { AdminAuthError, invalidateAdminCache, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminAuth, getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import type { AdminAccount, RoleId } from "@/types";

function mapAdminDoc(id: string, d: Record<string, unknown>): AdminAccount {
  const rawRole = String(d.role ?? "operations").toLowerCase();
  const role: RoleId =
    rawRole === "super_admin" || rawRole === "admin"
      ? "super_admin"
      : rawRole === "botanist"
        ? "botanist"
        : "operations";
  const isActive = d.active !== false && d.status !== "disabled";
  return {
    id,
    name: String(d.name ?? (typeof d.email === "string" ? d.email.split("@")[0] : "Quản trị viên")),
    email: String(d.email ?? ""),
    role,
    avatar: typeof d.avatar === "string" && d.avatar.trim() ? d.avatar.trim() : undefined,
    status: isActive ? "active" : "disabled",
    lastLogin: toIsoString(d.lastLogin ?? d.updatedAt ?? d.createdAt),
    twoFA: false,
  };
}

export async function GET(req: Request) {
  try {
    const current = await verifyAdminRequest(req);
    const db = getAdminDb();
    const snap = await db.collection("AdminAccounts").get();
    const list = snap.docs.map((doc) => mapAdminDoc(doc.id, doc.data()));

    if (current.email && !list.some((a) => a.id === current.id || a.email.toLowerCase() === current.email.toLowerCase())) {
      list.unshift({
        id: current.id,
        name: current.name,
        email: current.email,
        role: current.role,
        avatar: current.avatar,
        status: "active",
        lastLogin: new Date().toISOString(),
        twoFA: false,
      });
    }

    list.sort((a, b) => Date.parse(b.lastLogin) - Date.parse(a.lastLogin));
    return NextResponse.json(list);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải danh sách quản trị viên" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    const current = await verifyAdminRequest(req);
    if (current.role !== "super_admin") {
      return NextResponse.json({ error: "Chỉ Super Admin mới được thêm tài khoản quản trị" }, { status: 403 });
    }

    const body = (await req.json()) as Partial<AdminAccount> & { password?: string };
    const email = (body.email ?? "").trim().toLowerCase();
    const name = (body.name ?? "").trim();
    const password = (body.password ?? "").trim();

    if (!name || !email.includes("@")) {
      return NextResponse.json({ error: "Vui lòng nhập họ tên và email hợp lệ" }, { status: 400 });
    }

    const role: RoleId =
      body.role === "super_admin" || body.role === "botanist" || body.role === "operations"
        ? body.role
        : "operations";

    const auth = getAdminAuth();
    let uid: string;

    try {
      const existingUser = await auth.getUserByEmail(email);
      uid = existingUser.uid;
      if (password) {
        if (password.length < 6) {
          return NextResponse.json({ error: "Mật khẩu phải có ít nhất 6 ký tự" }, { status: 400 });
        }
        await auth.updateUser(uid, { password, displayName: name, disabled: body.status === "disabled" });
      } else {
        await auth.updateUser(uid, { displayName: name, disabled: body.status === "disabled" });
      }
    } catch (authErr: unknown) {
      const code = (authErr as { code?: string })?.code;
      if (code === "auth/user-not-found") {
        if (password.length < 6) {
          return NextResponse.json({ error: "Vui lòng nhập mật khẩu (tối thiểu 6 ký tự) để tạo tài khoản mới" }, { status: 400 });
        }
        const created = await auth.createUser({
          email,
          password,
          displayName: name,
          disabled: body.status === "disabled",
        });
        uid = created.uid;
      } else {
        throw authErr;
      }
    }

    const db = getAdminDb();
    const now = new Date().toISOString();
    const docPayload = {
      name,
      email,
      role,
      active: body.status !== "disabled",
      status: body.status === "disabled" ? "disabled" : "active",
      lastLogin: now,
      updatedAt: now,
    };

    await db.collection("AdminAccounts").doc(uid).set(docPayload, { merge: true });
    invalidateAdminCache();

    return NextResponse.json(mapAdminDoc(uid, docPayload), { status: 201 });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const msg = err instanceof Error ? err.message : "Không thể thêm tài khoản quản trị";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
