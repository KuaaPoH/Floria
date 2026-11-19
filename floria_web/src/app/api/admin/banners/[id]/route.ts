import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { mapWidgetToBanner } from "../route";
import type { Banner } from "@/types";

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    const patch = (await req.json()) as Partial<Banner>;

    const update: Record<string, unknown> = { updatedAt: new Date().toISOString() };
    if (patch.title !== undefined) update.mainTitle = patch.title;
    if (patch.subtitle !== undefined) update.advice = patch.subtitle;
    if (patch.cta !== undefined) update.badgeText = patch.cta;
    if (patch.image !== undefined) update.heroImageUrl = patch.image;
    if (patch.active !== undefined) update.active = patch.active;
    if (patch.order !== undefined) update.order = patch.order;
    if (typeof patch.startHour === "number") update.startHour = patch.startHour;
    if (typeof patch.endHour === "number") update.endHour = patch.endHour;
    if (patch.startHour === undefined && patch.endHour === undefined && patch.deepLink !== undefined) {
      const hourMatch = patch.deepLink.match(/(\d{1,2})\s*:\s*00\s*[–-]\s*(\d{1,2})/);
      if (hourMatch) {
        update.startHour = Number(hourMatch[1]);
        update.endHour = Number(hourMatch[2]);
      }
    }

    const ref = getAdminDb().collection("HomeWeatherWidgets").doc(decodeURIComponent(id));
    await ref.set(update, { merge: true });
    const doc = await ref.get();
    return NextResponse.json(mapWidgetToBanner(doc.id, doc.data() ?? {}));
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể cập nhật banner" }, { status: 500 });
  }
}

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    await getAdminDb().collection("HomeWeatherWidgets").doc(decodeURIComponent(id)).delete();
    return NextResponse.json({ ok: true });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể xoá banner" }, { status: 500 });
  }
}
