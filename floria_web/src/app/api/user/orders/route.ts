import { NextResponse } from "next/server";
import { FieldValue } from "firebase-admin/firestore";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import { UserAuthError, verifyUserRequest } from "@/lib/server/user-auth";
import { evaluateVoucher, orderTotals, unitPrice } from "@/features/ecommerce/logic";
import { IMG } from "@/mocks/user/images";
import { SHIPPING_FEE } from "@/mocks/user/shop";
import type {
  Address,
  Order,
  OrderItem,
  OrderStatus,
  PaymentMethod,
  PaymentStatus,
  ProductReview,
  ShopProduct,
  Voucher,
} from "@/types/user";

function mapOrderStatusFromFirestore(raw: unknown): OrderStatus {
  const s = String(raw ?? "pending").toLowerCase();
  if (s === "delivered" || s === "completed") return "delivered";
  if (s === "shipping") return "shipping";
  if (s === "processing" || s === "confirmed") return "processing";
  if (s === "cancelled") return "cancelled";
  return "pending";
}

function mapOrderFromFirestore(
  id: string,
  d: Record<string, unknown>,
  reviewedPairs: Set<string>,
): Order {
  const rawItems = Array.isArray(d.items) ? d.items : [];
  const reviewedList = Array.isArray(d.reviewedProductIds) ? d.reviewedProductIds.map(String) : [];
  const items: OrderItem[] = rawItems.map((it) => {
    const m = (typeof it === "object" && it !== null ? it : {}) as Record<string, unknown>;
    const pid = String(m.productId ?? "");
    const reviewed = Boolean(m.reviewed) || Boolean(d.isReviewed) || reviewedList.includes(pid) || reviewedPairs.has(`${id}:${pid}`);
    return {
      productId: pid,
      name: String(m.name ?? "Sản phẩm Floria"),
      image: String(m.imageUrl ?? m.image ?? "").trim() || IMG.products.fertilizer,
      unitPrice: Number(m.unitPrice ?? m.price ?? 0),
      quantity: Number(m.quantity ?? m.qty ?? 1),
      reviewed,
    };
  });

  const addrSnap = (typeof d.addressSnapshot === "object" && d.addressSnapshot !== null ? d.addressSnapshot : {}) as Record<string, unknown>;
  const shippingAddr = String(d.shippingAddress ?? "").trim();
  const addrParts = shippingAddr ? shippingAddr.split(",").map((s) => s.trim()).filter(Boolean) : [];
  const addressSnapshot: Order["addressSnapshot"] = {
    recipientName: String(addrSnap.recipientName ?? d.recipientName ?? "Người nhận"),
    phone: String(addrSnap.phone ?? d.recipientPhone ?? ""),
    provinceCode: String(addrSnap.provinceCode ?? ""),
    provinceName: String(addrSnap.provinceName ?? (addrParts.length >= 1 ? addrParts[addrParts.length - 1] : "")),
    wardCode: String(addrSnap.wardCode ?? ""),
    wardName: String(addrSnap.wardName ?? (addrParts.length >= 2 ? addrParts[addrParts.length - 2] : "")),
    street: String(addrSnap.street ?? (addrParts.length >= 3 ? addrParts.slice(0, -2).join(", ") : shippingAddr)),
    latitude: typeof addrSnap.latitude === "number" ? addrSnap.latitude : typeof d.latitude === "number" ? d.latitude : null,
    longitude: typeof addrSnap.longitude === "number" ? addrSnap.longitude : typeof d.longitude === "number" ? d.longitude : null,
    label: typeof addrSnap.label === "string" ? addrSnap.label : typeof d.addressLabel === "string" ? d.addressLabel : undefined,
  };

  const subtotalFromItems = items.reduce((s, i) => s + i.unitPrice * i.quantity, 0);
  const shippingFee = Number(d.shippingFee ?? 0);
  const discount = Number(d.discount ?? d.discountAmount ?? 0);
  const total = Number(d.totalAmount ?? d.total ?? Math.max(0, subtotalFromItems + shippingFee - discount));
  const status = mapOrderStatusFromFirestore(d.status);
  const paymentMethod: PaymentMethod = String(d.paymentMethod ?? "cod").toLowerCase() === "zalopay" ? "zalopay" : "cod";

  let paymentStatus: PaymentStatus = "unpaid";
  if (typeof d.paymentStatus === "string" && ["unpaid", "awaiting_gateway", "paid", "failed", "refunded"].includes(d.paymentStatus)) {
    paymentStatus = d.paymentStatus as PaymentStatus;
  } else if (status === "delivered" || paymentMethod === "zalopay") {
    paymentStatus = status === "cancelled" ? "refunded" : "paid";
  }

  return {
    id,
    code: String(d.orderCode ?? d.code ?? id.slice(0, 8).toUpperCase()),
    userId: String(d.userId ?? ""),
    items,
    addressSnapshot,
    subtotal: Number(d.subtotal ?? subtotalFromItems),
    shippingFee,
    discount,
    total,
    voucherCode: typeof d.voucherCode === "string" && d.voucherCode ? d.voucherCode : null,
    paymentMethod,
    paymentStatus,
    status,
    createdAt: toIsoString(d.createdAt),
    updatedAt: toIsoString(d.updatedAt ?? d.createdAt),
  };
}

