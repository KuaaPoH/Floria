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
  final bool active; // Cho phép Admin bật/tắt hiển thị ngoài app
  final int order;

  const WeatherWidgetConfig({
    required this.id,
    required this.badgeText,
    required this.mainTitle,
    required this.advice,
    required this.heroImageUrl,
    required this.startHour,
    required this.endHour,
    this.active = true,
    this.order = 0,
  });

  factory WeatherWidgetConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final parsedStart = (data['startHour'] as num?)?.toInt() ?? 0;
    final parsedEnd = (data['endHour'] as num?)?.toInt() ?? 24;
    return WeatherWidgetConfig(
      id: doc.id,
      badgeText: (data['badgeText'] ?? '').toString(),
      mainTitle: (data['mainTitle'] ?? '').toString(),
      advice: (data['advice'] ?? '').toString(),
      heroImageUrl: (data['heroImageUrl'] ?? '').toString(),
      startHour: parsedStart,
      endHour: parsedEnd,
      active: data['active'] != false,
      order: (data['order'] as num?)?.toInt() ?? parsedStart,
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
      'active': active,
      'order': order,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
