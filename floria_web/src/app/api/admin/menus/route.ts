import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import {
  DEFAULT_ADMIN_MENU_SEED,
  DEFAULT_MOBILE_MENU_SEED,
  DEFAULT_WEB_USER_MENU_SEED,
  type MenuItemDoc,
  type MenuTarget,
} from "@/lib/server/menu-seed";

function mapMenuDoc(id: string, d: Record<string, unknown>): MenuItemDoc {
  const target: MenuTarget =
    d.target === "mobile_app" || d.target === "web_user" ? d.target : "admin_sidebar";
  return {
    id,
    target,
    parentId: typeof d.parentId === "string" && d.parentId.trim() ? d.parentId.trim() : null,
    title: String(d.title ?? ""),
    titleEn: String(d.titleEn ?? d.title ?? ""),
    route: String(d.route ?? ""),
    icon: typeof d.icon === "string" ? d.icon : "Menu",
    module: typeof d.module === "string" ? d.module : "",
    badgeKey: typeof d.badgeKey === "string" ? d.badgeKey : "",
    order: Number(d.order ?? 0),
    visible: d.visible !== false,
    updatedAt: toIsoString(d.updatedAt),
  };
}

async function ensureSeedIfEmpty() {
  const db = getAdminDb();
  const col = db.collection("MenuItems");
  const snap = await col.get();

  const existingIds = new Set(snap.docs.map((d) => d.id));
  const hasAdmin = snap.docs.some((d) => d.data().target === "admin_sidebar");
  const hasMobile = snap.docs.some((d) => d.data().target === "mobile_app");
  const hasWebUser = snap.docs.some((d) => d.data().target === "web_user");

  if (!hasAdmin || !hasMobile || !hasWebUser) {
    const now = new Date().toISOString();
    const batch = db.batch();
    if (!hasAdmin) {
      for (const item of DEFAULT_ADMIN_MENU_SEED) {
        if (!existingIds.has(item.id)) {
          batch.set(col.doc(item.id), { ...item, updatedAt: now });
        }
      }
    }
    if (!hasMobile) {
      for (const item of DEFAULT_MOBILE_MENU_SEED) {
        if (!existingIds.has(item.id)) {
          batch.set(col.doc(item.id), { ...item, updatedAt: now });
        }
      }
    }
    if (!hasWebUser) {
      for (const item of DEFAULT_WEB_USER_MENU_SEED) {
        if (!existingIds.has(item.id)) {
          batch.set(col.doc(item.id), { ...item, updatedAt: now });
        }
      }
    }
    await batch.commit();
    return col.get();
  }

  return snap;
}

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const url = new URL(req.url);
    const targetParam = url.searchParams.get("target");

    const snap = await ensureSeedIfEmpty();
    let list = snap.docs.map((doc) => mapMenuDoc(doc.id, doc.data()));

    if (targetParam === "admin_sidebar" || targetParam === "mobile_app" || targetParam === "web_user") {
      list = list.filter((item) => item.target === targetParam);
    }

    list.sort((a, b) => a.order - b.order);
    return NextResponse.json(list);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải danh sách menu" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    await verifyAdminRequest(req);
    const body = (await req.json()) as Partial<MenuItemDoc>;
    if (!body.title?.trim()) {
      return NextResponse.json({ error: "Vui lòng nhập tên menu" }, { status: 400 });
    }

    const target: MenuTarget =
      body.target === "mobile_app" || body.target === "web_user" ? body.target : "admin_sidebar";
    const docId = body.id?.trim() || `menu_${Date.now()}`;
    const payload: Omit<MenuItemDoc, "id"> = {
      target,
      parentId: body.parentId?.trim() || null,
      title: body.title.trim(),
      titleEn: body.titleEn?.trim() || body.title.trim(),
      route: body.route?.trim() || "",
      icon: typeof body.icon === "string" ? body.icon.trim() : "Menu",
      module: body.module?.trim() || "",
      badgeKey: body.badgeKey?.trim() || "",
      order: Number(body.order ?? 1),
      visible: body.visible !== false,
      updatedAt: new Date().toISOString(),
    };

    await getAdminDb().collection("MenuItems").doc(docId).set(payload, { merge: true });
    return NextResponse.json({ id: docId, ...payload }, { status: 201 });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tạo mục menu" }, { status: 500 });
  }
}
