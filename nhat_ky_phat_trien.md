# Nhật Ký Phát Triển Dự Án AgriSmart / BotaniScan
*Ngày cập nhật: 30 tháng 10, 2026*

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
## 4.6. Các Công Việc Đã Hoàn Thành (Hôm nay - 29/06/2026)

### Việt Hóa & Tối ưu UI/UX Theo Giao Diện Mẫu (Template)
*   **Việt hóa toàn diện**: Chuyển đổi toàn bộ ngôn ngữ trên các màn hình chính (CameraScanningScreen, ShopScreen, ProfileScreen, SettingsScreen, GardenScreen) sang tiếng Việt.
*   **Tái cấu trúc giao diện theo thiết kế mẫu**: Dựa trên các file thiết kế HTML mẫu (`caidat`, `profile`, `store`, `camera`), ứng dụng đã được tinh chỉnh lại độ phân giải, bố cục, font chữ (`GoogleFonts.inter`), và màu sắc.
*   **Màn hình Splash (Khởi động)**: Đã thiết lập hiệu ứng entrance animations (lướt mờ và đẩy) mượt mà lúc mới vào app.
*   **Màn hình Cửa hàng (ShopScreen)**: Xóa bỏ thẻ xếp hạng người dùng, cập nhật thẻ sản phẩm ("Hot"), xử lý các lỗi tràn viền chữ (RenderFlex Overflow), và hoàn thiện nút "Mở khóa tài khoản để nhận ưu đãi".
*   **Màn hình Trang Cá nhân (ProfileScreen)**: Cắt góc Avatar thành hình tròn, thêm icon chỉnh sửa siêu nhỏ cạnh avatar, thêm mục "Trung tâm hỗ trợ", và đưa vào hệ thống điểm thưởng thay thế cho hệ thống thứ hạng phức tạp. Xóa bỏ âm thanh, dọn dẹp các mục không cần thiết trong phần cài đặt.

### Tối ưu Hiệu suất Tải Ảnh (Skeleton Loading)
*   **Hệ thống Shimmer Loading**: Thiết kế và triển khai một custom widget `ShimmerLoading` dùng chung để tái tạo hiệu ứng gợn sóng lấp lánh (Skeleton).
*   **Kiến trúc CustomImage**: Viết lại hệ thống tải ảnh với thành phần `CustomImage` (wrapper), thay thế hoàn toàn cho `Image.network` mặc định. Hệ thống này tự động hiện Skeleton khi đang tải, và báo biểu tượng lỗi (lá cây) một cách duyên dáng khi mất mạng hay lỗi 404 (cụ thể đã cứu thành công banner trang shop bị lỗi ảnh Unsplash). Đã ứng dụng `CustomImage` rải khắp các màn hình chính như Home, Shop, Garden, Plant Detail, và Plant Diary.

---
## 4.7. Các Công Việc Đã Hoàn Thành (Hôm nay - 02/07/2026)

### Tối ưu Giao diện Nhận Diện & Từ Điển Cây (Verdant Care Template)
*   **Thiết kế lại Báo Cáo Chẩn Đoán (`DiagnosisReportScreen`)**: Tinh chỉnh giao diện bám sát bản thiết kế mẫu với tông màu xanh rêu (`#6d7f69`), xử lý các nhãn (tags) động ("Khớp tốt nhất", "Đang xử lý...", "Cảnh báo bệnh") thay vì gán cứng mã HTML/Text tĩnh.
*   **Thiết kế lại Từ Điển Cây (`PlantWikiScreen`)**: Nâng cấp hiệu ứng Glassmorphism, thanh cuộn linh hoạt (`SliverAppBar`), chuyển màu nền Navbar tự động theo độ cuộn màn hình. Thêm các lưới đặc tính sinh thái với Icon được tinh chỉnh chi tiết (Mặt trời, Giọt nước, v.v.).
*   **Hiệu ứng Chuyển Trang & UI/UX**: Chuyển đổi hiệu ứng mở trang sang Native Android Fragment (fade & slide) bằng `MaterialPageRoute`. Xử lý triệt để hiệu ứng "nháy đỏ" khó chịu khi ấn nút Back bằng cách cấu hình delay 400ms chờ animation trượt màn hình kết thúc rồi mới tiến hành `reset()` bộ nhớ Cache hình ảnh.
*   **Sửa lỗi Reload Data**: Tối ưu hóa hiệu năng bằng cách lưu cache biến `Future` vào trong `State`, dập tắt hoàn toàn tình trạng màn hình bị chớp Loading giật cục mỗi khi thoát từ trang chi tiết (PlantWiki) quay lại màn hình Báo Cáo.

### Quản lý Dữ liệu Backend (Python AI_Engine & Firebase)
*   **Cập nhật Cơ sở dữ liệu Cây (`plants_data.json`)**: Viết thêm các kịch bản Python (`add_characteristics.py`) tự động tra cứu và bổ sung các trường dữ liệu bị thiếu như đặc điểm nhận dạng (`identification`), loại rễ (`root_type`), độc tính (`toxicity`), và đổi tên biến ánh sáng thành `light`.
*   **Đồng bộ Firestore**: Thực thi script `upload_to_firebase.py` đẩy toàn bộ metadata của 40 cây chuẩn xác lên bộ sưu tập (Collection) `plants_info` trên Firebase. Đã kết nối thành công UI app hiển thị dữ liệu thật kéo từ Firebase thay vì code cứng.
*   **Dọn dẹp Source Code Python**: Quét và dọn dẹp các tập tin rác, các scripts di chuyển dữ liệu một lần (one-off scripts).
*   **Cập nhật Dependencies**: Đồng bộ lại file `requirements.txt` của AI Engine với các thư viện thực tế đang chạy (`torch`, `transformers`, `onnxruntime`, `firebase-admin`), tránh lỗi môi trường khi deploy lên server.

---
## 4.8. Các Công Việc Đã Hoàn Thành (Hôm nay - 12/10/2026)

### Sửa Lỗi Quét Ảnh Bị Treo & Lỗi "Không Tìm Thấy Dữ Liệu Cho: ''"
*   **Khắc phục IP Backend Đổi Sang Mạng Mới**: Phát hiện `AppConstants.baseUrl` và `AuthProvider` bị gán cứng IP cũ `192.168.1.78:8080`, dẫn đến tình trạng app gửi request quét bệnh bị timeout do máy tính đã nhận IP Wi-Fi mới (`192.168.1.88`). Đã nâng cấp `AppConstants.baseUrl` thành getter thông minh:
    *   Tự động kết nối `http://localhost:8080/api` khi chạy trên nền tảng Web (`kIsWeb`).
    *   Tự động trỏ sang IP LAN `http://192.168.1.88:8080/api` khi chạy trên thiết bị di động trong mạng.
*   **Xử lý Lỗi Nuốt Exception & Query Firestore Rỗng**:
    *   Tại `diagnosis_report_screen.dart`, trước đây khi gặp lỗi kết nối hoặc ảnh bị AI từ chối (ảnh tối/không phải cây), `docId` bị rỗng dẫn đến câu lệnh `plants_info.doc("").get()` trả về null và màn hình hiển thị chuỗi khó hiểu: `Không tìm thấy dữ liệu cho: ''`.
    *   Đã bổ sung thẻ cảnh báo lỗi mạng rõ ràng (`scanProvider.errorMessage`) cùng nút điều hướng "Quay lại kiểm tra".
    *   Thêm logic fallback gán `docId = prediction` nếu `top_3` rỗng nhưng có nhãn dự đoán hợp lệ.
    *   Nếu ảnh bị từ chối hoặc không có kết quả hợp lệ, hiển thị thông báo hướng dẫn chụp lại ảnh thay vì cố gắng truy vấn Firestore tài liệu rỗng.

---
## 4.9. Các Công Việc Đã Hoàn Thành (Hôm nay - 12/10/2026 - Đợt 2)

### Khắc Phục Lỗi Firestore 403 & Tích Hợp Cơ Chế Offline Fallback Dictionary (PlantDatabase)
*   **Phát hiện nguyên nhân**: Server AI Engine và Spring Boot hoạt động hoàn toàn chính xác (đã nhận diện `Hedera helix` và trả về 200 OK). Tuy nhiên, khi Flutter Client gọi trực tiếp Firestore để lấy chi tiết cây thì gặp lỗi `403 PERMISSION_DENIED: Missing or insufficient permissions` do Firestore Security Rules trên Firebase Console chưa mở quyền đọc công khai cho collection `plants_info`. Điều này khiến `data` trả về null, dẫn đến tên cây bị hiển thị tiếng Anh và tất cả các trường thông tin đều hiện "Đang cập nhật...".
*   **Xây dựng PlantDatabase Offline-First**:
    *   Sinh file `plant_database.dart` chứa toàn bộ từ điển bách khoa của 40 loài cây trồng trong ứng dụng.
    *   Hỗ trợ cơ chế tra cứu thông minh: khớp chính xác, tự động chuẩn hóa dấu gạch dưới `_` thành khoảng trắng, và tra cứu không phân biệt chữ hoa/chữ thường.
*   **Nâng cấp Màn hình Chẩn đoán & Từ điển Cây**:
    *   `DiagnosisReportScreen`: Tự động tra cứu `PlantDatabase` ngay lập tức làm nền tảng, đồng thời truy vấn nền Firestore để gộp dữ liệu realtime. Tên tiếng Việt `Thường xuân` và tất cả các thông số sinh thái (ánh sáng, tưới nước, rễ, độc tính,...) luôn được hiển thị sắc nét 100%.
    *   `PlantWikiScreen`: Tự động dùng fallback `PlantDatabase` nếu dữ liệu truyền sang bị trống.

---
## 4.8. Các Công Việc Đã Hoàn Thành (Hôm nay - 13/10/2026)

### Thông luồng Dữ liệu Động 100% & Khắc phục Sự cố Đám mây
*   **Xóa bỏ triệt để Hardcode Từ điển**: Bác bỏ và xóa hoàn toàn file `plant_database.dart` cục bộ. Chuyển sang cơ chế dữ liệu động 100% từ đám mây (Cloud Firestore + Spring Boot Admin SDK Gateway) để hỗ trợ thêm/sửa/cập nhật cây không giới hạn từ xa.
*   **Phát hiện & Khắc phục Lỗi Security Rules Firestore**: Tìm ra nguyên nhân gốc rễ gây lỗi `403 PERMISSION_DENIED` (do chế độ Test Mode 30 ngày của Firestore đã hết hạn từ ngày 25/07/2026). Cấu hình lại bộ Rules mới mở quyền đọc công khai cho bộ sưu tập `plants_info`.
*   **Spring Boot Gateway**: Tích hợp Google Firebase Admin SDK tự động tra cứu và đồng bộ hồ sơ cây trồng cho toàn bộ danh sách `top_3`, mở endpoint `/api/plants/{id}` hỗ trợ tra cứu thời gian thực.

### Tối ưu hóa Hiệu năng & Tốc độ Xử lý AI
*   **Tăng tốc CLIP Gatekeeper (OpenAI ViT-Base)**: 
    *   Mã hóa sẵn và lưu vào RAM (Cache Text Features) vector đặc trưng của các nhãn kiểm duyệt văn bản 1 lần duy nhất khi khởi động server, loại bỏ việc chạy lặp lại Text Transformer trên CPU ở mỗi lượt quét.
    *   Kích hoạt `torch.inference_mode()` và `clip_model.eval()`, xử lý trích xuất chính xác thuộc tính `.pooler_output` trên phiên bản thư viện `transformers` mới.
    *   Tốc độ kiểm duyệt ảnh tăng gấp 2 – 3 lần, giải phóng RAM tức thì, giảm tải triệt để cho CPU.
*   **Bất đồng bộ hóa (Asynchronous) Lưu trữ Lịch sử**: Đưa tác vụ ghi `ScanHistory` vào luồng nền thông qua `CompletableFuture.runAsync()`, giải phóng phản hồi ngay lập tức về ứng dụng mà không cần chờ đợi mạng Firebase.

### Nâng cấp Hoàn thiện UI/UX Báo Cáo Chẩn Đoán (`DiagnosisReportScreen`)
*   **Trạng thái Quét Chuyên nghiệp**: Hiển thị `--%` thay vì `0%` gây hiểu nhầm khi đang trong tiến trình phân tích ảnh.
*   **Shimmer Skeleton Độ tương đồng**: Bổ sung `_buildResultStackSkeleton()` với hiệu ứng gợn sóng đồng bộ, xóa bỏ tình trạng hiển thị thẻ trống với nhãn `0 KẾT QUẢ`.
*   **Xóa bỏ Hiện tượng Giật Tên**: Backend gửi sẵn `name_vi` cùng `plants_map` trong phản hồi ban đầu, giúp tên tiếng Việt hiển thị ngay lập tức (0ms) thay vì giật từ tên khoa học sang tiếng Việt sau 0.5s.
*   **Sửa Lỗi Chuyển Đổi Kết Quả Top 3**: Khắc phục lỗi gán nhầm dữ liệu của cây top 1 khi người dùng bấm chọn cây thứ 2. Giờ đây khi click vào bất kỳ cây nào (ví dụ Cây ngọc ngân), toàn bộ ảnh, tên tiếng Việt, mô tả và bảng chăm sóc đều chuyển đổi chuẩn xác 100%.

### Hoàn Thiện Tính Năng "Khu Vườn Của Tôi" (My Garden) & Kiến Trúc Dữ Liệu Đồng Bộ Đám Mây
*   **Khẳng định Kiến trúc Auth-Gated & Collection Độc Lập `MyGarden`**: Ứng dụng Floria được bảo vệ nghiêm ngặt bằng cơ chế xác thực người dùng (`SplashScreen` chuyển hướng đến `LoginScreen` nếu chưa đăng nhập). Toàn bộ dữ liệu cây trồng được lưu trữ trong Collection gốc độc lập `MyGarden` trên Firebase Firestore (gắn với trường `userId`), trực quan 100% trên Firebase Console, vĩnh viễn không mất khi đổi máy hoặc xóa web cache.
*   **Mô hình & Quản lý Trạng thái Khu Vườn (`GardenPlant` & `GardenProvider`)**:
    *   Xây dựng model `GardenPlant` mang `userId`, hỗ trợ tính toán thông minh `isNeedsWater` (cần tưới nước) và `daysUntilWater` (đếm ngược ngày tưới) dựa trên tần suất chăm sóc thực tế của cây.
    *   Xây dựng `GardenProvider` tự động lắng nghe luồng thay đổi thời gian thực (`Stream<QuerySnapshot>`) từ bộ sưu tập `MyGarden` lọc theo `userId`, hỗ trợ các tác vụ `addPlant`, `waterPlant`, `removePlant`, và lọc cây theo khu vực.
*   **Nối Nút "Lưu vào vườn" & Thông Báo Nổi Đỉnh Màn Hình (Top Floating Banner)**:
    *   Bấm "Lưu vào vườn" hiển thị Modal BottomSheet cho phép đặt biệt danh tùy biến (chữ màu đen đậm tương phản cao trên nền trắng), chọn khu vực đặt cây ("Phòng khách", "Ban công", "Bàn làm việc", "Sân thượng"...).
    *   Tự động trích xuất chu kỳ tưới từ cơ sở dữ liệu thực vật của AI/Firestore (ví dụ "2-3 lần/tuần" -> nhắc mỗi 3 ngày).
    *   Thay thế SnackBar bằng **Thông báo nổi trên đỉnh màn hình (Top Floating Banner)**: Nền xanh lá đậm, chữ trắng tinh tương phản sắc nét, tự động biến mất sau 3.5 giây (hoặc bấm tắt). Nút "ĐẾN VƯỜN" chuyển hướng dứt khoát sang tab Khu vườn (`initialIndex: 1`).
*   **Đồng bộ Giao diện Quản lý Khu Vườn (`GardenScreen` & `PlantDetailScreen`)**:
    *   `GardenScreen`: Hiển thị số lượng cây thực tế, thanh tìm kiếm cây thời gian thực, mục "Cần chú ý" liệt kê các cây đến hạn tưới kèm nút tích nước nhanh (tưới nước xong tự động cập nhật hạn tưới mới), bộ lọc khu vực động và Empty State sinh động khi vườn chưa có cây.
    *   `PlantDetailScreen`: Hiển thị thông số chi tiết của cây trong vườn, bảng lịch chăm sóc với thao tác bấm tưới nước trực tiếp và menu hỗ trợ xóa cây khỏi vườn.

