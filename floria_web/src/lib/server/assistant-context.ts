import { getAdminDb } from "@/lib/server/firebase-admin";

const CONTEXT_CACHE_TTL_MS = 2 * 60_000;

interface CachedKnowledge {
  products: Array<{ id: string; line: string }>;
  vouchersText: string;
  diseasesText: string;
  plantsText: string;
  expiresAt: number;
}

let knowledgeCache: CachedKnowledge | null = null;

export const ANTI_HALLUCINATION_FALLBACK_RULE =
  "[Cấm bịa đặt số liệu, giá bán & dữ liệu hệ thống]: TUYỆT ĐỐI KHÔNG tự suy đoán hoặc bịa đặt giá bán, giá gốc, chương trình giảm giá, mã voucher, số lượng tồn kho, quy cách đóng gói hay thông tin khu vườn của người dùng. Mọi con số về giá tiền, khuyến mãi, tồn kho và lịch chăm sóc PHẢI lấy chính xác 100% từ dữ liệu hệ thống cung cấp trong ngữ cảnh. Nếu không có trong dữ liệu, phải nói rõ là hiện chưa có thông tin/sản phẩm đó trên hệ thống Floria.";

export function formatVndServer(amount: number): string {
  const rounded = Math.round(Number.isFinite(amount) ? amount : 0);
  return `${rounded.toLocaleString("vi-VN")}đ`;
}

function formatProductLine(id: string, d: Record<string, unknown>): string | null {
  if (d.visible === false) return null;
  const stock = typeof d.stock === "number" ? d.stock : d.inStock === false ? 0 : 25;
  if (stock <= 0 || d.inStock === false) return null;

  const name = String(d.name ?? "").trim();
  if (!name) return null;

  const price = Number(d.price ?? 0);
  const originalPrice = Number(d.originalPrice ?? 0);
  const category = String(d.category ?? "").trim();
  const indications = Array.isArray(d.indications) ? d.indications.map(String).filter(Boolean).join(", ") : "";
  const usageGuide = String(d.usageGuide ?? d.usage ?? "").trim().replace(/\s+/g, " ");
  const desc = String(d.shortDesc || d.shortDescription || d.description || "").trim().replace(/\s+/g, " ");

  const pricePart =
    price > 0
      ? originalPrice > price
        ? `Giá bán: ${formatVndServer(price)} (giá gốc ${formatVndServer(originalPrice)}, đang giảm giá)`
        : `Giá bán: ${formatVndServer(price)}`
      : "Giá bán: Chưa cập nhật";

  const details = [
    category ? `Nhóm: ${category}` : "",
    pricePart,
    `Tồn kho: ${stock}`,
    indications ? `Chỉ định: ${indications}` : "",
    usageGuide ? `Cách dùng: ${usageGuide.slice(0, 140)}` : "",
    desc ? `Mô tả: ${desc.slice(0, 120)}` : "",
  ]
    .filter(Boolean)
    .join(" · ");

  return `- id: \`${id}\` ➔ ${name} (${details})`;
}

function formatVoucherLine(id: string, d: Record<string, unknown>): string | null {
  if (d.active === false || d.isActive === false) return null;
  if (d.type === "shipping" || d.discountType === "shipping") return null;

  const expiresRaw = d.expiresAt ?? d.expiryDate;
  let expiresLabel = "";
  if (typeof expiresRaw === "string" && expiresRaw.trim()) {
    const ms = Date.parse(expiresRaw);
    if (Number.isFinite(ms)) {
      if (ms < Date.now()) return null;
      expiresLabel = `, HSD: ${new Date(ms).toLocaleDateString("vi-VN")}`;
    }
  }

  const code = String(d.code ?? id).trim().toUpperCase();
  if (!code) return null;

  const isFixed = d.type === "fixed" || d.discountType === "fixed";
  const value = Number(d.value ?? d.discountValue ?? 0);
  const minOrder = Number(d.minOrder ?? d.minOrderAmount ?? 0);
  const maxDiscount = typeof d.maxDiscount === "number" && d.maxDiscount > 0 ? d.maxDiscount : null;

  const discountDesc = isFixed
    ? `giảm ${formatVndServer(value)}`
    : `giảm ${value}%${maxDiscount ? ` (tối đa ${formatVndServer(maxDiscount)})` : ""}`;
  const minDesc = minOrder > 0 ? `, đơn tối thiểu ${formatVndServer(minOrder)}` : ", không giới hạn đơn tối thiểu";
  const title = String(d.description ?? d.title ?? "").trim();

  return `- Mã \`${code}\`: ${discountDesc}${minDesc}${expiresLabel}${title ? ` — ${title}` : ""}`;
}

