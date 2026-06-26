# 🗺️ LỘ TRÌNH TRIỂN KHAI ĐỒ ÁN (WORKFLOW)

Chúc mừng bạn đã chinh phục xong phần khó khăn nhất và mang đậm tính hàn lâm nhất của đồ án: **Huấn luyện mô hình AI (Giai đoạn 1)**!

Dưới đây là sơ đồ chiến thuật từng bước (Step-by-step Workflow) để biến các mô hình AI vô tri trở thành một hệ thống phần mềm Microservices hoàn chỉnh, có thể mang đi demo và thuyết trình trước hội đồng.

---

## 🟢 GIAI ĐOẠN 1: Kích hoạt Lõi AI (Đang thực hiện)
*Mục tiêu: Đưa mô hình AI chạy thực tế trên máy tính thông qua API.*

1. **[Người dùng]** Tải 3 file mô hình `best_..._model.keras` và file `labels.txt` từ Google Drive về máy tính.
2. **[Người dùng]** Chép các file vừa tải vào thư mục `utrasupervip/AI_Engine/models/`.
3. **[Hệ thống]** Cài đặt các thư viện Python: `pip install -r requirements.txt`.
4. **[Hệ thống]** Chạy thử máy chủ AI Engine bằng lệnh: `python main.py` (Khởi chạy trên cổng 8000).

> [!TIP]
> Chỉ cần máy chủ AI khởi chạy thành công và báo "✅ Đã tải xong mô hình", bạn đã nắm chắc trong tay cốt lõi của đề tài!

---

## 🟡 GIAI ĐOẠN 2: Thiết lập Bộ não Lưu trữ (Firebase)
*Mục tiêu: Xây dựng cơ sở dữ liệu và hệ thống quản lý tài khoản trên Cloud (Đỡ phải cài SQL Server nặng nề).*

1. **[Người dùng]** Truy cập [Firebase Console](https://console.firebase.google.com/), tạo một Project mới (Ví dụ: `PlantDiseaseAI`).
2. **[Hệ thống]** Kích hoạt **Authentication** (Cho phép người dùng Đăng nhập bằng Email/Password hoặc Google).
3. **[Hệ thống]** Kích hoạt **Cloud Firestore** (Tạo Database để lưu thông tin bệnh, nguyên nhân, cách chữa trị và Lịch sử quét của người dùng).
4. **[Hệ thống]** Xuất khóa bí mật `serviceAccountKey.json` để chuẩn bị nối vào Backend.

---

## 🟠 GIAI ĐOẠN 3: Phát triển Máy chủ Trung tâm (Java Spring Boot)
*Mục tiêu: Đứng giữa làm trung gian điều phối App, Firebase và AI Engine.*

1. **[Hệ thống]** Khởi tạo dự án Java Spring Boot.
2. **[Hệ thống]** Tích hợp **Firebase Admin SDK** vào Java (Để kiểm tra người dùng đã đăng nhập thật chưa).
3. **[Hệ thống]** Xây dựng API luồng chính: `POST /api/scan-disease`.
   * **Bước 3.1:** App gửi ảnh + Token đăng nhập lên Spring Boot.
   * **Bước 3.2:** Spring Boot kiểm tra Token hợp lệ.
   * **Bước 3.3:** Spring Boot bắn ảnh đó sang `http://localhost:8000/predict` (AI Engine Python).
   * **Bước 3.4:** Python trả về tên bệnh (VD: "Đốm vi khuẩn").
   * **Bước 3.5:** Spring Boot tìm cách chữa trị trong Firebase và lưu lịch sử quét ảnh.
   * **Bước 3.6:** Trả kết quả hoàn chỉnh về cho App hiển thị.

> [!IMPORTANT]
> Đây là minh chứng rõ nét nhất cho **Kiến trúc Microservices** - điểm cộng tuyệt đối cho sinh viên Software Engineering!

---

## 🔵 GIAI ĐOẠN 4: Giao diện Người dùng (Mobile App / Web)
*Mục tiêu: Đóng gói sản phẩm để Demo.*

1. **[Hệ thống]** Dựng khung giao diện (UI) bằng Android Studio (Java/Kotlin), Flutter hoặc Web (React/HTML).
2. **[Hệ thống]** Thiết kế luồng Đăng nhập / Đăng ký qua Firebase.
3. **[Hệ thống]** Màn hình Trang chủ: Nút chụp ảnh / Tải ảnh từ thư viện.
4. **[Hệ thống]** Gửi ảnh lên API của Spring Boot và hiển thị hoạt ảnh Loading.
5. **[Hệ thống]** Màn hình Kết quả: Hiển thị tên bệnh, phần trăm tự tin (Confidence), và thông tin lời khuyên cách chữa trị.

> [!NOTE]
> Cả quá trình từ Giai đoạn 2 đến Giai đoạn 4 mình sẽ trực tiếp code cùng bạn trên máy, bạn chỉ cần điều khiển và chỉnh sửa theo ý mình.
