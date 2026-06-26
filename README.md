# Hướng Dẫn Cài Đặt Dự Án AgriSmart (Floria)

Dự án Microservices bao gồm 3 thành phần chính. Dưới đây là các lệnh để cài đặt thư viện cho từng phần:

## 1. AI Engine (Python)
- Di chuyển vào thư mục: `cd AI_Engine`
- Tạo môi trường ảo (nếu chưa có): `python -m venv .venv`
- Kích hoạt môi trường ảo: `.\.venv\Scripts\activate`
- Cài đặt thư viện: `pip install -r requirements.txt`
*(Các thư viện chính: tensorflow, keras, fastapi, uvicorn, pillow, ...)*

## 2. Central Backend (Java Spring Boot)
- Di chuyển vào thư mục: `cd Backend`
- Spring Boot sử dụng Maven. Khi bạn chạy lệnh `mvnw.cmd spring-boot:run` (hoặc mở bằng VS Code/IntelliJ), Maven sẽ tự động đọc file `pom.xml` và tải toàn bộ thư viện về.
*(Các thư viện chính: spring-web, spring-boot-starter, firebase-admin, ...)*

## 3. Mobile App (Flutter)
- Di chuyển vào thư mục: `cd my_ai_plant_app`
- Cài đặt thư viện: `flutter pub get`
*(Các thư viện chính: provider, camera, google_fonts, dio, firebase_auth, ...)*

## 4. Web Frontend (Next.js)
- Di chuyển vào thư mục: `cd web_frontend_app`
- Cài đặt thư viện: `npm install`
*(Các thư viện chính: next, react, tailwindcss, framer-motion, ...)*

---
**🚀 Cách chạy nhanh tất cả:**
Chỉ cần nhấp đúp vào file `start_all.bat` ở thư mục gốc, hệ thống sẽ tự động khởi chạy AI Engine, Spring Boot và Flutter Web cùng lúc!
