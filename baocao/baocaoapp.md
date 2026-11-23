TRƯỜNG ĐẠI HỌC VINH
VIỆN KỸ THUẬT VÀ CÔNG NGHỆ
ĐỒ ÁN HỌC PHẦN
PHÁT TRIỂN ỨNG DỤNG CHO THIẾT BỊ DI ĐỘNG
XÂY DỰNG ỨNG DỤNG
ĐẶT VÉ XEM PHIM TRỰC TUYẾN
NHÓM: 3
GVHD: ThS. Lê Quốc Anh
SVTH: 1. Nguyễn Thị Ngọc Hà – 225748020110364 – SBD: 224
2. Trần Ngọc Hải – 225748020110069 – SBD: 98
3. Phan Thị Giang – 225748020110277 – SBD: 69
4. Hà Văn Hiệp – 225748020110228 – SBD: 72
Nghệ An, 06/2026

BẢNG ĐÁNH GIÁ CÔNG VIỆC
STT Tên sinh viên Công việc Đánh giá
Chương 1:
1.3. Hình thành ý tưởng thiết kế phần mềm
Chương 2:
Nguyễn Thị 2.2. Tổng quan các chức năng của hệ thống
1 100%
Ngọc Hà 2.3. Thiết kế cơ sở dữ liệu
Chương 3:
3.2. Xây dựng phần mềm
- Xây dựng chương trình, vẽ biểu đồ
Chương 1:
1.2. Khảo sát nghiệp vụ
Chương 2:
2 Trần Ngọc Hải 100%
2.2. Tổng quan các chức năng của hệ thống
2.3. Thiết kế cơ sở dữ liệu
- Xây dựng chương trình
Chương 1:
1.2. Khảo sát nghiệp vụ
3 Phan Thị Giang Chương 2: 95%
2.2. Tổng quan các chức năng của hệ thống
- Vẽ hình, làm slide, xây dựng chương trình
1

Chương 1:
1.1. Bài toán xây dựng ứng dụng đặt vé xem
phim
Chương 2:
4 Hà Văn Hiệp 90%
2.1. Phân tích hệ thống đặt vé xem phim
Chương 3:
3.1. Môi trường phát triển
- Xây dựng chương trình
2

MỞ ĐẦU
Trong những năm gần đây, cùng với sự phát triển mạnh mẽ của công nghệ thông
tin và Internet, các hoạt động kinh doanh và dịch vụ trực tuyến ngày càng trở nên phổ
biến. Đặc biệt, trong lĩnh vực giải trí, nhu cầu xem phim tại các rạp chiếu phim hiện đại
không ngừng gia tăng. Tuy nhiên, việc mua vé theo phương thức truyền thống thường
gây ra nhiều bất tiện như phải đến trực tiếp rạp, mất thời gian chờ đợi và khó khăn trong
việc lựa chọn suất chiếu hoặc vị trí ghế ngồi phù hợp.
Nhằm đáp ứng nhu cầu của người dùng và nâng cao hiệu quả quản lý cho các rạp
chiếu phim, việc xây dựng một hệ thống đặt vé xem phim trực tuyến là giải pháp cần
thiết. Thông qua hệ thống này, khách hàng có thể dễ dàng tra cứu thông tin phim, lịch
chiếu, lựa chọn ghế ngồi và thực hiện đặt vé mọi lúc, mọi nơi chỉ với thiết bị có kết nối
Internet. Đồng thời, hệ thống cũng hỗ trợ nhà quản lý trong việc quản lý phim, phòng
chiếu, suất chiếu, vé và doanh thu một cách thuận tiện và hiệu quả.
Xuất phát từ những nhu cầu thực tiễn đó, nhóm đã lựa chọn đề tài “Xây dựng ứng
dụng đặt vé xem phim trực tuyến” nhằm nghiên cứu, phân tích và phát triển một hệ
thống hỗ trợ đặt vé hiện đại, thân thiện với người dùng và đáp ứng các yêu cầu cơ bản
trong công tác quản lý rạp chiếu phim. Đề tài không chỉ góp phần vận dụng các kiến
thức đã học về phân tích, thiết kế và phát triển phần mềm mà còn mang ý nghĩa thực
tiễn trong việc ứng dụng công nghệ vào lĩnh vực dịch vụ giải trí hiện nay.
3

LỜI CẢM ƠN
Lời đầu tiên, chúng em không biết nói gì hơn ngoài sự biết ơn sâu sắc đến
các thầy cô. Trong suốt quá trình học tập và làm đồ án đã luôn nhận được sự
hướng dẫn, giúp đỡ tận tình của các thầy cô.
Đặc biệt, chúng em xin bày tỏ sự kính trọng và lòng biết ơn sâu sắc nhất đến
thầy giáo hướng dẫn ThS. Lê Quốc Anh, thầy là người đã trực tiếp hướng dẫn,
giúp đỡ cho chúng em để chúng em có thể hoàn thành đồ án này. Trong quá trình
học tập và nghiên cứu, nếu chúng em có những sai sót gì, kính mong thầy cô bỏ
qua cho chúng em!
Chúng em xin kính chúc thầy cô luôn khỏe mạnh và ngày một thành công
trên con đường giảng dạy của mình.
Chúng em xin chân thành cảm ơn!
4

DANH MỤC HÌNH ẢNH
Hình 1.1. Ứng dụng CGV Cinema ...................................................................... 13
Hình 1.2. Ứng dụng Lotte Cinema...................................................................... 14
Hình 2.1. Biểu đồ ca sử dụng của hệ thống ........................................................ 15
Hình 2.2. Biểu đồ tuần tự chức năng đăng ký .................................................... 16
Hình 2.3. Biểu đồ tuần tự chức năng đăng nhập ................................................. 17
Hình 2.4. Biểu đồ tuần tự chức năng đăng xuất ................................................. 18
Hình 2.5. Biểu đồ tuần tự chức năng tìm kiếm phim .......................................... 19
Hình 2.6. Biểu đồ tuần tự chức năng đặt vé ........................................................ 20
Hình 2.7. Biều đồ tuần tự chức năng thanh toán ................................................ 21
Hình 2.8. Biểu đồ tuần tự chức năng quản lý người dùng .................................. 22
Hình 2.9. Biểu đồ tuần tự chức năng quản lý phim ............................................ 23
Hình 2.10. Biểu đồ tuần tự chức năng quản lý lịch chiếu ................................... 24
Hình 2.11. Biểu đồ tuần tự chức năng quản lý ghế ngồi .................................... 25
Hình 2.12. Biểu đồ phân lớp ............................................................................... 26
Hình 3.1. Giao diện trang đăng ký, đăng nhập ................................................... 35
Hình 3.2. Giao diện trang chủ ............................................................................. 35
Hình 3.3. Giao diện trang thông tin phim ........................................................... 36
Hình 3.4. Giao diện trang đặt vé ......................................................................... 37
Hình 3.5. Giao diện trang đặt vé ......................................................................... 38
Hình 3.6. Giao diện trang tin tức ........................................................................ 38
Hình 3.7. Giao diện trang quản trị, trang quản lý người dùng ............................ 39
Hình 3.8. Giao diện trang quản lý phim ............................................................. 40
Hình 3.9. Giao diện trang quản lý suất chiếu ...................................................... 41
Hình 3.10. Giao diện trang quản lý suất chiếu .................................................... 41
Hình 3.11. Giao diện trang quản lý rạp ............................................................... 42
5

