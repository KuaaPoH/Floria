import type { DiseaseInfo } from "@/types/user";

// DiseasesInfo — the 5 result classes of tf_efficientnetv2_b0_disease.
export const DISEASES_INFO: DiseaseInfo[] = [
  {
    id: "healthy",
    name: "Lá khỏe mạnh",
    nameEn: "Healthy leaf",
    isHealthy: true,
    severity: "none",
    agent: "Không phát hiện tác nhân gây bệnh.",
    mechanism: "Mô lá phát triển bình thường, diệp lục phân bố đều.",
    outbreakConditions: "—",
    symptoms: "Lá xanh đều màu, không đốm, không biến dạng.",
    prevention: ["Duy trì lịch tưới và bón phân hiện tại.", "Kiểm tra mặt dưới lá định kỳ."],
    treatment: ["Không cần xử lý."],
    relatedProductIds: [],
  },
  {
    id: "leaf-spot",
    name: "Bệnh đốm lá",
    nameEn: "Leaf spot",
    isHealthy: false,
    severity: "medium",
    agent: "Nấm Cercospora, Septoria hoặc vi khuẩn Xanthomonas.",
    mechanism: "Bào tử bám trên mặt lá ẩm, xâm nhập qua khí khổng và phá hủy mô lá tạo vết hoại tử.",
    outbreakConditions: "Độ ẩm cao kéo dài, lá ướt qua đêm, cây trồng dày thiếu thông thoáng.",
    symptoms: "Đốm nâu tròn có quầng vàng, đốm lan rộng và liên kết, lá vàng rồi rụng.",
    prevention: ["Tưới vào gốc, tránh làm ướt lá buổi chiều.", "Tăng thông gió, giãn khoảng cách chậu.", "Vệ sinh lá rụng quanh gốc."],
    treatment: ["Cắt bỏ lá bệnh và tiêu hủy.", "Phun thuốc gốc đồng hoặc chế phẩm sinh học 7 ngày/lần.", "Cách ly cây khỏi các cây khác."],
    relatedProductIds: ["prd-fungicide", "prd-neem"],
  },
  {
    id: "powdery-mildew",
    name: "Bệnh phấn trắng",
    nameEn: "Powdery mildew",
    isHealthy: false,
    severity: "low",
    agent: "Nấm thuộc bộ Erysiphales (Oidium spp.).",
    mechanism: "Sợi nấm phát triển trên bề mặt lá, hút dinh dưỡng từ tế bào biểu bì.",
    outbreakConditions: "Ngày ấm khô, đêm ẩm, thiếu ánh sáng.",
    symptoms: "Lớp bột trắng xám phủ mặt lá, lá xoăn, chậm phát triển.",
    prevention: ["Đặt cây nơi đủ sáng.", "Không bón thừa đạm."],
    treatment: ["Lau sạch lớp phấn bằng khăn ẩm.", "Phun dầu neem pha loãng 5 ngày/lần."],
    relatedProductIds: ["prd-neem", "prd-mister"],
  },
  {
    id: "rust",
    name: "Bệnh gỉ sắt",
    nameEn: "Rust",
    isHealthy: false,
    severity: "medium",
    agent: "Nấm thuộc bộ Pucciniales.",
    mechanism: "Bào tử nảy mầm trên lá ẩm, hình thành ổ bào tử màu cam ở mặt dưới lá.",
    outbreakConditions: "Mùa mưa, nhiệt độ 18–25°C, lá ẩm kéo dài.",
    symptoms: "Mụn nhỏ màu cam nâu ở mặt dưới lá, mặt trên có đốm vàng nhạt.",
    prevention: ["Tưới gốc buổi sáng.", "Loại bỏ lá già sát đất."],
    treatment: ["Ngắt bỏ lá nhiễm.", "Phun thuốc trừ nấm theo hướng dẫn nhà sản xuất."],
    relatedProductIds: ["prd-fungicide"],
  },
  {
    id: "leaf-blight",
    name: "Bệnh cháy lá",
    nameEn: "Leaf blight",
    isHealthy: false,
    severity: "high",
    agent: "Nấm Alternaria, Phytophthora hoặc vi khuẩn Pseudomonas.",
    mechanism: "Tác nhân lan nhanh theo mạch lá, gây chết mô hàng loạt từ mép vào trong.",
    outbreakConditions: "Mưa nhiều, đất úng, vết thương cơ giới trên lá.",
    symptoms: "Mép lá cháy nâu đen lan nhanh, mô lá khô giòn, có thể lan xuống thân.",
    prevention: ["Đảm bảo thoát nước tốt.", "Khử trùng dụng cụ cắt tỉa."],
    treatment: ["Cắt bỏ toàn bộ phần lá cháy.", "Ngưng tưới lên lá, cải thiện thoát nước.", "Tham khảo chuyên gia nếu bệnh lan xuống thân."],
    relatedProductIds: ["prd-fungicide", "prd-soil"],
  },
  {
    id: "bacterial-blight",
    name: "Cháy bìa lá vi khuẩn",
    nameEn: "Bacterial Blight",
    isHealthy: false,
    severity: "high",
    agent: "Vi khuẩn Xanthomonas hoặc Erwinia xâm nhập qua khí khổng hoặc vết thương hở.",
    mechanism: "Vi khuẩn phát triển nhanh trong mạch dẫn khi giá thể quá ẩm, làm cháy khô mép và chóp lá.",
    outbreakConditions: "Độ ẩm cao, giá thể úng nước, tưới đọng nước trên lá.",
    symptoms: "Mép hoặc chóp lá xuất hiện vùng cháy khô nâu xám lan dần vào trong phiến lá.",
    prevention: ["Không tưới đọng nước lên lá vào chiều tối.", "Giữ giá thể thoát nước tốt."],
    treatment: ["Ngừng tưới 2–3 ngày để giá thể khô ráo.", "Cắt bỏ phần lá cháy, bôi keo liền sẹo hoặc vôi bột.", "Phun chế phẩm đặc trị vi khuẩn hoặc Nano Bạc."],
    relatedProductIds: ["prd-fungicide", "prd-soil"],
  },
  {
    id: "anthracnose",
    name: "Bệnh thán thư",
    nameEn: "Anthracnose",
    isHealthy: false,
    severity: "high",
    agent: "Nấm Colletotrichum spp.",
    mechanism: "Nấm gây các vết hoại tử nâu sẫm lõm xuống trên lá và lan rộng khi độ ẩm cao.",
    outbreakConditions: "Mưa nhiều, độ ẩm cao, tưới phun lên tán lá vào ban đêm.",
    symptoms: "Các đốm nâu đen lớn có viền rõ, thường xuất hiện ở đầu hoặc mép lá.",
    prevention: ["Cách ly chậu cây có dấu hiệu bệnh.", "Tưới nhẹ vào gốc buổi sáng."],
    treatment: ["Cắt bỏ các lá bị đốm hoại tử bằng kéo đã khử trùng.", "Phun thuốc trừ nấm gốc đồng hoặc Nano Bạc 2 lần cách nhau 5 ngày."],
    relatedProductIds: ["prd-fungicide"],
  },
];

