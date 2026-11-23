import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import type { WeatherRule } from "@/types";

export function mapWeatherRuleDoc(id: string, d: Record<string, unknown>): WeatherRule {
  const condType = (d.conditionType as WeatherRule["conditionType"]) ?? "temperature_high";
  const name = String(d.title ?? d.name ?? id);
  const advice = String(d.advice ?? d.tip ?? "");
  const badgeText = String(d.badgeText ?? "Cảnh báo vi khí hậu");

  // Map sang legacy condition cho tương thích
  let legacyCond: WeatherRule["condition"] = "sunny";
  if (condType === "rain") legacyCond = "rain";
  else if (condType === "temperature_high") legacyCond = "hot";
  else if (condType === "temperature_low") legacyCond = "cold";
  else if (condType === "humidity_high") legacyCond = "humid";

  return {
    id,
    name,
    title: name,
    badgeText,
    advice,
    tip: advice,
    conditionType: condType,
    condition: legacyCond,
    minTemp: typeof d.minTemp === "number" ? d.minTemp : null,
    maxTemp: typeof d.maxTemp === "number" ? d.maxTemp : null,
    tempMin: typeof d.minTemp === "number" ? d.minTemp : 0,
    tempMax: typeof d.maxTemp === "number" ? d.maxTemp : 40,
    minHumidity: typeof d.minHumidity === "number" ? d.minHumidity : null,
    maxHumidity: typeof d.maxHumidity === "number" ? d.maxHumidity : null,
    humidityMin: typeof d.minHumidity === "number" ? d.minHumidity : 0,
    humidityMax: typeof d.maxHumidity === "number" ? d.maxHumidity : 100,
    weatherCodes: Array.isArray(d.weatherCodes) ? (d.weatherCodes as number[]) : [],
    minWindSpeed: typeof d.minWindSpeed === "number" ? d.minWindSpeed : null,
    iconName: String(d.iconName ?? "thermostat"),
    active: d.active !== false,
    priority: typeof d.priority === "number" ? d.priority : 50,
    order: typeof d.order === "number" ? d.order : 0,
  };
}

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const snap = await getAdminDb().collection("WeatherAdviceRules").get();
    const list: WeatherRule[] = snap.docs
      .map((doc) => mapWeatherRuleDoc(doc.id, doc.data()))
      .sort((a, b) => (b.priority ?? 0) - (a.priority ?? 0));
    return NextResponse.json(list);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải quy tắc vi khí hậu" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    await verifyAdminRequest(req);
    const body = (await req.json()) as Partial<WeatherRule>;
    const docId = body.id?.trim() || `rule_${Date.now()}`;

    const payload = {
      id: docId,
      title: body.title?.trim() || body.name?.trim() || "Quy tắc mới",
      badgeText: body.badgeText?.trim() || "Khuyến nghị vi khí hậu",
      advice: body.advice?.trim() || body.tip?.trim() || "",
      conditionType: body.conditionType || "temperature_high",
      minTemp: body.minTemp !== undefined ? body.minTemp : null,
      maxTemp: body.maxTemp !== undefined ? body.maxTemp : null,
      minHumidity: body.minHumidity !== undefined ? body.minHumidity : null,
      maxHumidity: body.maxHumidity !== undefined ? body.maxHumidity : null,
      weatherCodes: Array.isArray(body.weatherCodes) ? body.weatherCodes : [],
      minWindSpeed: body.minWindSpeed !== undefined ? body.minWindSpeed : null,
      iconName: body.iconName || "thermostat",
      active: body.active !== false,
      priority: Number(body.priority ?? 50),
      order: Number(body.order ?? 0),
      updatedAt: new Date().toISOString(),
    };

    await getAdminDb().collection("WeatherAdviceRules").doc(docId).set(payload, { merge: true });
    return NextResponse.json(mapWeatherRuleDoc(docId, payload), { status: 201 });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tạo quy tắc vi khí hậu" }, { status: 500 });
  }
}
