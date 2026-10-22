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
  final int fertilizeFrequencyDays;
  final DateTime lastFertilized;
  final DateTime nextFertilizing;
  final int checkPestFrequencyDays;
  final DateTime lastCleaned;
  final DateTime nextCheckPest;
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
    this.fertilizeFrequencyDays = 20,
    DateTime? lastFertilized,
    DateTime? nextFertilizing,
    this.checkPestFrequencyDays = 3,
    DateTime? lastCleaned,
    DateTime? nextCheckPest,
    this.healthStatus = 'Khỏe mạnh',
    this.notes = '',
    this.wikiData = const {},
    required this.createdAt,
  })  : lastFertilized = lastFertilized ?? lastWatered,
        nextFertilizing = nextFertilizing ?? (lastFertilized ?? lastWatered).add(Duration(days: fertilizeFrequencyDays)),
        lastCleaned = lastCleaned ?? lastWatered,
        nextCheckPest = nextCheckPest ?? (lastCleaned ?? lastWatered).add(Duration(days: checkPestFrequencyDays));

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

  // Kiểm tra xem cây đã đến hạn bón phân chưa
  bool get isNeedsFertilizer {
    if (fertilizeFrequencyDays <= 0) return false;
    final now = DateTime.now();
    return now.isAfter(nextFertilizing) || nextFertilizing.difference(now).inHours <= 12;
  }

  int get daysUntilFertilizer {
    if (fertilizeFrequencyDays <= 0) return 0;
    final now = DateTime.now();
    final diff = nextFertilizing.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }

  // Kiểm tra xem cần kiểm tra sâu bệnh / lau lá không
  bool get isNeedsClean {
    if (checkPestFrequencyDays <= 0) return false;
    final now = DateTime.now();
    return now.isAfter(nextCheckPest) || nextCheckPest.difference(now).inHours <= 12;
  }

  int get daysUntilCheckPest {
    if (checkPestFrequencyDays <= 0) return 0;
    final now = DateTime.now();
    final diff = nextCheckPest.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }

  // Tính toán mức độ ẩm đất giả lập (1.0 = Đầy đủ ẩm, 0.0 = Rất khô)
  double get estimatedSoilMoisture {
    final now = DateTime.now();
    final elapsedHours = now.difference(lastWatered).inHours;
    final totalHours = waterFrequencyDays * 24;
    if (totalHours <= 0) return 0.5;
    final ratio = 1.0 - (elapsedHours / totalHours);
    return ratio.clamp(0.05, 1.0);
  }

  String get soilMoistureLabel {
    final m = estimatedSoilMoisture;
    if (m >= 0.75) return "Đất ẩm lý tưởng (80-100%)";
    if (m >= 0.45) return "Độ ẩm vừa phải (50-70%)";
    if (m >= 0.20) return "Đất bắt đầu se khô (20-40%)";
    return "Đất khô hạn (Cần tưới ngay)";
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
      'fertilizeFrequencyDays': fertilizeFrequencyDays,
      'lastFertilized': Timestamp.fromDate(lastFertilized),
      'nextFertilizing': Timestamp.fromDate(nextFertilizing),
      'checkPestFrequencyDays': checkPestFrequencyDays,
      'lastCleaned': Timestamp.fromDate(lastCleaned),
      'nextCheckPest': Timestamp.fromDate(nextCheckPest),
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

    final fertFreq = (data['fertilizeFrequencyDays'] as num?)?.toInt() ?? 20;
    final lastFertDate = parseTimestamp(data['lastFertilized'], lastWateredDate);
    final nextFertDate = parseTimestamp(
      data['nextFertilizing'],
      lastFertDate.add(Duration(days: fertFreq)),
    );

    final cleanFreq = (data['checkPestFrequencyDays'] as num?)?.toInt() ?? 3;
    final lastCleanDate = parseTimestamp(data['lastCleaned'], lastWateredDate);
    final nextCleanDate = parseTimestamp(
      data['nextCheckPest'],
      lastCleanDate.add(Duration(days: cleanFreq)),
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
      fertilizeFrequencyDays: fertFreq,
      lastFertilized: lastFertDate,
      nextFertilizing: nextFertDate,
      checkPestFrequencyDays: cleanFreq,
      lastCleaned: lastCleanDate,
      nextCheckPest: nextCleanDate,
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
    int? fertilizeFrequencyDays,
    DateTime? lastFertilized,
    DateTime? nextFertilizing,
    int? checkPestFrequencyDays,
    DateTime? lastCleaned,
    DateTime? nextCheckPest,
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
      fertilizeFrequencyDays: fertilizeFrequencyDays ?? this.fertilizeFrequencyDays,
      lastFertilized: lastFertilized ?? this.lastFertilized,
      nextFertilizing: nextFertilizing ?? this.nextFertilizing,
      checkPestFrequencyDays: checkPestFrequencyDays ?? this.checkPestFrequencyDays,
      lastCleaned: lastCleaned ?? this.lastCleaned,
      nextCheckPest: nextCheckPest ?? this.nextCheckPest,
      healthStatus: healthStatus ?? this.healthStatus,
      notes: notes ?? this.notes,
      wikiData: wikiData ?? this.wikiData,
      createdAt: createdAt,
    );
  }
}
