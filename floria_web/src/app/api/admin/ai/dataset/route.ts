import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";

function sanitizeSegment(raw: string): string {
  return raw
    .trim()
    .replace(/[<>:"/\\|?*]+/g, "_")
    .replace(/\s+/g, "_")
    .replace(/_+/g, "_")
    .replace(/^_+|_+$/g, "");
}

export interface DatasetImageItem {
  id: string;
  folderName: string;
  fileName: string;
  imageUrl: string;
  createdAt: string;
}

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const snap = await getAdminDb().collection("TrainingDataset").get();

    const folderMap = new Map<string, DatasetImageItem[]>();
    for (const doc of snap.docs) {
      const d = doc.data() ?? {};
      const folderName = String(d.folderName || "unknown").trim();
      const imageUrl = String(d.imageUrl || "").trim();
      if (!imageUrl) continue;

      const list = folderMap.get(folderName) ?? [];
      list.push({
        id: doc.id,
        folderName,
        fileName: String(d.fileName || `${doc.id}.jpg`),
        imageUrl,
        createdAt: String(d.createdAt || ""),
      });
      folderMap.set(folderName, list);
    }

    const folders = Array.from(folderMap.entries())
      .map(([name, items]) => ({
        name,
        count: items.length,
        items: items.sort((a, b) => b.createdAt.localeCompare(a.createdAt)),
      }))
      .sort((a, b) => b.count - a.count || a.name.localeCompare(b.name));

    return NextResponse.json({
      totalImages: snap.size,
      folders,
    });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const msg = err instanceof Error ? err.message : "Lỗi tải kho ảnh Dataset";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    await verifyAdminRequest(req);
    const body = (await req.json()) as {
      imageUrl?: string;
      folderName?: string;
      fileName?: string;
      requestId?: string;
    };

    const imageUrl = String(body.imageUrl ?? "").trim();
    const folderName = sanitizeSegment(String(body.folderName ?? ""));
    if (!imageUrl || !folderName) {
      return NextResponse.json({ error: "Thiếu imageUrl hoặc tên thư mục." }, { status: 400 });
    }

    const baseFile = sanitizeSegment(String(body.fileName ?? "")) || `img_${Date.now()}`;
    const fileName = /\.(png|webp|jpeg|jpg)$/i.test(baseFile) ? baseFile : `${baseFile}.jpg`;
    const createdAt = new Date().toISOString();

    const docRef = await getAdminDb().collection("TrainingDataset").add({
      folderName,
      fileName,
      imageUrl,
      requestId: String(body.requestId ?? ""),
      createdAt,
    });

    return NextResponse.json(
      { id: docRef.id, folderName, fileName, imageUrl, createdAt },
      { status: 201 },
    );
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const msg = err instanceof Error ? err.message : "Lỗi lưu ảnh vào kho Dataset";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}

export async function PATCH(req: Request) {
  try {
    await verifyAdminRequest(req);
    const body = (await req.json()) as { oldName?: string; newName?: string };
    const oldName = sanitizeSegment(String(body.oldName ?? ""));
    const newName = sanitizeSegment(String(body.newName ?? ""));

    if (!oldName || !newName || oldName === newName) {
      return NextResponse.json({ error: "Tên thư mục không hợp lệ." }, { status: 400 });
    }

    const db = getAdminDb();
    const snap = await db.collection("TrainingDataset").where("folderName", "==", oldName).get();
    if (snap.empty) {
      return NextResponse.json({ error: "Không tìm thấy thư mục gốc." }, { status: 404 });
    }

    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.update(doc.ref, { folderName: newName });
    }
    await batch.commit();

    return NextResponse.json({ renamed: true, oldName, newName, count: snap.size });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const msg = err instanceof Error ? err.message : "Lỗi đổi tên thư mục";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}

export async function DELETE(req: Request) {
  try {
    await verifyAdminRequest(req);
    const url = new URL(req.url);
    const id = String(url.searchParams.get("id") ?? "").trim();
    if (!id) {
      return NextResponse.json({ error: "Thiếu id ảnh cần xoá." }, { status: 400 });
    }
    await getAdminDb().collection("TrainingDataset").doc(id).delete();
    return NextResponse.json({ deleted: true, id });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const msg = err instanceof Error ? err.message : "Lỗi xoá ảnh khỏi Dataset";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
