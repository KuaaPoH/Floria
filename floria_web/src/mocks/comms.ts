import type { Campaign, Ticket, ConversationReport, Guardrail, ActionTag, PromptVersion, AssistantSettings } from "@/types";
import { daysAgo } from "@/lib/id";
import { IMAGES } from "./images";

export function seedCampaigns(): Campaign[] {
  return [
    { id: "cmp_1", name: "Nhắc tưới cuối tuần", title: "🌿 Cây của bạn đang khát!", body: "Đã 5 ngày chưa tưới Trầu bà lá xẻ. Mở Floria để xem lịch tưới nhé.", image: IMAGES.monstera, deepLink: "floria://garden", audience: "active", audienceDetail: "Người dùng hoạt động 30 ngày", scheduledAt: daysAgo(2, 8), status: "sent", targeted: 18420, success: 17986, failed: 434, opened: 6210 },
    { id: "cmp_2", name: "Ra mắt chẩn đoán bệnh v1.6", title: "Chẩn đoán bệnh chính xác hơn", body: "Floria vừa nâng cấp khả năng nhận diện bệnh đốm lá và gỉ sắt.", image: IMAGES.leafSpot, deepLink: "floria://scan/disease", audience: "diagnosed", audienceDetail: "Đã từng chẩn đoán bệnh", scheduledAt: daysAgo(9, 19), status: "sent", targeted: 7340, success: 7102, failed: 238, opened: 3120 },
    { id: "cmp_3", name: "Win-back tháng 11", title: "Lâu rồi không gặp bạn 👋", body: "Khu vườn nhớ bạn đó! Nhận voucher FREESHIP30 khi quay lại.", image: IMAGES.bannerHome, deepLink: "floria://shop", audience: "inactive", audienceDetail: "Không hoạt động > 30 ngày", scheduledAt: daysAgo(-2, 9), status: "scheduled", targeted: 9210, success: 0, failed: 0, opened: 0 },
    { id: "cmp_4", name: "Chăm Lan hồ điệp mùa lạnh", title: "Lan hồ điệp cần ấm hơn", body: "Nhiệt độ giảm, xem ngay 3 mẹo giữ lan ra hoa.", image: IMAGES.orchid, deepLink: "floria://handbook/art_1", audience: "species", audienceDetail: "Lan hồ điệp", scheduledAt: daysAgo(15, 18), status: "sent", targeted: 2140, success: 2098, failed: 42, opened: 1240 },
    { id: "cmp_5", name: "Khảo sát trải nghiệm", title: "Góp ý cho Floria", body: "2 phút khảo sát để Floria tốt hơn.", image: "", deepLink: "floria://survey", audience: "all", audienceDetail: "Tất cả người dùng", scheduledAt: daysAgo(22, 10), status: "failed", targeted: 31200, success: 0, failed: 31200, opened: 0 },
  ];
}

