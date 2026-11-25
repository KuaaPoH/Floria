import { isMock } from "@/config/env";
import { evaluateVoucher, orderTotals, unitPrice } from "@/features/ecommerce/logic";
import { uid } from "@/lib/id";
import { readDb, writeDb } from "@/mocks/user/db";
import { findProduct, getAllRuntimeProducts, SHIPPING_FEE, SHOP_PRODUCTS, VOUCHERS } from "@/mocks/user/shop";
import type { Address, Order, PaymentMethod, ProductReview, ShopProduct, Voucher } from "@/types/user";
import { http } from "./api/http";
import { fetchUserCatalog, invalidateCatalogCache } from "./content.service";
import { latency, MockError, requireUid } from "./mock/util";
import { session } from "./session";

export interface PlaceOrderInput {
  items: { productId: string; quantity: number }[];
  addressId: string;
  voucherCode: string | null;
  paymentMethod: PaymentMethod;
}

export interface ZaloPayCreateResult {
  order_url: string;
  app_trans_id: string;
  zp_trans_token?: string;
}

export interface CommerceService {
  listProducts(): Promise<ShopProduct[]>;
  getProduct(id: string): Promise<ShopProduct | null>;
  listReviews(productId: string): Promise<ProductReview[]>;
  createReview(input: { productId: string; orderId: string; rating: number; content: string; images: string[] }): Promise<ProductReview>;
  listVouchers(): Promise<Voucher[]>;
  listOrders(): Promise<Order[]>;
  placeOrder(input: PlaceOrderInput): Promise<Order>;
  cancelOrder(id: string): Promise<Order>;
  confirmReceived(id: string): Promise<Order>;
  createZaloPayPayment(orderId: string): Promise<ZaloPayCreateResult>;
  queryZaloPayPayment(appTransId: string, orderId?: string): Promise<{ return_code: number; is_processing: boolean }>;
  listAddresses(): Promise<Address[]>;
  saveAddress(input: Omit<Address, "id" | "userId"> & { id?: string }): Promise<Address>;
  deleteAddress(id: string): Promise<void>;
  setDefaultAddress(id: string): Promise<void>;
}

const me = () => requireUid(session.get());

async function getAllProducts(): Promise<ShopProduct[]> {
  if (!isMock()) {
    const cat = await fetchUserCatalog();
    return cat?.products ?? [];
  }
  return SHOP_PRODUCTS;
}

async function getAllVouchers(): Promise<Voucher[]> {
  if (!isMock()) {
    const cat = await fetchUserCatalog();
    return cat?.vouchers ?? [];
  }
  return VOUCHERS;
}

async function fetchRemoteAddresses(): Promise<Address[]> {
  const data = await http<{ addresses?: Address[] }>("/auth/sync");
  const list = Array.isArray(data.addresses) ? data.addresses : [];
  return [...list].sort((a, b) => Number(b.isDefault) - Number(a.isDefault));
}

async function persistRemoteAddresses(addresses: Address[]): Promise<Address[]> {
  const data = await http<{ addresses?: Address[] }>("/auth/sync", {
    method: "POST",
    json: { addresses },
  });
  return Array.isArray(data.addresses) ? data.addresses : addresses;
}

