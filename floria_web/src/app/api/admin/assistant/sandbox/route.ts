import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import {
  ANTI_HALLUCINATION_FALLBACK_RULE,
  buildActionTagsPromptBlock,
  filterGuardrailsByActionTags,
  getAssistantKnowledgeBlocks,
} from "@/lib/server/assistant-context";
import type { AssistantGuardrail } from "../config/route";

const GEMINI_MODELS = [
  "gemini-3.8-flash",
  "gemini-3-flash-preview",
  "gemini-3.5-flash-lite",
  "gemini-3.1-flash-lite",
  "gemini-3.1-flash-lite-preview",
  "gemini-3.6-flash",
];

type InlineImagePart = { inlineData: { mimeType: string; data: string } };

async function imageToInlinePart(src: string): Promise<InlineImagePart | null> {
  const trimmed = src.trim();
  if (!trimmed) return null;

  if (trimmed.startsWith("data:")) {
    const commaIdx = trimmed.indexOf(",");
    if (commaIdx === -1) return null;
    const header = trimmed.slice(5, commaIdx);
    const data = trimmed.slice(commaIdx + 1).trim();
    if (!data) return null;
    const mimeType = header.split(";")[0]?.trim() || "image/jpeg";
    return { inlineData: { mimeType, data } };
  }

  if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
    try {
      const res = await fetch(trimmed, { signal: AbortSignal.timeout(8_000) });
      if (!res.ok) return null;
      const blob = await res.blob();
      const buf = Buffer.from(await blob.arrayBuffer());
      return {
        inlineData: {
          mimeType: blob.type || "image/jpeg",
          data: buf.toString("base64"),
        },
      };
    } catch {
      return null;
    }
  }

  return null;
}

