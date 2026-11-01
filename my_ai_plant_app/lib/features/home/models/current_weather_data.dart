class CurrentWeatherData {
  final double temperature;
  final int humidity;
  final int weatherCode;
  final double windSpeed;
  final String conditionText;
  final String locationName;
  final bool isDay;
  final DateTime updatedAt;

  const CurrentWeatherData({
    required this.temperature,
    required this.humidity,
    required this.weatherCode,
    required this.windSpeed,
    required this.conditionText,
    required this.locationName,
    this.isDay = true,
    required this.updatedAt,
  });

  String get formattedTemp => '${temperature.round()}°C';
  String get formattedHumidity => 'Độ ẩm: $humidity%';

  /// Chuyển đổi mã WMO weather code sang tiếng Việt gần gũi cho người yêu cây
  /// Phân biệt rõ ràng ngày và đêm (không để ban đêm hiển thị "nắng nhẹ")
  static String codeToCondition(int code, {bool isDay = true}) {
    if (!isDay) {
      if (code == 0) return 'Đêm quang đãng';
      if (code == 1 || code == 2) return 'Đêm dịu mát • Ít mây';
      if (code == 3) return 'Đêm nhiều mây';
      if (code == 45 || code == 48) return 'Sương mù đêm';
      if (code >= 51 && code <= 55) return 'Mưa phùn đêm';
      if (code >= 61 && code <= 65) return 'Có mưa rào';
      if (code >= 80 && code <= 82) return 'Mưa rào đêm';
      if (code >= 95) return 'Dông sét đêm • Che cây';
      return 'Đêm mát mẻ';
    }

    if (code == 0) return 'Nắng đẹp';
    if (code == 1 || code == 2) return 'Nắng nhẹ • Ít mây';
    if (code == 3) return 'Trời râm mát • Nhiều mây';
    if (code == 45 || code == 48) return 'Sương mù ẩm';
    if (code >= 51 && code <= 55) return 'Mưa phùn nhẹ';
    if (code >= 61 && code <= 65) return 'Có mưa rào';
    if (code >= 80 && code <= 82) return 'Mưa ngắt quãng';
    if (code >= 95) return 'Có dông sét • Che cây';
    return 'Dịu mát';
  }
}

