# DÀN Ý CHI TIẾT BÁO CÁO ĐỒ ÁN TỐT NGHIỆP: HỆ THỐNG FLORIA

- **Tên đề tài:** *Nghiên cứu và xây dựng hệ thống nhận diện, chẩn đoán bệnh và hỗ trợ chăm sóc cây cảnh ứng dụng Học sâu* (Hệ thống **Floria**)
- **Chuẩn định dạng bám theo:** [mau.md](file:///d:/Plan/utrasupervip/baocao/mau.md) (Trường ĐH Vinh – Trường Kỹ thuật và Công nghệ – Khoa CNTT)
- **Độ dài mục tiêu:** **~45–52 trang Word (~11.500–13.000 từ)** (tương đương quy mô của [baocaohocmay.md](file:///d:/Plan/utrasupervip/baocao/baocaohocmay.md) và [baocaoapp.md](file:///D:/Plan/utrasupervip/baocao/baocaoapp.md))
- **Cấu trúc tổng thể:** Phần đầu + **3 Chương** + Kết luận + Tài liệu tham khảo

---

## PHẦN ĐẦU & MỞ ĐẦU (~6–8 trang | ~1.500–1.800 từ phần Mở đầu)

> **Lưu ý:** Do báo cáo chỉ chia 3 Chương (bắt đầu Chương 1 từ phần Nghiên cứu AI), phần **MỞ ĐẦU** được thiết kế gộp trọn vẹn cả nội dung Tổng quan / Mô tả bài toán / Khảo sát nghiệp vụ & Ứng dụng tương đồng (tương ứng Phần Mở đầu + Chương 1 của mẫu tham khảo ĐH Vinh).

1. **Trang bìa ngoài** *(theo mẫu ĐATN ĐH Vinh: Trường ĐH Vinh, Trường Kỹ thuật & Công nghệ, Tên SV, ĐỒ ÁN TỐT NGHIỆP ĐẠI HỌC – NGÀNH CNTT, Tên đề tài, Nghệ An, .../2026)*
2. **Trang bìa lót (Trang phụ bìa)** *(bổ sung Giảng viên hướng dẫn, Mã sinh viên, Lớp)*
3. **LỜI CAM ĐOAN** *(theo chuẩn ĐATN ĐH Vinh)*
4. **LỜI CẢM ƠN** *(và Bảng phân công nhiệm vụ nếu thực hiện theo nhóm)*
5. **DANH MỤC CÁC HÌNH** *(Hình 1.1, Hình 2.1, Hình 3.1...)*
6. **DANH MỤC CÁC BẢNG** *(Bảng 0.1, Bảng 1.1, Bảng 2.1...)*
7. **DANH MỤC CÁC TỪ VIẾT TẮT** *(AI, CNN, ViT, ONNX, CLIP, LLM, REST, UI/UX, CRUD, UML...)*
8. **MỤC LỤC**
9. **MỞ ĐẦU** *(~4–6 trang, gồm 6 tiểu mục gộp trọn Mở đầu + Tổng quan bài toán)*
   - **1. Lý do chọn đề tài và bài toán đặt ra** *(tính cấp thiết + 3 khó khăn thực tế trong trồng/chăm cây cảnh)*
   - **2. Khảo sát nghiệp vụ và các hệ thống liên quan** *(mô hình tổ chức Người dùng App/Web & Quản trị viên Web Admin; quy trình nghiệp vụ 4 bước; khảo sát PictureThis, Planta, PlantNet + Bảng 0.1 so sánh)*
   - **3. Mục đích thực hiện và hình thành ý tưởng hệ thống** *(mục tiêu nghiên cứu AI, kiến trúc hệ thống, sản phẩm đa nền tảng + 4 khối chức năng cốt lõi của Floria)*
   - **4. Đối tượng và phạm vi thực hiện** *(40 loài cây / 77.252 ảnh, 5 nhóm bệnh / 2.307 ảnh, App + Web + Backend)*
   - **5. Nội dung và phương pháp thực hiện** *(Nội dung về lý thuyết & thực tiễn; Phương pháp nghiên cứu tài liệu, thực nghiệm định lượng, phân tích thiết kế & kiểm thử)*
   - **6. Cấu trúc của đồ án** *(tóm tắt Chương 1, Chương 2, Chương 3)*

---

## CHƯƠNG 1. NGHIÊN CỨU, HUẤN LUYỆN VÀ ĐÁNH GIÁ MÔ HÌNH HỌC SÂU (~14–16 trang | ~4.000 từ)

> **Trọng tâm:** Chắt lọc tinh túy từ văn phong của `baocaohocmay.md`, sử dụng dữ liệu và kết quả thực tế từ `traincay.ipynb`, `trainbenh.ipynb` và `AI_Engine/main.py`.

### 1.1. Phát biểu bài toán và hướng tiếp cận (~1.5 trang)
- Bài toán 1: Phân loại 40 loài cây cảnh phổ biến (Multi-class Image Classification) dựa trên `AI_Engine/models/labels.txt`.
- Bài toán 2: Chẩn đoán 5 nhóm bệnh lá cốt lõi (`Healthy`, `Anthracnose`, `Leaf_Spot`, `Bacterial_Blight`, `Powdery_Mildew`) dựa trên `AI_Engine/models/disease_labels.txt`.
- Thách thức thực tế: Ảnh chụp ngoài thực tế (*in-the-wild*) có ánh sáng phức tạp, góc chụp đa dạng, độ tương đồng hình thái giữa các loài cùng họ (VD: *Alocasia*, *Calathea*, *Dracaena*, *Ficus*), và nguy cơ người dùng chụp ảnh không phải thực vật (ảnh tối, đồ vật, người/động vật).
- Hướng tiếp cận giải pháp: Transfer Learning trên các mạng gọn nhẹ (`timm`), tích hợp tiền kiểm duyệt Zero-shot bằng **CLIP Gatekeeper**, tối ưu tốc độ suy luận CPU bằng **ONNX Runtime**, và kết hợp **Gemini LLM** xử lý các loài cây nằm ngoài danh mục 40 loài.

### 1.2. Cơ sở lý thuyết các kiến trúc học sâu sử dụng (~2.5 trang)
*(Trình bày ngắn gọn bản chất kiến trúc & lý do lựa chọn, tránh viết quá dài lý thuyết CNN cơ bản)*
- **1.2.1. Tổng quan Transfer Learning và bài toán phân loại ảnh**
- **1.2.2. Kiến trúc EfficientNetV2 (`tf_efficientnetv2_b0`):** Fused-MBConv, Progressive Learning, cân bằng giữa độ chính xác và tốc độ.
- **1.2.3. Kiến trúc GhostNetV2 (`ghostnetv2_100`):** Ghost Module & DFC Attention giảm chi phí tính toán.
- **1.2.4. Kiến trúc MobileNetV3 (`mobilenetv3_large_100`):** Neural Architecture Search, Hard-Swish và Squeeze-and-Excitation cho thiết bị nhẹ.
- **1.2.5. Mô hình CLIP (`openai/clip-vit-base-patch32`) và chuẩn ONNX Runtime:** So khớp đặc trưng ảnh–văn bản Zero-shot làm bộ lọc đầu vào; tối ưu đồ thị tính toán với `opset_version=18`.

### 1.3. Thu thập, chuẩn bị và trực quan hóa dữ liệu (~3.5 trang)
- **1.3.1. Bộ dữ liệu nhận diện 40 loài cây cảnh (`traincay.ipynb` / `dataset_sach.zip`):**
  - *Nguồn thu thập:* Sưu tầm tổng hợp từ nhiều nguồn trên Internet bằng công cụ thu thập/cào ảnh tự động phân loại theo từng thư mục loài cây (Directory-based Labeling), sau đó rà soát lọc sạch ảnh nhiễu và tăng cường dữ liệu (Augmentation).
  - *Quy mô & phân chia:* Tổng **77.252 ảnh** RGB chuẩn hóa `224x224`, chia Stratified Split **80/10/10**: **Train = 61.801 ảnh**, **Validation = 7.725 ảnh**, **Test = 7.726 ảnh**.
  - *Bảng 1.1:* Thống kê thuộc tính và phân bổ bộ dữ liệu 40 loài cây.
  - *Hình 1.1 & 1.2:* Ảnh mẫu các loài cây (`All_Classes_Preview.png`) & biểu đồ phân bố số lượng ảnh (`Data_Distribution.png`).
- **1.3.2. Bộ dữ liệu chẩn đoán 5 nhóm bệnh lá (`trainbenh.ipynb`):**
  - *Nguồn thu thập:* Tổng hợp từ 3 bộ dataset công khai chuẩn mực: **PlantDoc Dataset (Kaggle)**, **Indoor Plant Disease Dataset (Roboflow Universe)**, và **Mango Leaf Disease Dataset (Kaggle)**.
  - *Quy mô & phân chia:* Tổng **2.307 ảnh** thuộc 5 lớp (`Anthracnose`, `Bacterial_Blight`, `Healthy`, `Leaf_Spot`, `Powdery_Mildew`), chia Stratified Split **80/10/10**: **Train = 1.845 ảnh**, **Validation = 231 ảnh**, **Test = 231 ảnh**.
  - *Bảng 1.2:* Thống kê bộ dữ liệu 5 nhóm bệnh lá và đặc điểm triệu chứng.
  - *Hình 1.3:* Ảnh đại diện 5 nhóm bệnh (`Disease_Classes_Preview.png`).

### 1.4. Cài đặt và quy trình huấn luyện mô hình (~3 trang)
*(Chỉ trích các đoạn code/cấu hình quan trọng nhất kèm giải thích kỹ thuật)*
- **1.4.1. Môi trường thực nghiệm:** Google Colab GPU **Tesla T4 (14.56 GB VRAM)**, PyTorch, `timm`, `albumentations`, `torchmetrics`, `onnx`, `onnxruntime`, `onnxscript`, cố định seed (`42`).
- **1.4.2. Đường ống tiền xử lý và cân bằng dữ liệu:** Resize + RandomCrop (`224x224`), Data Augmentation, chuẩn hóa ImageNet (`mean=[0.485, 0.456, 0.406]`, `std=[0.229, 0.224, 0.225]`), lọc ảnh tối/đơn sắc, xử lý mất cân bằng lớp bằng `WeightedRandomSampler`.
- **1.4.3. Chiến lược huấn luyện tinh chỉnh (Fine-tuning) & xuất ONNX:**
  - Optimizer `AdamW` với 2 mức learning rate phân biệt (`BACKBONE_LR = 1e-4`, `LEARNING_RATE = 1e-3`, `WEIGHT_DECAY = 1e-2`, `DROPOUT_RATE = 0.5`).
  - Lịch giảm tốc `CosineAnnealingLR`, **Mixed Precision (FP16)**, `BATCH_SIZE = 32`, `EPOCHS = 50` (40 loài cây) / `15` (5 nhóm bệnh), cơ chế **Auto-Resume** lưu checkpoint chống ngắt kết nối.
  - Đóng gói triển khai sang ONNX (`tf_efficientnetv2_b0.onnx` & `tf_efficientnetv2_b0_disease.onnx`).

### 1.5. Thực nghiệm, đánh giá và lựa chọn mô hình (~4–4.5 trang)
- **1.5.1. Các độ đo đánh giá:** Accuracy, Precision, Recall, F1-Score, ROC-AUC, tốc độ suy luận (FPS / Latency).
- **1.5.2. Kết quả nhận diện 40 loài cây cảnh:**
  - Bảng so sánh hiệu năng (`tf_efficientnetv2_b0`, `ghostnetv2_100`, `mobilenetv3_large_100`), đồ thị Loss/Accuracy qua các epoch, phân tích trường hợp nhầm lẫn giữa các loài cùng chi/họ. *(Lưu ý: cần xuất bảng metrics & hình từ Drive cho đủ 3 mô hình nếu log `traincay.ipynb` chưa chạy hết).*
- **1.5.3. Kết quả chẩn đoán 5 nhóm bệnh lá:**
  - Bảng so sánh 3 mô hình (`mobilenetv3_large_100`, `tf_efficientnetv2_b0`, `ghostnetv2_100`), biểu đồ tổng hợp (`GLOBAL_DISEASE_COMPARISON.png`), đường cong ROC và Confusion Matrix.
- **1.5.4. Kết luận lựa chọn mô hình & thiết kế luồng suy luận đa tầng (`AI_Engine/main.py`):**
  - Chọn **`tf_efficientnetv2_b0`** làm mô hình chính cho cả 2 tác vụ: **~90.0% Accuracy / ~90.0% F1 / ~438 FPS** (40 loài) và **~92.5% Accuracy / ~90.8% F1 / ~106 FPS** (5 nhóm bệnh).
  - Sơ đồ Pipeline suy luận thời gian thực: Kiểm tra độ tương phản (`np.std < 15.0`) $\rightarrow$ CLIP Gatekeeper (lọc ảnh không phải thực vật, cache text features khi khởi động) $\rightarrow$ ONNX Inference $\rightarrow$ Ngưỡng `confidence < 50%` chuyển sang Gemini LLM.

---

## CHƯƠNG 2. PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG FLORIA (~12–14 trang | ~3.300 từ)

> **Trọng tâm:** Thiết kế phần mềm theo chuẩn Chương 2 của `baocaoapp.md`, bao quát cả Mobile App (`floria_app`), Backend/AI và cổng Web User/Admin (`floria_web`).

### 2.1. Đặc tả yêu cầu hệ thống (~2 trang)
- **2.1.1. Yêu cầu chức năng (theo 2 tác nhân Người dùng App/Web & Nhóm Web Admin):**
  - *Bảng 2.1:* Tổng hợp yêu cầu chức năng chi tiết cho **Người dùng** (quét nhận diện cây, quét bệnh lá, bách khoa toàn thư & cẩm nang, quản lý `MyGarden`, lịch chăm sóc & nhật ký cây trồng, trợ lý Floria AI, lịch sử quét, cửa hàng & thanh toán ZaloPay/COD) và **Quản trị viên trên Web Admin `/admin`** (quản lý `plants_info`, `DiseasesInfo`, sản phẩm, mã giảm giá `Vouchers`, đơn hàng, `PlantHandbook`, `HomeWeatherWidgets`, `Users`, thống kê hệ thống).
- **2.1.2. Yêu cầu phi chức năng:**
  - Hiệu năng suy luận AI thời gian thực, bảo mật xác thực Bearer Token Firebase, giao diện Responsive/Dark Mode/song ngữ Anh–Việt, tính sẵn sàng qua HTTPS (`api.floria.id.vn`).

### 2.2. Thiết kế kiến trúc tổng thể hệ thống (~1.5 trang)
- **Hình 2.x:** Sơ đồ kiến trúc Microservices 4 tầng:
  1. **Tầng Client:** Ứng dụng di động đa nền tảng (`floria_app` - Flutter) & Cổng Web User/Admin (`floria_web` - Next.js).
  2. **Tầng Định tuyến & Bảo mật:** Cloudflare Tunnel (`https://api.floria.id.vn` $\rightarrow$ `localhost:8080`).
  3. **Tầng Central Backend (`Backend` - Java Spring Boot, cổng `8080`):** Xác thực Firebase Bearer Token, lưu trữ ảnh cục bộ/đám mây, ghi log Firestore và gọi sang AI Engine.
  4. **Tầng AI Engine (`AI_Engine` - Python FastAPI, cổng `8000`) & Dịch vụ Đám mây:** ONNX Runtime + CLIP + Firebase Auth/Firestore + Gemini API + Open-Meteo API + ZaloPay Sandbox.

### 2.3. Mô hình hóa chức năng hệ thống (UML) (~5.5 trang)
*(Chọn lọc các luồng nghiệp vụ đặc trưng, tránh vẽ dàn trải những thao tác CRUD giống hệt nhau)*
- **2.3.1. Biểu đồ Ca sử dụng (Use Case):**
  - Use Case tổng quát toàn hệ thống (2 tác nhân: **Người dùng**, **Quản trị viên**).
  - Use Case phân rã cho phân hệ Người dùng và phân hệ Quản trị viên Web Admin.
- **2.3.2. Đặc tả chức năng và Biểu đồ tuần tự (Sequence Diagram) các luồng chính:**
  1. Đăng ký / Đăng nhập tài khoản (Firebase Auth).
  2. Quét ảnh nhận diện loài cây (App/Web $\rightarrow$ Spring Boot $\rightarrow$ AI Engine CLIP/ONNX $\rightarrow$ Bách khoa toàn thư Firestore / Gemini fallback $\rightarrow$ Lưu `MyGarden` & `ScanHistory`).
  3. Quét chẩn đoán bệnh lá & Cập nhật bệnh án cây.
  4. Tương tác Trợ lý Floria AI (nhận ngữ cảnh cây, đề xuất lịch chăm sóc tự động & gợi ý sản phẩm từ cửa hàng).
  5. Đặt hàng và thanh toán trực tuyến (Giỏ hàng $\rightarrow$ Voucher $\rightarrow$ ZaloPay Sandbox / COD $\rightarrow$ Lưu đơn hàng).
  6. Quản trị dữ liệu thực vật, bệnh học, sản phẩm & đơn hàng trên Web Admin.
- **2.3.3. Biểu đồ lớp (Class Diagram):** Mô hình hóa các thực thể cốt lõi (`User`, `GardenPlant`, `PlantWiki`, `DiseaseInfo`, `ScanHistoryItem`, `DiaryEntry`, `ShopProduct`, `Order`).

### 2.4. Thiết kế Cơ sở dữ liệu (Cloud Firestore) (~2.5–3 trang)
- Giải thích lý do chọn NoSQL Cloud Firestore (đồng bộ thời gian thực giữa `floria_app`, `floria_web` User/Admin và Spring Boot Admin SDK).
- **Bảng 2.x:** Mô tả cấu trúc trường dữ liệu các Collection chính:
  - `Users`, `plants_info`, `DiseasesInfo`
  - `MyGarden` (kèm subcollection/nhật ký chăm sóc), `ScanHistory`
  - `PlantHandbook`, `HomeWeatherWidgets`, `Vouchers`, `Orders` / `Products`.

---

## CHƯƠNG 3. TRIỂN KHAI VÀ ĐÁNH GIÁ HỆ THỐNG (~13–15 trang | ~3.700 từ)

> **Trọng tâm:** Trình bày theo đúng phong cách Chương 3 của `baocaoapp.md`, làm rõ sản phẩm thực tế đã chạy trên Backend, Mobile App và cấu trúc Web User/Admin.

### 3.1. Môi trường phát triển và công nghệ sử dụng (~1.5 trang)
- *Bảng 3.1:* Tổng hợp công cụ, ngôn ngữ và thư viện cho từng phân hệ:
  - **AI Engine:** Python, FastAPI, Uvicorn, PyTorch, ONNX Runtime, Transformers (CLIP), Pillow.
  - **Central Backend:** Java, Spring Boot (`RestTemplate`, `MultipartFile`), Firebase Admin SDK.
  - **Mobile App (`floria_app`):** Flutter, Dart, Provider, `google_fonts` (đóng gói offline), `package_info_plus`, HTTP/Multipart.
  - **Web Portal (`floria_web`):** Next.js (App Router), React, TypeScript, Tailwind CSS, Firebase Web SDK.
  - **Hạ tầng & Tích hợp:** Cloud Firestore, Firebase Auth, Gemini API, Open-Meteo API, ZaloPay Sandbox, Cloudflare Tunnel (`cloudflared` – `api.floria.id.vn`).

### 3.2. Triển khai tầng AI Engine và Central Backend (~2.5 trang)
- **3.2.1. Xây dựng dịch vụ AI Engine (`AI_Engine/main.py`):**
  - Cơ chế nạp ưu tiên mô hình ONNX quán quân và cache vector văn bản CLIP 1 lần khi khởi động.
  - Triển khai 2 endpoint `/predict` (40 loài + ngưỡng 50% phát hiện cây ngoài danh mục) và `/predict-disease` (5 nhóm bệnh kèm phác đồ `DISEASE_META`).
- **3.2.2. Xây dựng Central Backend (`DiseaseController.java`, `AuthController.java`):**
  - Endpoint `/api/scan-disease`, `/api/diagnose-disease`, `/api/upload-image`, `/api/images/{filename}`, `/api/ping`.
  - Xác thực Firebase Bearer Token và ghi nhận `ScanHistory` bất đồng bộ lên Firestore.
- **3.2.3. Triển khai kết nối Internet qua Cloudflare Tunnel (`start_all.bat`):**
  - Định tuyến `https://api.floria.id.vn` $\rightarrow$ `http://localhost:8080`, cho phép thiết bị di động 4G/5G và Web truy cập ổn định.

### 3.3. Triển khai ứng dụng di động Floria (`floria_app`) (~5 trang)
- **3.3.1. Tổ chức mã nguồn Feature-first và quản lý trạng thái (`Provider`):** Sơ đồ cây thư mục (`auth`, `splash`, `home`, `scan`, `garden`, `chatbot`, `history`, `shop`, `profile`).
- **3.3.2. Giao diện và chức năng các màn hình chính:** *(kèm ảnh chụp thực tế trên Android/Web)*
  1. Splash Screen (Preload dữ liệu & mascot Floria), Đăng nhập / Đăng ký.
  2. Trang chủ (`HomeScreen`): Thẻ thời tiết thực tế (Open-Meteo + `HomeWeatherWidgets`), tổng quan vườn, nhắc việc hôm nay, cẩm nang chăm cây (`PlantHandbook`).
  3. Quét ảnh nhận diện cây & Chẩn đoán bệnh (`ScanScreen`, `CameraScanningScreen`, `DiagnosisReportScreen`, `PlantWikiScreen`): Hiển thị Top 3 kết quả, xử lý ảnh không hợp lệ/không phải cây, phác đồ điều trị 4 bước.
  4. Khu vườn của tôi (`GardenScreen`, `PlantDetailScreen`, `PlantDiaryScreen`): Theo dõi chu kỳ tưới/bón phân/lau lá, ước lượng độ ẩm đất, nhật ký hệ thống & ghi chú cá nhân.
  5. Trợ lý Floria AI (`AiAssistantScreen`) & Lịch sử quét (`HistoryScreen`): Chat đa phiên, áp dụng lịch chăm sóc 1 chạm, gợi ý sản phẩm kê đơn.
  6. Cửa hàng vật tư, Giỏ hàng, Thanh toán (`ShopScreen`, `CartScreen`, `CheckoutScreen`, `ZaloPayPaymentScreen`, `OrderHistoryScreen`) & Hồ sơ (`ProfileScreen`, `SettingsScreen` hỗ trợ Dark Mode và song ngữ Anh–Việt).

### 3.4. Triển khai cổng Web Người dùng và Quản trị viên (`floria_web` - Next.js) (~2.5 trang)
- **3.4.1. Kiến trúc phân quyền và đồng bộ dữ liệu trên Next.js App Router:** Tách biệt không gian **User Web** và **Admin Dashboard (`/admin`)** dùng chung Backend `api.floria.id.vn` và Cloud Firestore.
- **3.4.2. Giao diện Web dành cho Người dùng (User Portal):** Tra cứu từ điển thực vật, tải ảnh lên để nhận diện/chẩn đoán bệnh trên trình duyệt, xem Khu vườn cá nhân, Lịch sử quét & theo dõi đơn hàng.
- **3.4.3. Giao diện Web dành cho Quản trị viên (`/admin`):** Dashboard thống kê tổng quan, quản lý danh mục cây (`plants_info`) & bệnh học (`DiseasesInfo`), quản lý sản phẩm, mã giảm giá (`Vouchers`), đơn hàng và bài viết cẩm nang (`PlantHandbook`).

### 3.5. Kiểm thử và đánh giá hệ thống (~1.5 trang)
- **3.5.1. Kiểm thử chất lượng mã nguồn & tích hợp đa tầng:**
  - Kết quả phân tích tĩnh `flutter analyze` (0 lỗi, 0 cảnh báo) và build APK chạy trên thiết bị Android thật qua `https://api.floria.id.vn`.
- **3.5.2. Bảng kịch bản kiểm thử các ca thực tế (Test Cases):**
  - *Bảng 3.x:* Kiểm thử các ca: Ảnh tối/mờ (`std < 15`), Ảnh chó/mèo/đồ vật (CLIP Gatekeeper chặn), Ảnh cây thuộc 40 loài, Ảnh cây ngoài 40 loài (Gemini nhận diện thay thế), Ảnh lá bệnh, Áp dụng Voucher & Thanh toán ZaloPay Sandbox, Thao tác đồng bộ từ Web Admin xuống App.

---

## KẾT LUẬN & TÀI LIỆU THAM KHẢO (~3 trang, chuẩn [mau.md](file:///D:/Plan/utrasupervip/baocao/mau.md))

### KẾT LUẬN
1. **Kết quả đạt được:**
   - Huấn luyện và xuất ONNX thành công 2 mô hình `tf_efficientnetv2_b0` đạt ~90.0% Accuracy (40 loài cây, ~438 FPS) và ~92.5% Accuracy (5 nhóm bệnh lá, ~106 FPS), kết hợp CLIP Gatekeeper lọc ảnh rác.
   - Xây dựng hoàn chỉnh kiến trúc Microservices (FastAPI + Spring Boot + Firebase + Cloudflare Tunnel) và ứng dụng di động Flutter (`floria_app`) tích hợp AI, lịch chăm sóc, thương mại điện tử và thanh toán ZaloPay Sandbox.
   - Thiết kế và triển khai đồng bộ cổng Web Next.js (`floria_web`) phục vụ cả Người dùng và Quản trị viên.
2. **Hạn chế:**
   - Bộ dữ liệu tự động nhận diện bằng ONNX mới giới hạn ở 40 loài cây cảnh phổ biến và 5 nhóm bệnh lá chính (các loài lạ cần phụ thuộc vào Gemini API).
   - Chưa chẩn đoán đồng thời nhiều bệnh xuất hiện cùng lúc trên một chiếc lá; thanh toán ZaloPay đang chạy ở môi trường Sandbox; server backend chạy cục bộ qua Tunnel.
3. **Hướng phát triển:**
   - Mở rộng tập dữ liệu lên 100+ loài cây và áp dụng Object Detection/Segmentation (như YOLO) để khoanh vùng chính xác vùng lá bệnh.
   - Tích hợp cảm biến IoT đo độ ẩm đất/ánh sáng đồng bộ tự động vào `MyGarden`.
   - Triển khai hệ thống lên Cloud Production (Docker, VPS/GCP) và tích hợp cổng thanh toán chính thức.

### TÀI LIỆU THAM KHẢO
*(Định dạng theo quy chuẩn cuối file [mau.md](file:///D:/Plan/utrasupervip/baocao/mau.md): `[#] Tác giả, Tên tài liệu/sách, NXB/Link, Năm`)*
- Tài liệu về EfficientNetV2 (Tan & Le, 2021), GhostNetV2, MobileNetV3, CLIP (Radford et al., 2021).
- Tài liệu bộ dữ liệu PlantDoc, Roboflow Indoor Plant Disease, Mango Leaf Disease.
- Tài liệu kỹ thuật chính thức của PyTorch, ONNX Runtime, FastAPI, Spring Boot, Flutter, Next.js và Firebase.

### NHẬN XÉT CỦA GIÁO VIÊN HƯỚNG DẪN
*(Trang mẫu nhận xét & kết luận đồng ý bảo vệ trước hội đồng của Trường ĐH Vinh)*

---

## CHECKLIST VIỆC CẦN CHUẨN BỊ KHI VIẾT TỪNG CHƯƠNG
- [ ] **Cho Chương 1:** Lấy từ Google Drive (`/content/drive/MyDrive/Dudoancaycanh/` và `Dudoancaycanh_Disease/`) các ảnh `All_Classes_Preview.png`, `Data_Distribution.png`, `Disease_Classes_Preview.png`, `GLOBAL_DISEASE_COMPARISON.png`, biểu đồ Loss/Accuracy, Confusion Matrix, ROC của 3 mô hình ở cả 2 bài toán (đặc biệt bổ sung số liệu tổng kết của `ghostnetv2_100` và `mobilenetv3_large_100` trong bài toán 40 loài cây).
- [ ] **Cho Chương 2:** Vẽ các sơ đồ bằng Draw.io / Mermaid / StarUML (Kiến trúc tổng thể, Use Case tổng quát & phân rã, 5–6 Sequence Diagram cốt lõi, Class Diagram).
- [ ] **Cho Chương 3:** Chụp ảnh màn hình thực tế các luồng chạy của `floria_app` trên Android/Web, giao diện Swagger/terminal `AI_Engine` & `Backend`, và giao diện `floria_web` (User + Admin `/admin`) sau khi hoàn thiện.
