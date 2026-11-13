import 'package:flutter/material.dart';

/// Bảng màu ngữ nghĩa (semantic) cho Light / Dark mode.
///
/// Dùng trong widget: `final c = context.colors;` rồi `c.surface`, `c.textPrimary`...
/// Màu thương hiệu (nút bấm xanh, cam cảnh báo, đỏ lỗi) giữ nguyên ở cả 2 chế độ;
/// chỉ các màu nền / chữ / viền / nền nhạt mới đổi theo theme.
@immutable
class AppColors {
  final bool isDark;

  /// Nền màn hình (Scaffold). Light: F5F7F3 / FBF9F6
  final Color background;

  /// Nền thẻ, card, sheet, dialog, AppBar. Light: trắng
  final Color surface;

  /// Nền phụ nhạt màu xanh (chip, ô thông tin, input). Light: E5F4EA / EAF5EC / E8F2E3
  final Color surfaceTint;

  /// Nền phụ trung tính (ô xám nhạt, input). Light: F3F4F1
  final Color surfaceMuted;

  /// Chữ chính / tiêu đề. Light: 1B1C1A / 1F2A21 / 191C19
  final Color textPrimary;

  /// Chữ phụ / mô tả. Light: 364534 / 444842 / 4B5563
  final Color textSecondary;

  /// Chữ mờ / gợi ý / icon phụ. Light: 6A756B / 747871 / 6B7280 / 9CA3AF
  final Color textMuted;

  /// Viền, đường kẻ chia. Light: E4E2DF / E0E5DD
  final Color border;

  /// Màu thương hiệu dùng làm NỀN nút bấm (chữ trắng bên trên). Giống nhau 2 chế độ.
  final Color primary;

  /// Màu xanh dùng cho CHỮ / ICON nhấn mạnh (sáng hơn ở dark để đủ tương phản).
  final Color primaryText;

  /// Màu đổ bóng.
  final Color shadow;

  /// Nền nhạt cho trạng thái cảnh báo / lỗi / thông tin.
  final Color warningBg;
  final Color errorBg;
  final Color infoBg;

  const AppColors._({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceTint,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.primary,
    required this.primaryText,
    required this.shadow,
    required this.warningBg,
    required this.errorBg,
    required this.infoBg,
  });

  static const light = AppColors._(
    isDark: false,
    background: Color(0xFFF5F7F3),
    surface: Colors.white,
    surfaceTint: Color(0xFFE5F4EA),
    surfaceMuted: Color(0xFFF3F4F1),
    textPrimary: Color(0xFF1B1C1A),
    textSecondary: Color(0xFF364534),
    textMuted: Color(0xFF6A756B),
    border: Color(0xFFE4E2DF),
    primary: Color(0xFF2E6F40),
    primaryText: Color(0xFF2E6F40),
    shadow: Color(0xFF17231A),
    warningBg: Color(0xFFFEF3C7),
    errorBg: Color(0xFFFDECEC),
    infoBg: Color(0xFFEAF2FF),
  );

  static const dark = AppColors._(
    isDark: true,
    background: Color(0xFF0F1511),
    surface: Color(0xFF19211B),
    surfaceTint: Color(0xFF1F3326),
    surfaceMuted: Color(0xFF232B25),
    textPrimary: Color(0xFFE6ECE6),
    textSecondary: Color(0xFFC0CCC1),
    textMuted: Color(0xFF8E9B90),
    border: Color(0xFF2E3A31),
    primary: Color(0xFF3E8055),
    primaryText: Color(0xFF7FCB95),
    shadow: Colors.black,
    warningBg: Color(0xFF3A2E12),
    errorBg: Color(0xFF3A1A1C),
    infoBg: Color(0xFF16263A),
  );
}

extension AppColorsContext on BuildContext {
  /// Bảng màu theo theme hiện tại (Light / Dark).
  AppColors get colors =>
      Theme.of(this).brightness == Brightness.dark ? AppColors.dark : AppColors.light;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

