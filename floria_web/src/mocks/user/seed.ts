import type {
  Address, CareSchedule, CareType, ChatMessage, ChatSession, DiaryNote, Order, ProductReview,
  ReminderSettings, ScanHistoryItem, User, UserGarden, UserPlant,
} from "@/types/user";
import { IMG } from "./images";
import { findPlantInfo } from "./plants-info";
import { SEED_REVIEWS } from "./shop";

export type StoredUser = User & { password: string };

export interface MockDbShape {
  version: number;
  users: StoredUser[];
  gardens: UserGarden[];
  plants: UserPlant[];
  schedules: CareSchedule[];
  diary: DiaryNote[];
  scans: ScanHistoryItem[];
  chatSessions: ChatSession[];
  chatMessages: ChatMessage[];
  reviews: ProductReview[];
  orders: Order[];
  addresses: Address[];
  reminders: ReminderSettings[];
}

export const DB_VERSION = 1;
export const DEMO_USER_ID = "u-demo";
export const DEMO_EMAIL = "demo@floria.vn";
export const DEMO_PASSWORD = "floria123";

/** Build the demo dataset relative to `now` so care statuses stay meaningful. Call lazily (never at module scope). */
export function buildSeed(now = Date.now()): MockDbShape {
  const day = 86400000;
  const ago = (d: number, h = 8) => {
    const x = new Date(now - d * day);
    x.setHours(h, 0, 0, 0);
    return x.toISOString();
  };
  const U = DEMO_USER_ID;

  const users: StoredUser[] = [
    {
      uid: U, displayName: "Minh Anh", email: DEMO_EMAIL, password: DEMO_PASSWORD, avatarId: "monstera", avatarUrl: null,
      phone: "0912 345 678", bio: "Người yêu cây ở Hà Nội, đang nuôi một khu rừng nhỏ trong căn hộ.",
      joinedAt: ago(164), provider: "password", cartItems: [],
    },
  ];

  const gardens: UserGarden[] = [
    { id: "g-living", userId: U, name: "Căn hộ Tây Hồ", coverImage: IMG.gardens.livingRoom, environment: "indoor", light: "indirect", description: "Phòng khách hướng Đông, nắng sớm xuyên qua rèm voan.", createdAt: ago(160) },
    { id: "g-balcony", userId: U, name: "Ban công nắng", coverImage: IMG.gardens.balcony, environment: "balcony", light: "bright", description: "Ban công tầng 12 hướng Nam, nắng chiều mạnh.", createdAt: ago(120) },
    { id: "g-rooftop", userId: U, name: "Sân thượng nhà mẹ", coverImage: IMG.gardens.rooftop, environment: "rooftop", light: "direct", description: "Sân thượng nhà phố Đống Đa, nắng cả ngày.", createdAt: ago(40) },
  ];

  const p = (id: string, gardenId: string, speciesId: string, nickname: string, location: string, addedDays: number, extra: Partial<UserPlant> = {}): UserPlant => ({
    id, userId: U, gardenId, speciesId, nickname, location, image: findPlantInfo(speciesId)!.image,
    healthStatus: "healthy", activeDiseaseId: null, addedAt: ago(addedDays), ...extra,
  });

  const plants: UserPlant[] = [
    p("pl-moni", "g-living", "monstera-deliciosa", "Moni", "Phòng khách", 150),
    p("pl-fig", "g-living", "ficus-lyrata", "Bàng Cao", "Cửa sổ", 140),
    p("pl-vang", "g-living", "epipremnum-aureum", "Vàng Óng", "Kệ sách", 130),
    p("pl-lily", "g-living", "spathiphyllum-wallisii", "Bạch Ý", "Phòng ngủ", 90),
    p("pl-cala", "g-living", "calathea-orbifolia", "Sọc Bạc", "Phòng ngủ", 60, { healthStatus: "sick", activeDiseaseId: "leaf-spot" }),
    p("pl-zz", "g-living", "zamioculcas-zamiifolia", "Tài Lộc", "Phòng làm việc", 110),
    p("pl-orchid", "g-living", "phalaenopsis", "Hồ Điệp", "Phòng làm việc", 35),
    p("pl-rubber", "g-living", "ficus-elastica", "Đa Đỏ", "Phòng khách", 75),
    p("pl-aloe", "g-balcony", "aloe-vera", "Nha Đam", "Bậu cửa", 100),
    p("pl-bougain", "g-balcony", "bougainvillea", "Giấy Hồng", "Lan can", 95, { healthStatus: "recovering" }),
    p("pl-snake", "g-balcony", "sansevieria-trifasciata", "Lưỡi Hổ", "Góc ban công", 85),
    p("pl-bougain2", "g-rooftop", "bougainvillea", "Giấy Tím", "Giàn leo", 38),
  ];

  // lastDone offsets (days ago) per plant for [watering, fertilizing, inspection]
  const offsets: Record<string, [number, number, number]> = {
    "pl-moni": [3, 31, 6],
    "pl-fig": [8, 12, 4],
    "pl-vang": [7, 10, 3],
    "pl-lily": [5, 9, 2],
    "pl-cala": [2, 15, 8],
    "pl-zz": [9, 20, 5],
    "pl-orchid": [4, 15, 3],
    "pl-rubber": [4, 10, 15],
    "pl-aloe": [6, 30, 7],
    "pl-bougain": [1, 8, 4],
    "pl-snake": [10, 25, 9],
    "pl-bougain2": [2, 22, 3],
  };
  const times: Record<CareType, string> = { watering: "07:00", fertilizing: "08:30", inspection: "18:00" };
  const schedules: CareSchedule[] = [];
  for (const plant of plants) {
    const info = findPlantInfo(plant.speciesId)!;
    const intervals: Record<CareType, number> = { watering: info.wateringDays, fertilizing: info.fertilizingDays, inspection: info.inspectionDays };
    (["watering", "fertilizing", "inspection"] as CareType[]).forEach((type, i) => {
      const lastDays = offsets[plant.id][i];
      const [hh] = times[type].split(":").map(Number);
      const last = ago(lastDays, hh);
      const next = new Date(new Date(last).getTime() + intervals[type] * day).toISOString();
      const history = [0, 1, 2].map((k) => ({ id: `log-${plant.id}-${type}-${k}`, doneAt: ago(lastDays + k * intervals[type], hh) }));
      schedules.push({ id: `cs-${plant.id}-${type}`, plantId: plant.id, type, intervalDays: intervals[type], preferredTime: times[type], lastDoneAt: last, nextDueAt: next, enabled: true, history });
    });
  }

  const scans: ScanHistoryItem[] = [
    { id: "scan-1", userId: U, type: "identify", image: IMG.plants.monstera, createdAt: ago(150, 10), isValidPlant: true, predictions: [{ speciesId: "monstera-deliciosa", confidence: 0.94 }, { speciesId: "epipremnum-aureum", confidence: 0.04 }, { speciesId: "ficus-elastica", confidence: 0.01 }] },
    { id: "scan-2", userId: U, type: "identify", image: IMG.plants.orchid, createdAt: ago(35, 15), isValidPlant: true, predictions: [{ speciesId: "phalaenopsis", confidence: 0.88 }, { speciesId: "spathiphyllum-wallisii", confidence: 0.07 }, { speciesId: "calathea-orbifolia", confidence: 0.02 }] },
    { id: "scan-3", userId: U, type: "diagnose", image: IMG.leafSpot, createdAt: ago(3, 19), isValidPlant: true, plantId: "pl-cala", diseaseId: "leaf-spot", confidence: 0.87, appliedToRecord: true },
    { id: "scan-4", userId: U, type: "diagnose", image: IMG.plants.bougainvillea, createdAt: ago(12, 9), isValidPlant: true, plantId: "pl-bougain", diseaseId: "powdery-mildew", confidence: 0.72, appliedToRecord: true },
    { id: "scan-5", userId: U, type: "identify", image: IMG.plants.aloe, createdAt: ago(100, 11), isValidPlant: true, predictions: [{ speciesId: "aloe-vera", confidence: 0.91 }, { speciesId: "sansevieria-trifasciata", confidence: 0.05 }, { speciesId: "zamioculcas-zamiifolia", confidence: 0.02 }] },
  ];

  const diary: DiaryNote[] = [
    { id: "dn-1", plantId: "pl-moni", userId: U, category: "growth", content: "Moni ra lá thứ 9, lần đầu tiên có 3 lỗ xẻ thùy! Đã cắm thêm cọc rêu.", images: [IMG.plants.monstera], createdAt: ago(12, 9), updatedAt: ago(12, 9) },
    { id: "dn-2", plantId: "pl-moni", userId: U, category: "care", content: "Thay chậu sang giá thể Aroid Mix, rễ khỏe trắng, không thấy thối.", images: [], createdAt: ago(45, 16), updatedAt: ago(45, 16) },
    { id: "dn-3", plantId: "pl-cala", userId: U, category: "health", content: "Chẩn đoán: Bệnh đốm lá (87%). Đã cắt 2 lá bị nặng, chuyển chậu ra xa máy lạnh.", images: [IMG.leafSpot], diagnosisId: "scan-3", createdAt: ago(3, 19), updatedAt: ago(3, 19) },
    { id: "dn-4", plantId: "pl-bougain", userId: U, category: "health", content: "Chẩn đoán: Bệnh phấn trắng (72%). Lau lá, phun dầu neem lần 1.", images: [IMG.plants.bougainvillea], diagnosisId: "scan-4", createdAt: ago(12, 9), updatedAt: ago(12, 9) },
    { id: "dn-5", plantId: "pl-bougain", userId: U, category: "health", content: "Phấn trắng giảm rõ sau lần phun thứ 2, đang theo dõi thêm.", images: [], createdAt: ago(5, 18), updatedAt: ago(5, 18) },
  ];

  const chatSessions: ChatSession[] = [
    { id: "cs-1", userId: U, title: "Calathea bị đốm nâu", createdAt: ago(3, 20), updatedAt: ago(3, 20) },
    { id: "cs-2", userId: U, title: "Lịch tưới cho ban công", createdAt: ago(9, 7), updatedAt: ago(9, 7) },
  ];
  const chatMessages: ChatMessage[] = [
    { id: "m-1", sessionId: "cs-1", role: "user", content: "Cây đuôi công của mình xuất hiện các đốm nâu có viền vàng, phải làm sao?", images: [IMG.leafSpot], createdAt: ago(3, 20), status: "sent" },
    { id: "m-2", sessionId: "cs-1", role: "assistant", content: "Các đốm nâu có quầng vàng như trong ảnh là dấu hiệu điển hình của **bệnh đốm lá** do nấm. Bạn nên:\n\n1. Cắt bỏ những lá bị nặng bằng kéo đã khử trùng.\n2. Tưới vào gốc, tránh làm ướt lá vào buổi chiều.\n3. Đặt cây nơi thông thoáng, tránh gió điều hòa thổi trực tiếp.\n\n[RECOMMEND_PRODUCT]{\"productId\":\"prd-fungicide\",\"reason\":\"Chế phẩm vi sinh hỗ trợ kiểm soát nấm đốm lá\"}[/RECOMMEND_PRODUCT]\n\nTrong thời gian điều trị, bạn có thể tăng tần suất kiểm tra lá:\n\n[CARE_SCHEDULE]{\"plantName\":\"Sọc Bạc\",\"speciesId\":\"calathea-orbifolia\",\"careType\":\"inspection\",\"intervalDays\":3,\"preferredTime\":\"18:00\",\"reason\":\"Theo dõi sát tốc độ lan của đốm lá trong 2 tuần điều trị\"}[/CARE_SCHEDULE]", images: [], createdAt: ago(3, 20), status: "sent" },
    { id: "m-3", sessionId: "cs-2", role: "user", content: "Ban công hướng Nam nắng gắt, hoa giấy nên tưới mấy lần một tuần?", images: [], createdAt: ago(9, 7), status: "sent" },
    { id: "m-4", sessionId: "cs-2", role: "assistant", content: "Với ban công hướng Nam nắng mạnh, hoa giấy thoát hơi nước rất nhanh. Bạn nên tưới **2–3 ngày/lần** vào sáng sớm và kiểm tra đất mặt trước khi tưới.\n\n[CARE_SCHEDULE]{\"plantName\":\"Giấy Hồng\",\"speciesId\":\"bougainvillea\",\"careType\":\"watering\",\"intervalDays\":2,\"preferredTime\":\"06:30\",\"reason\":\"Nắng hướng Nam làm đất khô nhanh vào mùa nóng\"}[/CARE_SCHEDULE]", images: [], createdAt: ago(9, 7), status: "sent" },
  ];

  const addresses: Address[] = [
    { id: "addr-1", userId: U, recipientName: "Minh Anh", phone: "0912345678", provinceCode: "01", provinceName: "Hà Nội", wardCode: "00004", wardName: "Phường Tây Hồ", street: "18 Quảng An", latitude: 21.0636, longitude: 105.8231, isDefault: true, label: "Nhà riêng" },
    { id: "addr-2", userId: U, recipientName: "Nguyễn Minh Anh", phone: "0987654321", provinceCode: "01", provinceName: "Hà Nội", wardCode: "00211", wardName: "Phường Đống Đa", street: "102 Thái Hà", latitude: null, longitude: null, isDefault: false, label: "Nhà mẹ" },
  ];
  const snap = (a: Address) => {
    const { id: _id, userId: _u, isDefault: _d, ...rest } = a;
    return rest;
  };

  const orders: Order[] = [
    { id: "ord-1", code: "FL-2611-0412", userId: U, items: [{ productId: "prd-pots", name: "Bộ 3 chậu gốm men mờ Terra", image: IMG.products.pots, unitPrice: 459000, quantity: 1 }, { productId: "prd-soil", name: "Giá thể trộn sẵn cho cây ráy (Aroid Mix)", image: IMG.products.soil, unitPrice: 89000, quantity: 2 }], addressSnapshot: snap(addresses[0]), subtotal: 637000, shippingFee: 30000, discount: 50000, total: 617000, voucherCode: "XANH50K", paymentMethod: "cod", paymentStatus: "unpaid", status: "pending", createdAt: ago(0, 9), updatedAt: ago(0, 9) },
    { id: "ord-2", code: "FL-2611-0388", userId: U, items: [{ productId: "prd-fungicide", name: "Chế phẩm sinh học trừ nấm BioShield", image: IMG.products.fungicide, unitPrice: 149000, quantity: 1 }], addressSnapshot: snap(addresses[0]), subtotal: 149000, shippingFee: 30000, discount: 0, total: 179000, voucherCode: null, paymentMethod: "cod", paymentStatus: "unpaid", status: "shipping", createdAt: ago(2, 14), updatedAt: ago(1, 10) },
    { id: "ord-3", code: "FL-2610-0251", userId: U, items: [{ productId: "prd-neem", name: "Dầu neem nguyên chất ép lạnh 100ml", image: IMG.products.neem, unitPrice: 135000, quantity: 2 }, { productId: "prd-pruning", name: "Kéo cắt tỉa cán gỗ óc chó", image: IMG.products.pruning, unitPrice: 285000, quantity: 1 }], addressSnapshot: snap(addresses[1]), subtotal: 555000, shippingFee: 30000, discount: 30000, total: 555000, voucherCode: "FREESHIP", paymentMethod: "zalopay", paymentStatus: "paid", status: "delivered", createdAt: ago(21, 20), updatedAt: ago(17, 11) },
    { id: "ord-4", code: "FL-2610-0197", userId: U, items: [{ productId: "prd-fertilizer", name: "Phân hữu cơ trùn quế Floria Organic", image: IMG.products.fertilizer, unitPrice: 119000, quantity: 1, reviewed: true }], addressSnapshot: snap(addresses[0]), subtotal: 119000, shippingFee: 30000, discount: 0, total: 149000, voucherCode: null, paymentMethod: "cod", paymentStatus: "paid", status: "delivered", createdAt: ago(32, 8), updatedAt: ago(29, 16) },
    { id: "ord-5", code: "FL-2610-0150", userId: U, items: [{ productId: "prd-moisture", name: "Máy đo độ ẩm đất 3 trong 1", image: IMG.products.moisture, unitPrice: 79000, quantity: 1 }], addressSnapshot: snap(addresses[0]), subtotal: 79000, shippingFee: 30000, discount: 0, total: 109000, voucherCode: null, paymentMethod: "cod", paymentStatus: "unpaid", status: "cancelled", createdAt: ago(38, 12), updatedAt: ago(38, 13) },
    { id: "ord-6", code: "FL-2611-0399", userId: U, items: [{ productId: "prd-watering-can", name: "Bình tưới vòi dài Sage 1.2L", image: IMG.products.wateringCan, unitPrice: 210000, quantity: 1 }], addressSnapshot: snap(addresses[0]), subtotal: 210000, shippingFee: 30000, discount: 0, total: 240000, voucherCode: null, paymentMethod: "cod", paymentStatus: "unpaid", status: "processing", createdAt: ago(1, 11), updatedAt: ago(0, 8) },
  ];

  const reviews: ProductReview[] = [
    ...SEED_REVIEWS,
    { id: "rv-demo-1", productId: "prd-fertilizer", orderId: "ord-4", userId: U, userName: "Minh Anh", userAvatar: null, rating: 5, content: "Dùng cho Moni và Bàng Cao, lá mới xanh đậm hơn hẳn.", images: [], createdAt: ago(27, 10) },
  ];

  const reminders: ReminderSettings[] = [
    { userId: U, pushEnabled: true, watering: true, fertilizing: true, inspection: false, dndEnabled: true, dndStart: "22:00", dndEnd: "06:30" },
  ];

  return { version: DB_VERSION, users, gardens, plants, schedules, diary, scans, chatSessions, chatMessages, reviews, orders, addresses, reminders };
}
