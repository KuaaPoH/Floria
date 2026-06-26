# Nhật Ký Phát Triển Dự Án AgriSmart / BotaniScan
*Ngày cập nhật: 26 tháng 06, 2026*

Tài liệu này ghi lại toàn bộ tiến độ, các công việc đã hoàn thành và định hướng phát triển tiếp theo của hệ thống nhận diện bệnh lá cây trồng thông minh **AgriSmart**.

---

## 1. Tổng Quan Kiến Trúc Dự Án
Hệ thống được thiết kế theo mô hình Microservices bao gồm 3 phần chính:
1.  **AI Engine (Python FastAPI)** - Cổng `8000`: Chịu trách nhiệm tải mô hình TensorFlow/Keras và thực hiện phân tích hình ảnh bệnh lá cây.
2.  **Central Backend (Java Spring Boot)** - Cổng `8080`: Trung tâm điều phối, xác thực người dùng (Firebase Auth), quản lý dữ liệu (Firestore) và đóng vai trò Gateway kết nối với AI Engine.
3.  **Frontend (Flutter Mobile/Web App)** - Chạy debug trên môi trường Edge: Ứng dụng client đa nền tảng cho người dùng tương tác.

---

## 2. Các Công Việc Đã Hoàn Thành (Hôm nay)

### Tầng AI Engine (Python FastAPI)
*   **Khắc phục lỗi Keras 3 Deserialization**: Sửa lỗi do các phiên bản TensorFlow mới (2.16+) không nhận diện hàm Lambda cũ trong file mô hình `.keras`. Đã thêm decorator `@keras.saving.register_keras_serializable()` và đăng ký custom object thành công.
*   **Load thành công 3 mô hình**: Tải mượt mà các mô hình `efficientnetb0`, `mobilenetv2`, và `resnet50v2` khi khởi động server.
*   **Khởi chạy**: Đang chạy nền thành công tại cổng `8000`.

### Tầng Backend (Java Spring Boot)
*   **Tích hợp Firebase mềm dẻo**: Cấu hình Spring Boot để không bị crash khi thiếu file credentials `serviceAccountKey.json`. Backend tự động chuyển sang chế độ Mock/Bỏ qua Firebase nếu chưa được thiết lập.
*   **DiseaseController**: Xây dựng endpoint nhận hình ảnh tải lên từ Client, chuyển tiếp hình ảnh sang AI Engine qua API Multipart, nhận kết quả JSON và trả về cho Frontend.
*   **Khởi chạy**: Đang chạy nền thành công tại cổng `8080`.

### Tầng Frontend (Flutter App)
*   **Thiết lập cấu trúc Feature-first**: Tổ chức code khoa học theo các thư mục `auth`, `home`, `scan`, `profile`, `chatbot`.
*   **Sửa lỗi CORS trên Web**: Thay thế các liên kết ảnh ngoài (như logo Google, logo vương miện) bằng cách tải trực tiếp về thư mục `assets/images/` để trình duyệt không chặn hiển thị.
*   **Hiện thực hóa giao diện tĩnh & Logic điều hướng**:
    *   **Xác thực (Auth)**: Giao diện Đăng ký / Đăng nhập bám sát thiết kế Google Stitch. Đã sửa lỗi chuyển hướng sau khi đăng nhập thành công sang `MainNavigationScreen` (thay vì trực tiếp vào `HomeScreen` chưa cấu hình các nút bấm BottomNavBar), qua đó sửa hoàn toàn lỗi không thể click chuyển các tab từ Trang chủ sang Cá nhân và ngược lại.
    *   **Trang chủ (Home)**: Giao diện khu vườn thông minh, quản lý các khu vực chăm sóc (ban công, phòng khách...).
    *   **Quét bệnh (Scan)**: Giao diện chọn ảnh từ thư viện hoặc chụp ảnh để gửi lên Spring Boot phân tích.