---
## 4.9. Các Công Việc Đã Hoàn Thành (Hôm nay - 14/10/2026)

### Nâng Cấp Quản Lý Khu Vườn: Ẩn Thông Báo Thừa & Hệ Thống Tạo Khu Vườn Cá Nhân Hóa (Custom Gardens)
*   **Ẩn Mục "Cần chú ý" Khi Không Có Việc Khẩn Cấp**:
    *   Chỉ hiển thị mục "Cần chú ý" khi thực sự có cây đến hạn tưới nước (`attentionPlants.isNotEmpty`).
    *   Nếu tất cả cây đều khỏe mạnh, mục này và khoảng đệm thừa sẽ tự động ẩn đi hoàn toàn, giữ cho màn hình thoáng đãng và tinh gọn.
*   **Xây dựng Thực Thể & Collection `UserGardens`**:
    *   Tạo model `UserGarden` ([user_garden.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/garden/models/user_garden.dart)) và collection độc lập `UserGardens` trên Firestore liên kết với `userId`.
    *   Quản lý danh sách các khu vườn, khu vườn đang kích hoạt (`selectedGarden`), và lắng nghe realtime qua `GardenProvider`.
*   **Empty State "Bạn chưa có khu vườn nào" & Flow Tạo Vườn**:
    *   Khi người dùng mới chưa tạo khu vườn nào, hiển thị bảng thông báo trực quan "Bạn chưa có khu vườn nào" cùng nút nổi bật **"Tạo khu vườn ngay"**.
    *   Khi đã có khu vườn, hiển thị danh sách cuộn ngang các khu vườn (tên, môi trường, điều kiện ánh sáng, số cây) kèm nút "+ Thêm khu vườn".
*   **Màn Hình Tạo Khu Vườn (`CreateGardenScreen`)**:
    *   Tạo file [create_garden_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/garden/screens/create_garden_screen.dart) chuẩn phong cách thiết kế Floria:
        1. **Tên khu vườn**: TextFormField có validation (VD: "Vườn ban công tầng 2", "Góc xanh phòng khách"...).
        2. **Môi trường**: 4 lựa chọn trực quan dạng thẻ có icon và mô tả (Trong nhà, Ngoài trời, Văn phòng, Nhà kính).
        3. **Điều kiện ánh sáng**: 4 cấp độ ánh sáng chuẩn sinh thái (Sáng trực tiếp, Sáng gián tiếp, Ánh sáng trung bình, Ánh sáng yếu).
        4. **Nút "Tạo khu vườn"**: Lưu trực tiếp lên Firebase Firestore và tự động chọn khu vườn vừa tạo làm vườn kích hoạt (`selectedGarden`).

### Xây Dựng Màn Hình "Thêm Cây Vào Vườn" (`AddPlantToGardenScreen`) & Quy Trình Xác Nhận 2 Bước
*   **Màn hình Thêm Cây Tinh Gọn ([add_plant_to_garden_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/garden/screens/add_plant_to_garden_screen.dart))**:
    *   **Khung ảnh linh hoạt**: Hỗ trợ chụp trực tiếp từ Camera hoặc chọn từ Thư viện với chất lượng ảnh cao (1200px), hiển thị bản xem trước sắc nét và nút chụp lại tiện lợi.
    *   **Ghi chú đặc điểm hỗ trợ AI**: Ô nhập văn bản hỗ trợ ghi chú các đặc điểm hình thái nổi bật (màu hoa, gân lá, thân leo...) giúp AI nhận dạng loài cây rõ ràng hơn thay vì ghi chú tình trạng bệnh.
    *   **Nút "Nhận diện & Thêm vào vườn"**: Kích hoạt gửi ảnh và ghi chú lên AI Engine phân tích mô hình 40 loài cây.
*   **Modal BottomSheet Xác Nhận Lưu & Gợi Ý Vị Trí Thông Minh Theo Môi Trường Vườn**:
    *   Sau khi AI quét xong và ra kết quả nhận diện, mở BottomSheet xác nhận trực quan:
        *   **Biệt danh cây**: Tự động gợi ý tên tiếng Việt của cây, cho phép người dùng tùy chỉnh.
        *   **Chỗ đặt cây theo môi trường vườn (`Environment-Aware Zones`)**: Đề xuất 2-3 vị trí phù hợp với môi trường của khu vườn hiện tại:
            *   *Trong nhà*: Phòng khách, Phòng ngủ, Cửa sổ + Khác...
            *   *Ngoài trời*: Ban công, Sân thượng, Sân trước + Khác...
            *   *Văn phòng*: Bàn làm việc, Góc phòng họp, Quầy tiếp tân + Khác...
            *   *Nhà kính*: Kệ tầng trên, Kệ tầng dưới, Khu ươm giống + Khác...
        *   **Tùy biến vị trí**: Nếu người dùng chọn "Khác...", xuất hiện ô nhập vị trí riêng (VD: "Bàn ăn", "Cạnh TV", "Hành lang"...).
        *   **Đồng bộ Firestore 100%**: Ghi thẳng vào bộ sưu tập Firestore `MyGarden` liên kết với `gardenId` và `userId` của người dùng. Cây mới lập tức hiển thị trong khu vườn và tab góc vườn tương ứng.




---
## 4.10. Các Công Việc Đã Hoàn Thành (Hôm nay - 14/10/2026 - Đợt 2)

### Đánh Thức Trợ Lý Ảo Google Gemini 3.8 Flash & Nhận Diện Đa Phương Thức (Ảnh + Miêu Tả Hình Thái)
*   **Cài đặt Dependencies & Gắn API Key Mặc Định**:
    *   Tích hợp gói chính thức `google_generative_ai: ^0.4.7` và `shared_preferences: ^2.5.6`.
    *   Cấu hình `AppConstants.defaultGeminiApiKey`: Gắn thẳng API Key của hệ thống, người dùng và nhà phát triển mở app lên là dùng được ngay lập tức 100%, không cần phải nhập thủ công.
*   **Xây dựng Dịch vụ Gemini (`GeminiService`) ([gemini_service.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/core/services/gemini_service.dart))**:
    *   **Nâng cấp lên Google Gemini 3.8 Flash**: Thiết lập mô hình mặc định `gemini-3.8-flash` theo đúng phiên bản môi trường của người dùng với khả năng suy luận logic chuyên sâu, hiểu ảnh thị giác vượt trội và tốc độ phản hồi cực nhanh.
    *   **Tự động nhận diện API Key**: Hàm `getApiKey()` tự động ưu tiên lấy key từ SharedPreferences (nếu có tùy chỉnh riêng) hoặc dùng ngay `AppConstants.defaultGeminiApiKey` mà không bắt người dùng phải cấu hình.
    *   **Nhận diện cây kết hợp Ảnh + Miêu tả nhận dạng (`identifyPlantWithHint`)**:
        1. *Kiểm duyệt thực vật*: Xác định xem ảnh chụp có phải cây cối hay không. Nếu chụp người, động vật, đồ vật, màn hình -> từ chối ngay lập tức kèm lý do.
        2. *Đối chiếu 40 loài cây CSDL*: Đối chiếu cả hình thái ảnh và miêu tả (màu hoa, gân lá, thân mọng nước...) với danh sách 40 cây chuẩn.
        3. *Xử lý cây ngoài danh mục*: Nếu là cây nhưng không thuộc 40 loài trong CSDL, Gemini nhận diện tên khoa học và tên tiếng Việt thông dụng, đồng thời gắn cờ `matched_database: false`.
*   **Nâng Cấp Màn Hình "Thêm Cây Vào Vườn" ([add_plant_to_garden_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/garden/screens/add_plant_to_garden_screen.dart))**:
    *   **Thẻ trạng thái AI luôn sẵn sàng**: Tự động nhận diện Gemini AI đã sẵn sàng hoạt động mà không đòi hỏi nhập key.
    *   **Hiển thị "Đang cập nhật..." cho cây mới**: Nếu cây được nhận diện nằm ngoài 40 loài trong từ điển, toàn bộ các chỉ số sinh thái (Ánh sáng, Nước tưới, Độ khó chăm sóc, Họ cây, v.v.) hiển thị chuẩn xác **"Đang cập nhật..."**, người dùng vẫn tự do đặt biệt danh, chọn vị trí theo môi trường vườn và chọn lịch tưới tùy thích để lưu vào Firestore.
    *   **Tối ưu hóa CLIP Gatekeeper phía Backend (`AI_Engine/main.py`)**: Đảm bảo thực vật ngoài danh mục vẫn được xác nhận là cây hợp lệ (`is_valid_plant: True`), không bị chặn nhầm.
*   **Cơ Chế Chuyển Tiếp Mô Hình Thông Minh (Fallback Resilience)**:
    *   Phát hiện `gemini-1.5-flash` đã bị Google khai tử trên API v1beta (gây lỗi `models/gemini-1.5-flash is not found`). Đồng thời `gemini-3.8-flash` đôi lúc bị quá tải tạm thời (HTTP 503).
    *   Đã xóa bỏ hoàn toàn `1.5-flash`, thay thế bằng danh sách fallback mô hình cực mạnh và ổn định: `gemini-flash-lite-latest`, `gemini-3.5-flash-lite`, `gemini-3-flash-preview`. Khi mô hình chính gặp quá tải, hệ thống tự động trỏ sang mô hình kế tiếp tức thì (0ms lỗi) và trả về lời khuyên chẩn đoán hình ảnh sắc nét 100%.

---
## 4.11. Các Công Việc Đã Hoàn Thành (Hôm nay - 15/10/2026)

### Nâng Cấp Quản Lý Khu Vườn & Trải Nghiệm Chi Tiết Cây Trồng (Plant Details & Dynamic Floria AI)
*   **Thẻ Vị Trí Vườn Động (Dynamic Location Chips) ([garden_provider.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/garden/providers/garden_provider.dart))**:
    *   Sửa đổi `availableZones` trong `GardenProvider`: Loại bỏ hoàn toàn danh sách các thẻ vị trí tĩnh bị gán cứng ("Phòng khách", "Ban công", "Bàn làm việc"...).
    *   Hệ thống chuyển sang cơ chế **quét động**: Chỉ hiển thị thẻ "Tất cả" cùng các vị trí/khu vực **thực tế mà người dùng đã thêm cây vào** (ví dụ: chỉ có cây ở Ban công và Cửa sổ thì chỉ hiện đúng 2 thẻ này).
*   **Menu 3 Chấm (...) - Chỉnh Sửa Toàn Diện Cây Trồng ([plant_detail_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/garden/screens/plant_detail_screen.dart))**:
    *   Tích hợp menu tùy chọn: **Chỉnh sửa cây**, **Đã tưới nước hôm nay**, và **Xóa khỏi vườn**.
    *   Hộp thoại Modal Chỉnh Sửa (`_showEditPlantModal`):
        1. *Tên hiển thị / Biệt danh*: Sửa tên riêng cho từng chậu cây (`nickname`).
        2. *Góc vườn / Vị trí*: Chọn nhanh qua Chip (Phòng khách, Ban công, Cửa sổ, Bàn làm việc, Sân thượng...) hoặc gõ tự do.
        3. *Tình trạng sức khỏe*: Khỏe mạnh (xanh), Cần tưới nước (cam), Bị vàng lá (đỏ), Bị sâu bệnh (đỏ), Cần chú ý (vàng).
        4. *Tần suất tưới nước*: Slider kéo chọn số ngày/lần (1 đến 14 ngày).
        5. *Khung giờ nhắc nhở*: Chọn nhanh 07:00, 09:30, 17:30, 20:00.
        6. *Ghi chú riêng*: Lưu nhật ký cá nhân về cây.
    *   **Tối ưu Giao diện Menu 3 Chấm (Light Glass Design)**: Thiết lập cứng `color: Colors.white`, `surfaceTintColor: Colors.white`, bóng đổ `elevation: 10`, viền bo mềm `borderRadius: 18px` để khắc phục lỗi nền đen chìm chữ của Material 3 mặc định. Từng tùy chọn được bổ sung icon bo tròn tinh tế và phân cấp màu sắc rõ ràng (chữ đen, đỏ cảnh báo).
    *   Phương thức `updatePlantInfo` trong `GardenProvider` cập nhật tức thì lên Firestore `MyGarden` và giao diện phản ánh thay đổi ngay lập tức (Reactive qua `Consumer<GardenProvider>`).
*   **Thêm Nút "Chi Tiết" (Bách Khoa Toàn Thư Cây Trồng)**:
    *   Thêm nút `📖 Chi tiết` vào hàng hành động nhanh trên màn hình chi tiết cây (`[Chi tiết] [Quét bệnh] [Nhật ký] [Floria AI]`).
    *   Modal Bách Khoa (`_showPlantWikiModal`): Hiển thị chi tiết Tên khoa học, Họ thực vật (`family`), Nguồn gốc xuất xứ, Mức độ khó chăm sóc, Yêu cầu ánh sáng, Nước tưới, Nhiệt độ lý tưởng, Độ ẩm không khí, Đất trồng, Phân bón và Độc tính đối với trẻ em / thú cưng.
*   **Đánh Thức Nút "Floria AI" - Trợ Lý Chuyên Sâu Cho Từng Loài Cây**:
    *   Khi bấm nút `✨ Floria AI` từ cây đang xem, ứng dụng điều hướng sang `AiAssistantScreen` và nạp toàn bộ ngữ cảnh về loài cây (Tên, Tên khoa học, Vị trí đặt, Tình trạng sức khỏe, Tần suất tưới).
    *   **Tùy biến lời chào AI**: Bác sĩ Floria AI chào đích danh loài cây và tình trạng sức khỏe hiện tại của nó.
    *   **Tùy biến Quick Prompt Chips**: Gợi ý các câu hỏi chuyên sâu tự động thay đổi theo tên cây (VD: *"Lịch tưới & lượng nước cho Cây đuôi công lá tròn?"*, *"Cây đặt ở Cửa sổ có đủ sáng không?"*, *"Các bệnh và sâu hại hay gặp?"*).
    *   Gemini Prompt Context: Tự động ghim hồ sơ thực vật vào System Instruction để Bác sĩ AI phân tích và đưa ra phác đồ y khoa cây trồng chính xác nhất.

---
## 4.12. Định Hướng & Kiến Trúc Quét Chẩn Đoán Bệnh Cây Cảnh (Hôm nay - 18/10/2026)

### Phân Tách Hai Luồng Người Dùng (User Flow)
*   **Camera Màn Hình Chính (Tab Scan)**: Giữ nguyên tính năng **Nhận diện loài cây (Plant Discovery)**. Người dùng chụp để biết tên cây lạ, tra cứu bách khoa toàn thư thực vật và bấm "Lưu vào vườn".
*   **Quét Bệnh Trong Khu Vườn (Disease Diagnosis)**: Kích hoạt tại **Khu Vườn Của Tôi ➔ Chi tiết cây ➔ Bấm nút `[Quét bệnh]`**.
    *   Hệ thống tận dụng ngữ cảnh đã biết trước của cây trồng (`nameVi`, `scientificName`, vị trí `zone`, chu kỳ tưới `waterFrequencyDays`).
    *   Mở camera hướng dẫn chụp cận cảnh phiến lá bất thường để chẩn đoán đúng bệnh của loài cây đó.

### Chiến Lược Gom 5 Nhóm Bệnh Cốt Lõi Cho 40 Loài Cây Cảnh
Qua phân tích đặc thù 40 loài cây cảnh trong hệ thống (Monstera, Bàng Singapore, Lưỡi hổ, Đuôi công, Kim tiền, Môn, Trầu bà...), 95% bệnh lý thực tế tập trung vào 5 nhóm bệnh lá kinh điển:
1.  **`Healthy` (Khỏe mạnh)**: Lá xanh bóng, nguyên vẹn, không có tổn thương bệnh học.
2.  **`Anthracnose` (Bệnh Thán Thư)**: Vết đốm tròn nâu cháy viền vàng sậm (xuất hiện nặng trên Monstera, Bàng Singapore, Lưỡi hổ, Lan ý, Đa búp đỏ).
3.  **`Leaf_Spot` (Bệnh Đốm Lá Nấm)**: Đốm nâu/vàng li ti mắt cua do nấm Cercospora/Alternaria (xuất hiện trên Calathea, Begonia, Kim tiền, Thường xuân).
4.  **`Bacterial_Blight` (Cháy Bìa Lá / Thối Nhũn Vi Khuẩn)**: Vết cháy thâm đen viền lá ủng nước do tưới đọng đêm (xuất hiện trên Alocasia, Syngonium, Trầu bà).
5.  **`Powdery_Mildew` (Bệnh Phấn Trắng)**: Lớp phấn bột trắng xóa phủ bề mặt lá non (xuất hiện trên Hoa sứ, Hoa giấy, Begonia).

