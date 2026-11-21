import { NextResponse } from "next/server";
import { AdminAuthError, verifyAdminRequest } from "@/lib/server/admin-auth";
import { getAdminDb } from "@/lib/server/firebase-admin";
import { toIsoString } from "@/lib/server/firestore-utils";

export interface SupportArticle {
  id: string;
  category: string;
  categoryVi: string;
  categoryEn: string;
  questionVi: string;
  questionEn: string;
  answerVi: string;
  answerEn: string;
  order: number;
  visible: boolean;
  updatedAt: string;
}

const DEFAULT_SUPPORT_ARTICLES: Omit<SupportArticle, "id" | "updatedAt">[] = [
  {
    category: "scan",
    categoryVi: "Quét ảnh & Chẩn đoán AI",
    categoryEn: "Photo Scan & AI Diagnosis",
    questionVi: "Làm sao để chụp ảnh lá cho kết quả chính xác nhất?",
    questionEn: "How to take the most accurate leaf photo?",
    answerVi:
      "• Chụp ở nơi đủ sáng tự nhiên, tránh ánh nắng gắt hoặc đèn flash chói.\n• Đưa lá bệnh vào giữa khung hình, cách khoảng 15–30 cm, giữ máy thật chắc để ảnh không bị mờ.\n• Chỉ chụp 1 lá hoặc 1 cụm lá, nền phía sau càng đơn giản càng tốt.\n• Nên chụp mặt có vết bệnh rõ nhất (đốm, vàng, cháy mép...).",
    answerEn:
      "• Take photos in natural lighting, avoid harsh sunlight or direct flash.\n• Place the affected leaf in the center, 15–30 cm away, keep steady to avoid blur.\n• Capture 1 leaf or cluster, keep background as simple as possible.\n• Focus on the clearest symptom area (spots, yellowing, edge burn...).",
    order: 1,
    visible: true,
  },
  {
    category: "scan",
    categoryVi: "Quét ảnh & Chẩn đoán AI",
    categoryEn: "Photo Scan & AI Diagnosis",
    questionVi: "AI của Floria nhận diện được những gì?",
    questionEn: "What can Floria AI recognize?",
    answerVi:
      "Floria dùng mô hình EfficientNetV2 để nhận diện loài cây và các bệnh lá phổ biến trên cây trồng, cây cảnh. Độ chính xác đạt khoảng 90% với loài cây và 92,5% với bệnh lá trên bộ dữ liệu kiểm thử. Với các loài hiếm hoặc ảnh chất lượng thấp, kết quả có thể chưa chính xác.",
    answerEn:
      "Floria uses an EfficientNetV2 model to recognize plant species and common leaf diseases. Accuracy reaches ~90% on plant species and 92.5% on leaf diseases on test datasets. For rare species or low-quality photos, results may vary.",
    order: 2,
    visible: true,
  },
  {
    category: "scan",
    categoryVi: "Quét ảnh & Chẩn đoán AI",
    categoryEn: "Photo Scan & AI Diagnosis",
    questionVi: "Kết quả chẩn đoán có kèm hướng dẫn chữa trị không?",
    questionEn: "Do diagnosis results include treatment guides?",
    answerVi:
      "Có. Mỗi kết quả chẩn đoán đều có báo cáo gồm nguyên nhân, triệu chứng, cách xử lý và phòng ngừa. Bạn cũng có thể bấm hỏi thêm Trợ lý Floria để được tư vấn chi tiết theo đúng cây của mình.",
    answerEn:
      "Yes. Every diagnosis includes causes, symptoms, treatment, and prevention. You can also consult Floria Assistant for personalized care instructions.",
    order: 3,
    visible: true,
  },
  {
    category: "scan",
    categoryVi: "Quét ảnh & Chẩn đoán AI",
    categoryEn: "Photo Scan & AI Diagnosis",
    questionVi: "Vì sao ảnh của tôi không nhận diện được hoặc kết quả sai?",
    questionEn: "Why was my photo not recognized or inaccurate?",
    answerVi:
      'Nguyên nhân thường gặp: ảnh bị mờ/thiếu sáng, lá quá nhỏ trong khung hình, chụp cả chậu cây thay vì lá, hoặc loài cây chưa có trong dữ liệu. Hãy chụp lại theo hướng dẫn và kiểm tra kết nối mạng. Các lần quét được lưu trong mục "Lịch sử quét" để bạn so sánh lại.',
    answerEn:
      "Common reasons: blurry/low-light photo, leaf too small, whole pot photographed instead of leaf, or species not yet supported. Try capturing again with proper lighting and check network connection.",
    order: 4,
    visible: true,
  },
  {
    category: "care",
    categoryVi: "Lịch chăm sóc & Nhắc nhở",
    categoryEn: "Care Schedule & Reminders",
    questionVi: "Tại sao tôi không thấy thông báo nhắc tưới cây?",
    questionEn: "Why am I not receiving watering reminder notifications?",
    answerVi:
      'Hiện tại Floria nhắc nhở bằng thông báo hệ thống và banner hiển thị trong ứng dụng. Hãy kiểm tra: (1) đã bật "Nhắc nhở" trong mục Nhắc tưới, (2) không nằm trong khung giờ Không làm phiền, (3) đã qua giờ nhắc của cây đó trong ngày.',
    answerEn:
      "Currently Floria displays system notifications and in-app reminder banners. Please verify: (1) Reminders are enabled in Reminders Hub, (2) Not in Do Not Disturb hours, (3) The scheduled time has passed for today.",
    order: 5,
    visible: true,
  },
  {
    category: "care",
    categoryVi: "Lịch chăm sóc & Nhắc nhở",
    categoryEn: "Care Schedule & Reminders",
    questionVi: "Lỡ quên tưới cây vài ngày thì lịch có bị sai không?",
    questionEn: "If I miss watering for a few days, will the schedule break?",
    answerVi:
      'Không. Cây sẽ chuyển sang trạng thái "Cần tưới nước" và hiện trong danh sách việc cần làm. Khi bạn bấm hoàn thành, chu kỳ tiếp theo sẽ được tính lại từ thời điểm bạn thực sự tưới.',
    answerEn:
      'No. The plant will switch to "Needs Water" and appear in your task list. When you mark it completed, the next cycle will calculate from your actual watering date.',
    order: 6,
    visible: true,
  },
  {
    category: "care",
    categoryVi: "Lịch chăm sóc & Nhắc nhở",
    categoryEn: "Care Schedule & Reminders",
    questionVi: "Làm sao để đổi chu kỳ tưới hoặc giờ nhắc của một cây?",
    questionEn: "How do I change the watering frequency or reminder time for a plant?",
    answerVi:
      "Vào Khu vườn → chọn cây → mục Lịch chăm sóc để chỉnh số ngày tưới, bón phân, kiểm tra sâu bệnh và giờ nhắc riêng. Giờ nhắc mặc định cho cây mới thêm được chỉnh trong Cá nhân → Nhắc tưới.",
    answerEn:
      "Go to Garden → select plant → Care Schedule to adjust watering, fertilizing, pest check intervals and specific reminder times.",
    order: 7,
    visible: true,
  },
  {
    category: "account",
    categoryVi: "Tài khoản & Mua sắm",
    categoryEn: "Account & Shopping",
    questionVi: "Tôi muốn đổi mật khẩu thì làm thế nào?",
    questionEn: "How can I change my password?",
    answerVi:
      "Vào Cá nhân → Cài đặt → Đổi mật khẩu, Floria sẽ gửi đường dẫn đặt lại mật khẩu về email của bạn. Nếu bạn đăng nhập bằng Google, mật khẩu được quản lý bởi tài khoản Google nên không đổi trong ứng dụng.",
    answerEn:
      "Go to Profile → Settings → Change Password. Floria will email you a password reset link. If you signed in with Google, credentials are managed by Google.",
    order: 8,
    visible: true,
  },
  {
    category: "account",
    categoryVi: "Tài khoản & Mua sắm",
    categoryEn: "Account & Shopping",
    questionVi: "Thanh toán COD và thanh toán trực tuyến khác nhau thế nào?",
    questionEn: "What is the difference between COD and online payment?",
    answerVi:
      "COD (thanh toán khi nhận hàng): bạn trả tiền mặt cho người giao hàng. Thanh toán trực tuyến: thanh toán qua cổng ZaloPay Sandbox ngay khi đặt hàng.",
    answerEn:
      "COD (Cash on Delivery): pay cash upon delivery. Online payment: pay via ZaloPay Sandbox gateway when placing an order.",
    order: 9,
    visible: true,
  },
  {
    category: "account",
    categoryVi: "Tài khoản & Mua sắm",
    categoryEn: "Account & Shopping",
    questionVi: "Vật tư mua trên Floria có được đổi trả không?",
    questionEn: "Can garden supplies purchased on Floria be returned?",
    answerVi:
      "Sản phẩm lỗi, hư hỏng do vận chuyển hoặc giao sai được hỗ trợ đổi trả. Vui lòng liên hệ bộ phận hỗ trợ kèm ảnh sản phẩm và mã đơn hàng để được xử lý nhanh nhất.",
    answerEn:
      "Defective products or transit damages are eligible for return/replacement. Please contact support with photos and order code for prompt resolution.",
    order: 10,
    visible: true,
  },
];

