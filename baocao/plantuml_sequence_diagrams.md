# TỔNG HỢP MÃ NGUỒN PLANTUML CÁC BIỂU ĐỒ TUẦN TỰ (CHUẨN ĐỒ ÁN ĐH VINH)
*(Định dạng đen trắng, nét mảnh, có activation bar, self-call vuông vắn y đúc mẫu baocaoapp.md)*
*(Cách dùng: Vào draw.io -> Arrange -> Insert -> Advanced -> PlantUML -> Dán mã vào)*

---

### Hình 2.5. Biểu đồ tuần tự chức năng đăng ký
```plantuml
@startuml
skinparam monochrome true
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam sequenceMessageAlign center
skinparam roundcorner 0
skinparam sequenceBoxBorderColor black
skinparam participantBorderColor black
skinparam actorBorderColor black
skinparam sequenceLifeLineBorderColor black
skinparam sequenceArrowColor black

actor "Khách hàng" as User
participant ":Giao diện" as UI
participant ":Hệ thống" as System
participant ":Cơ sở dữ liệu" as DB

User -> UI: 1. Yêu cầu đăng ký
activate UI
UI -> UI: 2. Hiển thị giao diện
deactivate UI

User -> UI: 3. Nhập thông tin
activate UI
UI -> System: 4. Gửi thông tin
activate System
System -> System: 5. Kiểm tra thông tin
System -> DB: 6. Cập nhật vào CSDL
activate DB
DB --> System: (Tài khoản)
deactivate DB

System --> UI: Đăng nhập thành công
deactivate System
UI --> User: Đăng nhập thành công
deactivate UI

@enduml
```

---

### Hình 2.6. Biểu đồ tuần tự chức năng đăng nhập
```plantuml
@startuml
skinparam monochrome true
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam sequenceMessageAlign center
skinparam roundcorner 0

actor "Người dùng" as User
participant ":Giao diện" as UI
participant ":Hệ thống" as System
participant ":Cơ sở dữ liệu" as DB

User -> UI: 1. Chọn đăng nhập
activate UI
UI -> UI: 2. Hiển thị giao diện
deactivate UI

User -> UI: 3. Nhập tài khoản và mật khẩu
activate UI
UI -> System: 4. Gửi thông tin xác thực
activate System
System -> DB: 5. Kiểm tra tài khoản và quyền
activate DB
DB --> System: (Hợp lệ)
deactivate DB

System --> UI: Đăng nhập thành công
deactivate System
UI --> User: Chuyển vào màn hình chính
deactivate UI

@enduml
```

---

### Hình 2.7. Biểu đồ tuần tự chức năng đăng xuất
```plantuml
@startuml
skinparam monochrome true
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam sequenceMessageAlign center
skinparam roundcorner 0

actor "Người dùng" as User
participant ":Giao diện" as UI
participant ":Hệ thống" as System

User -> UI: 1. Chọn đăng xuất
activate UI
UI -> UI: 2. Hiển thị xác nhận
User -> UI: 3. Xác nhận đăng xuất
UI -> System: 4. Yêu cầu hủy phiên
activate System
System -> System: 5. Xóa phiên làm việc
System --> UI: Hủy phiên thành công
deactivate System
UI --> User: Về màn hình đăng nhập
deactivate UI

@enduml
```

---

### Hình 2.8. Biểu đồ tuần tự chức năng nhận diện loài cây và chẩn đoán bệnh
```plantuml
@startuml
skinparam monochrome true
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam sequenceMessageAlign center
skinparam roundcorner 0

actor "Khách hàng" as User
participant ":Giao diện" as UI
participant ":Hệ thống" as System
participant ":Mô hình AI" as AI
participant ":Cơ sở dữ liệu" as DB

User -> UI: 1. Chụp hoặc tải ảnh lá cây
activate UI
UI -> System: 2. Gửi ảnh phân tích
activate System
System -> AI: 3. Yêu cầu trích xuất đặc trưng
activate AI
AI --> System: 4. Kết quả loài cây và bệnh
deactivate AI

System -> DB: 5. Tra cứu phác đồ và lưu lịch sử
activate DB
DB --> System: (Thông tin chi tiết)
deactivate DB

System --> UI: 6. Trả về kết quả chẩn đoán
deactivate System
UI --> User: Hiển thị kết quả và cách điều trị
deactivate UI

@enduml
```

---

