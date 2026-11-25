import { isMock } from "@/config/env";
import { uid } from "@/lib/id";
import { readDb, writeDb } from "@/mocks/user/db";
import { DISEASES_INFO, findDisease } from "@/mocks/user/diseases";
import { PLANTS_INFO } from "@/mocks/user/plants-info";
import type { ScanHistoryItem, SpeciesPrediction } from "@/types/user";
import { http } from "./api/http";
import { fetchUserCatalog } from "./content.service";
import { analyzeImage } from "./mock/image-analysis";
import { latency, MockError, requireUid } from "./mock/util";
import { session } from "./session";

export interface IdentifyResponse {
  scanId: string;
  is_valid_plant: boolean;
  image: string;
  predictions: SpeciesPrediction[];
}

export interface DiagnoseResponse {
  scanId: string;
  is_valid_plant: boolean;
  image: string;
  diseaseId: string;
  confidence: number;
}

export interface HintIdentifyResponse {
  speciesId: string | null;
  confidence: number;
  alternatives: SpeciesPrediction[];
  note: string;
}

export interface ReportScanInput {
  reportType: "wrong_prediction" | "missing_plant" | "update_request";
  suggestedName: string;
  note: string;
  predictedLabel: string;
  predictedNameVi: string;
  confidence: number | null;
  isValidPlant: boolean;
  isDiseaseScan: boolean;
  imageUrl: string;
}

export interface ScanService {
  identify(image: string): Promise<IdentifyResponse>;
  diagnose(plantId: string, image: string): Promise<DiagnoseResponse>;
  identifyWithHint(input: { image: string | null; description: string; nameHint?: string }): Promise<HintIdentifyResponse>;
  listHistory(): Promise<ScanHistoryItem[]>;
  getScan(id: string): Promise<ScanHistoryItem | null>;
  applyDiagnosis(scanId: string): Promise<void>;
  reportScan(input: ReportScanInput): Promise<{ id: string; submitted: boolean }>;
}

function topPredictions(hash: number): SpeciesPrediction[] {
  const n = PLANTS_INFO.length;
  const first = hash % n;
  const second = (first + 1 + ((hash >> 5) % (n - 1))) % n;
  let third = (second + 1 + ((hash >> 9) % (n - 2))) % n;
  if (third === first) third = (third + 1) % n;
  const c1 = 0.62 + ((hash >> 3) % 33) / 100;
  const c2 = Math.round((1 - c1) * 0.65 * 100) / 100;
  const c3 = Math.round((1 - c1 - c2) * 0.6 * 100) / 100;
  return [
    { speciesId: PLANTS_INFO[first].id, confidence: Math.round(c1 * 100) / 100 },
    { speciesId: PLANTS_INFO[second].id, confidence: c2 },
    { speciesId: PLANTS_INFO[third].id, confidence: c3 },
  ];
}

