import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/handbook_article.dart';

class HandbookService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'PlantHandbook';

  /// Stream danh sách bài viết cẩm nang từ Firestore
  static Stream<List<HandbookArticle>> streamArticles() {
    return _firestore
        .collection(collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Tự động seed dữ liệu mẫu vào Firestore nếu chưa có
        seedSampleArticlesIfNeeded();
        return defaultSampleArticles;
      }
      return snapshot.docs.map((doc) => HandbookArticle.fromFirestore(doc)).toList();
    });
  }

  /// Tự động khởi tạo dữ liệu mẫu phong phú có chèn ảnh sinh động vào Firestore
  static Future<void> seedSampleArticlesIfNeeded() async {
    try {
      final snap = await _firestore.collection(collectionName).limit(1).get();
      if (snap.docs.isEmpty) {
        final batch = _firestore.batch();
        for (final article in defaultSampleArticles) {
          final docRef = _firestore.collection(collectionName).doc(article.id);
          batch.set(docRef, article.toMap());
        }
        await batch.commit();
        debugPrint("Đã khởi tạo thành công ${defaultSampleArticles.length} bài viết cẩm nang vào Firestore.");
      }
    } catch (e) {
      debugPrint("Lỗi seed bài viết cẩm nang vào Firestore: $e");
    }
  }

  /// Danh sách bài viết mẫu mặc định (có chèn ảnh minh họa vào giữa các đoạn văn)
  static final List<HandbookArticle> defaultSampleArticles = [
    HandbookArticle(
      id: "art_1_tuoi_nuoc",
      title: "Bí quyết tưới nước đúng cách: Nhận biết rễ úng hay thiếu nước",
      category: "Mẹo tưới cây",
      readTime: "4 phút đọc",
      author: "Ban biên tập Floria",
      coverImage: "https://i.ibb.co/MxQ1Lz37/86388f5c7477.jpg",
      summary: "Hơn 80% cây cảnh trong nhà chết vì tưới quá nhiều thay vì thiếu nước. Học ngay nguyên tắc ngón tay 3cm để đo độ ẩm rễ chuẩn xác nhất.",
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      blocks: [
        HandbookBlock(
          type: "text",
          value: "Nhiều người có thói quen tưới cây theo lịch cố định (ví dụ ngày nào cũng tưới), nhưng nhu cầu nước thực tế phụ thuộc rất nhiều vào nhiệt độ phòng, ánh sáng và loại giá thể thoát nước.",
        ),
        HandbookBlock(
          type: "tip",
          value: "💡 Quy tắc ngón tay 3cm: Nhẹ nhàng cắm ngón trỏ sâu khoảng 2-3cm vào bề mặt đất. Nếu cảm thấy mát và có đất ẩm dính nhẹ, cây vẫn đủ nước - TUYỆT ĐỐI KHÔNG TƯỚI. Nếu đất khô ráo và tơi xốp, đó mới là lúc thích hợp để tưới.",
        ),
        HandbookBlock(
          type: "image",
          value: "https://i.ibb.co/nM1WJMxk/ecae44420f93.jpg",
          caption: "Minh họa: Cách kiểm tra độ ẩm bề mặt đất trước khi quyết định tưới",
        ),
        HandbookBlock(
          type: "text",
          value: "Dấu hiệu cây bị úng nước: Lá mềm nhũn, ngả vàng bắt đầu từ các lá già ở gốc, đất có mùi chua nhẹ hoặc ẩm ướt liên tục quá 5 ngày mà không khô được.",
        ),
        HandbookBlock(
          type: "image",
          value: "https://i.ibb.co/Xx5BTsRX/4714b95e7862.jpg",
          caption: "Hệ rễ khỏe mạnh có màu trắng ngà, rễ úng sẽ chuyển sang màu nâu đen và nhũn",
        ),
        HandbookBlock(
          type: "text",
          value: "Dấu hiệu cây bị thiếu nước: Phiến lá cụp rũ xuống, mép lá khô giòn, bầu đất co lại tách khỏi thành chậu. Trường hợp này chỉ cần ngâm đáy chậu vào chậu nước 15 phút là cây sẽ hút nước mao dẫn và căng tràn sức sống trở lại.",
        ),
      ],
    ),
    HandbookArticle(
      id: "art_2_la_vang",
      title: "Xử lý lá vàng & cháy mép: Tìm đúng nguyên nhân để cứu cây",
      category: "Bắt bệnh cây",
      readTime: "5 phút đọc",
      author: "Bác sĩ Cây trồng Floria",
      coverImage: "https://i.ibb.co/fzBxkDFZ/ef61677f451a.jpg",
      summary: "Lá chuyển vàng mép ngoài khác hoàn toàn với vàng toàn bộ phiến lá. Phân biệt chính xác giữa thiếu vi lượng, thừa clo hay cháy nắng để chữa trị kịp thời.",
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      blocks: [
        HandbookBlock(
          type: "text",
          value: "Hiện tượng lá chuyển vàng là tiếng kêu cứu phổ biến nhất của cây xanh. Đừng vội cắt bỏ lá vàng khi bạn chưa xác định được nguồn gốc nguyên nhân.",
        ),
        HandbookBlock(
          type: "image",
          value: "https://i.ibb.co/Zb4bdd8/d732d46ea60f.jpg",
          caption: "Cháy mép lá do tiếp xúc trực tiếp với luồng gió điều hòa hoặc ánh nắng gắt",
        ),
        HandbookBlock(
          type: "text",
          value: "1. Vàng từ chóp lá lan dần vào trong: Thường do nguồn nước máy có hàm lượng clo hoặc khoáng chất quá cao. Hãy để nước máy lắng qua đêm trong bình mở nắp trước khi tưới.",
        ),
        HandbookBlock(
          type: "text",
          value: "2. Vàng xen kẽ giữa các gân lá (gân vẫn xanh): Triệu chứng điển hình của việc thiếu sắt hoặc magie. Bổ sung một lượng nhỏ phân bón vi lượng dạng xịt lá sẽ giúp cây hồi xanh sau 1 tuần.",
        ),
        HandbookBlock(
          type: "tip",
          value: "🌿 Lời khuyên: Đặt cây cách xa ít nhất 2 mét khỏi luồng gió phả trực tiếp của máy lạnh hoặc quạt gió để phiến lá không bị mất nước cục bộ.",
        ),
        HandbookBlock(
          type: "image",
          value: "https://i.ibb.co/whz73xn9/c710efab1c7d.jpg",
          caption: "Cây sau khi được chuyển sang khu vực ánh sáng tán xạ êm dịu",
        ),
      ],
    ),
    HandbookArticle(
      id: "art_3_cay_phong_ngu",
      title: "Top 5 loài cây lọc không khí tốt nhất cho phòng ngủ & bàn làm việc",
      category: "Chọn cây cảnh",
      readTime: "3 phút đọc",
      author: "Chuyên gia Không Gian Xanh",
      coverImage: "https://i.ibb.co/whz73xn9/c710efab1c7d.jpg",
      summary: "Báo cáo Clean Air Study của NASA chỉ ra cây lưỡi hổ và trầu bà có khả năng hấp thụ formaldehyde, benzene và nhả oxy ngay cả trong đêm tối.",
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      blocks: [
        HandbookBlock(
          type: "text",
          value: "Không phải loài cây nào cũng thích hợp đặt trong phòng ngủ kín. Dưới đây là các loài cây có cơ chế quang hợp CAM đặc biệt, hấp thụ CO2 và nhả Oxy vào ban đêm:",
        ),
        HandbookBlock(
          type: "image",
          value: "https://i.ibb.co/jZRfHvS4/93b8d9ffa9c5.jpg",
          caption: "Cây Lưỡi Hổ (Sansevieria) - 'Nhà máy lọc khí ban đêm' bền bỉ bậc nhất",
        ),
        HandbookBlock(
          type: "text",
          value: "🌿 1. Cây Lưỡi Hổ (Sansevieria): Chịu hạn cực tốt, chỉ cần tưới 2-3 tuần một lần, hấp thụ bức xạ điện từ và khí formaldehyde.",
        ),
        HandbookBlock(
          type: "text",
          value: "🌿 2. Cây Trầu Bà (Pothos): Dễ sống bậc nhất, phát triển tốt dưới ánh đèn huỳnh quang và có khả năng thanh lọc khói bụi.",
        ),
        HandbookBlock(
          type: "image",
          value: "https://i.ibb.co/xqZxDT18/5fc4d6ac2a8d.jpg",
          caption: "Lan Ý (Peace Lily) nở hoa trắng tinh khôi và diệt trừ bào tử nấm mốc",
        ),
        HandbookBlock(
          type: "text",
          value: "🌿 3. Cây Lan Ý: Tăng độ ẩm tự nhiên cho phòng máy lạnh thêm 5%, giúp hạn chế khô họng và ngạt mũi khi ngủ.",
        ),
      ],
    ),
    HandbookArticle(
      id: "art_4_bon_phan",
      title: "Bón phân NPK & Vi lượng: Bao lâu bón một lần là chuẩn?",
      category: "Dinh dưỡng cây",
      readTime: "4 phút đọc",
      author: "Ban nông nghiệp thông minh",
      coverImage: "https://i.ibb.co/wG57fFH/3bb2ddcbfd02.jpg",
      summary: "Sai lầm lớn nhất của người mới là bón phân quá đậm đặc khiến rễ bị 'xót'. Bí quyết pha loãng 1/2 liều lượng khuyến nghị cho cây trồng chậu trong nhà.",
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      blocks: [
        HandbookBlock(
          type: "text",
          value: "Cây trồng trong chậu có thể tích đất giới hạn, nếu bón thừa phân, muối khoáng tích tụ sẽ hút ngược nước từ rễ ra ngoài khiến cây héo khô nhanh chóng.",
        ),
        HandbookBlock(
          type: "tip",
          value: "💡 Nguyên tắc vàng: Thà bón loãng nhiều lần còn hơn bón đặc một lần. Pha phân bón lá hoặc phân vi lượng với liều lượng chỉ bằng 50% hướng dẫn trên bao bì.",
        ),
        HandbookBlock(
          type: "image",
          value: "https://i.ibb.co/MxQ1Lz37/86388f5c7477.jpg",
          caption: "Bón phân dạng xịt sương trực tiếp lên mặt dưới phiến lá giúp hấp thu nhanh nhất",
        ),
        HandbookBlock(
          type: "text",
          value: "Chu kỳ lý tưởng: Đối với cây nội thất thông thường, chu kỳ bón phân vi lượng từ 20 đến 30 ngày/lần trong mùa sinh trưởng (xuân, hè, thu) và ngừng bón vào mùa đông khi cây bước vào giai đoạn ngủ nghỉ.",
        ),
      ],
    ),
  ];
}