DANH MỤC CÁC BẢNG
Bảng 1.1. Yêu cầu chức năng của hệ thống đặt vé xem phim ............................ 12
Bảng 2.1. Mô tả chi tiết chức năng đăng ký ....................................................... 16
Bảng 2.2. Mô tả chi tiết chức năng đăng nhập ................................................... 17
Bảng 2.3. Mô tả chi tiết chức năng đăng xuất .................................................... 18
Bảng 2.4. Mô tả chi tiết chức năng tìm kiếm phim ............................................ 19
Bảng 2.5. Mô tả chi tiết chức năng đặt vé .......................................................... 20
Bảng 2.6. Mô tả chi tiết chức năng thanh toán ................................................... 21
Bảng 2.7. Mô tả chi tiết chức năng quản lý người dùng ..................................... 22
Bảng 2.8. Mô tả chi tiết chức năng quản lý phim ............................................... 23
Bảng 2.9. Mô tả chi tiết chức năng quản lý lịch chiếu ....................................... 24
Bảng 2.10. Mô tả chi tiết chức năng quản lý ghế ngồi ....................................... 25
Bảng 2.11. Bảng cơ sở dữ liệu banners ............................................................... 27
Bảng 2.12. Bảng thông tin đặt vé ........................................................................ 28
Bảng 2.13. Thông tin rạp chiếu phim ................................................................. 28
Bảng 2.14. Thông tin combo ............................................................................... 29
Bảng 2.15. Thông tin địa điểm ............................................................................ 29
Bảng 2.16. Thông tin phim ................................................................................. 30
Bảng 2.17. Bảng tin tức ...................................................................................... 30
Bảng 2.18. Bảng thông tin sản phẩm .................................................................. 31
Bảng 2.19. Bảng thông tin phòng chiếu .............................................................. 31
Bảng 2.20. Bảng thông tin lịch chiếu .................................................................. 32
Bảng 2.21. Bảng thông tin người dùng ............................................................... 32
6

MỤC LỤC
MỞ ĐẦU .............................................................................................................. 3
LỜI CẢM ƠN ...................................................................................................... 4
DANH MỤC HÌNH ẢNH ................................................................................... 5
DANH MỤC CÁC BẢNG .................................................................................. 6
CHƯƠNG 1: GIỚI THIỆU BÀI TOÁN ĐẶT VÉ XEM PHIM ..................... 8
1.1. Bài toán xây dựng ứng dụng đặt vé xem phim ........................................... 8
1.2. Khảo sát nghiệp vụ ...................................................................................... 9
1.3. Hình thành ý tưởng thiết kế phần mềm .................................................... 10
CHƯƠNG 2. PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG ĐẶT VÉ XEM
PHIM .................................................................................................................. 15
2.1. Phân tích hệ thống đặt vé xem phim ......................................................... 15
2.2. Tổng quan các chức năng của hệ thống .................................................... 16
2.3. Thiết kế cơ sở dữ liệu ................................................................................ 26
CHƯƠNG 3. TRIỂN KHAI HỆ THỐNG ĐẶT VÉ XEM PHIM ................ 33
3.1. Môi trường phát triển ................................................................................ 33
3.2. Xây dựng phần mềm ................................................................................. 34
KẾT LUẬN ........................................................................................................ 43
1. Kết quả đạt được .......................................................................................... 43
2. Hạn chế ........................................................................................................ 43
3. Hướng phát triển .......................................................................................... 44
TÀI LIỆU THAM KHẢO ................................................................................ 45
7

CHƯƠNG 1: GIỚI THIỆU BÀI TOÁN ĐẶT VÉ XEM PHIM
1.1. Bài toán xây dựng ứng dụng đặt vé xem phim
Trong thời đại công nghệ số, nhu cầu sử dụng các dịch vụ trực tuyến ngày
càng tăng, đặc biệt trong lĩnh vực giải trí. Việc mua vé xem phim trực tiếp tại rạp
thường mất nhiều thời gian và gây bất tiện cho khách hàng. Vì vậy, ứng dụng đặt
vé xem phim trực tuyến được xây dựng nhằm giúp người dùng dễ dàng tra cứu
thông tin phim, lịch chiếu, lựa chọn ghế ngồi và thanh toán nhanh chóng. Đây là
giải pháp góp phần nâng cao trải nghiệm khách hàng và hỗ trợ hiệu quả công tác
quản lý của rạp chiếu phim.
Trong quá trình xây dựng ứng dụng đặt vé xem phim, việc thiết kế giao diện
thân thiện và dễ sử dụng là rất quan trọng. Ứng dụng cần hỗ trợ người dùng tìm
kiếm phim, xem lịch chiếu, lựa chọn rạp chiếu và ghế ngồi một cách thuận tiện.
Bên cạnh đó, hệ thống cần tích hợp các phương thức thanh toán trực tuyến an
toàn và hỗ trợ quản lý vé hiệu quả. Đồng thời, các bộ phim cần được sắp xếp và
phân loại hợp lý để người dùng dễ dàng tra cứu và lựa chọn. Hệ thống cũng cần
cung cấp đầy đủ thông tin về phim như nội dung, thời lượng, thể loại và trailer
giới thiệu.
Ngoài ra, việc bổ sung các tính năng như đánh giá phim, nhận xét từ người
xem, gợi ý phim phù hợp và thông báo các chương trình khuyến mãi sẽ giúp tăng
tính tương tác và nâng cao chất lượng dịch vụ. Ứng dụng cũng cần được tối ưu
hóa để hoạt động ổn định trên nhiều nền tảng như Android và iOS, đáp ứng nhu
cầu đa dạng của người sử dụng.
Trong bối cảnh ngành công nghiệp điện ảnh ngày càng phát triển, việc xây
dựng một ứng dụng đặt vé xem phim trực tuyến không chỉ là một bài toán về công
nghệ mà còn là giải pháp giúp nâng cao chất lượng phục vụ khách hàng, tối ưu
hóa công tác quản lý của rạp chiếu phim, gia tăng doanh thu cho doanh nghiệp và
góp phần thúc đẩy quá trình chuyển đổi số trong lĩnh vực giải trí.
8

1.2. Khảo sát nghiệp vụ
1.2.1. Mô hình tổ chức
Ứng dụng đặt vé xem phim được xây dựng nhằm hỗ trợ khách hàng tìm kiếm
thông tin phim và đặt vé trực tuyến một cách nhanh chóng, thuận tiện. Giao diện
trang chủ được thiết kế trực quan, hiển thị danh sách các bộ phim đang chiếu và
sắp chiếu cùng các thông tin cần thiết như thể loại, thời lượng, độ tuổi quy định
và lịch chiếu.
Mỗi bộ phim đều có trang thông tin chi tiết, cung cấp nội dung tóm tắt,
trailer, diễn viên, đạo diễn và các suất chiếu tại từng rạp. Người dùng có thể lựa
chọn rạp chiếu phim, phòng chiếu, suất chiếu và vị trí ghế ngồi phù hợp với nhu
cầu của mình.
Hệ thống cho phép khách hàng đăng ký tài khoản, đăng nhập, đặt vé và thanh
toán trực tuyến thông qua các phương thức thanh toán được tích hợp. Sau khi
thanh toán thành công, thông tin vé sẽ được lưu trong hệ thống và gửi đến khách
hàng để sử dụng khi vào rạp.
Bên cạnh đó, quản trị viên có thể quản lý thông tin phim, lịch chiếu, phòng
chiếu, ghế ngồi, tài khoản người dùng và theo dõi tình trạng đặt vé. Mô hình tổ
chức này giúp nâng cao trải nghiệm khách hàng, đồng thời hỗ trợ rạp chiếu phim
quản lý hoạt động kinh doanh hiệu quả hơn.
1.2.2. Quy trình nghiệp vụ
Các nghiệp vụ cơ bản của ứng dụng đặt vé xem phim:
- Đăng ký và đăng nhập: Người dùng có thể tạo tài khoản bằng cách cung
cấp các thông tin cá nhân như họ tên, email, số điện thoại và mật khẩu. Sau khi
đăng ký, người dùng có thể đăng nhập để sử dụng các chức năng của hệ thống.
- Tìm kiếm và lựa chọn phim: Người dùng có thể tìm kiếm phim theo tên
phim, thể loại hoặc trạng thái đang chiếu hoặc sắp chiếu. Hệ thống hỗ trợ hiển thị
9

