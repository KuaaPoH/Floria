import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getDiseaseClasses, getSpeciesClasses } from "@/lib/server/ai-labels";

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Lỗi xác thực" }, { status: 500 });
  }

  const aiUrl = (process.env.AI_ENGINE_URL ?? "http://127.0.0.1:8000").replace(/\/+$/, "");
  const speciesCount = getSpeciesClasses().length;
  const diseaseCount = getDiseaseClasses().length;

  const t0 = Date.now();
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 3000);
    const res = await fetch(`${aiUrl}/`, { signal: controller.signal, cache: "no-store" });
    clearTimeout(timer);
    const latencyMs = Date.now() - t0;

    if (!res.ok) {
      return NextResponse.json({
        online: false,
        latencyMs,
        loadedModels: [],
        clipLoaded: false,
        speciesClassesCount: speciesCount,
        diseaseClassesCount: diseaseCount,
        detail: `HTTP ${res.status}`,
      });
    }

    const data = (await res.json()) as {
      status?: string;
      loaded_models?: string[];
      clip_loaded?: boolean;
      species_classes_count?: number;
      disease_classes_count?: number;
      config?: Record<string, unknown>;
    };

    return NextResponse.json({
      online: true,
      latencyMs,
      loadedModels: data.loaded_models ?? [],
      clipLoaded: Boolean(data.clip_loaded),
      speciesClassesCount: data.species_classes_count ?? speciesCount,
      diseaseClassesCount: data.disease_classes_count ?? diseaseCount,
      runtimeConfig: data.config ?? null,
    });
  } catch (err) {
    return NextResponse.json({
      online: false,
      latencyMs: Date.now() - t0,
      loadedModels: [],
      clipLoaded: false,
      speciesClassesCount: speciesCount,
      diseaseClassesCount: diseaseCount,
      detail: err instanceof Error ? err.message : "Không thể kết nối AI Engine",
    });
  }
}
