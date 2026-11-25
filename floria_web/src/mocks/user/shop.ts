import type { ProductReview, ShopProduct, Voucher } from "@/types/user";
import { IMG } from "./images";

const P = IMG.products;
// Fixed catalogue base date keeps SSR and client output identical.
const BASE = Date.parse("2026-11-15T09:00:00Z");
const daysAgo = (n: number) => new Date(BASE - n * 86400000).toISOString();

// ShopProducts
export const SHOP_PRODUCTS: ShopProduct[] = [
  {
    id: "prd-fertilizer", name: "Phân hữu cơ trùn quế Floria Organic", slug: "phan-huu-co-trun-que", category: "fertilizer",
    images: [P.fertilizer, P.soil], price: 145000, salePrice: 119000, rating: 4.8, reviewCount: 3, sold: 1284, stock: 86,
    shortDescription: "Phân trùn quế viên nén, giải phóng chậm 6–8 tuần.",
    description: "Phân hữu cơ từ trùn quế được ủ hoai và nén viên, bổ sung dinh dưỡng đa lượng – vi lượng và vi sinh vật có lợi giúp rễ khỏe, lá xanh bền.",
    ingredients: "Phân trùn quế 85%, chất hữu cơ 30%, N-P-K 2-1-1, vi sinh vật cố định đạm.",
    usage: ["Rắc 1 thìa (15g) quanh mép chậu 20cm.", "Bón nhắc lại sau 6–8 tuần.", "Tưới nước nhẹ sau khi bón."],
    benefits: ["bón lá", "kích rễ", "tăng trưởng"], tags: ["featured", "bestseller"], createdAt: daysAgo(120),
  },
  {
    id: "prd-soil", name: "Giá thể trộn sẵn cho cây ráy (Aroid Mix)", slug: "gia-the-aroid-mix", category: "soil",
    images: [P.soil], price: 89000, salePrice: null, rating: 4.7, reviewCount: 2, sold: 962, stock: 140,
    shortDescription: "Vỏ thông, perlite, xơ dừa và than hoạt tính — tơi xốp, thoát nước tốt.",
    description: "Công thức giá thể cho Monstera, Trầu bà, Philodendron. Hạn chế úng rễ và nấm bệnh vùng gốc.",
    ingredients: "Vỏ thông 35%, xơ dừa 30%, perlite 20%, than hoạt tính 10%, phân trùn 5%.",
    usage: ["Thay chậu vào đầu mùa sinh trưởng.", "Lót lớp sỏi dưới đáy chậu.", "Tưới đẫm sau khi trồng."],
    benefits: ["thoát nước", "chống thối rễ", "thay chậu"], tags: ["bestseller"], createdAt: daysAgo(200),
  },
  {
    id: "prd-pots", name: "Bộ 3 chậu gốm men mờ Terra", slug: "bo-3-chau-gom-terra", category: "pots",
    images: [P.pots], price: 520000, salePrice: 459000, rating: 4.9, reviewCount: 2, sold: 341, stock: 24,
    shortDescription: "Gốm nung 1200°C, có lỗ thoát nước, ba tông kem – xanh sage – đất nung.",
    description: "Bộ chậu gốm thủ công tráng men mờ, đường kính 12 – 16 – 20cm, kèm đĩa lót tách rời.",
    ingredients: "Gốm sứ Bát Tràng, men mờ không chì.",
    usage: ["Phù hợp cây để bàn và cây sàn cỡ nhỏ.", "Lau bằng khăn ẩm, tránh chất tẩy mạnh."],
    benefits: ["trang trí", "thoát nước"], tags: ["featured", "new"], createdAt: daysAgo(12),
  },
  {
    id: "prd-neem", name: "Dầu neem nguyên chất ép lạnh 100ml", slug: "dau-neem-ep-lanh", category: "treatment",
    images: [P.neem], price: 135000, salePrice: null, rating: 4.6, reviewCount: 3, sold: 708, stock: 52,
    shortDescription: "Phòng ngừa rệp, nhện đỏ, phấn trắng — nguồn gốc thực vật.",
    description: "Dầu neem ép lạnh giữ nguyên hoạt chất Azadirachtin, giúp xua đuổi côn trùng chích hút và hạn chế nấm bề mặt lá.",
    ingredients: "Dầu hạt neem 100% (Azadirachta indica).",
    usage: ["Pha 5ml dầu + 2ml xà phòng sinh học với 1 lít nước.", "Phun đều 2 mặt lá lúc chiều mát, 5–7 ngày/lần.", "Thử trên một lá trước khi phun toàn cây."],
    benefits: ["sâu bệnh", "phấn trắng", "rệp", "nhện đỏ"], tags: ["bestseller"], createdAt: daysAgo(160),
  },
  {
    id: "prd-fungicide", name: "Chế phẩm sinh học trừ nấm BioShield", slug: "bioshield-tru-nam", category: "treatment",
    images: [P.fungicide], price: 165000, salePrice: 149000, rating: 4.5, reviewCount: 2, sold: 455, stock: 0,
    shortDescription: "Chứa Bacillus subtilis hỗ trợ kiểm soát đốm lá, gỉ sắt, cháy lá.",
    description: "Chế phẩm vi sinh dạng xịt sẵn, an toàn cho cây trồng trong nhà. Hỗ trợ ức chế nấm bệnh trên lá khi dùng kết hợp với biện pháp canh tác đúng.",
    ingredients: "Bacillus subtilis 10⁸ CFU/ml, chiết xuất tỏi, dung môi nước.",
    usage: ["Lắc đều, xịt cách lá 20–30cm.", "Dùng 7 ngày/lần trong 3 tuần.", "Không xịt khi nắng gắt."],
    benefits: ["đốm lá", "gỉ sắt", "cháy lá", "nấm bệnh"], tags: ["featured"], createdAt: daysAgo(90),
  },
  {
    id: "prd-pruning", name: "Kéo cắt tỉa cán gỗ óc chó", slug: "keo-cat-tia-can-go", category: "tools",
    images: [P.pruning], price: 285000, salePrice: null, rating: 4.9, reviewCount: 1, sold: 219, stock: 37,
    shortDescription: "Lưỡi thép SK5 sắc bén, cắt gọn không dập cành.",
    description: "Kéo cắt tỉa chuyên dụng với cán gỗ óc chó tự nhiên, lò xo trợ lực, khóa an toàn.",
    ingredients: "Thép SK5, gỗ óc chó, đồng thau.",
    usage: ["Khử trùng lưỡi bằng cồn trước và sau khi cắt cây bệnh.", "Lau khô và tra dầu sau khi dùng."],
    benefits: ["cắt tỉa", "dụng cụ"], tags: ["new"], createdAt: daysAgo(8),
  },
  {
    id: "prd-mister", name: "Bình phun sương đồng thau cổ điển", slug: "binh-phun-suong-dong", category: "tools",
    images: [P.pruning], price: 320000, salePrice: 279000, rating: 4.7, reviewCount: 1, sold: 188, stock: 15,
    shortDescription: "Tia sương mịn, tăng độ ẩm cho Calathea, dương xỉ, lan.",
    description: "Bình phun sương bằng đồng thau dung tích 300ml, thiết kế cổ điển, phù hợp làm phụ kiện trang trí.",
    ingredients: "Đồng thau mạ chống oxy hóa.",
    usage: ["Phun sương buổi sáng.", "Dùng nước lọc để tránh vệt trắng trên lá."],
    benefits: ["tăng ẩm", "phun sương"], tags: [], createdAt: daysAgo(40),
  },
  {
    id: "prd-watering-can", name: "Bình tưới vòi dài Sage 1.2L", slug: "binh-tuoi-sage", category: "tools",
    images: [P.wateringCan], price: 210000, salePrice: null, rating: 4.6, reviewCount: 1, sold: 402, stock: 64,
    shortDescription: "Vòi dài kiểm soát dòng nước, tưới đúng gốc.",
    description: "Bình tưới thép sơn tĩnh điện màu xanh sage, vòi dài 30cm giúp tưới gọn vào gốc mà không làm ướt lá.",
    ingredients: "Thép mạ kẽm, sơn tĩnh điện.",
    usage: ["Tưới sát gốc, chậm rãi đến khi nước chảy ra lỗ đáy."],
    benefits: ["tưới nước", "dụng cụ"], tags: ["featured"], createdAt: daysAgo(70),
  },
  {
    id: "prd-moisture", name: "Máy đo độ ẩm đất 3 trong 1", slug: "may-do-do-am-dat", category: "tools",
    images: [P.moisture], price: 95000, salePrice: 79000, rating: 4.4, reviewCount: 1, sold: 1530, stock: 200,
    shortDescription: "Đo độ ẩm, ánh sáng và pH — không cần pin.",
    description: "Biết chính xác khi nào cần tưới, tránh úng rễ – nguyên nhân phổ biến nhất khiến cây trong nhà chết.",
    ingredients: "Que đo hợp kim, đồng hồ cơ.",
    usage: ["Cắm que sâu 2/3 chậu.", "Đọc kết quả sau 60 giây.", "Lau sạch que sau khi đo."],
    benefits: ["tưới nước", "chống thối rễ", "đo độ ẩm"], tags: ["bestseller", "new"], createdAt: daysAgo(5),
  },
  {
    id: "prd-plant-monstera", name: "Cây Trầu bà Nam Mỹ chậu 20cm", slug: "cay-monstera-20cm", category: "plants",
    images: [IMG.plants.monstera], price: 390000, salePrice: null, rating: 4.8, reviewCount: 1, sold: 276, stock: 9,
    shortDescription: "Cây cao 60–70cm, 5–6 lá, đã thuần khí hậu trong nhà.",
    description: "Monstera deliciosa trồng sẵn trong giá thể Aroid Mix, phù hợp phòng khách sáng.",
    ingredients: "Cây Monstera deliciosa, chậu nhựa ươm 20cm.",
    usage: ["Đặt nơi sáng gián tiếp.", "Tưới 1 lần/tuần."],
    benefits: ["cây nội thất", "lọc không khí"], tags: ["featured"], createdAt: daysAgo(30),
  },
  {
    id: "prd-plant-snake", name: "Cây Lưỡi hổ viền vàng chậu gốm", slug: "cay-luoi-ho-chau-gom", category: "plants",
    images: [IMG.plants.snake], price: 260000, salePrice: 229000, rating: 4.9, reviewCount: 1, sold: 512, stock: 22,
    shortDescription: "Cây bền, chịu bóng, chậu gốm trắng kèm đĩa.",
    description: "Sansevieria viền vàng cao 45cm trồng trong chậu gốm sọc trắng, quà tặng ý nghĩa cho văn phòng.",
    ingredients: "Cây Dracaena trifasciata, chậu gốm 15cm.",
    usage: ["Tưới 2–3 tuần/lần."],
    benefits: ["cây nội thất", "lọc không khí", "chịu bóng"], tags: ["bestseller"], createdAt: daysAgo(55),
  },
  {
    id: "prd-plant-orchid", name: "Lan hồ điệp trắng 1 cành", slug: "lan-ho-diep-trang", category: "plants",
    images: [IMG.plants.orchid], price: 450000, salePrice: null, rating: 4.7, reviewCount: 0, sold: 98, stock: 6,
    shortDescription: "Cành hoa 8–10 bông, hoa bền 2–3 tháng.",
    description: "Lan hồ điệp trắng trồng trong chậu sứ, phù hợp trang trí bàn làm việc hoặc làm quà.",
    ingredients: "Phalaenopsis amabilis, giá thể vỏ thông.",
    usage: ["Ngâm giá thể mỗi tuần 10 phút."],
    benefits: ["cây có hoa", "quà tặng"], tags: ["new"], createdAt: daysAgo(3),
  },
];

