import type { Article, Banner, WeatherRule, FeatureFlag, RemoteConfig, ConfigVersion } from "@/types";
import { daysAgo } from "@/lib/id";
import { IMAGES } from "./images";

export const ARTICLE_CATEGORIES = ["Chăm sóc cơ bản", "Sâu bệnh", "Cây phong thuỷ", "Mẹo làm vườn", "Mùa vụ"];

export function seedArticles(): Article[] {
  return [
    {
      id: "art_1",
      title: "Cách tưới cây trong nhà đúng cách vào mùa mưa",
      excerpt: "Mùa mưa độ ẩm cao, cây dễ úng rễ. Điều chỉnh lịch tưới để cây luôn khoẻ.",
      category: "Chăm sóc cơ bản",
      cover: IMAGES.bannerHome,
      author: "TS. Nguyễn Thảo",
      status: "published",
      publishedAt: daysAgo(5),
      updatedAt: daysAgo(5),
      views: 12840,
      blocks: [
        { id: "b1", type: "heading", text: "Vì sao mùa mưa cần giảm tưới?" },
        { id: "b2", type: "paragraph", text: "Độ ẩm không khí trên 80% khiến đất chậm khô, rễ cây thiếu oxy và dễ bị nấm Pythium tấn công." },
        { id: "b3", type: "bullets", text: "", items: ["Kiểm tra đất bằng ngón tay trước khi tưới", "Ưu tiên tưới buổi sáng", "Đảm bảo chậu có lỗ thoát nước"] },
        { id: "b4", type: "warning", text: "Không để nước đọng trong đĩa lót chậu quá 30 phút." },
      ],
    },
    {
      id: "art_2",
      title: "Nhận biết sớm bệnh đốm lá trên Trầu bà",
      excerpt: "Những dấu hiệu đầu tiên và cách xử lý trước khi bệnh lan rộng.",
      category: "Sâu bệnh",
      cover: IMAGES.leafSpot,
      author: "TS. Nguyễn Thảo",
      status: "published",
      publishedAt: daysAgo(12),
      updatedAt: daysAgo(11),
      views: 8420,
      blocks: [
        { id: "b1", type: "paragraph", text: "Đốm lá là bệnh nấm phổ biến nhất trên các loại Trầu bà trồng trong nhà." },
        { id: "b2", type: "info", text: "Bạn có thể chụp ảnh lá bằng tính năng Chẩn đoán bệnh của Floria để được gợi ý xử lý." },
      ],
    },
    {
      id: "art_3",
      title: "5 loại cây phong thuỷ hợp mệnh Mộc",
      excerpt: "Gợi ý những loại cây xanh mang lại năng lượng tích cực cho không gian sống.",
      category: "Cây phong thuỷ",
      cover: IMAGES.monstera,
      author: "Hồ Gia Linh",
      status: "draft",
      publishedAt: "",
      updatedAt: daysAgo(1),
      views: 0,
      blocks: [{ id: "b1", type: "paragraph", text: "Bản nháp đang được biên tập." }],
    },
    {
      id: "art_4",
      title: "Chọn chậu phù hợp cho từng loại cây",
      excerpt: "Chất liệu, kích thước và khả năng thoát nước ảnh hưởng thế nào tới bộ rễ.",
      category: "Mẹo làm vườn",
      cover: IMAGES.pot,
      author: "Ngô Thanh Tú",
      status: "published",
      publishedAt: daysAgo(20),
      updatedAt: daysAgo(20),
      views: 5310,
      blocks: [{ id: "b1", type: "paragraph", text: "Chậu gốm thoáng khí, chậu nhựa giữ ẩm tốt hơn." }],
    },
  ];
}

export function seedBanners(): Banner[] {
  return [
    { id: "bnr_1", title: "Mùa mưa, cây vẫn xanh", subtitle: "Bộ chăm sóc chống úng rễ giảm 20%", cta: "Mua ngay", deepLink: "floria://shop/collection/mua-mua", image: IMAGES.bannerHome, startDate: daysAgo(5), endDate: daysAgo(-25), active: true, order: 1 },
    { id: "bnr_2", title: "Chẩn đoán bệnh trong 3 giây", subtitle: "Chụp ảnh lá, nhận phác đồ điều trị", cta: "Thử ngay", deepLink: "floria://scan/disease", image: IMAGES.leafSpot, startDate: daysAgo(30), endDate: daysAgo(-60), active: true, order: 2 },
    { id: "bnr_3", title: "Chậu gốm Sage mới về", subtitle: "Thiết kế tối giản cho góc xanh", cta: "Khám phá", deepLink: "floria://shop/product/prd_007", image: IMAGES.pot, startDate: daysAgo(60), endDate: daysAgo(2), active: false, order: 3 },
  ];
}

