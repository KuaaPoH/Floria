import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý cài đặt hiển thị toàn app: Giao diện tối & Ngôn ngữ giao diện (Hub).
/// Lưu bền vững vào SharedPreferences.
class AppSettingsProvider extends ChangeNotifier {
  static const _kDarkMode = 'settings_dark_mode';
  static const _kLanguage = 'settings_language';

  bool _isDark = false;
  String _languageCode = 'vi';

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;
  String get languageCode => _languageCode;
  bool get isEnglish => _languageCode == 'en';
  Locale get locale => Locale(_languageCode);

  /// Đọc cài đặt đã lưu (gọi trước runApp để tránh nháy giao diện).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_kDarkMode) ?? false;
    _languageCode = prefs.getString(_kLanguage) ?? 'vi';
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, value);
  }

  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, code);
  }
}

