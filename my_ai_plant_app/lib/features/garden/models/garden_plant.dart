import 'package:cloud_firestore/cloud_firestore.dart';

class GardenPlant {
  final String id;
  final String userId;
  final String gardenId;
  final String nameVi;
  final String scientificName;
  final String nickname;
  final String zone;
  final String? imageUrl;
  final String plantType;
  final int waterFrequencyDays;
  final String reminderTime;
  final DateTime lastWatered;
  final DateTime nextWatering;
  final String healthStatus;
  final String notes;
  final Map<String, dynamic> wikiData;
  final DateTime createdAt;

  GardenPlant({
    required this.id,
    this.userId = '',
    this.gardenId = '',
    required this.nameVi,
    required this.scientificName,
    required this.nickname,
    required this.zone,
    this.imageUrl,
    this.plantType = 'Cây cảnh',
    this.waterFrequencyDays = 3,
    this.reminderTime = '07:00',
    required this.lastWatered,
    required this.nextWatering,
    this.healthStatus = 'Khỏe mạnh',
    this.notes = '',
    this.wikiData = const {},
    required this.createdAt,
  });

  // Kiểm tra xem cây đã đến hạn cần tưới chưa
  bool get isNeedsWater {
    final now = DateTime.now();
    return now.isAfter(nextWatering) || nextWatering.difference(now).inHours <= 12;
  }

  // Số ngày còn lại đến lần tưới tiếp theo
  int get daysUntilWater {
    final now = DateTime.now();
    final diff = nextWatering.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }

  // Chuyển sang JSON để lưu vào Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'gardenId': gardenId,
      'nameVi': nameVi,
      'scientificName': scientificName,
      'nickname': nickname,
      'zone': zone,
      'imageUrl': imageUrl,
      'plantType': plantType,
      'waterFrequencyDays': waterFrequencyDays,
      'reminderTime': reminderTime,
      'lastWatered': Timestamp.fromDate(lastWatered),
      'nextWatering': Timestamp.fromDate(nextWatering),
      'healthStatus': healthStatus,
      'notes': notes,
      'wikiData': wikiData,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Khởi tạo từ Firestore Document
  factory GardenPlant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseTimestamp(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    final lastWateredDate = parseTimestamp(data['lastWatered'], DateTime.now());
    final freq = (data['waterFrequencyDays'] as num?)?.toInt() ?? 3;
    final nextWateringDate = parseTimestamp(
      data['nextWatering'],
      lastWateredDate.add(Duration(days: freq)),
    );

    return GardenPlant(
      id: doc.id,
      userId: data['userId'] ?? '',
      gardenId: data['gardenId'] ?? '',
      nameVi: data['nameVi'] ?? 'Cây cảnh',
      scientificName: data['scientificName'] ?? '',
      nickname: data['nickname'] ?? (data['nameVi'] ?? 'Cây của tôi'),
      zone: data['zone'] ?? 'Phòng khách',
      imageUrl: data['imageUrl'],
      plantType: data['plantType'] ?? 'Cây cảnh',
      waterFrequencyDays: freq,
      reminderTime: data['reminderTime'] ?? '07:00',
      lastWatered: lastWateredDate,
      nextWatering: nextWateringDate,
      healthStatus: data['healthStatus'] ?? 'Khỏe mạnh',
      notes: data['notes'] ?? '',
      wikiData: data['wikiData'] is Map ? Map<String, dynamic>.from(data['wikiData']) : {},
      createdAt: parseTimestamp(data['createdAt'], DateTime.now()),
    );
  }

  // Tạo bản sao với giá trị cập nhật
  GardenPlant copyWith({
    String? gardenId,
    String? nickname,
    String? zone,
    String? imageUrl,
    int? waterFrequencyDays,
    String? reminderTime,
    DateTime? lastWatered,
    DateTime? nextWatering,
    String? healthStatus,
    String? notes,
    Map<String, dynamic>? wikiData,
  }) {
    return GardenPlant(
      id: id,
      userId: userId,
      gardenId: gardenId ?? this.gardenId,
      nameVi: nameVi,
      scientificName: scientificName,
      nickname: nickname ?? this.nickname,
      zone: zone ?? this.zone,
      imageUrl: imageUrl ?? this.imageUrl,
      plantType: plantType,
      waterFrequencyDays: waterFrequencyDays ?? this.waterFrequencyDays,
      reminderTime: reminderTime ?? this.reminderTime,
      lastWatered: lastWatered ?? this.lastWatered,
      nextWatering: nextWatering ?? this.nextWatering,
      healthStatus: healthStatus ?? this.healthStatus,
      notes: notes ?? this.notes,
      wikiData: wikiData ?? this.wikiData,
      createdAt: createdAt,
    );
  }
}