export function seedWeatherRules(): WeatherRule[] {
  return [
    { id: "wr_1", name: "Ngày mưa kéo dài", condition: "rain", tempMin: 20, tempMax: 32, humidityMin: 80, humidityMax: 100, tip: "Trời mưa nhiều — hãy giảm tưới và kiểm tra thoát nước của chậu.", active: true },
    { id: "wr_2", name: "Nắng gắt mùa hè", condition: "hot", tempMin: 35, tempMax: 45, humidityMin: 0, humidityMax: 60, tip: "Nhiệt độ trên 35°C — di chuyển cây ưa bóng vào trong, tưới vào sáng sớm.", active: true },
    { id: "wr_3", name: "Nồm ẩm", condition: "humid", tempMin: 15, tempMax: 25, humidityMin: 85, humidityMax: 100, tip: "Độ ẩm cao dễ phát sinh nấm — tăng thông gió, tránh phun sương lên lá.", active: true },
    { id: "wr_4", name: "Nắng đẹp", condition: "sunny", tempMin: 24, tempMax: 33, humidityMin: 40, humidityMax: 75, tip: "Thời tiết lý tưởng để bón phân và thay chậu.", active: false },
    { id: "wr_5", name: "Rét đậm", condition: "cold", tempMin: 0, tempMax: 12, humidityMin: 0, humidityMax: 100, tip: "Trời lạnh — đưa cây nhiệt đới vào trong nhà, giảm tưới một nửa.", active: true },
  ];
}

export function seedFlags(): FeatureFlag[] {
  const f = (key: string, name: string, description: string, enabled: boolean, d: number, by: string): FeatureFlag => ({
    id: `flg_${key}`, key, name, description, enabled, updatedAt: daysAgo(d), updatedBy: by,
  });
  return [
    f("ai_plant_recognition", "AI Plant Recognition", "Nhận diện loài cây bằng camera.", true, 6, "Phạm Minh Đức"),
    f("ai_disease_diagnosis", "AI Disease Diagnosis", "Chẩn đoán bệnh trên lá và gợi ý điều trị.", true, 18, "TS. Nguyễn Thảo"),
    f("floria_assistant", "Floria Assistant", "Trợ lý hỏi đáp chăm sóc cây.", true, 3, "Phạm Minh Đức"),
    f("zalopay_sandbox", "ZaloPay Sandbox", "Thanh toán nhanh qua cổng ZaloPay Sandbox trong giỏ hàng.", true, 9, "Ngô Thanh Tú"),
    f("weather_widget", "Weather Widget", "Thẻ thời tiết và mẹo chăm cây trên trang chủ.", true, 22, "Hồ Gia Linh"),
    f("watering_reminders", "Watering Reminders", "Thông báo nhắc lịch tưới cây.", true, 40, "Phạm Minh Đức"),
    f("community_feed", "Community Feed (Beta)", "Bảng tin chia sẻ góc xanh giữa người dùng.", false, 2, "Phạm Minh Đức"),
  ];
}

export const DEFAULT_REMOTE_CONFIG: RemoteConfig = {
  sections: [
    { id: "sec_banner", type: "banner", title: "Banner nổi bật", enabled: true, layout: "carousel" },
    { id: "sec_quick", type: "quick_actions", title: "Tác vụ nhanh", enabled: true, layout: "grid" },
    { id: "sec_weather", type: "weather", title: "Thời tiết hôm nay", enabled: true, layout: "list" },
    { id: "sec_plants", type: "my_plants", title: "Khu vườn của tôi", enabled: true, layout: "carousel" },
    { id: "sec_reminders", type: "reminders", title: "Lịch tưới hôm nay", enabled: true, layout: "list" },
    { id: "sec_shop", type: "shop", title: "Gợi ý cho bạn", enabled: true, layout: "grid" },
    { id: "sec_handbook", type: "handbook", title: "Cẩm nang", enabled: false, layout: "list" },
  ],
  theme: { primary: "#174B35", accent: "#78A878", rounded: true },
  banner: { title: "Mùa mưa, cây vẫn xanh", subtitle: "Bộ chăm sóc chống úng rễ giảm 20%", cta: "Mua ngay" },
};

export function seedConfigVersions(): ConfigVersion[] {
  const v2 = structuredClone(DEFAULT_REMOTE_CONFIG);
  const v1 = structuredClone(DEFAULT_REMOTE_CONFIG);
  v1.sections = v1.sections.filter((s) => s.type !== "reminders");
  v1.banner.title = "Chào mừng đến Floria";
  return [
    { id: "cfg_v12", version: 12, status: "published", at: daysAgo(3), by: "Phạm Minh Đức", note: "Thêm khối Lịch tưới hôm nay", snapshot: v2 },
    { id: "cfg_v11", version: 11, status: "published", at: daysAgo(17), by: "Hồ Gia Linh", note: "Đổi banner chiến dịch mùa mưa", snapshot: v1 },
  ];
}