export async function GET(req: Request) {
  try {
    const user = await verifyUserRequest(req);
    const db = getAdminDb();
    const [ordersSnap, revSnap] = await Promise.all([
      db.collection("Orders").where("userId", "==", user.uid).get(),
      db.collection("ProductReviews").where("userId", "==", user.uid).get(),
    ]);

    const reviewedPairs = new Set<string>();
    for (const doc of revSnap.docs) {
      const rd = doc.data();
      if (rd.orderId && rd.productId) {
        reviewedPairs.add(`${rd.orderId}:${rd.productId}`);
      }
    }

    const orders = ordersSnap.docs
      .map((doc) => mapOrderFromFirestore(doc.id, doc.data(), reviewedPairs))
      .sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt));

    return NextResponse.json(orders);
  } catch (err) {
    if (err instanceof UserAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: (err as Error).message || "Không thể tải đơn hàng" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    const user = await verifyUserRequest(req);
    const db = getAdminDb();
    const body = (await req.json()) as {
      items?: Array<{ productId: string; quantity: number }>;
      address?: Address;
      addressId?: string;
      voucherCode?: string | null;
      paymentMethod?: PaymentMethod;
    };

    const reqItems = Array.isArray(body.items) ? body.items : [];
    if (reqItems.length === 0) {
      return NextResponse.json({ error: "Chưa chọn sản phẩm." }, { status: 400 });
    }

    // Lấy địa chỉ từ body hoặc từ Users/{uid}.addresses
    let address = body.address;
    if (!address && body.addressId) {
      const uSnap = await db.collection("Users").doc(user.uid).get();
      const addrList = Array.isArray(uSnap.data()?.addresses) ? (uSnap.data()!.addresses as Record<string, unknown>[]) : [];
      const found = addrList.find((a) => String(a.id ?? "") === body.addressId);
      if (found) {
        address = {
          id: String(found.id ?? body.addressId),
          userId: user.uid,
          recipientName: String(found.recipientName ?? "Người nhận"),
          phone: String(found.phone ?? ""),
          provinceCode: String(found.provinceCode ?? ""),
          provinceName: String(found.provinceName ?? ""),
          wardCode: String(found.wardCode ?? ""),
          wardName: String(found.wardName ?? ""),
          street: String(found.street ?? ""),
          latitude: typeof found.latitude === "number" ? found.latitude : null,
          longitude: typeof found.longitude === "number" ? found.longitude : null,
          isDefault: Boolean(found.isDefault),
          label: typeof found.label === "string" ? found.label : undefined,
        };
      }
    }

    if (!address) {
      return NextResponse.json({ error: "Vui lòng chọn địa chỉ giao hàng." }, { status: 400 });
    }

    const paymentMethod: PaymentMethod = body.paymentMethod === "zalopay" ? "zalopay" : "cod";
    const now = new Date();
    const nowIso = now.toISOString();
    const orderRef = db.collection("Orders").doc();
    const orderCode = `FL-${String(now.getDate()).padStart(2, "0")}${String(now.getMonth() + 1).padStart(2, "0")}-${String(Math.floor(Math.random() * 9000) + 1000)}`;

    // Tra cứu voucher trước transaction
    let voucherDocRef: FirebaseFirestore.DocumentReference | null = null;
    let voucherObj: Voucher | undefined;
    if (body.voucherCode) {
      const codeUpper = body.voucherCode.trim().toUpperCase();
      const vSnap = await db.collection("Vouchers").get();
      for (const vdoc of vSnap.docs) {
        const vd = vdoc.data();
        const vc = String(vd.code ?? vdoc.id).toUpperCase();
        if (vc === codeUpper && vd.type !== "shipping" && vd.discountType !== "shipping") {
          voucherDocRef = vdoc.ref;
          voucherObj = {
            code: vc,
            title: String(vd.description ?? vd.title ?? vc),
            type: vd.type === "fixed" || vd.discountType === "fixed" ? "fixed" : "percent",
            value: Number(vd.value ?? vd.discountValue ?? 0),
            maxDiscount: typeof vd.maxDiscount === "number" ? vd.maxDiscount : undefined,
            minOrder: Number(vd.minOrder ?? vd.minOrderAmount ?? 0),
            expiresAt: toIsoString(vd.expiresAt ?? vd.expiryDate, "2027-12-31T23:59:59Z"),
            active: vd.active !== false && vd.isActive !== false,
          };
          break;
        }
      }
    }

    const createdOrder = await db.runTransaction(async (tx) => {
      // 1. ALL READS: Firestore requires all reads before any writes
      const [prodDocs, vSnapTx] = await Promise.all([
        Promise.all(reqItems.map((it) => tx.get(db.collection("ShopProducts").doc(it.productId)))),
        voucherDocRef ? tx.get(voucherDocRef) : Promise.resolve(null),
      ]);

      // 2. VALIDATION & PREPARATION (no writes yet)
      const orderItems: OrderItem[] = [];
      const stockUpdates: { ref: FirebaseFirestore.DocumentReference; nextStock: number; soldCount: number }[] = [];
      const inventoryLogs: {
        productId: string;
        productName: string;
        sku: string;
        quantity: number;
        previousStock: number;
        newStock: number;
        note: string;
      }[] = [];

      for (let i = 0; i < reqItems.length; i++) {
        const snap = prodDocs[i];
        const reqItem = reqItems[i];
        if (!snap.exists) {
          throw new Error(`Sản phẩm ${reqItem.productId} không tồn tại.`);
        }
        const pd = snap.data() ?? {};
        const curStock = Number(pd.stock ?? 0);
        if (curStock < reqItem.quantity) {
          throw new Error(`"${String(pd.name ?? reqItem.productId)}" chỉ còn ${curStock} sản phẩm trong kho.`);
        }
        const priceRaw = Number(pd.price ?? 0);
        const origRaw = Number(pd.originalPrice ?? priceRaw);
        const hasDiscount = origRaw > priceRaw && priceRaw > 0;
        const pShape: Pick<ShopProduct, "price" | "salePrice"> = {
          price: hasDiscount ? origRaw : priceRaw,
          salePrice: hasDiscount ? priceRaw : null,
        };
        const uPrice = unitPrice(pShape);
        const img = String(pd.imageUrl ?? pd.image ?? "").trim() || IMG.products.fertilizer;

        const nextStock = Math.max(0, curStock - reqItem.quantity);
        stockUpdates.push({
          ref: snap.ref,
          nextStock,
          soldCount: Number(pd.soldCount ?? 0) + reqItem.quantity,
        });

        inventoryLogs.push({
          productId: snap.id,
          productName: String(pd.name ?? ""),
          sku: String(pd.sku ?? snap.id),
          quantity: reqItem.quantity,
          previousStock: curStock,
          newStock: nextStock,
          note: `Đơn hàng Web #${orderCode}`,
        });

        orderItems.push({
          productId: snap.id,
          name: String(pd.name ?? "Sản phẩm Floria"),
          image: img,
          unitPrice: uPrice,
          quantity: reqItem.quantity,
        });
      }

      const subtotal = orderItems.reduce((s, it) => s + it.unitPrice * it.quantity, 0);
      const voucherCheck = body.voucherCode ? evaluateVoucher(voucherObj, subtotal, SHIPPING_FEE) : null;
      if (voucherCheck && !voucherCheck.ok) {
        throw new Error("Mã giảm giá không còn hợp lệ cho đơn hàng này.");
      }
      const totals = orderTotals(subtotal, SHIPPING_FEE, voucherCheck);

      // 3. ALL WRITES
      for (const update of stockUpdates) {
        tx.update(update.ref, {
          stock: update.nextStock,
          inStock: update.nextStock > 0,
          soldCount: update.soldCount,
          updatedAt: nowIso,
        });
      }

      for (const log of inventoryLogs) {
        const txLogRef = db.collection("InventoryTransactions").doc();
        tx.set(txLogRef, {
          productId: log.productId,
          productName: log.productName,
          sku: log.sku,
          type: "out",
          quantity: log.quantity,
          previousStock: log.previousStock,
          newStock: log.newStock,
          note: log.note,
          performedBy: user.email || user.uid,
          createdAt: nowIso,
        });
      }

      if (voucherDocRef && vSnapTx?.exists && voucherCheck?.ok) {
        const curUsed = Number(vSnapTx.data()?.used ?? 0);
        tx.update(voucherDocRef, { used: curUsed + 1 });
      }

      const { id: _aid, userId: _auid, isDefault: _adef, ...snapshot } = address!;
      const shippingAddress = [snapshot.street, snapshot.wardName, snapshot.provinceName].filter(Boolean).join(", ");
      const paymentStatus: PaymentStatus = paymentMethod === "zalopay" ? "awaiting_gateway" : "unpaid";

      const firestorePayload = {
        id: orderRef.id,
        orderCode,
        code: orderCode,
        userId: user.uid,
        customerEmail: user.email,
        recipientName: snapshot.recipientName,
        recipientPhone: snapshot.phone,
        shippingAddress,
        addressLabel: snapshot.label ?? "",
        latitude: snapshot.latitude,
        longitude: snapshot.longitude,
        addressSnapshot: snapshot,
        items: orderItems.map((it) => ({
          productId: it.productId,
          name: it.name,
          imageUrl: it.image,
          image: it.image,
          price: it.unitPrice,
          unitPrice: it.unitPrice,
          quantity: it.quantity,
        })),
        subtotal: totals.subtotal,
        shippingFee: totals.shippingFee,
        discount: totals.discount,
        discountAmount: totals.discount,
        voucherCode: voucherCheck?.ok ? body.voucherCode : null,
        totalAmount: totals.total,
        total: totals.total,
        paymentMethod,
        paymentLabel: paymentMethod === "zalopay" ? "Ví ZaloPay" : "Thanh toán khi nhận hàng (COD)",
        paymentStatus,
        status: "pending",
        isReviewed: false,
        reviewedProductIds: [],
        createdAt: nowIso,
        updatedAt: nowIso,
      };

      tx.set(orderRef, firestorePayload);

      const resultOrder: Order = {
        id: orderRef.id,
        code: orderCode,
        userId: user.uid,
        items: orderItems,
        addressSnapshot: snapshot,
        ...totals,
        voucherCode: voucherCheck?.ok ? (body.voucherCode ?? null) : null,
        paymentMethod,
        paymentStatus,
        status: "pending",
        createdAt: nowIso,
        updatedAt: nowIso,
      };
      return resultOrder;
    });

    return NextResponse.json(createdOrder, { status: 201 });
  } catch (err) {
    if (err instanceof UserAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: (err as Error).message || "Không thể đặt hàng" }, { status: 400 });
  }
}

