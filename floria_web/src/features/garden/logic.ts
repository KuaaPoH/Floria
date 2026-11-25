import type { CareSchedule, CareType, GardenEnvironment, LightCondition, PlantInfo, UserGarden, UserPlant } from "@/types/user";

/** Key of the effective plant status in priority order (see brief §6.4). */
export type EffectiveStatusKey = "sick" | "needs_water" | "needs_fertilizer" | "needs_inspection" | "healthy";

export const STATUS_PRIORITY: EffectiveStatusKey[] = ["sick", "needs_water", "needs_fertilizer", "needs_inspection", "healthy"];

const CARE_TO_STATUS: Record<CareType, EffectiveStatusKey> = {
  watering: "needs_water",
  fertilizing: "needs_fertilizer",
  inspection: "needs_inspection",
};

export function endOfDay(now: Date) {
  const d = new Date(now);
  d.setHours(23, 59, 59, 999);
  return d;
}

/** A schedule is due when it is enabled and its next due time is past or within 12 hours (matching floria_app). */
export function isScheduleDue(s: CareSchedule, now = new Date()) {
  return s.enabled && new Date(s.nextDueAt).getTime() <= now.getTime() + 12 * 3600_000;
}

export function isScheduleOverdue(s: CareSchedule, now = new Date()) {
  const startOfToday = new Date(now);
  startOfToday.setHours(0, 0, 0, 0);
  return s.enabled && new Date(s.nextDueAt).getTime() < startOfToday.getTime();
}

/**
 * effectiveStatusText priority:
 * 1. sick  2. needs water  3. needs fertilizer  4. needs inspection  5. healthy
 */
export function computeEffectiveStatus(plant: Pick<UserPlant, "id" | "healthStatus">, schedules: CareSchedule[], now = new Date()): EffectiveStatusKey {
  if (plant.healthStatus === "sick") return "sick";
  const due = schedules.filter((s) => s.plantId === plant.id && isScheduleDue(s, now));
  for (const key of STATUS_PRIORITY.slice(1, 4)) {
    if (due.some((s) => CARE_TO_STATUS[s.type] === key)) return key;
  }
  return "healthy";
}

/** Next upcoming (or overdue) task for a plant across its three independent schedules. */
export function nextTask(plantId: string, schedules: CareSchedule[]) {
  return schedules
    .filter((s) => s.plantId === plantId && s.enabled)
    .sort((a, b) => new Date(a.nextDueAt).getTime() - new Date(b.nextDueAt).getTime())[0] ?? null;
}

/** Profile garden statistics — exactly three numbers, computed from data. */
export function gardenStats(plants: UserPlant[], schedules: CareSchedule[], now = new Date()) {
  const needWater = plants.filter((p) => schedules.some((s) => s.plantId === p.id && s.type === "watering" && isScheduleDue(s, now))).length;
  const healthy = plants.filter((p) => computeEffectiveStatus(p, schedules, now) === "healthy").length;
  return { caring: plants.length, needWater, healthy };
}

/** Location chips come from real plant locations, never a fixed list. */
export function locationChips(plants: UserPlant[]) {
  const counts = new Map<string, number>();
  for (const p of plants) {
    const loc = p.location.trim();
    if (!loc) continue;
    counts.set(loc, (counts.get(loc) ?? 0) + 1);
  }
  return [...counts.entries()].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0], "vi")).map(([name, count]) => ({ name, count }));
}

/** Completing a task moves only that schedule forward. Other schedules are untouched. */
export function completeSchedule(s: CareSchedule, doneAt = new Date(), logId = `log_${doneAt.getTime()}`): CareSchedule {
  const next = new Date(doneAt.getTime() + s.intervalDays * 86400000);
  const [h, m] = s.preferredTime.split(":").map(Number);
  next.setHours(h, m || 0, 0, 0);
  return {
    ...s,
    lastDoneAt: doneAt.toISOString(),
    nextDueAt: next.toISOString(),
    history: [{ id: logId, doneAt: doneAt.toISOString() }, ...s.history].slice(0, 30),
  };
}

/** Today's tasks = due schedules (including overdue) for the given plants. */
export function todaysTasks(schedules: CareSchedule[], now = new Date()) {
  return schedules
    .filter((s) => isScheduleDue(s, now))
    .sort((a, b) => a.preferredTime.localeCompare(b.preferredTime));
}

/** Suggest locations for a plant based on garden environment & light. */
export function locationFit(info: PlantInfo, garden: Pick<UserGarden, "environment" | "light">) {
  const envOk = info.idealEnvironments.includes(garden.environment);
  const lightOk = info.idealLight.includes(garden.light);
  return { envOk, lightOk, score: (envOk ? 1 : 0) + (lightOk ? 1 : 0) };
}

export const LOCATION_SUGGESTIONS: Record<GardenEnvironment, Record<LightCondition, string[]>> = {
  indoor: {
    low: ["Phòng làm việc", "Góc hành lang", "Phòng tắm"],
    indirect: ["Phòng khách", "Kệ sách", "Phòng ngủ"],
    bright: ["Cửa sổ", "Phòng khách", "Bậu cửa"],
    direct: ["Cửa sổ hướng Nam", "Bậu cửa"],
  },
  balcony: {
    low: ["Góc ban công", "Dưới mái hiên"],
    indirect: ["Góc ban công", "Kệ treo"],
    bright: ["Lan can", "Bậu cửa", "Kệ treo"],
    direct: ["Lan can", "Giàn leo"],
  },
  yard: {
    low: ["Dưới tán cây", "Hiên nhà"],
    indirect: ["Hiên nhà", "Lối đi"],
    bright: ["Bồn hoa", "Lối đi"],
    direct: ["Bồn hoa", "Hàng rào", "Giàn leo"],
  },
  rooftop: {
    low: ["Dưới mái che"],
    indirect: ["Dưới lưới che", "Góc mái che"],
    bright: ["Bồn trồng", "Giàn leo"],
    direct: ["Bồn trồng", "Giàn leo", "Lan can"],
  },
};
