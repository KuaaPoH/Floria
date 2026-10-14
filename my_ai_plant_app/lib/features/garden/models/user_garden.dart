import 'package:cloud_firestore/cloud_firestore.dart';

class UserGarden {
  final String id;
  final String userId;
  final String name;
  final String environment; // "Trong nhà", "Ngoài trời", "Văn phòng", "Nhà kính"
  final String lightCondition; // "Sáng trực tiếp", "Sáng gián tiếp", "Ánh sáng trung bình", "Ánh sáng yếu"
  final DateTime createdAt;

  UserGarden({
    required this.id,
    required this.userId,
    required this.name,
    required this.environment,
    required this.lightCondition,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'environment': environment,
      'lightCondition': lightCondition,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserGarden.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseTimestamp(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    return UserGarden(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Khu vườn của tôi',
      environment: data['environment'] ?? 'Trong nhà',
      lightCondition: data['lightCondition'] ?? 'Sáng gián tiếp',
      createdAt: parseTimestamp(data['createdAt'], DateTime.now()),
    );
  }

  UserGarden copyWith({
    String? id,
    String? name,
    String? environment,
    String? lightCondition,
  }) {
    return UserGarden(
      id: id ?? this.id,
      userId: userId,
      name: name ?? this.name,
      environment: environment ?? this.environment,
      lightCondition: lightCondition ?? this.lightCondition,
      createdAt: createdAt,
    );
  }
}