export async function POST(req: Request) {
  try {
    await verifyAdminRequest(req);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Lỗi xác thực" }, { status: 500 });
  }

  try {
    const body = (await req.json()) as {
      message?: string;
      images?: string[];
      history?: Array<{ role: "user" | "model"; text: string; images?: string[] }>;
      name?: string;
      tone?: string;
      defaultModel?: string;
      systemPrompt?: string;
      guardrails?: AssistantGuardrail[];
      disabledProductIds?: string[];
      enableProductTags?: boolean;
      enableCareScheduleTags?: boolean;
    };

    const message = String(body.message ?? "").trim();
    const images = Array.isArray(body.images)
      ? body.images.map(String).map((s) => s.trim()).filter(Boolean).slice(0, 3)
      : [];

    if (!message && images.length === 0) {
      return NextResponse.json({ error: "Vui lòng nhập câu hỏi hoặc đính kèm ảnh kiểm thử." }, { status: 400 });
    }

    const apiKey = (process.env.GEMINI_API_KEY || "").trim();
    if (!apiKey) {
      return NextResponse.json(
        {
          error: "Chưa cấu hình GEMINI_API_KEY trong .env.local của floria_web.",
        },
        { status: 400 },
      );
    }

    const enableProductTags = body.enableProductTags !== false;
    const enableCareScheduleTags = body.enableCareScheduleTags !== false;

    const guardrailsInput = filterGuardrailsByActionTags(body.guardrails ?? [], {
      enableProductTags,
      enableCareScheduleTags,
    });
    const activeRuleItems = guardrailsInput
      .filter((g) => g.enabled)
      .map((g) => `[${g.name}]: ${g.ruleText}`);
    const hasAntiHallucination = guardrailsInput.some(
      (g) => g.id === "gr_no_hallucination" || String(g.ruleText ?? "").includes("bịa đặt giá"),
    );
    if (!hasAntiHallucination) {
      activeRuleItems.push(ANTI_HALLUCINATION_FALLBACK_RULE);
    }
    const activeRules = activeRuleItems.map((rule, i) => `${i + 1}. ${rule}`).join("\n");

    const disabledSet = new Set(Array.isArray(body.disabledProductIds) ? body.disabledProductIds : []);
    const { catalogText, vouchersText, diseasesText, plantsText } = await getAssistantKnowledgeBlocks(disabledSet);
    const tagInstruction = buildActionTagsPromptBlock({
      enableProductTags,
      enableCareScheduleTags,
    });

    const fullSystemInstruction = [
      body.systemPrompt || 'Bạn là Trợ lý Floria - chuyên gia cây trồng.',
      body.name ? `Tên xưng hô: ${body.name}.` : "",
      body.tone ? `Giọng điệu: ${body.tone}.` : "",
      activeRules ? `\nQUY TẮC AN TOÀN (GUARDRAILS BẮT BUỘC):\n${activeRules}` : "",
      catalogText ? `\nKHO SẢN PHẨM & BẢNG GIÁ FLORIA HIỆN CÓ:\n${catalogText}` : "",
      vouchersText ? `\nMÃ GIẢM GIÁ (VOUCHER) ĐANG HOẠT ĐỘNG:\n${vouchersText}` : "",
      diseasesText ? `\nHỒ SƠ BỆNH LÝ CÂY TRỒNG TRONG HỆ THỐNG:\n${diseasesText}` : "",
      plantsText ? `\nTỪ ĐIỂN CÂY CẢNH TRONG HỆ THỐNG:\n${plantsText}` : "",
      tagInstruction,
    ]
      .filter(Boolean)
      .join("\n");

    const t0 = Date.now();
    let reply = "";
    let usedModel = "";
    const attemptErrors: string[] = [];

    const modelsToTry = body.defaultModel?.trim()
      ? [body.defaultModel.trim(), ...GEMINI_MODELS.filter((m) => m !== body.defaultModel?.trim())]
      : GEMINI_MODELS;

    const rawHistory = Array.isArray(body.history)
      ? body.history
          .filter((m) => m && (m.text?.trim() || (Array.isArray(m.images) && m.images.length > 0)))
          .slice(-12)
      : [];

    // Giữ lại tối đa 2 lượt user gần nhất có ảnh để giữ ngữ cảnh mà không phình payload
    let remainingHistoryImageTurns = 2;
    const historyImageTurnsToKeep = new Set<number>();
    for (let i = rawHistory.length - 1; i >= 0 && remainingHistoryImageTurns > 0; i--) {
      const m = rawHistory[i];
      if (m.role !== "model" && Array.isArray(m.images) && m.images.length > 0) {
        historyImageTurnsToKeep.add(i);
        remainingHistoryImageTurns -= 1;
      }
    }

    const historyContents = await Promise.all(
      rawHistory.map(async (m, idx) => {
        const parts: Array<Record<string, unknown>> = [];
        const textVal = String(m.text ?? "").trim();
        if (textVal) {
          parts.push({ text: textVal });
        }
        if (historyImageTurnsToKeep.has(idx) && Array.isArray(m.images)) {
          for (const img of m.images.slice(0, 3)) {
            const part = await imageToInlinePart(String(img));
            if (part) parts.push(part);
          }
        }
        if (parts.length === 0) {
          parts.push({ text: "[Người dùng đã gửi ảnh cây trồng]" });
        }
        return {
          role: m.role === "model" ? "model" : "user",
          parts,
        };
      }),
    );

    const userParts: Array<Record<string, unknown>> = [];
    userParts.push({
      text: message || "Hãy nhận diện và tư vấn tình trạng cây trồng trong ảnh này.",
    });

    let attachedImageCount = 0;
    for (const img of images) {
      const part = await imageToInlinePart(img);
      if (part) {
        userParts.push(part);
        attachedImageCount += 1;
      }
    }

    if (!message && attachedImageCount === 0) {
      return NextResponse.json({ error: "Ảnh đính kèm không hợp lệ." }, { status: 400 });
    }

    const contents = [
      ...historyContents,
      { role: "user", parts: userParts },
    ];

    for (const model of modelsToTry) {
      try {
        const res = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(apiKey)}`,
          {
            method: "POST",
            signal: AbortSignal.timeout(25_000),
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              systemInstruction: { parts: [{ text: fullSystemInstruction }] },
              contents,
              generationConfig: { temperature: 0.7, maxOutputTokens: 2048 },
            }),
          },
        );
        if (!res.ok) {
          const errBody = await res.text().catch(() => "");
          attemptErrors.push(`${model}: HTTP ${res.status}${errBody ? ` - ${errBody.slice(0, 120)}` : ""}`);
          continue;
        }
        const json = (await res.json()) as {
          candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
        };
        const text = json.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
        if (text) {
          reply = text;
          usedModel = model;
          break;
        }
        attemptErrors.push(`${model}: empty response`);
      } catch (e) {
        attemptErrors.push(`${model}: ${e instanceof Error ? e.message : "timeout"}`);
      }
    }

    if (!reply) {
      return NextResponse.json(
        { error: `Không thể nhận phản hồi từ LLM (${attemptErrors.join(" | ") || "Timeout"}).` },
        { status: 502 },
      );
    }

    const detectedTags: string[] = [];
    const prodMatches = reply.match(/\[RECOMMEND_PRODUCT:\s*[^\]]+\]/g);
    if (prodMatches) detectedTags.push(...prodMatches);
    if (/\[CARE_SCHEDULE:/i.test(reply)) detectedTags.push("[CARE_SCHEDULE]");

    return NextResponse.json({
      reply,
      model: usedModel,
      latencyMs: Date.now() - t0,
      detectedTags,
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Lỗi kiểm thử Trợ lý";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
