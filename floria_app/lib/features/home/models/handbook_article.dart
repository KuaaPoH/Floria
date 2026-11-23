import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseFlexibleHandbookDate(dynamic raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  if (raw is String && raw.trim().isNotEmpty) {
    return DateTime.tryParse(raw.trim()) ?? DateTime.now();
  }
  return DateTime.now();
}

class HandbookBlock {
  final String type; // 'text', 'image', 'tip', 'heading', 'quote', 'warning', 'bullets', 'numbered'
  final String value;
  final String? caption;
  final List<String> items;

  HandbookBlock({
    required this.type,
    required this.value,
    this.caption,
    this.items = const [],
  });

  factory HandbookBlock.fromMap(Map<String, dynamic> map) {
    return HandbookBlock(
      type: (map['type'] ?? 'text').toString(),
      value: (map['value'] ?? map['text'] ?? map['src'] ?? '').toString(),
      caption: map['caption']?.toString(),
      items: (map['items'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'value': value,
      if (caption != null) 'caption': caption,
      if (items.isNotEmpty) 'items': items,
    };
  }
}

class HandbookArticle {
  final String id;
  final String title;
  final String category;
  final String readTime;
  final String author;
  final String coverImage;
  final String summary;
  final List<HandbookBlock> blocks;
  final DateTime createdAt;
  final String status;
  final bool visible;

  HandbookArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.readTime,
    required this.author,
    required this.coverImage,
    required this.summary,
    required this.blocks,
    required this.createdAt,
    this.status = 'published',
    this.visible = true,
  });

  bool get isPublished => status != 'draft' && visible;

  String get formattedDate =>
      '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';

  factory HandbookArticle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawBlocks = data['blocks'] as List<dynamic>? ?? [];

    return HandbookArticle(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      category: (data['category'] ?? 'Mẹo chăm cây').toString(),
      readTime: (data['readTime'] ?? '3 phút đọc').toString(),
      author: (data['author'] ?? 'Ban biên tập Floria').toString(),
      coverImage: (data['coverImage'] ?? data['cover'] ?? '').toString(),
      summary: (data['summary'] ?? data['excerpt'] ?? '').toString(),
      blocks: rawBlocks
          .whereType<Map>()
          .map((b) => HandbookBlock.fromMap(Map<String, dynamic>.from(b)))
          .toList(),
      createdAt: _parseFlexibleHandbookDate(data['createdAt'] ?? data['publishedAt']),
      status: (data['status'] ?? 'published').toString(),
      visible: data['visible'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'readTime': readTime,
      'author': author,
      'coverImage': coverImage,
      'summary': summary,
      'blocks': blocks.map((b) => b.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'visible': visible,
    };
  }
}
