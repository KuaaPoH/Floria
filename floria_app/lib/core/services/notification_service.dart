import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/garden/models/garden_plant.dart';
import '../../features/home/screens/main_navigation_screen.dart';
import 'push_notification_service.dart';

class NotificationService {
  static const String _prefKeyEnabled = 'notifications_enabled';
  static const String _prefKeyPrefixNotified = 'notified_plant_';

  static const String _prefKeyMorningTime = 'reminder_morning_time';
  static const String _prefKeyEveningTime = 'reminder_evening_time';
  static const String _prefKeyQuietEnabled = 'reminder_quiet_enabled';
  static const String _prefKeyQuietStart = 'reminder_quiet_start';
  static const String _prefKeyQuietEnd = 'reminder_quiet_end';

  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _isLocalNotificationsInitialized = false;

  /// Khởi tạo hệ thống thông báo đẩy cấp hệ điều hành (Android / iOS)
  static Future<void> initSystemNotifications() async {
    if (_isLocalNotificationsInitialized) return;
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Đã chạm vào thông báo hệ thống: ${response.payload}');
          // Tự động điều hướng đến tab Khu vườn khi chạm vào thông báo
          final nav = PushNotificationService.navigatorKey.currentState;
          if (nav != null) {
            nav.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const MainNavigationScreen(initialIndex: 1),
              ),
              (route) => false,
            );
          }
        },
      );

      final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'floria_care_channel',
            'Lịch chăm sóc cây Floria',
            description: 'Thông báo nhắc nhở tưới nước, bón phân và chăm sóc cây từ Floria',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
      }

      _isLocalNotificationsInitialized = true;
    } catch (e) {
      debugPrint('Lỗi khởi tạo flutter_local_notifications: $e');
    }
  }

  /// Bắn thông báo đẩy thật lên thanh trạng thái của thiết bị Android/iOS
  static Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_isLocalNotificationsInitialized) {
        await initSystemNotifications();
      }

      final androidDetails = AndroidNotificationDetails(
        'floria_care_channel',
        'Lịch chăm sóc cây Floria',
        channelDescription: 'Thông báo nhắc nhở tưới nước, bón phân và chăm sóc cây từ Floria',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'Floria Nhắc nhở',
        ),
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Lỗi phát thông báo hệ thống: $e');
    }
  }

  // ===== Tùy chọn nhắc nhở toàn cục (cache đồng bộ để dùng ngay khi thêm cây mới) =====
  static String cachedMorningTime = '07:30';
  static String cachedEveningTime = '17:30';
  static bool cachedQuietEnabled = false;
  static String cachedQuietStart = '22:00';
  static String cachedQuietEnd = '06:00';

  /// Tải các tùy chọn nhắc nhở từ bộ nhớ máy vào cache
  static Future<void> loadPreferences() async {
    unawaited(initSystemNotifications());
    final prefs = await SharedPreferences.getInstance();
    cachedMorningTime = prefs.getString(_prefKeyMorningTime) ?? '07:30';
    cachedEveningTime = prefs.getString(_prefKeyEveningTime) ?? '17:30';
    cachedQuietEnabled = prefs.getBool(_prefKeyQuietEnabled) ?? false;
    cachedQuietStart = prefs.getString(_prefKeyQuietStart) ?? '22:00';
    cachedQuietEnd = prefs.getString(_prefKeyQuietEnd) ?? '06:00';
  }

  static Future<void> setMorningTime(String time) async {
    cachedMorningTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyMorningTime, time);
  }

  static Future<void> setEveningTime(String time) async {
    cachedEveningTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyEveningTime, time);
  }

  static Future<void> setQuietHours({bool? enabled, String? start, String? end}) async {
    final prefs = await SharedPreferences.getInstance();
    if (enabled != null) {
      cachedQuietEnabled = enabled;
      await prefs.setBool(_prefKeyQuietEnabled, enabled);
    }
    if (start != null) {
      cachedQuietStart = start;
      await prefs.setString(_prefKeyQuietStart, start);
    }
    if (end != null) {
      cachedQuietEnd = end;
      await prefs.setString(_prefKeyQuietEnd, end);
    }
  }

  /// Đổi chuỗi "HH:mm" thành số phút trong ngày
  static int timeToMinutes(String time, {int fallback = 7 * 60}) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return fallback;
      return int.parse(parts[0].trim()) * 60 + int.parse(parts[1].trim());
    } catch (_) {
      return fallback;
    }
  }

  /// Thời điểm hiện tại có nằm trong khung giờ Không làm phiền không (hỗ trợ khung qua nửa đêm)
  static bool isInQuietHours([DateTime? at]) {
    if (!cachedQuietEnabled) return false;
    final now = at ?? DateTime.now();
    final current = now.hour * 60 + now.minute;
    final start = timeToMinutes(cachedQuietStart, fallback: 22 * 60);
    final end = timeToMinutes(cachedQuietEnd, fallback: 6 * 60);
    if (start == end) return false;
    if (start < end) return current >= start && current < end;
    return current >= start || current < end;
  }

  /// Kiểm tra trạng thái bật/tắt thông báo
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyEnabled) ?? true;
  }

  /// Cài đặt bật/tắt thông báo
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEnabled, enabled);
  }

  /// Đánh dấu một tác vụ của cây đã được hoàn thành hôm nay để không nhắc lại
  static Future<void> silenceForToday(String plantId, String taskType) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();
    await prefs.setString('$_prefKeyPrefixNotified${plantId}_$taskType', today);
    // Đã làm rồi thì không nhắc lại vào buổi chiều nữa
    await prefs.setString('$_prefKeyPrefixNotified${plantId}_${taskType}_evening', today);
  }

  /// Xóa lịch sử đã thông báo (dùng khi kiểm tra hoặc reset)
  static Future<void> resetNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefKeyPrefixNotified)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  /// Chuỗi ngày hiện tại dạng YYYY-MM-DD
  static String _getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// Kiểm tra xem một tác vụ đã được thông báo trong ngày hôm nay chưa
  static Future<bool> _isAlreadyNotifiedToday(String plantId, String taskType) async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('$_prefKeyPrefixNotified${plantId}_$taskType');
    return lastDate == _getTodayKey();
  }

  /// Đánh dấu đã thông báo tác vụ này hôm nay
  static Future<void> _markNotifiedToday(String plantId, String taskType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefKeyPrefixNotified${plantId}_$taskType', _getTodayKey());
  }

  /// Động cơ quét và kích hoạt thông báo đẩy hệ điều hành nhắc nhở chăm sóc cây
  static Future<void> checkAndNotifyPendingTasks(
    BuildContext context,
    List<GardenPlant> plants,
  ) async {
    if (!context.mounted) return;
    final enabled = await isEnabled();
    if (!enabled || plants.isEmpty) return;

    // Tải tùy chọn nhắc nhở & bỏ qua nếu đang trong khung giờ Không làm phiền
    await loadPreferences();
    if (isInQuietHours()) return;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final eveningMinutes = timeToMinutes(cachedEveningTime, fallback: 17 * 60 + 30);

    for (final plant in plants) {
      // 1. Phân tích giờ nhắc nhở của cây (mặc định 07:00 nếu chưa đặt)
      final reminderMinutes = timeToMinutes(plant.reminderTime);

      // Chỉ nhắc nhở khi thời gian hiện tại đã đến hoặc qua khung giờ hẹn hôm nay
      if (currentMinutes < reminderMinutes) continue;

      // Sau giờ nhắc buổi chiều: nhắc lại lần 2 cho các việc vẫn chưa làm
      final isEveningSlot = currentMinutes >= eveningMinutes && reminderMinutes < eveningMinutes;
      final slot = isEveningSlot ? '_evening' : '';
      final titlePrefix = isEveningSlot ? 'Nhắc lại: ' : '';

      // 2. Kiểm tra tác vụ Tưới nước
      if (plant.isNeedsWater) {
        final alreadyNotified = await _isAlreadyNotifiedToday(plant.id, 'water$slot');
        if (!alreadyNotified) {
          await _markNotifiedToday(plant.id, 'water$slot');
          await showSystemNotification(
            id: plant.id.hashCode,
            title: '🌿 Floria: $titlePrefixĐã đến giờ tưới nước!',
            body: 'Cây ${plant.nickname} cần được cấp ẩm để duy trì độ tươi tốt.',
            payload: plant.id,
          );
          break; // Giới hạn 1 thông báo mỗi lượt quét để không làm phiền người dùng
        }
      }

      // 3. Kiểm tra tác vụ Bón phân (nếu cây có chu kỳ bón phân > 0)
      if (plant.isNeedsFertilizer && plant.fertilizeFrequencyDays > 0) {
        final alreadyNotified = await _isAlreadyNotifiedToday(plant.id, 'fertilize$slot');
        if (!alreadyNotified) {
          await _markNotifiedToday(plant.id, 'fertilize$slot');
          await showSystemNotification(
            id: plant.id.hashCode + 1,
            title: '🌿 Floria: $titlePrefixĐã đến lịch bón phân vi lượng!',
            body: 'Bổ sung dinh dưỡng định kỳ cho ${plant.nickname}.',
            payload: plant.id,
          );
          break;
        }
      }

      // 4. Kiểm tra tác vụ Lau lá / kiểm tra sâu bệnh
      if (plant.isNeedsClean) {
        final alreadyNotified = await _isAlreadyNotifiedToday(plant.id, 'clean$slot');
        if (!alreadyNotified) {
          await _markNotifiedToday(plant.id, 'clean$slot');
          await showSystemNotification(
            id: plant.id.hashCode + 2,
            title: '🌿 Floria: ${titlePrefix}Vệ sinh lá & kiểm tra sâu bệnh!',
            body: 'Lau bụi phiến lá cho ${plant.nickname} để quang hợp tối ưu.',
            payload: plant.id,
          );
          break;
        }
      }
    }
  }

  /// Kích hoạt thử thông báo đẩy thật lên thiết bị (dành cho nút "Kiểm tra thử thông báo ngay" trong Cài đặt)
  static void showTestNotification(BuildContext context, {GardenPlant? samplePlant}) {
    final now = DateTime.now();
    final plant = samplePlant ??
        GardenPlant(
          id: 'test_demo',
          userId: 'test_user',
          nameVi: 'Cây Bàng Singapore',
          scientificName: 'Ficus lyrata',
          nickname: 'Bàng Singapore ban công',
          zone: 'Ban công',
          waterFrequencyDays: 3,
          healthStatus: 'Khỏe mạnh',
          reminderTime: '07:00',
          lastWatered: now,
          nextWatering: now.add(const Duration(days: 3)),
          createdAt: now,
        );

    // Bắn thông báo đẩy thật lên thanh trạng thái hệ điều hành Android / iOS
    unawaited(
      showSystemNotification(
        id: plant.id.hashCode,
        title: '🌿 Floria: Đã đến lịch tưới nước (Thử nghiệm)!',
        body: 'Cây ${plant.nickname} cần được tưới nước theo lịch chăm sóc.',
        payload: plant.id,
      ),
    );

    // Phản hồi SnackBar nhẹ trong app báo hiệu thành công
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã phát thông báo đẩy thử nghiệm lên thanh trạng thái thiết bị!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