export const commerceService: CommerceService = {
  async listProducts() {
    if (!isMock()) {
      return getAllProducts();
    }
    await latency(120, 260);
    return SHOP_PRODUCTS;
  },

  async getProduct(id) {
    if (!isMock()) {
      const list = await getAllProducts();
      return list.find((p) => p.id === id || p.slug === id) ?? null;
    }
    await latency(100, 200);
    return findProduct(id) ?? null;
  },

  async listReviews(productId) {
    if (!isMock()) {
      const cat = await fetchUserCatalog();
      return (cat?.reviews ?? [])
        .filter((r) => r.productId === productId)
        .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
    }
    await latency(100, 220);
    return readDb()
      .reviews.filter((r) => r.productId === productId)
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  },

  async createReview({ productId, orderId, rating, content, images }) {
    if (!isMock()) {
      const rev = await http<ProductReview>("/orders", {
        method: "PATCH",
        json: { action: "review", orderId, productId, rating, content, images },
      });
      invalidateCatalogCache();
      return rev;
    }
    await latency();
    const u = me();
    return writeDb((db) => {
      const order = db.orders.find((o) => o.id === orderId && o.userId === u);
      if (!order || order.status !== "delivered") throw new MockError("Chỉ có thể đánh giá đơn hàng đã giao.", "not_allowed");
      const item = order.items.find((i) => i.productId === productId);
      if (!item) throw new MockError("Sản phẩm không thuộc đơn hàng.", "not_allowed");
      if (item.reviewed) throw new MockError("Bạn đã đánh giá sản phẩm này.", "already_reviewed");
      const user = db.users.find((x) => x.uid === u);
      const review: ProductReview = {
        id: uid("rv"),
        productId,
        orderId,
        userId: u,
        userName: user?.displayName ?? "Người dùng Floria",
        userAvatar: user?.avatarUrl ?? null,
        rating,
        content,
        images,
        createdAt: new Date().toISOString(),
      };
      db.reviews.push(review);
      item.reviewed = true;
      return review;
    });
  },

  async listVouchers() {
    return getAllVouchers();
  },

  async listOrders() {
    if (!isMock()) {
      return http<Order[]>("/orders");
    }
    await latency(120, 260);
    const u = me();
    return readDb().orders.filter((o) => o.userId === u).sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  },

  async placeOrder(input) {
    if (!isMock()) {
      const addresses = await fetchRemoteAddresses();
      const address = addresses.find((a) => a.id === input.addressId);
      if (!address) throw new Error("Vui lòng chọn địa chỉ giao hàng.");
      const created = await http<Order>("/orders", {
        method: "POST",
        json: {
          items: input.items,
          addressId: input.addressId,
          address,
          voucherCode: input.voucherCode,
          paymentMethod: input.paymentMethod,
        },
      });
      invalidateCatalogCache();
      return created;
    }

    await latency(500, 900);
    const u = me();
    if (input.paymentMethod === "zalopay") {
      throw new MockError("Thanh toán ZaloPay cần máy chủ thanh toán Floria (/v2/create). Vui lòng chọn COD để đặt hàng.", "payment_backend_required");
    }
    const allProducts = await getAllProducts();
    const allVouchers = await getAllVouchers();

    return writeDb((db) => {
      const address = db.addresses.find((a) => a.id === input.addressId && a.userId === u);
      if (!address) throw new MockError("Vui lòng chọn địa chỉ giao hàng.", "address_required");
      if (!input.items.length) throw new MockError("Chưa chọn sản phẩm.", "empty");
      const items = input.items.map(({ productId, quantity }) => {
        const p = allProducts.find((x) => x.id === productId) ?? findProduct(productId);
        if (!p) throw new MockError("Sản phẩm không tồn tại.", "not_found");
        if (p.stock < quantity) throw new MockError(`"${p.name}" không đủ tồn kho.`, "out_of_stock");
        return { productId, name: p.name, image: p.images[0], unitPrice: unitPrice(p), quantity };
      });
      const subtotal = items.reduce((s, i) => s + i.unitPrice * i.quantity, 0);
      const voucher = input.voucherCode ? allVouchers.find((v) => v.code === input.voucherCode) : undefined;
      const check = input.voucherCode ? evaluateVoucher(voucher, subtotal, SHIPPING_FEE) : null;
      if (check && !check.ok) throw new MockError("Mã giảm giá không còn hợp lệ.", "voucher_invalid");
      const totals = orderTotals(subtotal, SHIPPING_FEE, check);
      const { id: _a, userId: _u, isDefault: _d, ...snapshot } = address;
      const now = new Date();
      const created: Order = {
        id: uid("ord"),
        code: `FL-${String(now.getDate()).padStart(2, "0")}${String(now.getMonth() + 1).padStart(2, "0")}-${String(Math.floor(Math.random() * 9000) + 1000)}`,
        userId: u,
        items,
        addressSnapshot: snapshot,
        ...totals,
        voucherCode: input.voucherCode,
        paymentMethod: "cod",
        paymentStatus: "unpaid",
        status: "pending",
        createdAt: now.toISOString(),
        updatedAt: now.toISOString(),
      };
      db.orders.push(created);
      return created;
    });
  },

  async cancelOrder(id) {
    if (!isMock()) {
      const updated = await http<Order>("/orders", {
        method: "PATCH",
        json: { action: "cancel", orderId: id },
      });
      invalidateCatalogCache();
      return updated;
    }
    await latency();
    const u = me();
    return writeDb((db) => {
      const o = db.orders.find((x) => x.id === id && x.userId === u);
      if (!o) throw new MockError("Không tìm thấy đơn hàng.", "not_found");
      if (o.status !== "pending") throw new MockError("Đơn hàng này không thể hủy.", "not_allowed");
      o.status = "cancelled";
      o.updatedAt = new Date().toISOString();
      return o;
    });
  },

  async confirmReceived(id) {
    if (!isMock()) {
      return http<Order>("/orders", {
        method: "PATCH",
        json: { action: "receive", orderId: id },
      });
    }
    await latency();
    const u = me();
    return writeDb((db) => {
      const o = db.orders.find((x) => x.id === id && x.userId === u);
      if (!o) throw new MockError("Không tìm thấy đơn hàng.", "not_found");
      if (o.status !== "shipping") throw new MockError("Đơn hàng chưa ở trạng thái đang giao.", "not_allowed");
      o.status = "delivered";
      if (o.paymentMethod === "cod") o.paymentStatus = "paid";
      o.updatedAt = new Date().toISOString();
      return o;
    });
  },

  async createZaloPayPayment(orderId) {
    if (isMock()) {
      throw new MockError("Cổng ZaloPay chưa được kết nối trong chế độ demo.", "payment_backend_required");
    }
    const callbackUrl = typeof window !== "undefined" ? `${window.location.origin}/orders` : undefined;
    return http<ZaloPayCreateResult>("/payment/zalopay", {
      method: "POST",
      json: { action: "create", orderId, callbackUrl },
    });
  },

  async queryZaloPayPayment(appTransId, orderId) {
    if (isMock()) {
      throw new MockError("Cổng ZaloPay chưa được kết nối trong chế độ demo.", "payment_backend_required");
    }
    return http<{ return_code: number; is_processing: boolean }>("/payment/zalopay", {
      method: "POST",
      json: { action: "query", appTransId, orderId },
    });
  },

  async listAddresses() {
    if (!isMock()) {
      return fetchRemoteAddresses();
    }
    await latency(100, 200);
    const u = me();
    return readDb().addresses.filter((a) => a.userId === u).sort((a, b) => Number(b.isDefault) - Number(a.isDefault));
  },

  async saveAddress(input) {
    if (!isMock()) {
      const u = session.get() ?? "";
      const list = await fetchRemoteAddresses();
      const makeDefault = Boolean(input.isDefault) || list.length === 0;
      const next = list.map((a) => (makeDefault ? { ...a, isDefault: false } : a));
      let saved: Address;
      if (input.id) {
        const idx = next.findIndex((x) => x.id === input.id);
        if (idx < 0) throw new Error("Không tìm thấy địa chỉ.");
        saved = { ...next[idx], ...input, userId: u, isDefault: makeDefault || next[idx].isDefault };
        next[idx] = saved;
      } else {
        saved = { ...input, id: uid("addr"), userId: u, isDefault: makeDefault };
        next.push(saved);
      }
      await persistRemoteAddresses(next);
      return saved;
    }
    await latency();
    const u = me();
    return writeDb((db) => {
      const mine = db.addresses.filter((a) => a.userId === u);
      const makeDefault = Boolean(input.isDefault) || mine.length === 0;
      if (makeDefault) mine.forEach((a) => (a.isDefault = false));
      if (input.id) {
        const a = mine.find((x) => x.id === input.id);
        if (!a) throw new MockError("Không tìm thấy địa chỉ.", "not_found");
        const wasDefault = a.isDefault;
        Object.assign(a, input, { isDefault: makeDefault || wasDefault });
        return a;
      }
      const a: Address = { ...input, id: uid("addr"), userId: u, isDefault: makeDefault };
      db.addresses.push(a);
      return a;
    });
  },

  async deleteAddress(id) {
    if (!isMock()) {
      const list = await fetchRemoteAddresses();
      const target = list.find((a) => a.id === id);
      if (!target) return;
      const next = list.filter((a) => a.id !== id);
      if (target.isDefault && next[0]) next[0].isDefault = true;
      await persistRemoteAddresses(next);
      return;
    }
    await latency();
    const u = me();
    writeDb((db) => {
      const target = db.addresses.find((a) => a.id === id && a.userId === u);
      if (!target) return;
      db.addresses = db.addresses.filter((a) => a.id !== id);
      if (target.isDefault) {
        const next = db.addresses.find((a) => a.userId === u);
        if (next) next.isDefault = true;
      }
    });
  },

  async setDefaultAddress(id) {
    if (!isMock()) {
      const list = await fetchRemoteAddresses();
      const next = list.map((a) => ({ ...a, isDefault: a.id === id }));
      await persistRemoteAddresses(next);
      return;
    }
    await latency(100, 200);
    const u = me();
    writeDb((db) => {
      db.addresses.filter((a) => a.userId === u).forEach((a) => (a.isDefault = a.id === id));
    });
  },
};