export function seedTickets(): Ticket[] {
  const t = (i: number, subject: string, category: Ticket["category"], userName: string, status: Ticket["status"], priority: Ticket["priority"], msg: string): Ticket => ({
    id: `tkt_${i}`,
    code: `HT-${2400 + i}`,
    subject,
    category,
    userName,
    email: `${userName.split(" ").at(-1)?.toLowerCase()}${i}@gmail.com`.normalize("NFD").replace(/[\u0300-\u036f]/g, ""),
    status,
    priority,
    createdAt: daysAgo(i, 9 + i),
    assignee: status === "open" ? "" : i % 2 ? "Ngô Thanh Tú" : "Hồ Gia Linh",
    messages: [
      { from: "user", text: msg, at: daysAgo(i, 9 + i) },
      ...(status !== "open" ? [{ from: "admin" as const, text: "Floria đã nhận được phản hồi và đang kiểm tra. Cảm ơn bạn!", at: daysAgo(i, 11 + i) }] : []),
    ],
    notes: status === "resolved" ? [{ by: "Ngô Thanh Tú", text: "Đã xử lý, khách xác nhận.", at: daysAgo(i - 1 < 0 ? 0 : i - 1) }] : [],
  });
  return [
    t(1, "Ứng dụng bị thoát khi mở camera", "app_error", "Trần Thu Hà", "open", "high", "Mỗi lần bấm Quét cây là app tự tắt trên Samsung A54."),
    t(2, "AI nhận nhầm Kim tiền thành Lưỡi hổ", "ai_wrong", "Lê Minh Quân", "in_progress", "medium", "Mình chụp cây Kim tiền nhưng kết quả ra Lưỡi hổ 72%."),
    t(3, "Đơn FL26110405 giao thiếu hàng", "order", "Phạm Ngọc Vy", "in_progress", "high", "Đơn của mình thiếu 1 túi đất trồng."),
    t(4, "Chậu bị nứt khi nhận", "product", "Đỗ Gia Bảo", "resolved", "medium", "Chậu gốm 22cm bị nứt ở viền."),
    t(5, "Đề xuất thêm nhắc bón phân", "suggestion", "Võ Thanh Trang", "open", "low", "Mong app có thêm lịch nhắc bón phân định kỳ."),
    t(6, "Không nhận được mã OTP", "app_error", "Bùi Quốc Hưng", "resolved", "high", "Đăng ký bằng email nhưng không nhận được mã."),
    t(7, "Chẩn đoán sai bệnh phấn trắng", "ai_wrong", "Nguyễn Gia An", "open", "medium", "Lá hoa hồng bị phấn trắng nhưng app báo lá khoẻ."),
  ];
}

export function seedReports(): ConversationReport[] {
  return [
    { id: "rpt_1", userName: "Trần Minh Khoa", preview: "Lá cây trầu bà có chữa được ho không?", reason: "Câu trả lời chưa cảnh báo rõ", at: daysAgo(1), status: "pending", note: "", transcript: [{ from: "user", text: "Lá cây trầu bà có chữa được ho không?" }, { from: "bot", text: "Floria không khuyến nghị sử dụng cây cảnh để chữa bệnh cho người. Trầu bà còn chứa calcium oxalate gây kích ứng. Bạn nên tham khảo ý kiến bác sĩ." }] },
    { id: "rpt_2", userName: "Lê Hoài Thương", preview: "Mèo nhà mình gặm lá lan ý thì sao?", reason: "Muốn thông tin chi tiết hơn", at: daysAgo(2), status: "pending", note: "", transcript: [{ from: "user", text: "Mèo nhà mình gặm lá lan ý thì sao?" }, { from: "bot", text: "⚠️ Lan ý độc với mèo. Hãy rửa miệng cho mèo và liên hệ bác sĩ thú y ngay nếu có dấu hiệu nôn, chảy dãi." }] },
    { id: "rpt_3", userName: "Phạm Gia Huy", preview: "Gợi ý phân bón cho hoa hồng", reason: "Sản phẩm gợi ý hết hàng", at: daysAgo(4), status: "reviewed", note: "Đã báo team kho cập nhật tồn.", transcript: [{ from: "user", text: "Gợi ý phân bón cho hoa hồng" }, { from: "bot", text: "Bạn có thể dùng Phân tan chậm Osmocote. [RECOMMEND_PRODUCT]" }] },
    { id: "rpt_4", userName: "Võ Ngọc Ánh", preview: "Dự báo giá vàng tuần tới?", reason: "Bot trả lời ngoài phạm vi", at: daysAgo(6), status: "dismissed", note: "Bot đã từ chối đúng quy tắc.", transcript: [{ from: "user", text: "Dự báo giá vàng tuần tới?" }, { from: "bot", text: "Xin lỗi, Floria chỉ hỗ trợ các câu hỏi về cây trồng và chăm sóc vườn." }] },
  ];
}