danh sách phim cùng các thông tin cơ bản để người dùng dễ dàng lựa chọn.
- Xem thông tin phim: Người dùng có thể xem chi tiết thông tin của từng bộ
phim như nội dung, thể loại, thời lượng, diễn viên, đạo diễn, trailer và lịch chiếu.
- Đặt vé xem phim: Người dùng lựa chọn rạp chiếu phim, suất chiếu, phòng
chiếu và vị trí ghế ngồi mong muốn trước khi xác nhận đặt vé.
- Thanh toán: Hệ thống hỗ trợ thanh toán trực tuyến thông qua các phương
thức như thẻ ngân hàng, ví điện tử hoặc mã QR, giúp quá trình đặt vé diễn ra
nhanh chóng và an toàn.
- Quản lý vé đã đặt: Người dùng có thể xem danh sách vé đã đặt, lịch sử giao
dịch và trạng thái thanh toán. Sau khi thanh toán thành công, thông tin vé sẽ được
lưu trong hệ thống để sử dụng khi đến rạp.
1.3. Hình thành ý tưởng thiết kế phần mềm
1.3.1. Ý tưởng thiết kế
Ứng dụng đặt vé xem phim được xây dựng nhằm đáp ứng nhu cầu đặt vé
trực tuyến của khách hàng và hỗ trợ công tác quản lý rạp chiếu phim một cách
hiệu quả. Hệ thống được thiết kế với các chức năng chính như sau:
1. GIAO DIỆN QUẢN TRỊ
Nội dung yêu cầu Mô tả
Đăng nhập hệ thống Cho phép quản trị viên đăng nhập vào hệ thống.
Quản lý người dùng Cho phép thêm, sửa, xóa và tìm kiếm người dùng.
Quản lý phim Cho phép thêm, sửa, xóa thông tin phim.
Quản lý rạp chiếu Cho phép quản lý thông tin các rạp chiếu phim.
Quản lý phòng chiếu Cho phép quản lý các phòng chiếu thuộc từng rạp.
Quản lý ghế ngồi Cho phép quản lý sơ đồ và trạng thái ghế ngồi.
10

Quản lý lịch chiếu Cho phép tạo và quản lý các suất chiếu phim.
Quản lý đặt vé Cho phép theo dõi và quản lý các vé đã đặt.
Quản lý combo Cho phép quản lý các combo đồ ăn và thức uống.
Quản lý sản phẩm Cho phép quản lý các sản phẩm bán kèm tại rạp.
Quản lý tin tức Cho phép đăng tải và quản lý tin tức.
Quản lý banner - slide Cho phép quản lý banner và slide trên trang chủ.
Quản lý mã giảm giá Cho phép tạo và quản lý các mã khuyến mãi.
Quản lý liên hệ Cho phép xem và xử lý phản hồi từ khách hàng.
Cho phép thống kê doanh thu, vé bán và khách
Thống kê
hàng.
Đăng nhập hệ thống Cho phép quản trị viên đăng nhập vào hệ thống.
Quản lý người dùng Cho phép thêm, sửa, xóa và tìm kiếm người dùng.
2. GIAO DIỆN KHÁCH HÀNG
Nội dung yêu cầu Mô tả
Đăng ký tài khoản Cho phép người dùng tạo tài khoản mới.
Đăng nhập hệ thống Cho phép người dùng đăng nhập vào hệ thống.
Xem phim Cho phép xem danh sách và thông tin phim.
Tìm kiếm phim Cho phép tìm kiếm phim theo tên hoặc thể loại.
Xem lịch chiếu Cho phép xem lịch chiếu theo phim và rạp.
Đặt vé xem phim Cho phép chọn ghế và đặt vé trực tuyến.
Mua combo Cho phép mua combo đi kèm vé xem phim.
Thanh toán Cho phép thanh toán trực tuyến.
Sử dụng mã giảm giá Cho phép áp dụng mã khuyến mãi khi thanh toán.
Xem lịch sử đặt vé Cho phép xem các vé đã đặt trước đó.
11

Cập nhật thông tin cá nhân Cho phép chỉnh sửa thông tin tài khoản.
Xem tin tức Cho phép theo dõi tin tức và khuyến mãi.
Đăng ký tài khoản Cho phép người dùng tạo tài khoản mới.
Bảng 1.1. Yêu cầu chức năng của hệ thống đặt vé xem phim
1.3.2. Các yêu cầu phi chức năng
Yêu cầu phi chức năng trình bày các tiêu chí không trực tiếp liên quan đến
các chức năng cụ thể của hệ thống nhưng đóng vai trò quan trọng trong việc đảm
bảo chất lượng, hiệu quả và khả năng vận hành của ứng dụng đặt vé xem phim.
Cụ thể, hệ thống cần đáp ứng các yêu cầu sau:
- Hệ thống cần có hiệu năng tốt, đảm bảo tốc độ phản hồi nhanh khi người
dùng tra cứu thông tin phim, lịch chiếu, lựa chọn ghế ngồi và thanh toán vé. Các
trang cần được tải trong thời gian ngắn ngay cả khi có nhiều người dùng truy cập
đồng thời.
- Tính bảo mật của hệ thống phải được đảm bảo nhằm bảo vệ thông tin tài
khoản, thông tin cá nhân và dữ liệu giao dịch của khách hàng. Hệ thống cần áp
dụng cơ chế xác thực đăng nhập và phân quyền hợp lý giữa quản trị viên và người
dùng, đảm bảo an toàn và tính riêng tư của dữ liệu.
- Giao diện ứng dụng cần được thiết kế thân thiện, trực quan và dễ sử dụng,
giúp người dùng dễ dàng tìm kiếm phim, lựa chọn suất chiếu và thực hiện các
thao tác đặt.
- Hệ thống phải có khả năng mở rộng để đáp ứng sự gia tăng về số lượng
người dùng, số lượng phim, lịch chiếu và dữ liệu giao dịch mà vẫn đảm bảo hiệu
suất hoạt động ổn định.
- Tính tin cậy và an toàn dữ liệu là yêu cầu quan trọng, hệ thống cần hỗ trợ
sao lưu dữ liệu định kỳ nhằm hạn chế rủi ro mất mát dữ liệu và đảm bảo khả năng
phục hồi khi xảy ra sự cố.
12

- Ứng dụng cần tương thích với nhiều thiết bị và trình duyệt khác nhau, đồng
thời có cấu trúc mã nguồn rõ ràng, dễ bảo trì và nâng cấp để đáp ứng các nhu cầu
phát triển trong tương lai.
1.3.3. Một số ứng dụng liên quan đến đề tài
CGV Cinema là một trong những hệ thống rạp chiếu phim lớn tại Việt Nam,
cung cấp ứng dụng đặt vé trực tuyến trên nền tảng web và thiết bị di động. Ứng
dụng cho phép người dùng tra cứu thông tin phim đang chiếu, phim sắp chiếu,
lịch chiếu theo từng rạp, lựa chọn ghế ngồi và thanh toán trực tuyến. Ngoài ra,
CGV Cinema còn hỗ trợ quản lý tài khoản thành viên, tích điểm thưởng, cập nhật
tin tức điện ảnh và các chương trình khuyến mãi. Giao diện hiện đại cùng quy
trình đặt vé đơn giản giúp người dùng dễ dàng tiếp cận và sử dụng.
Hình 1.1. Ứng dụng CGV Cinema
Lotte Cinema là hệ thống rạp chiếu phim hiện đại với ứng dụng hỗ trợ đặt
vé trực tuyến nhanh chóng và tiện lợi. Ứng dụng cung cấp đầy đủ thông tin về
phim, lịch chiếu, rạp chiếu và các chương trình ưu đãi dành cho khách hàng.
Người dùng có thể lựa chọn suất chiếu, vị trí ghế ngồi, mua combo bắp nước và
thực hiện thanh toán trực tuyến ngay trên ứng dụng. Bên cạnh đó, hệ thống còn
hỗ trợ quản lý tài khoản thành viên, lịch sử giao dịch và các chương trình tích
điểm nhằm nâng cao trải nghiệm người dùng.
13

Hình 1.2. Ứng dụng Lotte Cinema
Qua quá trình khảo sát hai hệ thống trên, nhóm nhận thấy các chức năng như
quản lý phim, lịch chiếu, ghế ngồi, đặt vé, thanh toán trực tuyến, quản lý thành
viên và khuyến mãi là những thành phần quan trọng cần được áp dụng trong quá
trình xây dựng ứng dụng đặt vé xem phim trực tuyến.
14