let runtimeDiseasesInfo: DiseaseInfo[] | null = null;

export function setRuntimeDiseasesInfo(list: DiseaseInfo[]) {
  if (Array.isArray(list) && list.length > 0) {
    runtimeDiseasesInfo = list;
  }
}

export function getAllDiseasesInfo(): DiseaseInfo[] {
  return runtimeDiseasesInfo && runtimeDiseasesInfo.length > 0 ? runtimeDiseasesInfo : DISEASES_INFO;
}

function normDiseaseKey(s: string): string {
  return s.trim().toLowerCase().replace(/[_\s]+/g, "-");
}

const DISEASE_ALIASES: Record<string, string> = {
  healthy: "healthy",
  "la-khoe-manh": "healthy",
  anthracnose: "anthracnose",
  "bacterial-blight": "bacterial-blight",
  "leaf-spot": "leaf-spot",
  "powdery-mildew": "powdery-mildew",
  rust: "rust",
  "leaf-blight": "leaf-blight",
};

export const findDisease = (idOrName: string): DiseaseInfo | undefined => {
  const list = getAllDiseasesInfo();
  const raw = idOrName.trim().toLowerCase();
  if (!raw) return undefined;
  const norm = normDiseaseKey(raw);
  const aliased = DISEASE_ALIASES[norm] ?? norm;
  return (
    list.find(
      (d) =>
        normDiseaseKey(d.id) === norm ||
        normDiseaseKey(d.id) === aliased ||
        normDiseaseKey(d.nameEn) === norm ||
        normDiseaseKey(d.name) === norm,
    ) ??
    DISEASES_INFO.find(
      (d) =>
        normDiseaseKey(d.id) === norm ||
        normDiseaseKey(d.id) === aliased ||
        normDiseaseKey(d.nameEn) === norm,
    )
  );
};
