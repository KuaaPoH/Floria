import type { AssistantBlock, CareScheduleSuggestion, CareType, ProductSuggestion } from "@/types/user";

const TAG_RE =
  /\[(CARE_SCHEDULE|RECOMMEND_PRODUCT)\]([\s\S]*?)\[\/\1\]|\[RECOMMEND_PRODUCT:\s*([^\]]+)\]|\[CARE_SCHEDULE:\s*([^\]]+)\]/g;
const CARE_TYPES: CareType[] = ["watering", "fertilizing", "inspection"];

function parseCare(raw: unknown): CareScheduleSuggestion | null {
  if (!raw || typeof raw !== "object") return null;
  const r = raw as Record<string, unknown>;
  if (typeof r.plantName !== "string" || !CARE_TYPES.includes(r.careType as CareType)) return null;
  const interval = Number(r.intervalDays);
  if (!Number.isFinite(interval) || interval < 1 || interval > 120) return null;
  const time = typeof r.preferredTime === "string" && /^\d{2}:\d{2}$/.test(r.preferredTime) ? r.preferredTime : "07:00";
  return { plantName: r.plantName, speciesId: typeof r.speciesId === "string" ? r.speciesId : undefined, careType: r.careType as CareType, intervalDays: Math.round(interval), preferredTime: time, reason: typeof r.reason === "string" ? r.reason : "" };
}

function parseProduct(raw: unknown): ProductSuggestion | null {
  if (!raw || typeof raw !== "object") return null;
  const r = raw as Record<string, unknown>;
  if (typeof r.productId !== "string") return null;
  return { productId: r.productId, reason: typeof r.reason === "string" ? r.reason : undefined };
}

/**
 * Splits raw assistant output into text and rich-card blocks.
 * Supports both `[RECOMMEND_PRODUCT]{...}[/RECOMMEND_PRODUCT]` and Flutter/Admin `[RECOMMEND_PRODUCT: id1, id2]`.
 */
export function parseAssistantContent(content: string): AssistantBlock[] {
  const blocks: AssistantBlock[] = [];
  let last = 0;
  const pushText = (t: string) => {
    const trimmed = t.replace(/\n{3,}/g, "\n\n").trim();
    if (trimmed) blocks.push({ kind: "text", text: trimmed });
  };
  for (const m of content.matchAll(TAG_RE)) {
    pushText(content.slice(last, m.index));
    last = (m.index ?? 0) + m[0].length;
    if (m[3]) {
      const ids = m[3]
        .split(/[,;\s]+/)
        .map((s) => s.trim())
        .filter(Boolean);
      for (const productId of ids) {
        blocks.push({ kind: "product", data: { productId } });
      }
      continue;
    }
    let json: unknown = null;
    if (m[4]) {
      // Hỗ trợ định dạng App/Admin: [CARE_SCHEDULE: water=3, fertilize=20, clean=3]
      const raw = m[4];
      const w = Number(raw.match(/water\s*=\s*(\d+)/i)?.[1]);
      const f = Number(raw.match(/fertilize\s*=\s*(\d+)/i)?.[1]);
      const c = Number(raw.match(/clean\s*=\s*(\d+)/i)?.[1]);
      if (Number.isFinite(w) && w >= 1 && w <= 120) {
        blocks.push({ kind: "care_schedule", data: { plantName: "Cây của bạn", careType: "watering", intervalDays: Math.round(w), preferredTime: "07:00", reason: "Đề xuất từ Trợ lý Floria" } });
      }
      if (Number.isFinite(f) && f >= 1 && f <= 120) {
        blocks.push({ kind: "care_schedule", data: { plantName: "Cây của bạn", careType: "fertilizing", intervalDays: Math.round(f), preferredTime: "08:30", reason: "Đề xuất từ Trợ lý Floria" } });
      }
      if (Number.isFinite(c) && c >= 1 && c <= 120) {
        blocks.push({ kind: "care_schedule", data: { plantName: "Cây của bạn", careType: "inspection", intervalDays: Math.round(c), preferredTime: "18:00", reason: "Đề xuất từ Trợ lý Floria" } });
      }
      continue;
    }
    try {
      json = JSON.parse(m[2].trim());
    } catch {
      continue;
    }
    if (m[1] === "CARE_SCHEDULE") {
      const d = parseCare(json);
      if (d) blocks.push({ kind: "care_schedule", data: d });
    } else {
      const d = parseProduct(json);
      if (d) blocks.push({ kind: "product", data: d });
    }
  }
  // strip any unterminated/stray tags from the tail
  pushText(content.slice(last).replace(/\[\/?(CARE_SCHEDULE|RECOMMEND_PRODUCT)\][\s\S]*$/g, ""));
  return blocks;
}
