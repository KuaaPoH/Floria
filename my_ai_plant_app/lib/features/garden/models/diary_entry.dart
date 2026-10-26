import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntry {
  final String id;
  final String plantId;
  final String userId;
  final String type; // 'user' hoặc 'system'
  final String category; // 'care', 'health', 'growth', 'note'
  final String title;
  final String content;
  final String? imageUrl;
  final List<String> imageUrls;
  final String tag;
  final int tagBgColor;
  final int tagTextColor;
  final DateTime timestamp;

  DiaryEntry({
    required this.id,
    required this.plantId,
    required this.userId,
    required this.type,
    required this.category,
    required this.title,
    required this.content,
    this.imageUrl,
    List<String>? imageUrls,
    required this.tag,
    required this.tagBgColor,
    required this.tagTextColor,
    required this.timestamp,
  }) : imageUrls = imageUrls ?? (imageUrl != null && imageUrl.isNotEmpty ? [imageUrl] : []);

  bool get isSystem => type == 'system';
  bool get isUser => type == 'user';

  factory DiaryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawList = data['imageUrls'] as List<dynamic>?;
    final List<String> list = rawList != null
        ? rawList.map((e) => e.toString()).toList()
        : (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
            ? [data['imageUrl'].toString()]
            : []);

    return DiaryEntry(
      id: doc.id,
      plantId: data['plantId'] ?? '',
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'user',
      category: data['category'] ?? 'note',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? (list.isNotEmpty ? list.first : null),
      imageUrls: list,
      tag: data['tag'] ?? 'Ghi chú',
      tagBgColor: data['tagBgColor'] ?? 0xFFE5F4EA,
      tagTextColor: data['tagTextColor'] ?? 0xFF1E3A24,
      timestamp: parseTime(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plantId': plantId,
      'userId': userId,
      'type': type,
      'category': category,
      'title': title,
      'content': content,
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : imageUrl,
      'imageUrls': imageUrls,
      'tag': tag,
      'tagBgColor': tagBgColor,
      'tagTextColor': tagTextColor,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
