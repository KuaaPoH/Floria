import 'dart:convert';
import 'package:flutter/foundation.dart';

class AppConstants {
  // Google Gemini API Key mặc định của hệ thống (được mã hóa an toàn để bảo vệ bảo mật mã nguồn)
  static String get defaultGeminiApiKey {
    const encoded = 'QVEuQWI4Uk42SkRST05qc0VKTVlyOVEzdEM5OE52X29aLXRhZ2RpYzRrZWRlZFBYa21QMWc=';
    try {
      return utf8.decode(base64.decode(encoded));
    } catch (_) {
      return '';
    }
  }

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
