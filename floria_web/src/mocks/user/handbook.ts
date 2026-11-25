import type { HandbookArticle, HomeWeatherWidget } from "@/types/user";
import { IMG } from "./images";

// PlantHandbook
export const PLANT_HANDBOOK: HandbookArticle[] = [
  {
    id: "hb-1", slug: "tuoi-cay-dung-cach", title: "Tưới cây đúng cách: khi nào, bao nhiêu và vì sao",
    excerpt: "Úng nước giết cây trong nhà nhiều hơn khô hạn. Học cách đọc tín hiệu của đất và lá.",
    category: "watering", image: IMG.plants.pothos, readMinutes: 6, tags: ["hot", "epipremnum-aureum", "spathiphyllum-wallisii"],
    body: [
      "Quy tắc quan trọng nhất: tưới theo độ ẩm của đất, không theo lịch cứng. Cắm ngón tay sâu 3–5 cm; nếu đất khô, đó là lúc tưới.",
      "Tưới đẫm đến khi nước chảy ra lỗ thoát, sau đó đổ bỏ nước đọng trong đĩa lót sau 15 phút để rễ không bị ngộp.",
      "Mùa nóng, cây thoát hơi nước nhanh hơn — rút ngắn chu kỳ 1–2 ngày. Mùa mưa và lạnh, giãn chu kỳ tưới.",
      "Dấu hiệu thừa nước: lá vàng từ gốc, thân mềm, đất có mùi chua. Dấu hiệu thiếu nước: lá rũ, mép lá giòn, đất co tách khỏi thành chậu.",
    ],
    publishedAt: "2026-10-02T08:00:00Z",
  },
  {
    id: "hb-2", slug: "cham-cay-mua-mua", title: "Chăm cây ban công trong mùa mưa",
    excerpt: "Độ ẩm cao là điều kiện lý tưởng cho nấm bệnh. 5 việc cần làm ngay khi mùa mưa đến.",
    category: "seasonal", image: IMG.gardens.balcony, readMinutes: 5, tags: ["rain", "bougainvillea", "aloe-vera"],
    body: [
      "Kê chậu cao khỏi sàn để nước mưa không đọng ở đáy chậu.",
      "Giảm tưới hoặc tạm ngưng những ngày mưa liên tục; kiểm tra đất trước khi tưới lại.",
      "Tỉa bớt cành lá rậm để tăng thông thoáng, hạn chế đốm lá và gỉ sắt.",
      "Phun phòng bằng chế phẩm sinh học 7–10 ngày/lần với cây từng bị bệnh.",
      "Che chắn cây mọng nước như nha đam, sen đá khỏi mưa lớn kéo dài.",
    ],
    publishedAt: "2026-09-18T08:00:00Z",
  },
  {
    id: "hb-3", slug: "nhan-biet-dom-la", title: "Nhận biết và xử lý bệnh đốm lá",
    excerpt: "Phân biệt đốm do nấm, vi khuẩn và cháy nắng để xử lý đúng ngay từ đầu.",
    category: "disease", image: IMG.leafSpot, readMinutes: 7, tags: ["rain", "leaf-spot"],
    body: [
      "Đốm nấm thường có viền rõ, quầng vàng và vòng đồng tâm. Đốm vi khuẩn có vẻ ướt, mép nhũn.",
      "Cháy nắng tạo mảng bạc màu, khô giòn ở phía lá hướng ra ánh sáng — không lây lan.",
      "Cắt bỏ lá bệnh bằng kéo đã khử trùng, cách ly cây và tránh tưới lên lá.",
      "Dùng ứng dụng Floria để chẩn đoán ảnh lá và ghi lại diễn biến trong nhật ký cây.",
    ],
    publishedAt: "2026-10-20T08:00:00Z",
  },
  {
    id: "hb-4", slug: "cay-it-anh-sang", title: "8 loại cây sống khỏe ở góc ít ánh sáng",
    excerpt: "Phòng không cửa sổ vẫn có thể xanh mướt với những lựa chọn bền bỉ này.",
    category: "indoor", image: IMG.plants.zz, readMinutes: 4, tags: ["zamioculcas-zamiifolia", "sansevieria-trifasciata"],
    body: [
      "Kim tiền và lưỡi hổ dẫn đầu danh sách nhờ khả năng dự trữ nước và chịu bóng.",
      "Trầu bà vàng vẫn sống tốt dù vân vàng có thể nhạt đi.",
      "Lan ý ra hoa ít hơn trong bóng râm nhưng lá vẫn xanh bóng.",
      "Xoay chậu mỗi 2 tuần và lau lá để tận dụng tối đa ánh sáng yếu.",
    ],
    publishedAt: "2026-08-30T08:00:00Z",
  },
  {
    id: "hb-5", slug: "bon-phan-cay-trong-nha", title: "Bón phân cho cây trong nhà: ít mà đều",
    excerpt: "Cây trong chậu cạn kiệt dinh dưỡng nhanh hơn bạn nghĩ. Hướng dẫn chọn và bón phân an toàn.",
    category: "basics", image: IMG.products.fertilizer, readMinutes: 5, tags: ["monstera-deliciosa", "ficus-lyrata"],
    body: [
      "Bón vào mùa sinh trưởng (xuân – thu), giảm hoặc ngưng vào mùa lạnh.",
      "Ưu tiên phân hữu cơ giải phóng chậm để tránh cháy rễ.",
      "Luôn tưới ẩm đất trước khi bón phân dạng lỏng.",
    ],
    publishedAt: "2026-07-12T08:00:00Z",
  },
  {
    id: "hb-6", slug: "vuon-san-thuong-nang-nong", title: "Giữ vườn sân thượng mát lành ngày nắng nóng",
    excerpt: "Nhiệt độ sân thượng có thể vượt 45°C. Che lưới, tưới sớm và phủ gốc đúng cách.",
    category: "outdoor", image: IMG.gardens.rooftop, readMinutes: 6, tags: ["hot", "bougainvillea"],
    body: [
      "Tưới trước 8 giờ sáng hoặc sau 5 giờ chiều để nước không bốc hơi nhanh và tránh sốc nhiệt.",
      "Phủ gốc bằng vỏ trấu, xơ dừa để giữ ẩm.",
      "Dùng lưới che nắng 50% cho cây lá mềm vào giữa trưa.",
    ],
    publishedAt: "2026-06-05T08:00:00Z",
  },
  {
    id: "hb-7", slug: "lau-la-va-kiem-tra-sau-benh", title: "Lau lá và kiểm tra sâu bệnh định kỳ",
    excerpt: "10 phút mỗi tuần giúp phát hiện rệp, nhện đỏ trước khi chúng lan khắp vườn.",
    category: "basics", image: IMG.plants.rubber, readMinutes: 3, tags: ["ficus-elastica", "monstera-deliciosa", "cool"],
    body: [
      "Lật mặt dưới lá — nơi rệp và nhện đỏ thường trú ẩn.",
      "Lau lá bằng khăn ẩm giúp lá quang hợp tốt hơn và phát hiện sớm vết bất thường.",
      "Ghi lại phát hiện vào nhật ký để theo dõi tiến triển.",
    ],
    publishedAt: "2026-10-28T08:00:00Z",
  },
  {
    id: "hb-8", slug: "cham-lan-ho-diep", title: "Chăm lan hồ điệp ra hoa lần hai",
    excerpt: "Sau khi hoa tàn, đừng vội bỏ cây. Kích hoa lại chỉ với 3 bước đơn giản.",
    category: "indoor", image: IMG.plants.orchid, readMinutes: 5, tags: ["phalaenopsis", "cool"],
    body: [
      "Cắt cành hoa phía trên mắt ngủ thứ hai từ gốc.",
      "Đặt cây nơi có chênh lệch nhiệt ngày đêm khoảng 5–8°C trong 4 tuần.",
      "Bón phân lân cao mỗi 2 tuần khi xuất hiện ngồng mới.",
    ],
    publishedAt: "2026-09-02T08:00:00Z",
  },
];

