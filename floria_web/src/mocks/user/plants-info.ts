import type { PlantInfo } from "@/types/user";
import { IMG } from "./images";

// plants_info — fallback subset while full 40 species load from Firestore `plants_info`.
export const PLANTS_INFO: PlantInfo[] = [
  {
    id: "monstera-deliciosa",
    commonName: "Trầu bà Nam Mỹ",
    commonNameEn: "Swiss Cheese Plant",
    scientificName: "Monstera deliciosa",
    family: "Araceae",
    image: IMG.plants.monstera,
    description: "Cây thân leo nhiệt đới với những chiếc lá lớn xẻ thùy đặc trưng, rất được ưa chuộng trong trang trí nội thất hiện đại.",
    origin: "Rừng mưa nhiệt đới Trung và Nam Mỹ (Mexico đến Panama).",
    environment: "Trong nhà, nơi thoáng khí, tránh gió lùa.",
    light: "Ánh sáng gián tiếp sáng; chịu được bóng râm một phần.",
    water: "Tưới khi 3–5 cm đất mặt khô, khoảng 1 lần/tuần.",
    soil: "Giá thể tơi xốp, thoát nước tốt: đất trộn vỏ thông, perlite và xơ dừa.",
    temperature: "18–30°C, không chịu được dưới 12°C.",
    humidity: "60–80%, thích phun sương vào mùa khô.",
    toxicity: "Độc nhẹ với chó mèo nếu nhai lá (chứa calcium oxalate).",
    careTips: ["Lau lá 2 tuần/lần để lá quang hợp tốt.", "Cắm cọc rêu giúp cây leo và ra lá xẻ thùy lớn hơn.", "Xoay chậu mỗi tháng để cây phát triển đều."],
    idealLight: ["indirect", "bright"],
    idealEnvironments: ["indoor", "balcony"],
    wateringDays: 7,
    fertilizingDays: 30,
    inspectionDays: 14,
  },
  {
    id: "ficus-lyrata",
    commonName: "Bàng Singapore",
    commonNameEn: "Fiddle Leaf Fig",
    scientificName: "Ficus lyrata",
    family: "Moraceae",
    image: IMG.plants.fiddle,
    description: "Cây thân gỗ với lá to hình đàn violin, tạo điểm nhấn mạnh mẽ cho phòng khách.",
    origin: "Vùng đất thấp nhiệt đới Tây Phi.",
    environment: "Trong nhà gần cửa sổ lớn, ổn định vị trí.",
    light: "Ánh sáng mạnh gián tiếp, chịu được nắng sớm.",
    water: "Tưới đẫm khi đất khô 50%, khoảng 7–10 ngày/lần.",
    soil: "Đất thịt nhẹ trộn perlite, thoát nước tốt.",
    temperature: "16–30°C.",
    humidity: "40–60%.",
    toxicity: "Nhựa cây có thể gây kích ứng da và độc với thú cưng.",
    careTips: ["Hạn chế di chuyển chậu — cây dễ rụng lá khi đổi môi trường.", "Lau bụi trên lá để tránh nhện đỏ."],
    idealLight: ["bright"],
    idealEnvironments: ["indoor"],
    wateringDays: 8,
    fertilizingDays: 30,
    inspectionDays: 14,
  },
  {
    id: "sansevieria-trifasciata",
    commonName: "Lưỡi hổ",
    commonNameEn: "Snake Plant",
    scientificName: "Dracaena trifasciata",
    family: "Asparagaceae",
    image: IMG.plants.snake,
    description: "Loài cây mọng nước cứng cáp, chịu hạn tốt và được biết đến với khả năng lọc không khí.",
    origin: "Tây Phi nhiệt đới, từ Nigeria đến Congo.",
    environment: "Trong nhà, văn phòng, phòng ngủ.",
    light: "Chịu được ánh sáng yếu đến mạnh.",
    water: "Tưới ít, 2–3 tuần/lần; mùa đông giảm còn 1 lần/tháng.",
    soil: "Đất cát pha hoặc đất cho xương rồng, thoát nước nhanh.",
    temperature: "15–32°C.",
    humidity: "30–50%, không kén độ ẩm.",
    toxicity: "Độc nhẹ với chó mèo.",
    careTips: ["Tưới quá nhiều là nguyên nhân hàng đầu gây thối gốc.", "Tách bụi khi chậu chật để nhân giống."],
    idealLight: ["low", "indirect", "bright"],
    idealEnvironments: ["indoor", "balcony"],
    wateringDays: 18,
    fertilizingDays: 45,
    inspectionDays: 21,
  },
  {
    id: "epipremnum-aureum",
    commonName: "Trầu bà vàng",
    commonNameEn: "Golden Pothos",
    scientificName: "Epipremnum aureum",
    family: "Araceae",
    image: IMG.plants.pothos,
    description: "Cây dây leo dễ trồng với lá hình tim loang vàng, phù hợp treo giỏ hoặc đặt kệ.",
    origin: "Quần đảo Society, Polynesia thuộc Pháp.",
    environment: "Trong nhà, kệ sách, giỏ treo, bể thủy sinh.",
    light: "Ánh sáng gián tiếp; ánh sáng yếu làm lá mất vân vàng.",
    water: "Tưới khi đất mặt khô, khoảng 5–7 ngày/lần.",
    soil: "Đất trồng cây cảnh thông thường, tơi xốp.",
    temperature: "17–30°C.",
    humidity: "50–70%.",
    toxicity: "Độc với chó mèo và trẻ nhỏ nếu nuốt phải.",
    careTips: ["Cắt ngọn để cây đâm nhánh rậm hơn.", "Có thể giâm cành trong nước dễ dàng."],
    idealLight: ["low", "indirect"],
    idealEnvironments: ["indoor"],
    wateringDays: 6,
    fertilizingDays: 30,
    inspectionDays: 14,
  },
  {
    id: "spathiphyllum-wallisii",
    commonName: "Lan ý",
    commonNameEn: "Peace Lily",
    scientificName: "Spathiphyllum wallisii",
    family: "Araceae",
    image: IMG.plants.peaceLily,
    description: "Cây có hoa mo trắng thanh lịch, lá xanh bóng, nổi tiếng với khả năng cải thiện chất lượng không khí.",
    origin: "Rừng nhiệt đới Colombia và Venezuela.",
    environment: "Trong nhà, phòng ngủ, phòng làm việc.",
    light: "Ánh sáng gián tiếp vừa phải, tránh nắng gắt.",
    water: "Giữ đất ẩm đều, khoảng 4–5 ngày/lần. Lá rũ là dấu hiệu khát nước.",
    soil: "Đất giàu mùn, giữ ẩm nhưng thoát nước.",
    temperature: "18–28°C.",
    humidity: "50–70%.",
    toxicity: "Độc với chó mèo.",
    careTips: ["Cắt bỏ hoa đã tàn sát gốc.", "Dùng nước để qua đêm để tránh cháy đầu lá."],
    idealLight: ["low", "indirect"],
    idealEnvironments: ["indoor"],
    wateringDays: 4,
    fertilizingDays: 30,
    inspectionDays: 10,
  },
  {
    id: "calathea-orbifolia",
    commonName: "Đuôi công tròn",
    commonNameEn: "Calathea Orbifolia",
    scientificName: "Goeppertia orbifolia",
    family: "Marantaceae",
    image: IMG.plants.calathea,
    description: "Lá tròn lớn với sọc bạc tinh tế, lá khép lại vào ban đêm.",
    origin: "Rừng mưa Bolivia.",
    environment: "Trong nhà, nơi ẩm, tránh gió và điều hòa trực tiếp.",
    light: "Ánh sáng gián tiếp nhẹ.",
    water: "Giữ ẩm đều, 3–5 ngày/lần, dùng nước lọc.",
    soil: "Đất giàu hữu cơ, trộn xơ dừa.",
    temperature: "18–27°C.",
    humidity: "Trên 60%, rất cần độ ẩm cao.",
    toxicity: null,
    careTips: ["Mép lá cháy nâu thường do độ ẩm thấp hoặc nước có clo.", "Đặt khay sỏi nước dưới chậu để tăng ẩm."],
    idealLight: ["indirect"],
    idealEnvironments: ["indoor"],
    wateringDays: 4,
    fertilizingDays: 30,
    inspectionDays: 7,
  },
  {
    id: "zamioculcas-zamiifolia",
    commonName: "Kim tiền",
    commonNameEn: "ZZ Plant",
    scientificName: "Zamioculcas zamiifolia",
    family: "Araceae",
    image: IMG.plants.zz,
    description: "Cây lá bóng, củ dự trữ nước, cực kỳ dễ chăm và mang ý nghĩa tài lộc.",
    origin: "Đông Phi (Kenya, Tanzania).",
    environment: "Trong nhà, văn phòng, góc ít sáng.",
    light: "Ánh sáng yếu đến gián tiếp.",
    water: "Tưới 2–3 tuần/lần khi đất khô hoàn toàn.",
    soil: "Đất thoát nước nhanh, trộn đá perlite.",
    temperature: "16–30°C.",
    humidity: "40–50%.",
    toxicity: "Độc nếu ăn phải.",
    careTips: ["Lá vàng thân mềm là dấu hiệu úng nước.", "Không cần bón phân nhiều."],
    idealLight: ["low", "indirect"],
    idealEnvironments: ["indoor"],
    wateringDays: 16,
    fertilizingDays: 60,
    inspectionDays: 21,
  },
  {
    id: "aloe-vera",
    commonName: "Nha đam",
    commonNameEn: "Aloe Vera",
    scientificName: "Aloe barbadensis miller",
    family: "Asphodelaceae",
    image: IMG.plants.aloe,
    description: "Cây mọng nước có gel trong lá, ưa nắng và chịu hạn tốt.",
    origin: "Bán đảo Ả Rập.",
    environment: "Ban công, sân thượng, cửa sổ hướng nắng.",
    light: "Ánh sáng mạnh đến nắng trực tiếp buổi sáng.",
    water: "10–14 ngày/lần, tránh đọng nước ở nách lá.",
    soil: "Đất cát pha, đất cho sen đá.",
    temperature: "13–35°C.",
    humidity: "Thấp, không kén.",
    toxicity: "Nhựa vàng gần vỏ có thể gây tiêu chảy cho thú cưng.",
    careTips: ["Lá mỏng và cong là dấu hiệu thiếu nước.", "Thay chậu khi cây con mọc dày."],
    idealLight: ["bright", "direct"],
    idealEnvironments: ["balcony", "rooftop", "yard"],
    wateringDays: 12,
    fertilizingDays: 60,
    inspectionDays: 21,
  },
  {
    id: "phalaenopsis",
    commonName: "Lan hồ điệp",
    commonNameEn: "Moth Orchid",
    scientificName: "Phalaenopsis amabilis",
    family: "Orchidaceae",
    image: IMG.plants.orchid,
    description: "Loài lan sang trọng với cành hoa cong mềm mại, hoa bền 2–3 tháng.",
    origin: "Đông Nam Á và Úc.",
    environment: "Trong nhà, bàn làm việc, bậu cửa sổ hướng đông.",
    light: "Ánh sáng gián tiếp sáng, tránh nắng trưa.",
    water: "Ngâm giá thể 10 phút mỗi 7 ngày, để ráo hoàn toàn.",
    soil: "Vỏ thông, dớn, than củi — không dùng đất.",
    temperature: "18–30°C.",
    humidity: "50–70%.",
    toxicity: null,
    careTips: ["Rễ xanh bạc là khỏe; rễ nâu mềm cần cắt bỏ.", "Chênh lệch nhiệt độ ngày đêm giúp kích hoa."],
    idealLight: ["indirect"],
    idealEnvironments: ["indoor"],
    wateringDays: 7,
    fertilizingDays: 14,
    inspectionDays: 10,
  },
  {
    id: "ficus-elastica",
    commonName: "Đa búp đỏ",
    commonNameEn: "Rubber Plant",
    scientificName: "Ficus elastica",
    family: "Moraceae",
    image: IMG.plants.rubber,
    description: "Lá dày bóng màu xanh đậm ánh đỏ, búp non đỏ tía rất đẹp.",
    origin: "Đông Bắc Ấn Độ và Indonesia.",
    environment: "Trong nhà, sảnh, phòng khách.",
    light: "Ánh sáng gián tiếp sáng.",
    water: "Tưới khi đất khô 2/3, khoảng 7–10 ngày/lần.",
    soil: "Đất tơi xốp, giàu dinh dưỡng.",
    temperature: "15–30°C.",
    humidity: "40–60%.",
    toxicity: "Nhựa trắng gây kích ứng da.",
    careTips: ["Lau lá bằng khăn ẩm để giữ độ bóng.", "Bấm ngọn để cây phân cành."],
    idealLight: ["indirect", "bright"],
    idealEnvironments: ["indoor"],
    wateringDays: 9,
    fertilizingDays: 30,
    inspectionDays: 14,
  },
  {
    id: "bougainvillea",
    commonName: "Hoa giấy",
    commonNameEn: "Bougainvillea",
    scientificName: "Bougainvillea spectabilis",
    family: "Nyctaginaceae",
    image: IMG.plants.bougainvillea,
    description: "Cây bụi leo ra hoa rực rỡ quanh năm, ưa nắng, rất hợp ban công và sân thượng.",
    origin: "Brazil, Nam Mỹ.",
    environment: "Ban công, sân thượng, hàng rào.",
    light: "Nắng trực tiếp ít nhất 6 giờ/ngày.",
    water: "Tưới 2–3 ngày/lần mùa nắng; hãm nước nhẹ để kích hoa.",
    soil: "Đất thịt pha cát, thoát nước tốt.",
    temperature: "20–38°C.",
    humidity: "Không kén.",
    toxicity: "Gai nhọn; nhựa có thể gây kích ứng nhẹ.",
    careTips: ["Cắt tỉa sau mỗi đợt hoa.", "Bón phân giàu kali để hoa lên màu đậm."],
    idealLight: ["direct", "bright"],
    idealEnvironments: ["balcony", "rooftop", "yard"],
    wateringDays: 3,
    fertilizingDays: 21,
    inspectionDays: 10,
  },
];

