import { NextResponse } from "next/server";
import { getSpeciesClasses, getDiseaseClasses } from "@/lib/server/ai-labels";
import { getAdminDb, isFirebaseAdminConfigured } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";
import { tryVerifyUserRequest, UserAuthError, verifyUserRequest } from "@/lib/server/user-auth";
import { findPlantInfoOrFallback, slugifySpecies } from "@/mocks/user/plants-info";
import type { ScanHistoryItem, SpeciesPrediction } from "@/types/user";

const GEMINI_MODELS = [
  "gemini-3.8-flash",
  "gemini-3-flash-preview",
  "gemini-3.5-flash-lite",
  "gemini-3.1-flash-lite",
  "gemini-3.1-flash-lite-preview",
  "gemini-3.6-flash",
];

function normalizeConfidence(raw: unknown, fallback = 0.85): number {
  const n = Number(raw);
  if (!Number.isFinite(n) || n < 0) return fallback;
  const unit = n > 1 ? n / 100 : n;
  return Math.min(0.99, Math.max(0, Number(unit.toFixed(4))));
}

async function loadAiConfig(): Promise<{ preferGemini: boolean; speciesThreshold: number; diseaseThreshold: number }> {
  try {
    const snap = await getAdminDb().collection("SystemConfig").doc("ai_config").get();
    if (snap.exists) {
      const d = snap.data() ?? {};
      return {
        preferGemini: typeof d.preferGemini === "boolean" ? d.preferGemini : true,
        speciesThreshold: Number(d.gatekeeperSpeciesThreshold ?? 0.7),
        diseaseThreshold: Number(d.gatekeeperDiseaseThreshold ?? 0.5),
      };
    }
  } catch {
    // default
  }
  return { preferGemini: true, speciesThreshold: 0.7, diseaseThreshold: 0.5 };
}

async function imageToInlineData(imageInput: string): Promise<{ mimeType: string; data: string; blob: Blob }> {
  const res = await fetch(imageInput);
  if (!res.ok) throw new Error("Không thể đọc dữ liệu ảnh.");
  const blob = await res.blob();
  const ab = await blob.arrayBuffer();
  const base64 = Buffer.from(ab).toString("base64");
  return { mimeType: blob.type || "image/jpeg", data: base64, blob };
}

async function tryUploadToCloudinary(imageInput: string): Promise<string> {
  if (!imageInput.startsWith("data:")) return imageInput;
  try {
    const form = new FormData();
    form.append("file", imageInput);
    form.append("upload_preset", process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET ?? "ml_default");
    form.append("folder", "floria_scans");
    const res = await fetch("https://api.cloudinary.com/v1_1/vbiltn75/image/upload", {
      method: "POST",
      body: form,
    });
    if (res.ok) {
      const json = (await res.json()) as { secure_url?: string };
      if (json.secure_url) return json.secure_url;
    }
  } catch {
    // Fallback to compact data URL if Cloudinary preset/network unavailable
  }
  return imageInput;
}

async function callGeminiJson(prompt: string, image?: { mimeType: string; data: string }): Promise<Record<string, unknown> | null> {
  const apiKey = (process.env.GEMINI_API_KEY ?? "").trim();
  if (!apiKey) return null;

  const parts: Array<Record<string, unknown>> = [{ text: prompt }];
  if (image) {
    parts.push({ inlineData: { mimeType: image.mimeType, data: image.data } });
  }

  for (const model of GEMINI_MODELS) {
    try {
      const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(apiKey)}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            contents: [{ role: "user", parts }],
            generationConfig: {
              temperature: 0.2,
              maxOutputTokens: 1024,
              responseMimeType: "application/json",
            },
          }),
        },
      );
      if (!res.ok) continue;
      const json = (await res.json()) as {
        candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
      };
      const text = json.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
      if (!text) continue;
      const cleaned = text.replace(/^```json\s*/i, "").replace(/```$/i, "").trim();
      return JSON.parse(cleaned) as Record<string, unknown>;
    } catch {
      // try next model
    }
  }
  return null;
}