### Hình 2.9. Biểu đồ tuần tự chức năng quản lý khu vườn cá nhân
```plantuml
@startuml
skinparam monochrome true
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam sequenceMessageAlign center
skinparam roundcorner 0

actor "Khách hàng" as User
participant ":Giao diện" as UI
participant ":Hệ thống" as System
participant ":Dịch vụ thời tiết" as Weather
participant ":Cơ sở dữ liệu" as DB

User -> UI: 1. Mở mục Vườn của tôi
activate UI
UI -> DB: 2. Lấy danh sách cây trồng
activate DB
DB --> UI: (Danh sách cây)
deactivate DB

UI -> Weather: 3. Lấy dữ liệu thời tiết
activate Weather
Weather --> UI: (Nhiệt độ, lượng mưa)
deactivate Weather

UI --> User: 4. Hiển thị lịch tưới hôm nay
User -> UI: 5. Bấm Đã tưới nước
UI -> System: 6. Cập nhật nhật ký chăm sóc
activate System
System -> DB: 7. Lưu thời điểm tưới mới
activate DB
DB --> System: (Thành công)
deactivate DB
System --> UI: Cập nhật thành công
deactivate System
UI --> User: Cập nhật trạng thái cây
deactivate UI

@enduml
```

---

### Hình 2.10. Biểu đồ tuần tự chức năng tương tác trợ lý ảo AI
```plantuml
@startuml
skinparam monochrome true
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam sequenceMessageAlign center
skinparam roundcorner 0

actor "Khách hàng" as User
participant ":Giao diện" as UI
participant ":Hệ thống" as System
participant ":Trợ lý AI" as LLM
participant ":Cơ sở dữ liệu" as DB

User -> UI: 1. Nhập câu hỏi chăm sóc cây
activate UI
UI -> System: 2. Gửi nội dung câu hỏi
activate System
System -> DB: 3. Tra cứu bách khoa thực vật
activate DB
DB --> System: (Ngữ cảnh hỗ trợ)
deactivate DB

System -> LLM: 4. Yêu cầu sinh phản hồi
activate LLM
LLM --> System: (Câu trả lời tư vấn)
deactivate LLM

System -> DB: 5. Lưu phiên trò chuyện
activate DB
DB --> System: (Đã lưu)
deactivate DB

System --> UI: 6. Gửi câu trả lời
deactivate System
UI --> User: Hiển thị phản hồi tư vấn
deactivate UI

@enduml
```

---

### Hình 2.11. Biểu đồ tuần tự chức năng đặt hàng và thanh toán
```plantuml
@startuml
skinparam monochrome true
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam sequenceMessageAlign center
skinparam roundcorner 0

actor "Khách hàng" as User
participant ":Giao diện" as UI
participant ":Hệ thống" as System
participant ":Cổng thanh toán" as Payment
participant ":Cơ sở dữ liệu" as DB

User -> UI: 1. Chọn sản phẩm và đặt hàng
activate UI
UI -> System: 2. Gửi thông tin đơn hàng
activate System
System -> DB: 3. Kiểm tra tồn kho
activate DB
DB --> System: (Đủ hàng)
deactivate DB

System -> Payment: 4. Khởi tạo thanh toán
activate Payment
Payment --> UI: 5. Màn hình thanh toán
deactivate Payment

User -> Payment: 6. Xác nhận thanh toán
activate Payment
Payment --> System: 7. Báo thanh toán thành công
deactivate Payment

System -> DB: 8. Lưu đơn hàng và trừ kho
activate DB
DB --> System: (Thành công)
deactivate DB

System --> UI: Đặt hàng thành công
deactivate System
UI --> User: Hiển thị hóa đơn
deactivate UI

@enduml
```

---

### Hình 2.12. Biểu đồ tuần tự chức năng quản lý đơn hàng
```plantuml
@startuml
skinparam monochrome true
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam sequenceMessageAlign center
skinparam roundcorner 0

actor "Nhân viên" as Staff
participant ":Giao diện" as UI
participant ":Hệ thống" as System
participant ":Cơ sở dữ liệu" as DB

Staff -> UI: 1. Chọn Quản lý đơn hàng
activate UI
UI -> System: 2. Yêu cầu danh sách đơn hàng
activate System
System -> DB: 3. Truy vấn đơn hàng
activate DB
DB --> System: (Danh sách đơn)
deactivate DB
System --> UI: Hiển thị bảng đơn hàng
deactivate System

Staff -> UI: 4. Duyệt đơn và giao hàng
UI -> System: 5. Gửi trạng thái mới
activate System
System -> DB: 6. Cập nhật đơn hàng
activate DB
DB --> System: (Thành công)
deactivate DB
System --> UI: Báo cập nhật hoàn tất
deactivate System
UI --> Staff: Cập nhật trạng thái mới
deactivate UI

@enduml
```

