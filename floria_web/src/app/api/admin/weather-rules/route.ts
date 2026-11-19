import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import type { WeatherRule } from "@/types";

function mapCondition(id: string, raw?: unknown): WeatherRule["condition"] {
  const s = String(raw ?? id).toLowerCase();
  if (s === "rain" || s === "sunny" || s === "humid" || s === "cold" || s === "hot") return s;
  if (s.includes("noon")) return "hot";
  if (s.includes("evening")) return "humid";
  return "sunny";
}

export function mapWeatherDoc(id: string, d: Record<string, unknown>): WeatherRule {
  return {
    id,
    name: String(d.badgeText ?? d.name ?? id),
    condition: mapCondition(id, d.condition),
    tempMin: Number(d.startHour ?? d.tempMin ?? 0),
    tempMax: Number(d.endHour ?? d.tempMax ?? 23),
    humidityMin: Number(d.humidityMin ?? 40),
    humidityMax: Number(d.humidityMax ?? 80),
    tip: String(d.advice ?? d.tip ?? ""),
    active: d.active !== false,
  };
}

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const snap = await getAdminDb().collection("HomeWeatherWidgets").get();
    const list = snap.docs.map((doc) => mapWeatherDoc(doc.id, doc.data()));
    return NextResponse.json(list);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải cấu hình thời tiết" }, { status: 500 });
  }
}