function formatDiseaseLine(id: string, d: Record<string, unknown>): string | null {
  const nameVi = String(d.nameVi ?? d.name ?? id).trim();
  if (!nameVi) return null;
  const severity = String(d.severity ?? "").trim();
  const pathogen = String(d.pathogen ?? d.agent ?? "").trim();
  const symptoms = Array.isArray(d.symptoms)
    ? d.symptoms.map(String).join("; ")
    : String(d.symptoms ?? d.mechanism ?? "").trim();
  const treatment = Array.isArray(d.treatmentSteps)
    ? d.treatmentSteps.map(String).slice(0, 3).join("; ")
    : Array.isArray(d.treatment)
      ? d.treatment.map(String).slice(0, 3).join("; ")
      : "";
  const relatedIds = Array.isArray(d.relatedProductIds)
    ? d.relatedProductIds.map(String).filter(Boolean).join(", ")
    : "";

  const parts = [
    severity ? `Mức độ: ${severity}` : "",
    pathogen ? `Tác nhân: ${pathogen}` : "",
    symptoms ? `Triệu chứng: ${symptoms.slice(0, 120)}` : "",
    treatment ? `Xử lý: ${treatment.slice(0, 140)}` : "",
    relatedIds ? `Vật tư gợi ý: ${relatedIds}` : "",
  ]
    .filter(Boolean)
    .join(" · ");

  return `- ${nameVi} (${id})${parts ? `: ${parts}` : ""}`;
}

function formatPlantInfoLine(id: string, d: Record<string, unknown>): string | null {
  if (d.status === "draft") return null;
  const nameVi = String(d.name_vi ?? d.viName ?? "").trim();
  const sci = String(d.scientific_name ?? d.sciName ?? id).trim();
  if (!nameVi && !sci) return null;

  const light = String(d.light ?? "").trim();
  const water = String(d.water_frequency ?? d.watering ?? "").trim();
  const temp = String(d.temperature ?? "").trim();
  const humidity = String(d.humidity ?? "").trim();
  const toxicity = String(d.toxicity ?? d.toxicityNote ?? "").trim();

  const parts = [
    light ? `Ánh sáng: ${light}` : "",
    water ? `Tưới: ${water}` : "",
    temp ? `Nhiệt độ: ${temp}` : "",
    humidity ? `Độ ẩm: ${humidity}` : "",
    toxicity ? `Độc tính: ${toxicity}` : "",
  ]
    .filter(Boolean)
    .join(" · ");

  return `- ${nameVi ? `${nameVi} (${sci})` : sci}${parts ? `: ${parts}` : ""}`;
}

async function loadCachedKnowledge(): Promise<CachedKnowledge> {
  if (knowledgeCache && knowledgeCache.expiresAt > Date.now()) {
    return knowledgeCache;
  }

  const db = getAdminDb();
  const [prodSnap, voucherSnap, diseasesSnap, plantsSnap] = await Promise.all([
    db.collection("ShopProducts").get().catch(() => null),
    db.collection("Vouchers").get().catch(() => null),
    db.collection("DiseasesInfo").get().catch(() => null),
    db.collection("plants_info").get().catch(() => null),
  ]);

  const products: Array<{ id: string; line: string }> = [];
  for (const doc of prodSnap?.docs ?? []) {
    const line = formatProductLine(doc.id, doc.data() ?? {});
    if (line) products.push({ id: doc.id, line });
  }

  const voucherLines = (voucherSnap?.docs ?? [])
    .map((doc) => formatVoucherLine(doc.id, doc.data() ?? {}))
    .filter((x): x is string => Boolean(x));

  const diseaseLines = (diseasesSnap?.docs ?? [])
    .map((doc) => formatDiseaseLine(doc.id, doc.data() ?? {}))
    .filter((x): x is string => Boolean(x));

  const plantLines = (plantsSnap?.docs ?? [])
    .map((doc) => formatPlantInfoLine(doc.id, doc.data() ?? {}))
    .filter((x): x is string => Boolean(x));

  knowledgeCache = {
    products,
    vouchersText: voucherLines.join("\n"),
    diseasesText: diseaseLines.join("\n"),
    plantsText: plantLines.join("\n"),
    expiresAt: Date.now() + CONTEXT_CACHE_TTL_MS,
  };

  return knowledgeCache;
}

