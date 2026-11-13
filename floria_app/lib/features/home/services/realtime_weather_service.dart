import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/current_weather_data.dart';

class RealtimeWeatherService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    ),
  );

  static const String _prefKeyCachedWeather = 'floria_cached_realtime_weather';
  static CurrentWeatherData? _memoryCache;

  /// Lấy thông tin thời tiết thực tế theo vị trí của người dùng
  static Future<CurrentWeatherData> fetchCurrentWeather() async {
    // 1. Kiểm tra cache trong bộ nhớ (còn hạn dưới 25 phút thì dùng luôn)
    if (_memoryCache != null &&
        DateTime.now().difference(_memoryCache!.updatedAt).inMinutes < 25) {
      return _memoryCache!;
    }

    // 2. Tìm tọa độ của người dùng (ưu tiên địa chỉ nhận hàng mặc định trong CSDL)
    double lat = 18.6796; // Fallback mặc định
    double lng = 105.6813;
    String locationName = 'Vị trí của bạn';

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          final addressesRaw = data['addresses'];
          if (addressesRaw is List && addressesRaw.isNotEmpty) {
            Map<String, dynamic>? selectedAddr;
            for (final a in addressesRaw) {
              if (a is Map) {
                final map = Map<String, dynamic>.from(a);
                if (map['isDefault'] == true) {
                  selectedAddr = map;
                  break;
                }
              }
            }
            if (selectedAddr == null && addressesRaw.first is Map) {
              selectedAddr = Map<String, dynamic>.from(addressesRaw.first as Map);
            }

            if (selectedAddr != null) {
              final docLat = (selectedAddr['latitude'] as num?)?.toDouble();
              final docLng = (selectedAddr['longitude'] as num?)?.toDouble();
              if (docLat != null && docLng != null) {
                lat = docLat;
                lng = docLng;
              }
              final ward = selectedAddr['wardName']?.toString();
              final district = selectedAddr['districtName']?.toString();
              final prov = selectedAddr['provinceName']?.toString();
              locationName = ward ?? district ?? prov ?? 'Vị trí của bạn';
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi đọc tọa độ người dùng cho thời tiết: $e');
    }

    // 3. Gọi Open-Meteo REST API (hoàn toàn miễn phí, không cần token)
    try {
      final url =
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,is_day';
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final current = response.data['current'] as Map<String, dynamic>?;
        if (current != null) {
          final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 27.0;
          final hum = (current['relative_humidity_2m'] as num?)?.toInt() ?? 70;
          final code = (current['weather_code'] as num?)?.toInt() ?? 1;
          final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 5.0;
          final isDay = (current['is_day'] as num?)?.toInt() == 1;

          final weather = CurrentWeatherData(
            temperature: temp,
            humidity: hum,
            weatherCode: code,
            windSpeed: wind,
            conditionText: CurrentWeatherData.codeToCondition(code, isDay: isDay),
            locationName: locationName,
            isDay: isDay,
            updatedAt: DateTime.now(),
          );

          _memoryCache = weather;
          _saveToPrefs(weather);
          return weather;
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải thời tiết Open-Meteo: $e');
    }

    // 4. Nếu lỗi mạng hoặc mất kết nối, lấy từ SharedPreferences hoặc tạo dữ liệu dự phòng
    final cached = await _loadFromPrefs();
    if (cached != null) {
      _memoryCache = cached;
      return cached;
    }

    return getFallbackWeather(DateTime.now().hour, locationName);
  }

  /// Dữ liệu dự phòng thông minh theo giờ trong ngày khi mất mạng
  static CurrentWeatherData getFallbackWeather(int hour, [String locationName = 'Vị trí của bạn']) {
    final isDay = hour >= 6 && hour < 18;
    double temp = 27.0;
    int hum = 75;
    String cond = 'Nắng sớm';
    if (!isDay) {
      temp = 25.0;
      hum = 85;
      cond = 'Đêm dịu mát';
    } else if (hour >= 11 && hour < 15) {
      temp = 32.0;
      hum = 62;
      cond = 'Nắng gắt';
    } else if (hour >= 15 && hour < 18) {
      temp = 29.0;
      hum = 70;
      cond = 'Thoáng đãng';
    }

    return CurrentWeatherData(
      temperature: temp,
      humidity: hum,
      weatherCode: 1,
      windSpeed: 6.0,
      conditionText: cond,
      locationName: locationName,
      isDay: isDay,
      updatedAt: DateTime.now(),
    );
  }

  static Future<void> _saveToPrefs(CurrentWeatherData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        'temperature': data.temperature,
        'humidity': data.humidity,
        'weatherCode': data.weatherCode,
        'windSpeed': data.windSpeed,
        'conditionText': data.conditionText,
        'locationName': data.locationName,
        'isDay': data.isDay,
        'updatedAt': data.updatedAt.toIso8601String(),
      };
      await prefs.setString(_prefKeyCachedWeather, jsonEncode(map));
    } catch (_) {}
  }

  static Future<CurrentWeatherData?> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKeyCachedWeather);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CurrentWeatherData(
        temperature: (map['temperature'] as num).toDouble(),
        humidity: (map['humidity'] as num).toInt(),
        weatherCode: (map['weatherCode'] as num).toInt(),
        windSpeed: (map['windSpeed'] as num).toDouble(),
        conditionText: map['conditionText'].toString(),
        locationName: (map['locationName'] ?? 'Vị trí của bạn').toString(),
        isDay: map['isDay'] != false,
        updatedAt: DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