CHƯƠNG 2. PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG ĐẶT VÉ XEM
PHIM
2.1. Phân tích hệ thống đặt vé xem phim
Hệ thống có hai đối tượng sử dụng chính là Khách hàng và Quản trị viên.
Khách hàng là người sử dụng ứng dụng để tìm kiếm và đặt vé xem phim.
Khách hàng có thể xem thông tin phim, lịch chiếu, lựa chọn rạp chiếu, ghế ngồi,
mua combo bắp nước và thực hiện thanh toán trực tuyến. Ngoài ra, khách hàng
có thể đăng ký tài khoản, đăng nhập, quản lý thông tin cá nhân và xem lịch sử đặt
vé.
Quản trị viên là người quản lý toàn bộ hoạt động của hệ thống. Quản trị
viên có thể quản lý phim, rạp chiếu, phòng chiếu, lịch chiếu, vé đặt, người dùng,
combo, tin tức, banner và các chương trình khuyến mãi. Bên cạnh đó, quản trị
viên còn thực hiện theo dõi doanh thu, thống kê hoạt động và xử lý các phản hồi
từ khách hàng nhằm nâng cao chất lượng dịch vụ.
Hình 2.1. Biểu đồ ca sử dụng của hệ thống
15

2.2. Tổng quan các chức năng của hệ thống
2.2.1. Chức năng đăng ký, đăng nhập, đăng xuất hệ thống
2.2.1.1. Đăng ký
Tên chức năng Đăng ký tài khoản khách hàng
Điều kiện trước Không
1. Chọn nút đăng ký.
Các bước 2. Nhập thông tin đăng ký vào form và bấm nút đăng ký.
thực hiện 3. Hệ thống kiểm tra và ghi thông tin tài khoản vào cơ sở
dữ liệu và tự động đăng nhập thông tin vừa đăng ký.
Các bước Trong bước 2, nếu số hộp thư hoặc mật khẩu bị trống thì
bổ sung hệ thống sẽ thông báo và yêu cầu nhập dữ liệu.
Các ngoại lệ Không
Tham chiếu Không
Bảng 2.1. Mô tả chi tiết chức năng đăng ký
Hình 2.2. Biểu đồ tuần tự chức năng đăng ký
16

2.2.1.2. Đăng nhập
Tên chức năng Đăng nhập tài khoản khách hàng
Điều kiện trước Đã có tài khoản từ trước
1. Chọn nút đăng nhập.
2. Nhập thông tin tài khoản và mật khẩu vào biểu mẫu và
Các bước chọn nút đăng nhập.
thực hiện 3. Hệ thống kiểm tra thông tin nếu trùng khớp với thông
tin trong cơ sở dữ liệu thì thông báo đăng nhập thành
công và chuyển đến giao diện trang chủ.
Các bước bổ Trong bước 2, nếu tài khoản hoặc mật khẩu bị trống thì
sung hệ thống sẽ thông báo và yêu cầu nhập dữ liệu.
Nếu thông tin đăng nhập không chính xác hoặc tài khoản
Các ngoại lệ
có vấn đề thì hệ thống sẽ thông báo cho khách hàng biết.
Bảng 2.2. Mô tả chi tiết chức năng đăng nhập
Hình 2.3. Biểu đồ tuần tự chức năng đăng nhập
17

2.2.1.3. Đăng xuất
Tên chức năng Đăng xuất khỏi hệ thống
Điều kiện trước Đã đăng nhập vào hệ thống
1. Chọn đăng xuất
Các bước thực hiện 2. Sau khi đăng xuất, hệ thống sẽ hủy phiên làm việc và
chuyển người dùng về trang chủ.
Bảng 2.3. Mô tả chi tiết chức năng đăng xuất
Hình 2.4. Biểu đồ tuần tự chức năng đăng xuất
2.2.2. Chức năng dành cho khách hàng
Trong phạm vi của báo cáo, nội dung dưới đây sẽ tập trung đặc tả chi tiết
các ca sử dụng (Use Case) cốt lõi, có độ phức tạp cao và đóng vai trò quyết định
trong luồng nghiệp vụ của khách hàng. Các chức năng quản lý cơ bản khác sẽ
được lược bớt để đảm bảo tính súc tích cho báo cáo, đồng thời vẫn đảm bảo tính
đầy đủ của hệ thống.
18

2.2.2.1. Tìm kiếm phim
Tên chức năng Tìm kiếm phim và lịch chiếu
Điều kiện trước Không
1. Khách hàng chọn xem danh sách phim theo danh mục
(Phim đang chiếu, Sắp chiếu).
Các bước thực
2. Khách hàng nhập tên phim vào ô tìm kiếm.
hiện
3. Hệ thống hiển thị danh sách các phim phù hợp với từ
khóa.
Khách hàng có thể sử dụng bộ lọc để tìm phim theo thể
Các bước bổ sung
loại hoặc rạp chiếu.
Nếu không có phim nào khớp với tên tìm kiếm, hệ thống
Các ngoại lệ
hiển thị "Không tìm thấy kết quả phù hợp".
Bảng 2.4. Mô tả chi tiết chức năng tìm kiếm phim
Hình 2.5. Biểu đồ tuần tự chức năng tìm kiếm phim
19

2.2.2.2. Đặt vé xem phim
Tên chức năng Đặt vé xem phim
Điều kiện trước Đã đăng nhập vào hệ thống
1. Khách hàng chọn phim, chọn rạp, chọn ngày và suất
chiếu, sau đó bấm "Đặt vé".
Các bước thực 2. Khách hàng lựa chọn ghế ngồi trên sơ đồ phòng chiếu và
hiện chọn mua combo bắp nước nếu muốn.
3. Hệ thống tạm giữ ghế và chuyển sang màn hình thanh
toán.
Các bước bổ Nếu khách hàng chưa đăng nhập thì hệ thống sẽ chuyển
sung hướng và yêu cầu đăng nhập/đăng ký để tiếp tục.
Nếu khách hàng chọn quá thời gian quy định là 8 phút chưa
Các ngoại lệ
hoàn tất, hệ thống sẽ hủy giữ ghế và yêu cầu chọn lại.
Bảng 2.5. Mô tả chi tiết chức năng đặt vé
Hình 2.6. Biểu đồ tuần tự chức năng đặt vé
20

2.2.2.3. Thanh toán
Tên chức năng Thanh toán trực tuyến
Điều kiện trước Đã đăng nhập và đã chốt ghế ngồi, suất chiếu
1. Khách hàng chọn phương thức thanhh toán
2. Xác nhận thông tin đơn hàng, số tiền và thực hiện thanh
Các bước thực
toán.
hiện
3. Hệ thống ghi nhận thanh toán và tạo vé điện tử, thông
báo đặt vé thành công.
Các bước bổ sung Hệ thống gửi vé điện tử về email của khách hàng.
Các ngoại lệ Thanh toán thất bại hệ thống sẽ báo lỗi.
Tham chiếu Không
Bảng 2.6. Mô tả chi tiết chức năng thanh toán
Hình 2.7. Biều đồ tuần tự chức năng thanh toán
21

2.2.3. Chức năng dành cho quản trị viên
2.2.3.1. Quản lý người dùng
Tên chức năng Quản lý người dùng
Điều kiện trước Đã đăng nhập vào hệ thống với quyền quản trị viên.
Các bước thực 1. Chọn chức năng Quản lý người dùng.
hiện
2. Hệ thống hiển thị danh sách người dùng.
3. Quản trị viên tìm kiếm hoặc xem thông tin người dùng.
4. Thực hiện khóa hoặc mở khóa tài khoản khi cần thiết.
5. Hệ thống cập nhật dữ liệu và thông báo kết quả.
Các bước bổ Nếu tài khoản không tồn tại hoặc dữ liệu không hợp lệ, hệ
sung thống sẽ hiển thị thông báo lỗi.
Bảng 2.7. Mô tả chi tiết chức năng quản lý người dùng
Hình 2.8. Biểu đồ tuần tự chức năng quản lý người dùng
22

2.2.3.2. Quản lý phim
Tên chức năng Quản lý phim
Điều kiện trước Đã đăng nhập vào hệ thống với quyền quản trị viên.
Các bước thực 1. Chọn chức năng Quản lý phim.
hiện
2. Chọn thêm, sửa hoặc xóa phim.
3. Nhập hoặc cập nhật thông tin phim.
4. Hệ thống kiểm tra dữ liệu và cập nhật vào cơ sở dữ liệu.
5. Thông báo kết quả cho quản trị viên.
Các bước bổ Nếu dữ liệu không hợp lệ hoặc thiếu thông tin bắt buộc, hệ
sung thống yêu cầu nhập lại.
Bảng 2.8. Mô tả chi tiết chức năng quản lý phim
Hình 2.9. Biểu đồ tuần tự chức năng quản lý phim
23

