import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import type { AssistantGuardrail } from "../config/route";

const GEMINI_MODELS = ["gemini-3-flash-preview", "gemini-flash-lite-latest"];

const CATALOG_CACHE_TTL_MS = 2 * 60_000;
let catalogCache: { text: string; expiresAt: number } | null = null;

async function getProductCatalogBlock(disabledIds: Set<string>): Promise<string> {
  if (!catalogCache || catalogCache.expiresAt <= Date.now()) {
    try {
      const snap = await getAdminDb().collection("ShopProducts").get();
      const items: Array<{ id: string; line: string }> = [];
      for (const doc of snap.docs) {
        const d = doc.data() ?? {};
        if (d.visible === false) continue;
        if (typeof d.stock === "number" && d.stock <= 0) continue;
        const name = String(d.name ?? "").trim();
        if (!name) continue;
        const indications = Array.isArray(d.indications) ? d.indications.join(", ") : "";
        const desc = String(d.shortDesc || d.description || "").trim();
        const info = [indications ? `Chỉ định: ${indications}` : "", desc].filter(Boolean).join(" · ");
        const short = info.length > 140 ? `${info.slice(0, 140)}...` : info;
        items.push({ id: doc.id, line: `- id: \`${doc.id}\` ➔ ${name}${short ? ` (${short})` : ""}` });
      }
      catalogCache = { text: JSON.stringify(items), expiresAt: Date.now() + CATALOG_CACHE_TTL_MS };
    } catch {
      return "";
    }
  }
  try {
    const parsed = JSON.parse(catalogCache.text) as Array<{ id: string; line: string }>;
    return parsed
      .filter((x) => !disabledIds.has(x.id))
      .map((x) => x.line)
      .join("\n");
  } catch {
    return "";
  }
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
      history?: Array<{ role: "user" | "model"; text: string }>;
      name?: string;
      tone?: string;
      defaultModel?: string;
      systemPrompt?: string;
      guardrails?: AssistantGuardrail[];
      disabledProductIds?: string[];
    };

    const message = String(body.message ?? "").trim();
    if (!message) {
      return NextResponse.json({ error: "Vui lòng nhập câu hỏi kiểm thử." }, { status: 400 });
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

    const activeRules = (body.guardrails ?? [])
      .filter((g) => g.enabled)
      .map((g, i) => `${i + 1}. [${g.name}]: ${g.ruleText}`)
      .join("\n");

    const disabledSet = new Set(Array.isArray(body.disabledProductIds) ? body.disabledProductIds : []);
    const catalogText = await getProductCatalogBlock(disabledSet);

    const fullSystemInstruction = [
      body.systemPrompt || 'Bạn là Trợ lý Floria - chuyên gia cây trồng.',
      body.name ? `Tên xưng hô: ${body.name}.` : "",
      body.tone ? `Giọng điệu: ${body.tone}.` : "",
      activeRules ? `\nQUY TẮC AN TOÀN (GUARDRAILS BẮT BUỘC):\n${activeRules}` : "",
      catalogText
        ? `\nKHO DƯỢC PHẨM & VẬT TƯ FLORIA (nếu kê đơn, ghi [RECOMMEND_PRODUCT: id] ở dòng cuối):\n${catalogText}`
        : "",
    ]
      .filter(Boolean)
      .join("\n");

    const t0 = Date.now();
    let reply = "";
    let usedModel = "";
    let lastErr = "";

    const modelsToTry = body.defaultModel?.trim()
      ? [body.defaultModel.trim(), ...GEMINI_MODELS.filter((m) => m !== body.defaultModel?.trim())]
      : GEMINI_MODELS;

    const contents = [
      ...(Array.isArray(body.history)
        ? body.history
            .filter((m) => m && m.text?.trim())
            .slice(-12)
            .map((m) => ({
              role: m.role === "model" ? "model" : "user",
              parts: [{ text: m.text }],
            }))
        : []),
      { role: "user", parts: [{ text: message }] },
    ];

    for (const model of modelsToTry) {
      try {
        const res = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(apiKey)}`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              systemInstruction: { parts: [{ text: fullSystemInstruction }] },
              contents,
              generationConfig: { temperature: 0.7, maxOutputTokens: 1024 },
            }),
          },
        );
        if (!res.ok) {
          lastErr = `HTTP ${res.status}`;
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
      } catch (e) {
        lastErr = e instanceof Error ? e.message : "Lỗi gọi LLM";
      }
    }

    if (!reply) {
      return NextResponse.json(
        { error: `Không thể nhận phản hồi từ LLM (${lastErr || "Timeout"}).` },
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
