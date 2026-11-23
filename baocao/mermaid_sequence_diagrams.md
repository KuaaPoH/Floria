# TỔNG HỢP MÃ NGUỒN MERMAID CÁC BIỂU ĐỒ TUẦN TỰ (HÌNH 2.5 - HÌNH 2.17)
*(Sao chép từng khối mã dưới đây để dán vào https://mermaid.live hoặc draw.io)*

---

### Hình 2.5. Biểu đồ tuần tự chức năng đăng ký
```mermaid
sequenceDiagram
    autonumber
    actor User as Khách hàng
    participant UI as Giao diện (App)
    participant Auth as Dịch vụ xác thực (Firebase Auth)
    participant DB as Cơ sở dữ liệu (Firestore)

    User->>UI: Nhập họ tên, email, mật khẩu và bấm "Đăng ký"
    activate UI
    UI->>UI: Kiểm tra định dạng email và độ dài mật khẩu
    alt Dữ liệu không hợp lệ
        UI-->>User: Báo lỗi và yêu cầu nhập lại
    else Dữ liệu hợp lệ
        UI->>Auth: Yêu cầu tạo tài khoản (Email, Password)
        activate Auth
        alt Email đã tồn tại
            Auth-->>UI: Báo lỗi email đã được sử dụng
            UI-->>User: Hiển thị thông báo tài khoản đã tồn tại
        else Tạo thành công
            Auth-->>UI: Trả về thông tin xác thực (UserCredential, UID)
            deactivate Auth
            UI->>DB: Khởi tạo bản ghi hồ sơ người dùng (Users/{UID})
            activate DB
            DB-->>UI: Xác nhận ghi thành công
            deactivate DB
            UI-->>User: Thông báo đăng ký thành công và tự động đăng nhập
        end
    end
    deactivate UI
```

---

### Hình 2.6. Biểu đồ tuần tự chức năng đăng nhập
```mermaid
sequenceDiagram
    autonumber
    actor User as Người dùng
    participant UI as Giao diện (App / Web)
    participant Auth as Dịch vụ xác thực
    participant DB as Cơ sở dữ liệu (Firestore)

    User->>UI: Nhập email, mật khẩu và bấm "Đăng nhập"
    activate UI
    UI->>Auth: Gửi yêu cầu xác thực thông tin đăng nhập
    activate Auth
    alt Sai thông tin đăng nhập
        Auth-->>UI: Báo lỗi sai tài khoản hoặc mật khẩu
        UI-->>User: Hiển thị thông báo đăng nhập thất bại
    else Xác thực thành công
        Auth-->>UI: Trả về Firebase ID Token & UID
        deactivate Auth
        UI->>DB: Truy vấn quyền và thông tin vai trò (Users/{UID})
        activate DB
        DB-->>UI: Trả về thông tin người dùng và vai trò (Role)
        deactivate DB
        alt Tài khoản bị khóa
            UI-->>User: Thông báo tài khoản bị vô hiệu hóa
        else Tài khoản hợp lệ
            UI-->>User: Đăng nhập thành công, chuyển hướng theo vai trò
        end
    end
    deactivate UI
```

---

### Hình 2.7. Biểu đồ tuần tự chức năng đăng xuất
```mermaid
sequenceDiagram
    autonumber
    actor User as Người dùng
    participant UI as Giao diện (App / Web)
    participant Storage as Bộ nhớ cục bộ (Local Storage)
    participant Auth as Dịch vụ xác thực

    User->>UI: Nhấn nút "Đăng xuất"
    activate UI
    UI-->>User: Hiển thị hộp thoại xác nhận đăng xuất
    User->>UI: Bấm "Xác nhận"
    UI->>Auth: Gọi lệnh đăng xuất (signOut)
    activate Auth
    Auth-->>UI: Xác nhận đã hủy phiên làm việc
    deactivate Auth
    UI->>Storage: Xóa ID Token và dữ liệu phiên đã lưu
    activate Storage
    Storage-->>UI: Đã làm sạch bộ nhớ tạm
    deactivate Storage
    UI-->>User: Chuyển hướng về màn hình đăng nhập
    deactivate UI
```

---

### Hình 2.8. Biểu đồ tuần tự chức năng nhận diện loài cây và chẩn đoán bệnh
```mermaid
sequenceDiagram
    autonumber
    actor User as Khách hàng
    participant App as Ứng dụng di động
    participant Backend as Máy chủ dịch vụ (Spring Boot)
    participant AI as Công cụ AI (FastAPI / ONNX)
    participant DB as Cơ sở dữ liệu (Firestore)

    User->>App: Chụp ảnh lá cây hoặc tải ảnh từ thư viện
    activate App
    App->>Backend: Gửi ảnh kèm thông tin người dùng qua API
    activate Backend
    Backend->>AI: Chuyển tiếp ảnh sang AI Engine
    activate AI
    AI->>AI: Tiền kiểm duyệt CLIP (loại bỏ ảnh không phải thực vật)
    alt Không phải ảnh thực vật
        AI-->>Backend: Báo lỗi ảnh không hợp lệ
        Backend-->>App: Yêu cầu chụp lại ảnh cây cảnh
        App-->>User: Hiển thị thông báo lỗi ảnh
    else Ảnh thực vật hợp lệ
        AI->>AI: Suy luận mô hình chuyên biệt (EfficientNetV2)
        AI-->>Backend: Trả về tên loài, bệnh lý, độ tin cậy
        deactivate AI
        Backend->>DB: Tra cứu thông tin chi tiết (plants_info, DiseasesInfo)
        activate DB
        DB-->>Backend: Trả về mô tả sinh học, cách chăm sóc, phác đồ điều trị
        Backend->>DB: Lưu nhật ký quét vào collection ScanHistory
        deactivate DB
        Backend-->>App: Trả về kết quả hoàn chỉnh
        deactivate Backend
        App-->>User: Hiển thị kết quả nhận diện, chẩn đoán và hướng dẫn
    end
    deactivate App
```

---

### Hình 2.9. Biểu đồ tuần tự chức năng quản lý khu vườn cá nhân
```mermaid
sequenceDiagram
    autonumber
    actor User as Khách hàng
    participant UI as Giao diện "Vườn của tôi"
    participant Weather as Dịch vụ thời tiết (Open-Meteo)
    participant DB as Cơ sở dữ liệu (Firestore)

    User->>UI: Mở màn hình khu vườn cá nhân
    activate UI
    UI->>DB: Tải danh sách cây đang trồng (MyGarden)
    activate DB
    DB-->>UI: Trả về danh sách cây và trạng thái chăm sóc
    deactivate DB
    UI->>Weather: Lấy dữ liệu thời tiết hiện tại (Nhiệt độ, Mưa, Độ ẩm)
    activate Weather
    Weather-->>UI: Trả về thông số thời tiết thời gian thực
    deactivate Weather
    UI->>UI: Tính toán điều chỉnh chu kỳ tưới thích ứng thời tiết
    UI-->>User: Hiển thị danh sách cây, cảnh báo thời tiết và lịch tưới hôm nay
    
    opt Khách hàng xác nhận chăm sóc cây
        User->>UI: Nhấn "Đã tưới nước" cho một cây
        UI->>DB: Cập nhật thời điểm tưới gần nhất và chu kỳ mới
        activate DB
        DB-->>UI: Xác nhận cập nhật thành công
        deactivate DB
        UI-->>User: Cập nhật giao diện trạng thái cây đã được tưới
    end
    deactivate UI
```

---

### Hình 2.10. Biểu đồ tuần tự chức năng tương tác trợ lý ảo AI
```mermaid
sequenceDiagram
    autonumber
    actor User as Khách hàng
    participant UI as Giao diện Chatbot
    participant Backend as Máy chủ dịch vụ
    participant LLM as Dịch vụ Trí tuệ nhân tạo (LLM)
    participant DB as Cơ sở dữ liệu (Firestore)

    User->>UI: Gửi câu hỏi tư vấn (kèm ảnh hoặc ngữ cảnh cây)
    activate UI
    UI->>Backend: Chuyển tiếp câu hỏi và lịch sử phiên trò chuyện
    activate Backend
    Backend->>DB: Truy cứu cơ sở tri thức cây và bệnh liên quan
    activate DB
    DB-->>Backend: Trả về dữ liệu bách khoa hỗ trợ
    deactivate DB
    Backend->>LLM: Gửi Prompt chuyên gia kèm tri thức ngữ cảnh
    activate LLM
    LLM-->>Backend: Trả về câu trả lời tư vấn chăm sóc chi tiết
    deactivate LLM
    Backend->>DB: Lưu tin nhắn mới vào ChatSessions
    activate DB
    DB-->>Backend: Đã ghi nhận phiên chat
    deactivate DB
    Backend-->>UI: Gửi câu trả lời hiển thị cho người dùng
    deactivate Backend
    UI-->>User: Hiển thị phản hồi tư vấn và sản phẩm khuyến nghị
    deactivate UI
```

---

### Hình 2.11. Biểu đồ tuần tự chức năng đặt hàng và thanh toán
```mermaid
sequenceDiagram
    autonumber
    actor User as Khách hàng
    participant App as Ứng dụng di động
    participant Backend as Máy chủ xử lý đơn hàng
    participant Payment as Cổng thanh toán (Ví điện tử)
    participant DB as Cơ sở dữ liệu (Firestore)

    User->>App: Chọn địa chỉ, áp mã giảm giá và bấm "Đặt hàng"
    activate App
    App->>Backend: Gửi thông tin đơn hàng và phương thức thanh toán
    activate Backend
    Backend->>DB: Kiểm tra tồn kho sản phẩm (ShopProducts)
    activate DB
    alt Hết hàng tồn kho
        DB-->>Backend: Số lượng không đủ đáp ứng
        Backend-->>App: Báo lỗi hết hàng
        App-->>User: Thông báo sản phẩm đã hết, vui lòng chọn lại
    else Còn hàng trong kho
        DB-->>Backend: Tồn kho hợp lệ
        deactivate DB
        alt Phương thức COD (Thanh toán khi nhận hàng)
            Backend->>DB: Tạo đơn hàng mới (Orders) và trừ tồn kho
            activate DB
            DB-->>Backend: Lưu đơn hàng thành công
            deactivate DB
            Backend-->>App: Xác nhận tạo đơn hàng thành công
            App-->>User: Hiển thị màn hình đặt hàng thành công
        else Phương thức Ví điện tử
            Backend->>Payment: Khởi tạo giao dịch thanh toán
            activate Payment
            Payment-->>Backend: Trả về URL thanh toán / Mã QR
            deactivate Payment
            Backend-->>App: Chuyển hướng người dùng sang cổng thanh toán
            App->>Payment: Khách hàng xác nhận thanh toán
            activate Payment
            Payment-->>Backend: Gửi thông báo kết quả giao dịch (Webhook/IPN)
            deactivate Payment
            Backend->>DB: Cập nhật trạng thái "Đã thanh toán" và tạo đơn
            activate DB
            DB-->>Backend: Đã cập nhật
            deactivate DB
            Backend-->>App: Gửi thông báo thanh toán thành công
            App-->>User: Hiển thị hóa đơn điện tử thành công
        end
    end
    deactivate Backend
    deactivate App
```

---

### Hình 2.12. Biểu đồ tuần tự chức năng quản lý đơn hàng
```mermaid
sequenceDiagram
    autonumber
    actor Staff as Nhân viên vận hành
    participant Web as Cổng Web Admin
    participant Backend as Máy chủ dịch vụ
    participant DB as Cơ sở dữ liệu (Firestore)
    participant Push as Dịch vụ thông báo đẩy

    Staff->>Web: Truy cập màn hình "Quản lý đơn hàng"
    activate Web
    Web->>Backend: Yêu cầu danh sách đơn đặt hàng
    activate Backend
    Backend->>DB: Truy vấn danh sách Orders theo trạng thái
    activate DB
    DB-->>Backend: Trả về danh sách đơn hàng
    deactivate DB
    Backend-->>Web: Hiển thị danh sách lên bảng dữ liệu
    deactivate Backend

    Staff->>Web: Chọn đơn hàng, xác nhận duyệt và gán mã vận đơn
    Web->>Backend: Gửi cập nhật trạng thái đơn (Đang giao hàng)
    activate Backend
    Backend->>DB: Cập nhật thông tin giao vận vào Orders/{id}
    activate DB
    DB-->>Backend: Xác nhận ghi thành công
    deactivate DB
    Backend->>Push: Gửi thông báo cập nhật đơn hàng đến người dùng
    activate Push
    Push-->>Backend: Đã gửi thông báo
    deactivate Push
    Backend-->>Web: Báo cập nhật thành công
    deactivate Backend
    Web-->>Staff: Cập nhật trạng thái mới trên giao diện
    deactivate Web
```

---

### Hình 2.13. Biểu đồ tuần tự chức năng quản lý sản phẩm và kho hàng
```mermaid
sequenceDiagram
    autonumber
    actor Staff as Nhân viên vận hành
    participant Web as Cổng Web Admin
    participant Backend as Máy chủ dịch vụ
    participant DB as Cơ sở dữ liệu (Firestore)

    Staff->>Web: Nhập thông tin sản phẩm mới hoặc cập nhật tồn kho
    activate Web
    Web->>Web: Kiểm tra hợp lệ dữ liệu (tên, giá > 0, tồn kho >= 0)
    Web->>Backend: Gửi yêu cầu lưu thông tin sản phẩm (ShopProducts)
    activate Backend
    Backend->>DB: Thực hiện ghi/cập nhật dữ liệu vào Firestore
    activate DB
    DB-->>Backend: Trả về kết quả ghi thành công
    deactivate DB
    Backend->>DB: Ghi nhận lịch sử xuất nhập kho (InventoryTransactions)
    activate DB
    DB-->>Backend: Đã lưu giao dịch kho
    deactivate DB
    Backend-->>Web: Trả về thông báo thành công
    deactivate Backend
    Web-->>Staff: Hiển thị thông báo cập nhật kho thành công
    deactivate Web
```

---

### Hình 2.14. Biểu đồ tuần tự chức năng quản lý từ điển thực vật và bệnh học
```mermaid
sequenceDiagram
    autonumber
    actor Botanist as Chuyên gia thực vật
    participant Web as Cổng Web Admin
    participant Backend as Máy chủ dịch vụ
    participant DB as Cơ sở dữ liệu (Firestore)

    Botanist->>Web: Chọn loài cây hoặc nhóm bệnh cần cập nhật
    activate Web
    Web->>DB: Tải thông tin hiện tại (plants_info / DiseasesInfo)
    activate DB
    DB-->>Web: Trả về hồ sơ chi tiết
    deactivate DB
    Botanist->>Web: Chỉnh sửa mô tả sinh học, triệu chứng, phác đồ điều trị
    Botanist->>Web: Nhấn nút "Xuất bản cập nhật"
    Web->>Backend: Gửi dữ liệu đã hiệu đính
    activate Backend
    Backend->>DB: Cập nhật hồ sơ vào Firestore
    activate DB
    DB-->>Backend: Xác nhận lưu dữ liệu thành công
    deactivate DB
    Backend-->>Web: Báo cập nhật cơ sở tri thức thành công
    deactivate Backend
    Web-->>Botanist: Thông báo xuất bản thành công
    deactivate Web
```

---

### Hình 2.15. Biểu đồ tuần tự chức năng duyệt nhãn dữ liệu AI Lab
```mermaid
sequenceDiagram
    autonumber
    actor Botanist as Chuyên gia thực vật
    participant Web as Cổng Web Admin (AI Lab)
    participant Backend as Máy chủ dịch vụ
    participant DB as Cơ sở dữ liệu (Firestore)
    participant Storage as Lưu trữ dữ liệu huấn luyện

    Botanist->>Web: Mở mô-đun duyệt dữ liệu AI Lab
    activate Web
    Web->>Backend: Lấy danh sách ảnh quét có phản hồi hoặc độ tin cậy thấp
    activate Backend
    Backend->>DB: Truy vấn các mẫu cần kiểm duyệt từ ScanHistory
    activate DB
    DB-->>Backend: Trả về danh sách hình ảnh và nhãn AI dự đoán
    deactivate DB
    Backend-->>Web: Hiển thị lưới hình ảnh cần duyệt
    deactivate Backend

    Botanist->>Web: Xem xét hình ảnh, chọn "Duyệt đúng" hoặc gán lại nhãn chuẩn
    Web->>Backend: Gửi quyết định phê duyệt nhãn
    activate Backend
    Backend->>Storage: Lưu trữ ảnh và nhãn chuẩn hóa vào tập dữ liệu tái huấn luyện
    activate Storage
    Storage-->>Backend: Đã ghi nhận mẫu dữ liệu chuẩn
    deactivate Storage
    Backend->>DB: Cập nhật trạng thái "Đã kiểm duyệt" trong ScanHistory
    activate DB
    DB-->>Backend: Cập nhật thành công
    deactivate DB
    Backend-->>Web: Thông báo duyệt mẫu thành công
    deactivate Backend
    Web-->>Botanist: Loại bỏ ảnh vừa duyệt khỏi danh sách chờ
    deactivate Web
```

---

### Hình 2.16. Biểu đồ tuần tự chức năng quản lý người dùng và phân quyền
```mermaid
sequenceDiagram
    autonumber
    actor Admin as Quản trị viên hệ thống
    participant Web as Cổng Web Admin
    participant Backend as Máy chủ dịch vụ
    participant DB as Cơ sở dữ liệu (Firestore)
    participant Auth as Dịch vụ xác thực

    Admin->>Web: Mở trang "Quản lý người dùng & Phân quyền"
    activate Web
    Web->>Backend: Yêu cầu danh sách tài khoản
    activate Backend
    Backend->>DB: Truy vấn collection Users
    activate DB
    DB-->>Backend: Trả về danh sách người dùng kèm vai trò
    deactivate DB
    Backend-->>Web: Hiển thị bảng người dùng
    deactivate Backend

    Admin->>Web: Chọn người dùng và thay đổi vai trò (VD: Gán quyền Botanist)
    Web->>Backend: Gửi yêu cầu cập nhật quyền hạn người dùng
    activate Backend
    Backend->>Auth: Cập nhật thuộc tính Custom Claims (role: botanist)
    activate Auth
    Auth-->>Backend: Xác nhận cấp quyền thành công
    deactivate Auth
    Backend->>DB: Cập nhật vai trò mới vào tài liệu Users/{uid}
    activate DB
    DB-->>Backend: Đã lưu quyền mới
    deactivate DB
    Backend-->>Web: Báo phân quyền thành công
    deactivate Backend
    Web-->>Admin: Hiển thị thông báo và cập nhật bảng phân quyền
    deactivate Web
```

---

### Hình 2.17. Biểu đồ tuần tự chức năng báo cáo thống kê và giám sát
```mermaid
sequenceDiagram
    autonumber
    actor Admin as Quản trị viên hệ thống
    participant Web as Cổng Web Admin
    participant Backend as Máy chủ dịch vụ
    participant DB as Cơ sở dữ liệu (Firestore)

    Admin->>Web: Truy cập "Tổng quan & Thống kê"
    activate Web
    Web->>Backend: Yêu cầu tổng hợp dữ liệu báo cáo (Khoảng thời gian: Tuần/Tháng)
    activate Backend
    Backend->>DB: Truy vấn dữ liệu từ ScanHistory, Orders, Users
    activate DB
    DB-->>Backend: Trả về dữ liệu thống kê thô
    deactivate DB
    Backend->>Backend: Tổng hợp số lượt quét, doanh thu, tăng trưởng người dùng
    Backend-->>Web: Trả về số liệu đã tổng hợp và dữ liệu đồ thị
    deactivate Backend
    Web-->>Admin: Hiển thị các biểu đồ trực quan (Doanh thu, Lượt quét, Độ chính xác AI)

    opt Xuất báo cáo thống kê
        Admin->>Web: Bấm "Xuất báo cáo Excel / PDF"
        Web->>Backend: Yêu cầu kết xuất tệp báo cáo
        activate Backend
        Backend->>Backend: Sinh tệp báo cáo thống kê
        Backend-->>Web: Trả về liên kết tải tệp
        deactivate Backend
        Web-->>Admin: Tự động tải tệp báo cáo về máy tính
    end
    deactivate Web
```
