import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/weather_widget_config.dart';

class WeatherWidgetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'HomeWeatherWidgets';

  /// Stream danh sách Ảnh nền & Câu thoại biên tập từ Firestore
  static Stream<List<WeatherWidgetConfig>> streamConfigs() {
    return _firestore.collection(collectionName).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        seedDefaultConfigsIfNeeded();
        return defaultConfigs;
      }
      return snapshot.docs.map((doc) => WeatherWidgetConfig.fromFirestore(doc)).toList();
    });
  }

  /// Lấy ảnh và câu thoại phù hợp theo giờ (ưu tiên Firestore, có fallback nếu mất mạng)
  static WeatherWidgetConfig getConfigForHour(List<WeatherWidgetConfig>? liveConfigs, int hour) {
    final configs = (liveConfigs != null && liveConfigs.isNotEmpty) ? liveConfigs : defaultConfigs;
    for (final cfg in configs) {
      if (cfg.startHour <= cfg.endHour) {
        if (hour >= cfg.startHour && hour < cfg.endHour) return cfg;
      } else {
        // Khung giờ qua đêm (ví dụ: từ 18h đến 5h sáng hôm sau)
        if (hour >= cfg.startHour || hour < cfg.endHour) return cfg;
      }
    }
    return configs.first;
  }

  /// Khởi tạo dữ liệu ảnh và câu thoại biên tập mẫu vào Firestore nếu chưa có
  static Future<void> seedDefaultConfigsIfNeeded() async {
    try {
      final snap = await _firestore.collection(collectionName).limit(1).get();
      if (snap.docs.isEmpty) {
        final batch = _firestore.batch();
        for (final config in defaultConfigs) {
          final docRef = _firestore.collection(collectionName).doc(config.id);
          batch.set(docRef, config.toMap());
        }
        await batch.commit();
        debugPrint("Đã khởi tạo thành công ${defaultConfigs.length} cấu hình Ảnh & Câu thoại vào Firestore.");
      }
    } catch (e) {
      debugPrint("Lỗi khi seed Widget ảnh và câu thoại vào Firestore: $e");
    }
  }

  /// 4 cấu hình ảnh nền và câu thoại biên tập mặc định theo khung giờ
  static const List<WeatherWidgetConfig> defaultConfigs = [
    WeatherWidgetConfig(
      id: "morning",
      startHour: 5,
      endHour: 11,
      badgeText: "Biên tập cho sáng nay",
      mainTitle: "Chăm vừa đủ, để góc\nxanh luôn đẹp",
      advice: "Tưới gốc vào sáng sớm giúp rễ hấp thụ tối đa mà không lo đọng nước nấm mốc.",
      heroImageUrl: "https://i.ibb.co/jZRfHvS4/93b8d9ffa9c5.jpg",
    ),
    WeatherWidgetConfig(
      id: "midday",
      startHour: 11,
      endHour: 15,
      badgeText: "Khung giờ trưa",
      mainTitle: "Tránh nắng trực tiếp,\ngiữ ẩm cho rễ",
      advice: "Tránh tưới xối lên mặt lá giữa trưa nắng để ngăn ngừa hiện tượng thấu kính cháy lá.",
      heroImageUrl: "https://i.ibb.co/gZDbqPT9/4944f95d57e2.jpg",
    ),
    WeatherWidgetConfig(
      id: "afternoon",
      startHour: 15,
      endHour: 18,
      badgeText: "Khung giờ chiều mát",
      mainTitle: "Thời điểm vàng để\ntưới nước và bón lá",
      advice: "Không khí dịu mát thích hợp để kiểm tra độ ẩm đất và phun phân bón vi lượng qua lá.",
      heroImageUrl: "https://i.ibb.co/TxyZTh3x/6ba34f5fae98.jpg",
    ),
    WeatherWidgetConfig(
      id: "night",
      startHour: 18,
      endHour: 5,
      badgeText: "Góc xanh buổi tối",
      mainTitle: "Không gian nghỉ ngơi,\ncây nhả oxy trong lành",
      advice: "Cây bước vào giai đoạn hô hấp ban đêm, hạn chế tưới đọng lá để phòng ngừa nấm bệnh.",
      heroImageUrl: "https://i.ibb.co/Kcd7vQ0y/d0da7c64e5ac.jpg",
    ),
  ];
}
