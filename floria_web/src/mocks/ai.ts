import type { AiConfig, AiModel, LabelReview } from "@/types";
import { daysAgo, seeded } from "@/lib/id";
import { LEAF_IMAGES } from "./images";
import { DISEASE_CLASSES, SPECIES_CLASSES } from "./ai-classes";

/** Demo metrics for UI development only — not results of a real evaluation run. */
export function seedModels(): AiModel[] {
  return [
    {
      id: "mdl_clip",
      name: "CLIP Gatekeeper",
      file: "clip_vit_b32_gatekeeper.onnx",
      kind: "gatekeeper",
      description: "Lọc ảnh đầu vào: xác định ảnh có chứa cây/lá trước khi chuyển sang các mô hình chuyên biệt.",
      version: "1.3.0",
      versions: [
        { version: "1.3.0", releasedAt: daysAgo(12), accuracy: 97.2, f1: 96.8, latencyMs: 38, note: "Bổ sung prompt cho ảnh thiếu sáng" },
        { version: "1.2.1", releasedAt: daysAgo(55), accuracy: 95.9, f1: 95.1, latencyMs: 41, note: "Tối ưu ngưỡng" },
        { version: "1.1.0", releasedAt: daysAgo(120), accuracy: 93.4, f1: 92.7, latencyMs: 47, note: "Phiên bản đầu" },
      ],
      active: true,
      accuracy: 97.2,
      precision: 96.5,
      recall: 97.1,
      f1: 96.8,
      latencyMs: 38,
      classes: 2,
      rollout: 100,
      updatedAt: daysAgo(12),
    },
    {
      id: "mdl_species",
      name: "Species Recognition",
      file: "tf_efficientnetv2_b0.onnx",
      kind: "species",
      description: "Nhận diện 40 loài cây cảnh phổ biến tại Việt Nam.",
      version: "2.4.0",
      versions: [
        { version: "2.4.0", releasedAt: daysAgo(6), accuracy: 92.8, f1: 92.1, latencyMs: 64, note: "Fine-tune thêm 3.200 ảnh từ Active Learning" },
        { version: "2.3.2", releasedAt: daysAgo(40), accuracy: 91.1, f1: 90.4, latencyMs: 66, note: "Cân bằng lớp Lan hồ điệp" },
        { version: "2.2.0", releasedAt: daysAgo(95), accuracy: 88.7, f1: 87.9, latencyMs: 71, note: "Mở rộng lên 40 lớp" },
      ],
      active: true,
      accuracy: 92.8,
      precision: 91.9,
      recall: 92.4,
      f1: 92.1,
      latencyMs: 64,
      classes: SPECIES_CLASSES.length,
      rollout: 100,
      updatedAt: daysAgo(6),
    },
    {
      id: "mdl_disease",
      name: "Disease Detection",
      file: "tf_efficientnetv2_b0_disease.onnx",
      kind: "disease",
      description: "Phân loại 5 nhóm bệnh lá phổ biến và lá khoẻ mạnh.",
      version: "1.6.1",
      versions: [
        { version: "1.6.1", releasedAt: daysAgo(18), accuracy: 89.4, f1: 88.2, latencyMs: 58, note: "Giảm nhầm lẫn Đốm lá / Gỉ sắt" },
        { version: "1.5.0", releasedAt: daysAgo(70), accuracy: 86.9, f1: 85.6, latencyMs: 60, note: "Thêm lớp Cháy lá vi khuẩn" },
      ],
      active: true,
      accuracy: 89.4,
      precision: 88.6,
      recall: 87.9,
      f1: 88.2,
      latencyMs: 58,
      classes: DISEASE_CLASSES.length,
      rollout: 80,
      updatedAt: daysAgo(18),
    },
  ];
}

export const DEFAULT_AI_CONFIG: AiConfig = {
  confidenceThreshold: 0.65,
  gatekeeperThreshold: 0.5,
  topK: 3,
  inputSize: 224,
  speciesVersion: "2.4.0",
  diseaseVersion: "1.6.1",
  executionProvider: "CPUExecutionProvider",
  batchSize: 1,
  normalize: true,
};

export function seedLabelReviews(): LabelReview[] {
  const r = seeded(7);
  const names = ["Trần Thu Hà", "Lê Minh Quân", "Phạm Ngọc Vy", "Đỗ Gia Bảo", "Võ Thanh Trang", "Bùi Quốc Hưng"];
  return Array.from({ length: 18 }, (_, i) => {
    const sp = SPECIES_CLASSES[Math.floor(r() * 12)];
    const ds = DISEASE_CLASSES[Math.floor(r() * DISEASE_CLASSES.length)];
    const status = i < 10 ? "pending" : i % 3 === 0 ? "rejected" : "approved";
    return {
      id: `lbl_${2000 + i}`,
      image: LEAF_IMAGES[i % LEAF_IMAGES.length],
      userName: names[i % names.length],
      predictedSpecies: sp.vi,
      predictedDisease: ds.vi,
      confidence: Math.round((0.38 + r() * 0.3) * 1000) / 1000,
      submittedAt: daysAgo(Math.floor(i / 2), 7 + (i % 10)),
      status,
      finalSpecies: status === "approved" ? sp.vi : undefined,
      finalDisease: status === "approved" ? ds.vi : undefined,
      notes: status === "rejected" ? "Ảnh mờ, không đủ chi tiết lá." : "",
      reviewedBy: status === "pending" ? undefined : "TS. Nguyễn Thảo",
    } satisfies LabelReview;
  });
}

/** Demo analytics series for the AI Analytics tab. */
export const CONFIDENCE_BUCKETS = [
  { bucket: "0–0,2", count: 120 },
  { bucket: "0,2–0,4", count: 310 },
  { bucket: "0,4–0,6", count: 860 },
  { bucket: "0,6–0,8", count: 2140 },
  { bucket: "0,8–0,9", count: 3380 },
  { bucket: "0,9–1,0", count: 5210 },
];

export const CLIP_REJECTION = Array.from({ length: 14 }, (_, i) => ({
  day: daysAgo(13 - i),
  rate: Math.round((6 + Math.sin(i / 2) * 2.2 + (i % 3)) * 10) / 10,
}));

export const CONFUSED_SPECIES = [
  { pair: "Trầu bà vàng ↔ Trầu bà lá tim", count: 184 },
  { pair: "Phát tài ↔ Lưỡi hổ", count: 121 },
  { pair: "Đa búp đỏ ↔ Bàng Singapore", count: 97 },
  { pair: "Vạn niên thanh ↔ Vạn niên thanh đốm", count: 88 },
  { pair: "Sen đá ↔ Ngọc bích", count: 64 },
];

export const CONFUSED_DISEASES = [
  { pair: "Đốm lá ↔ Gỉ sắt", count: 142 },
  { pair: "Cháy lá vi khuẩn ↔ Đốm lá", count: 96 },
  { pair: "Thối rễ ↔ Lá khoẻ mạnh", count: 51 },
  { pair: "Phấn trắng ↔ Lá khoẻ mạnh", count: 33 },
];

/** Row = actual, column = predicted, values in % (demo). */
export const DISEASE_CONFUSION: number[][] = [
  [94, 2, 1, 1, 1, 1],
  [3, 86, 1, 7, 3, 0],
  [4, 1, 92, 1, 1, 1],
  [1, 9, 1, 85, 3, 1],
  [2, 6, 0, 2, 88, 2],
  [6, 2, 0, 1, 2, 89],
];
