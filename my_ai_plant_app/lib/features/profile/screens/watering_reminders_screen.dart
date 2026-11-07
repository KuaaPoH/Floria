import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/custom_image.dart';
import '../../garden/models/garden_plant.dart';
import '../../garden/providers/garden_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_tr.dart';

/// Loại công việc chăm sóc đến hạn
enum _CareTaskType { water, fertilize, clean }

class _CareTask {
  final GardenPlant plant;
  final _CareTaskType type;
  final DateTime dueAt;

  _CareTask(this.plant, this.type, this.dueAt);

  String get key => '${plant.id}_${type.name}';
  bool get isOverdue => DateTime.now().isAfter(dueAt);
}

/// Bảng điều khiển Lịch chăm sóc & Nhắc nhở tập trung (Care & Reminder Hub)
class WateringRemindersScreen extends StatefulWidget {
  const WateringRemindersScreen({super.key});

  @override
  State<WateringRemindersScreen> createState() => _WateringRemindersScreenState();
}

class _WateringRemindersScreenState extends State<WateringRemindersScreen> with WidgetsBindingObserver {
  bool _notificationsEnabled = true;
  bool _isLoadingPrefs = true;
  PermissionStatus _devicePermissionStatus = PermissionStatus.denied;
  final Set<String> _processingKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPrefs();
    _checkDevicePermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Khi người dùng từ cài đặt máy quay lại app, cập nhật lại trạng thái quyền
      _checkDevicePermission();
    }
  }

  Future<void> _checkDevicePermission() async {
    try {
      final status = await Permission.notification.status;
      if (mounted) {
        setState(() => _devicePermissionStatus = status);
      }
    } catch (_) {}
  }

  Future<void> _requestDevicePermission() async {
    try {
      final status = await Permission.notification.request();
      if (mounted) {
        setState(() => _devicePermissionStatus = status);
        if (status.isGranted) {
          _showToast(context.tr('Đã cấp quyền thông báo trên thiết bị thành công!', 'Device notification permission granted successfully!'));
        } else if (status.isPermanentlyDenied) {
          _showToast(context.tr('Quyền đã bị chặn vĩnh viễn. Vui lòng mở Cài đặt máy để bật lại!', 'Permission permanently denied. Please open Device Settings to enable!'), isError: true);
        } else {
          _showToast(context.tr('Quyền thông báo chưa được cấp.', 'Notification permission not granted.'), isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showToast('${context.tr("Lỗi khi xin quyền:", "Error requesting permission:")} $e', isError: true);
      }
    }
  }

  Future<void> _openDeviceSettings() async {
    await openAppSettings();
  }

  Future<void> _loadPrefs() async {
    final enabled = await NotificationService.isEnabled();
    await NotificationService.loadPreferences();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _isLoadingPrefs = false;
    });
  }

  // ======================= DỮ LIỆU =======================

  List<_CareTask> _collectTodayTasks(List<GardenPlant> plants) {
    final tasks = <_CareTask>[];
    for (final p in plants) {
      if (p.isNeedsWater) tasks.add(_CareTask(p, _CareTaskType.water, p.nextWatering));
      if (p.isNeedsFertilizer) tasks.add(_CareTask(p, _CareTaskType.fertilize, p.nextFertilizing));
      if (p.isNeedsClean) tasks.add(_CareTask(p, _CareTaskType.clean, p.nextCheckPest));
    }
    // Quá hạn lâu nhất lên đầu
    tasks.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return tasks;
  }

  Future<void> _completeTask(_CareTask task) async {
    if (_processingKeys.contains(task.key)) return;
    setState(() => _processingKeys.add(task.key));
    final provider = Provider.of<GardenProvider>(context, listen: false);
    switch (task.type) {
      case _CareTaskType.water:
        await provider.waterPlant(task.plant.id);
        break;
      case _CareTaskType.fertilize:
        await provider.fertilizePlant(task.plant.id);
        break;
      case _CareTaskType.clean:
        await provider.cleanPlant(task.plant.id);
        break;
    }
    await NotificationService.silenceForToday(task.plant.id, task.type.name);
    if (!mounted) return;
    setState(() => _processingKeys.remove(task.key));
    _showToast('${context.tr("Đã ghi nhận:", "Recorded:")} ${_taskLabel(task.type).toLowerCase()} ${context.tr("cho", "for")} ${task.plant.nickname}');
  }

  Future<void> _pickTime({
    required String current,
    required Future<void> Function(String) onSaved,
  }) async {
    final c = context.colors;
    final minutes = NotificationService.timeToMinutes(current);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: c.primary)),
        child: MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      ),
    );
    if (picked == null) return;
    final value = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    await onSaved(value);
    if (mounted) setState(() {});
  }

  // ======================= TIỆN ÍCH HIỂN THỊ =======================

  String _taskLabel(_CareTaskType type) {
    switch (type) {
      case _CareTaskType.water:
        return context.tr('Tưới nước', 'Watering');
      case _CareTaskType.fertilize:
        return context.tr('Bón phân', 'Fertilizing');
      case _CareTaskType.clean:
        return context.tr('Lau lá & kiểm tra sâu bệnh', 'Leaf cleaning & pest check');
    }
  }

  IconData _taskIcon(_CareTaskType type) {
    switch (type) {
      case _CareTaskType.water:
        return Icons.water_drop_rounded;
      case _CareTaskType.fertilize:
        return Icons.science_rounded;
      case _CareTaskType.clean:
        return Icons.shield_outlined;
    }
  }

  Color _taskColor(_CareTaskType type) {
    switch (type) {
      case _CareTaskType.water:
        return const Color(0xFF0284C7);
      case _CareTaskType.fertilize:
        return const Color(0xFFD97706);
      case _CareTaskType.clean:
        return const Color(0xFF15803D);
    }
  }

  String _dueText(_CareTask task) {
    final now = DateTime.now();
    if (task.isOverdue) {
      final days = now.difference(task.dueAt).inDays;
      return days >= 1 ? '${context.tr("Quá hạn", "Overdue by")} $days ${context.tr("ngày", "days")}' : context.tr('Đến hạn hôm nay', 'Due today');
    }
    final hours = task.dueAt.difference(now).inHours;
    return hours <= 0 ? context.tr('Sắp đến hạn', 'Due soon') : '${context.tr("Còn khoảng", "About")} $hours ${context.tr("giờ", "hours left")}';
  }

  void _showToast(String message, {bool isError = false}) {
    final c = context.colors;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 2),
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? c.errorBg : c.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isError ? const Color(0xFFFF6B6B).withValues(alpha: 0.35) : c.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                    color: isError ? const Color(0xFFFF8A80) : const Color(0xFF81C784),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      message,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ======================= GIAO DIỆN =======================

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final gardenProvider = Provider.of<GardenProvider>(context);
    final tasks = _collectTodayTasks(gardenProvider.allUserPlants);
    final gardenNames = {for (final g in gardenProvider.gardens) g.id: g.name};

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('Nhắc tưới & chăm sóc', 'Reminders & Care'),
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: c.textPrimary),
        ),
      ),
      body: _isLoadingPrefs
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                _buildStatusHeader(),
                const SizedBox(height: 14),
                _buildDevicePermissionCard(),
                const SizedBox(height: 24),
                _buildSectionTitle(context.tr('VIỆC CẦN LÀM HÔM NAY', 'TODAY\'S TASKS'), trailing: '${tasks.length} ${context.tr("việc", "tasks")}'),
                const SizedBox(height: 8),
                if (tasks.isEmpty)
                  _buildEmptyTasks()
                else
                  ...tasks.map((t) => _buildTaskTile(t, gardenNames[t.plant.gardenId])),
                const SizedBox(height: 24),
                _buildSectionTitle(context.tr('KHÔNG LÀM PHIỀN', 'DO NOT DISTURB')),
                const SizedBox(height: 8),
                _buildQuietHoursCard(),
              ],
            ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsets? padding}) {
    final c = context.colors;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(color: c.shadow, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, {String? trailing}) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted, letterSpacing: 1),
          ),
          if (trailing != null)
            Text(trailing, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: c.primary)),
        ],
      ),
    );
  }

  // ---------- 1. Thẻ trạng thái thông báo ----------
  Widget _buildStatusHeader() {
    final c = context.colors;
    final on = _notificationsEnabled;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: on
              ? const [Color(0xFF2E6F40), Color(0xFF4F9D69)]
              : (c.isDark
                  ? const [Color(0xFF333B35), Color(0xFF262C27)]
                  : const [Color(0xFF5B6360), Color(0xFF7C8580)]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  on ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      on ? context.tr('Nhắc nhở đang bật', 'Reminders are ON') : context.tr('Nhắc nhở đang tắt', 'Reminders are OFF'),
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      on
                          ? context.tr('Floria sẽ hiện banner nhắc khi đến giờ chăm sóc trong lúc bạn mở ứng dụng.', 'Floria will show reminder banners when care is due while using the app.')
                          : context.tr('Bạn sẽ không nhận được nhắc tưới, bón phân và kiểm tra cây.', 'You will not receive watering, fertilizing and pest check reminders.'),
                      style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.88), height: 1.4),
                    ),
                  ],
                ),
              ),
              Switch(
                value: on,
                onChanged: (val) async {
                  setState(() => _notificationsEnabled = val);
                  await NotificationService.setEnabled(val);
                },
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.white.withValues(alpha: 0.35),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: on ? () => NotificationService.showTestNotification(context) : null,
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: Text(context.tr('Thử thông báo ngay', 'Test notification now'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white54,
                side: BorderSide(color: Colors.white.withValues(alpha: on ? 0.6 : 0.25)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- 1.5. Thẻ kiểm tra quyền hệ điều hành thiết bị ----------
  Widget _buildDevicePermissionCard() {
    final c = context.colors;
    final isGranted = _devicePermissionStatus.isGranted;
    return _buildCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isGranted ? c.surfaceTint : const Color(0xFFFEF3C7).withValues(alpha: c.isDark ? 0.15 : 1.0),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGranted ? Icons.verified_user_rounded : Icons.notifications_off_outlined,
                  color: isGranted ? c.primary : const Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Quyền thông báo thiết bị', 'Device Notification Permission'),
                      style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: c.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGranted
                          ? context.tr('Thiết bị đã cấp phép nhận thông báo từ ứng dụng.', 'Device granted notification permissions.')
                          : context.tr('Cần cấp quyền để thiết bị cho phép Floria gửi lời nhắc.', 'Grant permission to allow Floria to send reminders.'),
                      style: GoogleFonts.inter(fontSize: 12, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isGranted ? c.surfaceTint : const Color(0xFFFEF3C7).withValues(alpha: c.isDark ? 0.15 : 1.0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isGranted ? context.tr('Đã cấp', 'Granted') : context.tr('Chưa cấp', 'Not granted'),
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isGranted ? c.primary : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          if (!isGranted) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: c.border),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _requestDevicePermission,
                    icon: const Icon(Icons.touch_app_rounded, size: 16),
                    label: Text(context.tr('Cấp quyền ngay', 'Grant permission'), style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openDeviceSettings,
                    icon: const Icon(Icons.settings_outlined, size: 16),
                    label: Text(context.tr('Cài đặt máy', 'Device settings'), style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textPrimary,
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: _openDeviceSettings,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings_outlined, size: 14, color: c.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('Quản lý quyền trong Cài đặt thiết bị', 'Manage permissions in Device Settings'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: c.textMuted,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------- 2. Danh sách việc hôm nay ----------
  Widget _buildEmptyTasks() {
    final c = context.colors;
    return _buildCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.eco_rounded, size: 40, color: c.primary),
          const SizedBox(height: 10),
          Text(
            context.tr('Tuyệt vời! Hôm nay không còn việc nào', 'Awesome! No tasks left for today'),
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('Tất cả cây trong các khu vườn đều đã được chăm sóc đúng lịch.', 'All plants across your gardens are cared for on schedule.'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: c.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(_CareTask task, String? gardenName) {
    final c = context.colors;
    final color = _taskColor(task.type);
    final processing = _processingKeys.contains(task.key);
    final imageUrl = task.plant.imageUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _buildCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? CustomImage(imageUrl: imageUrl, width: 52, height: 52, borderRadius: BorderRadius.circular(14))
                  : Container(
                      decoration: BoxDecoration(
                        color: c.surfaceTint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.local_florist_rounded, color: c.primary),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.plant.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(_taskIcon(task.type), size: 14, color: color),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _taskLabel(task.type),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (gardenName != null && gardenName.isNotEmpty) gardenName,
                      task.plant.zone,
                      _dueText(task),
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: task.isOverdue ? const Color(0xFFB45309) : c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: '${context.tr("Đánh dấu đã", "Mark as completed")} ${_taskLabel(task.type).toLowerCase()}',
              child: InkWell(
                onTap: processing ? null : () => _completeTask(task),
                customBorder: const CircleBorder(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: processing ? c.primary : c.surface,
                    border: Border.all(color: c.primary, width: 2),
                  ),
                  child: processing
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(Icons.check_rounded, size: 20, color: c.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final c = context.colors;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: enabled ? c.primary : c.textMuted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 14.5, color: enabled ? c.textPrimary : c.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: c.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: enabled ? c.surfaceTint : c.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: enabled ? c.primary : c.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 4. Không làm phiền ----------
  Widget _buildQuietHoursCard() {
    final c = context.colors;
    final quietOn = NotificationService.cachedQuietEnabled;
    return _buildCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.bedtime_outlined, color: c.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('Không làm phiền', 'Do Not Disturb'), style: GoogleFonts.inter(fontSize: 14.5, color: c.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('Tạm dừng mọi nhắc nhở trong giờ nghỉ ngơi', 'Pause all notifications during resting hours'),
                        style: GoogleFonts.inter(fontSize: 12, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: quietOn,
                  onChanged: (val) async {
                    await NotificationService.setQuietHours(enabled: val);
                    if (mounted) setState(() {});
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: c.primary,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: c.isDark ? Colors.grey[800] : Colors.grey[300],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
          _buildTimeRow(
            icon: Icons.nightlight_outlined,
            title: context.tr('Bắt đầu', 'Start'),
            subtitle: context.tr('Từ giờ này sẽ không nhắc nữa', 'No reminders will be sent after this hour'),
            value: NotificationService.cachedQuietStart,
            enabled: quietOn,
            onTap: () => _pickTime(
              current: NotificationService.cachedQuietStart,
              onSaved: (v) => NotificationService.setQuietHours(start: v),
            ),
          ),
          Divider(height: 1, color: c.border),
          _buildTimeRow(
            icon: Icons.light_mode_outlined,
            title: context.tr('Kết thúc', 'End'),
            subtitle: context.tr('Nhắc nhở hoạt động lại từ giờ này', 'Reminders resume after this hour'),
            value: NotificationService.cachedQuietEnd,
            enabled: quietOn,
            onTap: () => _pickTime(
              current: NotificationService.cachedQuietEnd,
              onSaved: (v) => NotificationService.setQuietHours(end: v),
            ),
          ),
        ],
      ),
    );
  }
}

