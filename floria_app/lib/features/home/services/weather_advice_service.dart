import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/current_weather_data.dart';
import '../models/weather_advice_rule.dart';

class WeatherAdviceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lắng nghe luồng dữ liệu thời gian thực từ Firestore `WeatherAdviceRules`
  static Stream<List<WeatherAdviceRule>> streamRules() {
    return _firestore
      .collection('WeatherAdviceRules')
      .where('active', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs.map((doc) => WeatherAdviceRule.fromFirestore(doc)).toList();
        list.sort((a, b) => b.priority.compareTo(a.priority));
        return list;
      })
      .handleError((e) {
        debugPrint('Lỗi tải WeatherAdviceRules từ Firestore: $e');
        return fallbackRules;
      });
  }

  /// Bộ quy tắc ngoại tuyến dự phòng (Offline Fallback Rules)
  static final List<WeatherAdviceRule> fallbackRules = [
    const WeatherAdviceRule(
      id: 'fallback_storm',
      title: 'Dông lốc & Gió mạnh',
      badgeText: 'Cảnh báo dông sét • Che chắn cây',
      advice: 'Thời tiết dông lốc, gió giật: Đưa ngay các chậu cây treo ban công và cây lá to giòn vào nơi kín gió để tránh gãy cành, dập phiến lá.',
      conditionType: 'storm_wind',
      weatherCodes: [95, 96, 99],
      minWindSpeed: 25.0,
      iconName: 'thunderstorm',
      priority: 100,
    ),
    const WeatherAdviceRule(
      id: 'fallback_heat',
      title: 'Nắng nóng gay gắt',
      badgeText: 'Nhiệt độ cao • Chống sốc nhiệt',
      advice: 'Nhiệt độ ngoài trời rất cao: Tuyệt đối tránh tưới xối nước vào giữa trưa vì nước nóng dễ luộc rễ. Nên dời cây cách xa cửa kính hấp xạ nhiệt.',
      conditionType: 'temperature_high',
      minTemp: 33.0,
      iconName: 'thermostat',
      priority: 90,
    ),
    const WeatherAdviceRule(
      id: 'fallback_cold',
      title: 'Thời tiết trở lạnh',
      badgeText: 'Không khí lạnh • Giữ ấm rễ',
      advice: 'Trời trở lạnh: Cây trao đổi chất chậm và hấp thụ ít nước, giảm 50% lượng tưới và dùng nước ấm vừa phải. Tránh tưới nước lạnh buốt rễ cây nhiệt đới.',
      conditionType: 'temperature_low',
      maxTemp: 18.0,
      iconName: 'ac_unit',
      priority: 85,
    ),
    const WeatherAdviceRule(
      id: 'fallback_rain',
      title: 'Mưa dầm & Độ ẩm cao',
      badgeText: 'Mưa ẩm cao • Chống thối rễ',
      advice: 'Mưa nhiều và ẩm độ rất cao: Nước đọng lâu ở kẽ lá dễ phát sinh nấm thán thư, thối nhũn. Tạm ngừng tưới đất và kiểm tra lỗ thoát nước đáy chậu.',
      conditionType: 'rain',
      minHumidity: 85,
      weatherCodes: [51, 53, 55, 61, 63, 65, 80, 81, 82],
      iconName: 'water_drop',
      priority: 75,
    ),
    const WeatherAdviceRule(
      id: 'fallback_dry',
      title: 'Không khí khô hanh',
      badgeText: 'Độ ẩm thấp • Cấp ẩm vi khí hậu',
      advice: 'Độ ẩm không khí xuống thấp: Các loài cây lá mỏng (Calathea, Dương xỉ) dễ quăn giòn chóp lá. Nên phun sương tạo ẩm xung quanh hoặc gom các chậu lại gần nhau.',
      conditionType: 'humidity_low',
      maxHumidity: 50,
      iconName: 'air',
      priority: 60,
    ),
  ];

  /// Tìm mẹo vi khí hậu thích ứng có độ ưu tiên cao nhất đang thỏa mãn điều kiện thời tiết thực tế
  /// (Nếu thời tiết bình thường/ôn hòa, trả về `null` để widget hiển thị mẹo theo giờ nhịp sinh học)
  static WeatherAdviceRule? findActiveAdvice(
    CurrentWeatherData weather,
    List<WeatherAdviceRule>? rules,
  ) {
    final candidateRules = (rules != null && rules.isNotEmpty) ? rules : fallbackRules;

    for (final rule in candidateRules) {
      if (rule.matches(weather)) {
        return rule;
      }
    }
    return null;
  }
}
