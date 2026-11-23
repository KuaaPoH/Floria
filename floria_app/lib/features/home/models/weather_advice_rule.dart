import 'package:cloud_firestore/cloud_firestore.dart';
import 'current_weather_data.dart';

/// Model quy tắc thích ứng vi khí hậu thông minh (Phương Án A)
class WeatherAdviceRule {
  final String id;
  final String title;
  final String badgeText;
  final String advice;
  final String conditionType; // 'temperature_high', 'temperature_low', 'humidity_high', 'humidity_low', 'rain', 'storm_wind'
  final double? minTemp;
  final double? maxTemp;
  final int? minHumidity;
  final int? maxHumidity;
  final List<int> weatherCodes;
  final double? minWindSpeed;
  final String iconName;
  final bool active;
  final int priority;
  final int order;

  const WeatherAdviceRule({
    required this.id,
    required this.title,
    required this.badgeText,
    required this.advice,
    required this.conditionType,
    this.minTemp,
    this.maxTemp,
    this.minHumidity,
    this.maxHumidity,
    this.weatherCodes = const [],
    this.minWindSpeed,
    this.iconName = 'thermostat',
    this.active = true,
    this.priority = 50,
    this.order = 0,
  });

  factory WeatherAdviceRule.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final rawCodes = d['weatherCodes'];
    List<int> codes = [];
    if (rawCodes is List) {
      codes = rawCodes.map((e) => (e as num).toInt()).toList();
    }

    return WeatherAdviceRule(
      id: doc.id,
      title: (d['title'] ?? d['name'] ?? '').toString(),
      badgeText: (d['badgeText'] ?? 'Khuyến nghị vi khí hậu').toString(),
      advice: (d['advice'] ?? d['tip'] ?? '').toString(),
      conditionType: (d['conditionType'] ?? 'temperature_high').toString(),
      minTemp: (d['minTemp'] as num?)?.toDouble(),
      maxTemp: (d['maxTemp'] as num?)?.toDouble(),
      minHumidity: (d['minHumidity'] as num?)?.toInt(),
      maxHumidity: (d['maxHumidity'] as num?)?.toInt(),
      weatherCodes: codes,
      minWindSpeed: (d['minWindSpeed'] as num?)?.toDouble(),
      iconName: (d['iconName'] ?? 'thermostat').toString(),
      active: d['active'] != false,
      priority: (d['priority'] as num?)?.toInt() ?? 50,
      order: (d['order'] as num?)?.toInt() ?? 0,
    );
  }

  /// Kiểm tra xem điều kiện thời tiết thực tế có khớp với quy tắc này hay không
  bool matches(CurrentWeatherData weather) {
    if (!active) return false;

    switch (conditionType) {
      case 'temperature_high':
        return weather.temperature >= (minTemp ?? 33.0);

      case 'temperature_low':
        return weather.temperature < (maxTemp ?? 18.0);

      case 'humidity_high':
        return weather.humidity >= (minHumidity ?? 85);

      case 'humidity_low':
        return weather.humidity <= (maxHumidity ?? 50);

      case 'rain':
        final codes = weatherCodes.isNotEmpty ? weatherCodes : [51, 53, 55, 61, 63, 65, 80, 81, 82];
        return codes.contains(weather.weatherCode) || weather.humidity >= (minHumidity ?? 85);

      case 'storm_wind':
        final codes = weatherCodes.isNotEmpty ? weatherCodes : [95, 96, 99];
        return codes.contains(weather.weatherCode) || weather.windSpeed >= (minWindSpeed ?? 25.0);

      default:
        return false;
    }
  }
}
