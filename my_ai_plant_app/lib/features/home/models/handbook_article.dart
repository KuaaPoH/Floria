import 'package:cloud_firestore/cloud_firestore.dart';

class HandbookBlock {
  final String type; // 'text', 'image', 'tip'
  final String value;
  final String? caption;

  HandbookBlock({
    required this.type,
    required this.value,
    this.caption,
  });

  factory HandbookBlock.fromMap(Map<String, dynamic> map) {
    return HandbookBlock(
      type: map['type'] ?? 'text',
      value: map['value'] ?? '',
      caption: map['caption'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'value': value,
      if (caption != null) 'caption': caption,
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
  });

  factory HandbookArticle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawBlocks = data['blocks'] as List<dynamic>? ?? [];

    return HandbookArticle(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? 'Mẹo chăm cây',
      readTime: data['readTime'] ?? '3 phút đọc',
      author: data['author'] ?? 'Ban biên tập Floria',
      coverImage: data['coverImage'] ?? '',
      summary: data['summary'] ?? '',
      blocks: rawBlocks
          .map((b) => HandbookBlock.fromMap(Map<String, dynamic>.from(b)))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
    };
  }
}
