import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/disease_info.dart';

class DiseaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'DiseasesInfo';

  /// Stream danh sách toàn bộ 5 hồ sơ bệnh học từ Firestore
  static Stream<List<DiseaseInfo>> streamDiseases() {
    return _firestore.collection(collectionName).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        seedDefaultDiseasesIfNeeded();
        return defaultDiseases;
      }
      return snapshot.docs.map((doc) => DiseaseInfo.fromFirestore(doc)).toList();
    });
  }

  /// Lấy hồ sơ bệnh học theo ID mầm bệnh ('Anthracnose', 'Healthy', 'Leaf_Spot'...)
  static Future<DiseaseInfo?> getDiseaseById(String diseaseId) async {
    try {
      final doc = await _firestore.collection(collectionName).doc(diseaseId).get();
      if (doc.exists) {
        return DiseaseInfo.fromFirestore(doc);
      }
      return defaultDiseases.firstWhere(
        (d) => d.id.toLowerCase() == diseaseId.toLowerCase(),
        orElse: () => defaultDiseases.first,
      );
    } catch (e) {
      debugPrint("Lỗi lấy thông tin bệnh từ Firestore: $e");
      return defaultDiseases.firstWhere(
        (d) => d.id.toLowerCase() == diseaseId.toLowerCase(),
        orElse: () => defaultDiseases.first,
      );
    }
  }

  /// Tự động seed hồ sơ khoa học (Tác nhân, Cơ chế, Điều kiện phát sinh, Phòng ngừa) vào Firestore
  static Future<void> seedDefaultDiseasesIfNeeded() async {
    try {
      final snap = await _firestore.collection(collectionName).limit(1).get();
      if (snap.docs.isEmpty) {
        final batch = _firestore.batch();
        for (final disease in defaultDiseases) {
          final docRef = _firestore.collection(collectionName).doc(disease.id);
          batch.set(docRef, disease.toMap());
        }
        await batch.commit();
        debugPrint("Đã khởi tạo thành công 5 hồ sơ bệnh học vào Firestore Collection: $collectionName");
      }
    } catch (e) {
      debugPrint("Lỗi khi seed hồ sơ bệnh học vào Firestore: $e");
    }
  }

  /// 5 hồ sơ bệnh học chuẩn khoa học
  static const List<DiseaseInfo> defaultDiseases = [
    DiseaseInfo(
      id: "Healthy",
      nameVi: "Lá Khỏe Mạnh",
      nameEn: "Healthy Leaf",
      severity: "Bình thường",
      pathogen: "Không có mầm bệnh - Sinh lý cây cân bằng",
      mechanism: "Quá trình quang hợp, hô hấp và thoát hơi nước diễn ra ổn định. Biểu bì và tầng cutin nguyên vẹn bảo vệ các mô xốp bên trong khỏi tác nhân xâm hại.",
      favorableConditions: "Ánh sáng tán xạ thích hợp, nhiệt độ 20-30°C, giá thể tơi xốp thoáng khí và dinh dưỡng khoáng cân bằng.",
      prevention: "Duy trì chế độ tưới nước vừa đủ theo nguyên tắc khô - ướt xen kẽ, lau bụi lá định kỳ để tối ưu quang hợp.",
    ),
    DiseaseInfo(
      id: "Anthracnose",
      nameVi: "Bệnh Thán Thư",
      nameEn: "Anthracnose",
      severity: "Nguy hiểm",
      pathogen: "Nấm Colletotrichum spp.",
      mechanism: "Bào tử nấm nảy mầm hình thành giác bám (appressorium), đâm xuyên lớp cutin biểu bì lá và tiết enzyme phân giải pectin, cellulose. Mô lá bị hoại tử sụp đổ tạo thành các đốm nâu khô giòn có viền sẫm màu.",
      favorableConditions: "Độ ẩm không khí cao (>85%), giọt nước đọng sương qua đêm trên phiến lá, nhiệt độ ấm áp 25-30°C và không gian bí gió.",
      prevention: "Cách ly cây, giữ khoảng cách thông thoáng giữa các chậu cây, tưới trực tiếp vào gốc vào buổi sáng và tránh làm ướt mặt lá vào ban đêm.",
    ),
    DiseaseInfo(
      id: "Leaf_Spot",
      nameVi: "Bệnh Đốm Lá Nấm",
      nameEn: "Fungal Leaf Spot",
      severity: "Cảnh báo",
      pathogen: "Nấm Cercospora / Alternaria spp.",
      mechanism: "Sợi nấm xâm nhập qua khí khổng hoặc vết thương vi mô, tiết độc tố cercosporin phá hủy màng tế bào. Diệp lục bị phân hủy tạo thành các đốm mắt cua hoại tử, gây vàng úa và rụng lá sớm.",
      favorableConditions: "Lá bị ẩm ướt kéo dài, ánh sáng tự nhiên yếu ớt, giá thể chậu ngậm nước lâu ngày hoặc cây thiếu vi lượng.",
      prevention: "Tăng cường độ thông thoáng khí, đưa cây ra khu vực có ánh sáng tán xạ tốt hơn, khử trùng kéo cắt tỉa định kỳ.",
    ),
    DiseaseInfo(
      id: "Bacterial_Blight",
      nameVi: "Cháy Bìa Lá Vi Khuẩn",
      nameEn: "Bacterial Blight",
      severity: "Nguy hiểm",
      pathogen: "Vi khuẩn Xanthomonas / Erwinia spp.",
      mechanism: "Vi khuẩn xâm nhập qua thủy khổng ở mép lá hoặc qua vết rách tổn thương cơ học. Chúng sinh sôi trong bó mạch dẫn, tiết chất nhầy polysaccharide gây tắc nghẽn dòng nhựa, làm mép lá sũng nước rồi cháy khô hoại tử.",
      favorableConditions: "Giá thể ngập úng bí rễ, thời tiết nồm ẩm oi bức (28-32°C), nước tưới bắn tung tóe hoặc vết thương hở do va quẹt.",
      prevention: "Kiểm tra lỗ thoát nước đáy chậu, ngưng tưới khi phát hiện vết úng, không cắt tỉa lá lúc trời mưa ẩm để tránh vi khuẩn xâm nhập.",
    ),
    DiseaseInfo(
      id: "Powdery_Mildew",
      nameVi: "Bệnh Phấn Trắng",
      nameEn: "Powdery Mildew",
      severity: "Cảnh báo",
      pathogen: "Nấm ngoại ký sinh họ Erysiphaceae",
      mechanism: "Bào tử nấm phát triển mạng lưới sợi nấm màu trắng phủ kín mặt ngoài phiến lá. Chúng đâm các vòi hút (haustoria) vào tế bào biểu bì hút kiệt chất dinh dưỡng, cản trở quang hợp khiến lá non xoăn tít và biến dạng.",
      favorableConditions: "Chênh lệch nhiệt độ ngày - đêm cao, đêm nồm ẩm sương mù nhưng ban ngày khô ráo, cây thiếu sáng hoặc bón thừa phân đạm.",
      prevention: "Tăng độ lưu thông không khí, đặt chậu ở nơi đón nắng sớm, tránh bón đạm quá mức và bổ sung kali tăng độ cứng vách tế bào.",
    ),
  ];
}