2.2.3.3. Quản lý lịch chiếu
Tên chức năng Quản lý lịch chiếu
Điều kiện trước Đã đăng nhập vào hệ thống với quyền quản trị viên.
Các bước thực 1. Chọn chức năng Quản lý lịch chiếu.
hiện
2. Chọn thêm, sửa hoặc xóa lịch chiếu.
3. Nhập hoặc cập nhật thông tin lịch chiếu gồm phim, rạp,
phòng chiếu, thời gian chiếu.
4. Hệ thống kiểm tra dữ liệu và cập nhật vào cơ sở dữ liệu.
5. Thông báo kết quả cho quản trị viên.
Các bước bổ Nếu thời gian chiếu bị trùng hoặc dữ liệu không hợp lệ, hệ
sung thống sẽ hiển thị thông báo lỗi và yêu cầu nhập lại.
Bảng 2.9. Mô tả chi tiết chức năng quản lý lịch chiếu
Hình 2.10. Biểu đồ tuần tự chức năng quản lý lịch chiếu
24

2.2.3.4. Quản lý ghế ngồi
Tên chức năng Quản lý ghế ngồi
Điều kiện trước Đã đăng nhập vào hệ thống với quyền quản trị viên.
Các bước thực 1. Chọn chức năng Quản lý ghế ngồi.
hiện
2. Chọn phòng chiếu cần quản lý.
3. Thêm mới, chỉnh sửa hoặc cập nhật trạng thái ghế.
4. Hệ thống kiểm tra dữ liệu và cập nhật vào cơ sở dữ liệu.
5. Thông báo kết quả cho quản trị viên.
Các bước bổ Nếu thông tin ghế không hợp lệ hoặc bị trùng mã ghế, hệ
sung thống sẽ yêu cầu nhập lại.
Bảng 2.10. Mô tả chi tiết chức năng quản lý ghế ngồi
Hình 2.11. Biểu đồ tuần tự chức năng quản lý ghế ngồi
25

2.3. Thiết kế cơ sở dữ liệu
2.3.1. Biểu đồ lớp của bài toán
Hình 2.12. Biểu đồ phân lớp
2.3.2. Cơ sở dữ liệu
Hệ thống sử dụng Firebase Firestore làm cơ sở dữ liệu để lưu trữ và quản lý
thông tin người dùng, phim, lịch chiếu và vé đặt. Firebase Firestore là cơ sở dữ
liệu NoSQL, dữ liệu được tổ chức theo mô hình Collection và Document thay vì
các bảng quan hệ truyền thống.
a) Bảng ảnh trình chiếu
- Tên bảng: banners
26

- Mục đích: Dùng để lưu trữ thông tin ảnh trình chiếu
Ràng  Ghi
| STT  | Diễn giải  |     | Tên trường  | Kiểu  |     |
| ---- | ---------- | --- | ----------- | ----- | --- |
buộc  chú
| 1  Mã banner                        |     |     | id             | String  PK  |     |
| ----------------------------------- | --- | --- | -------------- | ----------- | --- |
| 2  Đường dẫn hình ảnh banner        |     |     | imageUrl       | String      |     |
| 3  Danh sách các khối nội dung      |     |     | contentBlocks  | Array       |     |
| Loại nội dung (title, text, image,  |     |     |                |             |     |
| 4                                   |     |     | type           | String      |     |
bullet, italic)
| 5  Giá trị nội dung hiển thị  |     |     | Value  | String    |     |
| ----------------------------- | --- | --- | ------ | --------- | --- |
Bảng 2.11. Bảng cơ sở dữ liệu banners
b) Bảng đặt vé
- Tên bảng: Bookings
- Mục đích: Dùng để lưu trữ thông tin đặt vé
| STT               | Diễn giải  | Tên trường      | Kiểu    | Ràng buộc  | Ghi chú  |
| ----------------- | ---------- | --------------- | ------- | ---------- | -------- |
| 1  Mã đặt vé      |            | bookingId       | String  | PK         |          |
| 2  Mã người dùng  |            | userId          | String  | FK         |          |
| 3  Mã phim        |            | movieId         | String  | FK         |          |
| 4  Tên phim       |            | mainTitle       | String  |            |          |
| 5  Hình ảnh phim  |            | mainImage       | String  |            |          |
| 6  Mã rạp chiếu   |            | cinemaId        | String  | FK         |          |
| 7  Tên rạp chiếu  |            | cinemaName      | String  |            |          |
| 8  Mã lịch chiếu  |            | showtimeId      | String  | FK         |          |
| 9  Danh sách ghế  |            | seats           | Array   |            |          |
| 10  Tổng tiền vé  |            | seatTotalPrice  | Double  |            |          |
27

| 11  Danh sách combo   |     | combos       |     |     | Array      |     |     |
| --------------------- | --- | ------------ | --- | --- | ---------- | --- | --- |
| 12  Giá combo         |     | comboPrices  |     |     | Array      |     |     |
| 13  Tổng thanh toán   |     | totalPrice   |     |     | Double     |     |     |
| 14  Loại giao dịch    |     | type         |     |     | String     |     |     |
| 15  Thời gian đặt vé  |     | timestamp    |     |     | Timestamp  |     |     |
Bảng 2.12. Bảng thông tin đặt vé
c) Bảng rạp chiếu phim
- Tên bảng: Cinemas
- Mục đích: Dùng để lưu trữ thông tin rạp chiếu phim
| STT               | Diễn giải  |     | Tên trường  |     | Kiểu    | Ràng buộc  | Ghi chú  |
| ----------------- | ---------- | --- | ----------- | --- | ------- | ---------- | -------- |
| 1  Mã rạp chiếu   |            |     | cinemaId    |     | String  | PK         |          |
| 2  Tên rạp chiếu  |            |     | name        |     | String  |            |          |
| 3  Địa chỉ        |            |     | address     |     | String  |            |          |
| 4  Thành phố      |            |     | city        |     | String  |            |          |
| 5  Hình ảnh rạp   |            |     | imageUrl    |     | String  |            |          |
| 6  Số điện thoại  |            |     | phone       |     | String  |            |          |
Bảng 2.13. Thông tin rạp chiếu phim
d) Bảng gói combo
- Tên bảng: Combos
- Mục đích: Dùng để lưu trữ thông tin gói combos
| STT           | Diễn giải  | Tên trường  |     |         | Kiểu  | Ràng buộc  | Ghi chú  |
| ------------- | ---------- | ----------- | --- | ------- | ----- | ---------- | -------- |
| 1  Mã combo   |            | comboId     |     | String  |       | PK         |          |
| 2  Tên combo  |            | name        |     | String  |       |            |          |
28

| 3  Mô tả     |     | description  |     | String  |     |     |     |
| ------------ | --- | ------------ | --- | ------- | --- | --- | --- |
| 4  Hình ảnh  |     | imageUrl     |     | String  |     |     |     |
| 5  Giá bán   |     | price        |     | Double  |     |     |     |
Bảng 2.14. Thông tin combo
e) Bảng thông tin địa điểm
- Tên bảng: Metadata
- Mục đích: Dùng để lưu trữ danh sách các tỉnh thành
| STT                    | Diễn giải  |     | Tên trường  |     | Kiểu    | Ràng buộc  | Ghi chú  |
| ---------------------- | ---------- | --- | ----------- | --- | ------- | ---------- | -------- |
| 1  Mã địa điểm         |            |     | locationId  |     | String  | PK         |          |
| 2  Danh sách địa điểm  |            |     | list        |     | Array   |            |          |
Bảng 2.15. Thông tin địa điểm
f) Bảng thông tin phim
- Tên bảng: Movies
- Mục đích: Dùng để lưu trữ thông tin phim
| STT                  | Diễn giải  |              | Tên trường  |          | Kiểu  | Ràng buộc  | Ghi chú  |
| -------------------- | ---------- | ------------ | ----------- | -------- | ----- | ---------- | -------- |
| 1  Mã phim           |            | movieId      |             | String   |       | PK         |          |
| 2  Tên phim          |            | title        |             | String   |       |            |          |
| 3  Mô tả phim        |            | description  |             | String   |       |            |          |
| 4  Đạo diễn          |            | director     |             | String   |       |            |          |
| 5  Diễn viên         |            | cast         |             | String   |       |            |          |
| 6  Thời lượng        |            | duration     |             | Integer  |       |            |          |
| 7  Độ tuổi quy định  |            | ageRating    |             | String   |       |            |          |
| 8  Điểm đánh giá     |            | rating       |             | Double   |       |            |          |
29