*   **Thiết kế & Tích hợp 3 Màn hình Mới theo thiết kế Google Stitch**:
    *   **Màn hình Cá nhân (`c_nh_n_c_i_t`)**: [profile_screen.dart](file:///D:/Plan/utrasupervip/my_ai_plant_app/lib/features/profile/screens/profile_screen.dart) hiển thị thông tin và quản lý trạng thái tài khoản. Thẻ Premium đổi màu sang vàng kim hoàng gia khi kích hoạt gói PRO.
    *   **Màn hình Nâng cấp Pro (`n_ng_c_p_botaniscan_pro_light_theme`)**: [premium_screen.dart](file:///D:/Plan/utrasupervip/my_ai_plant_app/lib/features/profile/screens/premium_screen.dart) hiển thị bảng so sánh tính năng Free vs PRO, hỗ trợ chọn gói Tháng/Năm.
    *   **Màn hình Thanh toán (`thanhtoan`)**: [payment_screen.dart](file:///D:/Plan/utrasupervip/my_ai_plant_app/lib/features/profile/screens/payment_screen.dart) hỗ trợ thanh toán giả lập qua Credit Card (nhập số thẻ), MoMo, ZaloPay, Apple Pay. Sau khi thanh toán sẽ cập nhật quyền PRO vào `AuthProvider` và quay lại Profile Screen.

---

## 3. Các Công Việc Đã Hoàn Thành (Hôm nay - 24/06/2026)

### Tầng Web Frontend (Next.js & Tailwind CSS)
*   **Khởi tạo & Cấu trúc dự án**: Thiết lập dự án Web hoàn chỉnh với Next.js App Router và Tailwind CSS v4. Đảm bảo giao diện bám sát phong cách thiết kế Glassmorphism hiện đại của mẫu giao diện UI/UX.
*   **Thanh điều hướng thông minh (TopNavBar)**: Tách Navigation Bar thành Client Component để có khả năng nhận biết trang đang hiển thị. Áp dụng thư viện `framer-motion` để tạo hiệu ứng thanh gạch chân trượt mượt mà (sliding animation) giữa các tab trang chủ, khu vườn, chẩn đoán, trợ lý AI và cửa hàng. Xử lý triệt để lỗi con trỏ chuột chọn văn bản khi click vào menu.
*   **Trang Trợ lý AI (AI Assistant)**: Xây dựng bố cục 2 cột (Sidebar lịch sử chat và Khung chat chính). Sửa lỗi giao diện để thanh input tự động giãn nở khi bấm Shift+Enter, ẩn thanh cuộn scrollbar. Đã gỡ bỏ thành công nút "Nâng cấp Ultra" trong code Flutter di động để đồng bộ với Web.
*   **Trang Chẩn Đoán (Diagnostic)**: Tối ưu lại toàn bộ bố cục (Layout) để vừa vặn hoàn hảo trên màn hình (min-h-[calc(100vh-80px)]) mà không bị tràn hay phải cuộn dư thừa. Di chuyển vị trí nút "Bắt Đầu Phân Tích" sang phần cột trái (bên dưới khối chọn Ảnh) để tạo Flow trải nghiệm tự nhiên nhất.
*   **Trang Cá Nhân (Profile)**: Hoàn thiện xây dựng giao diện tổng quan người dùng theo bản mẫu, hiển thị Avatar, gói PRO banner, nhật ký bệnh cây, và hệ thống cài đặt.

### Tầng Mobile App (Flutter)
*   **Dọn dẹp mã nguồn (Refactor Code)**: Phát hiện và xử lý tự động triệt để 145 lỗi cảnh báo (Warnings) trong ứng dụng Flutter Mobile (`my_ai_plant_app`). Đã dùng công cụ `dart fix` và thao tác thủ công để chuyển đổi các API cũ (`.withOpacity()` -> `.withValues()`, `activeColor` -> `activeThumbColor`), làm cho Workspace của IDE hiển thị "0 vấn đề".

---

## 4. Các Công Việc Đã Hoàn Thành (Hôm nay - 25/06/2026)

### Tầng Mobile App / Web App (Flutter - UI/UX & Firebase Auth)
*   **Tinh chỉnh Giao diện (UI/UX) Chẩn đoán:** Khắc phục triệt để lỗi tràn viền (overflow) trên màn hình Báo cáo chẩn đoán (`diagnosis_report_screen.dart`). Xóa bỏ các gradient bóng đen che khuất nội dung, thiết kế lại Avatar tròn tinh tế thay cho ảnh tải mạng (ngăn chặn lỗi link hỏng).
*   **Tích hợp Firebase Auth toàn diện:**
    * Cài đặt và cấu hình thành công Firebase cho các nền tảng thông qua FlutterFire CLI, bao gồm việc bóc tách chứng chỉ `SHA-1/SHA-256` trên môi trường Windows.
    * Tích hợp đăng nhập/đăng ký bằng Email và **Đăng nhập Google 1 chạm**.
    * Xây dựng lại `AuthProvider` (`auth_provider.dart`), kết nối trực tiếp với máy chủ Google, xóa bỏ dữ liệu mock ảo.
    * Xử lý lỗi tương thích Web Client ID trên Flutter Web, ép chạy cố định `port 5000` thông qua `.vscode/launch.json` để Google OAuth 2.0 hoạt động hoàn hảo.
*   **Auto-Routing (Điều hướng thông minh):** Thay đổi `main.dart` bọc `Consumer<AuthProvider>` để tự động đưa người dùng vào `MainNavigationScreen` nếu đã đăng nhập, loại bỏ lỗi điều hướng chồng chéo.

---

## 4.5. Các Công Việc Đã Hoàn Thành (Hôm nay - 26/06/2026)

### Tối ưu Trải nghiệm (UI/UX) và AI Camera
*   **Nâng cấp độ phân giải Camera**: Chuyển đổi từ `medium` sang `veryHigh` (1080p) trong `CameraController` để đảm bảo ảnh chụp lá cây cực kỳ sắc nét, phục vụ tốt nhất cho AI phân tích.
*   **Tối ưu Server tải ảnh**: Tăng giới hạn dung lượng file upload của Spring Boot (`spring.servlet.multipart.max-file-size`) từ 1MB lên 10MB để hỗ trợ xử lý mượt mà các bức ảnh 1080p.
*   **Xử lý lỗi giao diện Android**: Sử dụng thẻ `SafeArea` bọc quanh các nút bấm ở đáy màn hình (`scan_screen.dart` và `diagnosis_report_screen.dart`) để giải quyết triệt để tình trạng các nút bị che khuất bởi thanh điều hướng hệ thống (Navigation Bar) của Android.

### Quản lý Source Code & Không gian làm việc
*   **Thiết lập file Hướng dẫn (README)**: Xây dựng file `README.md` với đầy đủ các lệnh cài đặt và thiết lập nhanh cho cả 4 môi trường: AI (Python), Backend (Java), Mobile (Flutter), Web (Next.js).
*   **Tối ưu kho lưu trữ Git**: Cấu hình lại `.gitignore` siêu chuẩn, khóa chặt các file cấu hình bảo mật Firebase (`google-services.json`, `serviceAccountKey.json`) và chặn việc tải lên thư mục `.venv` của AI.
*   **Làm sạch Git History**: Xử lý triệt để lỗi "100MB limit" của GitHub bằng lệnh `git update-ref -d HEAD` và `git rm --cached`, loại bỏ các file nặng khỏi lịch sử commit, sau đó đẩy thành công toàn bộ source code gọn nhẹ lên kho lưu trữ `KuaaPoH/Floria`.
*   **Dọn dẹp hệ thống**: Phát hiện thùng rác Windows (Recycle Bin) chiếm dụng 1.6GB không gian lưu trữ và hướng dẫn dọn dẹp. Dùng lệnh `attrib +h` để làm ẩn các thư mục template cũ (`fontend_app_temple`, `fontend_web_temple`), giúp không gian IDE gọn gàng hơn.

### Tích hợp Auth, Firestore & Sửa lỗi Môi trường Web
*   **Sửa lỗi trắng màn hình Web**: Khắc phục triệt để lỗi thời gian tải Web chậm và kẹt ở màn hình trắng trên cổng 5000 (đã giải quyết dứt điểm các lỗi xung đột Firebase). Luồng Đăng nhập Google giờ đây mượt mà, không còn độ trễ.
*   **Hoàn thiện luồng Xác thực (Auth)**: Tích hợp và chạy hoàn hảo toàn bộ các luồng Đăng ký, Đăng nhập truyền thống, Đăng nhập 1 chạm với Google (Google SignIn) và tính năng Quên mật khẩu (Forgot Password).
*   **Lưu trữ Firestore**: Đã hoàn thành logic đồng bộ và lưu trữ Lịch sử chẩn đoán (ScanHistory) bệnh cây vào cơ sở dữ liệu thực Firebase Firestore. Đang tạm chờ để thiết kế lại UI phần quét ảnh.
---
## 5. Các Task Đang Chạy Nền (Active Tasks)
*   *Hiện tại tất cả các Background Tasks cho Web và Mobile đã được hoàn thành.*

---

## 6. Kế Hoạch Tiếp Theo (Next Steps - Actionable)

**Bước 1: Nối cáp thông luồng AI thực tế (Ưu tiên cao nhất)**
- Khởi chạy đồng thời 3 hệ thống (AI Engine: 8000, Spring Boot: 8080, Flutter Web).
- Bỏ Mock Data trong `ScanProvider`, test gửi ảnh lá cây để dòng chảy dữ liệu (Flutter -> Java -> Python -> Java -> Flutter) hoạt động trơn tru.
- Tích hợp bộ giao diện Quét ảnh mới (sau khi thiết kế lại xong).

**Bước 2: Đánh thức Trợ lý Ảo (AI Chatbot - Gemini)**
- Tích hợp Gemini API vào thư mục `lib/features/chatbot/` trên Flutter/Web để trả lời tư vấn cây trồng.

**Bước 3: Hoàn thiện Cửa hàng (Shop & Payment)**
- Xử lý logic Giỏ hàng.
- Nối API thanh toán đơn giản cho các màn hình UI đã code sẵn ở profile.