function mapDoc(id: string, d: Record<string, unknown>): SupportArticle {
  return {
    id,
    category: String(d.category ?? "other"),
    categoryVi: String(d.categoryVi ?? "Hỗ trợ chung"),
    categoryEn: String(d.categoryEn ?? "General Support"),
    questionVi: String(d.questionVi ?? ""),
    questionEn: String(d.questionEn ?? ""),
    answerVi: String(d.answerVi ?? ""),
    answerEn: String(d.answerEn ?? ""),
    order: Number(d.order ?? 0),
    visible: d.visible !== false,
    updatedAt: toIsoString(d.updatedAt),
  };
}

export async function GET(req: Request) {
  try {
    await verifyAdminRequest(req);
    const db = getAdminDb();
    const col = db.collection("SupportArticles");
    let snap = await col.get();

    // Khởi tạo dữ liệu gốc vào Firestore nếu collection chưa có bài viết nào
    if (snap.empty) {
      const now = new Date().toISOString();
      const batch = db.batch();
      DEFAULT_SUPPORT_ARTICLES.forEach((item, idx) => {
        const ref = col.doc(`sup_${idx + 1}`);
        batch.set(ref, { ...item, updatedAt: now });
      });
      await batch.commit();
      snap = await col.get();
    }

    const list = snap.docs
      .map((doc) => mapDoc(doc.id, doc.data()))
      .sort((a, b) => a.order - b.order);

    return NextResponse.json(list);
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tải danh sách bài viết hỗ trợ" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    await verifyAdminRequest(req);
    const body = (await req.json()) as Partial<SupportArticle>;
    if (!body.questionVi?.trim() || !body.answerVi?.trim()) {
      return NextResponse.json({ error: "Vui lòng nhập tiêu đề câu hỏi và nội dung trả lời" }, { status: 400 });
    }

    const docId = body.id?.trim() || `sup_${Date.now()}`;
    const payload: Omit<SupportArticle, "id"> = {
      category: body.category?.trim() || "other",
      categoryVi: body.categoryVi?.trim() || "Hỗ trợ chung",
      categoryEn: body.categoryEn?.trim() || "General Support",
      questionVi: body.questionVi.trim(),
      questionEn: body.questionEn?.trim() || body.questionVi.trim(),
      answerVi: body.answerVi.trim(),
      answerEn: body.answerEn?.trim() || body.answerVi.trim(),
      order: Number(body.order ?? 100),
      visible: body.visible !== false,
      updatedAt: new Date().toISOString(),
    };

    await getAdminDb().collection("SupportArticles").doc(docId).set(payload, { merge: true });
    return NextResponse.json({ id: docId, ...payload }, { status: 201 });
  } catch (err) {
    if (err instanceof AdminAuthError) {
      return NextResponse.json({ error: err.message }, { status: err.status });
    }
    return NextResponse.json({ error: "Không thể tạo bài viết hỗ trợ" }, { status: 500 });
  }
}