| 9  Giá vé            |     | price        | Double     |     |     |
| -------------------- | --- | ------------ | ---------- | --- | --- |
| 10  Ngày khởi chiếu  |     | releaseDate  | Timestamp  |     |     |
| 11  Ảnh poster       |     | posterUrl    | String     |     |     |
| 12  Trailer phim     |     | trailerUrl   | String     |     |     |
| 13  Thư viện ảnh     |     | galleryUrls  | Array      |     |     |
Bảng 2.16. Thông tin phim
g) Bảng thông tin tức
- Tên bảng: News
- Mục đích: Dùng để lưu trữ thông tin tin tức
| STT                   | Diễn giải  | Tên trường     | Kiểu       | Ràng buộc  | Ghi chú  |
| --------------------- | ---------- | -------------- | ---------- | ---------- | -------- |
| 1  Mã tin tức         |            | newsId         | String     | PK         |          |
| 2  Tiêu đề            |            | title          | String     |            |          |
| 3  Danh mục           |            | category       | String     |            |          |
| 4  Nội dung tóm tắt   |            | content        | String     |            |          |
| 5  Nội dung chi tiết  |            | contentBlocks  | Array      |            |          |
| 6  Hình ảnh           |            | imageUrl       | String     |            |          |
| 7  Ngày đăng          |            | publishedDate  | Timestamp  |            |          |
Bảng 2.17. Bảng tin tức
h) Bảng thông tin sản phẩm
- Tên bảng: products
- Mục đích: Dùng để lưu trữ thông tin sản phẩm
| STT             | Diễn giải  | Tên trường  | Kiểu    | Ràng buộc  | Ghi chú  |
| --------------- | ---------- | ----------- | ------- | ---------- | -------- |
| 1  Mã sản phẩm  |            | productId   | String  | PK         |          |
30

| 2  Tên sản phẩm       |     | name         | String  |     |     |
| --------------------- | --- | ------------ | ------- | --- | --- |
| 3  Danh mục sản phẩm  |     | category     | String  |     |     |
| 4  Mô tả sản phẩm     |     | description  | String  |     |     |
| 5  Hình ảnh sản phẩm  |     | imageUrl     | String  |     |     |
| 6  Giá bán            |     | price        | Double  |     |     |
Bảng 2.18. Bảng thông tin sản phẩm
i) Bảng thông tin phòng chiếu
- Tên bảng: rooms
- Mục đích: Dùng để lưu trữ thông tin phòng chiếu
| STT                  | Diễn giải  | Tên trường  | Kiểu     | Ràng buộc  | Ghi chú  |
| -------------------- | ---------- | ----------- | -------- | ---------- | -------- |
| 1  Mã phòng chiếu    |            | roomId      | String   | PK         |          |
| 2  Tên phòng chiếu   |            | name        | String   |            |          |
| 3  Sơ đồ ghế         |            | layout      | Array    |            |          |
| 4  Tổng số cột ghế   |            | totalCols   | Integer  |            |          |
| 5  Tổng số hàng ghế  |            | totalRows   | Integer  |            |          |
Bảng 2.19. Bảng thông tin phòng chiếu
j) Bảng thông tin lịch chiếu
- Tên bảng: showtimes
- Mục đích: Dùng để lưu trữ thông tin lịch chiếu
| STT               | Diễn giải  | Tên trường  | Kiểu    | Ràng buộc  | Ghi chú  |
| ----------------- | ---------- | ----------- | ------- | ---------- | -------- |
| 1  Mã lịch chiếu  |            | showtimeId  | String  | PK         |          |
| 2  Mã phim        |            | movieId     | String  | FK         |          |
| 3  Mã rạp chiếu   |            | cinemaId    | String  | FK         |          |
31

| 4  Mã phòng chiếu  |     | roomId       | String  | FK  |     |
| ------------------ | --- | ------------ | ------- | --- | --- |
| 5  Thành phố       |     | city         | String  |     |     |
| 6  Ngày chiếu      |     | date         | String  |     |     |
| 7  Giờ chiếu       |     | time         | String  |     |     |
| 8  Định dạng phim  |     | format       | String  |     |     |
| 9  Ghế đã đặt      |     | bookedSeats  | Array   |     |     |
Bảng 2.20. Bảng thông tin lịch chiếu
k) Bảng thông tin người dùng
- Tên bảng: users
- Mục đích: Dùng để lưu trữ thông tin người dùng
| STT               | Diễn giải  | Tên trường  | Kiểu     | Ràng buộc  | Ghi chú  |
| ----------------- | ---------- | ----------- | -------- | ---------- | -------- |
| 1  Mã người dùng  |            | uid         | String   | PK         |          |
| 2  Họ và tên      |            | name        | String   |            |          |
| 3  Email          |            | email       | String   |            |          |
| 4  Số điện thoại  |            | phone       | String   |            |          |
| 5  Ngày sinh      |            | birthday    | String   |            |          |
| 6  Vai trò        |            | role        | String   |            |          |
| 7  Điểm tích lũy  |            | stars       | Integer  |            |          |
| 8  Ảnh đại diện   |            | avatarUrl   | String   |            |          |
Bảng 2.21. Bảng thông tin người dùng
32

CHƯƠNG 3. TRIỂN KHAI HỆ THỐNG ĐẶT VÉ XEM PHIM
3.1. Môi trường phát triển
3.1.1. Công nghệ và công cụ
Trong quá trình xây dựng ứng dụng đặt vé xem phim trực tuyến, nhóm đã
sử dụng nhiều công cụ và công nghệ khác nhau nhằm hỗ trợ việc phát triển, quản
lý và triển khai hệ thống. Các công cụ chính được sử dụng bao gồm Android
Studio, ngôn ngữ lập trình Java, GitHub và Firebase, Figma.
- Android Studio là môi trường phát triển chính thức dành cho hệ điều hành
Android do Google phát triển. Công cụ này cung cấp đầy đủ các chức năng hỗ
trợ lập trình, thiết kế giao diện, gỡ lỗi và kiểm thử ứng dụng trên thiết bị thật hoặc
máy ảo. Trong đề tài, Android Studio được sử dụng để xây dựng toàn bộ ứng
dụng đặt vé xem phim trực tuyến.
- Java là ngôn ngữ lập trình hướng đối tượng được sử dụng để phát triển các
chức năng của ứng dụng như đăng nhập, đăng ký tài khoản, tìm kiếm phim, đặt
vé và quản lý thông tin người dùng. Java có tính ổn định cao, dễ bảo trì và được
hỗ trợ tốt trên nền tảng Android.
- GitHub là nền tảng lưu trữ mã nguồn trực tuyến dựa trên Git. Công cụ này
hỗ trợ quản lý phiên bản, theo dõi lịch sử thay đổi của dự án và giúp các thành
viên trong nhóm dễ dàng phối hợp phát triển phần mềm.
- Firebase là nền tảng Backend-as-a-Service (BaaS) do Google cung cấp.
Trong đề tài, Firebase được sử dụng để lưu trữ dữ liệu người dùng, thông tin
phim, lịch chiếu và hỗ trợ xác thực tài khoản. Firebase giúp giảm thời gian xây
dựng hệ thống máy chủ và tăng khả năng đồng bộ dữ liệu giữa các thiết bị.
- Diagram hỗ trợ xây dựng các sơ đồ phân tích và thiết kế hệ thống như sơ
đồ use case, sơ đồ lớp, sơ đồ trình tự,…
- Figma là công cụ thiết kế giao diện người dùng (UI/UX) được sử dụng để
33

