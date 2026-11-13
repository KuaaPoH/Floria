import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSessionMessage {
  final bool isUser;
  final String text;
  final DateTime timestamp;
  final List<String> recommendedProductIds;

  ChatSessionMessage({
    required this.isUser,
    required this.text,
    DateTime? timestamp,
    this.recommendedProductIds = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatSessionMessage.fromMap(Map<String, dynamic> map) {
    DateTime ts = DateTime.now();
    if (map['timestamp'] is Timestamp) {
      ts = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int);
    }

    List<String> products = [];
    if (map['recommendedProductIds'] is List) {
      products = (map['recommendedProductIds'] as List).map((e) => e.toString()).toList();
    }

    return ChatSessionMessage(
      isUser: map['isUser'] == true,
      text: map['text']?.toString() ?? '',
      timestamp: ts,
      recommendedProductIds: products,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isUser': isUser,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'recommendedProductIds': recommendedProductIds,
    };
  }
}

class ChatSession {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatSessionMessage> messages;

  ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  factory ChatSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    List<ChatSessionMessage> msgs = [];
    if (data['messages'] is List) {
      msgs = (data['messages'] as List)
          .map((m) => ChatSessionMessage.fromMap(m as Map<String, dynamic>))
          .toList();
    }

    return ChatSession(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      title: data['title']?.toString() ?? 'Cuộc trò chuyện mới',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      messages: msgs,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'messages': messages.map((m) => m.toMap()).toList(),
    };
  }
}
