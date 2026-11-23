**TRƯỜNG ĐẠI HỌC VINH VIỆN KỸ THUẬT VÀ CÔNG NGHỆ**

**![](data:image/png;base64...)**

**BÁO CÁO CUỐI KỲ HỌC PHẦN HỌC MÁY**

PHÂN LOẠI CẢNH QUAN TỰ NHIÊN SỬ DỤNG MẠNG HỌC SÂU HIỆN ĐẠI

**GVHD**: PGS. TS. Hoàng Hữu Việt

**SV thực hiện**: 1. Trần Ngọc Hải, 225748020110069

2. Phan Thị Giang, 225748020110277

3. Hà Văn Hiệp, 225748020110228

**Nghệ An, 06/2026**

# LỜI NÓI ĐẦU

Trong bối cảnh công nghệ thị giác máy tính đang phát triển vô cùng mạnh mẽ, việc tự động nhận diện và phân loại hình ảnh đóng vai trò nòng cốt trong việc xây dựng vô số các ứng dụng thực tiễn như hệ thống xe tự hành, công cụ tìm kiếm hình ảnh thông minh và nền tảng du lịch trực tuyến. Nhận thức được tầm quan trọng đó, đồng thời với mong muốn áp dụng những kiến thức chuyên môn đã được trang bị trong học phần Học máy vào một bài toán thực tiễn, chúng em quyết định lựa chọn thực hiện đề tài “Phân loại cảnh quan tự nhiên (Intel Image Classification) sử dụng các kiến trúc Học sâu hiện đại”.

Bài tiểu luận cuối kỳ này sẽ tập trung vào việc phân tích, xây dựng và so sánh hiệu năng của kiến trúc mạng Nơ–ron Tích chập (CNN) tiêu biểu hiện nay, bao gồm: VGG16, ResNet50, DenseNet121 và MobileNetV2. Thông qua quá trình thực nghiệm trên bộ dữ liệu Intel Image Classification với 6 danh mục cảnh quan tự nhiên đa dạng (buildings, forest, glacier, mountain, sea, street), nghiên cứu hướng tới mục tiêu đánh giá toàn diện khả năng trích xuất đặc trưng thị giác cũng như giải quyết thách thức về sự tương đồng hình học giữa các lớp thực tế. Đồng thời, báo cáo cũng sẽ đi sâu phân tích sự đánh đổi (trade-off) giữa độ chính xác phân lớp và chi phí tính toán của từng kiến trúc mạng.

Dù đã nỗ lực hết mình để mang lại một góc nhìn toàn diện và đánh giá mô hình đa chiều, song do những giới hạn nhất định về mặt kinh nghiệm thực tiễn cũng như sự phức tạp trong việc tinh chỉnh các mô hình học sâu cỡ lớn, bài báo cáo chắc chắn khó tránh khỏi những thiếu sót. Chúng em rất mong sẽ nhận được những ý kiến phản biện và đóng góp quý báu từ Thầy để tiếp tục hoàn thiện, làm tiền đề để mở rộng hướng tiếp cận sang các cấu trúc học máy mạnh mẽ hơn trong tương lai.

Xin chân thành cảm ơn!

# BẢNG PHÂN CÔNG NHIỆM VỤ

|  |  |  |  |  |
| --- | --- | --- | --- | --- |
| **STT** | **Họ và tên** | **Nhiệm vụ** | **Đóng góp** | **Ghi chú** |
| 1 | Trần Ngọc Hải | Chương 1: 1.1. Mô tả bài toán. Chương 2: 2.2. Cài đặt mô hình bằng Python.  Chương 3: 3.1. Tóm tắt kết quả đạt được.  Xây dựng chương trình code và trích xuất kết quả đánh giá. | 40 % | Nhóm trưởng |
| 2 | Phan Thị Giang | Chương 1: 1.2. Giới thiệu bộ dữ liệu.  1.3. Mô tả dữ liệu.  1.4. Trực quan dữ liệu.  Chương 2: 2.1. Mô tả kiến trúc của các mô hình học sâu.  2.4. So sánh và giải thích kết quả.  Chương 3: 3.2. Hạn chế của đề tài.  Tổng hợp báo cáo và phân tích biểu đồ. | 40 % |  |
| 3 | Hà Văn Hiệp | Chương 2: 2.3. Đánh giá mô hình từng mô hình học sâu.  Chương 3: 3.3. Định hướng mở rộng.  Trích xuất kết quả thực nghiệm. | 20 % |  |

**MỤC LỤC**