export async function PATCH(req: Request) {
  try {
    const user = await verifyUserRequest(req);
    const db = getAdminDb();
    const body = (await req.json()) as {
      action?: "cancel" | "receive" | "review" | "mark_paid";
      orderId?: string;
      productId?: string;
      rating?: number;
      content?: string;
      images?: string[];
      appTransId?: string;
    };

    const orderId = String(body.orderId ?? "");
    const orderRef = db.collection("Orders").doc(orderId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists || orderSnap.data()?.userId !== user.uid) {
      return NextResponse.json({ error: "Không tìm thấy đơn hàng." }, { status: 404 });
    }
    const d = orderSnap.data() ?? {};
    const nowIso = new Date().toISOString();
    const curStatus = mapOrderStatusFromFirestore(d.status);

    if (body.action === "cancel") {
      if (curStatus !== "pending") {
        return NextResponse.json({ error: "Đơn hàng này không thể hủy." }, { status: 400 });
      }
      await db.runTransaction(async (tx) => {
        const rawItems = Array.isArray(d.items) ? (d.items as Record<string, unknown>[]) : [];
        const items = rawItems
          .map((it) => ({
            pid: String(it.productId ?? ""),
            qty: Number(it.quantity ?? 1),
          }))
          .filter((it) => Boolean(it.pid));

        // 1. ALL READS FIRST
        const pSnaps = await Promise.all(
          items.map((it) => tx.get(db.collection("ShopProducts").doc(it.pid))),
        );

        // 2. ALL WRITES AFTER
        for (let i = 0; i < items.length; i++) {
          const pSnap = pSnaps[i];
          const { pid, qty } = items[i];
          if (pSnap.exists) {
            const pd = pSnap.data() ?? {};
            const curStock = Number(pd.stock ?? 0);
            const nextStock = curStock + qty;
            tx.update(pSnap.ref, {
              stock: nextStock,
              inStock: nextStock > 0,
              soldCount: Math.max(0, Number(pd.soldCount ?? 0) - qty),
              updatedAt: nowIso,
            });
            tx.set(db.collection("InventoryTransactions").doc(), {
              productId: pid,
              productName: String(pd.name ?? ""),
              type: "in",
              quantity: qty,
              previousStock: curStock,
              newStock: nextStock,
              note: `Hoàn kho hủy đơn #${String(d.orderCode ?? d.code ?? orderId)}`,
              createdAt: nowIso,
            });
          }
        }
        tx.update(orderRef, {
          status: "cancelled",
          paymentStatus: d.paymentStatus === "paid" ? "refunded" : d.paymentStatus ?? "unpaid",
          updatedAt: nowIso,
        });
      });

      const updatedSnap = await orderRef.get();
      return NextResponse.json(mapOrderFromFirestore(orderId, updatedSnap.data() ?? {}, new Set()));
    }

    if (body.action === "receive") {
      if (curStatus !== "pending" && curStatus !== "processing" && curStatus !== "shipping") {
        return NextResponse.json({ error: "Đơn hàng này không thể xác nhận nhận hàng." }, { status: 400 });
      }
      await orderRef.set(
        { status: "delivered", paymentStatus: "paid", updatedAt: nowIso },
        { merge: true },
      );
      const updatedSnap = await orderRef.get();
      return NextResponse.json(mapOrderFromFirestore(orderId, updatedSnap.data() ?? {}, new Set()));
    }

    if (body.action === "mark_paid") {
      await orderRef.set(
        {
          paymentStatus: "paid",
          ...(body.appTransId ? { appTransId: body.appTransId } : {}),
          updatedAt: nowIso,
        },
        { merge: true },
      );
      const updatedSnap = await orderRef.get();
      return NextResponse.json(mapOrderFromFirestore(orderId, updatedSnap.data() ?? {}, new Set()));
    }

    if (body.action === "review") {
      if (curStatus !== "delivered") {
        return NextResponse.json({ error: "Chỉ có thể đánh giá đơn hàng đã giao." }, { status: 400 });
      }
      const productId = String(body.productId ?? "");
      const items = Array.isArray(d.items) ? (d.items as Record<string, unknown>[]) : [];
      const targetItem = items.find((i) => String(i.productId ?? "") === productId);
      if (!targetItem) {
        return NextResponse.json({ error: "Sản phẩm không thuộc đơn hàng." }, { status: 400 });
      }
      const reviewedIds = new Set(Array.isArray(d.reviewedProductIds) ? d.reviewedProductIds.map(String) : []);
      if (reviewedIds.has(productId)) {
        return NextResponse.json({ error: "Bạn đã đánh giá sản phẩm này." }, { status: 400 });
      }

      const uSnap = await db.collection("Users").doc(user.uid).get();
      const ud = uSnap.data() ?? {};
      const userName = String(ud.displayName ?? user.name ?? "Người dùng Floria");
      const userAvatar = typeof ud.customPhotoUrl === "string" && !ud.customPhotoUrl.startsWith("preset:")
        ? ud.customPhotoUrl
        : typeof ud.googlePhotoUrl === "string"
          ? ud.googlePhotoUrl
          : user.picture ?? null;

      const rating = Math.min(5, Math.max(1, Number(body.rating ?? 5)));
      const content = String(body.content ?? "").trim();
      const images = Array.isArray(body.images) ? body.images.map(String).filter(Boolean) : [];

      const reviewRef = await db.collection("ProductReviews").add({
        productId,
        productName: String(targetItem.name ?? "Sản phẩm Floria"),
        orderId,
        userId: user.uid,
        userName,
        userAvatar: userAvatar ?? "",
        rating,
        comment: content,
        content,
        images,
        reviewImages: images,
        status: "approved",
        createdAt: FieldValue.serverTimestamp(),
      });

      reviewedIds.add(productId);
      const allReviewed = items.every((i) => reviewedIds.has(String(i.productId ?? "")));
      await orderRef.set(
        {
          reviewedProductIds: [...reviewedIds],
          isReviewed: allReviewed,
          updatedAt: nowIso,
        },
        { merge: true },
      );

      // Cập nhật lại rating trung bình của sản phẩm trên ShopProducts
      try {
        const pRevs = await db.collection("ProductReviews").where("productId", "==", productId).get();
        const validRevs = pRevs.docs.filter((doc) => doc.data().status !== "hidden" && doc.data().status !== "rejected");
        if (validRevs.length > 0) {
          const avg = validRevs.reduce((s, doc) => s + Number(doc.data().rating ?? 5), 0) / validRevs.length;
          await db.collection("ShopProducts").doc(productId).set(
            { rating: Number(avg.toFixed(1)), reviewCount: validRevs.length },
            { merge: true },
          );
        }
      } catch {
        // Bỏ qua nếu cập nhật rating bị trễ
      }

      const createdReview: ProductReview = {
        id: reviewRef.id,
        productId,
        orderId,
        userId: user.uid,
        userName,
        userAvatar,
        rating,
        content,
        images,
        createdAt: nowIso,
      };
      return NextResponse.json(createdReview, { status: 201 });
    }

    return NextResponse.json({ error: "Hành động không hợp lệ." }, { status: 400 });
  } catch (err) {
    if (err instanceof UserAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: (err as Error).message || "Không thể cập nhật đơn hàng" }, { status: 400 });
  }
}
