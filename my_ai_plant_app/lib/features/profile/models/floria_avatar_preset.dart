import 'package:flutter/material.dart';

class FloriaAvatarPreset {
  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color iconColor;

  const FloriaAvatarPreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    this.iconColor = Colors.white,
  });

  static const List<FloriaAvatarPreset> allPresets = [
    FloriaAvatarPreset(
      id: 'sprout',
      name: 'Mầm Xanh Floria',
      subtitle: 'Khởi đầu xanh tươi',
      icon: Icons.spa_rounded,
      gradientColors: [Color(0xFF2E6F40), Color(0xFF68B684)],
    ),
    FloriaAvatarPreset(
      id: 'monstera',
      name: 'Trầu Bà Nam Mỹ',
      subtitle: 'Đam mê cây trong nhà',
      icon: Icons.eco_rounded,
      gradientColors: [Color(0xFF1B4332), Color(0xFF40916C)],
    ),
    FloriaAvatarPreset(
      id: 'succulent',
      name: 'Sen Đá Cát Tường',
      subtitle: 'Bền bỉ & Tinh tế',
      icon: Icons.filter_vintage_rounded,
      gradientColors: [Color(0xFF2B5B84), Color(0xFF6BA3BE)],
    ),
    FloriaAvatarPreset(
      id: 'cactus',
      name: 'Xương Rồng Sa Mạc',
      subtitle: 'Kiên cường & Độc lập',
      icon: Icons.nature_rounded,
      gradientColors: [Color(0xFF2D6A4F), Color(0xFF74C69D)],
    ),
    FloriaAvatarPreset(
      id: 'sunflower',
      name: 'Hướng Dương Rực Rỡ',
      subtitle: 'Năng lượng tích cực',
      icon: Icons.wb_sunny_rounded,
      gradientColors: [Color(0xFFD9531E), Color(0xFFF4A261)],
    ),
    FloriaAvatarPreset(
      id: 'bonsai',
      name: 'Bonsai Trí Tuệ',
      subtitle: 'Điềm tĩnh & Kinh nghiệm',
      icon: Icons.park_rounded,
      gradientColors: [Color(0xFF3F4E4F), Color(0xFF2C3639)],
    ),
  ];

  static FloriaAvatarPreset getById(String id) {
    final cleanId = id.replaceFirst('preset:', '').trim();
    return allPresets.firstWhere(
      (p) => p.id == cleanId,
      orElse: () => allPresets.first,
    );
  }
}