xây dựng các bản thiết kế và nguyên mẫu cho ứng dụng trước khi tiến hành lập
trình. Công cụ này giúp trực quan hóa giao diện và hỗ trợ quá trình phát triển ứng
dụng hiệu quả hơn.
3.1.2. Lựa chọn giao diện cho bài toán
Giao diện của ứng dụng được thiết kế dựa trên việc tham khảo ứng dụng của
Galaxy Cinema nhằm mang đến trải nghiệm quen thuộc cho người dùng. Bố cục
các màn hình được sắp xếp một cách khoa học, giúp người dùng dễ dàng thao tác
và sử dụng các chức năng của hệ thống. Màu sắc và cách trình bày thông tin được
lựa chọn theo hướng hiện đại, trực quan và thân thiện. Các chức năng như tìm
kiếm phim, xem lịch chiếu, chọn ghế và đặt vé được bố trí rõ ràng để nâng cao
trải nghiệm sử dụng. Ngoài việc tham khảo giao diện từ Galaxy Cinema, nhóm
cũng thực hiện một số điều chỉnh về bố cục và thiết kế nhằm phù hợp với yêu cầu
của đề tài. Nhờ đó, ứng dụng vừa đảm bảo tính thẩm mỹ vừa đáp ứng tốt nhu cầu
sử dụng của người dùng.
3.2. Xây dựng phần mềm
3.2.1. Giao diện đăng ký, đăng nhập tài khoản
Giao diện đăng ký và đăng nhập tài khoản được thiết kế đơn giản, trực quan
nhằm giúp người dùng dễ dàng truy cập và sử dụng ứng dụng. Màn hình đăng
nhập cho phép người dùng nhập địa chỉ email và mật khẩu để xác thực tài khoản
đã đăng ký. Đối với người dùng mới, hệ thống cung cấp chức năng đăng ký tài
khoản bằng cách nhập các thông tin cần thiết như họ tên, email và mật khẩu. Các
trường dữ liệu được bố trí rõ ràng, dễ quan sát và thuận tiện cho việc nhập liệu.
Ngoài ra, hệ thống còn thực hiện kiểm tra tính hợp lệ của dữ liệu trước khi xử lý
nhằm đảm bảo tính chính xác và bảo mật cho tài khoản người dùng. Giao diện
được thiết kế theo phong cách hiện đại, thân thiện, mang lại trải nghiệm sử dụng
thuận tiện và hiệu quả. Sau khi đăng nhập thành công, người dùng có thể truy cập
và sử dụng đầy đủ các chức năng của hệ thống.
34

Hình 3.1. Giao diện trang đăng ký, đăng nhập
3.2.2. Giao diện trang chủ
Hình 3.2. Giao diện trang chủ
35

Giao diện trang chủ của ứng dụng được thiết kế nhằm mang lại trải nghiệm
thuận tiện và thân thiện cho người dùng. Tại đây, người dùng có thể dễ dàng theo
dõi các bộ phim đang chiếu, phim sắp chiếu, các chương trình khuyến mãi nổi
bật và những thông tin mới nhất từ hệ thống rạp. Bố cục giao diện được sắp xếp
khoa học với các danh mục chức năng rõ ràng, giúp người dùng nhanh chóng tìm
kiếm phim, xem lịch chiếu và thực hiện đặt vé. Thiết kế trực quan cùng màu sắc
hài hòa góp phần nâng cao tính thẩm mỹ và hiệu quả sử dụng của ứng dụng.
3.2.3. Giao diện trang chi tiết phim
Giao diện chi tiết phim được xây dựng nhằm cung cấp đầy đủ thông tin về
bộ phim mà người dùng quan tâm. Tại đây, người dùng có thể theo dõi tên phim,
hình ảnh giới thiệu, thời lượng, ngày khởi chiếu, điểm đánh giá và nội dung tóm
tắt của phim. Bên cạnh đó, giao diện còn hỗ trợ chuyển đổi giữa các mục như
Suất chiếu, Thông tin và Tin tức, giúp người dùng dễ dàng tra cứu các thông tin
liên quan. Việc trình bày thông tin một cách trực quan và khoa học góp phần nâng
cao trải nghiệm người dùng, đồng thời hỗ trợ quá trình lựa chọn và đặt vé trở nên
thuận tiện hơn.
Hình 3.3. Giao diện trang thông tin phim
36

3.2.4. Giao diện trang đặt vé
Giao diện thông tin đặt vé được thiết kế nhằm hỗ trợ người dùng thực hiện
quá trình đặt vé một cách nhanh chóng và thuận tiện. Tại đây, hệ thống hiển thị
các thông tin chi tiết của bộ phim như tên phim, thời lượng, ngày khởi chiếu, đánh
giá và nội dung giới thiệu. Người dùng có thể lựa chọn rạp chiếu phù hợp, xem
các suất chiếu đang khả dụng và chọn thời gian xem mong muốn. Sau khi lựa
chọn suất chiếu, người dùng tiếp tục chọn vị trí ghế ngồi trong rạp theo nhu cầu.
Hình 3.3. Giao diện trang đặt vé
Bên cạnh đó, hệ thống còn hỗ trợ người dùng lựa chọn các sản phẩm đi kèm
như bắp rang, nước uống hoặc các combo ưu đãi để nâng cao trải nghiệm xem
phim. Các sản phẩm được hiển thị trực quan cùng thông tin về giá bán, giúp người
dùng dễ dàng lựa chọn theo nhu cầu. Sau khi hoàn tất các bước lựa chọn, hệ thống
sẽ tổng hợp và hiển thị toàn bộ thông tin đặt vé, bao gồm tên phim, rạp chiếu,
suất chiếu, vị trí ghế ngồi, sản phẩm đi kèm và tổng chi phí thanh toán. Người
dùng có thể kiểm tra lại các thông tin đã chọn trước khi xác nhận đặt vé.
37

Hình 3.5. Giao diện trang đặt vé
3.2.5. Giao diện trang tin tức
Giao diện tin tức cung cấp các bài viết và thông tin mới nhất về phim ảnh, lịch
khởi chiếu, diễn viên, các sự kiện điện ảnh nổi bật và chương trình khuyến mãi của hệ
thống. Nội dung được sắp xếp khoa học, giúp người dùng dễ dàng theo dõi và cập nhật
các thông tin liên quan đến lĩnh vực điện ảnh.
Hình 3.6. Giao diện trang tin tức
38

3.2.6. Giao diện trang quản trị, trang quản lý người dùng
Giao diện trang quản trị được xây dựng nhằm hỗ trợ quản trị viên theo dõi
và quản lý toàn bộ hoạt động của hệ thống. Tại đây, quản trị viên có thể xem các
thông tin thống kê như doanh thu, số lượng phim, rạp chiếu, suất chiếu và sản
phẩm đang được quản lý. Đồng thời, hệ thống cung cấp các chức năng quản lý
phim, rạp chiếu, suất chiếu, cửa hàng và các nội dung hiển thị trên ứng dụng.
Bên cạnh đó, giao diện quản lý người dùng cho phép quản trị viên theo dõi
danh sách tài khoản, tìm kiếm người dùng và thực hiện các thao tác chỉnh sửa
hoặc xóa tài khoản khi cần thiết. Việc tích hợp các chức năng quản lý trên cùng
một hệ thống giúp nâng cao hiệu quả quản trị và đảm bảo hoạt động ổn định của
ứng dụng.
Hình 3.7. Giao diện trang quản trị, trang quản lý người dùng
3.2.7. Giao diện trang quản lý phim
Giao diện quản lý phim cho phép quản trị viên thực hiện các chức năng quản
lý thông tin phim trong hệ thống. Tại đây, quản trị viên có thể xem danh sách
phim, tìm kiếm phim theo tên và thực hiện các thao tác thêm mới, chỉnh sửa hoặc
39

xóa phim. Ngoài ra, các thông tin như tên phim, thời lượng, thể loại, ngày khởi
chiếu, hình ảnh và nội dung giới thiệu cũng được quản lý tập trung, giúp đảm bảo
dữ liệu luôn được cập nhật đầy đủ và chính xác.
Hình 3.8. Giao diện trang quản lý phim
3.2.8. Giao diện trang quản lý suất chiếu
Giao diện quản lý suất chiếu được xây dựng nhằm hỗ trợ quản trị viên quản
lý lịch chiếu của các bộ phim trong hệ thống một cách hiệu quả. Tại đây, quản trị
viên có thể theo dõi danh sách các suất chiếu đang hoạt động, đồng thời thực hiện
các thao tác thêm mới, chỉnh sửa, xóa và tìm kiếm suất chiếu theo nhu cầu. Mỗi
suất chiếu được lưu trữ với các thông tin như tên phim, rạp chiếu, phòng chiếu,
thời gian bắt đầu và thời gian kết thúc. Việc quản lý tập trung giúp đảm bảo lịch
chiếu được sắp xếp hợp lý, tránh trùng lặp thời gian và hỗ trợ quá trình đặt vé của
người dùng diễn ra chính xác, thuận tiện. Ngoài ra, giao diện còn giúp quản trị
viên dễ dàng kiểm soát và cập nhật lịch chiếu khi có sự thay đổi, góp phần nâng
cao hiệu quả vận hành của hệ thống.
40

