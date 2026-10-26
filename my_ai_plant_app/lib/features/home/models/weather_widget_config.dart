import 'package:cloud_firestore/cloud_firestore.dart';

/// Model cấu hình Ảnh nền và Câu thoại biên tập cho Widget trang chủ (lưu trên Firestore)
class WeatherWidgetConfig {
  final String id; // 'morning', 'midday', 'afternoon', 'night'
  final String badgeText; // Nhãn biên tập: "Biên tập cho sáng nay", "Góc xanh buổi tối"...
  final String mainTitle; // Câu thoại chính truyền cảm hứng
  final String advice; // Lời khuyên chăm sóc biên tập
  final String heroImageUrl; // Đường dẫn ảnh nền chất lượng cao
  final int startHour; // Giờ bắt đầu áp dụng
  final int endHour; // Giờ kết thúc

  const WeatherWidgetConfig({
    required this.id,
    required this.badgeText,
    required this.mainTitle,
    required this.advice,
    required this.heroImageUrl,
    required this.startHour,
    required this.endHour,
  });

  factory WeatherWidgetConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WeatherWidgetConfig(
      id: doc.id,
      badgeText: data['badgeText'] ?? '',
      mainTitle: data['mainTitle'] ?? '',
      advice: data['advice'] ?? '',
      heroImageUrl: data['heroImageUrl'] ?? '',
      startHour: data['startHour'] ?? 0,
      endHour: data['endHour'] ?? 24,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'badgeText': badgeText,
      'mainTitle': mainTitle,
      'advice': advice,
      'heroImageUrl': heroImageUrl,
      'startHour': startHour,
      'endHour': endHour,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