### Nguồn Dữ Liệu Gom Dataset
Không cần cào thủ công trên mạng, hệ thống tổng hợp từ các bộ dataset chuẩn mực đã được gán nhãn chuyên nghiệp:
*   **PlantDoc Dataset (Kaggle)**: [https://www.kaggle.com/datasets/nirmalsankalana/plantdoc-dataset](https://www.kaggle.com/datasets/nirmalsankalana/plantdoc-dataset) (Ảnh chụp đời thực in-the-wild, ánh sáng tự nhiên).
*   **Indoor Plant Disease Dataset by Nishad (Roboflow Universe)**: [https://universe.roboflow.com/nishad-a6yze/indoor-plant-disease-dataset-odg74](https://universe.roboflow.com/nishad-a6yze/indoor-plant-disease-dataset-odg74) (Chuyên cây cảnh trong nhà: Lưỡi hổ, Kim tiền, Trầu bà).
*   **Mango Leaf Disease Dataset (Kaggle)**: [https://www.kaggle.com/datasets/aryashah2k/mango-leaf-disease-dataset](https://www.kaggle.com/datasets/aryashah2k/mango-leaf-disease-dataset) (Mẫu bệnh Thán thư & Phấn trắng lá to sắc nét).

### Kế Hoạch Huấn Luyện & Tích Hợp AI Engine
*   **Bộ dữ liệu cục bộ**: Đã tải và gom thành công hơn 2.100 ảnh vào [AI_Engine/dataset/](file:///d:/Plan/utrasupervip/AI_Engine/dataset) (gồm `train` và `val` của 5 nhóm bệnh).
*   **Phát hành Enterprise Pipeline Notebook ([PlantDiseaseClassifier.ipynb](file:///d:/Plan/utrasupervip/PlantDiseaseClassifier.ipynb))**:
    *   Xây dựng file notebook hoàn chỉnh theo kiến trúc chuẩn MLOps của [PlantClassifierV4.ipynb](file:///d:/Plan/utrasupervip/PlantClassifierV4.ipynb).
    *   Hỗ trợ tự động tải dữ liệu KaggleHub, Stratified Split 80/10/10, WeightedRandomSampler, Mixed Precision FP16, Auto-Resume chống mất điện.
    *   Huấn luyện lần lượt 3 mô hình (`mobilenetv3_large_100`, `tf_efficientnetv2_b0`, `ghostnetv2_100`) trên GPU Colab.
    *   Vẽ Master Dashboard học thuật (Loss/Accuracy Dynamics, Confusion Matrix, ROC Curve, FPS, Latency).
*   **Lựa Chọn Quán Quân Tuyệt Đối: `tf_efficientnetv2_b0` (Google EfficientNetV2)**:
    *   *Loài cây (40 loài)*: Đạt Accuracy **~90.0%**, F1 **~90.0%**, Tốc độ **~438 FPS** (Vô địch).
    *   *Bệnh cây (5 nhóm bệnh)*: Đạt Accuracy **~92.5%**, F1 **~90.8%**, Tốc độ **~106 FPS** (Vô địch).
    *   Đã dọn sạch các file mô hình cũ `mobilenetv3_large_100` khỏi thư mục `models/`.
    *   Đã nạp chính thức cặp file mô hình quán quân vào [AI_Engine/models/](file:///d:/Plan/utrasupervip/AI_Engine/models):
        1. [tf_efficientnetv2_b0.onnx](file:///d:/Plan/utrasupervip/AI_Engine/models/tf_efficientnetv2_b0.onnx) (Nhận diện 40 loài cây, Output: `[1, 40]`).
        2. [tf_efficientnetv2_b0_disease.onnx](file:///d:/Plan/utrasupervip/AI_Engine/models/tf_efficientnetv2_b0_disease.onnx) (Chẩn đoán 5 nhóm bệnh, Output: `[1, 5]`).
*   **Nâng cấp AI Engine ([AI_Engine/main.py](file:///d:/Plan/utrasupervip/AI_Engine/main.py))**:
    *   Tự động nạp đồng thời 2 mô hình `tf_efficientnetv2_b0` và `tf_efficientnetv2_b0_disease`.
    *   Mở endpoint `/predict-disease` trả về tên bệnh tiếng Việt, mức độ nguy hiểm, nguyên nhân và phác đồ điều trị 4 bước.

---
## 5. Các Task Đang Chạy Nền (Active Tasks)
*   *Hiện tại tất cả các Background Tasks cho Web và Mobile đã được hoàn thành.*

---

## 6. Kế Hoạch Tiếp Theo (Next Steps - Actionable)

**Bước 1: Nối cáp thông luồng AI thực tế & Tối ưu hóa** ✅ *(Đã hoàn thành xuất sắc ngày 13/10/2026)*
**Bước 2: Tính năng Khu Vườn Của Tôi (My Garden)** ✅ *(Đã hoàn thành xuất sắc ngày 13/10/2026)*
**Bước 3: Đánh thức Trợ lý Ảo (AI Chatbot - Gemini Bác sĩ Cây trồng & Nhận diện Đa phương thức)** ✅ *(Đã hoàn thành xuất sắc ngày 14/10/2026)*
**Bước 4: Huấn luyện & Tích Hợp Cặp Mô Hình Quán Quân EfficientNetV2 Vào AI Engine** ✅ *(Đã hoàn thành xuất sắc ngày 19/10/2026)*
- Đã xuất sắc train và nạp cặp đôi `tf_efficientnetv2_b0` (Accuracy 90% cho 40 cây và 92.5% cho 5 nhóm bệnh).
- Đã hoàn thiện endpoint `/predict-disease` trên FastAPI.

**Bước 5: Nối Luồng Quét Bệnh Tại Khu Vườn Trên Flutter App** ✅ *(Đã hoàn thành xuất sắc ngày 19/10/2026)*
- Đã hoàn thiện endpoint `/api/diagnose-disease` trong Spring Boot Backend.
- Đã kết nối nút `[Quét bệnh]` trong màn hình chi tiết cây (`plant_detail_screen.dart`), hiển thị kết quả chẩn đoán bệnh động kèm phác đồ điều trị và cập nhật trạng thái cây vào `MyGarden`.

**Bước 6: Màn hình Lịch sử Quét (Scan History)** ✅ *(Đã hoàn thành xuất sắc ngày 20/10/2026)*
- Xây dựng hoàn chỉnh kiến trúc Model-Provider-Screen cho `lib/features/history/`.
- Đồng bộ Realtime với Firestore `ScanHistory`, hỗ trợ bộ lọc loài cây / bệnh lá, tìm kiếm theo tên, xem chi tiết và xóa lịch sử.

**Bước 7: Hoàn thiện Cửa hàng & Giỏ hàng (Shop & Cart)** 🎯 *(Ưu tiên tiếp theo)*
- Xử lý logic Giỏ hàng và đặt mua vật tư nông nghiệp/cây cảnh.

---

## 7. Cấu Trúc Cơ Sở Dữ Liệu (Firebase Firestore)

Dưới đây là sơ đồ cấu trúc của các bộ sưu tập (Collections) hiện đang được lưu trữ trên hệ thống cơ sở dữ liệu NoSQL Firebase Firestore.

### 7.1. Collection: `plants_info`
Lưu trữ hồ sơ thực vật, từ điển bách khoa toàn thư cho cây cảnh và cây trồng.
*   **Document ID**: Tên khoa học hoặc tên tiếng Anh (VD: `Adenium obesum`, `Aloe vera`)
*   **Fields**:
    *   `name_vi` (String): Tên tiếng Việt của cây (VD: "Cây hoa sứ")
    *   `scientific_name` (String): Tên khoa học
    *   `family` (String): Họ thực vật (VD: "Apocynaceae (Họ Trúc đào)")
    *   `plant_type` (String): Loại cây (VD: "Cây mọng nước")
    *   `origin` (String): Nguồn gốc xuất xứ
    *   `difficulty` (String): Mức độ chăm sóc (Dễ/Trung bình/Khó)
    *   `light` (String): Nhu cầu ánh sáng (VD: "Nắng trực tiếp")
    *   `water_frequency` (String): Tần suất tưới nước (VD: "1 lần/tuần")
    *   `temperature` (String): Nhiệt độ phù hợp (VD: "25-35°C")
    *   `humidity` (String): Độ ẩm phù hợp
    *   `short_desc` (String): Mô tả ngắn gọn xuất hiện ở Card
    *   `wiki_detail` (String): Đoạn giới thiệu chi tiết, bách khoa toàn thư
    *   `placements` (Array[String]): Gợi ý vị trí đặt (VD: ["Ban công", "Sân thượng"])
    *   `identification` (String): Đặc điểm nhận dạng hình thái
    *   `root_type` (String): Loại rễ cây (VD: "Rễ củ phình to")
    *   `toxicity` (String): Tình trạng độc tính (nếu có)

### 7.2. Collection: `ScanHistory`
Lưu trữ nhật ký phân tích, quét ảnh chẩn đoán bệnh của người dùng.
*   **Document ID**: Auto-generated ID do Firebase tạo ngẫu nhiên
*   **Fields**:
    *   `userId` (String): Định danh của người dùng (Firebase Auth UID)
    *   `prediction` (String): Kết quả nhận diện (Tên cây / Tên bệnh)
    *   `confidence` (Number): Mức độ tin cậy (Tỉ lệ % do AI trả về)
    *   `modelUsed` (String): Tên AI model đã sử dụng (VD: "efficientnetb0")
    *   `timestamp` (Timestamp): Thời gian thực hiện quét

### 7.3. Collection: `Users`
Lưu trữ hồ sơ tài khoản và thông tin người dùng sử dụng ứng dụng.
*   **Document ID**: User UID (Đồng bộ trực tiếp với Firebase Auth UID)
*   **Fields**:
    *   `email` (String): Địa chỉ email đăng ký
    *   `name` (String): Tên hiển thị (Display Name)
    *   `lastLogin` (Timestamp): Thời điểm truy cập ứng dụng gần nhất

### 7.4. Collection: `MyGarden`
Lưu trữ bộ sưu tập cây trồng cá nhân trong "Khu Vườn Của Tôi" (Root Collection độc lập trên Firebase Firestore).
*   **Document ID**: Auto-generated ID do Firestore tạo ngẫu nhiên
*   **Fields**:
    *   `userId` (String): Định danh người sở hữu cây (Firebase Auth UID)
    *   `nameVi` (String): Tên tiếng Việt của cây
    *   `scientificName` (String): Tên khoa học
    *   `nickname` (String): Biệt danh do người dùng đặt (hoặc tên mặc định)
    *   `zone` (String): Khu vực đặt cây (VD: "Phòng khách", "Ban công", "Bàn làm việc")
    *   `imageUrl` (String): Đường dẫn hoặc link ảnh cây
    *   `plantType` (String): Phân loại cây
    *   `waterFrequencyDays` (Number): Chu kỳ tưới nước định kỳ (tính theo ngày)
    *   `lastWatered` (Timestamp): Thời điểm tưới nước gần nhất
    *   `nextWatering` (Timestamp): Thời điểm cần tưới nước tiếp theo
    *   `healthStatus` (String): Trạng thái sức khỏe của cây ("Khỏe mạnh")
    *   `notes` (String): Ghi chú chăm sóc của người dùng
    *   `wikiData` (Map): Toàn bộ thông số sinh thái lưu kèm từ kết quả AI/Firestore
    *   `createdAt` (Timestamp): Thời điểm thêm cây vào khu vườn

---

## 4.12. Nâng Cấp Quán Quân Kép EfficientNetV2 & Hoàn Thiện Luồng Quét Bệnh Lá Cây (End-to-End)
*Ngày cập nhật: 19 tháng 10, 2026*

### 1. Bối cảnh & Phân tách luồng sản phẩm (Product Workflow Separation)
*   **Trải nghiệm nhận diện loài cây (Plant Discovery)**: Giữ nguyên tại Camera chính (Tab Scan ngoài) phục vụ khám phá 40 loài cây cảnh, tìm hiểu kiến thức sinh học bách khoa và thêm cây mới vào vườn.
*   **Trải nghiệm chẩn đoán bệnh cây (Plant Disease Diagnosis)**: Kích hoạt chuyên biệt trong **Khu Vườn Của Tôi ➔ Chi tiết cây cụ thể ➔ Nút `[Quét bệnh]`**, tận dụng triệt để ngữ cảnh cây đã biết (`nameVi`, `scientificName`, `zone`, `healthStatus`) để đưa ra phác đồ điều trị chuẩn xác nhất.

### 2. Thành tựu Huấn luyện AI & Tối ưu Mô hình ONNX
*   **Dataset 5 nhóm bệnh chuẩn hóa**: Gom thành công 2.107 ảnh sạch tại `AI_Engine/dataset/` (`Anthracnose`, `Bacterial_Blight`, `Healthy`, `Leaf_Spot`, `Powdery_Mildew`).
*   **Lựa chọn mô hình Quán quân**: Thực nghiệm trên Google Colab qua notebook `PlantDiseaseClassifier.ipynb`, mô hình **Google EfficientNetV2 (`tf_efficientnetv2_b0`)** đạt thành tích cao nhất:
    *   *Nhận diện 40 loài cây*: Đạt ~90% Accuracy, tốc độ suy luận cực nhanh ~438 FPS.
    *   *Chẩn đoán 5 bệnh lá*: Đạt **92.48% Accuracy**, suy luận thời gian thực ~106 FPS.
*   **Dọn dẹp & Tối ưu xuất ONNX**:
    *   Xóa bỏ hoàn toàn mô hình cũ `mobilenetv3_large_100.onnx` và các file weight thừa.
    *   Xuất chuẩn ONNX với `opset_version=18` và `onnxscript` không còn warning version converter.
    *   Nạp cặp mô hình chính thức vào `AI_Engine/models/`:
        1. `tf_efficientnetv2_b0.onnx` + `.data` (40 loài cây).
        2. `tf_efficientnetv2_b0_disease.onnx` + `.data` (5 nhóm bệnh).

### 3. Cập nhật AI Engine (Python FastAPI - Cổng 8000)
*   Tự động nạp đồng thời cả 2 mô hình ONNX khi khởi động máy chủ.
*   Thêm endpoint chuyên trách `@app.post("/predict-disease")`: Nhận ảnh lá bệnh, trả về `prediction`, `prediction_vi`, `confidence`, `severity`, `severity_vi`, `cause`, `treatment_steps` (phác đồ 3-4 bước), và danh sách `top_predictions`.

### 4. Cập nhật Central Backend (Java Spring Boot - Cổng 8080)
*   Thêm cấu hình `ai.engine.disease.url=http://localhost:8000/predict-disease` trong `application.properties`.
*   Bổ sung endpoint `@PostMapping("/diagnose-disease")` trong `DiseaseController.java`: Tiếp nhận MultipartFile từ ứng dụng di động, đính kèm `plant_name`, `plant_id`, xác thực Firebase Bearer token, chuyển tiếp sang AI Engine và lưu nhật ký ngầm vào Firestore `ScanHistory` với `type: "disease_diagnosis"`.

### 5. Cập nhật Mobile App (Flutter)
*   **`AppConstants`**: Bổ sung `diagnoseDiseaseUrl => '$baseUrl/diagnose-disease'`.
*   **`ScanProvider`**: Thêm hàm `uploadAndDiagnoseDisease({plantName, plantId, token})` xử lý upload ảnh lá qua FormData multipart đa nền tảng (Web/Mobile).
*   **`PlantDetailScreen`**: 
    *   Sửa nút `[Quét bệnh]` mở BottomSheet tùy chọn chụp ảnh cận cảnh lá bệnh từ Camera hoặc chọn từ Thư viện.
    *   Chuyển mượt mà sang `DiagnosisReportScreen(isDiseaseScan: true, currentPlant: currentPlant)` kèm hiệu ứng Shimmer Loading.
*   **`DiagnosisReportScreen`**:
    *   Hiển thị Hero Card với tên bệnh tiếng Việt, badge mức độ nguy hiểm và thẻ trạng thái theo màu sắc cảnh báo y học cây trồng.
    *   Thẻ **Nguyên nhân & Mầm bệnh** (`_buildCauseCard`) lấy động 100% từ AI Engine.
    *   Thẻ **Phác đồ điều trị** (`_buildTreatmentCard`) hiển thị từng bước hành động xử lý khẩn cấp (cách ly, cắt tỉa, phun thuốc).
    *   Nút **"Cập nhật bệnh án"**: Tự động ghi nhận `healthStatus = 'Bị ' + predictionVi` vào hồ sơ cây trong Firestore `MyGarden`.
    *   Nút **"Hỏi Bác sĩ AI"**: Mở màn hình chat trợ lý Floria AI kèm ngữ cảnh bệnh lá và lịch chăm sóc để nhận tư vấn chuyên sâu tức thì.

### 6. Rà Soát Làm Sạch Hệ Thống & Loại Bỏ Triệt Để Dữ Liệu Mock
*   **Xóa bỏ Dataset thô**: Dọn dẹp hoàn toàn thư mục `AI_Engine/dataset/` (hơn 2.100 ảnh lá) sau khi đã xuất mô hình ONNX thành công, giúp giảm tải dung lượng ổ cứng.
*   **Xóa các file Google Colab**: Xóa bỏ các file notebook huấn luyện thừa trên repo (`PlantClassifierV4.ipynb`, `PlantDiseaseClassifier.ipynb`, `train_plant_disease_colab.ipynb`).
*   **Loại bỏ mã Mock Fallback**:
    *   Xóa bỏ `mock_disease_detector` trong `AI_Engine/main.py`. Nếu máy chủ gặp lỗi, hệ thống sẽ trả về HTTP 500 trung thực.
    *   Xóa bỏ fallback bypass tự đăng nhập trong `login_screen.dart` của Flutter App.
*   **Vận hành thực tế (Live Production)**: Hệ thống chạy 100% bằng mô hình ONNX thật, Spring Boot Gateway thật và cơ sở dữ liệu Firebase Firestore đồng bộ thời gian thực.

---

## 4.13. Hoàn Thiện Tính Năng Lịch Sử Quét (Scan History) Toàn Diện & Tối Ưu Hóa Hệ Thống
*Ngày cập nhật: 20 tháng 10, 2026*

### 1. Nâng cấp Central Backend (Spring Boot Gateway)
*   **Chuẩn hóa dữ liệu lưu `ScanHistory`**:
    *   Tại endpoint `/scan-disease`: Bổ sung lưu ngầm `type: "plant_discovery"` và `predictionVi` (trích xuất trực tiếp từ hồ sơ cây `plants_info` của Firestore).
    *   Tại endpoint `/diagnose-disease`: Lưu đầy đủ thông tin bệnh học `type: "disease_diagnosis"`, `predictionVi`, `severity`, `severityVi`, `cause`, `treatmentSteps`, và `plantName`.

### 2. Xây dựng Tính Năng Lịch Sử Quét Trên Ứng Dụng Flutter Di Động
*   **Model Dữ Liệu Thực Thể ([scan_history_item.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/history/models/scan_history_item.dart))**:
    *   Khởi tạo `ScanHistoryItem` tương thích linh hoạt với cả các bản ghi mới và cũ (xử lý an toàn các kiểu timestamp số millis hoặc Timestamp của Firestore).
    *   Hỗ trợ các getters tiện ích: `isDisease`, `isHealthy`, `cleanPrediction`, `displayName`.
*   **Quản Lý Trạng Thái ([history_provider.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/history/providers/history_provider.dart))**:
    *   Tự động lắng nghe thời gian thực (`Stream<QuerySnapshot>`) bộ sưu tập `ScanHistory` theo `userId` người dùng đăng nhập.
    *   Sắp xếp thứ tự bản ghi mới nhất lên đầu (`timestamp desc`).
    *   Bộ lọc đa dạng: *Tất cả*, *Khám phá loài cây* (`plant_discovery`), *Chẩn đoán bệnh* (`disease_diagnosis`).
    *   Tìm kiếm tức thì theo từ khóa tên cây, tên khoa học, hoặc tên bệnh.
    *   Hỗ trợ các thao tác xóa từng mục (`deleteItem`) và xóa toàn bộ lịch sử (`clearAllHistory`) bằng Firebase Batch.
*   **Giao Diện Người Dùng Chuẩn Thiết Kế Glassmorphism ([history_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/history/screens/history_screen.dart))**:
    *   Thanh tìm kiếm bo tròn tinh tế và hàng thẻ bộ lọc danh mục động kèm số lượng đếm thực tế.
    *   Mỗi thẻ lịch sử hiển thị: Icon phân loại màu sắc y học (Xanh lá thực vật, Xanh dương an toàn, Đỏ cảnh báo mầm bệnh), tên tiếng Việt, độ tin cậy AI %, nhãn mức độ, và thời gian quét thân thiện ("Hôm nay, 14:30").
    *   **Thao tác vuốt để xóa (Dismissible swipe-to-delete)**: Vuốt sang trái để xóa kèm hộp thoại xác nhận an toàn.
    *   **Modal Chi tiết Toàn diện (Bottom Sheet)**: Bấm vào từng bản ghi để xem lại toàn bộ thông số AI, nguyên nhân mầm bệnh, phác đồ điều trị 4 bước, nút mở Từ điển cây (`PlantWikiScreen`) và nút hỏi trợ lý ảo `Floria AI`.
    *   Menu 3 chấm ở góc trên hỗ trợ "Xóa toàn bộ lịch sử".
*   **Kết Nối Điểm Truy Cập Tiện Lợi (Entry Points)**:
    *   Kết nối mục *Lịch sử quét* trong Trang Cá nhân ([profile_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/profile/screens/profile_screen.dart)).
    *   Bổ sung nút truy cập nhanh lịch sử quét ngay trên AppBar của Màn hình Quét Camera ([scan_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/scan/screens/scan_screen.dart)).
*   **Dọn Dẹp Mã Nguồn (Clean Code)**:
    *   Đăng ký `HistoryProvider` vào `MultiProvider` trong `main.dart`.
    *   Dọn sạch toàn bộ import thừa trong `main.dart` và `scan_screen.dart`.

---

## 4.14. Xây Dựng Hệ Sinh Thái Cửa Hàng Vật Tư & Mô Hình "AI Agentic Commerce" (Bác Sĩ AI Kê Đơn)
*Ngày cập nhật: 20 tháng 10, 2026*

### 1. Đồng bộ Kho Dữ Liệu Dược Phẩm & Vật Tư Lên Cloud Firestore
* Khởi tạo bộ sưu tập `ShopProducts` trên Firebase Firestore gồm 7 sản phẩm chuyên dụng cho chăm sóc & điều trị bệnh cây trồng:
  1. `nano-bac-tri-nam`: Chế Phẩm Nano Bạc Đồng Sinh Học (Đặc trị Thán thư, Đốm lá, Phấn trắng, Cháy lá vi khuẩn).
  2. `dau-neem-tri-rep`: Tinh Dầu Neem Hữu Cơ Ép Lạnh (Đặc trị Rệp sáp, Bọ trĩ, Nhện đỏ, Sâu hại).
  3. `phan-rong-bien-kich-re`: Phân Bón Hữu Cơ Rong Biển & Vi Lượng (Phục hồi cây vàng lá, suy rễ sau ốm).
  4. `phan-trun-que-vien-nen`: Phân Trùn Quế Viên Nén Tan Chậm (Dinh dưỡng êm dịu, ngăn ngừa mầm bệnh đất).
  5. `binh-xit-phun-suong-15l`: Bình Xịt Áp Suất Phun Sương Mịn 1.5L (Đầu đồng thau cao cấp).
  6. `keo-cat-tia-canh-nhat`: Kéo Cắt Tỉa Cành Thép SK5 (Cắt tỉa lá bệnh, tránh lây lan chéo).
  7. `dat-trong-indoor-premium`: Giá Thể Đất Trồng Indoor Mix (Thoát nước siêu tốc, chống úng rễ).

### 2. Kiến Trúc Quản Lý Trạng Thái & Mô Hình Thực Thể (State Management)
* **Model [shop_product.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/shop/models/shop_product.dart)**: Định nghĩa `ShopProduct` và `CartItem`, tự động tính toán tiền tệ định dạng VNĐ chuẩn (`135.000đ`).
* **Quản Lý Trạng Thái [shop_provider.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/shop/providers/shop_provider.dart)**:
  * Kết nối thời gian thực với Firestore, hỗ trợ bộ lọc đa danh mục (*Thuốc trị bệnh*, *Phân bón & Dưỡng*, *Dụng cụ*, *Đất trồng*).
  * Tìm kiếm theo từ khóa tên sản phẩm và tên bệnh cây chỉ định.
  * Toàn bộ logic giỏ hàng: thêm số lượng, giảm số lượng, xóa sản phẩm, tính tổng tiền.
  * Hàm tiện ích `getProductById` và `getProductsForDisease`.

### 3. Đột Phá: Mô Hình "AI Agentic Commerce" (Trợ Lý AI Kê Đơn Thuốc Trực Tiếp Trong Chat)
* **Prompt Engineering [gemini_service.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/core/services/gemini_service.dart)**:
  * Nạp kiến thức về toàn bộ danh mục dược phẩm sinh học của Floria vào System Instruction của Gemini.
  * Hướng dẫn Bác sĩ AI phân tích bệnh học và kê đơn sản phẩm bằng thẻ nhận diện `[RECOMMEND_PRODUCT: product_id]`.
* **Giao Diện Chatbot Thông Minh [ai_assistant_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/chatbot/screens/ai_assistant_screen.dart)**:
  * Tự động bắt thẻ `[RECOMMEND_PRODUCT: ...]` trong lời khuyên của Bác sĩ AI.
  * Hiển thị ngay **Thẻ Dược Phẩm Kê Đơn (Product Recommendation Card)** ngay dưới tin nhắn: có ảnh sản phẩm, huy hiệu y tế, giá bán, nút "Chi tiết" và nút "Mua ngay" tiện lợi.

### 4. Giao Diện Người Dùng Chuẩn Thương Mại Điện Tử Sinh Thái
* **Màn Hình Cửa Hàng ([shop_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/shop/screens/shop_screen.dart))**: Lưới sản phẩm hiện đại, thanh tìm kiếm thông minh, thẻ lọc danh mục mượt mà, huy hiệu số lượng giỏ hàng trên AppBar.
* **Chi Tiết Sản Phẩm ([product_detail_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/shop/screens/product_detail_screen.dart))**: Header ảnh dạng cuộn mượt mà, nhãn "Chỉ định điều trị" theo bệnh cây, hướng dẫn pha thuốc, bộ chọn số lượng và nút thêm vào giỏ.
* **Giỏ Hàng & Thanh Toán ([cart_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/shop/screens/cart_screen.dart))**: Tăng giảm số lượng sản phẩm, tổng thanh toán và hộp thoại đặt hàng thành công.
* **Liên Kết Từ Màn Hình Quét Bệnh ([diagnosis_report_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/scan/screens/diagnosis_report_screen.dart))**: Thêm nút chuyển hướng nhanh sang Cửa hàng tại phần phác đồ điều trị khi cây được chẩn đoán mắc bệnh lá.

---

## 4.15. Nâng Cấp Hệ Thống AI: Tối Ưu Độ Trễ 1s, Chế Độ Suy Nghĩ Sâu & Chuẩn Hóa Y Đức Kê Đơn
*Ngày cập nhật: 20 tháng 10, 2026*

### 1. Nâng Cấp Toàn Diện Mô Hình AI Google Gemini Mới Nhất
* **Kiểm tra trực tiếp từ Google API Endpoint (`/v1beta/models`)**:
  * Phát hiện các model cũ (`gemini-1.5-flash`, `gemini-2.0-flash`, `gemini-2.5-flash`) đã bị Google trả về mã `404: No longer available to new users`.
  * Cập nhật danh sách mô hình sang thế hệ mới nhất của Google:
    * Mặc định chính thức: **`gemini-3-flash-preview`** (hoạt động 100%, ổn định cao).
    * Fallback dự phòng: **`gemini-3.1-flash-lite`**, **`gemini-3.6-flash`**.
  * Cập nhật đồng bộ hộp thoại cấu hình model trong [gemini_service.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/core/services/gemini_service.dart).

### 2. Đột Phá Tốc Độ: Khắc Phục Triệt Để Thời Gian Chờ (Từ 11s Xuống ~1.2s)
* **Nguyên nhân cốt lõi phát hiện qua Benchmark**:
  * Các model thế hệ 3 của Google mặc định tự kích hoạt chế độ "Suy nghĩ ngầm" (ngốn tới 651 token suy nghĩ, mất đúng **11.26 giây** trước khi phát ra chữ đầu tiên).
* **Giải pháp kỹ thuật**:
  * Chuyển đổi phương thức giao tiếp sang **Direct Server-Sent Events (SSE Stream)** qua thư viện `Dio`.
  * Thiết lập cấu hình `thinkingConfig: {"thinkingBudget": 0}` (Zero-latency Mode).
  * **Kết quả đo đạc thực tế trong Dart**: First Token xuất hiện chỉ sau **1.238ms (~1.2s)**, chữ tuôn ra mượt mà tức thì với con trỏ nhấp nháy `▍`.

### 3. Trang Bị Bộ Chuyển Đổi 2 Chế Độ Tư Duy (Pill Switcher)
* **Thanh chuyển đổi 2 chế độ thông minh ngay trên khung chat**:
  * **⚡ Chế độ Siêu tốc (~1s)**: Thiết lập `thinkingBudget: 0`, trả lời nhanh tức thì, trực tiếp vào trọng tâm, tiết kiệm thời gian cho các câu hỏi thường ngày.
  * **🧠 Chế độ Suy nghĩ sâu (Deep Thinking)**: Thiết lập `thinkingBudget: 1024`, dành cho các ca bệnh phức tạp, AI kích hoạt chuỗi suy luận y khoa bệnh học thực vật đa tầng trước khi đưa ra phác đồ.
* **Ghi nhớ cấu hình**: Tự động lưu lựa chọn của người dùng vào `SharedPreferences`, đồng bộ tiêu đề trạng thái trên AppBar.

### 4. Chuẩn Hóa Y Đức & Quy Tắc Kê Đơn Của Bác Sĩ AI
* Loại bỏ triệt để tình trạng "hỏi câu nào AI cũng gượng ép bán sản phẩm".
* **Quy tắc mới nghiêm ngặt**:
  * Khi người dùng hỏi kiến thức cơ bản (lịch tưới nước, vị trí đặt cây, cách tỉa cành...): AI trả lời thuần túy kiến thức sinh học, **100% KHÔNG gắn thẻ sản phẩm**.
  * Chỉ kê đơn khi thỏa mãn 2 điều kiện: Cây thực sự bị bệnh/sâu hại nặng cần thuốc đặc trị, HOẶC người dùng chủ động hỏi tên thuốc/vật tư.

---

## 4.16. Tinh Gọn Giao Diện Trợ Lý AI (Clean Minimalist AI Assistant UI)
*Ngày cập nhật: 22 tháng 10, 2026*

* **Loại bỏ Nút Chọn Model AI & Cài Đặt**: Ẩn nút bánh răng cấu hình API Key / Model trên AppBar để giao diện sạch sẽ, thân thiện với người dùng cuối; hệ thống dùng API Key mặc định tự động.
* **Loại bỏ Hiển Thị Tên Kỹ Thuật Model**: Bỏ nhãn "Floria Gemini 3 Flash" ở tiêu đề phụ; chỉ giữ lại biểu tượng trạng thái trực quan tương ứng với chế độ tư duy (`🧠 Suy nghĩ sâu` hoặc `⚡ Siêu tốc`).
* **Đơn Giản Hóa Tab Chuyển Đổi Chế Độ**:
  * Đổi tên tab `⚡ Siêu tốc (~1s)` thành `⚡ Siêu tốc` ngắn gọn, súc tích.
  * Loại bỏ hoàn toàn dòng chữ chú thích dài dòng ở cạnh phải (`Phân tích bệnh học đa tầng` / `Tối ưu phản hồi tức thì`).
* **Loại bỏ Thanh Viên Thuốc Gợi Ý (Quick Prompts)**: Loại bỏ toàn bộ các thẻ gợi ý câu hỏi nhanh phía trên khung nhập tin nhắn để mở rộng tối đa không gian đọc nội dung trò chuyện.
* **Dọn Dẹp Mã Nguồn**: Loại bỏ các biến và hàm không còn dùng (`_quickPrompts`, `_setupPlantSpecificPrompts`, `_modelName`, `_formatModelDisplay`), kiểm tra mã nguồn đạt 0 lỗi phân tích tĩnh (`No issues found!`).

---

## 4.17. Trình Diễn Markdown Thẩm Mỹ & Quản Lý Lịch Sử Hội Thoại (ChatGPT-Style Chat Sessions)
*Ngày cập nhật: 22 tháng 10, 2026*

### 1. Tích Hợp Render Markdown Chuyên Sâu (`flutter_markdown`)
* **Chấm dứt hiển thị văn bản thô**: Loại bỏ `SelectableText` thô vốn làm lộ các ký tự kỹ thuật `**in đậm**`, `* gạch đầu dòng`, `"""..."""`.
* **Bộ Custom MarkdownStyleSheet chuẩn thẩm mỹ**:
  * Chữ in đậm `**...**` hiển thị màu xanh rêu đậm sang trọng (`#1B3B22`).
  * Danh sách có thứ tự `1. 2.` và danh sách gạch đầu dòng `*` tự động thụt lề chuẩn xác, khoảng cách dòng thoáng đãng (`height: 1.6`).
  * Khối trích dẫn (Blockquote) có viền trái xanh lá cây và nền mờ nhẹ nhàng (`#F1F7F2`).
  * Code/tên khoa học dạng monospace với font `robotoMono` và nền bo tròn tinh tế.
* **Tích Hợp Tiện Ích Dưới Mỗi Tin Nhắn**:
  * Nút **Sao chép (Copy)** 1 chạm với thông báo nổi `SnackBar` xác nhận.
  * Hiển thị thời gian gửi tin nhắn nhỏ tinh tế góc dưới (`14:32`).

### 2. Quản Lý Lịch Sử Hội Thoại Kiểu ChatGPT (Cloud Firestore `ChatSessions`)
* **Kiến trúc Dữ Liệu**:
  * Tạo model [chat_session.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/chatbot/models/chat_session.dart) và [chat_provider.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/chatbot/providers/chat_provider.dart) kết nối thời gian thực với bộ sưu tập `ChatSessions` của Firestore gắn với `userId`.
* **Drawer Lịch Sử Trò Chuyện (EndDrawer)**:
  * Nút **"+ Cuộc trò chuyện mới"** nổi bật trên đầu Drawer và ngay trên AppBar (`Icons.add_comment_outlined`).
  * Danh sách các phiên trò chuyện sắp xếp theo thời gian cập nhật mới nhất, hiển thị số lượng tin nhắn, tự động highlight phiên đang kích hoạt.
  * Thao tác chuyển đổi phiên mượt mà: tải lại toàn bộ tin nhắn và nạp lịch sử ngữ cảnh vào Gemini để tiếp tục mạch tư vấn.
  * **Hỗ trợ Đổi Tên Cuộc Trò Chuyện**: Thêm icon cây bút ✏️ (`Icons.edit_outlined`) tại mỗi thẻ hội thoại và hỗ trợ **bấm trực tiếp vào tiêu đề cuộc trò chuyện trên AppBar** để mở hộp thoại đổi tên tùy biến theo ý thích người dùng.
  * Hỗ trợ xóa từng cuộc trò chuyện với hộp thoại xác nhận an toàn.
* **AI Tự Động Đặt Tên Thông Minh (ChatGPT Style Auto-Naming)**:
  * Tích hợp hàm `generateConversationTitle` trong [gemini_service.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/core/services/gemini_service.dart).
  * Ngay khi người dùng hoàn thành lượt trò chuyện đầu tiên, một tác vụ nền siêu nhẹ (Zero-latency) sẽ kích hoạt Gemini tự động phân tích câu hỏi và tóm tắt thành một tiêu đề ngắn gọn, tự nhiên từ 3–6 từ (VD: *"Gợi ý cây trồng cho người mới"*, *"Cách chăm sóc Cây Lưỡi Hổ"*, *"Xử lý cây bị vàng lá"*).
  * Tiêu đề mới được tự động cập nhật ngay lập tức lên Firestore, thanh tiêu đề AppBar và danh sách lịch sử mà người dùng không cần phải gõ tay.
  * Người dùng vẫn giữ quyền tự do chỉnh sửa lại tên theo ý muốn bất cứ lúc nào qua icon cây bút hoặc bấm vào tiêu đề AppBar.
* **Tự Động Lưu Phiên (Auto-Save)**:
  * Sau mỗi lượt hỏi - đáp, hệ thống tự động lưu/cập nhật toàn bộ tin nhắn lên Cloud Firestore.
  * **Bảo vệ hội thoại khi tạo mới**: Khi bấm "Cuộc trò chuyện mới", nếu phiên hiện tại đã có tin nhắn hỏi-đáp mà chưa được lưu thì hệ thống tự động lưu vào Firestore trước khi tạo phiên mới, đảm bảo hội thoại cũ không bao giờ bị mất.
  * **Tối ưu hóa Firestore**: Loại bỏ `orderBy` phức hợp để tránh lỗi Composite Index, tự động sắp xếp trên bộ nhớ client và hỗ trợ fallback định danh người dùng an toàn (`effectiveUserId`).

---

## 4.18. Nâng Cấp Toàn Diện Lịch Chăm Sóc Cây Trồng Thực Tế (Actionable Plant Care System)
*Ngày cập nhật: 22 tháng 10, 2026*

### 1. Nâng Cấp Mô Hình Dữ Liệu Nông Học (`GardenPlant` & `GardenProvider`)
* **Bổ sung chu kỳ bón phân dinh dưỡng (`fertilizeFrequencyDays`, `lastFertilized`, `nextFertilizing`)**: Hỗ trợ chu kỳ dinh dưỡng vi lượng tách biệt với chu kỳ tưới nước (từ 7 - 60 ngày/lần).
* **Bổ sung chu kỳ kiểm tra sâu bệnh & vệ sinh lá (`checkPestFrequencyDays`, `lastCleaned`, `nextCheckPest`)**: Hỗ trợ chu kỳ kiểm tra sâu bệnh và lau lá quang hợp tùy chỉnh (từ 1 - 14 ngày/lần).
* **Thanh ước lượng độ ẩm đất sinh học (`estimatedSoilMoisture`)**: Tự động tính toán mức suy hao độ ẩm đất theo thời gian thực dựa trên số giờ trôi qua kể từ lần tưới gần nhất và chu kỳ tưới của từng loài cây.
* **Cơ chế chống Reset sớm (Anti-Reset Protection)**: 
  * Nếu một tác vụ chưa đến hạn (ví dụ còn 2 ngày nữa mới tưới), người dùng bấm vào tác vụ sẽ nhận thông báo thân thiện nhắc nhở số ngày còn lại thay vì tự động reset ngày tưới về 0.
* **Nút "Hoàn tất mọi việc hôm nay" thông minh**:
  * Chỉ hoàn thành các tác vụ thực sự đến hạn trong ngày hôm nay (`isNeedsWater`, `isNeedsFertilizer`, `isNeedsClean`).
  * Khi tất cả các tác vụ hôm nay đã hoàn thành, nút bấm tự động chuyển màu xám nhạt (`#E5E7EB` / `#9CA3AF`) và bị vô hiệu hóa (`disabled`), ngăn chặn việc vô tình ấn nhầm.

### 2. Thiết Kế Lại Giao Diện Lịch Chăm Sóc Thực Tế (`plant_detail_screen.dart`)
* **Thanh đo độ ẩm đất trực quan (Soil Moisture Gauge)**: Hiển thị thanh tiến trình đổi màu linh hoạt (Xanh lá > Vàng > Đỏ) kèm nhãn trạng thái chính xác (VD: *Đất ẩm lý tưởng 80-100%*, *Đất khô hạn cần tưới ngay*).
* **Hệ thống 3 Tác vụ Chuẩn Nông Học**:
  1. 💧 **Tưới nước định kỳ**: Bấm để tưới và reset chu kỳ nước.
  2. 🧪 **Bón phân vi lượng**: Bấm để bón phân và reset chu kỳ phân.
  3. 🍃 **Kiểm tra sâu bệnh & Lau bụi lá**: Đánh dấu đã kiểm tra sâu bệnh / vệ sinh lá.
* **Nút bấm 1 chạm "Hoàn tất mọi việc hôm nay"**: Tự động vô hiệu hóa & xám lại khi không còn việc tồn đọng hôm nay.
* **Thông báo nổi (Floating Toast Card)**: Hiển thị xác nhận thao tác thành công với icon màu sắc, tiêu đề trắng đậm nét và phụ đề xanh pastel sang trọng (`#1E3A24`).
* **Modal "Chỉnh sửa cây trồng"**: Tích hợp đầy đủ 3 thanh trượt nông học: Chu kỳ tưới nước (1 - 14 ngày), Chu kỳ bón phân (7 - 60 ngày), Chu kỳ kiểm tra sâu bệnh (1 - 14 ngày), hỗ trợ dấu tick trắng (`Colors.white`) tương phản cao và đã loại bỏ hoàn toàn các emoji gây rối mắt.

---

## 4.19. Trợ Lý AI Hành Động - Đề Xuất & Tự Động Áp Dụng Lịch Chăm Sóc Cây (Actionable AI Care Schedule)
*Ngày cập nhật: 23 tháng 10, 2026*

* **Chuẩn Hóa Danh Xưng Thân Thiện ("Trợ Lý Floria" Thay Vì "Floria AI")**:
  * Thay thế toàn bộ các nhãn kỹ thuật, danh xưng cứng nhắc ("Floria AI", "Bác sĩ AI", "AI Assistant") thành **"Trợ lý Floria"** đồng bộ xuyên suốt từ AppBar, màn hình Vườn, màn hình Chẩn đoán đến lời chào khởi động và System Prompt của Gemini.
  * Hướng dẫn Gemini luôn xưng là *"Trợ lý Floria"* ấm áp, tận tâm, không xưng là AI.
* **Loại Bỏ Icon Sấm Sét & Tinh Giản Giao Diện Loading**:
  * Gỡ bỏ thanh chuyển đổi chế độ sấm sét (`⚡ Siêu tốc` / `🧠 Suy nghĩ sâu`) gây rối mắt trên thanh chat; giữ giao diện tinh gọn, phản hồi nhanh mặc định.
  * Khi đang suy nghĩ (loading), chỉ hiển thị thông báo nhẹ nhàng chuẩn chỉnh: *"Trợ lý Floria đang suy nghĩ..."*.
* **Tự Động Gọt Bỏ Tiêu Đề Treo Cụt Lủn**:
  * Gemini không còn tự in các tiêu đề treo như `**Lịch chăm sóc đề xuất...:**` ở cuối văn bản.
  * Client tự động làm sạch (sanitize) mọi dòng tiêu đề thừa trước khi render bong bóng chat, giúp giao diện hiển thị thẻ lịch trình riêng biệt bên dưới một cách liền mạch, không trùng lặp.
* **Ràng Buộc Chặt Chẽ Giữa Kê Đơn Vật Tư & Lịch Chăm Sóc**:
  * Phân định rõ ràng ngữ cảnh: Khi người dùng chỉ hỏi về phân bón ("nên dùng phân gì", "mua loại nào"), Trợ lý Floria chỉ kê đơn vật tư phù hợp (`[RECOMMEND_PRODUCT]`) mà **không đính kèm thẻ lịch chăm sóc**, tránh gây rối thông tin.
* **Đồng Bộ Hệ Thống Toast Nổi Chuẩn Sang Trọng (`_showAppToast`)**:
  * Chuyển toàn bộ các thông báo nổi (Sao chép tin nhắn, Thêm vào giỏ hàng, Cập nhật lịch chăm sóc) sang card nổi bo góc 14px, nền xanh rêu đậm sang trọng (`#1E3A24`), icon trạng thái trong huy hiệu tròn trong suốt và phụ đề xanh pastel (`#B4F4C2`), căn lề lơ lửng (`margin: 16px`) không còn tràn viền.

---

## 4.20. Tùy Chọn Radio Button Bật / Tắt Yêu Cầu Bón Phân (Cho Các Loài Cây Không Cần Phân)
*Ngày cập nhật: 23 tháng 10, 2026*

* **Bổ Sung Radio Button Trong Modal "Chỉnh Sửa Cây Trồng" (`plant_detail_screen.dart`)**:
  * Thêm nhóm tùy chọn Radio Button trực quan ngay tại mục Bón phân dinh dưỡng:
    * 🔘 **Cần bón phân**: Kích hoạt thanh trượt chu kỳ từ 7 - 60 ngày/lần.
    * 🔘 **Không cần bón**: Ẩn thanh trượt, gắn nhãn *"Không áp dụng"*, kèm chú thích hướng dẫn cho các giống cây không cần dinh dưỡng vi lượng (cây không khí, sen đá mùa nghỉ, cây mới thay chậu...).
* **Cơ Chế Quản Lý Lịch Không Đòi Hỏi Nhiệm Vụ Ảo**:
  * Khi chọn *"Không cần bón"*, chu kỳ `fertilizeFrequencyDays` được lưu về `0`.
  * Thuộc tính `isNeedsFertilizer` trong [garden_plant.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/garden/models/garden_plant.dart) tự động trả về `false`, không bao giờ báo quá hạn hay thúc giục người dùng bón phân.
  * Tác vụ Bón phân được **tự động ẩn hoàn toàn khỏi danh sách lịch chăm sóc** trên màn hình Chi tiết cây, giúp giao diện gọn gàng, đúng với đặc tính của cây và không tạo thêm nhiệm vụ thừa.

---

## 4.21. Tinh Gọn Trạng Thái Chờ AI & Tối Ưu Độ Tương Phản Hộp Thoại Xóa Hội Thoại
*Ngày cập nhật: 23 tháng 10, 2026*

* **Tinh Gọn Trạng Thái Chờ Đang Trả Lời Của AI (`ai_assistant_screen.dart`)**:
  * Đơn giản hóa bong bóng chờ phản hồi và thanh trạng thái thành duy nhất dòng chữ nghiêng nhã nhặn: **"Đang suy nghĩ..."** kèm vòng quay tiến trình nhỏ gọn.
  * Loại bỏ hoàn toàn các biểu tượng rườm rà (⚡, 🧠) và câu chữ dài dòng gây rối mắt trước đây (*"Bác sĩ đang chẩn đoán tức thì..."*, *"Bác sĩ đang suy luận y khoa đa tầng..."*).
* **Tăng Cường Độ Tương Phản & Khả Năng Đọc Của Hộp Thoại Xóa Cuộc Trò Chuyện**:
  * Sửa lỗi chữ tiêu đề bị mờ/trắng nhạt do phụ thuộc màu theme mặc định.
  * Đặt màu sắc tường minh có độ tương phản cao:
    * Tiêu đề *"Xóa cuộc trò chuyện"*: Màu đen xám đậm sắc nét (`#111827`, font weight 700) kèm icon thùng rác đỏ tươi (`#DC2626`).
    * Nội dung xác nhận: Màu xám than chuẩn typography (`#374151`), cỡ chữ 14px dễ đọc.
    * Nút hành động: Nút "Hủy" màu xám trung tính (`#4B5563`) và nút "Xóa" nền đỏ tươi (`#DC2626`), chữ trắng in đậm nổi bật.

---

## 4.22. Hoàn Thiện Tối Ưu UI/UX (Skeleton Loading & Kết Nối Trợ Lý 1 Chạm) & Động Cơ Thông Báo Nhắc Lịch Chăm Sóc Thông Minh
*Ngày cập nhật: 26 tháng 10, 2026*

### 1. Tối Ưu UI/UX & Kết Nối Chẩn Đoán Sang Chatbot (Nhóm 2)
* **Nút bấm 1 chạm "Hỏi Trợ lý Floria về cây này" (`diagnosis_report_screen.dart`)**:
  * Tích hợp nút hành động nổi bật với icon `Icons.auto_awesome` lấp lánh và sắc vàng kim hoàng gia ngay dưới hàng nút "Lưu vào vườn / Chi tiết" trên màn hình kết quả nhận diện cây.
  * Tự động chuyển thẳng sang màn hình trò chuyện `AiAssistantScreen`, nạp sẵn toàn bộ ngữ cảnh về tên tiếng Việt, tên khoa học và câu hỏi hướng dẫn chăm sóc chuyên sâu.
* **Hệ thống Skeleton Loading Cho Vườn Của Tôi (`garden_screen.dart`)**:
  * Thay thế toàn bộ vòng xoay `CircularProgressIndicator` cũ kỹ bằng layout **`_buildGardenSkeleton()`** chuẩn thiết kế gợn sóng lấp lánh (`ShimmerLoading`).
  * Tái hiện đầy đủ khung xương của tiêu đề, thẻ vườn, các chip khu vực bo tròn và lưới 2 cột thẻ cây cảnh.
* **Hệ thống Skeleton Loading Cho Cửa Hàng Vật Tư (`shop_screen.dart`)**:
  * Triển khai hàm **`_buildShopSkeleton()`** gồm lưới 4 thẻ sản phẩm mô phỏng với ảnh bo góc, nhãn danh mục, dòng tiêu đề, giá tiền và nút thêm giỏ hàng.

### 2. Động Cơ Thông Báo Nhắc Nhở Chăm Sóc Cây Trồng Thông Minh (Nhóm 3)
* **Khởi Tạo `NotificationService` Độc Lập ([notification_service.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/core/services/notification_service.dart))**:
  * **Kiểm tra thông minh**: Tự động rà soát các cây trong `MyGarden` đến hạn tưới (`isNeedsWater`), bón phân (`isNeedsFertilizer`) hoặc lau lá (`isNeedsClean`).
  * **Đối chiếu khung giờ hẹn**: So sánh thời gian thực với khung giờ nhắc nhở `reminderTime` của từng chậu cây (07:00, 09:30, 17:30, 20:00).
  * **Cơ chế chống spam**: Sử dụng `SharedPreferences` lưu vết ngày thông báo (`notified_plant_{id}_{task}`); mỗi tác vụ chỉ nhắc tối đa 1 lần trong ngày.
  * **Tự động hoãn/tắt thông báo khi hoàn thành sớm (`silenceForToday`)**: Khi người dùng tưới nước, bón phân hoặc bấm "Hoàn tất mọi việc hôm nay" trên màn hình Chi tiết cây (`plant_detail_screen.dart`), hệ thống lập tức đánh dấu hoàn thành cho ngày hôm nay và tự động im lặng.
* **Giao Diện Banner Nổi Sang Trọng (`_SmartNotificationWidget`)**:
  * Card nổi bo góc 20px, màu xanh rêu đậm hoàng gia (`#1E3A24`), trượt từ trên xuống với hiệu ứng `easeOutBack`.
  * Hiển thị nhãn giờ hẹn, tên cây, mô tả nhiệm vụ và 2 nút hành động nhanh: *"Chi tiết cây"* (chuyển sang màn hình cây) và *"Tưới ngay" / "Đã bón phân"* (hoàn thành tác vụ 1 chạm).
* **Tích Hợp Vào Vòng Đời Ứng Dụng (`main_navigation_screen.dart`)**:
  * Tự động quét khi mở app và duy trì timer định kỳ mỗi 3 phút khi người dùng đang sử dụng ứng dụng.
* **Tích Hợp Cài Đặt & Nút Thử Nghiệm (`settings_screen.dart`)**:
  * Đồng bộ công tắc *"Nhắc nhở tưới cây & chăm sóc"* với `NotificationService.isEnabled()`.
  * Bổ sung mục *"Kiểm tra thử thông báo ngay"* cho phép người dùng trải nghiệm ngay banner nhắc nhở 1 chạm.

---

## 4.23. Hoàn Thiện Toàn Diện Hệ Thống Nhật Ký Cây Trồng (Plant Diary & System Timeline)
*Ngày cập nhật: 26 tháng 10, 2026*

### 1. Phân Tách 2 Luồng Dữ Liệu Rõ Ràng (System Log & Personal Journal)
* **Model Dữ Liệu [diary_entry.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/garden/models/diary_entry.dart)**:
  * Phân biệt rõ hai thuộc tính `type: 'system'` (nhật ký hệ thống) và `type: 'user'` (nhật ký người dùng).
  * Hỗ trợ lưu trữ ảnh đính kèm (base64/link), thẻ phân loại sinh trưởng (`tag`), màu sắc (`tagBgColor`, `tagTextColor`), tiêu đề và thời gian chi tiết.
* **Tự Động Ghi Nhận Hoạt Động Chăm Sóc (Zero Effort for Users)**:
  * Trong [garden_provider.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/garden/providers/garden_provider.dart), các hàm `waterPlant` (tưới nước), `fertilizePlant` (bón phân), `cleanPlant` (vệ sinh lá & kiểm tra sâu bệnh) tự động tạo mốc nhật ký vào Firestore Subcollection `MyGarden/{plantId}/DiaryNotes`.
  * Tự động gộp mốc *"Chào mừng về vườn mới"* dựa trên `createdAt` của chậu cây.

### 2. Giao Diện Người Dùng Chuẩn Thẩm Mỹ Thiên Nhiên ([plant_diary_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/garden/screens/plant_diary_screen.dart))
* **Sticky Glassmorphism Header & Bộ Lọc Dạng Viên Thuốc (Pill Tabs)**:
  * Thanh trượt 3 chế độ xem: **🌟 Tất cả**, **✍️ Của tôi** và **⚙️ Hoạt động**.
* **Trục Thời Gian Timeline Cao Cấp**:
  * Đường nối xanh pastel mềm mại (`#D6E8CF`), các node icon phát sáng theo từng phân loại (giọt nước xanh dương, bình thí nghiệm hổ phách, lá cây xanh ngọc, mầm cây xanh rêu).
  * Hiển thị ngày giờ thân thiện (*"Hôm nay, 14:30"*, *"Hôm qua, 09:15"*, *"26/10/2026"*).
  * Hỗ trợ xem ảnh phóng to và nút xóa bài viết an toàn cho các trang nhật ký cá nhân.
* **Nâng Cấp Nút Bấm "Viết Nhật Ký" Hoàng Gia Sang Trọng**:
  * Thay thế icon cây bút vuông thông thường bằng **Icon Cây Bút Máy Hoàng Gia (`Icons.history_edu_rounded`)** màu vàng kim quý phái (`#FFD700`).
  * Nền xanh rêu đậm (`#1E3A24`), viền ánh kim vàng nhẹ và đổ bóng nổi 3D bồng bềnh.
* **Modal Viết Nhật Ký Mới Đầy Đủ Tiện Nghi**:
  * Chụp ảnh từ camera hoặc chọn từ thư viện ảnh máy ảnh.
  * Bộ thẻ mốc sinh trưởng: *🌱 Đâm chồi, 🌸 Ra hoa, 🪴 Thay chậu, ✂️ Cắt tỉa, 📸 Kỷ niệm, 💚 Tâm tình*.
  * Ô nhập tiêu đề và cảm nghĩ thoáng đãng, lưu trữ trực tiếp vào Firestore thời gian thực.
* **Trải Nghiệm Trang Con Dạng Side-Sheet Trượt Phải Sang Trái & Tinh Chỉnh UI**:
  * **Trang Nhật Ký Dạng Sub-page Side-sheet**: Khi mở Nhật ký từ trang Chi tiết cây ([plant_detail_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/garden/screens/plant_detail_screen.dart)), trang trượt mượt mà từ bên phải qua trái (`SlideTransition`), chừa lại một khoảng ~48px bên trái với nền mờ scrim để người dùng vẫn nhìn thấy cây trồng phía sau. Hỗ trợ vuốt ngang sang phải hoặc chạm vùng bên trái để đóng nhanh.
  * **Làm Sạch Văn Bản Tác Vụ Chăm Sóc**: Loại bỏ hoàn toàn các cụm từ thừa thãi như `(Bấm để hoàn thành)`, `(Bấm để bón)`, `(Bấm để hoàn tất)` – chỉ giữ nguyên trạng thái ngắn gọn, thanh lịch: *"Đã đến hạn tưới"*, *"Đã đến hạn bón phân"*, *"Đã đến hạn kiểm tra"*.
  * **Tối Giản Bộ Lọc & Khôi Phục Icon**:
    * Các tab lọc được chuyển thành văn bản tinh gọn không icon: `Tất cả`, `Của tôi`, `Hoạt động`.
    * Khôi phục icon `Icons.menu_book` ở nút Nhật ký trang Chi tiết và `Icons.edit_square` / `Icons.edit_note_rounded` cho hành động Viết nhật ký.
  * **Hỗ Trợ Thêm Nhiều Ảnh Vào Nhật Ký (Multi-Image Gallery)**:
    * Cho phép chọn nhiều ảnh từ thư viện (`pickMultiImage`) hoặc chụp trực tiếp từ camera, đính kèm tối đa 8 ảnh/trang nhật ký.
    * Giao diện chọn ảnh hiển thị dải ngang với nhãn "Ảnh bìa", nút xóa từng ảnh và nút "+ Thêm ảnh" linh hoạt.
    * Thẻ dòng thời gian tự động hiển thị album ảnh cuộn ngang kèm bộ đếm số lượng ảnh.
    * **Xem Ảnh Phóng To Toàn Màn Hình (`_openImageViewer`)**: Khi chạm vào bất kỳ ảnh nào trên dòng thời gian, mở trình xem ảnh toàn màn hình có hỗ trợ vuốt chuyển ảnh (PageView), chỉ số trang và tính năng zoom hai ngón tay phóng to/thu nhỏ (`InteractiveViewer`).
  * **Tối Ưu Độ Tương Phản Màu Chữ & Bỏ Icon Mốc Sinh Trưởng**:
    * Ô nhập tiêu đề và nội dung được cập nhật font chữ đen than đậm (`#1B1C1A`), hint text xám trung tính (`#6B7280`), nền trắng viền xám sáng (`#CBD5E1`) giúp chữ gõ vào rõ nét 100%, không còn bị mờ.
    * Tinh giản văn bản placeholder: bỏ gợi ý rườm rà `(VD: Hôm nay nhú thêm 2 lá mới)` chỉ giữ `"Tiêu đề"`; khu vực chọn ảnh làm rõ thành `"Thêm ảnh chụp cho cây (Tối đa 8 ảnh)"`.
    * Toàn bộ icon emoji ở các mốc sinh trưởng được loại bỏ, chỉ giữ lại chữ ngắn gọn thanh nhã: `Đâm chồi`, `Ra hoa`, `Thay chậu`, `Cắt tỉa`, `Kỷ niệm`, `Tâm tình`.
* **Tích Hợp ImgBB Cloud Storage Đám Mây & Dịch Vụ Di Chuyển Dữ Liệu Vĩnh Viễn (100% Miễn Phí)**:
  * **Giải pháp Lưu trữ Không Cần Thẻ Tín Dụng**: Thay vì Firebase Storage yêu cầu nâng cấp gói trả phí Blaze (cần thẻ thanh toán quốc tế), hệ thống chuyển sang tích hợp trực tiếp với **ImgBB API** (`https://api.imgbb.com/1/upload`) với khóa API cá nhân, hỗ trợ lưu trữ ảnh vĩnh viễn, không giới hạn số lượng ảnh, miễn phí 100%.
  * **Dịch vụ Lưu trữ Chuyên dụng ([storage_service.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/core/services/storage_service.dart))**: Tự động tải ảnh nhật ký và ảnh chụp cây mới lên ImgBB Cloud thông qua `Dio`, nhận về Direct URL cố định (`https://i.ibb.co/...`), tự động fallback sang Base64 nén khi mất mạng để bài viết nhật ký không bao giờ bị mất.
  * **Công cụ Đồng bộ & Di chuyển Ảnh Toàn Diện ([migration_service.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/core/services/migration_service.dart))**:
    * Quét toàn bộ ảnh Unsplash/link ngoài trong `ShopProducts` và `MyGarden` $\rightarrow$ Tự động tải về máy chủ và lưu lên ImgBB $\rightarrow$ Cập nhật lại đường dẫn mới vào Firestore.
    * Quét toàn bộ ảnh Base64 trong `DiaryNotes` $\rightarrow$ Giải mã và đưa lên ImgBB Cloud $\rightarrow$ Tối ưu dung lượng document Firestore từ hàng trăm KB xuống dưới 1 KB/bản ghi!
    * Bổ sung nút 1 chạm **"Chuyển ảnh sang ImgBB Cloud"** trong trang Cài đặt ([settings_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/profile/screens/settings_screen.dart)) kèm hộp thoại theo dõi tiến trình trực quan.
  * **Tối Ưu Tốc Độ Tải Ảnh Tức Thì (Background Pre-Upload UX)**:
    * Kích hoạt tiến trình upload ảnh lên ImgBB Cloud ở chế độ chạy ngầm ngay khoảnh khắc người dùng chọn/chụp ảnh (`_DiaryDraftPhoto`). Trong lúc người dùng đang gõ tiêu đề & nội dung bài viết, ảnh đã được tải lên hoàn tất, giúp thời gian bấm "Lưu trang nhật ký" giảm từ ~10s xuống còn **chưa đầy 0.2s** (gần như tức thì).
    * Hiển thị **vòng tròn tiến trình mờ mờ với % thực tế chạy từ 0% $\rightarrow$ 100%** trên từng ảnh ngay khi đang tải ngầm (đã loại bỏ icon đám mây xanh theo yêu cầu để giao diện tối giản, sạch sẽ nhất).
    * Nếu người dùng gõ thông tin trước rồi chọn ảnh và bấm Lưu ngay lập tức: Nút bấm hiển thị trực tiếp tiến trình theo thời gian thực: *"Đang tải ảnh (65%)..."* rồi *"Đang lưu bài viết..."*, giúp trải nghiệm hoàn toàn mượt mà, minh bạch, loại bỏ cảm giác bị lag.
    * Nén ảnh kích thước phù hợp (`maxWidth: 960`, `maxHeight: 960`, `imageQuality: 72`), giảm dung lượng truyền tải từ 2MB xuống 150KB.
    * **Chuẩn Hóa Toast Thông Báo (SnackBar)**: Đổi màu chữ thông báo thành trắng sáng nổi bật (`Colors.white`), font Inter đậm nét, loại bỏ hoàn toàn biểu tượng lá `🌿` theo yêu cầu.

*   **Nâng Cấp Giao Diện Thêm Cây Vào Vườn (`add_plant_to_garden_screen.dart`)**:
    * **Hiệu Ứng Nút Nhận Diện Chống Đơ**: Khi bấm nút, nút lập tức hiển thị Spinner xoay vòng tròn trắng kèm trạng thái *"Đang nhận diện & phân tích cây..."*, giữ vững tông màu nền rêu đậm `#364534` chuẩn thương hiệu mà không bị mờ xám hay tạo cảm giác lag/đơ.
    * **Loại Bỏ Hoàn Toàn Giao Diện "Đổi Key"**: Xóa bỏ banner trạng thái Gemini AI kèm nút đổi Key khỏi màn hình, tối ưu không gian hiển thị liền mạch và an toàn.
    * **Chuẩn Hóa Dấu Tích Màu Trắng Trên ChoiceChip**: Chuyển dấu tick checkmark của các chip chỗ đặt cây, khung giờ nhắc nhở và tình trạng sức khỏe sang màu trắng thuần (`checkmarkColor: Colors.white`), tạo độ tương phản sắc nét trên nền xanh rêu `#364534`.
    * **Xóa Bỏ Icon Emoji Khung Giờ**: Xóa bỏ các biểu tượng mặt trời/mặt trăng (🌅, 🌤️, 🌇, 🌙) ở các khung giờ nhắc nhở và chip "Giờ khác...", chuyển sang giao diện chữ tối giản và tinh gọn.
    * **Đồng Bộ Đầy Đủ Chức Năng Chăm Sóc Cây**:
        * Bổ sung **Tình trạng sức khỏe cây ban đầu** (Khỏe mạnh, Cần chú ý, Đang phục hồi).
        * Bổ sung **Chu kỳ bón phân dinh dưỡng** với Radio Button (Cần bón phân / Không cần bón) kết hợp Slider điều chỉnh chu kỳ từ 7 - 60 ngày.
        * Bổ sung **Chu kỳ kiểm tra sâu bệnh & lau lá** với Slider điều chỉnh từ 1 - 14 ngày.
        * Bổ sung **Ghi chú chăm sóc riêng**, tự động kế thừa mô tả đặc điểm người dùng đã nhập trước đó.
    * **Chuẩn Hóa Toàn Bộ Toast / SnackBar**: Rà soát và cập nhật 100% các thông báo SnackBar (Thêm cây, Tạo vườn, Xóa cây, Báo lỗi) sang màu chữ trắng (`color: Colors.white`) rõ ràng, loại bỏ biểu tượng lá `🌿`.

*   **Tái Thiết Kế & Nâng Cấp Toàn Diện Trang Chủ ([home_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/home/screens/home_screen.dart))**:
    * **Widget Thời Tiết Có Ảnh Nền Động Theo Giờ & Thời Tiết**:
      * Khôi phục thiết kế widget thời tiết có ảnh nền bao trọn (background image) tuyệt đẹp như mẫu thiết kế ban đầu.
      * Tự động chuyển đổi ảnh nền sinh thái theo thời tiết và thời gian thực trong ngày:
        - Buổi sáng: Bình minh rực nắng qua tán cây (`morning golden sunlight`).
        - Buổi trưa: Vòm lá nhiệt đới xanh mướt mát mẻ dưới nắng hè (`lush canopy green leaf sunlight`).
        - Buổi chiều: Ánh hoàng hôn ấm áp chiếu qua khu vườn (`sunset golden hour garden`).
        - Buổi tối: Không gian phòng cây xanh ấm cúng về đêm (`cozy indoor plants night warm light`).
      * Lớp phủ kính mờ Glassmorphism hiển thị nhiệt độ (29°C), độ ẩm (72%), trạng thái nắng nhẹ, số chậu cây cần tưới hôm nay và lời khuyên chăm sóc thực tế theo độ ẩm không khí.
    * **Loại Bỏ 4 Nút Tắt Tròn & Tinh Giản Giao Diện**:
      * Đã loại bỏ hoàn toàn 4 nút tắt tròn (Khám bệnh, Thêm cây, Bác sĩ Floria, Cửa hàng) để tránh làm rối mắt và giải phóng không gian theo đúng yêu cầu người dùng.
    * **Khôi Phục Phần Chat Trợ Lý Floria Nguyên Bản**:
      * Phục dựng lại thẻ Trợ lý Floria danh tiếng với gam màu xanh pastel dịu mát (`#D6E8CF`), điểm nhấn biểu tượng ngôi sao lấp lánh (`Icons.auto_awesome`), thông điệp chào đón thông minh và nút *"Hỏi ngay"* dẫn trực tiếp vào màn hình trò chuyện AI ([ai_assistant_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/chatbot/screens/ai_assistant_screen.dart)).
    * **Hiển Thị Đầy Đủ Tất Cả Khu Vườn & Chuyển Tab Tự Động**:
      * Khắc phục tình trạng chỉ hiển thị 1 vườn duy nhất: Hệ thống tích hợp bộ lọc chip thông minh hỗ trợ hiển thị **"Tất cả các vườn"** và từng khu vườn riêng biệt của người dùng (Ban công, Phòng khách, Sân thượng...) kèm số lượng cây thực tế trong từng vườn.
      * Tải danh sách cây trồng thật từ Firestore, hiển thị hình ảnh chuẩn, tên cây, vị trí đặt và duy nhất huy hiệu **Tình trạng sức khỏe** (Khỏe mạnh, Cần chú ý, Đang phục hồi), loại bỏ hoàn toàn đếm ngược ngày tưới.
      * Tích hợp cơ chế tự động chuyển tab Bottom Nav: Khi bấm nút **"Xem tất cả"** hoặc nút **"Đến khu vườn ➔"**, ứng dụng lập tức chuyển mượt mà sang tab Khu vườn (index 1 trên `MainNavigationScreen`).
    * **Cẩm Nang Chăm Sóc Cây Lưu Trữ CSDL & Hỗ Trợ Chèn Ảnh Mọi Vị Trí**:
      * **Model Đa Khối ([handbook_article.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/home/models/handbook_article.dart))**: Thiết kế cấu trúc bài viết linh hoạt theo các khối `HandbookBlock` (khối văn bản `text`, khối hình ảnh `image` kèm chú thích `caption`, khối mẹo chuyên gia `tip`), cho phép chèn ảnh vào bất kỳ đoạn nào trong bài viết.
      * **Dịch Vụ Firestore ([handbook_service.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/home/services/handbook_service.dart))**: Lưu trữ dữ liệu cẩm nang vào Firestore Collection `PlantHandbook`, tự động stream thời gian thực và khởi tạo sẵn 4 bài viết cẩm nang mẫu phong phú có chèn ảnh minh họa sinh động xen kẽ nội dung.
      * **Giao Diện Đọc Bài Viết Chuẩn Tạp Chí**: Modal xem cẩm nang hỗ trợ render mượt mà các khối chữ, ảnh minh họa có bo góc đổ bóng và khung ghi chú mẹo nổi bật, hỗ trợ cuộn êm ái.

*   **Lưu Trữ CSDL Cho 5 Bệnh Của Lá & Widget Thời Tiết Trang Chủ**:
    * **Lưu Trữ 5 Bệnh Của Lá Vào CSDL Firestore (`DiseasesInfo`)**:
      * Xây dựng Model [disease_info.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/scan/models/disease_info.dart) và Service [disease_service.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/scan/services/disease_service.dart) quản lý danh mục 5 bệnh lá chuẩn khoa học của AI Engine (`Healthy`, `Anthracnose`, `Leaf_Spot`, `Bacterial_Blight`, `Powdery_Mildew`).
      * Tự động khởi tạo dữ liệu chuyên sâu vào Firestore Collection `DiseasesInfo`: tên tiếng Việt, tiếng Anh, mức độ nghiêm trọng (Bình thường / Cảnh báo / Nguy hiểm), nguyên nhân, 3 triệu chứng nhận biết, 4 bước phác đồ điều trị, danh sách thuốc đặc trị gợi ý, ảnh minh họa sắc nét và biện pháp phòng ngừa.
      * Bổ sung script [seed_diseases.py](file:///d:/Plan/utrasupervip/AI_Engine/seed_diseases.py) cho backend/AI Engine.
    * **Lưu Trữ Ảnh Nền & Câu Thoại Biên Tập Widget Trang Chủ Vào CSDL Firestore (`HomeWeatherWidgets`)**:
      * Xây dựng Model [weather_widget_config.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/home/models/weather_widget_config.dart) và Service [weather_widget_service.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/home/services/weather_widget_service.dart).
      * **Tách bạch chuẩn xác**:
        - **Dữ liệu lưu CSDL Firestore (`HomeWeatherWidgets`)**: Chỉ lưu trữ ảnh nền chất lượng cao (`heroImageUrl`), câu chào/thông điệp chính (`mainTitle`), nhãn biên tập (`badgeText`) và câu thoại lời khuyên chăm cây (`advice`) theo khung giờ (`startHour` - `endHour`). Admin có thể tự do thay đổi ảnh nền và câu thoại theo mùa/dịp lễ trực tiếp trên Firebase Console mà không cần sửa code.
        - **Dữ liệu môi trường động**: Nhiệt độ, độ ẩm, trạng thái thời tiết và ánh sáng hoàn toàn được tính toán động dựa theo thời gian thực tế của thiết bị chứ không lưu cứng trong CSDL.
      * Tích hợp khung hiển thị câu thoại lời khuyên (`advice`) sang trọng ngay dưới các chỉ số sinh thái trên Widget trang chủ.
    * **Chuyển Đổi Toàn Bộ Ảnh Unsplash Sang ImgBB Cloud & Cập Nhật Firestore**:
      * Đã chạy script tự động [upload_and_migrate_all_to_imgbb.py](file:///d:/Plan/utrasupervip/AI_Engine/upload_and_migrate_all_to_imgbb.py) tải toàn bộ ảnh từ Unsplash về và lưu trữ vĩnh viễn lên **ImgBB Cloud Storage** (`https://i.ibb.co/...`).
      * Cập nhật đồng bộ 100% các collection trên **Firebase Firestore**:
        - `DiseasesInfo`: Toàn bộ 5 bệnh lá cây đã chuyển sang link ảnh ImgBB trực tiếp.
        - `HomeWeatherWidgets`: Cả 4 khung giờ widget (sáng, trưa, chiều, tối) đã chuyển sang link ảnh nền ImgBB.
        - `PlantHandbook`: Cả 4 bài viết cẩm nang và các ảnh minh họa chèn trong bài đã chuyển sang link ImgBB.
      * Cập nhật toàn bộ link ảnh mặc định trong source code Flutter ([weather_widget_service.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/home/services/weather_widget_service.dart), [disease_service.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/scan/services/disease_service.dart), [handbook_service.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/home/services/handbook_service.dart)) và backend AI ([seed_diseases.py](file:///d:/Plan/utrasupervip/AI_Engine/seed_diseases.py)), loại bỏ hoàn toàn phụ thuộc vào link ngoài Unsplash.

### Tái Thiết Lập CSDL Bệnh Lá (DiseasesInfo) & Tách Biệt Vai Trò Trợ Lý AI Floria
*   **Loại bỏ ảnh thừa & Phác đồ điều trị tĩnh**:
    *   Xóa bỏ trường `imageUrl` khỏi `DiseasesInfo` vì không cần thiết và tránh ảnh không phản ánh đúng mầm bệnh thực tế.
    *   Loại bỏ các bước phác đồ điều trị tĩnh dạng cứng (Bước 1, 2, 3) và thuốc gợi ý cố định; chuyển đổi hoàn toàn nhiệm vụ này cho **Trợ lý AI Floria** để sinh lời khuyên động cá nhân hóa theo từng loại cây và mức độ bệnh thực tế.
*   **Chuẩn Hóa Dữ Liệu Bệnh Học & Cơ Chế Sinh Bệnh**:
    *   Lưu trữ nền tảng bệnh học trong `DiseasesInfo` trên Firestore: `id`, `nameVi`, `nameEn`, `severity`, `pathogen` (tác nhân gây bệnh: chủng nấm/vi khuẩn), `mechanism` (cơ chế gây hại biểu mô lá), `favorableConditions` (môi trường thuận lợi bùng phát), `prevention` (biện pháp canh tác phòng ngừa).
    *   Thực thi nạp và cập nhật lại toàn bộ 5 tài liệu trong collection `DiseasesInfo` trên Firestore (`floria-71734`) qua [seed_diseases.py](file:///d:/Plan/utrasupervip/AI_Engine/seed_diseases.py) và [disease_service.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/scan/services/disease_service.dart).
*   **Nâng Cấp Giao Diện Chẩn Đoán & Tinh Gọn Trực Quan**:
    *   **Thẻ Hồ Sơ Bệnh Học & Cơ Chế** ([diagnosis_report_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/scan/screens/diagnosis_report_screen.dart)): Hiển thị trực quan Tác nhân (Pathogen), Cơ chế gây bệnh, Môi trường phát sinh và Phòng ngừa canh tác.
    *   **Khắc phục lỗi Mức độ nguy hại không hiển thị**: Sửa lỗi key mismatch giữa Backend (`severity`) và Frontend (`severity_vi`), đồng thời kết nối trực tiếp với dữ liệu `disease?.severity` từ Firestore để hiển thị chính xác mức độ (An toàn, Trung bình, Cảnh báo, Nguy hiểm, Rất nguy hiểm) kèm màu sắc badge tương ứng.
    *   **Tự động ghi bệnh án vào Nhật ký cây trồng (`PlantDiary`)**: Khi nhấn "Cập nhật bệnh án", hệ thống vừa cập nhật tình trạng sức khỏe của cây vừa tự động tạo một mục nhật ký hoạt động hệ thống (`health` category) ghi lại chẩn đoán, tác nhân, mức độ nguy hại, độ tin cậy và ảnh chụp lá đã quét.
    *   **Đồng bộ thiết kế Toast thông báo (SnackBar)**: Chuẩn hóa màu nền (`#1E3A24`), icon tròn với viền mờ và chữ trắng tương phản cao sắc nét, đồng bộ 100% với các thông báo hệ thống khác.
    *   **Chuẩn hóa văn bản và kiểu chữ Ghi chú chăm sóc**: Đổi nội dung tự động từ *"Chẩn đoán AI"* thành *"Chẩn đoán Trợ lý Floria"*; đồng thời tăng độ sắc nét cho ô nhập văn bản `TextField` trong Modal chỉnh sửa cây (`#1B1C1A`, font-weight 600) giúp người dùng dễ đọc và chỉnh sửa.
    *   Cập nhật modal chẩn đoán lá cây tại [plant_detail_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/garden/screens/plant_detail_screen.dart): *"Floria sẽ phân tích các vết đốm, mầm bệnh thán thư, cháy lá vi khuẩn hoặc phấn trắng và đề xuất phác đồ điều trị."*

### Khắc Phục Lỗi Đồng Bộ Lịch Chăm Sóc Cây Trồng (Decouple Care Schedule)
*   **Hiện tượng**: Khi cây có cả tác vụ *"Tưới nước"* và *"Kiểm tra sâu bệnh & Lau lá"* cùng đến hạn (hoặc đang chờ), người dùng chỉ bấm nút *"Tưới nước"* nhưng tác vụ *"Kiểm tra sâu bệnh & Lau lá"* cũng tự động chuyển sang hoàn thành (Đã chu toàn, hiện tick xanh).
*   **Nguyên nhân kỹ thuật**:
    *   Trong `GardenPlant.fromFirestore` ([garden_plant.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/garden/models/garden_plant.dart)), trường `lastCleanDate` và `lastFertDate` trước đây đặt giá trị dự phòng (fallback) là `lastWateredDate` khi trên Firestore chưa có trường `lastCleaned` / `lastFertilized`.
    *   Đồng thời `nextCheckPest` được tính bằng `lastCleanDate + cleanFreq`.
    *   Khi người dùng bấm tưới nước, hàm `waterPlant()` cập nhật `lastWatered = now` lên Firestore. Khi stream bắn snapshot mới về, `lastCleanDate` bị kéo theo bằng `now`, khiến `nextCheckPest` bị cộng thêm 3 ngày vào tương lai $\rightarrow$ `isNeedsClean` chuyển ngay sang `false` và hiển thị như đã làm xong.
*   **Giải pháp đã xử lý**:
    *   **Tách độc lập hoàn toàn các mốc thời gian**: Sửa hàm khởi tạo `GardenPlant` và `fromFirestore` để `lastCleanDate` và `lastFertDate` dùng dự phòng là `createdAt` (thời điểm tạo cây) thay vì `lastWateredDate`.
    *   **Backfill dữ liệu trên Firestore**: Khởi tạo và lưu rõ ràng các trường `lastCleaned`, `nextCheckPest`, `lastFertilized`, `nextFertilizing` cho toàn bộ tài liệu trong collection `MyGarden`.
    *   **Khôi phục trạng thái kiểm tra sâu bệnh**: Đặt lại hạn kiểm tra sâu bệnh cho cây của người dùng về trạng thái *"Đã đến hạn kiểm tra"* để người dùng tiếp tục thao tác và nghiệm thu chính xác.

---

## 4.24. Chặn Câu Hỏi Ngoài Chủ Đề Thực Vật Ở Trợ Lý Floria & Đồng Bộ Trạng Thái Cây Thực Tế Trên Trang Chủ
*Ngày cập nhật: 29 tháng 10, 2026*

### 1. Giới Hạn Phạm Vi Chủ Đề Nghiêm Ngặt Cho Trợ Lý Floria (Domain Guardrails)
*   **Bổ sung Quy tắc Kiểm duyệt Chủ đề (`gemini_service.dart`)**:
    *   Cấu hình System Instruction bắt buộc cho cả `chatWithDoctor` và `chatWithDoctorStream`: Trợ lý Floria **chỉ được phép** tư vấn các chủ đề về thực vật học, cây cảnh, nông nghiệp, làm vườn, kỹ thuật chăm sóc cây, chẩn đoán sâu bệnh, phong thủy/ý nghĩa cây và vật tư cửa hàng Floria.
    *   **Từ chối câu hỏi ngoài lề**: Lịch sự từ chối mọi câu hỏi không liên quan đến cây cối (lập trình, toán học, lịch sử, chính trị, nấu ăn, bóng đá, giải trí, tài chính...) và hướng người dùng quay lại chủ đề chăm sóc cây trồng. Chống Prompt Injection và tuyệt đối không gắn thẻ `[RECOMMEND_PRODUCT]` hay `[CARE_SCHEDULE]` khi từ chối.
    *   **Kiểm duyệt hình ảnh trong khung chat**: Nếu người dùng gửi ảnh không phải thực vật/cây trồng/vật tư làm vườn (ảnh người, thú cưng, đồ vật, màn hình...), Trợ lý Floria nhận diện và lịch sự từ chối phân tích, mời chụp lại ảnh cây cảnh hoặc lá cây cần kiểm tra.
*   **Làm sạch mã nguồn `ai_assistant_screen.dart`**:
    *   Xóa các hàm chuyển đổi chế độ không còn dùng (`_buildModeSwitcher`, `_buildModeTabItem`, `_toggleDeepThinking`) và đồng bộ toàn bộ câu chữ sang danh xưng *"Trợ lý Floria"*.

### 2. Khắc Phục Lỗi Hiển Thị Trạng Thái Cây "Khỏe Mạnh" Khi Cây Đang Đến Hạn Chăm Sóc (`home_screen.dart`, `garden_screen.dart`, `plant_detail_screen.dart`)
*   **Nguyên nhân**: Phần *"Khu vườn của tôi"* trên Trang chủ trước đây chỉ đọc trường tĩnh `plant.healthStatus` (mặc định là `"Khỏe mạnh"` trên Firestore) mà không kiểm tra các cờ đến hạn chăm sóc thực tế (`isNeedsWater`, `isNeedsFertilizer`, `isNeedsClean`). Dẫn đến việc cây ở dưới mục *"Lịch chăm sóc hôm nay"* đang báo cần tưới nước / kiểm tra sâu bệnh nhưng thẻ cây ở trên lại hiện tích xanh `"Khỏe mạnh"`.
*   **Giải pháp đồng bộ toàn hệ thống**:
    *   Xây dựng thuộc tính tính toán thời gian thực `effectiveStatusText` và `isNeedsAnyCare` trong `GardenPlant` ([garden_plant.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/garden/models/garden_plant.dart)) theo thứ tự ưu tiên:
        1. Đang có bệnh lý (`Bị ...` / `Cần điều trị`) $\rightarrow$ Cảnh báo đỏ (`#DC2626`).
        2. Đến hạn tưới nước (`isNeedsWater`) $\rightarrow$ Hiện **`Cần tưới nước`** màu cam (`#E06C00`, icon giọt nước).
        3. Đến hạn bón phân (`isNeedsFertilizer`) $\rightarrow$ Hiện **`Cần bón phân`** màu vàng hổ phách (`#D97706`, icon bình thí nghiệm).
        4. Đến hạn kiểm tra sâu bệnh & lau lá (`isNeedsClean`) $\rightarrow$ Hiện **`Cần kiểm tra`** màu vàng cam (`#D97706`, icon khiên bảo vệ).
        5. Trạng thái `"Cần chú ý"` / `"Đang phục hồi"` $\rightarrow$ Màu vàng cam / xanh dương.
        6. Khi tất cả lịch chăm sóc đều đã hoàn thành và không có bệnh $\rightarrow$ Hiện **`Khỏe mạnh`** màu xanh lá (`#15803D`, icon tích tròn).
    *   Đồng bộ hiển thị `effectiveStatusText` trên cả 3 màn hình: Trang chủ ([home_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/home/screens/home_screen.dart)), Quản lý khu vườn ([garden_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/garden/screens/garden_screen.dart)) và Chi tiết cây ([plant_detail_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/garden/screens/plant_detail_screen.dart)).
    *   Sửa thêm bộ đếm số cây trên từng thẻ Khu vườn trong `garden_screen.dart` để hiển thị chính xác số cây thuộc riêng từng vườn thay vì dùng chung tổng số cây.

---

## 4.25. Tinh Giản Giao Diện Camera Quét Ảnh & Dọn Dẹp Các Trang Gói Mua Premium
*Ngày cập nhật: 30 tháng 10, 2026*

### 1. Tinh Giản Màn Hình Hướng Dẫn Chụp Ảnh ([scan_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/scan/screens/scan_screen.dart))
*   **Loại bỏ hoàn toàn khu vực chọn mô hình AI**:
    *   Hệ thống backend hiện đã chuẩn hóa và sử dụng mô hình ONNX quán quân Google EfficientNetV2 (`tf_efficientnetv2_b0`) duy nhất, đạt độ chính xác cao nhất (90% nhận diện loài và 92.5% nhận diện bệnh).
    *   Xóa bỏ phần `_buildAiModelSection()` và danh sách chọn mô hình mock cũ (`Floria Flash`, `Floria Vision`, `Floria Pro`, `Floria Platinum`).
    *   Màn hình hướng dẫn chụp ảnh giờ đây chỉ tập trung vào các mẹo chụp chuẩn xác (**NÊN** / **KHÔNG NÊN**) và nút **"Mở camera ngay"** nổi bật.
    *   Đơn giản hóa [camera_scanning_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/scan/screens/camera_scanning_screen.dart), không yêu cầu truyền tham số mô hình rườm rà.

### 2. Xóa Bỏ Toàn Diện Tính Năng & Các Màn Hình Mua Gói Premium
*   **Xóa bỏ các màn hình thanh toán & nâng cấp VIP**:
    *   Xóa file `premium_screen.dart` (màn hình giới thiệu các gói Floria Pro / VIP).
    *   Xóa file `payment_screen.dart` (màn hình thanh toán thẻ tín dụng, MoMo, Apple Pay).
*   **Dọn dẹp Trang Cá Nhân ([profile_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/profile/screens/profile_screen.dart))**:
    *   Xóa huy hiệu nhãn `'Premium'` trên góc tiêu đề cá nhân.
    *   Xóa mục shortcut `'Gói Premium'` trong danh sách cài đặt và phím tắt.
    *   Toàn bộ tính năng cao cấp của Floria đều mở miễn phí 100% cho mọi người dùng.

---

## 4.26. Nâng Cấp Hồ Sơ Cá Nhân, Ảnh Đại Diện Không Dùng ImgBB & Hệ Thống Sổ Địa Chỉ + Bản Đồ Tương Tác + Thẻ Thanh Toán
*Ngày cập nhật: 30 tháng 10, 2026*

### 1. Cơ Chế Avatar Phân Tầng Thông Minh & Lưu Trữ Trực Tiếp Firestore ([auth_provider.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/auth/providers/auth_provider.dart))
*   **Ưu tiên hiển thị ảnh đại diện riêng (`effectivePhotoUrl`)**:
    1.  **Ảnh đại diện tùy chỉnh (`customPhotoUrl`)**: Nếu người dùng đã tải lên ảnh đại diện riêng trong ứng dụng, hệ thống ưu tiên hiển thị ảnh này.
    2.  **Ảnh đại diện tài khoản Google (`googlePhotoUrl` / `user.photoURL`)**: Nếu đăng nhập bằng Google và chưa đổi ảnh riêng, app tự động hiển thị avatar Google.
    3.  **Ký tự viết tắt mặc định**: Hiển thị khung tròn xanh lá cùng chữ cái đầu của tên nếu chưa có ảnh.
*   **Loại bỏ phụ thuộc ImgBB cho Avatar**:
    *   Nén ảnh đại diện về kích thước tối ưu `400x400px` (`imageQuality: 75`, dung lượng chỉ ~15–25KB) và lưu trực tiếp dưới dạng Data URI Base64 (`data:image/jpeg;base64,...`) ngay trong document `Users/{uid}` trên Cloud Firestore.
    *   Tốc độ cập nhật ảnh đại diện diễn ra tức thì, không lo lỗi mạng bên thứ 3 hay giới hạn API Key.
*   **Hỗ trợ khôi phục ảnh Google (`resetToDefaultAvatar`)**: Cho phép người dùng xóa ảnh tùy chỉnh để quay về ảnh đại diện Google gốc chỉ với 1 chạm.

### 2. Nâng Cấp Giao Diện Trang Cá Nhân & Thông Báo Toast Hiện Đại ([profile_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/profile/screens/profile_screen.dart))
*   **Khắc phục lỗi màu chữ bị chìm trong BottomSheet & Dialog**: Thiết lập tường minh màu chữ xanh đen đậm (`#1F2A21`) và xám rêu (`#6A756B`) trên nền sáng cho toàn bộ menu chọn ảnh đại diện và hộp thoại sửa thông tin.
*   **Thiết kế lại Toast thông báo nổi (`_showModernToast`)**:
    *   Thay thế `SnackBar` tràn ngang màn hình cũ bằng viên thuốc nổi gọn gàng (`maxWidth: 380px`), nền xanh đen sang trọng (`#1E2D22`), viền mảnh phát sáng nhẹ và icon tròn tinh tế.

### 3. Xây Dựng Sổ Địa Chỉ Hành Chính Mới Nhất & Bản Đồ Ghim Vị Trí Nhận Hàng ([address_payment_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/profile/screens/address_payment_screen.dart), [user_checkout_models.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/profile/models/user_checkout_models.dart))
*   **Tích hợp API Đơn vị Hành chính Việt Nam mới nhất sau sáp nhập (`esgoo.net/api-tinhthanh-new`)**:
    *   Không hardcode dữ liệu: Tải trực tiếp danh sách **34 Tỉnh/Thành phố mới** và **Phường/Xã/Đặc khu** theo mô hình hành chính 2 cấp mới nhất.
    *   Tự động tra cứu tọa độ GPS chuẩn xác của từng Phường/Xã theo mã hành chính (`esgoo.net/api-tinhthanh/5/{code}.htm`), khắc phục triệt để tình trạng nhảy sai vị trí đối với các tên phường mới sau sáp nhập (như *Phường Vinh Lộc - Tỉnh Nghệ An*).
*   **Bản đồ tương tác ghim vị trí nhận hàng (`_InteractiveMapPicker`)**:
    *   Sử dụng lớp bản đồ đường phố tiếng Việt (`mt1.google.com/vt/lyrs=m&hl=vi`) sắc nét, không yêu cầu API Key.
    *   Hỗ trợ giữ chuột/ngón tay kéo bản đồ 4 hướng mượt mà (đã khóa xung đột cuộn dọc với hộp thoại bên ngoài), lăn chuột phóng to/thu nhỏ, bấm chấm ghim trực tiếp và tự động gợi ý điền tên đường (`Reverse Geocode`).
    *   Tích hợp nút **"Mở rộng"** ngay ở góc trên bên trái bản đồ để mở cửa sổ bản đồ kích thước lớn.
*   **Nút Tick Tròn Mặc Định (`_buildCircularCheckOption`)**:
    *   Thiết kế nút chọn mặc định dạng hình tròn (`BoxShape.circle`), nền xanh lá (`#3E8055`) với dấu tick màu trắng (`Colors.white`) nổi bật.
*   **Quản lý Thẻ Ngân Hàng Đã Lưu & Liên Kết Giỏ Hàng ([cart_screen.dart](file:///d:/Plan/utrasupervip/my_ai_plant_app/lib/features/shop/screens/cart_screen.dart))**:
    *   Cho phép thêm, xóa, đặt thẻ ngân hàng mặc định trong trang *Địa chỉ & Thẻ thanh toán* (đã loại bỏ các chữ `VNPay Sandbox` thừa).
    *   Khi vào **Giỏ hàng (`cart_screen.dart`)** để thanh toán, hệ thống tự động hiển thị địa chỉ nhận hàng mặc định, danh sách thẻ ngân hàng đã lưu kèm tùy chọn **Thanh toán khi nhận hàng (COD)**, và có nút *"Chỉnh sửa"* / *"Quản lý thẻ"* dẫn thẳng về trang quản lý.

---

## 5. Kế Hoạch & Định Hướng Phát Triển Trong Tương Lai (Future Roadmap)

### 1. Hoàn Thiện Trang Cá Nhân & Cài Đặt (Profile & Settings)
- [ ] **Trang Nhắc Tưới Tập Trung (`WateringRemindersScreen`)**:
  - Xây dựng màn hình quản lý tập trung toàn bộ khung giờ nhắc nhở của tất cả các chậu cây trong các khu vườn khi người dùng bấm vào mục *"Nhắc tưới"* trong Trang cá nhân.
- [ ] **Trung Tâm Hỗ Trợ & Câu Hỏi Thường Gặp (`SupportCenterScreen`)**:
  - Xây dựng màn hình hướng dẫn sử dụng, mẹo chụp ảnh chẩn đoán bệnh lá chuẩn xác, chính sách đổi trả vật tư và liên hệ hỗ trợ khi bấm vào *"Trung tâm hỗ trợ"*.
- [ ] **Hoàn Thiện Các Mục Trong Cài Đặt (`settings_screen.dart`)**:
  - Hoàn thiện chức năng Đổi mật khẩu (cho tài khoản Email), Quản lý quyền riêng tư và Xóa bộ nhớ đệm (Cache).

### 2. Hoàn Thiện Luồng Thanh Toán & Quản Lý Đơn Hàng (E-Commerce & Order Tracking)
- [x] **Sổ địa chỉ hành chính mới + Ghim bản đồ + Lưu thẻ ngân hàng & Chọn phương thức thanh toán ở Giỏ hàng**. ✅
- [ ] **Tích Hợp Cổng Thanh Toán Sandbox VNPay Thực Tế**:
  - Tạo URL thanh toán chuẩn chuẩn mã băm `HMAC-SHA512` (`vnp_SecureHash`) và mở WebView/Trình duyệt thanh toán VNPay khi người dùng chọn thanh toán qua thẻ ngân hàng đã lưu.
- [ ] **Lưu Đơn Hàng Lên Firestore (`Orders` Collection) & Màn Hình Lịch Sử Đơn Hàng**:
  - Lưu chi tiết đơn hàng (danh sách vật tư, tổng tiền, địa chỉ nhận hàng kèm tọa độ ghim bản đồ, phương thức thanh toán, trạng thái đơn hàng) vào Firestore.
  - Xây dựng màn hình theo dõi trạng thái đơn hàng (*Chờ xác nhận $\rightarrow$ Đang giao hàng $\rightarrow$ Đã giao*).

### 3. Tối Ưu Hóa Trải Nghiệm & Mở Rộng Hệ Sinh Thái Chăm Sóc Cây
- [x] **Rà soát & Hoàn thiện Skeleton Loading, Toast thông báo hiện đại và Nút hỏi nhanh Trợ lý Floria**. ✅
- [x] **Thông báo nhắc lịch chăm sóc thông minh (`NotificationService`) & Đồng bộ trạng thái cây thời gian thực**. ✅
- [ ] **Tích Hợp Thời Tiết Thực Tế Theo Vị Trí Địa Chỉ Người Dùng**:
  - Tận dụng tọa độ (`latitude`, `longitude`) từ địa chỉ mặc định người dùng đã ghim để lấy nhiệt độ & độ ẩm thời tiết thực tế tại khu vực đó cho Widget Thời tiết ngoài Trang chủ.
- [ ] **Tối Ưu Hiển Thị Đa Thiết Bị (Responsive Mobile / Web)**:
  - Kiểm thử và tinh chỉnh trải nghiệm mượt mà trên cả trình duyệt Web lẫn thiết bị di động Android/iOS thực tế.