[LỜI NÓI ĐẦU 1](#_Toc231048554)

[BẢNG PHÂN CÔNG NHIỆM VỤ 2](#_Toc231048555)

[DANH SÁCH CÁC HÌNH 5](#_Toc231048556)

[DANH MỤC CÁC BẢNG 6](#_Toc231048557)

[CHƯƠNG 1. GIỚI THIỆU BÀI TOÁN 7](#_Toc231048558)

[1.1. Mô tả bài toán 7](#_Toc231048559)

[1.2. Giới thiệu bộ dữ liệu 7](#_Toc231048560)

[1.3. Mô tả dữ liệu 8](#_Toc231048561)

[1.3.1. Mô tả các thuộc tính dữ liệu 8](#_Toc231048562)

[1.3.2. Số lượng mẫu cho train/test/validation 9](#_Toc231048563)

[1.4. Trực quan dữ liệu 10](#_Toc231048564)

[1.4.1. Hiển thị mẫu ảnh 10](#_Toc231048565)

[1.4.2. Biểu đồ phân bố nhãn lớp 11](#_Toc231048566)

[CHƯƠNG 2. XÂY DỰNG VÀ HUẤN LUYỆN MÔ HÌNH 13](#_Toc231048567)

[2.1. Mô tả kiến trúc của các mô hình học sâu 13](#_Toc231048568)

[2.1.1. Giới thiệu các mô hình đã chọn và cơ sở toán học chung 13](#_Toc231048569)

[2.1.2. Kiến trúc VGG16 15](#_Toc231048570)

[2.1.3. Kiến trúc ResNet50 16](#_Toc231048571)

[2.1.4. Kiến trúc DenseNet121 (Densely Connected Convolutional Network) 18](#_Toc231048572)

[2.1.5. Kiến trúc MobileNetV2 19](#_Toc231048573)

[2.2. Cài đặt mô hình bằng Python 20](#_Toc231048574)

[2.2.1. Môi trường thực nghiệm và Công cụ hỗ trợ 20](#_Toc231048575)

[2.2.2. Khai báo thư viện và Thiết lập dữ liệu đầu vào 21](#_Toc231048576)

[2.2.3. Khởi tạo đường ống nạp dữ liệu 23](#_Toc231048577)

[2.2.4. Tích hợp kỹ thuật tăng cường dữ liệu trên GPU 24](#_Toc231048578)

[2.2.5. Trừu tượng hoá kiến trúc mô hình 26](#_Toc231048579)

[2.2.6. Thiết lập chiến lược huấn luyện tinh chỉnh 27](#_Toc231048580)

[2.3. Đánh giá mô hình từng mô hình học sâu 29](#_Toc231048581)

[2.3.1. Các chỉ số đánh giá tỷ lệ chính xác 29](#_Toc231048582)

[2.3.2. Đồ thị biểu diễn độ chính xác và hàm mất mát 30](#_Toc231048583)

[2.4. So sánh và giải thích kết quả của mỗi mô hình 34](#_Toc231048584)

[2.4.1. Đánh giá dựa trên các chỉ số phân loại tổng thể 34](#_Toc231048585)

[2.4.2. Đánh giá khả năng phân tách qua Đường cong ROC 35](#_Toc231048586)

[2.4.3. Phân tích nguyên nhân nhầm lẫn qua Ma trận nhầm lẫn 40](#_Toc231048587)

[CHƯƠNG 3. KẾT LUẬN 47](#_Toc231048588)

[3.1. Tóm tắt kết quả đạt được 47](#_Toc231048589)

[3.2. Hạn chế của đề tài 49](#_Toc231048590)

[3.3. Định hướng mở rộng 50](#_Toc231048591)

DANH SÁCH CÁC HÌNH

[Hình 1.1. Ảnh mẫu từ 6 lớp cảnh quan 11](#_Toc231252482)

[Hình 2.1. Đồ thị biểu diễn chính xác và hàm mất mát của mô hình VGG16 31](#_Toc231252483)

[Hình 2.2. Đồ thị biểu diễn chính xác và hàm mất mát của mô hình ResNet50 32](#_Toc231252484)

[Hình 2.3. Đồ thị biểu diễn chính xác và hàm mất mát của mô hình DenseNet121 32](#_Toc231252485)

[Hình 2.4. Đồ thị biểu diễn chính xác và hàm mất mát của mô hình MobileNetV2 33](#_Toc231252486)

[Hình 2.5. Đường cong ROC của mô hình VGG16 35](#_Toc231252487)

[Hình 2.6. Đường cong ROC của mô hình ResNet50 37](#_Toc231252488)

[Hình 2.7. Đường cong ROC của mô hình DenseNet121 38](#_Toc231252489)

[Hình 2.8. Đường cong ROC của mô hình MobileNetV2 39](#_Toc231252490)

[Hình 2.9. Ma trận nhầm lẫn của mô hình VGG16 41](#_Toc231252491)

[Hình 2.10. Ma trận nhầm lẫn của mô hình ResNet50 42](#_Toc231252492)

[Hình 2.11. Ma trận nhầm lẫn của mô hình DenseNet121 43](#_Toc231252493)

[Hình 2.12. Ma trận nhầm lẫn của mô hình MobileNetV2 44](#_Toc231252494)

[Hình 3.1. So sánh tốc độ hội tụ của 4 kiến trúc 47](#_Toc231252495)

[Hình 3.2. So sánh tổng hợp 4 độ đo 48](#_Toc231252496)

[Hình 3.3. So sánh thời gian phân lớp trên 1 ảnh (ms) 48](#_Toc231252497)

[Hình 3.4. Sự đánh đổi giữa kích thước mô hình và độ chính xác 49](#_Toc231252498)

# DANH MỤC CÁC BẢNG

[Bảng 1.1. Tổng hợp các thuộc tính kỹ thuật và quy mô của bộ dữ liệu Intel Image Classification 8](#_Toc230986169)

[Bảng 1.2. Thống kê phân bổ quy mô các tập dữ liệu cho Train/ Test/ Validation 9](#_Toc230986170)

[Bảng 2.1. Tổng hợp các chỉ số đánh giá độ chính xác của 4 mô hình học sâu 30](#_Toc230986171)

# CHƯƠNG 1. GIỚI THIỆU BÀI TOÁN

# 1.1. Mô tả bài toán

Bài toán phân loại cảnh quan tự nhiên (Natural Scenes Classification) thuộc nhóm bài toán phân lớp hình ảnh đa lớp (Multi – class Image Classification). Bài toán này tập trung vào việc gán nhãn tự động cho bức ảnh thực tế ngoài trời, yêu cầu hệ thống phân loại chính xác hình ảnh vào một trong 6 danh mục mục tiêu đã được định nghĩa trước.

Mục tiêu cốt lõi của đề tài là xây dựng một mô hình máy học có khả năng tự động trích xuất các đặc trưng thị giác từ một bức ảnh đầu vào (ảnh chụp ngoài trời) và phân loại bức ảnh đó một cách chuẩn xác vào một trong các danh mục địa hình. Thách thức lớn nhất trong quá trình phân lớp này nằm ở sự tương đồng cao về đặc trưng thị giác giữa các lớp địa hình tự nhiên, điển hình như sự giống nhau về mặt cấu trúc hình học và màu sắc giữa lớp núi (Mountain) và lớp sông băng (Glacier).

Việc giải quyết thành công bài toán phân lớp ảnh này sẽ tạo nền tảng vững chắc cho nhiều hệ thống thông minh hiện đại. Cụ thể, khả năng tự động nhận diện và phân loại hình ảnh đóng vai trò nòng cốt trong việc xây dựng vô số các ứng dụng thực tiễn ngày nay như: phát triển hệ thống xe tự hành, tối ưu hoá công cụ tìm kiếm hình ảnh thông minh và xây dựng các nền tảng du lịch trực tuyến.

## 1.2. Giới thiệu bộ dữ liệu

**- Nguồn dữ liệu:** Nền tảng Kaggle

**-** **Tên bộ dữ liệu:** Intel Image Classification

**- Đường dẫn:** https://www.kaggle.com/datasets/puneet6060/intel-image-classification.

**-** **Phương pháp gán nhãn**: Dữ liệu trong tập này được gán nhãn theo phương pháp Directory-based Labeling.Cụ thể, nhãn của từng hình ảnh được hệ thống phân loại xác định tự động thông qua việc đối chiếu với tên của thư mục đang chứa hình ảnh đó (ví dụ: một thư mục mang tên "forest" sẽ được dùng để chứa toàn bộ các bức ảnh thuộc danh mục rừng).

**- Tính cân bằng của dữ liệu:** Dựa trên quá trình khảo sát và tính toán định lượng tỷ lệ phân bổ của các lớp, bộ dữ liệu thể hiện trạng thái cân bằng rất tốt. Đặc tính này đóng vai trò vô cùng quan trọng, giúp đảm bảo cho mô hình học máy không bị rơi vào trạng thái thiên kiến (bias) đối với bất kỳ một lớp dữ liệu chiếm đa số nào trong suốt quá trình huấn luyện.

## 1.3. Mô tả dữ liệu

### 1.3.1. Mô tả các thuộc tính dữ liệu

Bộ dữ liệu Intel Image Classification bao gồm các hình ảnh mô tả 6 danh mục mục tiêu thuộc các loại địa hình cảnh quan tự nhiên đa dạng. Nhằm cung cấp cái nhìn tổng quan và trực quan nhất về các đặc trưng kỹ thuật cũng như quy mô phân tách của tập dữ liệu phục vụ cho quá trình huấn luyện mô hình, toàn bộ các thuộc tính cốt lõi được thống kê chi tiết trong bảng dưới đây:

*Bảng 1.1. Tổng hợp các thuộc tính kỹ thuật và quy mô của bộ dữ liệu Intel Image Classification*

|  |  |  |
| --- | --- | --- |
| **STT** | **Đặc trưng/Thuộc tính** | **Mô tả chi tiết** |
| 1 | Định dạng hình ảnh | Hình ảnh màu chuẩn không gian màu RGB |
| 2 | Kích thước ảnh gốc | 150 x 150 pixels |
| 3 | Kích thước tiền xử lý | 224 x 224 pixels (Dữ liệu được chuẩn hóa lên kích thước này nhằm khai thác tối ưu các bộ lọc đặc trưng từ những mạng Nơ-ron học sâu đã được huấn luyện sẵn). |
| 4 | Số lượng danh mục (Lớp) | 06 lớp cảnh quan tự nhiên (Bao gồm: buildings, forest, glacier, mountain, sea, street). |
| 5 | Tập huấn luyện (Train set) | Bao gồm khoảng 14.034 mẫu ảnh (Được sử dụng trực tiếp để mô hình học các đặc trưng thị giác). |
| 6 | Tập kiểm tra (Test set) | Bao gồm khoảng 3.000 mẫu ảnh (Được sử dụng làm thước đo độc lập để đánh giá hiệu năng mô hình sau huấn luyện). |
| Tổng | Tổng số lượng dữ liệu | Khoảng 17.034 mẫu ảnh |

Dựa vào bảng thống kê trên, có thể thấy bộ dữ liệu cung cấp một lượng lớn hình ảnh màu đa dạng bao quát 6 loại không gian ngoài trời. Mặc dù các hình ảnh nguyên bản được thu thập với độ phân giải 150 x 150 pixels, nhưng trong quá trình tiền xử lý, toàn bộ ảnh đều được chuẩn hóa (resize) về kích thước 224 x 224 pixels. Việc điều chỉnh kích thước này là một thao tác kỹ thuật cần thiết nhằm đáp ứng đúng chuẩn đầu vào của các kiến trúc mạng học sâu đã được huấn luyện sẵn (Pre-trained models), từ đó giúp mô hình khai thác tối đa sức mạnh của các bộ lọc đặc trưng.

### 1.3.2. Số lượng mẫu cho train/test/validation

Nhằm phục vụ cho quá trình huấn luyện và đánh giá mô hình học sâu một cách toàn diện, khách quan, bộ dữ liệu Intel Image Classification với tổng quy mô khoảng 17.034 ảnh được tổ chức phân tách một cách khoa học. Dựa trên cấu trúc thư mục gốc kết hợp với tham số chia tách trong mã nguồn (validation\_split=0.2), dữ liệu được chia thành 3 tập riêng biệt. Chi tiết phân bổ được thống kê trong bảng sau:

*Bảng 1.2. Thống kê phân bổ quy mô các tập dữ liệu cho Train/ Test/ Validation*

|  |  |  |  |  |
| --- | --- | --- | --- | --- |
| **STT** | **Tập dữ liệu** | **Tỷ lệ phân tách** | **Số lượng mẫu** | **Vai trò cốt lõi** |
| **1** | **Tập huấn luyện (Training set)** | 80% | ~11.227 ảnh | Cung cấp dữ liệu chính để mạng Nơ-ron học hỏi, tối ưu hóa các trọng số và trích xuất đặc trưng thị giác từ 6 lớp cảnh quan. |
| **2** | **Tập kiểm định (Validation set)** | 20% | ~2.807 ảnh | Đánh giá hiệu năng sau mỗi chu kỳ (epoch), giám sát trạng thái hội tụ, hỗ trợ tinh chỉnh siêu tham số và kích hoạt cơ chế Dừng sớm (Early Stopping). |
| **3** | **Tập kiểm tra (Testing set)** | Độc lập hoàn toàn | ~3.000 ảnh | Đóng vai trò làm thước đo khách quan cuối cùng để kiểm chứng độ chính xác và khả năng tổng quát hoá của hệ thống trên dữ liệu thực tế mới |
| **Tổng** | **Toàn bộ dữ liệu** |  | ~17.034 ảnh | Bao gồm toàn bộ 6 danh mục cảnh quan tự nhiên |

Việc phân bổ dữ liệu chặt chẽ thành 3 tập Train/Validation/Test như trên là một tiêu chuẩn kỹ thuật thiết yếu trong nghiên cứu Học máy. Cấu trúc này vừa đảm bảo cung cấp khối lượng dữ liệu khổng lồ (hơn 11.000 ảnh) để hệ thống phân biệt các lớp phức tạp, vừa đảm bảo các chỉ số đánh giá độ tin cậy mang tính khách quan tuyệt đối.

## 1.4. Trực quan dữ liệu

Nhằm minh hoạ một cách trực quan đặc điểm quang học, mức độ phức tạp của bài toán cũng như cung cấp bằng chứng về tính cân bằng của dữ liệu, nghiên cứu tiến hành trực quan hoá các mẫu ảnh đặc trưng và phân bố nhãn lớp như sau:

### 1.4.1. Hiển thị mẫu ảnh

Dưới đây là các hình ảnh đại diện được trích xuất ngẫu nhiên cho 6 danh mục cảnh quan tự nhiên trong bộ dữ liệu Intel. Sự đa dạng về bối cảnh, góc chụp và đặc biệt là mức độ tương đồng cao về hình học giữa một số lớp (điển hình như sự giống nhau giữa lớp núi - Mountain và lớp sông băng - Glacier) thể hiện rõ những thách thức mà mô hình học sâu cần giải quyết trong quá trình học và trích xuất đặc trưng.

**![](data:image/png;base64...)**

*Hình 1.1. Ảnh mẫu từ 6 lớp cảnh quan*

### 1.4.2. Biểu đồ phân bố nhãn lớp

Để kiểm chứng định lượng về tính đồng đều của dữ liệu phục vụ cho quá trình huấn luyện, biểu đồ dưới đây biểu diễn cơ cấu số lượng mẫu ảnh của từng lớp trong tập huấn luyện (Train set).

![](data:image/png;base64...)*Hình 1.2. Biểu đồ phân bố số lượng mẫu ảnh theo từng nhãn lớp trên tập dữ liệu huấn luyện*

Biểu đồ cung cấp bằng chứng trực quan cho thấy số lượng mẫu giữa 6 danh mục cảnh quan (buildings, forest, glacier, mountain, sea, street) không có sự chênh lệch đáng kể, tất cả đều dao động đồng đều ở ngưỡng từ 2000 đến hơn 2500 mẫu. Điều này khẳng định bộ dữ liệu đạt trạng thái cân bằng rất tốt, giúp loại bỏ hoàn toàn nguy cơ mô hình bị thiên lệch (bias) đối với bất kỳ lớp chiếm đa số nào trong suốt quá trình học.

# CHƯƠNG 2. XÂY DỰNG VÀ HUẤN LUYỆN MÔ HÌNH

## 2.1. Mô tả kiến trúc của các mô hình học sâu

### 2.1.1. Giới thiệu các mô hình đã chọn và cơ sở toán học chung

Để giải quyết bài toán phân loại hình ảnh cảnh quan tự nhiên, nghiên cứu lựa chọn và cài đặt 4 kiến trúc mạng Nơ-ron Tích chập (CNN) tiên tiến, bao gồm: VGG16, ResNet50, DenseNet121 và MobileNetV2. Việc ứng dụng đồng thời nhiều mô hình nhằm mục đích đánh giá toàn diện hiệu năng trích xuất đặc trưng thị giác của từng cấu trúc mạng.

Trong quá trình xây dựng và huấn luyện các mô hình học sâu này, nghiên cứu áp dụng kỹ thuật Học chuyển giao (Transfer Learning) kết hợp với các phương pháp điều chuẩn (Regularization) nhằm tối ưu hóa hiệu suất trích xuất đặc trưng và ngăn chặn triệt để hiện tượng quá khớp (Overfitting). Các cơ sở toán học cốt lõi chi phối luồng hoạt động chung của các mạng nơ-ron được định nghĩa và phân tích chi tiết như sau:

**a) Hàm kích hoạt Softmax (Softmax Activation Function)**: Do bản chất của đề tài là bài toán phân lớp đa lớp, hàm kích hoạt Softmax bắt buộc phải được thiết lập tại lớp phân loại cuối cùng (Output layer) của mọi kiến trúc. Công thức toán học của hàm được biểu diễn như sau:

$$σ ( z)\_{i} = \frac{e^{Z\_{i}}}{\sum\_{j=1}^{K}e^{Z\_{i}}}$$

Trong đó:

- $Z\_{i}$: Là giá trị đầu ra thô (logit) chưa chuẩn hóa của nơ-ron thứ *i*.

- K: Tổng số lớp mục tiêu của bài toán (ở đây K = 6, tương ứng với 6 danh mục: buildings, forest, glacier, mountain, sea, street).

Việc sử dụng hàm số tự nhiên *e* (hàm mũ) ở tử số có tác dụng khuếch đại phi tuyến tính: những logit có giá trị lớn sẽ càng trở nên nổi bật, trong khi các logit âm sẽ bị ép về sát . Tiếp đó, phép chia cho tổng các giá trị hàm mũ $\sum\_{j=1}^{K}e^{Z\_{i}}$ đóng vai trò như một phép chuẩn hóa toàn cục. Nhờ vậy, hàm Softmax chuyển đổi một vector đầu ra thô thành một phân phối xác suất dự đoán hợp lệ, trong đó xác suất của từng lớp nằm trong khoảng (0,1) và tổng xác suất của cả 6 lớp luôn bằng tuyệt đối 1.

**b) Hàm mất mát Categorical Cross-Entropy:** Để định lượng mức độ sai lệch giữa phân phối xác suất dự đoán của mô hình và nhãn thực tế, hệ thống sử dụng hàm mất mát Categorical Cross-Entropy. Công thức được định nghĩa là:

$$L\left(y,ŷ\right)=-\sum\_{i = 1}^{K}y\_{i}log(ŷ\_{i})$$

Trong đó:

- $y\_{i}$: Là nhãn thực tế của hình ảnh, được mã hóa dưới dạng vector One-hot (nhận giá trị 1 tại vị trí lớp đúng và 0 tại vị trí lớp sai).

- $ŷ\_{i}$: Là xác suất dự đoán do hàm Softmax trả về cho lớp thứ *i*.

Do tính chất của vector One-hot (chỉ có một giá trị $y\_{i}$= 1), hàm tổng ∑ thực chất bị triệt tiêu ở mọi lớp sai và chỉ giữ lại phép tính - $log(ŷ\_{i})$ tại lớp đúng. Hàm logarit âm (- log) có đặc tính rất đặc biệt: nếu mô hình dự đoán chính xác (xác suất tiến gần về 1), sai số sẽ tiến về 0 . Tuy nhiên, nếu mô hình tự tin đưa ra dự đoán sai (xác suất lớp đúng tiến về 0), hàm logarit sẽ trừng phạt mô hình bằng một giá trị sai số tiến ra vô cực. Cơ chế phạt nặng này tạo ra tín hiệu đạo hàm cực kỳ mạnh mẽ, giúp thuật toán lan truyền ngược (Backpropagation) điều chỉnh trọng số nhanh chóng và chính xác.

**c) Kỹ thuật điều chuẩn L2 Regularization (Weight Decay):** Một trong những thách thức lớn nhất khi huấn luyện các mạng CNN học sâu (đặc biệt là các mạng có hàng chục triệu tham số như ResNet50 hay VGG16) là hiện tượng quá khớp (Overfitting). Để giải quyết vấn đề này, kỹ thuật L2 Regularization được tích hợp, làm biến đổi hàm mất mát tổng thể thành:

$$L\_{total }= L + ⋋\sum\_{}^{}w^{2}$$

Trong đó:

- $L$: Là hàm mất mát Categorical Cross-Entropy nguyên bản.

- *w:* Đại diện cho các ma trận trọng số (weights) bên trong mạng nơ-ron.

- $⋋$: Là hệ số phạt (penalty coefficient), dùng để kiểm soát mức độ điều chuẩn.

Bằng cách cộng thêm tổng bình phương của tất cả các trọng số $(\sum\_{}^{}w^{2})$ vào hàm mất mát gốc, thuật toán tối ưu (Optimizer) bị đặt vào một bài toán tối ưu kép: vừa phải phân loại đúng ảnh để giảm $L$, vừa phải triệt tiêu các giá trị trọng số *w* để giữ cho chúng ở mức nhỏ nhất có thể. Thành phần phạt này ngăn chặn hiện tượng bùng nổ trọng số – nguyên nhân cốt lõi khiến các đường ranh giới quyết định (decision boundary) trở nên quá phức tạp và nhạy cảm với nhiễu. Nhờ L2 Regularization, mô hình học được các đặc trưng mượt mà hơn và gia tăng tính tổng quát hóa khi dự đoán trên tập kiểm tra độc lập.

### 2.1.2. Kiến trúc VGG16

VGG16 là một trong những mạng Nơ-ron Tích chập (CNN) kinh điển và phổ biến nhất trong lĩnh vực thị giác máy tính, nổi bật với thiết kế kiến trúc đồng nhất nhưng mang lại hiệu quả cực kỳ cao trong việc phân loại và nhận diện hình ảnh quy mô lớn.

Nhằm tận dụng sức mạnh của kỹ thuật Học chuyển giao (Transfer Learning), kiến trúc yêu cầu toàn bộ dữ liệu hình ảnh trước khi đưa vào mạng lưới phải được chuẩn hóa nghiêm ngặt về kích thước pixels với 3 kênh màu (RGB), tương đương với kích thước tensor là 224 x 224 x 3.

Mạng sở hữu độ sâu cấu trúc bao gồm tổng cộng 16 lớp có trọng số có thể huấn luyện (bao gồm các lớp Tích chập và các lớp Kết nối đầy đủ - Fully Connected Layers).

Điểm đặc trưng làm nên sức mạnh cốt lõi của VGG16 là việc mô hình này áp dụng liên tiếp các khối tích chập (Convolutional Blocks) sử dụng bộ lọc (filter) có kích thước rất nhỏ, chỉ 3 x 3. Thay vì dùng các bộ lọc lớn trong một lớp đơn lẻ, việc xếp chồng nhiều bộ lọc nhỏ lên nhau giúp mạng lưới gia tăng đáng kể độ sâu cấu trúc. Chính sự gia tăng về độ sâu này đã cung cấp cho VGG16 khả năng trích xuất các đặc trưng hình ảnh vô cùng mạnh mẽ và chi tiết. Các lớp tích chập nông đầu tiên sẽ chịu trách nhiệm học các đường nét, góc cạnh cơ bản, trong khi các tầng sâu hơn sẽ tổng hợp thông tin để nhận diện ra các cấu trúc hình học phức tạp của cảnh quan thiên nhiên (như cấu trúc gồ ghề của núi hay sự nhấp nhô của sông băng).

### 2.1.3. Kiến trúc ResNet50

ResNet50 là một mô hình học sâu mang tính đột phá, được thiết kế để giải quyết triệt để vấn đề biến mất đạo hàm (Vanishing Gradient) – một hiện tượng phổ biến khiến các mạng nơ-ron có cấu trúc rất sâu không thể huấn luyện được.

Mặc dù hình ảnh nguyên bản của bộ dữ liệu chỉ có độ phân giải 150 x 150 pixels, nhưng để tận dụng tối đa sức mạnh của phương pháp Học chuyển giao (Transfer Learning), mạng tiếp nhận đầu vào là các tensor hình ảnh đã qua tiền xử lý, ép chuẩn hóa về kích thước 224 x 224 x 3. Thao tác kỹ thuật này nhằm tương thích hoàn toàn với chuẩn đầu vào của các kiến trúc mạng học sâu đã được huấn luyện sẵn trên ImageNet.

Mô hình sở hữu một mạng lưới rất sâu lên tới 50 lớp có trọng số có thể huấn luyện. Điểm khác biệt cốt lõi làm nên sự thành công của ResNet là việc áp dụng kỹ thuật Kết nối tắt (Skip Connection). Thay vì bắt các lớp xếp chồng lên nhau phải học toàn bộ một hàm ánh xạ phức tạp, ResNet chỉ yêu cầu chúng học phần thặng dư (residual). Sự đột phá của kiến trúc ResNet nằm ở công thức biểu diễn luồng thông tin qua các tầng mạng của khối thặng dư:

*y = F(x{*$W\_{i}$*​}) + x*

Trong đó:

- x: Là ma trận/tensor dữ liệu đầu vào (Input) của một khối kiến trúc.

- F(x,$W\_{i}$}): Là hàm ánh xạ thặng dư (Residual Mapping) mà các lớp tích chập cần phải học. Hàm này đại diện cho các phép biến đổi phức tạp khi dữ liệu đi qua các lớp Tích chập đi kèm với bộ trọng số $W\_{i}$. Thay vì ép mạng lưới phải học toàn bộ biểu diễn đặc trưng, ResNet chỉ yêu cầu mạng học "phần thặng dư" (những đặc trưng mới mà các lớp trước chưa trích xuất được).

- x (Skip Connection / Kết nối tắt): Đây chính là cốt lõi tạo nên sức mạnh của mô hình. Thao tác cộng trực tiếp đầu vào x vào đầu ra của hàm *F* tạo ra một "đường tắt". Cơ chế này cho phép thông tin (bản sắc của hình ảnh gốc) được truyền đi nguyên vẹn xuyên qua nhiều tầng mạng mà không bị suy giảm hay biến dạng.

- y: Là đầu ra (Output) tổng thể của khối sau khi thực hiện phép cộng.

Trong các mạng CNN truyền thống, khi độ sâu tăng lên, giá trị đạo hàm truyền ngược thường bị triệt tiêu về 0. Tuy nhiên, với công thức của ResNet, trong quá trình lan truyền ngược (Backpropagation), khi tính đạo hàm của đầu ra *y* theo đầu vào *x,* ta có: $\frac{∂y}{∂x}=\frac{∂F}{∂x} + 1$ . Sự xuất hiện của hằng số 1 mang ý nghĩa toán học sống còn. Nó đóng vai trò như một lực đẩy, đảm bảo rằng ngay cả khi thành phần đạo hàm $\frac{∂F}{∂x} $tiến về 0 do mạng quá sâu, đạo hàm tổng thể vẫn luôn được bảo toàn. Nhờ đó, luồng thông tin truyền đi nguyên vẹn hơn, giúp mô hình có thể cập nhật trọng số hiệu quả và hội tụ thành công bất chấp độ sâu lên tới 50 lớp.

### 2.1.4. Kiến trúc DenseNet121 (Densely Connected Convolutional Network)

DenseNet là kiến trúc được phát triển và kế thừa dựa trên ý tưởng của mạng ResNet, nhưng tiến xa hơn trong việc tối ưu hóa luồng thông tin truyền tải trong mạng thông qua cơ chế kết nối dày đặc (Dense Connectivity).

Mô hình tiếp nhận đầu vào là các tensor hình ảnh có kích thước chuẩn pixels 224 x 224 x 3 pixels. Điểm làm nên tính độc bản của DenseNet là cơ chế kết nối dày đặc. Cụ thể, thay vì chỉ kết nối lớp trước với lớp ngay sau nó, DenseNet kết nối mỗi lớp với *tất cả* các lớp trước đó trong cùng một khối đặc (Dense Block)

Sự đột phá của kiến trúc DenseNet nằm ở công thức biểu diễn luồng thông tin qua các tầng mạng:

$$x\_{l} = H\_{l}([x\_{0,}x\_{1,}...., x\_{l-1}])$$

Trong đó:

- *l:* Là chỉ số của lớp (layer) hiện tại đang xét trong mạng.

- $x\_{l}$: Là đầu ra (Output) hay bản đồ đặc trưng (feature map) của lớp thứ *l*.

- $[x\_{0,}x\_{1,},...., x\_{l-1}]$: (Phép ghép nối - Concatenation): Trái ngược với ResNet là sử dụng phép "cộng" ma trận các đặc trưng, DenseNet sử dụng phép "ghép nối" tất cả các bản đồ đặc trưng từ các lớp trước đó (từ lớp đầu tiên 0 cho đến lớp ngay trước nó *l - 1*) theo chiều sâu kênh (channel-wise).

- $H\_{l}$: Là một hàm phi tuyến tổng hợp (Composite function) đại diện cho các phép biến đổi tại lớp thứ *l*, bao gồm các thao tác: Chuẩn hóa theo lô (Batch Normalization), hàm kích hoạt ReLU, và phép Tích chập (Convolution).

Việc sử dụng thao tác ghép nối $[x\_{0,}x\_{1,},...., x\_{l-1}]$: mang lại một lợi thế toán học tuyệt vời là khả năng "Tái sử dụng đặc trưng" (Feature Reuse). Thay vì các lớp sâu phải tốn công học lại từ đầu, mạng chuyển thẳng các đặc trưng cơ bản (góc cạnh, màu sắc) đã được trích xuất ở các lớp nông tới mọi tầng sâu hơn. Cơ chế này không chỉ giúp duy trì luồng đạo hàm (gradient) một cách nguyên vẹn để chống lại hiện tượng biến mất đạo hàm, mà còn giúp giảm thiểu đáng kể lượng tham số cần thiết kế do mỗi lớp mới chỉ cần thêm vào một lượng nhỏ các đặc trưng thay vì tái tạo lại toàn bộ.

### 2.1.5. Kiến trúc MobileNetV2

Khác với các kiến trúc cố gắng tối đa hóa độ chính xác bằng cách tăng cường độ sâu như ResNet hay DenseNet, MobileNetV2 được tinh chỉnh đặc biệt nhằm tối ưu hóa cho tốc độ xử lý, cực kỳ phù hợp để triển khai thực tế trên các thiết bị di động có giới hạn về tài nguyên tính toán. Yêu cầu đầu vào tiêu chuẩn 224 x 224 x 3 pixels.

Trái tim của MobileNetV2 nằm ở việc áp dụng phương pháp Tích chập tách khối (Depthwise Separable Convolution). Phương pháp này chia phép tích chập không gian tiêu chuẩn thành hai bước độc lập: lọc theo từng kênh chiều sâu (Depthwise Convolution) và sau đó kết hợp bằng tích chập điểm 1 x 1 (Pointwise Convolution).

Về mặt toán học, cấu trúc Tích chập tách khối giúp mô hình thu gọn mạnh mẽ khối lượng phép tính. So với chi phí tính toán của tích chập truyền thống là: $D\_{K}^{2} . M . N$*,* thuật toán của MobileNetV2 giúp giảm thiểu khối lượng tính toán xuống chỉ còn:

$D\_{K}^{2} . M + M . N$

Trong đó:

*-* $D\_{K}$: Là kích thước không gian của bộ lọc.

*- M*: Là số lượng kênh đầu vào (Input channels).

*- N*: Là số lượng kênh đầu ra (Output channels).

Sự chuyển đổi khéo léo này phân tách chi phí tính toán $D\_{K}^{2} . M . N$ khổng lồ thành phép cộng hai thành phần nhỏ hơn rất nhiều ($D\_{K}^{2} . M + M . N$). Nhờ đó, MobileNetV2 loại bỏ được một lượng lớn các phép tính dư thừa, giúp giảm đáng kể khối lượng tham số tính toán trong khi khả năng biểu diễn đặc trưng hình ảnh vẫn được bảo toàn ở mức độ chính xác rất cạnh tranh.

## 2.2. Cài đặt mô hình bằng Python

Quá trình xây dựng, cấu hình và huấn luyện các mô hình học sâu được triển khai trên môi trường ngôn ngữ lập trình Python, tận dụng các sức mạnh của nền tảng mã nguồn mở TensorFlow và Keras. Nhằm tối ưu hoá hiệu năng tính toán trên GPU và kiểm soát triệt để hiện tượng quá khớp (Overfiting), kiến trúc mã nguồn được phân rã thành các phân hệ chức năng chuyên biệt cùng phân tích thuật toán đi kèm:

### 2.2.1. Môi trường thực nghiệm và Công cụ hỗ trợ

Để đảm bảo hiệu năng tính toán cũng như tính đồng bộ trong quá trình xây dựng, huấn luyện và đánh giá các mô hình học sâu, toàn bộ quá trình thực nghiệm của nghiên cứu được triển khai trên nền tảng điện toán đám mây Google Colab. Các thiết lập về phần cứng và phần mềm được cấu hình cụ thể như sau:

Các kiến trúc mạng Nơ-ron Tích chập (CNN) như VGG16, ResNet50 hay DenseNet121 đòi hỏi năng lực xử lý phép nhân ma trận khổng lồ. Do đó, nghiên cứu sử dụng bộ xử lý đồ họa (GPU) NVIDIA Tesla T4 với dung lượng 16GB VRAM. Việc sử dụng phần cứng chuyên dụng này kết hợp với kỹ thuật tính toán độ chính xác hỗn hợp (Mixed Precision) giúp tăng tốc độ huấn luyện lên tối đa, đồng thời ngăn chặn tình trạng tràn bộ nhớ (Out-Of-Memory) khi xử lý các lô hình ảnh có kích thước lớn. Đặc biệt, toàn bộ quá trình Tăng cường dữ liệu (Data Augmentation) được thiết lập chạy trực tiếp trên GPU nhằm giải phóng nút thắt cổ chai ở CPU, tối ưu hóa triệt để luồng dữ liệu đầu vào.

Toàn bộ mã nguồn được viết bằng ngôn ngữ Python (phiên bản 3.x), đây là ngôn ngữ tiêu chuẩn và hỗ trợ hệ sinh thái mạnh mẽ nhất cho trí tuệ nhân tạo hiện nay.

Nghiên cứu sử dụng thư viện mã nguồn mở TensorFlow và Keras (phiên bản mới nhất) làm nền tảng cốt lõi. Thư viện này cung cấp sẵn các bộ trọng số đã được huấn luyện trên ImageNet, hỗ trợ thiết lập hệ thống đường ống dữ liệu (Data Pipeline), và cung cấp các hàm tối ưu hóa thuật toán cực kỳ linh hoạt cho chiến lược Học chuyển giao (Transfer Learning) và Tinh chỉnh (Fine-tuning).

Các thư viện xử lý và trực quan hóa dữ liệu:

- Scikit-learn (sklearn): Được ứng dụng để trích xuất các độ đo đánh giá mô hình chuyên sâu như Ma trận nhầm lẫn (Confusion Matrix), Báo cáo phân loại (Classification Report), và thiết lập dữ liệu để vẽ đường cong ROC/AUC.

- NumPy và Pandas: Đóng vai trò cấu trúc hóa dữ liệu thống kê, xử lý các mảng vector đa chiều và tính toán định lượng tỷ lệ phân bổ của các tập dữ liệu.

- Matplotlib và Seaborn: Được sử dụng để trực quan hóa dữ liệu một cách chuyên nghiệp, từ việc vẽ biểu đồ phân phối nhãn lớp, biểu diễn hình ảnh thực tế, cho đến vẽ đồ thị hội tụ (Learning Curves) của hàm mất mát và độ chính xác sau mỗi chu kỳ (epoch).

### 2.2.2. Khai báo thư viện và Thiết lập dữ liệu đầu vào

Để bắt đầu quá trình xây dựng hệ thống, nghiên cứu tiến hành nạp các thư viện tính toán khoa học, các module học sâu cốt lõi từ hệ sinh thái TensorFlow, và thiết lập đường dẫn giải nén bộ dữ liệu Intel Image Classification từ nền tảng lưu trữ đám mây. Đồng thời, một lớp Callback tùy chỉnh được định nghĩa để đo lường chính xác thời gian tính toán của GPU qua từng chu kỳ huấn luyện.

|  |
| --- |
| import os  import time  import numpy as np  import pandas as pd  import seaborn as sns  import matplotlib.pyplot as plt  import tensorflow as tf  from tensorflow.keras import layers, models, callbacks, regularizers  from sklearn.metrics import classification\_report, confusion\_matrix, accuracy\_score, precision\_score, recall\_score, f1\_score, roc\_curve, auc  from sklearn.preprocessing import label\_binarize  os.environ['TF\_CPP\_MIN\_LOG\_LEVEL'] = '3'  BASE\_PATH = "/content/intel\_data"  TRAIN\_DIR = os.path.join(BASE\_PATH, "train")  TEST\_DIR = os.path.join(BASE\_PATH, "test")  if not os.path.exists(TRAIN\_DIR):  raise FileNotFoundError("LỖI: Không tìm thấy dữ liệu huấn luyện!") |

**Giải thích:**

- Hệ sinh thái học sâu (tensorflow.keras): Nạp các module cốt lõi như layers, models để xây dựng cấu trúc mạng Nơ-ron nhiều tầng, và regularizers để gọi thuật toán phạt L2 Penalty nhằm chống hiện tượng quá khớp (Overfitting).

-Thư viện đánh giá chuyên sâu (sklearn.metrics): Sử dụng các hàm classification\_report, confusion\_matrix và roc\_curve phục vụ cho việc trích xuất, đo lường độ chính xác và vẽ biểu đồ báo cáo hiệu năng ở Chương 3.

- Thư viện trực quan hóa (matplotlib, seaborn): Hỗ trợ vẽ đồ thị đường cong hội tụ (Learning Curve) của hàm mất mát và độ chính xác sau mỗi chu kỳ (epoch).

- Thiết lập cấu trúc đường dẫn: Các biến hằng số TRAIN\_DIR và TEST\_DIR được thiết lập trỏ chính xác vào hệ thống thư mục chứa 6 danh mục ảnh. Thao tác này đóng vai trò tạo tiền đề đầu vào bắt buộc cho việc xây dựng đường ống nạp dữ liệu tự động (Data Pipeline) ở bước tiếp theo.

### 2.2.3. Khởi tạo đường ống nạp dữ liệu

Khâu đầu tiên và nền tảng nhất trong luồng xử lý là thiết lập đường ống nạp dữ liệu hình ảnh trực tiếp từ hệ thống thư mục lưu trữ. Dữ liệu được cấu hình nạp theo từng lô (batch) để tối ưu hoá sức chứa của bộ nhớ.

|  |
| --- |
| IMG\_SIZE = (224, 224)  BATCH\_SIZE = 32  train\_ds\_raw=tf.keras.utils.image\_dataset\_from\_directory(TRAIN\_DIR, validation\_split=0.2, subset='training', seed=123, image\_size=IMG\_SIZE, batch\_size=BATCH\_SIZE, label\_mode='categorical')  val\_ds\_raw=tf.keras.utils.image\_dataset\_from\_directory(TRAIN\_DIR, validation\_split=0.2, subset='validation', seed=123, image\_size=IMG\_SIZE, batch\_size=BATCH\_SIZE, label\_mode='categorical')  test\_ds\_raw = tf.keras.utils.image\_dataset\_from\_directory(  TEST\_DIR,  image\_size=IMG\_SIZE,  batch\_size=BATCH\_SIZE,  label\_mode='categorical') |

**Giải thích:** Đoạn mã trên thực hiện nhiệm vụ thiết lập đường ống truyền tải dữ liệu hình ảnh trực tiếp từ hệ thống thư mục lưu trữ vào bộ nhớ xử lý. Dữ liệu được cấu hình nạp theo từng lô với kích thước BATCH\_SIZE = 32 nhằm tối ưu hóa sức chứa của bộ nhớ RAM và tăng tốc quá trình lan truyền của thuật toán. Ý nghĩa cụ thể của các tham số như sau:

- Hàm image\_dataset\_from\_directory: Được sử dụng để tự động duyệt qua các thư mục con, nạp hình ảnh và gán nhãn tương ứng theo tên của danh mục thư mục (Directory-based Labeling). Cơ chế này giúp bỏ qua bước gán nhãn thủ công phức tạp.

- Chuẩn hóa kích thước (image\_size=IMG\_SIZE): Tham số này đóng vai trò ép chuẩn hóa kích thước toàn bộ ảnh đầu vào về mức 224 x 224 pixels. Đây là thao tác kỹ thuật bắt buộc để các tensor hình ảnh tương thích hoàn toàn với cấu trúc màng lọc đầu vào của các mạng Nơ-ron Tích chập (CNN) đã được huấn luyện sẵn (Pre-trained models).

- Phân tách tập dữ liệu (validation\_split=0.2): Thông qua tham số này, hệ thống tự động trích xuất lượng dữ liệu từ thư mục gốc để hình thành tập Kiểm định (Validation set thông qua subset='validation'), đồng thời phân bổ còn lại cho tập Huấn luyện (Training set thông qua subset='training'). Việc thiết lập chung một hạt giống ngẫu nhiên (seed=123) đảm bảo sự nhất quán của hai tập dữ liệu trong mỗi lần chạy mã nguồn.

- Mã hóa nhãn đa lớp (label\_mode='categorical'): Tham số này chịu trách nhiệm chuyển đổi nhãn từ định dạng số nguyên thông thường sang định dạng vector One-hot Encoding. Việc chuyển đổi này là điều kiện tiên quyết để định dạng nhãn tương thích tuyệt đối với hàm mất mát Categorical Cross-Entropy đã được thiết lập cho bài toán phân lớp đa lớp.

- Tiền xử lý dữ liệu đặc thù (Preprocess Input): Khi sử dụng Học chuyển giao (Transfer Learning), việc chỉ chuẩn hóa kích thước ảnh (Resize) là chưa đủ. Mỗi kiến trúc mạng yêu cầu một phương pháp chuẩn hóa không gian màu (pixel scaling) riêng biệt để khớp với định dạng lúc chúng được huấn luyện trên ImageNet (ví dụ: VGG16 yêu cầu chuyển từ RGB sang BGR và trừ đi dải màu trung bình, trong khi MobileNetV2 yêu cầu đưa giá trị pixel về dải [-1,1]). Hệ thống đã nạp và tích hợp các hàm tiền xử lý chuyên biệt này trực tiếp vào luồng dữ liệu để đảm bảo các bộ lọc trích xuất đặc trưng với độ chính xác tối đa.

### 2.2.4. Tích hợp kỹ thuật tăng cường dữ liệu trên GPU

Để giải quyết bài toán thiếu hụt sự đa dạng của dữ liệu thực tế và gia tăng tính bền vững (robustness) của mô hình, một chuỗi các phép biến đổi hình học và quang học ngẫu nhiên được khởi tạo.

|  |
| --- |
| data\_aug = tf.keras.Sequential([      layers.RandomFlip("horizontal"),      layers.RandomRotation(0.2),      layers.RandomZoom(0.2),      layers.RandomContrast(0.1)]) |

**Giải thích:** Đoạn mã cấu hình data\_aug sử dụng hàm tf.keras.Sequential để đóng gói một chuỗi các phép biến đổi hình ảnh ngẫu nhiên, được thực thi trực tiếp trên phần cứng GPU. Ý nghĩa thuật toán của từng lớp được bóc tách như sau:

- layers.RandomFlip("horizontal"): Lật ngược hình ảnh theo chiều ngang một cách ngẫu nhiên. Phép biến đổi này giúp mô hình nhận diện cảnh quan (ví dụ: núi, biển) không bị phụ thuộc vào hướng nhìn trái/phải của bức ảnh gốc, qua đó học được tính đối xứng của tự nhiên.

- layers.RandomRotation(0.2): Xoay bức ảnh ngẫu nhiên với biên độ tối đa là 20% của 2$π$ (tương đương khoảng 72 độ). Thao tác này giúp mạng Nơ-ron tăng cường khả năng nhận diện đối tượng ở nhiều góc chụp nghiêng đa dạng trong môi trường thực tế.

- layers.RandomZoom(0.2)**:** Thu phóng quang học ngẫu nhiên lên đến 20%. Việc phóng to hoặc thu nhỏ tỷ lệ ảnh giúp mô hình học được các đặc trưng thị giác bất kể khoảng cách từ ống kính máy ảnh đến đối tượng (ví dụ: phân loại đúng cả khi chụp cận cảnh một tòa nhà hay khi chụp toàn cảnh đường phố từ xa).

- layers.RandomContrast(0.1)**:** Điều chỉnh độ tương phản của ảnh ngẫu nhiên trong khoảng 10%. Kỹ thuật này vô cùng quan trọng đối với ảnh phong cảnh ngoài trời, giúp hệ thống thích nghi tốt với các điều kiện độ sáng, thời tiết khác nhau (nắng gắt, râm mát, hay sương mù).

**-** Điểm đột phá về mặt kỹ thuật ở đây là việc định nghĩa Data Augmentation dưới dạng một Lớp (Layer) trực tiếp của Keras được tích hợp thẳng vào kiến trúc mạng. Cấu trúc này cho phép toàn bộ quá trình biến đổi ảnh được chuyển giao từ CPU sang xử lý tính toán song song trực tiếp trên GPU. Cơ chế này phá vỡ điểm thắt cổ chai (bottleneck) của luồng nạp dữ liệu, giúp đẩy nhanh tối đa tốc độ xử lý trong từng chu kỳ học.

### 2.2.5. Trừu tượng hoá kiến trúc mô hình

Nhằm đảm bảo tính đồng nhất khách quan khi tiến hành thực nghiệm so sánh 4 mạng CNN khác nhau, hệ thống định nghĩa một hàm dựng mô hình dùng chung mang tên build\_model\_custom. Hàm này vận dụng triết lý Học chuyển giao (Transfer Learning) kết hợp với các lớp điều chuẩn nghiêm ngặt nhằm triệt tiêu hiện tượng quá khớp (Overfitting).

|  |
| --- |
| def build\_model\_custom(base\_class):      base = base\_class(input\_shape=(224, 224, 3), include\_top=False, weights='imagenet')      model = models.Sequential([          data\_aug,          base,          layers.GlobalAveragePooling2D(),          layers.Dense(256, activation='relu', kernel\_regularizer=regularizers.l2(0.001)),          layers.Dropout(0.2),          layers.Dense(6, activation='softmax') ])      return model, base |

**Giải thích:** Luồng dữ liệu đi qua các tầng mạng trong hàm được bóc tách ý nghĩa toán học và cấu trúc như sau:

**-** Biến base nạp kiến trúc mạng CNN nền tảng (như VGG16, ResNet50...) cùng với bộ trọng số cực kỳ giá trị đã được hội tụ trên tập dữ liệu khổng lồ ImageNet (weights='imagenet'). Tham số include\_top=False đóng vai trò quan trọng trong việc cắt bỏ lớp phân loại 1000 đối tượng nguyên bản, chỉ giữ lại phần lõi chuyên trích xuất đặc trưng thị giác.

**-** Lớp data\_aug được đưa lên đầu tiên trong cấu trúc chuỗi (Sequential), đảm bảo mọi hình ảnh đầu vào đều được biến đổi ngẫu nhiên trên GPU trước khi đi vào mạng lõi.

**-** Lớp GlobalAveragePooling2D thực hiện tính trung bình không gian trên toàn bộ các bản đồ đặc trưng (feature maps) do Backbone xuất ra, nén chúng thành một vector 1 chiều. Thao tác này giúp triệt tiêu hàng triệu tham số tính toán không cần thiết so với kỹ thuật ép phẳng (Flatten) truyền thống.

**-** Dữ liệu tiếp tục đi qua một lớp ẩn Dense(256) sử dụng hàm kích hoạt phi tuyến ReLU. Tại đây, kỹ thuật L2 Regularization với hệ số phạt 0.001 được áp dụng thẳng vào nhân trọng số (kernel\_regularizer) để giới hạn biên độ tăng trưởng của tham số. Kế tiếp, lớp Dropout(0.2) thực hiện ngắt kết nối ngẫu nhiên số lượng nơ-ron nhằm phá vỡ sự phụ thuộc cục bộ, buộc mạng lưới phải học các biểu diễn tổng quát hơn.

**-** Lớp Dense(6) cuối cùng gắn liền với hàm kích hoạt softmax làm nhiệm vụ xuất ra phân phối xác suất dự đoán cho đúng 6 lớp cảnh quan tự nhiên của bài toán.

### 2.2.6. Thiết lập chiến lược huấn luyện tinh chỉnh

Trong quá trình thực nghiệm, để tối ưu hóa và áp dụng đồng loạt chiến lược huấn luyện 2 giai đoạn cho cả 4 kiến trúc mạng, nghiên cứu đã xây dựng một hàm trừu tượng hóa mang tên run\_experiment. Đoạn mã dưới đây minh họa cách thức gọi hàm để thực thi huấn luyện lần lượt cho VGG16, ResNet50, DenseNet121 và MobileNetV2.

|  |
| --- |
| def run\_experiment(builder\_fn, prep\_fn, name, epochs\_s1=10, epochs\_s2=10):      print(f"\n{'='\*35}\n>>> THỰC NGHIỆM MÔ HÌNH: {name}\n{'='\*35}")  theta = 0.001  k = 0  run\_experiment(lambda: build\_model\_custom(VGG16), p\_vgg, "VGG16")  run\_experiment(lambda: build\_model\_custom(ResNet50), p\_res, "ResNet50")  run\_experiment(lambda: build\_model\_custom(DenseNet121), p\_den, "DenseNet121")  run\_experiment(lambda: build\_model\_custom(MobileNetV2), p\_mob, "MobileNetV2") |

**Giải thích:**Hàm run\_experiment được thiết kế để nhận đầu vào là hàm xây dựng cấu trúc mô hình (builder\_fn) và hàm tiền xử lý đặc thù của từng mạng (prep\_fn). Việc đóng gói này đảm bảo cả 4 mô hình đều được huấn luyện trong một điều kiện cấu hình hoàn toàn nhất quán. Bên trong thân hàm, thuật toán tuân thủ nghiêm ngặt quy trình chống quá khớp (Overfitting) với các cơ chế sau:

- Chiến lược Fine-tuning 2 giai đoạn: Nhằm bảo vệ các trọng số đã được huấn luyện sẵn (Pre-trained weights) khỏi hiện tượng chấn động Gradient (Gradient Shock) khi tiếp xúc với dữ liệu mới, quá trình học được chia làm hai bước:

+ Giai đoạn 1 (Warm-up): Đóng băng (Freeze) hoàn toàn phần lõi trích xuất đặc trưng (Backbone). Hệ thống chỉ tập trung cập nhật các trọng số được khởi tạo ngẫu nhiên tại cụm phân loại mới (Classifier Head) với Tốc độ học (Learning Rate) tương đối lớn ở mức $10^{-3}$ .

+ Giai đoạn 2 (Fine-tuning): Mở khóa (Unfreeze) 50% số tầng mạng sâu nhất của khối Backbone. Đặc biệt, các lớp Chuẩn hóa theo lô (Batch Normalization) vẫn được giữ trạng thái đóng băng để duy trì các tham số thống kê (mean, variance) ổn định. Đồng thời, Tốc độ học được giảm mạnh xuống ngưỡng cực nhỏ ($10^{-5}$ .). Cơ chế này cho phép mạng lưới vi chỉnh tinh tế các đặc trưng hình học phức tạp của ảnh phong cảnh thiên nhiên mà không làm phá vỡ đi khối kiến thức nền tảng quý giá từ ImageNet.

- Cơ chế giám sát tự động (Callbacks): Trong suốt quá trình lan truyền ngược, hệ thống liên tục được giám sát bởi hai thuật toán:

+ EarlyStopping: Tự động chấm dứt quá trình huấn luyện khi hàm mất mát trên tập kiểm định (Val Loss) không còn dấu hiệu cải thiện sau một số chu kỳ nhất định, giúp mô hình bảo toàn được bộ trọng số tốt nhất và tiết kiệm tài nguyên tính toán.

+ ReduceLROnPlateau: Một kỹ thuật tối ưu hóa động, tự động thu hẹp tốc độ học khi mô hình đi vào trạng thái bão hòa (plateau) tại các điểm cực tiểu cục bộ, giúp hàm mất mát từ từ tiến sát về đáy của điểm cực tiểu toàn cục.

## 2.3. Đánh giá mô hình từng mô hình học sâu

Sau khi hoàn tất quá trình huấn luyện bằng chiến lược Fine-tuning 2 giai đoạn, các mô hình học sâu (VGG16, ResNet50, DenseNet121, MobileNetV2) được đưa vào đánh giá độc lập trên tập Kiểm tra (Test set). Để có cái nhìn khách quan và toàn diện về hiệu năng trích xuất đặc trưng của từng kiến trúc mạng, nghiên cứu tiến hành phân tích dựa trên các chỉ số phân loại và đồ thị hội tụ.

### 2.3.1. Các chỉ số đánh giá tỷ lệ chính xác

Đối với bài toán phân loại cảnh quan tự nhiên đa lớp (Multi-class Classification) có sự tương đồng cao về hình học giữa các lớp, việc chỉ sử dụng một thước đo duy nhất là không đủ. Do đó, hệ thống sử dụng kết hợp 4 chỉ số thống kê cơ bản để nghiệm thu tỷ lệ chính xác của các mô hình:

- Độ chính xác tổng thể (Accuracy): Đo lường tỷ lệ các mẫu ảnh được mô hình dự đoán đúng danh mục trên tổng số toàn bộ hình ảnh.

- Độ chuẩn xác (Precision): Trong số các mẫu mà mô hình dự đoán là thuộc một lớp cụ thể, tỷ lệ thực sự thuộc lớp đó là bao nhiêu phần trăm.

- Độ bao phủ (Recall): Trong số các mẫu thực tế thuộc một lớp cụ thể, mô hình đã nhận diện đúng được bao nhiêu phần trăm.

- Điểm F1 (F1-Score): Là trung bình điều hòa (Harmonic Mean) giữa Precision và Recall. Chỉ số này đặc biệt quan trọng để đánh giá sự cân bằng và hiệu năng thực sự của mô hình phân lớp.

Kết quả trích xuất các chỉ số đánh giá độ chính xác của cả 4 mô hình sau khi kết thúc 2 giai đoạn huấn luyện được tổng hợp chi tiết trong Bảng 2.1 dưới đây:

*Bảng 2.1. Tổng hợp các chỉ số đánh giá độ chính xác của 4 mô hình học sâu*

|  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- |
| **STT** | **Kiến trúc mô hình** | **Accuracy (%)** | **Precision (%)** | **Recall (%)** | **F1 – Score (%)** |
| 1 | VGG16 | 90.97 | 90.97 | 90.97 | 90.97 |
| 2 | ResNet50 | 91.33 | 91.33 | 91.33 | 91.33 |
| 3 | DenseNet121 | 90.30 | 90.30 | 90.30 | 90.30 |
| 4 | MobileNetV2 | 89.77 | 89.77 | 89.77 | 89.77 |

Dựa vào Bảng 2.1, có thể thấy toàn bộ 4 kiến trúc mạng Nơ-ron Tích chập (CNN) đều đạt được tỷ lệ chính xác (Accuracy) và F1-Score ở mức rất khả quan (từ 90% đến 91%), chứng minh sự thành công của chiến lược áp dụng Học chuyển giao (Transfer Learning). Mặc dù có sự khác biệt về độ sâu cấu trúc và cơ chế truyền đạo hàm (như Kết nối tắt của ResNet hay Ghép nối dày đặc của DenseNet), các mô hình đều thể hiện năng lực vượt trội trong việc phân tách các đặc trưng thị giác phức tạp của cảnh quan ngoài trời.

### 2.3.2. Đồ thị biểu diễn độ chính xác và hàm mất mát

Để quan sát trực quan hành vi học tập và đánh giá trạng thái hội tụ của các mạng nơ-ron qua từng chu kỳ huấn luyện (Epoch), nghiên cứu tiến hành trích xuất đồ thị biểu diễn Độ chính xác (Accuracy) và Hàm mất mát (Loss) tách biệt cho từng kiến trúc. Trên mỗi đồ thị, đường ranh giới đứt nét màu đỏ được sử dụng để đánh dấu mốc chuyển giao giữa hai giai đoạn: Khởi động (Warm-up) và Tinh chỉnh sâu (Fine-tuning).

**a) Đồ thị hội tụ của kiến trúc VGG16**

![](data:image/png;base64...)

*Hình 2.1. Đồ thị biểu diễn chính xác và hàm mất mát của mô hình VGG16*

Quan sát đồ thị VGG16, ở Giai đoạn 1 (trước đường nét đứt), khi khối trích xuất đặc trưng bị đóng băng, độ chính xác của tập dữ liệu huấn luyện (Train Accuracy) tăng trưởng dốc từ khoảng 74% lên trên 85%. Đáng chú ý, đường Validation Accuracy bám đuổi sát sao và nhanh chóng đạt ngưỡng 88%. Bước sang Giai đoạn 2 (Start Fine-tuning), khi hệ thống mở khóa 50% số tầng mạng và giảm tốc độ học xuống $10^{-5}$ , mô hình có sức bật mới. Độ chính xác tiếp tục đà tăng và tiệm cận ổn định ở mức trên 91%. Trên đồ thị hàm mất mát, đường Validation Loss dao động cực kỳ trơn tru quanh ngưỡng 0.4 và tuyệt đối không xuất hiện hiện tượng chĩa ngược lên trên (spike). Khoảng cách (gap) rất hẹp giữa hai đường Train và Validation, kết hợp với việc hệ thống tự động ngắt ở Epoch 17 chứng tỏ cơ chế Dừng sớm (Early Stopping) cùng lớp Dropout (0.2) đã hoạt động hoàn hảo, giúp mô hình khử bỏ hoàn toàn hiện tượng quá khớp.

**b) Đồ thị hội tụ của kiến trúc ResNet50**

![](data:image/png;base64...)

*Hình 2.2. Đồ thị biểu diễn chính xác và hàm mất mát của mô hình ResNet50*

Với thế mạnh của cơ chế kết nối tắt (Skip Connection) giúp luồng đạo hàm không bị triệt tiêu, đồ thị ResNet50 cho thấy tốc độ giảm hàm mất mát ở những Epoch đầu tiên diễn ra cực kỳ mạnh mẽ (từ mức >0.9 xuống chỉ còn khoảng 0.5). Tại mốc bắt đầu Fine-tuning (đường nét đứt màu đỏ), hệ thống tiếp tục vi chỉnh các trọng số, giúp độ chính xác Validation có bước nhảy vọt và bám sát đường Train ở mức rất cao (>91%). Hàm mất mát trên tập kiểm định duy trì trạng thái "đáy phẳng" quanh mức 0.35 đến 0.4. Việc đồ thị kết thúc sớm ở khoảng Epoch 17 minh chứng cho việc kiến trúc mạng sâu 50 lớp này đã nhanh chóng hội tụ về điểm cực tiểu toàn cục với bộ trọng số tối ưu nhất mà không cần tiêu tốn tài nguyên chạy hết toàn bộ số chu kỳ thiết lập ban đầu.

**c) Đồ thị hội tụ của kiến trúc DenseNet121**

**![](data:image/png;base64...)**

*Hình 2.3. Đồ thị biểu diễn chính xác và hàm mất mát của mô hình DenseNet121*

Nhờ cơ chế tái sử dụng đặc trưng một cách dày đặc (Dense Connectivity), DenseNet121 thể hiện một hành vi hội tụ rất đặc thù và bền vững. Trong Giai đoạn 1, đường Validation Loss có đôi chút dao động nhẹ. Tuy nhiên, ngay khi bước vào Giai đoạn Tinh chỉnh sâu (sau đường nét đứt đỏ), hàm mất mát lập tức hội tụ phẳng và mượt mà đi ngang quanh mức 0.35. Cùng lúc đó, độ chính xác duy trì ổn định ở mức ~90%. Khoảng cách hội tụ chặt chẽ này chứng tỏ hệ thống đã học được các đặc trưng quang học phức tạp của 6 lớp cảnh quan mà không bị nhạy cảm với nhiễu dữ liệu.

**d) Đồ thị hội tụ của kiến trúc MobileNetV2**

**![](data:image/png;base64...)**

*Hình 2.4. Đồ thị biểu diễn chính xác và hàm mất mát của mô hình MobileNetV2*

Là một mạng được thiết kế theo cấu trúc Tích chập tách khối (Depthwise Separable Convolution) tối ưu hóa cho di động với lượng tham số nhỏ gọn, MobileNetV2 có khởi điểm học chậm hơn đôi chút so với các mạng lớn. Tuy nhiên, đường Validation Accuracy lại vô cùng ổn định và ôm sát đường Train Accuracy ngay từ những Epoch đầu tiên. Quá trình Fine-tuning đóng vai trò then chốt giúp mạng vi chỉnh cực kỳ tinh tế, tiếp tục thu hẹp khoảng cách sai lệch và chốt hạ độ chính xác ở mức xấp xỉ 90% tại Epoch 19. Đồ thị Loss giảm đều và không có dấu hiệu bùng nổ, khẳng định tính hiệu quả tuyệt đối của chiến lược huấn luyện trên các cấu trúc mạng siêu nhẹ.

Thông qua việc phân tích chi tiết 4 bộ đồ thị, có thể đưa ra kết luận: Chiến thuật thiết lập quy trình huấn luyện hai giai đoạn (đóng băng Backbone kết hợp mở khóa 50% lớp sâu) là hoàn toàn đúng đắn. Việc ứng dụng đồng bộ các kỹ thuật Tăng cường dữ liệu (Data Augmentation) trên GPU, hàm phạt L2 Regularization (0.001) và lớp Dropout (0.2) đã bảo vệ hệ thống thành công trước hiện tượng Overfitting, giúp tất cả các mạng học sâu trích xuất được ranh giới quyết định (decision boundary) tổng quát và chính xác nhất.

## 2.4. So sánh và giải thích kết quả của mỗi mô hình

Thông qua các số liệu trích xuất từ quá trình thực nghiệm, nghiên cứu tiến hành phân tích, so sánh đối chiếu và rút ra các đánh giá chuyên sâu về hiệu năng, đặc thù phân loại cũng như giới hạn của từng kiến trúc mạng học sâu. Việc so sánh được triển khai toàn diện trên ba khía cạnh: Các chỉ số phân loại tổng thể, Năng lực phân tách qua Đường cong ROC, và Phân tích nguyên nhân sai số qua Ma trận nhầm lẫn.

## 2.4.1. Đánh giá dựa trên các chỉ số phân loại tổng thể

Quan sát các độ đo đánh giá (Accuracy, Precision, Recall, F1-Score) thu được từ tập kiểm tra (Test set), có thể thấy sự chênh lệch về năng lực trích xuất đặc trưng giữa 4 mô hình là không quá lớn. Kiến trúc **ResNet50** và **VGG16** thể hiện sự áp đảo nhẹ khi đạt đỉnh độ chính xác tổng thể lần lượt ở mức 91.33% và 90.97%. Kết quả này minh chứng cho tính ưu việt của các kiến trúc có mạng lưới sâu (như 16 lớp tích chập của VGG) và đặc biệt là cơ chế kết nối tắt (Skip Connection của ResNet). Nhờ khả năng bảo toàn luồng đạo hàm, ResNet50 có thể trích xuất những biến thiên tinh tế nhất của cảnh quan tự nhiên mà không làm mất đi thông tin gốc.

Trong khi đó, **DenseNet121** và **MobileNetV2** bám sát sít sao với điểm số tương ứng là 90.30% và 89.77%. Mặc dù có độ chính xác thấp hơn khoảng 1%, nhưng đây lại là một thành tựu công nghệ đáng nể của MobileNetV2. Với thiết kế Tích chập tách khối (Depthwise Separable Convolution), mô hình này tiết kiệm được hàng chục lần số lượng tham số tính toán nhưng vẫn duy trì được năng lực phân loại đồng đều cho cả 6 lớp.

## 2.4.2. Đánh giá khả năng phân tách qua Đường cong ROC

Đường cong ROC và chỉ số AUC (Area Under Curve) là một trong những công cụ toán học mạnh mẽ nhất để đo lường năng lực phân tách ranh giới của các mô hình học máy. Đối với bài toán phân lớp đa lớp (Multi-class Classification) với 6 danh mục, nghiên cứu thiết lập đường cong ROC dựa trên chiến lược Một-đối-Phần còn lại (One-vs-Rest). Biểu đồ biểu diễn sự đánh đổi trực tiếp giữa Tỷ lệ dự đoán đúng (True Positive Rate) và Tỷ lệ dự báo sai (False Positive Rate) tại nhiều ngưỡng xác suất (thresholds) khác nhau. Chỉ số AUC càng tiệm cận giá trị tuyệt đối 1.00, mô hình càng chứng tỏ khả năng thiết lập các siêu mặt phẳng (hyperplanes) phân định rạch ròi các lớp dữ liệu mà không bị nhiễu.

**a) Năng lực phân tách của kiến trúc VGG16**

**![](data:image/png;base64...)**

*Hình 2.5. Đường cong ROC của mô hình VGG16*

Phân tích biểu đồ ROC của kiến trúc VGG16 (Hình 2.5), có thể thấy các đường ranh giới của toàn bộ 6 danh mục đều ôm sát tiệm cận vào góc trên cùng bên trái của trục tọa độ. Cụ thể, các danh mục có bối cảnh không gian rộng và đặc trưng quang học mang tính đồng nhất cao như Rừng (Forest) và Biển (Sea) đạt diện tích AUC tuyệt đối 1.00. Các lớp có cấu trúc nhân tạo như Tòa nhà (Buildings) và Đường phố (Street) đạt AUC rất cao ở mức 0.99. Đáng chú ý, với hai lớp có mức độ giao thoa đặc trưng hình học cao nhất là Sông băng (Glacier) và Núi (Mountain), mô hình vẫn duy trì năng lực phân tách cực kỳ xuất sắc với chỉ số AUC đạt 0.98.

Thành tựu phân loại rạch ròi này là minh chứng rõ nét cho triết lý thiết kế của mạng VGG16. Thay vì sử dụng các bộ lọc tích chập (filters) cỡ lớn, sức mạnh cốt lõi của VGG16 nằm ở việc xếp chồng liên tiếp các bộ lọc kích thước nhỏ 3 x 3. Về mặt toán học, cấu trúc này giúp gia tăng đáng kể vùng tiếp nhận (receptive field) của mạng lưới một cách hiệu quả mà không làm bùng nổ số lượng tham số. Khả năng này cho phép hệ thống phân rã hình ảnh thành các cấp độ phân cấp đặc trưng từ thấp đến cao – từ các đường viền, góc cạnh cơ bản của tòa nhà cho đến các kết cấu bề mặt phức tạp của núi đá hay sóng biển, tạo ra các mặt phẳng phân cách sắc bén để cô lập thành công các loại địa hình.

**b) Năng lực phân tách của kiến trúc ResNet50**

![](data:image/png;base64...)

*Hình 2.6. Đường cong ROC của mô hình ResNet50*

Quan sát Hình 2.6, ResNet50 duy trì mức AUC áp đảo, với 3 lớp gồm Rừng (Forest), Biển (Sea) và Đường phố (Street) đều đạt mức hoàn hảo 1.00. Lớp Tòa nhà (Buildings) theo sát với AUC 0.99, trong khi hai lớp khó nhất là Sông băng (Glacier) và Núi (Mountain) tiếp tục được giữ vững ở ngưỡng xuất sắc 0.98.

Sự ổn định toàn diện của các đường cong này là minh chứng toán học đanh thép khẳng định cơ chế Kết nối tắt (Skip Connection) đã phát huy tối đa hiệu năng. Bằng cách cộng trực tiếp đầu vào với đầu ra của khối thặng dư thông qua phương trình *y = F (x) +x*, mạng lưới đã triệt tiêu hoàn toàn vấn đề suy giảm đạo hàm (Vanishing Gradient) thường gặp ở các mạng nơ-ron sâu. Nhờ đó, luồng thông tin chứa bản sắc quang học nguyên thủy của hình ảnh được bảo toàn nguyên vẹn khi truyền qua 50 tầng mạng. Hệ thống không bị đánh mất đi các biến thiên đặc trưng tinh tế nhất, giúp hàm Softmax ở lớp cuối cùng đưa ra phân phối xác suất tự tin và rạch ròi giữa các loại địa lý phức tạp.

**c) Năng lực phân tách của kiến trúc DenseNet121**

**![](data:image/png;base64...)**

*Hình 2.7. Đường cong ROC của mô hình DenseNet121*

Chuyển sang kiến trúc DenseNet121, Hình 2.7 cho thấy mô hình tạo ra các đường cong ROC vô cùng mượt mà và gần như thẳng đứng ở giai đoạn đầu (False Positive Rate cực thấp nhưng True Positive Rate đã tiệm cận 1.0). Tương tự ResNet50, 3 lớp Rừng, Biển và Đường phố đạt AUC 1.00; lớp Tòa nhà đạt 0.99; Sông băng và Núi đạt 0.98.

Sự mượt mà và mức độ chính xác này bắt nguồn từ cơ chế kết nối dày đặc (Dense Connectivity) đặc thù của mạng. Nhờ thao tác ghép nối (Concatenation) bản đồ đặc trưng của mọi lớp trước đó lại với nhau $x\_{l} = H\_{l}([x\_{0,}x\_{1,},...., x\_{l-1}])$, hàm phân loại ở tầng cuối cùng của DenseNet121 được tiếp cận đồng thời cả những đặc trưng cấp thấp (low-level features) lẫn đặc trưng ngữ nghĩa cấp cao (high-level features). Việc "tái sử dụng đặc trưng" ở mức độ tối đa này giúp mạng lưới không bị "quên" các chi tiết nhỏ lẻ, cung cấp cho không gian vector lượng thông tin phong phú nhất để thiết lập ranh giới quyết định.

***d) Năng lực phân tách của kiến trúc MobileNetV2***

**![](data:image/png;base64...)**

*Hình 2.8. Đường cong ROC của mô hình MobileNetV2*

Dù là một mạng được thiết kế tối giản, loại bỏ hàng chục triệu tham số dư thừa để phù hợp với môi trường di động, MobileNetV2 (Hình 2.8) vẫn bám đuổi sát sao các mô hình khổng lồ. Các chỉ số AUC của mô hình này vẫn đạt mức 1.00 đối với Rừng, Biển, Đường phố; 0.99 đối với Tòa nhà và 0.98 đối với Sông băng, Núi.

Khả năng duy trì sức mạnh phân tách ranh giới xuất sắc này là nhờ việc ứng dụng chiến lược Tích chập tách khối (Depthwise Separable Convolution). Phép tính toán học này đã chia nhỏ quá trình tích chập không gian 3D tiêu chuẩn thành hai bước tuần tự: lọc theo chiều sâu (Depthwise) và kết hợp điểm (Pointwise 1 x 1). Thuật toán giúp thu gọn mạnh mẽ khối lượng phép tính từ $D\_{K}^{2} . M . N$ xuống chỉ còn $D\_{K}^{2} . M + M . N$. Tuy nhiên, mức chỉ số AUC tiệm cận tuyệt đối trên biểu đồ thực nghiệm đã chứng minh một chân lý quan trọng trong học sâu: sự tối giản về mặt tham số thuật toán theo cơ chế này hoàn toàn không làm tổn hại đến không gian biểu diễn đặc trưng (feature representation space), giúp hệ thống vẫn tự tin phân loại cảnh quan tự nhiên với độ chính xác vô cùng cạnh tranh.

## 2.4.3. Phân tích nguyên nhân nhầm lẫn qua Ma trận nhầm lẫn

Đường cong ROC cung cấp cái nhìn tổng quan về năng lực phân tách, nhưng để đi sâu "mổ xẻ" các điểm mù đặc trưng còn tồn tại và giải thích bản chất sai số của hệ thống trên từng loại địa hình, nghiên cứu tiến hành đối chiếu trực quan thông qua Ma trận nhầm lẫn (Confusion Matrix). Ma trận này cho phép định lượng chính xác số lượng mẫu True Positive (dự đoán đúng) và sự phân bổ của các mẫu False Positive/False Negative giữa các cặp lớp cụ thể.

**a) Phân bố dự đoán và sai số của kiến trúc VGG16**

![](data:image/png;base64...)

*Hình 2.9. Ma trận nhầm lẫn của mô hình VGG16*

Quan sát đường chéo chính của ma trận (Hình 2.9), VGG16 dự đoán gần như hoàn hảo các lớp có bối cảnh rộng và màu sắc đặc thù như Rừng (nhận diện đúng 466 ảnh) và Biển (nhận diện đúng 498 ảnh). Tuy nhiên, ma trận bộc lộ rõ ranh giới sai số lớn nhất: hệ thống đã dự đoán nhầm 71 bức ảnh sông băng (Glacier) thực tế thành núi (Mountain), và ở chiều ngược lại, chẩn đoán nhầm 66 bức ảnh núi thành sông băng.

Sự nhầm lẫn mang tính đối xứng (symmetrical error) này phản ánh đặc tính của kiến trúc VGG16. Việc xếp chồng các bộ lọc kích thước nhỏ 3 x 3 giúp mạng trích xuất cực tốt các góc cạnh cục bộ (local edges). Tuy nhiên, do thiếu đi cơ chế liên kết thông tin toàn cục ưu việt, hàm Softmax ở tầng cuối cùng gặp khó khăn trong việc phân biệt kết cấu bề mặt vĩ mô (macro-texture) giữa bề mặt băng tuyết và bề mặt đá phiến, dẫn đến việc phân phối xác suất dự đoán bị chia đều cho cả hai lớp. Bên cạnh đó, hiện tượng nhầm lẫn 42 bức ảnh tòa nhà (Buildings) thành đường phố (Street) cũng bộc lộ hạn chế của VGG16 trong việc bóc tách bối cảnh phụ.

**b) Phân bố dự đoán và sai số của kiến trúc ResNet50**

**![](data:image/png;base64...)**

*Hình 2.10. Ma trận nhầm lẫn của mô hình ResNet50*

Mặc dù sở hữu độ chính xác tổng thể cao nhất, ResNet50 cũng không tránh khỏi khó khăn tại "điểm mù" đặc trưng giữa Mountain và Glacier. Cụ thể, mô hình chẩn đoán sai 61 ảnh sông băng thành núi và 70 ảnh núi thành sông băng. Đối với các lớp khác, ResNet50 thể hiện sự vượt trội khi nhận diện đúng 473 ảnh Rừng và 498 ảnh Biển.

Sự duy trì sai số đối xứng này có thể được lý giải thông qua chính cơ chế Kết nối tắt (Skip Connection) của mạng. Bằng cách cộng trực tiếp đầu vào với đầu ra *(y = F(x) + x),* mạng bảo toàn được toàn bộ luồng thông tin. Tuy nhiên, điều này vô tình giữ lại nguyên vẹn cả những điểm ảnh "gây nhiễu" về mặt quang học (như sắc trắng rực rỡ của tuyết trên đỉnh núi và màu trắng trong suốt của sông băng). Do phổ màu của hai danh mục này quá trùng lặp, việc bảo toàn thông tin màu sắc nguyên thủy đã khiến bộ phân loại cuối cùng không thể thiết lập một siêu mặt phẳng phân cách tuyệt đối, dẫn đến sự bối rối khi đưa ra quyết định.

**c) Phân bố dự đoán và sai số của kiến trúc DenseNet121**

**![](data:image/png;base64...)**

*Hình 2.11. Ma trận nhầm lẫn của mô hình DenseNet121*

Khác biệt hoàn toàn với sự nhầm lẫn đối xứng của VGG16 và ResNet50, cấu trúc DenseNet121 lại tạo ra một xu hướng sai số lệch hẳn về một phía (Bias). Phân tích Hình 2.11 cho thấy, hệ thống nhạy cảm thái quá với đặc trưng của núi, dẫn đến việc dự đoán sai tới 114 ảnh sông băng thành núi, nhưng ở chiều ngược lại chỉ nhầm 38 ảnh núi thành sông băng. Ngoài ra, 47 ảnh đường phố cũng bị nhận diện nhầm thành tòa nhà.

Hiện tượng thiên kiến (bias) này xuất phát từ kiến trúc kết nối dày đặc (Dense Connectivity). Do DenseNet liên tục ghép nối (concatenation) và tái sử dụng các đặc trưng cấp thấp (low-level features) như các đường viền sắc nhọn hoặc ranh giới lởm chởm qua tất cả 121 tầng mạng, mô hình bị "ám ảnh" bởi các góc cạnh này. Vì núi đá tự nhiên thường có cấu trúc góc cạnh cực kỳ mạnh mẽ, nên khi gặp các bức ảnh sông băng có bề mặt gồ ghề, DenseNet121 có xu hướng áp đặt trực tiếp nhãn "Mountain" thay vì phân tích thêm các đặc trưng vĩ mô khác.

**d) Phân bố dự đoán và sai số của kiến trúc MobileNetV2**

**![](data:image/png;base64...)**

*Hình 2.12. Ma trận nhầm lẫn của mô hình MobileNetV2*

Trái ngược với DenseNet121, kiến trúc MobileNetV2 lại thể hiện một xu hướng nhận diện thiên lệch về lớp sông băng (Glacier). Cụ thể, mô hình dự đoán nhầm tới 107 ảnh núi thành sông băng, trong khi chỉ nhầm 46 ảnh sông băng thành núi.

Bản chất của sự nhầm lẫn ngược này nằm ở kỹ thuật Tích chập tách khối (Depthwise Separable Convolution). Để giảm thiểu số lượng tham số, MobileNetV2 đã tách rời việc học đặc trưng không gian (spatial features) và đặc trưng kênh màu (channel features) thành hai bước độc lập. Sự phân tách này vô tình làm mất đi một phần nhỏ các thông tin tương quan không gian chéo giữa các kênh màu (cross-channel spatial relationships). Hậu quả là, mô hình dễ bị đánh lừa bởi màu sắc chủ đạo của bức ảnh hơn là cấu trúc hình học. Khi một bức ảnh núi có diện tích tuyết phủ màu trắng/xanh dương quá lớn, MobileNetV2 sẽ ưu tiên dự đoán đó là "Glacier" dựa trên màu sắc thay vì nhận diện cấu trúc đá bên dưới.

Thông qua việc bóc tách chi tiết 4 ma trận nhầm lẫn, nghiên cứu rút ra kết luận mang tính bản chất về giới hạn của các thuật toán Thị giác máy tính hiện đại: Các mạng Nơ-ron Tích chập (CNN) hoạt động cực kỳ hoàn hảo khi xử lý các không gian có màu sắc và hình khối đặc thù (như mảng xanh lá của Rừng hay khoảng xanh dương đồng nhất của Biển).

Tuy nhiên, hệ thống vấp phải rào cản lớn khi xử lý các cặp danh mục có sự giao thoa mạnh về đặc trưng. Dưới lăng kính của máy tính, lớp Núi (Mountain) và Sông băng (Glacier) chia sẻ sự tương đồng quá lớn về cả quang học và hình học. Cả hai đều sở hữu cấu trúc biên (edges) lởm chởm, hình khối đa giác dốc, và phổ màu chủ đạo hòa lẫn giữa sắc trắng, xám và xanh nhạt. Sự giao thoa về ranh giới điểm ảnh (pixel variance) này đã tạo ra các điểm nhiễu trong không gian vector đa chiều, khiến các mô hình dù có cấu trúc tinh vi đến đâu cũng gặp khó khăn trong việc thiết lập một ranh giới quyết định tuyệt đối. Hiện tượng nhầm lẫn chéo giữa cặp lớp *Buildings* và *Street* cũng tuân theo logic tương tự, do trong điều kiện thực tế, các bức ảnh chụp đường phố luôn bao hàm các khối tòa nhà làm hậu cảnh (background).

# CHƯƠNG 3. KẾT LUẬN

## 3.1. Tóm tắt kết quả đạt được

Sau quá trình nghiên cứu, xây dựng và thực nghiệm trên bộ dữ liệu Intel Image Classification, đề tài đã hoàn thành xuất sắc các mục tiêu đề ra ban đầu. Hệ thống đã triển khai thành công 4 kiến trúc mạng Nơ-ron Tích chập (CNN) hiện đại bao gồm: VGG16, ResNet50, DenseNet121 và MobileNetV2. Việc áp dụng chiến lược Học chuyển giao (Transfer Learning) kết hợp với kỹ thuật tinh chỉnh (Fine-tuning) hai giai đoạn và các phương pháp điều chuẩn đã mang lại hiệu quả rõ rệt. Nhằm cung cấp cái nhìn tổng quan, nghiên cứu tiến hành đối chiếu kết quả dựa trên các khía cạnh sau:

**a) Đánh giá tốc độ hội tụ của các mô hình**

**![](data:image/png;base64...)**

*Hình 3.1. So sánh tốc độ hội tụ của 4 kiến trúc*

Dựa vào Hình 3.1, có thể thấy toàn bộ 4 kiến trúc đều hội tụ thành công về điểm cực tiểu mà không gặp phải hiện tượng quá khớp (Overfitting). Sự bám đuổi sát sao và dao động ổn định của các đường Validation Accuracy trong giai đoạn Fine-tuning chứng tỏ các kỹ thuật như Dropout (0.2) và Data Augmentation trên GPU đã phát huy tối đa tác dụng, giúp mô hình học được các đặc trưng mang tính tổng quát cao.

**b) So sánh hiệu năng phân loại tổng thể**

**![](data:image/png;base64...)**

*Hình 3.2. So sánh tổng hợp 4 độ đo*

Phân tích Hình 3.2 cho thấy, cả 4 mô hình đều chứng tỏ năng lực trích xuất đặc trưng xuất sắc với độ chính xác xấp xỉ 90% trở lên. Dẫn đầu là kiến trúc ResNet50 với đỉnh độ chính xác đạt 91.33%, bám sát theo sau là VGG16 (90.97%), DenseNet121 (90.30%) và MobileNetV2 (89.77%). Các chỉ số F1-Score, Precision và Recall của từng mạng đều thể hiện sự đồng đều, chứng minh các ranh giới quyết định (decision boundaries) được thiết lập một cách vững chắc và tin cậy.

**c) So sánh tốc độ xử lý thực tế (Inference Time)**

**![](data:image/png;base64...)**

*Hình 3.3. So sánh thời gian phân lớp trên 1 ảnh (ms)*

Về mặt thời gian suy luận (Hình 3.3), **MobileNetV2** đã chứng tỏ sự vượt trội tuyệt đối về tối ưu hóa tính toán. Nhờ kiến trúc Tích chập tách khối (Depthwise Separable Convolution), mô hình này sở hữu tốc độ nhận diện cực nhanh, chỉ mất **5.56 ms** để xử lý một bức ảnh, nhanh gấp đôi so với DenseNet121 (11.91 ms) và vượt xa các kiến trúc cồng kềnh khác.

**d) Sự đánh đổi giữa hiệu năng và kích thước (Trade-off)**

**![](data:image/png;base64...)**

*Hình 3.4. Sự đánh đổi giữa kích thước mô hình và độ chính xác*

Cuối cùng, biểu đồ bong bóng (Hình 3.4) phản ánh rõ nét tính thực tiễn của từng mạng. Mặc dù ResNet50 có độ chính xác cao nhất (91.33%) nhưng kích thước lại vô cùng đồ sộ với hàng chục triệu tham số. Ngược lại, MobileNetV2 (góc trái dưới) cho thấy một sự đánh đổi hoàn hảo: dù kích thước siêu nhẹ (vài triệu tham số), mô hình vẫn bám sát ngưỡng chính xác 90%. Điều này biến MobileNetV2 trở thành lựa chọn thực tiễn và lý tưởng nhất để triển khai trên các thiết bị di động có cấu hình giới hạn.

## 3.2. Hạn chế của đề tài

Bên cạnh những kết quả tích cực đã đạt được, quá trình đánh giá chuyên sâu cũng chỉ ra một số điểm giới hạn mang tính bản chất của phương pháp cũng như của bộ dữ liệu hiện tại:

- Mặc dù mạng CNN rất xuất sắc trong việc nắm bắt các đặc trưng cục bộ (local features) thông qua cửa sổ trượt (sliding window), nhưng chúng lại thiếu đi khả năng liên kết thông tin ngữ cảnh toàn cục (global context) một cách linh hoạt. Đây là nguyên nhân sâu xa khiến cả 4 mô hình đều gặp khó khăn và xảy ra nhầm lẫn có tính hệ thống khi phân biệt Núi (Mountain) và Sông băng (Glacier).

**-** Bộ dữ liệu Intel Image Classification tuy cân bằng và có chất lượng cao, nhưng hầu hết các bức ảnh đều được thu thập trong điều kiện ánh sáng tốt và góc chụp lý tưởng. Do đó, mô hình chưa được tiếp xúc với các điều kiện nhiễu của môi trường thực tế (như sương mù dày đặc, bão tuyết, chụp ngược sáng, hoặc ảnh bị che khuất).

**-** Việc tinh chỉnh (Fine-tuning) các mô hình học sâu cỡ lớn đòi hỏi tài nguyên GPU rất lớn. Do những giới hạn về mặt phần cứng và thời gian, nghiên cứu chưa thể triển khai các phương pháp tìm kiếm siêu tham số diện rộng (Grid/Random Search) để tối ưu hóa triệt để tốc độ học (Learning Rate) hay các hệ số phạt L2.

## 3.3. Định hướng mở rộng

Nhằm khắc phục các hạn chế nêu trên, nâng cấp chất lượng dự báo và hướng tới việc ứng dụng thực tiễn, nhóm nghiên cứu đề xuất các phương hướng phát triển trong tương lai như sau:

- Thay vì chỉ phụ thuộc vào CNN truyền thống, bước đi tiếp theo là ứng dụng các kiến trúc mạng hiện đại hơn như Vision Transformer (ViT). Với cơ chế tự chú ý (Self-Attention), ViT có khả năng nắm bắt xuất sắc mối quan hệ ngữ cảnh toàn cục, hứa hẹn sẽ giải quyết triệt để ranh giới nhầm lẫn giữa các lớp có hình học tương đồng.

- Áp dụng các kỹ thuật tăng cường dữ liệu tiên tiến hơn như MixUp, CutOut, hoặc chủ động thêm nhiễu (noise) nhân tạo vào tập huấn luyện. Đồng thời, cần thu thập thêm các bức ảnh cảnh quan đặc thù tại môi trường Việt Nam để tăng cường sức chịu đựng (robustness) của hệ thống.

- Hướng tới việc tối ưu hóa định dạng trọng số của mô hình MobileNetV2 (chuyển đổi sang TensorFlow Lite hoặc ONNX). Đóng gói mô hình thành một giao diện lập trình ứng dụng (API) để tích hợp trực tiếp lên các hệ thống nhúng (Embedded systems) hoặc ứng dụng di động (Mobile App), cung cấp khả năng phân loại cảnh quan theo thời gian thực.

**Tài liệu tham khảo**

[1] Kho dữ liệu Kaggle, *Intel Image Classification Dataset*. Truy cập tại đường dẫn: https://www.kaggle.com/datasets/puneet6060/intel-image-classification.

[2] Simonyan, K., & Zisserman, A. (2014). *Very Deep Convolutional Networks for Large-Scale Image Recognition*. arXiv preprint arXiv:1409.1556.

[3] He, K., Zhang, X., Ren, S., & Sun, J. (2016). *Deep Residual Learning for Image Recognition*. Proceedings of the IEEE conference on computer vision and pattern recognition (CVPR).