const mockScan: ScanService = {
  async identify(image) {
    const { greenRatio, hash } = await analyzeImage(image);
    await latency(1400, 2200);
    const userId = session.get();
    const valid = greenRatio >= 0.06;
    const predictions = valid ? topPredictions(hash) : [];
    const scan: ScanHistoryItem = { id: uid("scan"), userId, type: "identify", image, createdAt: new Date().toISOString(), isValidPlant: valid, predictions };
    writeDb((db) => {
      db.scans.push(scan);
    });
    return { scanId: scan.id, is_valid_plant: valid, image, predictions };
  },
  async diagnose(plantId, image) {
    const u = requireUid(session.get());
    const { greenRatio, hash } = await analyzeImage(image);
    await latency(1600, 2400);
    if (!readDb().plants.some((p) => p.id === plantId && p.userId === u)) throw new MockError("Không tìm thấy cây.", "not_found");
    const valid = greenRatio >= 0.06;
    const disease = DISEASES_INFO[hash % DISEASES_INFO.length];
    const confidence = Math.round((0.68 + ((hash >> 4) % 28) / 100) * 100) / 100;
    const scan: ScanHistoryItem = { id: uid("scan"), userId: u, type: "diagnose", image, createdAt: new Date().toISOString(), isValidPlant: valid, plantId, diseaseId: valid ? disease.id : undefined, confidence: valid ? confidence : undefined, appliedToRecord: false };
    writeDb((db) => {
      db.scans.push(scan);
    });
    return { scanId: scan.id, is_valid_plant: valid, image, diseaseId: disease.id, confidence };
  },
  async identifyWithHint({ image, description, nameHint = "" }) {
    await latency(1200, 1800);
    const q = `${nameHint} ${description}`.toLowerCase();
    const byName = PLANTS_INFO.find((p) => [p.commonName, p.commonNameEn, p.scientificName].some((n) => q.includes(n.toLowerCase())) || q.includes(p.id.split("-")[0]));
    let preds: SpeciesPrediction[] = [];
    if (image) {
      const { greenRatio, hash } = await analyzeImage(image);
      if (greenRatio < 0.06 && !byName) return { speciesId: null, confidence: 0, alternatives: [], note: "Ảnh không giống thực vật. Hãy thử ảnh rõ lá và thân cây." };
      preds = topPredictions(hash);
    }
    if (byName) {
      preds = [{ speciesId: byName.id, confidence: 0.91 }, ...preds.filter((p) => p.speciesId !== byName.id)].slice(0, 3);
    }
    if (!preds.length) return { speciesId: null, confidence: 0, alternatives: [], note: "Chưa đủ thông tin. Hãy tải ảnh hoặc nhập tên gợi ý." };
    return { speciesId: preds[0].speciesId, confidence: preds[0].confidence, alternatives: preds.slice(1), note: byName ? "Khớp với tên gợi ý bạn nhập." : "Dựa trên hình ảnh và mô tả hình thái." };
  },
  async listHistory() {
    await latency(200, 400);
    const u = requireUid(session.get());
    return readDb().scans.filter((s) => s.userId === u).sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  },
  async getScan(id) {
    await latency(100, 250);
    const u = session.get();
    const s = readDb().scans.find((x) => x.id === id);
    if (!s) return null;
    if (s.userId && s.userId !== u) return null;
    return s;
  },
  async applyDiagnosis(scanId) {
    await latency(400, 700);
    const u = requireUid(session.get());
    writeDb((db) => {
      const scan = db.scans.find((s) => s.id === scanId && s.userId === u);
      if (!scan || scan.type !== "diagnose" || !scan.plantId || !scan.diseaseId) throw new MockError("Không tìm thấy kết quả chẩn đoán.", "not_found");
      if (scan.appliedToRecord) throw new MockError("Kết quả này đã được cập nhật vào bệnh án.", "already_applied");
      const plant = db.plants.find((p) => p.id === scan.plantId && p.userId === u);
      if (!plant) throw new MockError("Không tìm thấy cây.", "not_found");
      const disease = findDisease(scan.diseaseId)!;
      plant.healthStatus = disease.isHealthy ? (plant.healthStatus === "sick" ? "recovering" : "healthy") : "sick";
      plant.activeDiseaseId = disease.isHealthy ? null : disease.id;
      const now = new Date().toISOString();
      db.diary.push({
        id: uid("dn"), plantId: plant.id, userId: u, category: "health",
        content: `Chẩn đoán: ${disease.name} (${Math.round((scan.confidence ?? 0) * 100)}%). ${disease.isHealthy ? "Lá khỏe mạnh." : disease.symptoms}`,
        images: [scan.image], diagnosisId: scan.id, createdAt: now, updatedAt: now,
      });
      scan.appliedToRecord = true;
    });
  },
  async reportScan() {
    await latency(300, 500);
    return { id: uid("req"), submitted: true };
  },
};

const apiScan: ScanService = {
  async identify(image) {
    await fetchUserCatalog().catch(() => null);
    return http<IdentifyResponse>("/scan", { method: "POST", json: { mode: "identify", image }, timeoutMs: 45000 });
  },
  async diagnose(plantId, image) {
    await fetchUserCatalog().catch(() => null);
    return http<DiagnoseResponse>("/scan", { method: "POST", json: { mode: "diagnose", plantId, image }, timeoutMs: 45000 });
  },
  async identifyWithHint(input) {
    await fetchUserCatalog().catch(() => null);
    return http<HintIdentifyResponse>("/scan", { method: "POST", json: { mode: "hint", ...input }, timeoutMs: 45000 });
  },
  async listHistory() {
    await fetchUserCatalog().catch(() => null);
    return http<ScanHistoryItem[]>("/scan");
  },
  async getScan(id) {
    await fetchUserCatalog().catch(() => null);
    try {
      return await http<ScanHistoryItem>(`/scan?id=${encodeURIComponent(id)}`);
    } catch (e) {
      if (e instanceof Error && "status" in e && (e as { status: number }).status === 404) {
        return null;
      }
      throw e;
    }
  },
  async applyDiagnosis(scanId) {
    await http("/scan", { method: "POST", json: { mode: "apply", scanId } });
  },
  async reportScan(input) {
    return http<{ id: string; submitted: boolean }>("/scan", { method: "POST", json: { mode: "report", ...input } });
  },
};

export const scanService: ScanService = isMock() ? mockScan : apiScan;