let runtimeProducts: ShopProduct[] | null = null;

export function setRuntimeProducts(list: ShopProduct[]) {
  if (Array.isArray(list) && list.length > 0) {
    runtimeProducts = list;
  }
}

export function getAllRuntimeProducts(): ShopProduct[] {
  return runtimeProducts && runtimeProducts.length > 0 ? runtimeProducts : SHOP_PRODUCTS;
}

export const findProduct = (id: string) => {
  const q = id.trim();
  const list = getAllRuntimeProducts();
  return list.find((p) => p.id === q || p.slug === q) ?? SHOP_PRODUCTS.find((p) => p.id === q || p.slug === q);
};

// ProductReviews (seed — reviewer accounts other than the demo user)
export const SEED_REVIEWS: ProductReview[] = [
  { id: "rv1", productId: "prd-fertilizer", orderId: null, userId: "u-lan", userName: "Ngọc Lan", userAvatar: null, rating: 5, content: "Bón 3 tuần thấy Monstera ra lá mới to hẳn, mùi không nặng như phân chuồng.", images: [IMG.plants.monstera], createdAt: daysAgo(14) },
  { id: "rv2", productId: "prd-fertilizer", orderId: null, userId: "u-khoa", userName: "Đăng Khoa", userAvatar: null, rating: 5, content: "Viên nén dễ dùng, đóng gói kỹ.", images: [], createdAt: daysAgo(30) },
  { id: "rv3", productId: "prd-fertilizer", orderId: null, userId: "u-thu", userName: "Thu Hà", userAvatar: null, rating: 4, content: "Hiệu quả ổn, mong có túi lớn hơn.", images: [], createdAt: daysAgo(46) },
  { id: "rv4", productId: "prd-soil", orderId: null, userId: "u-phuc", userName: "Hoàng Phúc", userAvatar: null, rating: 5, content: "Giá thể rất tơi, thay chậu xong cây không bị sốc.", images: [IMG.products.soil], createdAt: daysAgo(9) },
  { id: "rv5", productId: "prd-soil", orderId: null, userId: "u-my", userName: "Trà My", userAvatar: null, rating: 4, content: "Thoát nước tốt, hơi nhiều vỏ thông với cây nhỏ.", images: [], createdAt: daysAgo(60) },
  { id: "rv6", productId: "prd-pots", orderId: null, userId: "u-linh", userName: "Khánh Linh", userAvatar: null, rating: 5, content: "Màu men ngoài đời đẹp hơn ảnh, rất hợp phòng tối giản.", images: [IMG.products.pots], createdAt: daysAgo(4) },
  { id: "rv7", productId: "prd-pots", orderId: null, userId: "u-nam", userName: "Hải Nam", userAvatar: null, rating: 5, content: "Đóng gói chống sốc cẩn thận.", images: [], createdAt: daysAgo(7) },
  { id: "rv8", productId: "prd-neem", orderId: null, userId: "u-quan", userName: "Minh Quân", userAvatar: null, rating: 5, content: "Hết rệp sáp trên hoa giấy sau 2 lần phun.", images: [], createdAt: daysAgo(20) },
  { id: "rv9", productId: "prd-neem", orderId: null, userId: "u-vy", userName: "Tường Vy", userAvatar: null, rating: 4, content: "Mùi hơi hắc nhưng hiệu quả.", images: [], createdAt: daysAgo(33) },
  { id: "rv10", productId: "prd-neem", orderId: null, userId: "u-an", userName: "Bảo An", userAvatar: null, rating: 5, content: "Dùng phòng ngừa định kỳ cho cả vườn ban công.", images: [], createdAt: daysAgo(51) },
  { id: "rv11", productId: "prd-fungicide", orderId: null, userId: "u-tuan", userName: "Anh Tuấn", userAvatar: null, rating: 5, content: "Đốm lá trên trầu bà giảm rõ sau 2 tuần kết hợp cắt lá bệnh.", images: [IMG.leafSpot], createdAt: daysAgo(18) },
  { id: "rv12", productId: "prd-fungicide", orderId: null, userId: "u-hoa", userName: "Mai Hoa", userAvatar: null, rating: 4, content: "Dạng xịt tiện, nên mua thêm chai lớn.", images: [], createdAt: daysAgo(40) },
  { id: "rv13", productId: "prd-pruning", orderId: null, userId: "u-son", userName: "Thái Sơn", userAvatar: null, rating: 5, content: "Kéo cầm đầm tay, cắt rất ngọt.", images: [], createdAt: daysAgo(3) },
  { id: "rv14", productId: "prd-mister", orderId: null, userId: "u-ngan", userName: "Kim Ngân", userAvatar: null, rating: 5, content: "Phun sương mịn, để trên kệ cũng đẹp.", images: [], createdAt: daysAgo(25) },
  { id: "rv15", productId: "prd-watering-can", orderId: null, userId: "u-duc", userName: "Minh Đức", userAvatar: null, rating: 4, content: "Vòi dài tưới chậu treo rất tiện.", images: [], createdAt: daysAgo(36) },
  { id: "rv16", productId: "prd-moisture", orderId: null, userId: "u-yen", userName: "Hải Yến", userAvatar: null, rating: 4, content: "Đo độ ẩm khá chuẩn, pH thì chỉ tham khảo.", images: [], createdAt: daysAgo(2) },
  { id: "rv17", productId: "prd-plant-monstera", orderId: null, userId: "u-long", userName: "Gia Long", userAvatar: null, rating: 5, content: "Cây khỏe, lá to, giao nhanh.", images: [IMG.plants.monstera], createdAt: daysAgo(11) },
  { id: "rv18", productId: "prd-plant-snake", orderId: null, userId: "u-thao", userName: "Phương Thảo", userAvatar: null, rating: 5, content: "Chậu gốm đẹp, cây đúng mô tả.", images: [], createdAt: daysAgo(15) },
];

// Vouchers
export const VOUCHERS: Voucher[] = [
  { code: "FLORIA10", title: "Giảm 10% cho đơn đầu tiên", type: "percent", value: 10, maxDiscount: 50000, minOrder: 150000, expiresAt: "2027-03-31T16:59:59Z", active: true },
  { code: "XANH50K", title: "Giảm 50.000₫ đơn từ 500.000₫", type: "fixed", value: 50000, minOrder: 500000, expiresAt: "2027-01-31T16:59:59Z", active: true },
  { code: "MUAMUA", title: "Giảm 15% mùa mưa", type: "percent", value: 15, maxDiscount: 80000, minOrder: 300000, expiresAt: "2026-10-31T16:59:59Z", active: false },
];

export const SHIPPING_FEE = 0;
