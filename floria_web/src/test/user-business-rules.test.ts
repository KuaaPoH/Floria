import { describe, expect, it } from "vitest";
import { parseAssistantContent } from "@/features/assistant/parser";
import { evaluateVoucher, orderActions, removeOrderedItems } from "@/features/ecommerce/logic";
import { completeSchedule, computeEffectiveStatus, gardenStats } from "@/features/garden/logic";
import type { CareSchedule, CartItem, UserPlant, Voucher } from "@/types/user";

describe("Garden business rules", () => {
  const now = new Date("2026-11-24T10:00:00.000Z");
  const past = "2026-11-23T07:00:00.000Z";
  const future = "2026-11-28T07:00:00.000Z";

  const makeSchedule = (type: CareSchedule["type"], nextDueAt: string): CareSchedule => ({
    id: `cs-${type}`,
    plantId: "pl-1",
    type,
    intervalDays: 5,
    preferredTime: "07:00",
    lastDoneAt: null,
    nextDueAt,
    enabled: true,
    history: [],
  });

  it("enforces effectiveStatusText priority: sick > watering > fertilizing > inspection > healthy", () => {
    const healthyPlant: Pick<UserPlant, "id" | "healthStatus"> = { id: "pl-1", healthStatus: "healthy" };
    const sickPlant: Pick<UserPlant, "id" | "healthStatus"> = { id: "pl-1", healthStatus: "sick" };

    const allDue = [makeSchedule("inspection", past), makeSchedule("fertilizing", past), makeSchedule("watering", past)];
    expect(computeEffectiveStatus(sickPlant, allDue, now)).toBe("sick");
    expect(computeEffectiveStatus(healthyPlant, allDue, now)).toBe("needs_water");
    expect(computeEffectiveStatus(healthyPlant, [makeSchedule("inspection", past), makeSchedule("fertilizing", past)], now)).toBe("needs_fertilizer");
    expect(computeEffectiveStatus(healthyPlant, [makeSchedule("inspection", past)], now)).toBe("needs_inspection");
    expect(computeEffectiveStatus(healthyPlant, [makeSchedule("watering", future)], now)).toBe("healthy");
  });

  it("keeps the three care schedules independent when completing one", () => {
    const w = makeSchedule("watering", past);
    const completed = completeSchedule(w, now, "log-1");
    expect(completed.lastDoneAt).toBe(now.toISOString());
    expect(new Date(completed.nextDueAt).getTime()).toBeGreaterThan(now.getTime());
    expect(completed.history[0]?.id).toBe("log-1");
  });

  it("computes the three profile garden statistics from real plant and schedule data", () => {
    const plants: UserPlant[] = [
      { id: "pl-1", userId: "u1", gardenId: "g1", speciesId: "monstera-deliciosa", nickname: "Moni", location: "Phòng khách", image: "", healthStatus: "healthy", activeDiseaseId: null, addedAt: past },
      { id: "pl-2", userId: "u1", gardenId: "g1", speciesId: "sansevieria-trifasciata", nickname: "Hổ", location: "Ban công", image: "", healthStatus: "healthy", activeDiseaseId: null, addedAt: past },
    ];
    const schedules: CareSchedule[] = [
      { ...makeSchedule("watering", past), plantId: "pl-1" },
      { ...makeSchedule("watering", future), plantId: "pl-2" },
    ];
    expect(gardenStats(plants, schedules, now)).toEqual({ caring: 2, needWater: 1, healthy: 1 });
  });
});

describe("E-commerce rules", () => {
  it("evaluates vouchers, removes only ordered cart items, and gates order actions", () => {
    const voucher: Voucher = {
      code: "FLORIA10",
      title: "10% off",
      type: "percent",
      value: 10,
      maxDiscount: 50000,
      minOrder: 150000,
      expiresAt: "2027-01-01T00:00:00.000Z",
      active: true,
    };
    expect(evaluateVoucher(voucher, 100000, 30000, new Date("2026-11-24T00:00:00Z"))).toEqual({
      ok: false,
      reason: "min_order",
      minOrder: 150000,
    });
    expect(evaluateVoucher(voucher, 600000, 0, new Date("2026-11-24T00:00:00Z"))).toEqual({
      ok: true,
      discount: 50000,
    });

    const cart: CartItem[] = [
      { productId: "p1", quantity: 1, selected: true, addedAt: "" },
      { productId: "p2", quantity: 2, selected: false, addedAt: "" },
    ];
    expect(removeOrderedItems(cart, ["p1"]).map((i) => i.productId)).toEqual(["p2"]);

    expect(orderActions({ status: "pending", items: [] })).toEqual({ cancel: true, receive: true, rebuy: false, review: false });
    expect(orderActions({ status: "shipping", items: [] })).toEqual({ cancel: false, receive: true, rebuy: false, review: false });
    expect(orderActions({ status: "delivered", items: [{ productId: "p1", name: "A", image: "", unitPrice: 1, quantity: 1, reviewed: false }] })).toEqual({
      cancel: false,
      receive: false,
      rebuy: true,
      review: true,
    });
  });
});

describe("Assistant action-tag parser", () => {
  it("parses CARE_SCHEDULE and RECOMMEND_PRODUCT tags without leaking raw tags", () => {
    const raw = `Gợi ý cho bạn:\n\n[CARE_SCHEDULE]{"plantName":"Moni","careType":"watering","intervalDays":7,"preferredTime":"07:00","reason":"Đất khô"}[/CARE_SCHEDULE]\n\n[RECOMMEND_PRODUCT]{"productId":"prd-moisture","reason":"Đo ẩm"}[/RECOMMEND_PRODUCT]`;
    const blocks = parseAssistantContent(raw);
    expect(blocks.map((b) => b.kind)).toEqual(["text", "care_schedule", "product"]);
  });
});
