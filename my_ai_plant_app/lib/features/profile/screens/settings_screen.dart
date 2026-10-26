import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/migration_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _saveImages = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await NotificationService.isEnabled();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F3).withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(color: const Color(0xFF17231A).withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: const Icon(Icons.chevron_left, color: Color(0xFF1F2A21)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cài đặt',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2A21),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Group 1: HIỂN THỊ
          _buildGroupTitle('HIỂN THỊ'),
          const SizedBox(height: 8),
          _buildSettingsContainer([
            _buildToggleTile(
              icon: Icons.dark_mode_outlined,
              title: 'Giao diện tối',
              value: _darkMode,
              onChanged: (val) => setState(() => _darkMode = val),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0x144F9D69)),
            _buildArrowTile(
              icon: Icons.language_outlined,
              title: 'Ngôn ngữ',
              valueText: 'Tiếng Việt',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 24),

          // Group 2: TÙY CHỈNH
          _buildGroupTitle('TÙY CHỈNH'),
          const SizedBox(height: 8),
          _buildSettingsContainer([
            _buildToggleTile(
              icon: Icons.notifications_none_outlined,
              title: 'Nhắc nhở tưới cây & chăm sóc',
              value: _notificationsEnabled,
              onChanged: (val) async {
                setState(() => _notificationsEnabled = val);
                await NotificationService.setEnabled(val);
              },
            ),
            const Divider(height: 1, thickness: 1, color: Color(0x144F9D69)),
            _buildArrowTile(
              icon: Icons.notifications_active_outlined,
              title: 'Kiểm tra thử thông báo ngay',
              valueText: 'Thử ngay',
              onTap: () {
                NotificationService.showTestNotification(context);
              },
            ),
            const Divider(height: 1, thickness: 1, color: Color(0x144F9D69)),
            _buildToggleTile(
              icon: Icons.image_outlined,
              title: 'Lưu ảnh quét vào Thư viện',
              value: _saveImages,
              onChanged: (val) => setState(() => _saveImages = val),
            ),
          ]),
          const SizedBox(height: 24),

          // Group 2.5: DỮ LIỆU & ĐÁM MÂY
          _buildGroupTitle('DỮ LIỆU & ĐÁM MÂY'),
          const SizedBox(height: 8),
          _buildSettingsContainer([
            _buildArrowTile(
              icon: Icons.cloud_sync_rounded,
              title: 'Chuyển ảnh sang ImgBB Cloud',
              valueText: 'Đồng bộ',
              onTap: () => _showMigrationDialog(context),
            ),
          ]),
          const SizedBox(height: 24),

          // Group 3: THÔNG TIN
          _buildGroupTitle('THÔNG TIN'),
          const SizedBox(height: 8),
          _buildSettingsContainer([
            _buildArrowTile(
              icon: null,
              title: 'Điều khoản bảo mật',
              onTap: () {},
            ),
            const Divider(height: 1, thickness: 1, color: Color(0x144F9D69)),
            _buildValueTile(
              title: 'Phiên bản ứng dụng',
              valueText: 'v2.4.1',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6A756B),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17231A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF4F9D69), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: const Color(0xFF1F2A21),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF4F9D69),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildArrowTile({
    IconData? icon,
    required String title,
    String? valueText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: const Color(0xFF4F9D69), size: 24),
                  const SizedBox(width: 12),
                ],
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF1F2A21),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (valueText != null) ...[
                  Text(
                    valueText,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6A756B),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.chevron_right, color: Color(0xFF6A756B), size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueTile({
    required String title,
    required String valueText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF1F2A21),
            ),
          ),
          Text(
            valueText,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6A756B),
            ),
          ),
        ],
      ),
    );
  }

  void _showMigrationDialog(BuildContext context) {
    String status = "Chuyển toàn bộ ảnh Unsplash và ảnh Base64 sang ImgBB Cloud hoàn toàn miễn phí, lưu trữ vĩnh viễn và tối ưu tốc độ tải.";
    bool isRunning = false;
    Map<String, int>? result;

    showDialog(
      context: context,
      barrierDismissible: !isRunning,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.cloud_sync_rounded, color: Color(0xFF2E6F40)),
                  const SizedBox(width: 8),
                  Text(
                    "Đồng bộ ImgBB Cloud",
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: const Color(0xFF374151)),
                  ),
                  if (isRunning) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(color: Color(0xFF2E6F40)),
                  ],
                  if (result != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF5EC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Đã chuyển đổi thành công:\n• ${result!['shop']} ảnh cửa hàng\n• ${result!['plants']} ảnh cây\n• ${result!['diaries']} bài nhật ký",
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A24)),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!isRunning && result == null)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text("Hủy", style: GoogleFonts.inter(color: Colors.grey)),
                  ),
                ElevatedButton(
                  onPressed: isRunning
                      ? null
                      : () async {
                          if (result != null) {
                            Navigator.pop(dialogCtx);
                            return;
                          }
                          setDialogState(() {
                            isRunning = true;
                            status = "Đang kết nối ImgBB Cloud và tải ảnh...";
                          });

                          final res = await MigrationService.runFullMigration(
                            onProgress: (msg) {
                              setDialogState(() {
                                status = msg;
                              });
                            },
                          );

                          setDialogState(() {
                            isRunning = false;
                            result = res;
                            status = "Quá trình đồng bộ hoàn tất!";
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E6F40),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    result != null ? "Đóng" : (isRunning ? "Đang xử lý..." : "Bắt đầu chuyển đổi"),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
