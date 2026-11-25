import { isMock } from "@/config/env";
import { uid } from "@/lib/id";
import { readDb, writeDb } from "@/mocks/user/db";
import type { ChatMessage, ChatSession } from "@/types/user";
import { http } from "./api/http";
import { fetchUserCatalog } from "./content.service";
import { analyzeImage } from "./mock/image-analysis";
import { latency, MockError, requireUid } from "./mock/util";
import { session } from "./session";

export interface AssistantService {
  listSessions(): Promise<ChatSession[]>;
  createSession(title?: string): Promise<ChatSession>;
  renameSession(id: string, title: string): Promise<ChatSession>;
  deleteSession(id: string): Promise<void>;
  listMessages(sessionId: string): Promise<ChatMessage[]>;
  sendMessage(sessionId: string, content: string, images: string[]): Promise<[ChatMessage, ChatMessage]>;
}

const PLANT_WORDS = ["cây", "lá", "hoa", "tưới", "bón", "phân", "đất", "chậu", "vườn", "sâu", "bệnh", "rệp", "nấm", "ánh sáng", "nắng", "ban công", "trồng", "rễ", "cành", "thân", "giâm", "mùa mưa", "độ ẩm", "plant", "leaf", "water", "soil", "garden", "pest", "monstera", "lan", "sen đá", "xương rồng", "trầu bà", "lưỡi hổ", "kim tiền", "hoa giấy", "nha đam"];

const tag = (name: string, data: unknown) => `[${name}]${JSON.stringify(data)}[/${name}]`;

async function mockReply(text: string, images: string[]): Promise<string> {
  const q = text.toLowerCase();
  if (images.length) {
    const checks = await Promise.all(images.map((i) => analyzeImage(i).catch(() => ({ greenRatio: 0, hash: 0 }))));
    if (checks.every((c) => c.greenRatio < 0.06)) {
      return "Ảnh bạn gửi có vẻ không chứa cây trồng nên mình chưa thể phân tích. Hãy gửi ảnh chụp rõ lá, thân hoặc toàn cây trong điều kiện đủ sáng nhé.";
    }
  }
  const onTopic = images.length > 0 || PLANT_WORDS.some((w) => q.includes(w));
  if (!onTopic) {
    return "Mình là Floria — trợ lý chuyên về cây trồng, nên chỉ có thể tư vấn về thực vật, chăm sóc cây, sâu bệnh, môi trường trồng và làm vườn. Bạn có câu hỏi nào về khu vườn của mình không?";
  }
  if (q.includes("vàng lá") || q.includes("lá vàng") || q.includes("vàng")) {
    return `Lá vàng thường do **tưới quá nhiều** (vàng từ lá gốc, đất ẩm lâu), **thiếu sáng** hoặc **thiếu dinh dưỡng** (vàng đều, lá non nhạt màu).\n\n1. Kiểm tra độ ẩm đất ở độ sâu 3–5 cm trước mỗi lần tưới.\n2. Đảm bảo chậu có lỗ thoát nước và đổ nước đọng ở đĩa lót.\n3. Nếu cây đã lâu không bón phân, bổ sung phân hữu cơ giải phóng chậm.\n\n${tag("CARE_SCHEDULE", { plantName: "Cây bị vàng lá", careType: "watering", intervalDays: 7, preferredTime: "07:00", reason: "Giãn chu kỳ tưới để đất khô bớt giữa các lần tưới" })}\n\n${tag("RECOMMEND_PRODUCT", { productId: "prd-moisture", reason: "Biết chính xác khi nào đất cần tưới" })}`;
  }
  if (q.includes("mùa mưa") || q.includes("mưa")) {
    return `Mùa mưa độ ẩm cao là điều kiện thuận lợi cho nấm bệnh. Bạn nên:\n\n1. Kê chậu cao, tránh đọng nước ở đáy.\n2. Giảm tưới, chỉ tưới khi đất mặt khô.\n3. Tỉa thưa cành lá để thông thoáng.\n4. Kiểm tra mặt dưới lá thường xuyên hơn.\n\n${tag("CARE_SCHEDULE", { plantName: "Cây ban công", careType: "inspection", intervalDays: 5, preferredTime: "17:30", reason: "Phát hiện sớm đốm lá, gỉ sắt trong mùa mưa" })}\n\n${tag("RECOMMEND_PRODUCT", { productId: "prd-fungicide", reason: "Phòng ngừa nấm bệnh trên lá" })}`;
  }
  if (q.includes("tưới") || q.includes("bao nhiêu lần")) {
    return `Không có lịch tưới cố định cho mọi loài — hãy tưới theo **độ ẩm đất**. Gợi ý chung:\n\n- Cây lá mỏng (lan ý, đuôi công): 3–5 ngày/lần.\n- Cây lá to (trầu bà, bàng Singapore): khoảng 7 ngày/lần.\n- Cây mọng nước (lưỡi hổ, kim tiền, nha đam): 2–3 tuần/lần.\n\nTưới vào buổi sáng, tưới đẫm đến khi nước chảy ra đáy chậu.\n\n${tag("CARE_SCHEDULE", { plantName: "Trầu bà Nam Mỹ", speciesId: "monstera-deliciosa", careType: "watering", intervalDays: 7, preferredTime: "07:00", reason: "Phù hợp nhịp hút nước của cây lá to trong nhà" })}`;
  }
  if (q.includes("ánh sáng") || q.includes("ít sáng") || q.includes("ban công")) {
    return "Với ban công hoặc phòng **ít ánh sáng**, bạn có thể chọn:\n\n- **Kim tiền** (Zamioculcas) — chịu bóng rất tốt, ít tưới.\n- **Lưỡi hổ** — bền, lọc không khí.\n- **Trầu bà vàng** — dễ trồng, có thể treo giỏ.\n- **Lan ý** — vẫn xanh tốt trong bóng râm.\n\n" + tag("RECOMMEND_PRODUCT", { productId: "prd-plant-snake", reason: "Lựa chọn bền bỉ cho góc ít sáng" });
  }
  if (q.includes("sâu") || q.includes("rệp") || q.includes("nhện")) {
    return `Rệp và nhện đỏ thường trú ở mặt dưới lá. Cách xử lý an toàn:\n\n1. Xịt nước mạnh rửa trôi côn trùng.\n2. Lau lá bằng khăn ẩm có pha chút xà phòng sinh học.\n3. Phun dầu neem pha loãng 5–7 ngày/lần.\n\n${tag("RECOMMEND_PRODUCT", { productId: "prd-neem", reason: "Xua đuổi côn trùng chích hút, nguồn gốc thực vật" })}`;
  }
  if (q.includes("bệnh") || q.includes("đốm") || q.includes("nấm")) {
    return `Để xác định đúng bệnh, bạn nên dùng tính năng **Quét bệnh** trong trang chi tiết cây. Trong lúc chờ, hãy:\n\n1. Cách ly cây bệnh.\n2. Cắt bỏ lá bị nặng bằng kéo đã khử trùng.\n3. Tránh tưới lên lá.\n\n${tag("RECOMMEND_PRODUCT", { productId: "prd-fungicide", reason: "Hỗ trợ kiểm soát nấm đốm lá" })}`;
  }
  return "Cảm ơn câu hỏi của bạn! Để tư vấn chính xác hơn, bạn có thể cho mình biết **tên cây**, **vị trí đặt cây** (trong nhà, ban công…) và **hiện tượng** bạn quan sát được không? Gửi kèm ảnh lá sẽ giúp mình phân tích tốt hơn.";
}

