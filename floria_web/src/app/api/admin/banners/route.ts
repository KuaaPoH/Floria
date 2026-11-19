import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import type { Banner } from "@/types";

export function mapWidgetToBanner(id: string, d: Record<string, unknown>): Banner {
  const startHour = typeof d.startHour === "number" ? d.startHour : 0;
  const endHour = typeof d.endHour === "number" ? d.endHour : 23;
  const updatedAt = toIsoString(d.updatedAt);

  return {
    id,
    title: String(d.mainTitle ?? d.title ?? "Banner Floria").replace(/\n/g, " "),
    subtitle: String(d.advice ?? d.subtitle ?? ""),
    cta: String(d.badgeText ?? d.cta ?? "Khung giờ"),
    deepLink: `${String(startHour).padStart(2, "0")}:00 – ${String(endHour).padStart(2, "0")}:00`,
    image: String(d.heroImageUrl ?? d.image ?? d.imageUrl ?? ""),
    startHour,
    endHour,
    startDate: String(d.startDate ?? updatedAt.slice(0, 10)),
    endDate: String(d.endDate ?? new Date(Date.now() + 365 * 86400000).toISOString().slice(0, 10)),
    active: d.active !== false,
    order: typeof d.order === "number" ? d.order : startHour,
  };
}

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const snap = await getAdminDb().collection("HomeWeatherWidgets").get();
    const list: Banner[] = snap.docs
      .map((doc) => mapWidgetToBanner(doc.id, doc.data()))
      .sort((a, b) => a.order - b.order);
    return NextResponse.json(list);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải banner trang chủ" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    await verifyAdminRequest(req);
    const body = (await req.json()) as Partial<Banner>;
    const docId = body.id?.trim() || `widget_${Date.now()}`;
    const hourMatch = (body.deepLink ?? "").match(/(\d{1,2})\s*:\s*00\s*[–-]\s*(\d{1,2})/);
    const startHour = typeof body.startHour === "number" ? body.startHour : hourMatch ? Number(hourMatch[1]) : Number(body.order ?? 6);
    const endHour = typeof body.endHour === "number" ? body.endHour : hourMatch ? Number(hourMatch[2]) : Math.min(23, startHour + 4);

    const payload = {
      id: docId,
      mainTitle: body.title?.trim() || "Banner mới",
      advice: body.subtitle?.trim() || "",
      badgeText: body.cta?.trim() || "Khung giờ",
      heroImageUrl: body.image?.trim() || "",
      startHour,
      endHour,
      active: body.active !== false,
      order: Number(body.order ?? startHour),
      updatedAt: new Date().toISOString(),
    };
    await getAdminDb().collection("HomeWeatherWidgets").doc(docId).set(payload, { merge: true });
    return NextResponse.json(mapWidgetToBanner(docId, payload), { status: 201 });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tạo banner" }, { status: 500 });
  }
}
