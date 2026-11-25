import { NextResponse } from "next/server";
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

      // Đọc SystemConfig/assistant_config + ShopProducts + MyGarden + UserGardens của user
      const [cfgSnap, prodSnap, gardenSnap, userGardensSnap] = await Promise.all([
        db.collection("SystemConfig").doc("assistant_config").get().catch(() => null),
        db.collection("ShopProducts").get().catch(() => null),
        db.collection("MyGarden").where("userId", "==", user.uid).get().catch(() => null),
        db.collection("UserGardens").where("userId", "==", user.uid).get().catch(() => null),
      ]);

      const cfg = (cfgSnap?.exists ? cfgSnap.data() : {}) as Record<string, unknown>;
      const assistantName = String(cfg.name ?? "Trợ lý Floria");
      const tone = String(cfg.tone ?? "Thân thiện, chuyên môn thực vật rõ ràng");
      const defaultModel = String(cfg.defaultModel ?? "").trim();
      let basePrompt =
        typeof cfg.systemPrompt === "string" && cfg.systemPrompt.trim()
          ? cfg.systemPrompt.trim()
          : "Bạn là Trợ lý Floria — bác sĩ cây trồng AI. Chỉ tư vấn về thực vật, trồng cây, chăm sóc cây, sâu bệnh, môi trường trồng và làm vườn. Từ chối lịch sự các chủ đề ngoài phạm vi. Trả lời bằng tiếng Việt rõ ràng, thân thiện.";

      const guardrails = Array.isArray(cfg.guardrails)
        ? (cfg.guardrails as Array<{ name?: string; ruleText?: string; enabled?: boolean }>)
          .filter((g) => g.enabled !== false && g.ruleText)
          .map((g, i) => `${i + 1}. [${g.name ?? "Quy tắc"}]: ${g.ruleText}`)
          .join("\n")
        : "";

      const disabledIds = new Set(Array.isArray(cfg.disabledProductIds) ? cfg.disabledProductIds.map(String) : []);
      const catalogLines = (prodSnap?.docs ?? [])
        .filter((doc) => {
          const pd = doc.data();
          if (pd.visible === false || disabledIds.has(doc.id)) return false;
          if (typeof pd.stock === "number" && pd.stock <= 0) return false;
          return Boolean(String(pd.name ?? "").trim());
        })
        .slice(0, 24)
        .map((doc) => {
          const pd = doc.data();
          const ind = Array.isArray(pd.indications) ? pd.indications.join(", ") : "";
          const desc = String(pd.shortDesc ?? pd.description ?? "").slice(0, 120);
          return `- id: "${doc.id}" -> ${String(pd.name)} (${[ind, desc].filter(Boolean).join(" · ")})`;
        })
        .join("\n");

      // Xây dựng bản đồ khu vườn: gardenId -> gardenName
      const gardenMap = new Map<string, string>();
      const userGardenList: string[] = [];

      (userGardensSnap?.docs ?? []).forEach((doc) => {
        const gd = doc.data();
        const gName = String(gd.name ?? "Khu vườn").trim();
        gardenMap.set(doc.id, gName);
        const env = String(gd.environment ?? "").trim();
        const desc = String(gd.description ?? "").trim();
        userGardenList.push(`- Khu vườn "${gName}" (Mã vườn: ${doc.id}${env ? `, Môi trường: ${env}` : ""}${desc ? `, Ghi chú: ${desc}` : ""})`);
      });

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
          return `- "${plantName}" (${sciName}) -> Thuộc khu vườn: "${resolvedGardenName}", Vị trí cụ thể trong vườn: ${zone}, Trạng thái: ${health}`;
        })
        .join("\n");

      const tagInstruction = `
ĐỊNH DẠNG THẺ HÀNH ĐỘNG (chỉ dùng khi thực sự hữu ích):
1. Nếu đề xuất sản phẩm trong kho Floria, thêm cuối câu trả lời:
[RECOMMEND_PRODUCT]{"productId":"<id chính xác từ kho>","reason":"<lý do ngắn>"}[/RECOMMEND_PRODUCT]
2. Nếu đề xuất chu kỳ chăm sóc mới (watering | fertilizing | inspection), thêm cuối câu trả lời:
[CARE_SCHEDULE]{"plantName":"<tên cây>","careType":"watering","intervalDays":7,"preferredTime":"07:00","reason":"<lý do ngắn>"}[/CARE_SCHEDULE]`;

      const gardensSection = userGardenList.length > 0
        ? `\nDANH SÁCH CÁC KHU VƯỜN CỦA NGƯỜI DÙNG (${userGardenList.length} khu vườn):\n${userGardenList.join("\n")}`
        : "";

      const gardenInstruction = gardenMap.size > 0
        ? `\n(LƯU Ý ĐẶC BIỆT: Khi người dùng hỏi cây nằm ở khu vườn nào, hãy đối chiếu chính xác tên khu vườn thực tế của họ (${Array.from(gardenMap.values()).map((n) => `"${n}"`).join(", ")}) và vị trí cụ thể như ban công/phòng khách để trả lời chi tiết, chính xác từng cây thuộc khu vườn nào).`
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
        catalogLines ? `\nKHO SẢN PHẨM FLORIA HIỆN CÓ:\n${catalogLines}` : "",
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

      // Trích xuất productId gợi ý để đồng bộ trường recommendedProductIds với Flutter App
      const recIds: string[] = [];
      for (const match of reply.matchAll(/\[RECOMMEND_PRODUCT\]([\s\S]*?)\[\/RECOMMEND_PRODUCT\]/g)) {
        try {
          const parsed = JSON.parse(match[1].trim()) as { productId?: string };
          if (parsed.productId) recIds.push(parsed.productId);
        } catch {
          // ignore
        }
      }

      const aiNow = Date.now();
      const aiIso = new Date(aiNow).toISOString();
      const aiMsgStored = {
        id: `m_a_${aiNow}`,
        isUser: false,
        role: "assistant",
        text: reply,
        content: reply,
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