export async function getAssistantKnowledgeBlocks(disabledIds: Set<string>): Promise<{
  catalogText: string;
  vouchersText: string;
  diseasesText: string;
  plantsText: string;
}> {
  const cached = await loadCachedKnowledge();
  return {
    catalogText: cached.products
      .filter((p) => !disabledIds.has(p.id))
      .map((p) => p.line)
      .join("\n"),
    vouchersText: cached.vouchersText,
    diseasesText: cached.diseasesText,
    plantsText: cached.plantsText,
  };
}

export function filterGuardrailsByActionTags<T extends { id?: string; name?: string; ruleText?: string }>(
  rules: T[],
  options: { enableProductTags: boolean; enableCareScheduleTags: boolean },
): T[] {
  return rules.filter((g) => {
    const id = String(g.id ?? "");
    const text = String(g.ruleText ?? "");
    if (!options.enableProductTags && (id === "gr_prescribe" || text.includes("[RECOMMEND_PRODUCT"))) {
      return false;
    }
    if (!options.enableCareScheduleTags && (id === "gr_care_schedule" || text.includes("[CARE_SCHEDULE"))) {
      return false;
    }
    return true;
  });
}

export function buildActionTagsPromptBlock(options: {
  enableProductTags: boolean;
  enableCareScheduleTags: boolean;
}): string {
  const sections: string[] = [];

  if (options.enableProductTags) {
    sections.push(
      `THẺ HÀNH ĐỘNG ĐỀ XUẤT SẢN PHẨM (CHỈ dùng khi cây bệnh/sâu hại nặng cần đặc trị HOẶC người dùng hỏi mua/tìm/lọc sản phẩm theo tầm giá, công dụng):
Gắn ở cuối câu trả lời đúng cú pháp (mỗi sản phẩm 1 thẻ hoặc liệt kê id chính xác từ KHO SẢN PHẨM):
[RECOMMEND_PRODUCT: id_san_pham]`,
    );
  } else {
    sections.push(
      `THẺ HÀNH ĐỘNG SẢN PHẨM ĐANG TẮT: TUYỆT ĐỐI KHÔNG chèn hoặc xuất ra thẻ [RECOMMEND_PRODUCT...] dưới bất kỳ hình thức nào.`,
    );
  }

  if (options.enableCareScheduleTags) {
    sections.push(
      `THẺ HÀNH ĐỘNG ĐỀ XUẤT LỊCH CHĂM SÓC (CHỈ dùng khi người dùng hỏi lịch/cách chăm sóc cây toàn diện):
Gắn ở cuối câu trả lời đúng cú pháp:
[CARE_SCHEDULE: water=SO_NGAY_TUOI, fertilize=SO_NGAY_BON_PHAN, clean=SO_NGAY_KIEM_TRA]
(Quy ước: water 1-14, fertilize 7-60, clean 1-14; không viết dòng tiêu đề cụt lủn ngay trước thẻ).`,
    );
  } else {
    sections.push(
      `THẺ HÀNH ĐỘNG LỊCH CHĂM SÓC ĐANG TẮT: TUYỆT ĐỐI KHÔNG chèn hoặc xuất ra thẻ [CARE_SCHEDULE...] dưới bất kỳ hình thức nào.`,
    );
  }

  return sections.join("\n\n");
}
