import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/garden/models/garden_plant.dart';
import '../../features/garden/providers/garden_provider.dart';
import '../../features/garden/screens/plant_detail_screen.dart';
import 'package:provider/provider.dart';

class NotificationService {
  static const String _prefKeyEnabled = 'notifications_enabled';
  static const String _prefKeyPrefixNotified = 'notified_plant_';

  static const String _prefKeyMorningTime = 'reminder_morning_time';
  static const String _prefKeyEveningTime = 'reminder_evening_time';
  static const String _prefKeyQuietEnabled = 'reminder_quiet_enabled';
  static const String _prefKeyQuietStart = 'reminder_quiet_start';
  static const String _prefKeyQuietEnd = 'reminder_quiet_end';

  static OverlayEntry? _activeOverlayEntry;
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
        },
      );

      final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
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

  /// Bắn thông báo đẩy thật lên thanh trạng thái của thiết bị
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

      const androidDetails = AndroidNotificationDetails(
        'floria_care_channel',
        'Lịch chăm sóc cây Floria',
        channelDescription: 'Thông báo nhắc nhở tưới nước, bón phân và chăm sóc cây từ Floria',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
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

  /// Động cơ quét và kích hoạt thông báo nhắc nhở chăm sóc cây
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
          if (context.mounted) {
            _showSmartCareBanner(
              context: context,
              plant: plant,
              taskTitle: '$titlePrefixĐã đến giờ tưới nước!',
              taskDesc: 'Cây ${plant.nickname} cần được cấp ẩm để duy trì độ tươi tốt.',
              icon: Icons.water_drop,
              iconColor: const Color(0xFF38BDF8),
              actionLabel: 'Tưới ngay',
              onAction: () async {
                final gardenProvider = Provider.of<GardenProvider>(context, listen: false);
                await gardenProvider.waterPlant(plant.id);
                silenceForToday(plant.id, 'water');
              },
            );
          }
          break; // Chỉ hiện 1 banner tại một thời điểm để không làm phiền
        }
      }

      // 3. Kiểm tra tác vụ Bón phân (nếu cây có chu kỳ bón phân > 0)
      if (plant.isNeedsFertilizer && plant.fertilizeFrequencyDays > 0) {
        final alreadyNotified = await _isAlreadyNotifiedToday(plant.id, 'fertilize$slot');
        if (!alreadyNotified) {
          await _markNotifiedToday(plant.id, 'fertilize$slot');
          if (context.mounted) {
            _showSmartCareBanner(
              context: context,
              plant: plant,
              taskTitle: '$titlePrefixĐã đến lịch bón phân vi lượng!',
              taskDesc: 'Bổ sung dinh dưỡng định kỳ cho ${plant.nickname}.',
              icon: Icons.science,
              iconColor: const Color(0xFFFBBF24),
              actionLabel: 'Đã bón phân',
              onAction: () async {
                final gardenProvider = Provider.of<GardenProvider>(context, listen: false);
                await gardenProvider.fertilizePlant(plant.id);
                silenceForToday(plant.id, 'fertilize');
              },
            );
          }
          break;
        }
      }

      // 4. Kiểm tra tác vụ Lau lá / kiểm tra sâu bệnh
      if (plant.isNeedsClean) {
        final alreadyNotified = await _isAlreadyNotifiedToday(plant.id, 'clean$slot');
        if (!alreadyNotified) {
          await _markNotifiedToday(plant.id, 'clean$slot');
          if (context.mounted) {
            _showSmartCareBanner(
              context: context,
              plant: plant,
              taskTitle: '${titlePrefix}Vệ sinh lá & kiểm tra sâu bệnh!',
              taskDesc: 'Lau bụi phiến lá cho ${plant.nickname} để quang hợp tối ưu.',
              icon: Icons.eco,
              iconColor: const Color(0xFF4ADE80),
              actionLabel: 'Đã lau sạch',
              onAction: () async {
                final gardenProvider = Provider.of<GardenProvider>(context, listen: false);
                await gardenProvider.cleanPlant(plant.id);
                silenceForToday(plant.id, 'clean');
              },
            );
          }
          break;
        }
      }
    }
  }

  /// Kích hoạt thử thông báo ngay lập tức (dành cho nút Test trong Cài đặt)
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

    _showSmartCareBanner(
      context: context,
      plant: plant,
      taskTitle: 'Đã đến lịch tưới nước (Thử nghiệm)!',
      taskDesc: 'Cây ${plant.nickname} cần được tưới nước theo lịch chăm sóc.',
      icon: Icons.water_drop,
      iconColor: const Color(0xFF38BDF8),
      actionLabel: 'Tưới ngay',
      onAction: () {
        debugPrint("Đã xác nhận tưới nước thành công trong chế độ thử nghiệm!");
      },
    );
  }

  /// Hiển thị Banner nổi thông minh chuẩn thiết kế thẩm mỹ cao Floria
  static void _showSmartCareBanner({
    required BuildContext context,
    required GardenPlant plant,
    required String taskTitle,
    required String taskDesc,
    required IconData icon,
    required Color iconColor,
    required String actionLabel,
    required FutureOr<void> Function() onAction,
  }) {
    _activeOverlayEntry?.remove();
    _activeOverlayEntry = null;

    // Đồng thời bắn thông báo đẩy cấp hệ điều hành lên thanh trạng thái máy
    unawaited(
      showSystemNotification(
        id: plant.id.hashCode,
        title: '🌿 Floria: $taskTitle',
        body: taskDesc,
        payload: plant.id,
      ),
    );

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return _SmartNotificationWidget(
          plant: plant,
          taskTitle: taskTitle,
          taskDesc: taskDesc,
          icon: icon,
          iconColor: iconColor,
          actionLabel: actionLabel,
          onDismiss: () {
            entry.remove();
            if (_activeOverlayEntry == entry) {
              _activeOverlayEntry = null;
            }
          },
          onAction: () async {
            entry.remove();
            if (_activeOverlayEntry == entry) {
              _activeOverlayEntry = null;
            }
            await onAction();
          },
          onOpenPlantDetail: () {
            entry.remove();
            if (_activeOverlayEntry == entry) {
              _activeOverlayEntry = null;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlantDetailScreen(gardenPlant: plant),
              ),
            );
          },
        );
      },
    );

    _activeOverlayEntry = entry;
    overlay.insert(entry);
  }
}

