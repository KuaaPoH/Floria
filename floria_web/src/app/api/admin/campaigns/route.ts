import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import type { AudienceKind, Campaign } from "@/types";

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const snap = await getAdminDb().collection("NotificationCampaigns").get();
    const list: Campaign[] = snap.docs
      .map((doc) => {
        const d = doc.data();
        const status: Campaign["status"] =
          d.status === "sent" || d.status === "scheduled" || d.status === "draft" || d.status === "failed"
            ? d.status
            : "draft";
        const audience: AudienceKind =
          d.audience === "active" ||
          d.audience === "inactive" ||
          d.audience === "species" ||
          d.audience === "diagnosed" ||
          d.audience === "custom"
            ? d.audience
            : "all";
        return {
          id: doc.id,
          name: String(d.name ?? d.title ?? "Chiến dịch"),
          title: String(d.title ?? "Thông báo"),
          body: String(d.body ?? ""),
          image: String(d.image ?? ""),
          deepLink: String(d.deepLink ?? ""),
          audience,
          audienceDetail: String(d.audienceDetail ?? "Tất cả người dùng"),
          scheduledAt: toIsoString(d.scheduledAt),
          status,
          targeted: Number(d.targeted ?? 0),
          success: Number(d.success ?? 0),
          failed: Number(d.failed ?? 0),
          opened: Number(d.opened ?? 0),
        };
      })
      .sort((a, b) => Date.parse(b.scheduledAt) - Date.parse(a.scheduledAt));
    return NextResponse.json(list);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải danh sách thông báo" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    await verifyAdminRequest(req);
    const body = (await req.json()) as Partial<Campaign>;
    const docId = body.id?.trim() || `cmp_${Date.now()}`;
    const payload: Omit<Campaign, "id"> = {
      name: body.name?.trim() || body.title?.trim() || "Chiến dịch mới",
      title: body.title?.trim() || "Thông báo mới",
      body: body.body?.trim() || "",
      image: body.image?.trim() || "",
      deepLink: body.deepLink ?? "",
      audience: body.audience ?? "all",
      audienceDetail: body.audienceDetail ?? "Tất cả người dùng",
      scheduledAt: body.scheduledAt ?? new Date().toISOString(),
      status: body.status ?? "draft",
      targeted: Number(body.targeted ?? 0),
      success: Number(body.success ?? 0),
      failed: Number(body.failed ?? 0),
      opened: Number(body.opened ?? 0),
    };
    await getAdminDb().collection("NotificationCampaigns").doc(docId).set(payload, { merge: true });
    return NextResponse.json({ id: docId, ...payload }, { status: 201 });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tạo chiến dịch thông báo" }, { status: 500 });
  }
}
