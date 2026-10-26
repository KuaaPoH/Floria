import 'package:cloud_firestore/cloud_firestore.dart';

/// Model Hồ sơ bệnh học lưu trữ trên CSDL Firestore
class DiseaseInfo {
  final String id; // 'Anthracnose', 'Bacterial_Blight', 'Healthy', 'Leaf_Spot', 'Powdery_Mildew'
  final String nameVi;
  final String nameEn;
  final String severity; // 'Bình thường', 'Cảnh báo', 'Nguy hiểm'
  final String pathogen; // Tác nhân gây bệnh (chủng nấm, vi khuẩn, hoặc sinh trưởng bình thường)
  final String mechanism; // Cơ chế gây hại & xâm nhiễm tế bào lá
  final String favorableConditions; // Điều kiện môi trường thuận lợi phát sinh mầm bệnh
  final String prevention; // Biện pháp phòng ngừa canh tác cách ly

  const DiseaseInfo({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.severity,
    required this.pathogen,
    required this.mechanism,
    required this.favorableConditions,
    required this.prevention,
  });

  factory DiseaseInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DiseaseInfo(
      id: doc.id,
      nameVi: data['nameVi'] ?? '',
      nameEn: data['nameEn'] ?? doc.id,
      severity: data['severity'] ?? 'Cảnh báo',
      pathogen: data['pathogen'] ?? data['cause'] ?? 'Chưa xác định',
      mechanism: data['mechanism'] ?? '',
      favorableConditions: data['favorableConditions'] ?? '',
      prevention: data['prevention'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameVi': nameVi,
      'nameEn': nameEn,
      'severity': severity,
      'pathogen': pathogen,
      'mechanism': mechanism,
      'favorableConditions': favorableConditions,
      'prevention': prevention,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