export function slugifySpecies(input: string): string {
  return input
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

let runtimePlantsInfo: PlantInfo[] | null = null;

export function setRuntimePlantsInfo(list: PlantInfo[]) {
  if (Array.isArray(list) && list.length > 0) {
    runtimePlantsInfo = list;
  }
}

export function getAllPlantsInfo(): PlantInfo[] {
  return runtimePlantsInfo && runtimePlantsInfo.length > 0 ? runtimePlantsInfo : PLANTS_INFO;
}

export const findPlantInfo = (idOrName: string): PlantInfo | undefined => {
  const list = getAllPlantsInfo();
  const q = idOrName.trim().toLowerCase();
  if (!q) return undefined;
  const qSlug = slugifySpecies(q);
  return (
    list.find(
      (p) =>
        p.id.toLowerCase() === q ||
        slugifySpecies(p.id) === qSlug ||
        p.scientificName.toLowerCase() === q ||
        slugifySpecies(p.scientificName) === qSlug ||
        p.commonName.toLowerCase() === q ||
        p.commonNameEn.toLowerCase() === q,
    ) ??
    PLANTS_INFO.find(
      (p) =>
        p.id.toLowerCase() === q ||
        slugifySpecies(p.scientificName) === qSlug ||
        p.scientificName.toLowerCase() === q,
    )
  );
};

export function findPlantInfoOrFallback(idOrName: string, nameVi?: string, image?: string): PlantInfo {
  const found = findPlantInfo(idOrName) ?? (nameVi ? findPlantInfo(nameVi) : undefined);
  if (found) return found;
  const display = nameVi?.trim() || idOrName || "Cây cảnh";
  const sci = idOrName.includes("-") ? idOrName.replace(/-/g, " ") : idOrName;
  return {
    id: slugifySpecies(idOrName || display) || "plant",
    commonName: display,
    commonNameEn: sci,
    scientificName: sci,
    family: "Thực vật cảnh",
    image: image || IMG.plants.monstera,
    description: "Cây cảnh trong khu vườn Floria.",
    origin: "Nhiệt đới",
    environment: "Trong nhà hoặc ban công thoáng mát",
    light: "Ánh sáng gián tiếp",
    water: "Tưới khi đất mặt khô",
    soil: "Giá thể tơi xốp, thoát nước tốt",
    temperature: "18–30°C",
    humidity: "50–70%",
    toxicity: null,
    careTips: ["Kiểm tra độ ẩm đất trước khi tưới.", "Lau lá định kỳ để cây quang hợp tốt."],
    idealLight: ["indirect", "bright"],
    idealEnvironments: ["indoor", "balcony"],
    wateringDays: 5,
    fertilizingDays: 20,
    inspectionDays: 7,
  };
}
