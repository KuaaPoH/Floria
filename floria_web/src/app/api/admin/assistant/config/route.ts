import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";

export interface AssistantGuardrail {
  id: string;
  name: string;
  category: "care" | "toxicity" | "medical" | "scope";
  ruleText: string;
  enabled: boolean;
}

export interface AssistantConfig {
  name: string;
  tone: string;
  language: string;
  defaultModel: string;
  systemPrompt: string;
  guardrails: AssistantGuardrail[];
  disabledProductIds?: string[];
  updatedAt?: string;
  updatedBy?: string;
}

const DEFAULT_ASSISTANT_CONFIG: AssistantConfig = {
  name: "Trợ lý Floria",
  tone: "100% tiếng Việt tự nhiên, ấm áp, chuẩn khoa học thực vật",
  language: "vi",
  defaultModel: "gemini-3-flash-preview",
  disabledProductIds: [],
  systemPrompt:
    'Bạn là Trợ lý Cây trồng Floria (hoặc Trợ lý Floria) - chuyên gia nông nghiệp và thực vật học giàu kinh nghiệm, khách quan, tận tâm và gần gũi.\nNgôn ngữ trả lời: 100% tiếng Việt tự nhiên, ấm áp, chuẩn khoa học thực vật.\nXƯNG HÔ: Tự xưng là "Trợ lý Floria" (TUYỆT ĐỐI KHÔNG tự xưng là "Floria AI", "Bác sĩ AI" hay dùng từ "AI").',
  guardrails: [
    {
      id: "gr_scope",
      name: "Giới hạn phạm vi chủ đề nghiêm ngặt",
      category: "scope",
      ruleText:
        "CHỈ tư vấn cây cối, thực vật học, chăm sóc cây, sâu bệnh và vật tư Floria. TUYỆT ĐỐI TỪ CHỐI mọi câu hỏi/ảnh ngoài chủ đề (lập trình, toán, lịch sử, y tế người, nấu ăn, tài chính...). Khi từ chối KHÔNG đính kèm [RECOMMEND_PRODUCT] hay [CARE_SCHEDULE].",
      enabled: true,
    },
    {
      id: "gr_natural_first",
      name: "Ưu tiên giải pháp chăm sóc tự nhiên",
      category: "care",
      ruleText:
        "Luôn ưu tiên điều chỉnh ánh sáng, độ ẩm, nước tưới, độ thông thoáng trước khi nghĩ đến thuốc hay phân bón. Không gượng ép bán sản phẩm.",
      enabled: true,
    },
    {
      id: "gr_prescribe",
      name: "Quy tắc kê đơn thuốc / vật tư chặt chẽ",
      category: "care",
      ruleText:
        "KHÔNG gắn [RECOMMEND_PRODUCT: id] nếu chỉ hỏi kiến thức cơ bản hoặc vấn đề sinh lý nhẹ. CHỈ gắn khi cây bệnh/sâu hại nặng cần đặc trị HOẶC người dùng chủ động hỏi mua thuốc/phân/đất.",
      enabled: true,
    },
    {
      id: "gr_care_schedule",
      name: "Quy tắc đính kèm lịch chăm sóc",
      category: "care",
      ruleText:
        "CHỈ gắn [CARE_SCHEDULE: water=..., fertilize=..., clean=...] khi hỏi toàn diện về cách chăm sóc cây. KHÔNG gắn khi chỉ hỏi mua phân/thuốc hoặc chữa bệnh, không viết tiêu đề cụt lủn ở cuối.",
      enabled: true,
    },
    {
      id: "gr_toxicity",
      name: "Cảnh báo độc tính & Cấm chữa bệnh người",
      category: "toxicity",
      ruleText:
        "Cảnh báo rõ nếu cây có độc tính với thú cưng/trẻ nhỏ, và tuyệt đối không hướng dẫn dùng cây cảnh làm thuốc chữa bệnh cho người.",
      enabled: true,
    },
  ],
};

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const snap = await getAdminDb().collection("SystemConfig").doc("assistant_config").get();
    if (!snap.exists) {
      return NextResponse.json(DEFAULT_ASSISTANT_CONFIG);
    }
    const raw = snap.data() ?? {};
    return NextResponse.json({
      ...DEFAULT_ASSISTANT_CONFIG,
      name: typeof raw.name === "string" && raw.name ? raw.name : DEFAULT_ASSISTANT_CONFIG.name,
      tone: typeof raw.tone === "string" && raw.tone ? raw.tone : DEFAULT_ASSISTANT_CONFIG.tone,
      language: typeof raw.language === "string" && raw.language ? raw.language : DEFAULT_ASSISTANT_CONFIG.language,
      defaultModel:
        typeof raw.defaultModel === "string" && raw.defaultModel.trim()
          ? raw.defaultModel.trim()
          : DEFAULT_ASSISTANT_CONFIG.defaultModel,
      systemPrompt:
        typeof raw.systemPrompt === "string" && raw.systemPrompt
          ? raw.systemPrompt
          : DEFAULT_ASSISTANT_CONFIG.systemPrompt,
      guardrails: Array.isArray(raw.guardrails) ? raw.guardrails : DEFAULT_ASSISTANT_CONFIG.guardrails,
      disabledProductIds: Array.isArray(raw.disabledProductIds)
        ? raw.disabledProductIds.map((x) => String(x))
        : [],
      updatedAt: typeof raw.updatedAt === "string" ? raw.updatedAt : undefined,
      updatedBy: typeof raw.updatedBy === "string" ? raw.updatedBy : undefined,
    });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const msg = err instanceof Error ? err.message : "Lỗi đọc cấu hình Trợ lý Floria";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}

export async function PUT(req: Request) {
  try {
    const admin = await verifyAdminRequest(req);
    const body = (await req.json()) as Partial<AssistantConfig>;

    const nextCfg: AssistantConfig = {
      name: String(body.name ?? DEFAULT_ASSISTANT_CONFIG.name).trim() || DEFAULT_ASSISTANT_CONFIG.name,
      tone: String(body.tone ?? DEFAULT_ASSISTANT_CONFIG.tone).trim() || DEFAULT_ASSISTANT_CONFIG.tone,
      language: String(body.language ?? "vi"),
      defaultModel:
        String(body.defaultModel ?? DEFAULT_ASSISTANT_CONFIG.defaultModel).trim() ||
        DEFAULT_ASSISTANT_CONFIG.defaultModel,
      systemPrompt: String(body.systemPrompt ?? DEFAULT_ASSISTANT_CONFIG.systemPrompt).trim(),
      guardrails: Array.isArray(body.guardrails) ? body.guardrails : DEFAULT_ASSISTANT_CONFIG.guardrails,
      disabledProductIds: Array.isArray(body.disabledProductIds)
        ? body.disabledProductIds.map((x) => String(x))
        : [],
      updatedAt: new Date().toISOString(),
      updatedBy: admin.name,
    };

    await getAdminDb().collection("SystemConfig").doc("assistant_config").set(nextCfg, { merge: true });
    return NextResponse.json(nextCfg);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const msg = err instanceof Error ? err.message : "Lỗi lưu cấu hình Trợ lý Floria";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
