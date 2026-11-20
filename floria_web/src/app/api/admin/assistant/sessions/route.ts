import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";

export interface ChatSessionSummary {
  id: string;
  userId: string;
  title: string;
  messageCount: number;
  lastMessage: string;
  updatedAt: string;
  messages: Array<{ role: string; text: string; timestamp?: string }>;
}

const SESSIONS_CACHE_TTL_MS = 5 * 60_000;
let cachedSessions: { data: ChatSessionSummary[]; expiresAt: number } | null = null;

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const url = new URL(req.url);
    const forceRefresh = url.searchParams.get("refresh") === "1";

    if (!forceRefresh && cachedSessions && cachedSessions.expiresAt > Date.now()) {
      return NextResponse.json(cachedSessions.data);
    }

    const snap = await getAdminDb()
      .collection("ChatSessions")
      .orderBy("updatedAt", "desc")
      .limit(40)
      .get();

    const items: ChatSessionSummary[] = snap.docs.map((doc) => {
      const d = doc.data() ?? {};
      const rawMsgs = Array.isArray(d.messages) ? d.messages : [];
      const messages = rawMsgs.slice(-12).map((m: Record<string, unknown>) => ({
        role: String(m.role ?? m.sender ?? (m.isUser ? "user" : "model")),
        text: String(m.text ?? m.content ?? ""),
        timestamp: m.timestamp ? toIsoString(m.timestamp) : undefined,
      }));
      const lastMsg = messages[messages.length - 1]?.text ?? "";

      return {
        id: doc.id,
        userId: String(d.userId ?? ""),
        title: String(d.title || "Cuộc trò chuyện"),
        messageCount: rawMsgs.length,
        lastMessage: lastMsg,
        updatedAt: toIsoString(d.updatedAt ?? d.createdAt),
        messages,
      };
    });

    cachedSessions = { data: items, expiresAt: Date.now() + SESSIONS_CACHE_TTL_MS };
    return NextResponse.json(items);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const msg = err instanceof Error ? err.message : "Lỗi tải lịch sử ChatSessions";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
