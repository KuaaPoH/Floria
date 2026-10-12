import 'package:flutter/foundation.dart';

class AppConstants {
  // URL của Spring Boot Backend trung tâm
  // Tự động nhận diện nền tảng: Web dùng localhost:8080, thiết bị di động dùng IP mạng LAN
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }
    return 'http://192.168.1.88:8080/api';
  }

  static String get scanDiseaseUrl => '$baseUrl/scan-disease';
  static String get pingUrl => '$baseUrl/ping';
  static String get authSyncUrl => '$baseUrl/auth/sync';
}
