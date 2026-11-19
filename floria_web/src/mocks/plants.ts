import type { Plant } from "@/types";
import { daysAgo } from "@/lib/id";
import { IMAGES } from "./images";
import { SPECIES_CLASSES } from "./ai-classes";

type Row = [string, string, string, string, string, string, string, boolean, number | null, string[]];
// viName, sciName, enName, category, light, watering, image key, petToxic, aiClassId, related diseases
const ROWS: Row[] = [
  ["Trầu bà lá xẻ", "Monstera deliciosa", "Swiss cheese plant", "Cây trong nhà", "Ánh sáng tán xạ", "1 lần/tuần", "monstera", true, 0, ["dis_leaf_spot", "dis_root_rot"]],
  ["Lưỡi hổ", "Sansevieria trifasciata", "Snake plant", "Cây trong nhà", "Bóng râm đến nắng nhẹ", "2–3 tuần/lần", "snake", true, 1, ["dis_root_rot"]],
  ["Lan hồ điệp", "Phalaenopsis sp.", "Moth orchid", "Cây hoa", "Ánh sáng tán xạ", "1 lần/tuần", "orchid", false, 2, ["dis_leaf_spot", "dis_bacterial"]],
  ["Bàng Singapore", "Ficus lyrata", "Fiddle leaf fig", "Cây trong nhà", "Nắng sáng gián tiếp", "1 lần/tuần", "fiddle", true, 3, ["dis_leaf_spot", "dis_root_rot"]],
  ["Trầu bà vàng", "Epipremnum aureum", "Golden pothos", "Cây leo", "Ánh sáng yếu đến vừa", "1–2 lần/tuần", "pothos", true, 4, ["dis_root_rot", "dis_bacterial"]],
  ["Lan ý", "Spathiphyllum wallisii", "Peace lily", "Cây trong nhà", "Bóng râm", "2 lần/tuần", "pothos", true, 5, ["dis_leaf_spot"]],
  ["Kim tiền", "Zamioculcas zamiifolia", "ZZ plant", "Cây phong thuỷ", "Ánh sáng yếu", "2 tuần/lần", "snake", true, 6, ["dis_root_rot"]],
  ["Cỏ lan chi", "Chlorophytum comosum", "Spider plant", "Cây treo", "Ánh sáng tán xạ", "1 lần/tuần", "pothos", false, 7, ["dis_leaf_spot"]],
  ["Vạn niên thanh", "Aglaonema commutatum", "Chinese evergreen", "Cây phong thuỷ", "Bóng râm", "1 lần/tuần", "monstera", true, 8, ["dis_bacterial"]],
  ["Phát tài", "Dracaena fragrans", "Corn plant", "Cây phong thuỷ", "Ánh sáng vừa", "1 lần/tuần", "snake", true, 9, ["dis_leaf_spot"]],
  ["Đa búp đỏ", "Ficus elastica", "Rubber plant", "Cây trong nhà", "Nắng sáng gián tiếp", "1 lần/tuần", "fiddle", true, 10, ["dis_powdery"]],
  ["Hoa hồng", "Rosa chinensis", "China rose", "Cây hoa", "Nắng trực tiếp 6h", "Hằng ngày", "orchid", false, 28, ["dis_powdery", "dis_rust", "dis_leaf_spot"]],
  ["Hoa giấy", "Bougainvillea glabra", "Bougainvillea", "Cây ngoài trời", "Nắng trực tiếp", "2–3 lần/tuần", "orchid", false, 26, ["dis_leaf_spot"]],
  ["Nha đam", "Aloe vera", "Aloe vera", "Mọng nước", "Nắng nhiều", "2 tuần/lần", "snake", true, 13, ["dis_root_rot"]],
  ["Sen đá", "Echeveria elegans", "Mexican snowball", "Mọng nước", "Nắng nhiều", "10 ngày/lần", "snake", false, 14, ["dis_root_rot", "dis_powdery"]],
  ["Dâm bụt", "Hibiscus rosa-sinensis", "Chinese hibiscus", "Cây ngoài trời", "Nắng trực tiếp", "Hằng ngày", "orchid", false, 27, ["dis_rust", "dis_powdery"]],
  ["Trầu bà lá tim", "Philodendron hederaceum", "Heartleaf philodendron", "Cây leo", "Ánh sáng tán xạ", "1 lần/tuần", "pothos", true, 4, ["dis_root_rot"]],
  ["Hồng môn", "Anthurium andraeanum", "Flamingo flower", "Cây hoa", "Ánh sáng tán xạ", "2 lần/tuần", "monstera", true, null, ["dis_bacterial"]],
];

export const PLANT_CATEGORIES = ["Cây trong nhà", "Cây hoa", "Cây leo", "Cây treo", "Cây phong thuỷ", "Cây ngoài trời", "Mọng nước"];

export function seedPlants(): Plant[] {
  return ROWS.map(([vi, sci, en, cat, light, water, img, toxic, classId, related], i) => ({
    id: `plt_${String(i + 1).padStart(3, "0")}`,
    viName: vi,
    sciName: sci,
    enName: en,
    category: cat,
    image: IMAGES[img as keyof typeof IMAGES],
    description: `${vi} (${sci}) là loài cây được nhiều người dùng Floria trồng. Cây thích nghi tốt với khí hậu Việt Nam, phù hợp không gian ${cat.toLowerCase()} và dễ chăm sóc khi đảm bảo đủ ánh sáng và độ ẩm.`,
    light,
    watering: water,
    soil: cat === "Mọng nước" ? "Đất thoát nước nhanh, trộn đá perlite" : cat === "Cây hoa" ? "Giá thể tơi xốp, giàu hữu cơ" : "Đất thịt nhẹ trộn xơ dừa, trấu hun",
    humidity: cat === "Mọng nước" ? "30–40%" : "50–70%",
    temperature: cat === "Cây ngoài trời" ? "22–35°C" : "18–30°C",
    petToxic: toxic,
    toxicityNote: toxic ? "Nhựa cây chứa calcium oxalate, gây kích ứng miệng và tiêu hoá ở chó, mèo và trẻ nhỏ." : "Chưa ghi nhận độc tính với thú cưng.",
    aiClassId: classId,
    aiClassName: classId === null ? "" : SPECIES_CLASSES[classId].name,
    relatedDiseaseIds: related,
    careTips: [
      `Tưới ${water.toLowerCase()}, kiểm tra 2–3 cm đất mặt khô trước khi tưới.`,
      `Đặt cây ở vị trí ${light.toLowerCase()}.`,
      "Bón phân NPK cân bằng 1 lần/tháng vào mùa sinh trưởng.",
      "Lau lá định kỳ để cây quang hợp tốt.",
    ],
    status: i === 17 ? "draft" : "published",
    updatedAt: daysAgo(i * 3 + 1),
  }));
}