async function callAiEngine(endpoint: "/predict" | "/predict-disease", blob: Blob): Promise<Record<string, unknown> | null> {
  const aiUrl = (process.env.AI_ENGINE_URL ?? "http://127.0.0.1:8000").replace(/\/+$/, "");
  try {
    const form = new FormData();
    form.append("file", blob, "scan.jpg");
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 12_000);
    const res = await fetch(`${aiUrl}${endpoint}`, {
      method: "POST",
      body: form,
      signal: controller.signal,
    });
    clearTimeout(timer);
    if (!res.ok) return null;
    return (await res.json()) as Record<string, unknown>;
  } catch {
    return null;
  }
}

function mapScanDoc(id: string, d: Record<string, unknown>): ScanHistoryItem {
  const rawType = String(d.type ?? "");
  const isDiagnose =
    rawType === "diagnose" ||
    rawType === "disease_diagnosis" ||
    (!rawType && (d.severity !== undefined || d.treatmentSteps !== undefined || d.plantName !== undefined));

  const isValidPlant = d.isValidPlant !== false && d.is_valid_plant !== false;

  let predictions: SpeciesPrediction[] | undefined;
  if (Array.isArray(d.predictions)) {
    predictions = d.predictions.map((p) => {
      const r = p as Record<string, unknown>;
      return {
        speciesId: slugifySpecies(String(r.speciesId ?? r.class ?? "")),
        confidence: normalizeConfidence(r.confidence, 0),
        ...(typeof r.nameVi === "string" && r.nameVi ? { nameVi: r.nameVi } : {}),
        ...(typeof r.scientificName === "string" && r.scientificName ? { scientificName: r.scientificName } : {}),
        ...(typeof r.matchedDatabase === "boolean" ? { matchedDatabase: r.matchedDatabase } : {}),
      };
    });
  } else if (Array.isArray(d.top3)) {
    predictions = d.top3.map((p) => {
      const r = p as Record<string, unknown>;
      return {
        speciesId: slugifySpecies(String(r.class ?? r.speciesId ?? "")),
        confidence: normalizeConfidence(r.confidence, 0),
        ...(typeof r.name_vi === "string" && r.name_vi ? { nameVi: r.name_vi } : {}),
        ...(typeof r.class === "string" && r.class ? { scientificName: r.class } : {}),
      };
    });
  } else if (!isDiagnose && d.prediction) {
    predictions = [
      {
        speciesId: slugifySpecies(String(d.prediction)),
        confidence: normalizeConfidence(d.confidence, 0.85),
        ...(typeof d.predictionVi === "string" && d.predictionVi ? { nameVi: d.predictionVi } : {}),
        ...(typeof d.prediction === "string" ? { scientificName: d.prediction } : {}),
        ...(typeof d.matchedDatabase === "boolean" ? { matchedDatabase: d.matchedDatabase } : {}),
      },
    ];
  }

  return {
    id,
    userId: typeof d.userId === "string" ? d.userId : null,
    type: isDiagnose ? "diagnose" : "identify",
    image: String(d.imageUrl ?? d.image ?? ""),
    createdAt: toIsoString(d.timestamp ?? d.createdAt),
    isValidPlant,
    predictions,
    plantId: typeof d.plantId === "string" ? d.plantId : undefined,
    diseaseId: typeof d.diseaseId === "string"
      ? d.diseaseId
      : isDiagnose && typeof d.prediction === "string"
        ? d.prediction
        : undefined,
    confidence: typeof d.confidence === "number" ? normalizeConfidence(d.confidence, 0.85) : undefined,
    appliedToRecord: Boolean(d.appliedToRecord),
  };
}

