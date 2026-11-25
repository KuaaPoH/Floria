import type { EffectiveStatusKey } from "@/features/garden/logic";
import type { CareType, DiseaseSeverity, GardenEnvironment, LightCondition, OrderStatus } from "@/types/user";
import { common } from "./common";

type CK = keyof typeof common.vi;

export const STATUS_LABEL: Record<EffectiveStatusKey, CK> = {
  sick: "statusSick",
  needs_water: "statusNeedsWater",
  needs_fertilizer: "statusNeedsFertilizer",
  needs_inspection: "statusNeedsInspection",
  healthy: "statusHealthy",
};
export const CARE_LABEL: Record<CareType, CK> = { watering: "careWatering", fertilizing: "careFertilizing", inspection: "careInspection" };
export const CARE_SHORT_LABEL: Record<CareType, CK> = { watering: "careWatering", fertilizing: "careFertilizing", inspection: "careInspectionShort" };
export const ENV_LABEL: Record<GardenEnvironment, CK> = { indoor: "envIndoor", balcony: "envBalcony", yard: "envYard", rooftop: "envRooftop" };
export const LIGHT_LABEL: Record<LightCondition, CK> = { direct: "lightDirect", indirect: "lightIndirect", bright: "lightBright", low: "lightLow" };
export const SEVERITY_LABEL: Record<DiseaseSeverity, CK> = { none: "sevNone", low: "sevLow", medium: "sevMedium", high: "sevHigh" };
export const ORDER_STATUS_LABEL: Record<OrderStatus, CK> = { pending: "orderPending", processing: "orderProcessing", shipping: "orderShipping", delivered: "orderDelivered", cancelled: "orderCancelled" };
