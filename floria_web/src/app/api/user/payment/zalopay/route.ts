import crypto from "node:crypto";
import { NextResponse } from "next/server";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { UserAuthError, verifyUserRequest } from "@/lib/server/user-auth";

const ZALOPAY_APP_ID = Number(process.env.ZALOPAY_APP_ID ?? 2554);
const ZALOPAY_KEY1 = process.env.ZALOPAY_KEY1 ?? "sdngKKJmqEMzvh5QQcdD2A9XBSKUNaYn";
const ZALOPAY_CREATE_URL = "https://sb-openapi.zalopay.vn/v2/create";
const ZALOPAY_QUERY_URL = "https://sb-openapi.zalopay.vn/v2/query";

function hmacSha256(data: string, key: string): string {
  return crypto.createHmac("sha256", key).update(data).digest("hex");
}

function formatYyMmDd(d: Date): string {
  const yy = String(d.getFullYear()).slice(-2);
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${yy}${mm}${dd}`;
}

export async function POST(req: Request) {
  try {
    const user = await verifyUserRequest(req);
    const body = (await req.json()) as {
      action?: "create" | "query";
      orderId?: string;
      appTransId?: string;
      callbackUrl?: string;
    };

    if (body.action === "query") {
      const appTransId = String(body.appTransId ?? "").trim();
      if (!appTransId) {
        return NextResponse.json({ error: "Thiếu mã giao dịch ZaloPay." }, { status: 400 });
      }
      const mac = hmacSha256(`${ZALOPAY_APP_ID}|${appTransId}|${ZALOPAY_KEY1}`, ZALOPAY_KEY1);
      const res = await fetch(ZALOPAY_QUERY_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ app_id: ZALOPAY_APP_ID, app_trans_id: appTransId, mac }),
      });
      const json = (await res.json()) as { return_code?: number; is_processing?: boolean; return_message?: string };
      const returnCode = Number(json.return_code ?? 0);

      // Nếu thanh toán thành công (return_code === 1), cập nhật paymentStatus = "paid"
      // và chuyển đơn từ pending/processing sang trạng thái đang giao ("shipping")
      if (returnCode === 1) {
        const db = getAdminDb();
        let orderRef: FirebaseFirestore.DocumentReference | null = null;
        if (body.orderId) {
          orderRef = db.collection("Orders").doc(body.orderId);
        } else {
          const found = await db.collection("Orders").where("appTransId", "==", appTransId).limit(1).get().catch(() => null);
          if (found && !found.empty) {
            orderRef = found.docs[0].ref;
          }
        }

        if (orderRef) {
          const orderSnap = await orderRef.get().catch(() => null);
          const curStatus = String(orderSnap?.data()?.status ?? "pending").toLowerCase();
          const shouldMoveToShipping = curStatus === "pending" || curStatus === "processing";

          await orderRef
            .set(
              {
                paymentStatus: "paid",
                ...(shouldMoveToShipping ? { status: "shipping" } : {}),
                appTransId,
                updatedAt: new Date().toISOString(),
              },
              { merge: true },
            )
            .catch(() => {});
        }
      }

      return NextResponse.json({
        return_code: returnCode,
        is_processing: Boolean(json.is_processing),
        return_message: json.return_message ?? "",
      });
    }

    // Create ZaloPay Sandbox order
    const orderId = String(body.orderId ?? "").trim();
    if (!orderId) {
      return NextResponse.json({ error: "Thiếu mã đơn hàng." }, { status: 400 });
    }
    const db = getAdminDb();
    const orderSnap = await db.collection("Orders").doc(orderId).get();
    if (!orderSnap.exists || orderSnap.data()?.userId !== user.uid) {
      return NextResponse.json({ error: "Không tìm thấy đơn hàng." }, { status: 404 });
    }
    const od = orderSnap.data() ?? {};
    const orderCode = String(od.orderCode ?? od.code ?? orderId);
    const amountVnd = Math.round(Number(od.totalAmount ?? od.total ?? 0));
    if (amountVnd <= 0) {
      return NextResponse.json({ error: "Số tiền thanh toán không hợp lệ." }, { status: 400 });
    }

    const now = new Date();
    const yyMMdd = formatYyMmDd(now);
    const suffix = String(now.getTime() % 1_000_000).padStart(6, "0");
    const cleanCode = orderCode.replace(/[^a-zA-Z0-9]/g, "");
    const appTransId = `${yyMMdd}_${cleanCode || "FLORIA"}_${suffix}`;
    const appTime = now.getTime();
    const appUser = user.email || user.uid;
    const embedData = JSON.stringify(body.callbackUrl ? { redirecturl: body.callbackUrl } : {});
    const item = "[]";
    const description = `Floria - Thanh toan don hang #${orderCode}`;

    const macInput = `${ZALOPAY_APP_ID}|${appTransId}|${appUser}|${amountVnd}|${appTime}|${embedData}|${item}`;
    const mac = hmacSha256(macInput, ZALOPAY_KEY1);

    const zRes = await fetch(ZALOPAY_CREATE_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        app_id: ZALOPAY_APP_ID,
        app_user: appUser,
        app_time: appTime,
        amount: amountVnd,
        app_trans_id: appTransId,
        embed_data: embedData,
        item,
        description,
        bank_code: "",
        mac,
      }),
    });

    const zJson = (await zRes.json()) as {
      return_code?: number;
      return_message?: string;
      sub_return_message?: string;
      order_url?: string;
      zp_trans_token?: string;
    };

    if (Number(zJson.return_code) !== 1 || !zJson.order_url) {
      return NextResponse.json(
        {
          error:
            zJson.sub_return_message ||
            zJson.return_message ||
            "Không thể khởi tạo giao dịch ZaloPay Sandbox.",
        },
        { status: 502 },
      );
    }

    await orderSnap.ref.set(
      {
        appTransId,
        zpTransToken: zJson.zp_trans_token ?? "",
        updatedAt: now.toISOString(),
      },
      { merge: true },
    );

    return NextResponse.json({
      order_url: zJson.order_url,
      app_trans_id: appTransId,
      zp_trans_token: zJson.zp_trans_token ?? "",
    });
  } catch (err) {
    if (err instanceof UserAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: (err as Error).message || "Lỗi kết nối ZaloPay Sandbox" }, { status: 502 });
  }
}