const mockAssistant: AssistantService = {
  async listSessions() {
    await latency(100, 220);
    const u = requireUid(session.get());
    return readDb().chatSessions.filter((s) => s.userId === u).sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
  },
  async createSession(title = "Cuộc trò chuyện mới") {
    const u = requireUid(session.get());
    return writeDb((db) => {
      const now = new Date().toISOString();
      const s: ChatSession = { id: uid("chat"), userId: u, title, createdAt: now, updatedAt: now };
      db.chatSessions.push(s);
      return s;
    });
  },
  async renameSession(id, title) {
    const u = requireUid(session.get());
    return writeDb((db) => {
      const s = db.chatSessions.find((x) => x.id === id && x.userId === u);
      if (!s) throw new MockError("Không tìm thấy hội thoại.", "not_found");
      s.title = title;
      return s;
    });
  },
  async deleteSession(id) {
    const u = requireUid(session.get());
    writeDb((db) => {
      db.chatSessions = db.chatSessions.filter((s) => !(s.id === id && s.userId === u));
      db.chatMessages = db.chatMessages.filter((m) => m.sessionId !== id);
    });
  },
  async listMessages(sessionId) {
    await latency(80, 180);
    const u = requireUid(session.get());
    const db = readDb();
    if (!db.chatSessions.some((s) => s.id === sessionId && s.userId === u)) return [];
    return db.chatMessages.filter((m) => m.sessionId === sessionId).sort((a, b) => a.createdAt.localeCompare(b.createdAt));
  },
  async sendMessage(sessionId, content, images) {
    const u = requireUid(session.get());
    const userMsg: ChatMessage = { id: uid("m"), sessionId, role: "user", content, images, createdAt: new Date().toISOString(), status: "sent" };
    writeDb((db) => {
      const s = db.chatSessions.find((x) => x.id === sessionId && x.userId === u);
      if (!s) throw new MockError("Không tìm thấy hội thoại.", "not_found");
      db.chatMessages.push(userMsg);
      if (s.title === "Cuộc trò chuyện mới" && content.trim()) s.title = content.trim().slice(0, 48);
      s.updatedAt = userMsg.createdAt;
    });
    await latency(500, 900);
    const reply = await mockReply(content, images);
    const aiMsg: ChatMessage = { id: uid("m"), sessionId, role: "assistant", content: reply, images: [], createdAt: new Date().toISOString(), status: "sent" };
    writeDb((db) => {
      db.chatMessages.push(aiMsg);
    });
    return [userMsg, aiMsg];
  },
};

const apiAssistant: AssistantService = {
  listSessions: () => http<ChatSession[]>("/assistant"),
  createSession: (title = "Cuộc trò chuyện mới") =>
    http<ChatSession>("/assistant", { method: "POST", json: { action: "create", title } }),
  renameSession: (id, title) =>
    http<ChatSession>("/assistant", { method: "POST", json: { action: "rename", sessionId: id, title } }),
  deleteSession: async (id) => {
    await http("/assistant", { method: "POST", json: { action: "delete", sessionId: id } });
  },
  async listMessages(sessionId) {
    await fetchUserCatalog().catch(() => null);
    return http<ChatMessage[]>(`/assistant?sessionId=${encodeURIComponent(sessionId)}`);
  },
  async sendMessage(sessionId, content, images) {
    await fetchUserCatalog().catch(() => null);
    return http<[ChatMessage, ChatMessage]>("/assistant", {
      method: "POST",
      json: { action: "send", sessionId, content, images },
      timeoutMs: 45000,
    });
  },
};

export const assistantService: AssistantService = isMock() ? mockAssistant : apiAssistant;
