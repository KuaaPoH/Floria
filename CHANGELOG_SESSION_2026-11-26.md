# Nhật ký cập nhật ca làm việc (26/11/2026)

## 1. AI & Mô hình Gemini (`floria_web` + `floria_app`)
- Cập nhật ưu tiên model `gemini-3.8-flash` kèm danh sách dự phòng thế hệ 3 (`gemini-3-flash-preview`, `gemini-3.5-flash-lite`, `gemini-3.1-flash-lite`, `gemini-3.1-flash-lite-preview`, `gemini-3.6-flash`) cho:
  - Web User: `floria_web/src/app/api/user/scan/route.ts`, `floria_web/src/app/api/user/assistant/route.ts`
  - Web Admin: `floria_web/src/app/admin/assistant/page.tsx`, `floria_web/src/app/api/admin/assistant/config/route.ts`, `floria_web/src/app/api/admin/assistant/sandbox/route.ts`
  - Mobile App: `floria_app/lib/core/services/gemini_service.dart`
- Sửa lỗi gọi `flash-lite` bị `HTTP 400 INVALID_ARGUMENT` do gửi kèm `thinkingConfig` trên app, bổ sung timeout 12s mỗi model và log chi tiết lỗi từng model trên cả App, Web User và Web Admin.
- Dọn dẹp prompt cứng và danh sách cứng `database40Plants` trong `gemini_service.dart`, chuyển sang đọc trực tiếp từ cấu hình Admin (`AiConfigService`) và collection `plants_info` trên Firestore.
- Bỏ emoji trong lời chào/câu trả lời chat trên App, bổ sung rule định dạng sạch (`gr_clean_format`) trong Admin, và sửa bộ render chat Web (`RichText` trong `floria_web/src/features/assistant/components.tsx`) để không hiện raw `###` / `**`.
- Lọc sạch các thẻ JSON `[RECOMMEND_PRODUCT]{...}[/RECOMMEND_PRODUCT]` và `[CARE_SCHEDULE]{...}[/CARE_SCHEDULE]` khi đồng bộ lịch sử chat từ Web sang App.

## 2. Loại bỏ nguồn Mock dự phòng ở chế độ API (`floria_web`)
- Bỏ tự động fallback sang dữ liệu mock khi mất kết nối backend trong `content.service.ts`, `commerce.service.ts`, `garden.service.ts`, `scan.service.ts`, `hooks/queries.ts` và `api/user/catalog/route.ts`.
- Chuẩn hóa thông báo `"Mất kết nối máy chủ"` trong `http.ts`, `common.ts` và bổ sung `ErrorState` kèm nút Thử lại trên các trang chi tiết cây, chẩn đoán bệnh và kết quả quét.

## 3. Giao diện Web Người dùng (`floria_web`)
- **Trang chủ chưa đăng nhập (`app/page.tsx`) & Thương hiệu**:
  - Thay logo header/footer sang `/logo.jpg`, cập nhật tiêu đề tab Chrome thành `Floria` và favicon thành `/logo.png` (`app/layout.tsx`, giữ riêng `Floria Admin` + `/adminicon.jpg` cho `/admin`).
  - Thay thẻ kết quả động Hero bằng `/mascot_chao_mung.png` với hiệu ứng chuyển động `animate-float`, bỏ tag `Modern Botanical · Digital Garden`, xóa mục Cửa hàng ở trang chủ và loại bỏ các chữ `AI`, `40 loài cây`.
- **Trang Tổng quan (`dashboard/page.tsx` & `WeatherCard.tsx`)**:
  - Đồng bộ ảnh Hero theo 4 khung giờ `HomeWeatherWidgets` do Admin quản lý.
  - Bỏ text gợi ý viết cứng ở `WeatherCard`, chuyển sang dùng đúng quy tắc vi khí hậu `WeatherAdviceRules` từ Admin (khớp logic `conditionType` với App).
  - Đồng bộ logic **Việc cần làm hôm nay** (`api/user/gardens/route.ts`, `features/garden/logic.ts`) khớp với App: chu kỳ `<= 0` ngày giữ `enabled: false`, và chỉ tính đến hạn trong vòng `<= 12 giờ`.
- **Cẩm nang (`handbook/page.tsx`, `handbook/[slug]/page.tsx`)**:
  - Xóa tag `phút đọc` trên Tổng quan, Trang chủ và Cẩm nang.
  - Render các URL ảnh trong nội dung bài viết thành thẻ `<img>`.
  - Bỏ danh sách tag danh mục cố định, dùng trực tiếp trường `category` thực tế từ `PlantHandbook` trên Firestore.
- **Chẩn đoán bệnh & Trợ lý & Cài đặt**:
  - Xóa mục **Sản phẩm hỗ trợ** trên trang chẩn đoán bệnh (`diagnosis/page.tsx`).
  - Đổi avatar Trợ lý Floria trên Web sang `/mascot_avatar_chatbot.png`.
  - Đồng bộ bộ 6 avatar mẫu ở trang Hồ sơ/Cài đặt (`BotanicalAvatar.tsx`) theo `FloriaAvatarPreset` của App.
  - Xóa mục **Nhắc nhở** trong `ProfileShell.tsx`, xóa hiển thị phiên bản `v0.0.1` ở trang Cài đặt và Footer.
- **Cửa hàng (`shop/page.tsx` & `shop_screen.dart`)**:
  - Banner lớn hiển thị các sản phẩm có tag `hot` (tự động chuyển mỗi 10 giây nếu có nhiều hơn 1 sản phẩm) trên cả Web và App.
  - Xóa 2 mục **Bán chạy nhất** và **Sản phẩm mới** trên Web Shop.
- **Tách biệt luồng đăng nhập Admin & User**:
  - Sử dụng `floria_portal_scope` để tách riêng phiên `/admin` và phiên User: vào `/admin` bắt buộc đăng nhập Admin, và khi rời `/admin` quay về trang User sẽ tự đăng xuất phiên Admin để yêu cầu đăng nhập User.

## 4. Ứng dụng Di động (`floria_app`)
- **Xem chi tiết & Quét cây (`plant_wiki_screen.dart`, `plant_detail_screen.dart`)**: Cho phép bấm vào các ô thông số bị rút gọn (`...`) để mở hộp thoại xem đầy đủ nội dung.
- **Nhật ký cây (`plant_diary_screen.dart`)**: Bổ sung `viewPadding.bottom` cho modal **Trang nhật ký mới** để nút **Lưu trang nhật ký** không bị thanh điều hướng Android che mất.
- **Thông báo chăm sóc (`notification_service.dart`)**: Sửa cơ chế nhắc nhở đảm bảo mỗi cây đến hạn chỉ thông báo đúng 1 lần/ngày vào đúng khung giờ đã cài đặt.

## 5. Kiểm tra
- `npm --prefix floria_web run typecheck`: đạt (không lỗi TypeScript).
- `npm --prefix floria_web run test`: đạt (2 file test / 10 tests passed).
- `dart analyze` trên các file đã sửa của `floria_app`: `No issues found!`.