// HomeWeatherWidgets — time-slot configuration for the dashboard weather card.
export const HOME_WEATHER_WIDGETS: HomeWeatherWidget[] = [
  { id: "w-morning", slot: "morning", fromHour: 5, toHour: 11, greeting: "Chào buổi sáng", greetingEn: "Good morning", message: "Buổi sáng là thời điểm lý tưởng để tưới cây.", messageEn: "Morning is the best time to water." },
  { id: "w-afternoon", slot: "afternoon", fromHour: 11, toHour: 17, greeting: "Chào buổi chiều", greetingEn: "Good afternoon", message: "Tránh tưới lên lá khi nắng gắt.", messageEn: "Avoid wetting leaves under harsh sun." },
  { id: "w-evening", slot: "evening", fromHour: 17, toHour: 21, greeting: "Chào buổi tối", greetingEn: "Good evening", message: "Kiểm tra mặt dưới lá trước khi nghỉ ngơi.", messageEn: "Check leaf undersides before winding down." },
  { id: "w-night", slot: "night", fromHour: 21, toHour: 5, greeting: "Chúc ngủ ngon", greetingEn: "Good night", message: "Cây cũng cần nghỉ — hạn chế tưới vào ban đêm.", messageEn: "Plants rest too — avoid watering at night." },
];