class _SmartNotificationWidget extends StatefulWidget {
  final GardenPlant plant;
  final String taskTitle;
  final String taskDesc;
  final IconData icon;
  final Color iconColor;
  final String actionLabel;
  final VoidCallback onDismiss;
  final VoidCallback onAction;
  final VoidCallback onOpenPlantDetail;

  const _SmartNotificationWidget({
    required this.plant,
    required this.taskTitle,
    required this.taskDesc,
    required this.icon,
    required this.iconColor,
    required this.actionLabel,
    required this.onDismiss,
    required this.onAction,
    required this.onOpenPlantDetail,
  });

  @override
  State<_SmartNotificationWidget> createState() => _SmartNotificationWidgetState();
}

class _SmartNotificationWidgetState extends State<_SmartNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutBack));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);

    _animController.forward();

    // Tự động đóng sau 7 giây
    _autoDismissTimer = Timer(const Duration(seconds: 7), () {
      _closeBanner();
    });
  }

  void _closeBanner() {
    if (!mounted) return;
    _animController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A24), // Xanh rêu đậm hoàng gia
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng tiêu đề + Nút đóng
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.iconColor.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, color: widget.iconColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.taskTitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.plant.reminderTime,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFB4F4C2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.taskDesc,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFFD1E7D6),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                        onPressed: _closeBanner,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Hàng nút hành động nhanh
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: widget.onOpenPlantDetail,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFD1E7D6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: Text(
                          'Chi tiết cây',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _animController.reverse().then((_) {
                            widget.onAction();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4ADE80),
                          foregroundColor: const Color(0xFF0F2913),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: Text(
                          widget.actionLabel,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
