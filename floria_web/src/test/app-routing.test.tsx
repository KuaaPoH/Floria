import { beforeEach, describe, expect, it } from "vitest";
import { findLeaf, NAV_LEAVES } from "@/components/layout/nav-config";
import { buildMapping, orphanRecords } from "@/features/botanical/label-mapping";
import {
  canConfirmCod,
  canRequestRefund,
  isVerifiedTransaction,
  nextStatuses,
  orderSubtotal,
} from "@/features/orders/order-rules";
import { createCollection, resetMockDb } from "@/lib/mock-db";
import { can, DEFAULT_PERMISSIONS } from "@/lib/rbac";
import type { Order } from "@/types";

const baseOrder: Order = {
  id: "ord_t1",
  code: "FL26110999",
  customerName: "Nguyễn Văn An",
  customerEmail: "an@example.com",
  phone: "0901234567",
  address: "123 Lê Lợi, Q.1",
  createdAt: "2026-11-18T10:00:00.000Z",
  items: [
    { productId: "p1", name: "Phân bón", qty: 2, price: 50000 },
    { productId: "p2", name: "Chậu cây", qty: 1, price: 120000 },
  ],
  shippingFee: 30000,
  discount: 0,
  total: 250000,
  paymentMethod: "COD",
  paymentStatus: "unpaid",
  fulfillment: "pending",
  timeline: [{ status: "pending", at: "2026-11-18T10:00:00.000Z", by: "Hệ thống" }],
  notes: "",
};

describe("Nav config", () => {
  it("resolves every defined leaf route and dynamic sub-routes", () => {
    expect(NAV_LEAVES.length).toBeGreaterThanOrEqual(18);
    for (const leaf of NAV_LEAVES) {
      expect(findLeaf(leaf.to)?.to).toBe(leaf.to);
    }
    expect(findLeaf("/admin/plants/plt_01")?.to).toBe("/admin/plants");
  });
});

describe("Order business rules (COD & ZaloPay)", () => {
  it("enforces fulfillment transitions and COD/ZaloPay payment rules", () => {
    expect(nextStatuses("pending")).toEqual(["confirmed", "cancelled"]);
    expect(nextStatuses("delivered")).toEqual([]);
    expect(orderSubtotal(baseOrder)).toBe(220000);

    expect(canConfirmCod(baseOrder)).toBe(false);
    expect(canConfirmCod({ ...baseOrder, fulfillment: "delivered" })).toBe(true);

    const zalopayPaid: Order = {
      ...baseOrder,
      paymentMethod: "ZALOPAY",
      paymentStatus: "paid",
      transaction: { id: "ZLP1001", at: "2026-11-18T10:01:00.000Z", sandbox: true },
    };
    expect(canRequestRefund(zalopayPaid)).toBe(true);
    expect(isVerifiedTransaction(zalopayPaid)).toBe(false);
    expect(isVerifiedTransaction({ ...zalopayPaid, transaction: { ...zalopayPaid.transaction!, sandbox: false } })).toBe(true);
  });
});

describe("RBAC permissions", () => {
  it("grants full access to super_admin and scopes botanist / operations", () => {
    expect(can(DEFAULT_PERMISSIONS, "super_admin", "system", "configure")).toBe(true);
    expect(can(DEFAULT_PERMISSIONS, "botanist", "botanical", "publish")).toBe(true);
    expect(can(DEFAULT_PERMISSIONS, "botanist", "orders", "edit")).toBe(false);
    expect(can(DEFAULT_PERMISSIONS, "operations", "orders", "approve")).toBe(true);
    expect(can(DEFAULT_PERMISSIONS, "operations", "ai_lab", "configure")).toBe(false);
  });
});

describe("AI label mapping", () => {
  it("detects mapped, unmatched, duplicate and orphan records", () => {
    const classes = [
      { id: 0, name: "monstera" },
      { id: 1, name: "snake_plant" },
      { id: 2, name: "orchid" },
    ];
    const records = [
      { id: "p1", name: "Monstera", aiClassId: 0 },
      { id: "p2", name: "Lưỡi hổ 1", aiClassId: 1 },
      { id: "p3", name: "Lưỡi hổ 2", aiClassId: 1 },
      { id: "p4", name: "Cây mới", aiClassId: null },
    ];
    const mapped = buildMapping(classes, records);
    expect(mapped[0]?.status).toBe("mapped");
    expect(mapped[1]?.status).toBe("duplicate");
    expect(mapped[2]?.status).toBe("unmatched");
    expect(orphanRecords(records)).toHaveLength(1);
  });
});

describe("Mock DB persistence", () => {
  beforeEach(() => resetMockDb());

  it("supports local CRUD operations", async () => {
    const col = createCollection<{ id: string; name: string }>("test-items", () => [{ id: "1", name: "Monstera" }]);
    expect(await col.list()).toHaveLength(1);
    await col.create({ id: "2", name: "Trầu bà" });
    expect(await col.list()).toHaveLength(2);
    const updated = await col.update("2", { name: "Trầu bà lá xẻ" });
    expect(updated.name).toBe("Trầu bà lá xẻ");
    await col.remove("1");
    expect(await col.list()).toHaveLength(1);
  });
});