Hình 3.9. Giao diện trang quản lý suất chiếu
3.2.9. Giao diện trang quản lý phòng chiếu
Giao diện quản lý phòng chiếu hỗ trợ quản trị viên quản lý các phòng chiếu
trong hệ thống. Tại đây, quản trị viên có thể thực hiện các thao tác thêm, sửa, xóa
và tìm kiếm phòng chiếu, đồng thời theo dõi các thông tin như tên phòng, sức
chứa và số lượng ghế. Việc quản lý tập trung giúp đảm bảo dữ liệu phòng chiếu
luôn chính xác và hỗ trợ quá trình sắp xếp lịch chiếu hiệu quả.
Hình 3.10. Giao diện trang quản lý suất chiếu
41

Ngoài việc quản lý thông tin cơ bản của phòng chiếu, hệ thống còn cho phép quản
trị viên thiết lập và chỉnh sửa sơ đồ ghế ngồi phù hợp với từng phòng. Điều này giúp
đảm bảo tính chính xác trong quá trình đặt vé, đồng thời tạo điều kiện thuận lợi cho việc
quản lý sức chứa và vận hành rạp chiếu một cách hiệu quả.
3.2.10. Giao diện trang quản lý rạp chiếu
Giao diện quản lý rạp chiếu hỗ trợ quản trị viên quản lý thông tin các rạp
trong hệ thống. Tại đây, quản trị viên có thể thực hiện các thao tác thêm, sửa, xóa
và tìm kiếm rạp chiếu, đồng thời theo dõi các thông tin như tên rạp, địa chỉ và số
lượng phòng chiếu. Việc quản lý tập trung giúp đảm bảo dữ liệu rạp chiếu luôn
chính xác, tạo điều kiện thuận lợi cho việc sắp xếp lịch chiếu và nâng cao hiệu
quả vận hành của hệ thống.
Hình 3.11. Giao diện trang quản lý rạp
Nhờ việc quản lý tập trung các thông tin về rạp chiếu, hệ thống giúp quản trị viên
dễ dàng theo dõi, cập nhật và kiểm soát dữ liệu một cách hiệu quả. Điều này góp phần
đảm bảo tính chính xác của thông tin, đồng thời hỗ trợ tốt cho quá trình tổ chức lịch
chiếu và vận hành hệ thống đặt vé.
42

KẾT LUẬN
1. Kết quả đạt được
Sau quá trình nghiên cứu và thực hiện đề tài “Xây dựng ứng dụng đặt vé
xem phim trực tuyến”, nhóm đã hoàn thành các mục tiêu cơ bản đã đề ra. Về mặt
lý thuyết, đề tài đã tìm hiểu và trình bày các kiến thức liên quan đến hệ thống đặt
vé xem phim trực tuyến, quy trình phân tích và thiết kế hệ thống, cũng như các
công nghệ được sử dụng trong quá trình phát triển ứng dụng.
Về mặt thực tiễn, nhóm đã xây dựng được ứng dụng trên nền tảng Android
với các chức năng chính như đăng ký, đăng nhập tài khoản, xem danh sách phim,
tìm kiếm phim, xem chi tiết phim, xem lịch chiếu, lựa chọn ghế ngồi và đặt vé.
Dữ liệu của hệ thống được lưu trữ và quản lý thông qua Firebase, giúp việc truy
xuất và đồng bộ dữ liệu diễn ra thuận lợi.
Bên cạnh đó, ứng dụng được thiết kế với giao diện thân thiện, dễ sử dụng và
tham khảo từ các ứng dụng đặt vé xem phim phổ biến hiện nay. Thông qua quá
trình thực hiện đề tài, nhóm đã củng cố được kiến thức về lập trình Android, cơ
sở dữ liệu Firebase cũng như kỹ năng phân tích, thiết kế và phát triển phần mềm.
Mặc dù đã cố gắng hoàn thành đề tài trong phạm vi kiến thức và thời gian
cho phép, nhưng hệ thống vẫn còn một số hạn chế nhất định. Nhóm rất mong
nhận được những ý kiến đóng góp từ quý Thầy, Cô để tiếp tục hoàn thiện và phát
triển ứng dụng trong tương lai.
2. Hạn chế
Bên cạnh những kết quả đã đạt được, đề tài vẫn còn tồn tại một số hạn chế
như sau:
- Ứng dụng hiện tại chưa tích hợp hệ thống thanh toán trực tuyến thực tế, do
đó người dùng chưa thể thực hiện thanh toán vé thông qua các cổng thanh toán
điện tử.
43

- Một số chức năng vẫn đang ở mức cơ bản và chưa được hoàn thiện đầy đủ
để đáp ứng các nhu cầu thực tế của người dùng.
- Dữ liệu phim, lịch chiếu và rạp chiếu hiện tại chủ yếu phục vụ cho mục
đích minh họa và thử nghiệm hệ thống.
- Giao diện ứng dụng vẫn cần được tối ưu hơn về trải nghiệm người dùng và
khả năng tương thích trên nhiều thiết bị Android khác nhau.
- Mã nguồn và cơ sở dữ liệu chưa được tối ưu hoàn toàn, cần tiếp tục cải
thiện để nâng cao hiệu năng và khả năng mở rộng của hệ thống.
3. Hướng phát triển
Trong thời gian tới, nhóm sẽ tiếp tục nghiên cứu và phát triển ứng dụng
nhằm hoàn thiện hơn các chức năng hiện có. Trước hết, hệ thống sẽ được tích hợp
các cổng thanh toán trực tuyến như MoMo, ZaloPay hoặc VNPay để người dùng
có thể thực hiện thanh toán vé một cách thuận tiện và an toàn.
Bên cạnh đó, nhóm sẽ bổ sung thêm các chức năng như quản lý vé đã đặt,
lịch sử giao dịch, đánh giá phim, thông báo lịch chiếu và gợi ý phim phù hợp với
sở thích của người dùng. Giao diện ứng dụng cũng sẽ được cải tiến theo hướng
hiện đại, trực quan và thân thiện hơn.
Ngoài ra, hệ thống sẽ được tối ưu về hiệu năng, bảo mật và khả năng xử lý
dữ liệu nhằm đáp ứng số lượng người dùng lớn hơn trong thực tế. Với những kiến
thức và kinh nghiệm tích lũy được trong quá trình thực hiện đề tài, nhóm tin rằng
ứng dụng có thể tiếp tục được phát triển và hoàn thiện để trở thành một hệ thống
đặt vé xem phim trực tuyến hữu ích và đáp ứng tốt nhu cầu của người dùng.
44

TÀI LIỆU THAM KHẢO
[1] Android Developers, Android Developer Documentation,
https://developer.android.com.
[2] Oracle Corporation, Java Documentation, https://docs.oracle.com/javase.
[3] Google Firebase, Firebase Documentation, https://firebase.google.com/docs.
[4] GitHub Documentation, https://docs.github.com.
[5] Figma Help Center, https://help.figma.com.
[6] Roger S. Pressman, Software Engineering: A Practitioner's Approach,
McGraw-Hill Education.
[7] Galaxy Cinema, Hệ thống đặt vé xem phim trực tuyến,
https://www.galaxycine.vn.
[8] UML Resource Page, Unified Modeling Language (UML),
https://www.uml.org.
[9] Tài liệu bài giảng môn Phân tích và Thiết kế Hệ thống Thông tin, Trường Đại
học Vinh.
[10] Tài liệu bài giảng môn Lập trình Android, Trường Đại học Vinh.
[11] CGV Cinemas Vietnam, Hệ thống đặt vé xem phim trực tuyến,
https://www.cgv.vn.
[12] Lotte Cinema Việt Nam, Hệ thống đặt vé xem phim trực tuyến,
https://www.lottecinemavn.com.
45