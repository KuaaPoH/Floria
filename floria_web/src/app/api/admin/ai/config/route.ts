import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";

export interface RealAiConfig {
  preferGemini: boolean;
  speciesConfidenceThreshold: number;
  diseaseConfidenceThreshold: number;
  gatekeeperSpeciesThreshold: number;
  gatekeeperDiseaseThreshold: number;
  // Các trường thông số cố định của mô hình ONNX (Read-only trên UI)
  inputSize: number;
  normalize: boolean;
  executionProvider: string;
  speciesModel: string;
  diseaseModel: string;
  updatedAt?: string;
  updatedBy?: string;
}

const DEFAULT_CONFIG: RealAiConfig = {
  preferGemini: true,
  speciesConfidenceThreshold: 70,
  diseaseConfidenceThreshold: 50,
  gatekeeperSpeciesThreshold: 0.7,
  gatekeeperDiseaseThreshold: 0.5,
  inputSize: 224,
  normalize: true,
  executionProvider: "CPUExecutionProvider",
  speciesModel: "tf_efficientnetv2_b0.onnx",
  diseaseModel: "tf_efficientnetv2_b0_disease.onnx",
};

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const snap = await getAdminDb().collection("SystemConfig").doc("ai_config").get();
    if (!snap.exists) {
      return NextResponse.json(DEFAULT_CONFIG);
    }
    const raw = snap.data() ?? {};
    return NextResponse.json({
      ...DEFAULT_CONFIG,
      preferGemini: typeof raw.preferGemini === "boolean" ? raw.preferGemini : DEFAULT_CONFIG.preferGemini,
      speciesConfidenceThreshold:
        typeof raw.speciesConfidenceThreshold === "number"
          ? raw.speciesConfidenceThreshold
          : DEFAULT_CONFIG.speciesConfidenceThreshold,
      diseaseConfidenceThreshold:
        typeof raw.diseaseConfidenceThreshold === "number"
          ? raw.diseaseConfidenceThreshold
          : DEFAULT_CONFIG.diseaseConfidenceThreshold,
      gatekeeperSpeciesThreshold:
        typeof raw.gatekeeperSpeciesThreshold === "number"
          ? raw.gatekeeperSpeciesThreshold
          : DEFAULT_CONFIG.gatekeeperSpeciesThreshold,
      gatekeeperDiseaseThreshold:
        typeof raw.gatekeeperDiseaseThreshold === "number"
          ? raw.gatekeeperDiseaseThreshold
          : DEFAULT_CONFIG.gatekeeperDiseaseThreshold,
      updatedAt: typeof raw.updatedAt === "string" ? raw.updatedAt : undefined,
      updatedBy: typeof raw.updatedBy === "string" ? raw.updatedBy : undefined,
    });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const msg = err instanceof Error ? err.message : "Lỗi đọc cấu hình AI";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}

export async function PUT(req: Request) {
  try {
    const admin = await verifyAdminRequest(req);
    const body = (await req.json()) as Partial<RealAiConfig>;

    const nextCfg = {
      preferGemini: Boolean(body.preferGemini ?? DEFAULT_CONFIG.preferGemini),
      speciesConfidenceThreshold: Math.min(99, Math.max(10, Number(body.speciesConfidenceThreshold ?? 70))),
      diseaseConfidenceThreshold: Math.min(99, Math.max(10, Number(body.diseaseConfidenceThreshold ?? 50))),
      gatekeeperSpeciesThreshold: Math.min(0.99, Math.max(0.1, Number(body.gatekeeperSpeciesThreshold ?? 0.7))),
      gatekeeperDiseaseThreshold: Math.min(0.99, Math.max(0.1, Number(body.gatekeeperDiseaseThreshold ?? 0.5))),
      inputSize: DEFAULT_CONFIG.inputSize,
      normalize: DEFAULT_CONFIG.normalize,
      executionProvider: DEFAULT_CONFIG.executionProvider,
      speciesModel: DEFAULT_CONFIG.speciesModel,
      diseaseModel: DEFAULT_CONFIG.diseaseModel,
      updatedAt: new Date().toISOString(),
      updatedBy: admin.name,
    };

    await getAdminDb().collection("SystemConfig").doc("ai_config").set(nextCfg, { merge: true });

    // Đồng bộ nóng sang AI Engine nếu đang chạy (không làm fail request nếu AI Engine offline)
    const aiUrl = (process.env.AI_ENGINE_URL ?? "http://127.0.0.1:8000").replace(/\/+$/, "");
    let engineReloaded = false;
    try {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), 2000);
      const reloadRes = await fetch(`${aiUrl}/config/reload`, {
        method: "POST",
        signal: controller.signal,
      });
      clearTimeout(timer);
      engineReloaded = reloadRes.ok;
    } catch {
      // Bỏ qua nếu AI Engine tạm offline; engine sẽ đọc lại khi bật hoặc hết TTL
    }

    return NextResponse.json({ ...nextCfg, engineReloaded });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    const msg = err instanceof Error ? err.message : "Lỗi lưu cấu hình AI";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
