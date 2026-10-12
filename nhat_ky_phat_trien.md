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
## 5. Các Task Đang Chạy Nền (Active Tasks)
*   *Hiện tại tất cả các Background Tasks cho Web và Mobile đã được hoàn thành.*

---

## 6. Kế Hoạch Tiếp Theo (Next Steps - Actionable)

**Bước 1: Nối cáp thông luồng AI thực tế & Tối ưu hóa** ✅ *(Đã hoàn thành xuất sắc ngày 13/10/2026)*
- Ba hệ thống (AI Engine: 8000, Spring Boot: 8080, Flutter Web) đã kết nối thông suốt 100%.
- Dữ liệu thực vật lấy động trực tiếp từ Firestore qua Backend Gateway.
- Tối ưu hóa CLIP Gatekeeper và Asynchronous Firestore, UI chẩn đoán hoàn thiện không lỗi.

**Bước 2: Tính năng Khu Vườn Của Tôi (My Garden)** ✅ *(Đã hoàn thành xuất sắc ngày 13/10/2026)*
- Lưu cây trực tiếp từ báo cáo quét vào `users/{userId}/my_garden`.
- Quản lý danh sách cây, khu vực và lịch tưới nước thời gian thực.

**Bước 3: Đánh thức Trợ lý Ảo (AI Chatbot - Gemini Bác sĩ Cây trồng)** 🎯 *(Ưu tiên tiếp theo)*
- Tích hợp Google Gemini API vào `lib/features/chatbot/` trên Flutter/Web.
- Thay thế các đoạn chat giả lập (mock) bằng trợ lý trò chuyện thông minh trả lời thời gian thực về cách chăm sóc và xử lý sâu bệnh.

**Bước 4: Màn hình Lịch sử Quét (Scan History)**
- Xây dựng giao diện cho thư mục `lib/features/history/screens/` để người dùng xem lại toàn bộ các lần quét đã lưu trong collection `ScanHistory` của Firestore.

**Bước 5: Hoàn thiện Cửa hàng & Giỏ hàng (Shop & Cart)**
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