export async function GET(req: Request) {
  if (!isFirebaseAdminConfigured()) {
    return NextResponse.json({ error: "Firebase Admin chưa được cấu hình" }, { status: 503 });
  }
  try {
    const db = getAdminDb();
    const url = new URL(req.url);
    const id = url.searchParams.get("id");

    if (id) {
      const doc = await db.collection("ScanHistory").doc(id).get();
      if (!doc.exists) {
        return NextResponse.json({ error: "Không tìm thấy kết quả quét" }, { status: 404 });
      }
      return NextResponse.json(mapScanDoc(doc.id, doc.data() ?? {}));
    }

    const user = await verifyUserRequest(req);
    const snap = await db.collection("ScanHistory").where("userId", "==", user.uid).get();
    const list = snap.docs
      .map((doc) => mapScanDoc(doc.id, doc.data()))
      .sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt));

    return NextResponse.json(list);
  } catch (err) {
    if (err instanceof UserAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: (err as Error).message || "Không thể tải lịch sử quét" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  if (!isFirebaseAdminConfigured()) {
    return NextResponse.json({ error: "Firebase Admin chưa được cấu hình" }, { status: 503 });
  }

  try {
    const db = getAdminDb();
    const user = await tryVerifyUserRequest(req);
    const body = (await req.json()) as Record<string, unknown>;
    const mode = String(body.mode ?? "");
    const nowIso = new Date().toISOString();

    if (mode === "apply") {
      if (!user) return NextResponse.json({ error: "Vui lòng đăng nhập." }, { status: 401 });
      const scanId = String(body.scanId ?? "");
      const scanRef = db.collection("ScanHistory").doc(scanId);
      const scanSnap = await scanRef.get();
      if (!scanSnap.exists || scanSnap.data()?.userId !== user.uid) {
        return NextResponse.json({ error: "Không tìm thấy kết quả chẩn đoán." }, { status: 404 });
      }
      const sd = scanSnap.data() ?? {};
      if (sd.appliedToRecord) {
        return NextResponse.json({ error: "Kết quả này đã được cập nhật vào bệnh án." }, { status: 400 });
      }
      const plantId = String(sd.plantId ?? "");
      const diseaseId = String(sd.diseaseId ?? sd.prediction ?? "");
      const plantRef = db.collection("MyGarden").doc(plantId);
      const plantSnap = await plantRef.get();
      if (!plantSnap.exists || plantSnap.data()?.userId !== user.uid) {
        return NextResponse.json({ error: "Không tìm thấy cây trong khu vườn." }, { status: 404 });
      }

      const dSnap = await db.collection("DiseasesInfo").get();
      let diseaseName = String(sd.predictionVi ?? diseaseId);
      let isHealthy = diseaseId.toLowerCase() === "healthy";
      let symptoms = String(sd.cause ?? "");
      for (const ddoc of dSnap.docs) {
        if (ddoc.id.toLowerCase() === diseaseId.toLowerCase() || ddoc.id.toLowerCase().replace(/[_\s]+/g, "-") === diseaseId.toLowerCase().replace(/[_\s]+/g, "-")) {
          const dd = ddoc.data();
          diseaseName = String(dd.nameVi ?? diseaseName);
          isHealthy = ddoc.id.toLowerCase() === "healthy" || diseaseName.toLowerCase().includes("khỏe");
          symptoms = Array.isArray(dd.symptoms) ? dd.symptoms.join(". ") : String(dd.mechanism ?? "");
          break;
        }
      }

      const curHealth = String(plantSnap.data()?.healthStatus ?? "");
      const nextHealth = isHealthy
        ? curHealth.startsWith("Bị")
          ? "Đang phục hồi"
          : "Khỏe mạnh"
        : `Bị ${diseaseName}`;

      await plantRef.set(
        {
          healthStatus: nextHealth,
          activeDiseaseId: isHealthy ? null : diseaseId,
          updatedAt: nowIso,
        },
        { merge: true },
      );

      const img = String(sd.imageUrl ?? sd.image ?? "");
      await plantRef.collection("DiaryNotes").add({
        plantId,
        userId: user.uid,
        type: "system",
        category: "health",
        title: `Chẩn đoán: ${diseaseName}`,
        content: `Chẩn đoán: ${diseaseName} (${Math.round(Number(sd.confidence ?? 0) * 100)}%). ${isHealthy ? "Lá khỏe mạnh." : symptoms}`,
        imageUrl: img || null,
        imageUrls: img ? [img] : [],
        diagnosisId: scanId,
        timestamp: nowIso,
        createdAt: nowIso,
        updatedAt: nowIso,
      });

      await scanRef.set({ appliedToRecord: true }, { merge: true });
      return NextResponse.json({ applied: true });
    }

    if (mode === "report") {
      const suggestedName = String(body.suggestedName ?? "").trim();
      const note = String(body.note ?? "").trim();
      if (!suggestedName && !note) {
        return NextResponse.json({ error: "Vui lòng nhập tên gợi ý hoặc mô tả lỗi." }, { status: 400 });
      }
      const imageStr = String(body.imageUrl ?? body.image ?? "");
      const savedImageUrl = imageStr ? await tryUploadToCloudinary(imageStr) : "";
      const ref = await db.collection("PlantRequests").add({
        userId: user?.uid ?? "guest",
        userEmail: user?.email ?? "",
        userName: user?.name ?? "Khách Web",
        reportType: String(body.reportType ?? "wrong_prediction"),
        suggestedName,
        note,
        predictedLabel: String(body.predictedLabel ?? ""),
        predictedNameVi: String(body.predictedNameVi ?? ""),
        confidence: typeof body.confidence === "number" ? body.confidence : null,
        isValidPlant: body.isValidPlant !== false,
        isDiseaseScan: Boolean(body.isDiseaseScan),
        imageUrl: savedImageUrl,
        status: "pending",
        createdAt: nowIso,
        createdAtIso: nowIso,
      });
      return NextResponse.json({ id: ref.id, submitted: true }, { status: 201 });
    }

    const aiCfg = await loadAiConfig();

    if (mode === "hint") {
      const imageStr = typeof body.image === "string" && body.image ? body.image : null;
      const description = String(body.description ?? "").trim();
      const speciesList = getSpeciesClasses().map((c) => c.name);
      const inline = imageStr ? await imageToInlineData(imageStr) : undefined;

      let preds: SpeciesPrediction[] = [];
      let note = "";

      const runMlEngine = async () => {
        if (!inline) return;
        const engineRes = await callAiEngine("/predict", inline.blob);
        if (!engineRes || engineRes.is_valid_plant === false) return;
        if (Array.isArray(engineRes.top_3) && engineRes.top_3.length > 0) {
          preds = engineRes.top_3.slice(0, 3).map((x) => {
            const r = x as Record<string, unknown>;
            return {
              speciesId: slugifySpecies(String(r.class ?? "")),
              confidence: Number(r.confidence ?? 0.7),
            };
          });
          note = "Nhận diện bởi mô hình học máy Floria.";
        } else if (typeof engineRes.prediction === "string" && engineRes.prediction) {
          preds = [{ speciesId: slugifySpecies(engineRes.prediction), confidence: Number(engineRes.confidence ?? 0.8) }];
          note = "Nhận diện bởi mô hình học máy Floria.";
        }
      };

      const runGemini = async () => {
        const prompt = `Bạn là chuyên gia thực vật học Floria. Hãy xác định loài cây cảnh phù hợp nhất trong danh sách 40 loài chuẩn sau đây (trả về đúng tên khoa học trong danh sách nếu khớp):
${speciesList.join(", ")}

Miêu tả đặc điểm từ người dùng: "${description || "Không có"}"

Trả về JSON thuần theo cấu trúc:
{
  "is_valid_plant": true/false,
  "predictions": [
    { "scientificName": "Tên khoa học trong danh sách", "confidence": 0.92 }
  ],
  "note": "Giải thích ngắn gọn bằng tiếng Việt lý do nhận diện"
}
Tối đa 3 predictions sắp xếp theo confidence giảm dần.`;

        const gemRes = await callGeminiJson(prompt, inline);
        if (gemRes && Array.isArray(gemRes.predictions) && gemRes.predictions.length > 0 && gemRes.is_valid_plant !== false) {
          preds = gemRes.predictions.slice(0, 3).map((p) => {
            const r = p as Record<string, unknown>;
            return {
              speciesId: slugifySpecies(String(r.scientificName ?? "")),
              confidence: Math.min(0.99, Math.max(0.1, Number(r.confidence ?? 0.75))),
            };
          });
          note = String(gemRes.note ?? "Nhận diện bởi Trợ lý AI Floria.");
        }
      };

      // Kết hợp LLM + Mô hình học máy theo cấu hình SystemConfig/ai_config giống App
      if (!aiCfg.preferGemini && inline) {
        await runMlEngine();
        if (preds.length === 0) await runGemini();
      } else {
        await runGemini();
        if (preds.length === 0 && inline) await runMlEngine();
      }

      if (preds.length > 0) {
        return NextResponse.json({
          speciesId: preds[0]?.speciesId ?? null,
          confidence: preds[0]?.confidence ?? 0,
          alternatives: preds.slice(1),
          note,
        });
      }

      // Fallback sang tìm khớp theo miêu tả đặc điểm trong plants_info
      if (description) {
        const found = findPlantInfoOrFallback(description);
        return NextResponse.json({
          speciesId: found.id,
          confidence: 0.72,
          alternatives: [],
          note: "Khớp theo miêu tả đặc điểm.",
        });
      }

      return NextResponse.json({
        speciesId: null,
        confidence: 0,
        alternatives: [],
        note: "Ảnh không giống thực vật hoặc chưa đủ thông tin nhận diện.",
      });
    }

    if (mode === "identify") {
      const imageStr = String(body.image ?? "");
      if (!imageStr) {
        return NextResponse.json({ error: "Vui lòng cung cấp ảnh cây." }, { status: 400 });
      }
      const inline = await imageToInlineData(imageStr);
      const speciesClasses = getSpeciesClasses().map((s) => s.name);
      let isValid = false;
      let predictions: SpeciesPrediction[] = [];
      let modelUsed = "tf_efficientnetv2_b0.onnx";

      // Nếu không ưu tiên Gemini -> thử AI Engine trước
      if (!aiCfg.preferGemini) {
        const engineRes = await callAiEngine("/predict", inline.blob);
        if (engineRes) {
          isValid = Boolean(engineRes.is_valid_plant);
          if (isValid && Array.isArray(engineRes.top_3)) {
            predictions = engineRes.top_3.slice(0, 3).map((x) => {
              const r = x as Record<string, unknown>;
              return {
                speciesId: slugifySpecies(String(r.class ?? "")),
                confidence: normalizeConfidence(r.confidence, 0),
              };
            });
          } else if (isValid && typeof engineRes.prediction === "string") {
            predictions = [{ speciesId: slugifySpecies(engineRes.prediction), confidence: normalizeConfidence(engineRes.confidence, 0.8) }];
          }
        }
      }

      // Dùng Gemini Multimodal nếu preferGemini === true, hoặc AI Engine offline, hoặc AI Engine lọc nhầm (CLIP reject cây có hoa/quả màu vàng như bắp ngô)
      if (predictions.length === 0 && (aiCfg.preferGemini || process.env.GEMINI_API_KEY)) {
        const prompt = `Bạn là chuyên gia phân loại thực vật học Floria.
Bước 1 (Gatekeeper): Kiểm tra ảnh này có phải là thực vật (cây cảnh, lá cây, hoa, chậu cây, cây lương thực, bắp ngô, quả trên cây...) hay không. Chỉ đặt is_valid_plant = false nếu là người, động vật, đồ vật nhân tạo hoặc ảnh đen/mờ hoàn toàn.
Bước 2: Nếu is_valid_plant = true:
- TRƯỜNG HỢP A: Nếu khớp với 1 trong 40 loài chuẩn sau, đặt matched_database = true và trả về Top 3 dùng chính xác tên khoa học trong danh sách:
${speciesClasses.join(", ")}
- TRƯỜNG HỢP B: Nếu LÀ THỰC VẬT thật (ví dụ: Cây ngô/bắp, Cây lúa, Hoa hướng dương, Cây ăn quả...) nhưng KHÔNG nằm trong 40 loài trên, đặt matched_database = false, trả về 1 kết quả với scientificName và nameVi tiếng Việt chính xác của loài cây đó!

Trả về JSON thuần:
{
  "is_valid_plant": true,
  "matched_database": true,
  "predictions": [
    { "scientificName": "...", "nameVi": "...", "confidence": 0.92 }
  ]
}`;
        const gem = await callGeminiJson(prompt, inline);
        if (gem) {
          modelUsed = "gemini-multimodal";
          isValid = gem.is_valid_plant !== false;
          const matchedDb = gem.matched_database !== false;
          if (isValid && Array.isArray(gem.predictions)) {
            predictions = gem.predictions.slice(0, 3).map((x) => {
              const r = x as Record<string, unknown>;
              const sci = String(r.scientificName ?? r.scientific_name ?? "");
              const nVi = String(r.nameVi ?? r.name_vi ?? "");
              return {
                speciesId: slugifySpecies(sci || nVi),
                confidence: Math.min(0.99, Math.max(0.01, Number(r.confidence ?? 0.85))),
                ...(nVi ? { nameVi: nVi } : {}),
                ...(sci ? { scientificName: sci } : {}),
                matchedDatabase: matchedDb,
              };
            });
          }
        } else if (aiCfg.preferGemini) {
          // Thử fallback sang AI Engine lần cuối
          const engineRes = await callAiEngine("/predict", inline.blob);
          if (engineRes) {
            isValid = Boolean(engineRes.is_valid_plant);
            if (isValid && Array.isArray(engineRes.top_3)) {
              predictions = engineRes.top_3.slice(0, 3).map((x) => {
                const r = x as Record<string, unknown>;
                return {
                  speciesId: slugifySpecies(String(r.class ?? "")),
                  confidence: normalizeConfidence(r.confidence, 0),
                };
              });
            }
          }
        }
      }

      const savedImageUrl = await tryUploadToCloudinary(imageStr);
      const top = predictions[0];
      const topInfo = top && top.matchedDatabase !== false ? findPlantInfoOrFallback(top.speciesId) : null;
      const topSci = top?.scientificName || topInfo?.scientificName || (isValid ? "Unknown" : "Không phải cây");
      const topVi = top?.nameVi || topInfo?.commonName || (isValid ? "Chưa xác định" : "Không phải cây");

      const scanRef = await db.collection("ScanHistory").add({
        userId: user?.uid ?? null,
        type: "plant_discovery",
        isValidPlant: isValid,
        matchedDatabase: top?.matchedDatabase !== false,
        prediction: topSci,
        predictionVi: topVi,
        confidence: top?.confidence ?? 0,
        top3: predictions.map((p) => {
          const info = p.matchedDatabase !== false ? findPlantInfoOrFallback(p.speciesId) : null;
          return {
            class: p.scientificName || info?.scientificName || p.speciesId,
            name_vi: p.nameVi || info?.commonName || p.speciesId,
            confidence: p.confidence,
            speciesId: p.speciesId,
          };
        }),
        predictions,
        modelUsed,
        imageUrl: savedImageUrl,
        timestamp: nowIso,
        createdAt: nowIso,
      });

      return NextResponse.json({
        scanId: scanRef.id,
        is_valid_plant: isValid,
        image: savedImageUrl,
        predictions,
      });
    }

    if (mode === "diagnose") {
      if (!user) return NextResponse.json({ error: "Vui lòng đăng nhập." }, { status: 401 });
      const plantId = String(body.plantId ?? "");
      const imageStr = String(body.image ?? "");
      if (!plantId || !imageStr) {
        return NextResponse.json({ error: "Thiếu thông tin cây hoặc ảnh lá." }, { status: 400 });
      }

      const plantSnap = await db.collection("MyGarden").doc(plantId).get();
      if (!plantSnap.exists || plantSnap.data()?.userId !== user.uid) {
        return NextResponse.json({ error: "Không tìm thấy cây." }, { status: 404 });
      }
      const plantName = String(plantSnap.data()?.nickname ?? plantSnap.data()?.nameVi ?? "Cây của tôi");
      const inline = await imageToInlineData(imageStr);

      // Lấy danh sách bệnh thực tế trên Firestore DiseasesInfo
      const diseasesSnap = await db.collection("DiseasesInfo").get();
      const diseaseIds = diseasesSnap.empty
        ? getDiseaseClasses().map((d) => d.name)
        : diseasesSnap.docs.map((doc) => doc.id);

      let isValid = false;
      let diseaseId = "Healthy";
      let confidence = 0.85;
      let modelUsed = "tf_efficientnetv2_b0_disease.onnx";

      if (!aiCfg.preferGemini) {
        const engineRes = await callAiEngine("/predict-disease", inline.blob);
        if (engineRes) {
          isValid = Boolean(engineRes.is_valid_plant);
          if (typeof engineRes.prediction === "string" && engineRes.prediction) {
            diseaseId = engineRes.prediction;
          }
          confidence = normalizeConfidence(engineRes.confidence, 0.85);
        }
      }

      if ((aiCfg.preferGemini || !isValid) && process.env.GEMINI_API_KEY) {
        const prompt = `Bạn là bác sĩ bệnh học cây trồng của ứng dụng Floria.
Cây đang được kiểm tra là: "${plantName}".
Hãy quan sát kỹ ảnh lá/thân cây được cung cấp và thực hiện:
1. Kiểm duyệt thực vật: Nếu ảnh không phải thực vật (người, động vật, đồ vật, ảnh đen/mờ) -> đặt "is_valid_plant": false.
2. Nếu là thực vật: đối chiếu triệu chứng với 5 nhóm chuẩn trong CSDL:
- Healthy (Lá khỏe mạnh)
- Anthracnose (Bệnh thán thư)
- Bacterial_Blight (Bệnh cháy bìa lá / héo rũ vi khuẩn - ví dụ mép/chóp lá cháy khô nâu xám lan vào trong)
- Leaf_Spot (Bệnh đốm lá)
- Powdery_Mildew (Bệnh phấn trắng)
(Nếu khớp 1 trong 5 nhóm trên, trả về chính xác mã tiếng Anh trong 5 nhóm trên vào "diseaseId". Nếu là bệnh khác ngoài 5 nhóm trên, ghi tên bệnh ngắn gọn vào "diseaseId").

Trả về JSON thuần:
{
  "is_valid_plant": true,
  "diseaseId": "Bacterial_Blight",
  "confidence": 0.90
}`;
        const gem = await callGeminiJson(prompt, inline);
        if (gem) {
          modelUsed = "gemini-multimodal";
          isValid = gem.is_valid_plant !== false;
          if (typeof gem.diseaseId === "string" && gem.diseaseId) {
            diseaseId = gem.diseaseId;
          }
          confidence = normalizeConfidence(gem.confidence, 0.86);
        } else {
          const engineRes = await callAiEngine("/predict-disease", inline.blob);
          if (engineRes) {
            isValid = Boolean(engineRes.is_valid_plant);
            diseaseId = String(engineRes.prediction ?? "Healthy");
            confidence = normalizeConfidence(engineRes.confidence, 0.85);
          }
        }
      }

      const matchedDiseaseDoc = diseasesSnap.docs.find(
        (doc) => doc.id.toLowerCase() === diseaseId.toLowerCase() || doc.id.toLowerCase().replace(/[_\s]+/g, "-") === diseaseId.toLowerCase().replace(/[_\s]+/g, "-"),
      );
      const dd = matchedDiseaseDoc?.data() ?? {};
      const finalDiseaseId = matchedDiseaseDoc?.id ?? diseaseId;
      const savedImageUrl = await tryUploadToCloudinary(imageStr);

      const scanRef = await db.collection("ScanHistory").add({
        userId: user.uid,
        type: "disease_diagnosis",
        isValidPlant: isValid,
        plantId,
        plantName,
        prediction: finalDiseaseId,
        diseaseId: finalDiseaseId,
        predictionVi: String(dd.nameVi ?? finalDiseaseId),
        confidence,
        severity: String(dd.severity ?? "medium"),
        cause: String(dd.pathogen ?? dd.mechanism ?? ""),
        treatmentSteps: Array.isArray(dd.treatment) ? dd.treatment : Array.isArray(dd.treatmentSteps) ? dd.treatmentSteps : [],
        modelUsed,
        imageUrl: savedImageUrl,
        appliedToRecord: false,
        timestamp: nowIso,
        createdAt: nowIso,
      });

      return NextResponse.json({
        scanId: scanRef.id,
        is_valid_plant: isValid,
        image: savedImageUrl,
        diseaseId: finalDiseaseId,
        confidence,
      });
    }

    return NextResponse.json({ error: "Chế độ quét không hợp lệ." }, { status: 400 });
  } catch (err) {
    return NextResponse.json({ error: (err as Error).message || "Không thể xử lý yêu cầu quét AI" }, { status: 500 });
  }
}