export function seedGuardrails(): Guardrail[] {
  return [
    { id: "gr_1", category: "care", name: "Ưu tiên chăm sóc & chẩn đoán", description: "Trả lời tập trung vào chăm sóc cây, chẩn đoán bệnh và gợi ý điều trị an toàn.", response: "Hãy mô tả triệu chứng hoặc gửi ảnh lá để Floria hỗ trợ chính xác hơn.", keywords: ["tưới", "bón phân", "vàng lá", "héo", "bệnh"], enabled: true },
    { id: "gr_2", category: "toxicity", name: "Cảnh báo độc tính thú cưng & trẻ em", description: "Luôn cảnh báo khi cây có độc tính với chó, mèo hoặc trẻ nhỏ.", response: "⚠️ Loài cây này có thể gây độc cho thú cưng và trẻ nhỏ. Hãy đặt cây ngoài tầm với.", keywords: ["mèo", "chó", "thú cưng", "trẻ em", "ăn lá"], enabled: true },
    { id: "gr_3", category: "medical", name: "Không dùng cây cảnh chữa bệnh cho người", description: "Từ chối hướng dẫn sử dụng cây cảnh như thuốc chữa bệnh cho người.", response: "Floria không khuyến nghị dùng cây cảnh để chữa bệnh. Vui lòng tham khảo ý kiến bác sĩ.", keywords: ["chữa", "uống", "thuốc", "đắp", "ho", "đau"], enabled: true },
    { id: "gr_4", category: "scope", name: "Chặn chủ đề ngoài phạm vi", description: "Từ chối lịch sự các câu hỏi không liên quan đến cây trồng, làm vườn hoặc cửa hàng Floria.", response: "Xin lỗi, Floria chỉ hỗ trợ các câu hỏi về cây trồng và chăm sóc vườn.", keywords: ["giá vàng", "bóng đá", "chứng khoán", "chính trị", "xổ số"], enabled: true },
  ];
}

export function seedActionTags(): ActionTag[] {
  return [
    { id: "tag_1", tag: "[RECOMMEND_PRODUCT]", keywords: ["mua", "phân bón", "chậu", "thuốc", "gợi ý sản phẩm"], intent: "Người dùng cần sản phẩm để chăm sóc hoặc điều trị cây.", condition: "Có ít nhất 1 sản phẩm còn hàng thuộc danh mục phù hợp", enabled: true },
    { id: "tag_2", tag: "[CARE_SCHEDULE]", keywords: ["lịch tưới", "nhắc", "bao lâu tưới", "lịch bón"], intent: "Người dùng muốn tạo hoặc điều chỉnh lịch chăm sóc.", condition: "Người dùng đã có cây trong Khu vườn của tôi", enabled: true },
  ];
}

export const DEFAULT_PROMPT = `Bạn là Floria — trợ lý chăm sóc cây cảnh thân thiện, am hiểu thực vật học.

Nguyên tắc:
1. Trả lời bằng tiếng Việt, ngắn gọn, dễ hiểu, có bước hành động cụ thể.
2. Chỉ tư vấn về cây trồng, sâu bệnh, làm vườn và sản phẩm trong cửa hàng Floria.
3. Luôn cảnh báo độc tính nếu cây có hại với thú cưng hoặc trẻ nhỏ.
4. Không hướng dẫn dùng cây cảnh để chữa bệnh cho người.
5. Khi phù hợp, chèn thẻ [RECOMMEND_PRODUCT] hoặc [CARE_SCHEDULE].`;

export function seedPromptVersions(): PromptVersion[] {
  return [
    { id: "pv_7", version: 7, status: "published", at: daysAgo(4), by: "TS. Nguyễn Thảo", content: DEFAULT_PROMPT },
    { id: "pv_6", version: 6, status: "published", at: daysAgo(26), by: "Phạm Minh Đức", content: DEFAULT_PROMPT.replace("\n5. Khi phù hợp, chèn thẻ [RECOMMEND_PRODUCT] hoặc [CARE_SCHEDULE].", "") },
  ];
}

export const DEFAULT_ASSISTANT: AssistantSettings = {
  name: "Floria",
  language: "vi",
  tone: "friendly",
  maxLength: 600,
  fallback: "Xin lỗi, Floria chưa hiểu câu hỏi. Bạn có thể mô tả rõ hơn hoặc gửi ảnh cây nhé!",
};
