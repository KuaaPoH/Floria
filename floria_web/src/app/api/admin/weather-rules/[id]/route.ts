import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { mapWeatherRuleDoc } from "../route";
import type { WeatherRule } from "@/types";

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    const docId = decodeURIComponent(id);
    const patch = (await req.json()) as Partial<WeatherRule>;

    const update: Record<string, unknown> = { updatedAt: new Date().toISOString() };
    if (patch.title !== undefined) update.title = patch.title;
    if (patch.name !== undefined) update.title = patch.name;
    if (patch.badgeText !== undefined) update.badgeText = patch.badgeText;
    if (patch.advice !== undefined) update.advice = patch.advice;
    if (patch.tip !== undefined) update.advice = patch.tip;
    if (patch.conditionType !== undefined) update.conditionType = patch.conditionType;
    if (patch.minTemp !== undefined) update.minTemp = patch.minTemp;
    if (patch.maxTemp !== undefined) update.maxTemp = patch.maxTemp;
    if (patch.minHumidity !== undefined) update.minHumidity = patch.minHumidity;
    if (patch.maxHumidity !== undefined) update.maxHumidity = patch.maxHumidity;
    if (patch.weatherCodes !== undefined) update.weatherCodes = patch.weatherCodes;
    if (patch.minWindSpeed !== undefined) update.minWindSpeed = patch.minWindSpeed;
    if (patch.iconName !== undefined) update.iconName = patch.iconName;
    if (patch.priority !== undefined) update.priority = patch.priority;
    if (patch.active !== undefined) update.active = patch.active;
    if (patch.order !== undefined) update.order = patch.order;

    const ref = getAdminDb().collection("WeatherAdviceRules").doc(docId);
    await ref.set(update, { merge: true });
    const doc = await ref.get();
    return NextResponse.json(mapWeatherRuleDoc(doc.id, doc.data() ?? {}));
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể cập nhật quy tắc vi khí hậu" }, { status: 500 });
  }
}

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await verifyAdminRequest(req);
    const { id } = await params;
    const docId = decodeURIComponent(id);

    await getAdminDb().collection("WeatherAdviceRules").doc(docId).delete();
    return NextResponse.json({ success: true, id: docId });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể xóa quy tắc vi khí hậu" }, { status: 500 });
  }
}
