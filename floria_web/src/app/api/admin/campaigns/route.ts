import { NextResponse } from "next/server";
import type { Message } from "firebase-admin/messaging";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb, getAdminMessaging } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import type { AudienceKind, Campaign } from "@/types";

const BROADCAST_TOPIC = "floria_broadcast";

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
          audienceDetail: String(d.audienceDetail ?? "Tất cả thiết bị"),
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
    const body = (await req.json()) as Partial<Campaign> & { sendNow?: boolean };
    const docId = body.id?.trim() || `cmp_${Date.now()}`;
    const title = body.title?.trim() || "Thông báo từ Floria";
    const messageBody = body.body?.trim() || "";
    const image = body.image?.trim() || "";
    const deepLink = body.deepLink?.trim() || "floria://home";
    const sendNow = Boolean(body.sendNow) || body.status === "sent";

    const db = getAdminDb();

    // Đếm số thiết bị đã đăng ký token (tham khảo số lượng máy)
    let registeredDevices = 0;
    try {
      const tokensSnap = await db.collection("DeviceTokens").count().get();
      registeredDevices = tokensSnap.data().count;
    } catch {
      registeredDevices = 0;
    }

    let finalStatus: Campaign["status"] = body.status ?? (sendNow ? "sent" : "scheduled");
    let messageId = "";
    let fcmError = "";
    let successCount = Number(body.success ?? 0);
    let failedCount = Number(body.failed ?? 0);

    if (sendNow) {
      try {
        const validImage = image.startsWith("http://") || image.startsWith("https://") ? image : undefined;
        const fcmMessage: Message = {
          topic: BROADCAST_TOPIC,
          notification: {
            title,
            body: messageBody,
            ...(validImage ? { imageUrl: validImage } : {}),
          },
          data: {
            campaignId: docId,
            deepLink,
            title,
            body: messageBody,
            image,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high",
            notification: {
              channelId: "floria_care_channel",
              sound: "default",
              clickAction: "FLUTTER_NOTIFICATION_CLICK",
              ...(validImage ? { imageUrl: validImage } : {}),
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                "mutable-content": 1,
              },
            },
          },
        };

        messageId = await getAdminMessaging().send(fcmMessage);
        finalStatus = "sent";
        successCount = Math.max(registeredDevices, 1);
        failedCount = 0;
      } catch (err) {
        finalStatus = "failed";
        fcmError = err instanceof Error ? err.message : "Gửi FCM thất bại";
        failedCount = Math.max(registeredDevices, 1);
        successCount = 0;
      }
    }

    const payload: Omit<Campaign, "id"> & { messageId?: string; fcmTopic: string; errorMessage?: string } = {
      name: body.name?.trim() || title,
      title,
      body: messageBody,
      image,
      deepLink,
      audience: body.audience ?? "all",
      audienceDetail: body.audienceDetail?.trim() || "Tất cả thiết bị (FCM)",
      scheduledAt: sendNow ? new Date().toISOString() : body.scheduledAt ?? new Date().toISOString(),
      status: finalStatus,
      targeted: registeredDevices,
      success: successCount,
      failed: failedCount,
      opened: Number(body.opened ?? 0),
      fcmTopic: BROADCAST_TOPIC,
      ...(messageId ? { messageId } : {}),
      ...(fcmError ? { errorMessage: fcmError } : {}),
    };

    await db.collection("NotificationCampaigns").doc(docId).set(payload, { merge: true });

    if (fcmError) {
      return NextResponse.json({ error: `Gửi thông báo đẩy thất bại: ${fcmError}`, campaign: { id: docId, ...payload } }, { status: 500 });
    }

    return NextResponse.json({ id: docId, ...payload }, { status: 201 });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tạo chiến dịch thông báo" }, { status: 500 });
  }
}
