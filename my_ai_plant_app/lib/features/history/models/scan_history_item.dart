import 'package:cloud_firestore/cloud_firestore.dart';

class ScanHistoryItem {
  final String id;
  final String userId;
  final String type; // 'plant_discovery' | 'disease_diagnosis'
  final String prediction;
  final String predictionVi;
  final double confidence;
  final String modelUsed;
  final String severity;
  final String severityVi;
  final String cause;
  final List<String> treatmentSteps;
  final String plantName;
  final String? imageUrl;
  final DateTime timestamp;

  ScanHistoryItem({
    required this.id,
    this.userId = '',
    this.type = 'plant_discovery',
    required this.prediction,
    this.predictionVi = '',
    this.confidence = 0.0,
    this.modelUsed = '',
    this.severity = 'info',
    this.severityVi = '',
    this.cause = '',
    this.treatmentSteps = const [],
    this.plantName = '',
    this.imageUrl,
    required this.timestamp,
  });

  bool get isDisease => type == 'disease_diagnosis';

  bool get isHealthy =>
      prediction.toLowerCase() == 'healthy' ||
      predictionVi.toLowerCase().contains('khỏe mạnh');

  String get cleanPrediction {
    String p = prediction;
    if (p.contains('___')) {
      p = p.split('___').last;
    }
    return p.replaceAll('_', ' ').trim();
  }

  String get displayName {
    if (predictionVi.isNotEmpty) return predictionVi;
    return cleanPrediction;
  }

  factory ScanHistoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is num) return DateTime.fromMillisecondsSinceEpoch(val.toInt());
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    double parseConfidence(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    List<String> parseSteps(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    // Xác định type
    String t = data['type']?.toString() ?? '';
    if (t.isEmpty) {
      // Nếu có severity hoặc treatmentSteps hoặc plantName -> là disease_diagnosis
      if (data['severity'] != null ||
          data['treatmentSteps'] != null ||
          data['plantName'] != null) {
        t = 'disease_diagnosis';
      } else {
        t = 'plant_discovery';
      }
    }

    return ScanHistoryItem(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      type: t,
      prediction: data['prediction']?.toString() ?? '',
      predictionVi: data['predictionVi']?.toString() ?? '',
      confidence: parseConfidence(data['confidence']),
      modelUsed: data['modelUsed']?.toString() ?? '',
      severity: data['severity']?.toString() ?? (t == 'disease_diagnosis' ? 'warning' : 'info'),
      severityVi: data['severityVi']?.toString() ?? '',
      cause: data['cause']?.toString() ?? '',
      treatmentSteps: parseSteps(data['treatmentSteps']),
      plantName: data['plantName']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString(),
      timestamp: parseTimestamp(data['timestamp']),
    );
  }
}
