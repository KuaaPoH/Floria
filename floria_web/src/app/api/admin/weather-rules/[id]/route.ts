import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { mapWeatherDoc } from "../route";
import type { WeatherRule } from "@/types";

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    const docId = decodeURIComponent(id);
    const patch = (await req.json()) as Partial<WeatherRule>;

    const update: Record<string, unknown> = { updatedAt: new Date().toISOString() };
    if (patch.name !== undefined) update.badgeText = patch.name;
    if (patch.tip !== undefined) update.advice = patch.tip;
    if (patch.active !== undefined) update.active = patch.active;
    if (patch.condition !== undefined) update.condition = patch.condition;

    const ref = getAdminDb().collection("HomeWeatherWidgets").doc(docId);
    await ref.set(update, { merge: true });
    const doc = await ref.get();
    return NextResponse.json(mapWeatherDoc(doc.id, doc.data() ?? {}));
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể cập nhật quy tắc thời tiết" }, { status: 500 });
  }
}
