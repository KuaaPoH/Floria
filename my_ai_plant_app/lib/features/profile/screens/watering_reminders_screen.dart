import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/custom_image.dart';
import '../../garden/models/garden_plant.dart';
import '../../garden/providers/garden_provider.dart';

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
  static const Color _textDark = Color(0xFF1F2A21);
  static const Color _textMuted = Color(0xFF6A756B);
  static const Color _green = Color(0xFF3E8055);

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
          _showToast('Đã cấp quyền thông báo trên thiết bị thành công!');
        } else if (status.isPermanentlyDenied) {
          _showToast('Quyền đã bị chặn vĩnh viễn. Vui lòng mở Cài đặt máy để bật lại!', isError: true);
        } else {
          _showToast('Quyền thông báo chưa được cấp.', isError: true);
        }
      }
    } catch (e) {
      _showToast('Lỗi khi xin quyền: $e', isError: true);
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
    _showToast('Đã ghi nhận: ${_taskLabel(task.type).toLowerCase()} cho ${task.plant.nickname}');
  }

  Future<void> _pickTime({
    required String current,
    required Future<void> Function(String) onSaved,
  }) async {
    final minutes = NotificationService.timeToMinutes(current);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _green)),
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
        return 'Tưới nước';
      case _CareTaskType.fertilize:
        return 'Bón phân';
      case _CareTaskType.clean:
        return 'Lau lá & kiểm tra sâu bệnh';
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
      return days >= 1 ? 'Quá hạn $days ngày' : 'Đến hạn hôm nay';
    }
    final hours = task.dueAt.difference(now).inHours;
    return hours <= 0 ? 'Sắp đến hạn' : 'Còn khoảng $hours giờ';
  }

  void _showToast(String message, {bool isError = false}) {
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
                color: isError ? const Color(0xFF2D1618) : const Color(0xFF1E2D22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isError ? const Color(0xFFFF6B6B) : const Color(0xFF66BB6A)).withValues(alpha: 0.35),
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
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
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
    final gardenProvider = Provider.of<GardenProvider>(context);
    final tasks = _collectTodayTasks(gardenProvider.allUserPlants);
    final gardenNames = {for (final g in gardenProvider.gardens) g.id: g.name};

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F3),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nhắc tưới & chăm sóc',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: _textDark),
        ),
      ),
      body: _isLoadingPrefs
          ? const Center(child: CircularProgressIndicator(color: _green))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                _buildStatusHeader(),
                const SizedBox(height: 14),
                _buildDevicePermissionCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('VIỆC CẦN LÀM HÔM NAY', trailing: '${tasks.length} việc'),
                const SizedBox(height: 8),
                if (tasks.isEmpty)
                  _buildEmptyTasks()
                else
                  ...tasks.map((t) => _buildTaskTile(t, gardenNames[t.plant.gardenId])),
                const SizedBox(height: 24),
                _buildSectionTitle('KHÔNG LÀM PHIỀN'),
                const SizedBox(height: 8),
                _buildQuietHoursCard(),
              ],
            ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF17231A).withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _textMuted, letterSpacing: 1),
          ),
          if (trailing != null)
            Text(trailing, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _green)),
        ],
      ),
    );
  }

  // ---------- 1. Thẻ trạng thái thông báo ----------
  Widget _buildStatusHeader() {
    final on = _notificationsEnabled;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: on
              ? const [Color(0xFF2E6F40), Color(0xFF4F9D69)]
              : const [Color(0xFF5B6360), Color(0xFF7C8580)],
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
                      on ? 'Nhắc nhở đang bật' : 'Nhắc nhở đang tắt',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      on
                          ? 'Floria sẽ hiện banner nhắc khi đến giờ chăm sóc trong lúc bạn mở ứng dụng.'
                          : 'Bạn sẽ không nhận được nhắc tưới, bón phân và kiểm tra cây.',
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
              label: Text('Thử thông báo ngay', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
                  color: isGranted ? const Color(0xFFE5F4EA) : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGranted ? Icons.verified_user_rounded : Icons.notifications_off_outlined,
                  color: isGranted ? _green : const Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quyền thông báo thiết bị',
                      style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: _textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGranted
                          ? 'Thiết bị đã cấp phép nhận thông báo từ ứng dụng.'
                          : 'Cần cấp quyền để thiết bị cho phép Floria gửi lời nhắc.',
                      style: GoogleFonts.inter(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isGranted ? const Color(0xFFE5F4EA) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isGranted ? 'Đã cấp' : 'Chưa cấp',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isGranted ? _green : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          if (!isGranted) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0x144F9D69)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _requestDevicePermission,
                    icon: const Icon(Icons.touch_app_rounded, size: 16),
                    label: Text('Cấp quyền ngay', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
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
                    label: Text('Cài đặt máy', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textDark,
                      side: const BorderSide(color: Color(0xFFCFD5CE)),
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
                    const Icon(Icons.settings_outlined, size: 14, color: _textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Quản lý quyền trong Cài đặt thiết bị',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _textMuted,
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
    return _buildCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          const Icon(Icons.eco_rounded, size: 40, color: Color(0xFF4F9D69)),
          const SizedBox(height: 10),
          Text(
            'Tuyệt vời! Hôm nay không còn việc nào',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Tất cả cây trong các khu vườn đều đã được chăm sóc đúng lịch.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: _textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(_CareTask task, String? gardenName) {
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
                        color: const Color(0xFFE5F4EA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.local_florist_rounded, color: _green),
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
                    style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: _textDark),
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
                      color: task.isOverdue ? const Color(0xFFB45309) : _textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Đánh dấu đã ${_taskLabel(task.type).toLowerCase()}',
              child: InkWell(
                onTap: processing ? null : () => _completeTask(task),
                customBorder: const CircleBorder(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: processing ? _green : Colors.white,
                    border: Border.all(color: _green, width: 2),
                  ),
                  child: processing
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 20, color: _green),
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
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: enabled ? const Color(0xFF4F9D69) : Colors.grey, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 14.5, color: enabled ? _textDark : Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: _textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: enabled ? const Color(0xFFE5F4EA) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: enabled ? _green : Colors.grey,
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
    final quietOn = NotificationService.cachedQuietEnabled;
    return _buildCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.bedtime_outlined, color: Color(0xFF4F9D69), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Không làm phiền', style: GoogleFonts.inter(fontSize: 14.5, color: _textDark)),
                      const SizedBox(height: 2),
                      Text(
                        'Tạm dừng mọi nhắc nhở trong giờ nghỉ ngơi',
                        style: GoogleFonts.inter(fontSize: 12, color: _textMuted),
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
                  activeTrackColor: const Color(0xFF4F9D69),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey[300],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x144F9D69)),
          _buildTimeRow(
            icon: Icons.nightlight_outlined,
            title: 'Bắt đầu',
            subtitle: 'Từ giờ này sẽ không nhắc nữa',
            value: NotificationService.cachedQuietStart,
            enabled: quietOn,
            onTap: () => _pickTime(
              current: NotificationService.cachedQuietStart,
              onSaved: (v) => NotificationService.setQuietHours(start: v),
            ),
          ),
          const Divider(height: 1, color: Color(0x144F9D69)),
          _buildTimeRow(
            icon: Icons.light_mode_outlined,
            title: 'Kết thúc',
            subtitle: 'Nhắc nhở hoạt động lại từ giờ này',
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

