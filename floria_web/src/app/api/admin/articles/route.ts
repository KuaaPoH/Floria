import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import type { Article, ArticleBlock } from "@/types";

function mapBlocksToAdmin(raw: unknown): ArticleBlock[] {
  if (!Array.isArray(raw)) return [];
  return raw.map((item, idx) => {
    const b = typeof item === "object" && item !== null ? (item as Record<string, unknown>) : {};
    const t = String(b.type ?? "text");
    const id = String(b.id ?? `blk_${idx}`);
    if (t === "image") {
      return {
        id,
        type: "image",
        src: String(b.src ?? b.url ?? b.value ?? ""),
        text: String(b.caption ?? b.text ?? ""),
      };
    }
    if (t === "tip" || t === "info") {
      return {
        id,
        type: "info",
        text: String(b.text ?? b.value ?? ""),
      };
    }
    if (t === "heading" || t === "quote" || t === "warning" || t === "bullets" || t === "numbered") {
      return {
        id,
        type: t,
        text: String(b.text ?? b.value ?? ""),
        items: Array.isArray(b.items) ? b.items.map((x) => String(x)) : undefined,
      };
    }
    return {
      id,
      type: "paragraph",
      text: String(b.text ?? b.value ?? ""),
    };
  });
}

export function mapBlocksToFirestore(blocks: ArticleBlock[] | undefined): Array<Record<string, unknown>> {
  if (!Array.isArray(blocks)) return [];
  return blocks.map((b) => {
    if (b.type === "image") {
      return { type: "image", value: b.src ?? "", caption: b.text ?? "" };
    }
    if (b.type === "info") {
      return { type: "tip", value: b.text ?? "" };
    }
    if (b.type === "paragraph") {
      return { type: "text", value: b.text ?? "" };
    }
    return { type: b.type, value: b.text ?? "", items: b.items ?? [] };
  });
}

export function mapArticleDoc(id: string, d: Record<string, unknown>): Article {
  return {
    id,
    title: String(d.title ?? "Bài viết Floria"),
    excerpt: String(d.summary ?? d.excerpt ?? ""),
    category: String(d.category ?? "Kiến thức"),
    cover: String(d.coverImage ?? d.cover ?? ""),
    author: String(d.author ?? "Ban biên tập Floria"),
    status: d.status === "draft" ? "draft" : "published",
    publishedAt: toIsoString(d.publishedAt ?? d.createdAt),
    updatedAt: toIsoString(d.updatedAt ?? d.createdAt),
    views: Number(d.views ?? 0),
    blocks: mapBlocksToAdmin(d.blocks),
  };
}

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const snap = await getAdminDb().collection("PlantHandbook").get();
    const list = snap.docs
      .map((doc) => mapArticleDoc(doc.id, doc.data()))
      .sort((a, b) => Date.parse(b.updatedAt) - Date.parse(a.updatedAt));
    return NextResponse.json(list);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải danh sách bài viết" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    await verifyAdminRequest(req);
    const body = (await req.json()) as Partial<Article>;
    if (!body.title?.trim()) {
      return NextResponse.json({ error: "Thiếu tiêu đề bài viết" }, { status: 400 });
    }
    const docId = body.id?.trim() || `art_${Date.now()}`;
    const now = new Date().toISOString();

    const payload = {
      title: body.title.trim(),
      category: body.category?.trim() || "Mẹo chăm sóc",
      coverImage: body.cover?.trim() || "",
      summary: body.excerpt?.trim() || "",
      readTime: "4 phút đọc",
      author: body.author?.trim() || "Ban biên tập Floria",
      status: body.status ?? "published",
      views: Number(body.views ?? 0),
      blocks: mapBlocksToFirestore(body.blocks),
      createdAt: now,
      updatedAt: now,
    };

    await getAdminDb().collection("PlantHandbook").doc(docId).set(payload, { merge: true });
    return NextResponse.json(mapArticleDoc(docId, payload), { status: 201 });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tạo bài viết" }, { status: 500 });
  }
}