---

### Hình 2.13. Biểu đồ tuần tự chức năng quản lý sản phẩm và kho hàng
```plantuml
@startuml
skinparam monochrome true
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam sequenceMessageAlign center
skinparam roundcorner 0

actor "Nhân viên" as Staff
participant ":Giao diện" as UI
participant ":Hệ thống" as System
participant ":Cơ sở dữ liệu" as DB

Staff -> UI: 1. Nhập thông tin sản phẩm và kho
activate UI
UI -> System: 2. Gửi yêu cầu lưu
activate System
System -> DB: 3. Cập nhật sản phẩm và kho
activate DB
DB --> System: (Thành công)
deactivate DB
System --> UI: Lưu thành công
deactivate System
UI --> Staff: Cập nhật danh sách sản phẩm
deactivate UI

@enduml
```

---

### Hình 2.14. Biểu đồ tuần tự chức năng quản lý từ điển thực vật và bệnh học
```plantuml
@startuml
skinparam monochrome true
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam sequenceMessageAlign center
skinparam roundcorner 0

actor "Chuyên gia" as Botanist
participant ":Giao diện" as UI
participant ":Hệ thống" as System
participant ":Cơ sở dữ liệu" as DB

Botanist -> UI: 1. Chọn hồ sơ cây hoặc bệnh
activate UI
UI -> DB: 2. Lấy dữ liệu chi tiết
activate DB
DB --> UI: (Hiển thị biểu mẫu)
deactivate DB

Botanist -> UI: 3. Chỉnh sửa mô tả và phác đồ
UI -> System: 4. Gửi nội dung hiệu đính
activate System
System -> DB: 5. Lưu vào cơ sở tri thức
activate DB
DB --> System: (Thành công)
deactivate DB
System --> UI: Xuất bản thành công
deactivate System
UI --> Botanist: Thông báo hoàn tất
deactivate UI

@enduml
```

---

### Hình 2.15. Biểu đồ tuần tự chức năng duyệt nhãn dữ liệu AI Lab
```plantuml
@startuml
skinparam monochrome true
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam sequenceMessageAlign center
skinparam roundcorner 0

actor "Chuyên gia" as Botanist
participant ":Giao diện" as UI
participant ":Hệ thống" as System
participant ":Cơ sở dữ liệu" as DB

Botanist -> UI: 1. Mở danh sách ảnh chờ duyệt
activate UI
UI -> System: 2. Yêu cầu mẫu dữ liệu
activate System
System -> DB: 3. Lấy ảnh độ tin cậy thấp
activate DB
DB --> System: (Danh sách ảnh)
deactivate DB
System --> UI: Hiển thị lưới hình ảnh
deactivate System

Botanist -> UI: 4. Chọn duyệt hoặc gán lại nhãn
UI -> System: 5. Gửi nhãn chuẩn hóa
activate System
System -> DB: 6. Lưu vào kho tái huấn luyện
activate DB
DB --> System: (Đã lưu)
deactivate DB
System --> UI: Duyệt mẫu thành công
deactivate System
UI --> Botanist: Loại bỏ ảnh khỏi danh sách chờ
deactivate UI

@enduml
```

---

### Hình 2.16. Biểu đồ tuần tự chức năng quản lý người dùng và phân quyền
```plantuml
@startuml
skinparam monochrome true
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam sequenceMessageAlign center
skinparam roundcorner 0

actor "Quản trị viên" as Admin
participant ":Giao diện" as UI
participant ":Hệ thống" as System
participant ":Cơ sở dữ liệu" as DB

Admin -> UI: 1. Mở mục Quản lý người dùng
activate UI
UI -> System: 2. Yêu cầu danh sách tài khoản
activate System
System -> DB: 3. Lấy danh sách người dùng
activate DB
DB --> System: (Danh sách tài khoản)
deactivate DB
System --> UI: Hiển thị bảng phân quyền
deactivate System

Admin -> UI: 4. Chọn tài khoản và đổi quyền
UI -> System: 5. Gửi phân quyền mới
activate System
System -> DB: 6. Cập nhật quyền vào CSDL
activate DB
DB --> System: (Thành công)
deactivate DB
System --> UI: Báo cập nhật hoàn tất
deactivate System
UI --> Admin: Cập nhật giao diện phân quyền
deactivate UI

@enduml
```

---
