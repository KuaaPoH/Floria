import { NextResponse } from "next/server";
import {
  ANTI_HALLUCINATION_FALLBACK_RULE,
  buildActionTagsPromptBlock,
  filterGuardrailsByActionTags,
  getAssistantKnowledgeBlocks,
} from "@/lib/server/assistant-context";
import { getAdminDb, isFirebaseAdminConfigured } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import { UserAuthError, verifyUserRequest } from "@/lib/server/user-auth";
import type { ChatMessage, ChatSession } from "@/types/user";

const DEFAULT_MODELS = [
  "gemini-3.8-flash",
  "gemini-3-flash-preview",
  "gemini-3.5-flash-lite",
  "gemini-3.1-flash-lite",
  "gemini-3.1-flash-lite-preview",
  "gemini-3.6-flash",
];

async function imageToInlinePart(src: string): Promise<{ inlineData: { mimeType: string; data: string } } | null> {
  try {
    const res = await fetch(src);
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

function mapMessage(sessionId: string, raw: unknown, index: number): ChatMessage {
  const m = (typeof raw === "object" && raw !== null ? raw : {}) as Record<string, unknown>;
  const isUser = typeof m.isUser === "boolean" ? m.isUser : m.role === "user";
  let text = String(m.text ?? m.content ?? "");
  const recIds = Array.isArray(m.recommendedProductIds) ? m.recommendedProductIds.map(String).filter(Boolean) : [];
  if (!isUser && recIds.length > 0 && !text.includes("[RECOMMEND_PRODUCT")) {
    const extra = recIds
      .map((pid) => `[RECOMMEND_PRODUCT]${JSON.stringify({ productId: pid })}[/RECOMMEND_PRODUCT]`)
      .join("\n");
    text = `${text}\n\n${extra}`.trim();
  }
  const images = Array.isArray(m.images) ? m.images.map(String).filter(Boolean) : [];
  const createdAt = toIsoString(m.timestamp ?? m.createdAt);

  return {
    id: String(m.id ?? `${sessionId}_m_${index}`),
    sessionId,
    role: isUser ? "user" : "assistant",
    content: text,
    images,
    createdAt,
    status: "sent",
  };
}

function mapSession(id: string, d: Record<string, unknown>): ChatSession {
  return {
    id,
    userId: String(d.userId ?? ""),
    title: String(d.title ?? "Cuộc trò chuyện mới"),
    createdAt: toIsoString(d.createdAt),
    updatedAt: toIsoString(d.updatedAt ?? d.createdAt),
  };
}

export async function GET(req: Request) {
  if (!isFirebaseAdminConfigured()) {
    return NextResponse.json({ error: "Firebase Admin chưa được cấu hình" }, { status: 503 });
  }
  try {
    const user = await verifyUserRequest(req);
    const db = getAdminDb();
    const url = new URL(req.url);
    const sessionId = url.searchParams.get("sessionId");

    if (sessionId) {
      const snap = await db.collection("ChatSessions").doc(sessionId).get();
      if (!snap.exists || snap.data()?.userId !== user.uid) {
        return NextResponse.json([]);
      }
      const rawMsgs = Array.isArray(snap.data()?.messages) ? (snap.data()!.messages as unknown[]) : [];
      return NextResponse.json(rawMsgs.map((m, idx) => mapMessage(sessionId, m, idx)));
    }

    const snap = await db.collection("ChatSessions").where("userId", "==", user.uid).get();
    const sessions = snap.docs
      .map((doc) => mapSession(doc.id, doc.data()))
      .sort((a, b) => Date.parse(b.updatedAt) - Date.parse(a.updatedAt));

    return NextResponse.json(sessions);
  } catch (err) {
    if (err instanceof UserAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: (err as Error).message || "Không thể tải hội thoại" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  if (!isFirebaseAdminConfigured()) {
    return NextResponse.json({ error: "Firebase Admin chưa được cấu hình" }, { status: 503 });
  }

  try {
    const user = await verifyUserRequest(req);
    const db = getAdminDb();
    const body = (await req.json()) as Record<string, unknown>;
    const action = String(body.action ?? (body.message ? "send" : ""));
    const now = Date.now();
    const nowIso = new Date(now).toISOString();

    if (action === "create") {
      const title = String(body.title ?? "Cuộc trò chuyện mới").trim() || "Cuộc trò chuyện mới";
      const payload = {
        userId: user.uid,
        title,
        createdAt: nowIso,
        updatedAt: nowIso,
        messages: [],
      };
      const ref = await db.collection("ChatSessions").add(payload);
      return NextResponse.json(mapSession(ref.id, payload), { status: 201 });
    }

    if (action === "rename") {
      const id = String(body.sessionId ?? body.id ?? "");
      const title = String(body.title ?? "").trim() || "Cuộc trò chuyện mới";
      const ref = db.collection("ChatSessions").doc(id);
      const snap = await ref.get();
      if (!snap.exists || snap.data()?.userId !== user.uid) {
        return NextResponse.json({ error: "Không tìm thấy hội thoại." }, { status: 404 });
      }
      await ref.set({ title, updatedAt: nowIso }, { merge: true });
      return NextResponse.json(mapSession(id, { ...snap.data(), title, updatedAt: nowIso }));
    }

    if (action === "delete") {
      const id = String(body.sessionId ?? body.id ?? "");
      const ref = db.collection("ChatSessions").doc(id);
      const snap = await ref.get();
      if (!snap.exists || snap.data()?.userId !== user.uid) {
        return NextResponse.json({ error: "Không tìm thấy hội thoại." }, { status: 404 });
      }
      await ref.delete();
      return NextResponse.json({ deleted: true });
    }

    if (action === "send") {
      const apiKey = (process.env.GEMINI_API_KEY ?? "").trim();
      if (!apiKey) {
        return NextResponse.json({ error: "Chưa cấu hình GEMINI_API_KEY trên máy chủ." }, { status: 503 });
      }

      const sessionId = String(body.sessionId ?? "");
      const content = String(body.content ?? body.message ?? "").trim();
      const images = Array.isArray(body.images) ? body.images.map(String).filter(Boolean) : [];
      if (!content && images.length === 0) {
        return NextResponse.json({ error: "Thiếu nội dung tin nhắn." }, { status: 400 });
      }

      const sessionRef = db.collection("ChatSessions").doc(sessionId);
      const sessionSnap = await sessionRef.get();
      if (!sessionSnap.exists || sessionSnap.data()?.userId !== user.uid) {
        return NextResponse.json({ error: "Không tìm thấy hội thoại." }, { status: 404 });
      }
      const sd = sessionSnap.data() ?? {};
      const existingMsgs = Array.isArray(sd.messages) ? (sd.messages as Record<string, unknown>[]) : [];

      // Đọc SystemConfig/assistant_config + MyGarden + UserGardens của user
      const [cfgSnap, gardenSnap, userGardensSnap] = await Promise.all([
        db.collection("SystemConfig").doc("assistant_config").get().catch(() => null),
        db.collection("MyGarden").where("userId", "==", user.uid).get().catch(() => null),
        db.collection("UserGardens").where("userId", "==", user.uid).get().catch(() => null),
      ]);

      const cfg = (cfgSnap?.exists ? cfgSnap.data() : {}) as Record<string, unknown>;
      const assistantName = String(cfg.name ?? "Trợ lý Floria");
      const tone = String(cfg.tone ?? "Thân thiện, chuyên môn thực vật rõ ràng");
      const defaultModel = String(cfg.defaultModel ?? "").trim();
      const enableProductTags = cfg.enableProductTags !== false;
      const enableCareScheduleTags = cfg.enableCareScheduleTags !== false;
      let basePrompt =
        typeof cfg.systemPrompt === "string" && cfg.systemPrompt.trim()
          ? cfg.systemPrompt.trim()
          : "Bạn là Trợ lý Floria — bác sĩ cây trồng AI. Chỉ tư vấn về thực vật, trồng cây, chăm sóc cây, sâu bệnh, môi trường trồng và làm vườn. Từ chối lịch sự các chủ đề ngoài phạm vi. Trả lời bằng tiếng Việt rõ ràng, thân thiện.";

      const rawGuardrails = Array.isArray(cfg.guardrails)
        ? (cfg.guardrails as Array<{ id?: string; name?: string; ruleText?: string; enabled?: boolean }>)
        : [];
      const filteredGuardrails = filterGuardrailsByActionTags(rawGuardrails, {
        enableProductTags,
        enableCareScheduleTags,
      });
      const activeRulesList = filteredGuardrails
        .filter((g) => g.enabled !== false && g.ruleText)
        .map((g) => `[${g.name ?? "Quy tắc"}]: ${g.ruleText}`);
      const hasAntiHallucination = filteredGuardrails.some(
        (g) => g.id === "gr_no_hallucination" || String(g.ruleText ?? "").includes("bịa đặt giá"),
      );
      if (!hasAntiHallucination) {
        activeRulesList.push(ANTI_HALLUCINATION_FALLBACK_RULE);
      }
      const guardrails = activeRulesList.map((rule, i) => `${i + 1}. ${rule}`).join("\n");

      const disabledIds = new Set(Array.isArray(cfg.disabledProductIds) ? cfg.disabledProductIds.map(String) : []);
      const { catalogText, vouchersText, diseasesText, plantsText } = await getAssistantKnowledgeBlocks(disabledIds);

      // Xây dựng bản đồ khu vườn: gardenId -> gardenName
      const gardenMap = new Map<string, string>();
      const userGardenList: string[] = [];

      (userGardensSnap?.docs ?? []).forEach((doc) => {
        const gd = doc.data();
        const gName = String(gd.name ?? "Khu vườn").trim();
        gardenMap.set(doc.id, gName);
        const env = String(gd.environment ?? "").trim();
        const light = String(gd.lightCondition ?? "").trim();
        const desc = String(gd.description ?? "").trim();
        userGardenList.push(
          `- Khu vườn "${gName}" (Mã vườn: ${doc.id}${env ? `, Môi trường: ${env}` : ""}${light ? `, Ánh sáng: ${light}` : ""}${desc ? `, Ghi chú: ${desc}` : ""})`,
        );
      });

      const parseDueFlag = (rawTs: unknown, freqDays: number): boolean => {
        if (freqDays <= 0 || !rawTs) return false;
        const iso = toIsoString(rawTs, "");
        if (!iso) return false;
        const ms = Date.parse(iso);
        return Number.isFinite(ms) && ms - now <= 12 * 3600 * 1000;
      };

      const gardenLines = (gardenSnap?.docs ?? [])
        .slice(0, 50)
        .map((doc) => {
          const gd = doc.data();
          const gId = String(gd.gardenId ?? "").trim();
          const resolvedGardenName = (gId && gardenMap.get(gId)) || String(gd.gardenName ?? "").trim() || "Khu vườn chính";
          const plantName = String(gd.nickname ?? gd.nameVi ?? "Cây");
          const sciName = String(gd.scientificName ?? gd.nameVi ?? "");
          const zone = String(gd.zone ?? gd.location ?? "Trong nhà");
          const health = String(gd.healthStatus ?? "Khỏe mạnh");
          const waterDays = Number(gd.waterFrequencyDays ?? 3);
          const fertDays = Number(gd.fertilizeFrequencyDays ?? 20);
          const pestDays = Number(gd.checkPestFrequencyDays ?? 3);
          const dueTasks: string[] = [];
          if (parseDueFlag(gd.nextWatering, waterDays)) dueTasks.push("Cần tưới nước hôm nay");
          if (parseDueFlag(gd.nextFertilizing, fertDays)) dueTasks.push("Cần bón phân hôm nay");
          if (parseDueFlag(gd.nextCheckPest, pestDays)) dueTasks.push("Cần kiểm tra sâu bệnh hôm nay");
          const notes = String(gd.notes ?? "").trim();
          return `- "${plantName}" (${sciName}) -> Khu vườn: "${resolvedGardenName}", Vị trí: ${zone}, Trạng thái: ${health}, Chu kỳ: tưới ${waterDays} ngày / bón phân ${fertDays} ngày / kiểm tra ${pestDays} ngày${dueTasks.length ? `, Việc đến hạn: ${dueTasks.join(", ")}` : ""}${notes ? `, Ghi chú: ${notes.slice(0, 80)}` : ""}`;
        })
        .join("\n");

      const tagInstruction = buildActionTagsPromptBlock({
        enableProductTags,
        enableCareScheduleTags,
      });

      const gardensSection = userGardenList.length > 0
        ? `\nDANH SÁCH CÁC KHU VƯỜN CỦA NGƯỜI DÙNG (${userGardenList.length} khu vườn):\n${userGardenList.join("\n")}`
        : "";

      const gardenInstruction = gardenMap.size > 0
        ? `\n(LƯU Ý ĐẶC BIỆT: Khi người dùng hỏi cây nằm ở khu vườn nào, lịch chăm sóc hay cây nào cần tưới hôm nay, hãy đối chiếu chính xác tên khu vườn, ánh sáng, chu kỳ và việc đến hạn thực tế của họ để trả lời chi tiết).`
        : "";

      const plantsSection = gardenLines
        ? `\nDANH SÁCH CÂY TRONG TỪNG KHU VƯỜN CỦA NGƯỜI DÙNG (${(gardenSnap?.docs ?? []).length} cây):\n${gardenLines}${gardenInstruction}`
        : "";

      const fullSystemInstruction = [
        basePrompt,
        `Tên xưng hô: ${assistantName}. Giọng điệu: ${tone}.`,
        "QUY TẮC ĐỊNH DẠNG BẮT BUỘC: Không sử dụng ký tự tiêu đề Markdown (#, ##, ###) và không sử dụng emoji/biểu tượng cảm xúc trong câu trả lời.",
        guardrails ? `\nQUY TẮC AN TOÀN (GUARDRAILS BẮT BUỘC):\n${guardrails}` : "",
        gardensSection,
        plantsSection,
        catalogText ? `\nKHO SẢN PHẨM & BẢNG GIÁ FLORIA HIỆN CÓ:\n${catalogText}` : "",
        vouchersText ? `\nMÃ GIẢM GIÁ (VOUCHER) ĐANG HOẠT ĐỘNG:\n${vouchersText}` : "",
        diseasesText ? `\nHỒ SƠ BỆNH LÝ CÂY TRỒNG TRONG HỆ THỐNG:\n${diseasesText}` : "",
        plantsText ? `\nTỪ ĐIỂN CÂY CẢNH TRONG HỆ THỐNG:\n${plantsText}` : "",
        tagInstruction,
      ]
        .filter(Boolean)
        .join("\n");

      const historyContents = existingMsgs.slice(-10).map((m) => {
        const isU = typeof m.isUser === "boolean" ? m.isUser : m.role === "user";
        return {
          role: isU ? "user" : "model",
          parts: [{ text: String(m.text ?? m.content ?? "") }],
        };
      });

      const userParts: Array<Record<string, unknown>> = [];
      if (content) userParts.push({ text: content });
      for (const img of images.slice(0, 3)) {
        const part = await imageToInlinePart(img);
        if (part) userParts.push(part);
      }

      const modelsToTry = defaultModel
        ? [defaultModel, ...DEFAULT_MODELS.filter((m) => m !== defaultModel)]
        : DEFAULT_MODELS;

      let reply = "";
      const attemptErrors: string[] = [];
      for (const model of modelsToTry) {
        try {
          const res = await fetch(
            `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(apiKey)}`,
            {
              method: "POST",
              signal: AbortSignal.timeout(12_000),
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                systemInstruction: { parts: [{ text: fullSystemInstruction }] },
                contents: [...historyContents, { role: "user", parts: userParts }],
                generationConfig: { temperature: 0.7, maxOutputTokens: 3000 },
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
            break;
          }
          attemptErrors.push(`${model}: empty response`);
        } catch (e) {
          attemptErrors.push(`${model}: ${e instanceof Error ? e.message : "timeout"}`);
        }
      }

      if (!reply) {
        return NextResponse.json(
          { error: `Trợ lý Gemini tạm thời không phản hồi (${attemptErrors.join(" | ") || "Timeout"}).` },
          { status: 502 },
        );
      }

      const userMsgStored = {
        id: `m_u_${now}`,
        isUser: true,
        role: "user",
        text: content,
        content,
        images,
        timestamp: now,
        createdAt: nowIso,
        recommendedProductIds: [],
      };

      let sanitizedReply = reply;
      if (!enableProductTags) {
        sanitizedReply = sanitizedReply
          .replace(/\[RECOMMEND_PRODUCT:\s*[^\]]+\]/gi, "")
          .replace(/\[RECOMMEND_PRODUCT\][\s\S]*?\[\/RECOMMEND_PRODUCT\]/gi, "")
          .trim();
      }
      if (!enableCareScheduleTags) {
        sanitizedReply = sanitizedReply
          .replace(/\[CARE_SCHEDULE:\s*[^\]]+\]/gi, "")
          .replace(/\[CARE_SCHEDULE\][\s\S]*?\[\/CARE_SCHEDULE\]/gi, "")
          .trim();
      }

      // Trích xuất productId gợi ý để đồng bộ trường recommendedProductIds với Flutter App
      const recIds: string[] = [];
      if (enableProductTags) {
        for (const match of sanitizedReply.matchAll(/\[RECOMMEND_PRODUCT:\s*([^\]]+)\]/gi)) {
          for (const pid of match[1].split(/[,;\s]+/).map((s) => s.trim()).filter(Boolean)) {
            if (!recIds.includes(pid)) recIds.push(pid);
          }
        }
        for (const match of sanitizedReply.matchAll(/\[RECOMMEND_PRODUCT\]([\s\S]*?)\[\/RECOMMEND_PRODUCT\]/gi)) {
          try {
            const parsed = JSON.parse(match[1].trim()) as { productId?: string };
            const pid = String(parsed.productId ?? "").trim();
            if (pid && !recIds.includes(pid)) recIds.push(pid);
          } catch {
            // ignore
          }
        }
      }

      const aiNow = Date.now();
      const aiIso = new Date(aiNow).toISOString();
      const aiMsgStored = {
        id: `m_a_${aiNow}`,
        isUser: false,
        role: "assistant",
        text: sanitizedReply,
        content: sanitizedReply,
        images: [],
        timestamp: aiNow,
        createdAt: aiIso,
        recommendedProductIds: recIds,
      };

      const nextTitle =
        String(sd.title ?? "") === "Cuộc trò chuyện mới" && content
          ? content.slice(0, 44)
          : String(sd.title ?? "Cuộc trò chuyện mới");

      await sessionRef.set(
        {
          title: nextTitle,
          updatedAt: aiIso,
          messages: [...existingMsgs, userMsgStored, aiMsgStored],
        },
        { merge: true },
      );

      return NextResponse.json([
        mapMessage(sessionId, userMsgStored, existingMsgs.length),
        mapMessage(sessionId, aiMsgStored, existingMsgs.length + 1),
      ]);
    }

    return NextResponse.json({ error: "Hành động không hợp lệ." }, { status: 400 });
  } catch (err) {
    if (err instanceof UserAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: (err as Error).message || "Lỗi Trợ lý AI" }, { status: 500 });
  }
}
