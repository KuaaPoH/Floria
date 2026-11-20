import fs from "node:fs";
import path from "node:path";
import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";

const PLANT_NAME_CACHE_TTL_MS = 5 * 60_000;
let plantNameMapCache: { map: Map<string, string>; expiresAt: number } | null = null;

async function getPlantViNameMap(): Promise<Map<string, string>> {
  if (plantNameMapCache && plantNameMapCache.expiresAt > Date.now()) {
    return plantNameMapCache.map;
  }
  const map = new Map<string, string>();
  try {
    const snap = await getAdminDb().collection("plants_info").select("name_vi", "scientific_name").get();
    for (const doc of snap.docs) {
      const d = doc.data() ?? {};
      const nameVi = String(d.name_vi ?? "").trim();
      if (!nameVi) continue;
      map.set(doc.id.toLowerCase(), nameVi);
      if (typeof d.scientific_name === "string" && d.scientific_name.trim()) {
        map.set(d.scientific_name.trim().toLowerCase(), nameVi);
      }
    }
  } catch {
    // Fallback nếu Firestore lỗi
  }
  plantNameMapCache = { map, expiresAt: Date.now() + PLANT_NAME_CACHE_TTL_MS };
  return map;
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
    const formData = await req.formData();
    const mode = String(formData.get("mode") ?? "species") === "disease" ? "disease" : "species";
    const file = formData.get("file");
    const imageUrl = String(formData.get("imageUrl") ?? "").trim();

    const outbound = new FormData();

    if (file instanceof Blob && file.size > 0) {
      outbound.append("file", file, (file as File).name || "sandbox.jpg");
    } else if (imageUrl) {
      if (imageUrl.startsWith("data:")) {
        const res = await fetch(imageUrl);
        const blob = await res.blob();
        outbound.append("file", blob, "sample.jpg");
      } else if (imageUrl.startsWith("/")) {
        const publicPath = path.resolve(/*turbopackIgnore: true*/ process.cwd(), "public", imageUrl.slice(1));
        if (!fs.existsSync(publicPath)) {
          return NextResponse.json({ error: "Không tìm thấy ảnh mẫu cục bộ." }, { status: 400 });
        }
        const buf = fs.readFileSync(publicPath);
        outbound.append("file", new Blob([buf], { type: "image/jpeg" }), "sample.jpg");
      } else {
        const imgRes = await fetch(imageUrl);
        if (!imgRes.ok) {
          return NextResponse.json({ error: "Không tải được ảnh mẫu từ URL." }, { status: 400 });
        }
        const blob = await imgRes.blob();
        outbound.append("file", blob, "sample.jpg");
      }
    } else {
      return NextResponse.json({ error: "Vui lòng chọn hoặc tải ảnh lên." }, { status: 400 });
    }

    const aiUrl = (process.env.AI_ENGINE_URL ?? "http://127.0.0.1:8000").replace(/\/+$/, "");
    const targetEndpoint = mode === "disease" ? `${aiUrl}/predict-disease` : `${aiUrl}/predict`;

    const t0 = Date.now();
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 15_000);
    const aiRes = await fetch(targetEndpoint, {
      method: "POST",
      body: outbound,
      signal: controller.signal,
    });
    clearTimeout(timer);
    const totalMs = Date.now() - t0;

    if (!aiRes.ok) {
      const errText = await aiRes.text();
      return NextResponse.json(
        { error: `AI Engine trả về lỗi ${aiRes.status}: ${errText}` },
        { status: 502 },
      );
    }

    const result = (await aiRes.json()) as Record<string, unknown>;

    if (mode === "species" && result.is_valid_plant) {
      const nameMap = await getPlantViNameMap();
      const pred = String(result.prediction ?? "").trim();
      const predVi = nameMap.get(pred.toLowerCase()) ?? nameMap.get(pred.replace(/_/g, " ").toLowerCase());
      if (predVi) {
        result.prediction_vi = predVi;
      }
      if (Array.isArray(result.top_3)) {
        result.top_3 = result.top_3.map((item: Record<string, unknown>) => {
          const cls = String(item.class ?? "").trim();
          const vi = nameMap.get(cls.toLowerCase()) ?? nameMap.get(cls.replace(/_/g, " ").toLowerCase());
          return vi ? { ...item, name_vi: vi } : item;
        });
      }
    }

    return NextResponse.json({
      ...result,
      mode,
      roundTripMs: totalMs,
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Không thể kết nối AI Engine";
    return NextResponse.json({ error: msg }, { status: 502 });
  }
}
