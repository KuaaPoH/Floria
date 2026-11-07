import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_tr.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/migration_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    final authProvider = Provider.of<AuthProvider>(context);
    final settings = context.watch<AppSettingsProvider>();
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.surface.withValues(alpha: 0.82),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(color: c.shadow.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Icon(Icons.chevron_left, color: c.textPrimary),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('Cài đặt', 'Settings'),
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Group 1: HIỂN THỊ
          _buildGroupTitle(context.tr('HIỂN THỊ', 'DISPLAY')),
          const SizedBox(height: 8),
          _buildSettingsContainer([
            _buildToggleTile(
              icon: Icons.dark_mode_outlined,
              title: context.tr('Giao diện tối', 'Dark mode'),
              value: settings.isDark,
              onChanged: (val) => settings.setDarkMode(val),
            ),
            _divider(),
            _buildArrowTile(
              icon: Icons.language_outlined,
              title: context.tr('Ngôn ngữ', 'Language'),
              valueText: settings.isEnglish ? 'English' : 'Tiếng Việt',
              onTap: () => _showLanguageSheet(settings),
            ),
          ]),
          const SizedBox(height: 24),

          // Group 2: TÙY CHỈNH
          _buildGroupTitle(context.tr('TÙY CHỈNH', 'PREFERENCES')),
          const SizedBox(height: 8),
          _buildSettingsContainer([
            _buildToggleTile(
              icon: Icons.notifications_none_outlined,
              title: context.tr('Nhắc nhở tưới cây & chăm sóc', 'Watering & care reminders'),
              value: _notificationsEnabled,
              onChanged: (val) async {
                setState(() => _notificationsEnabled = val);
                await NotificationService.setEnabled(val);
              },
            ),
            _divider(),
            _buildArrowTile(
              icon: Icons.notifications_active_outlined,
              title: context.tr('Kiểm tra thử thông báo ngay', 'Send a test notification'),
              valueText: context.tr('Thử ngay', 'Try now'),
              onTap: () {
                NotificationService.showTestNotification(context);
              },
            ),
            _divider(),
            _buildToggleTile(
              icon: Icons.image_outlined,
              title: context.tr('Lưu ảnh quét vào Thư viện', 'Save scans to Gallery'),
              value: _saveImages,
              onChanged: (val) => setState(() => _saveImages = val),
            ),
          ]),
          const SizedBox(height: 24),

          // Group 2.4: TÀI KHOẢN & BẢO MẬT
          _buildGroupTitle(context.tr('TÀI KHOẢN & BẢO MẬT', 'ACCOUNT & SECURITY')),
          const SizedBox(height: 8),
          _buildSettingsContainer([
            if (authProvider.canChangePassword)
              _buildArrowTile(
                icon: Icons.lock_reset_rounded,
                title: context.tr('Đổi mật khẩu', 'Change password'),
                valueText: context.tr('Gửi qua email', 'Via email'),
                onTap: () => _showChangePasswordDialog(context, authProvider),
              )
            else
              _buildValueTile(
                title: context.tr('Đăng nhập bằng Google', 'Signed in with Google'),
                valueText: context.tr('Do Google quản lý', 'Managed by Google'),
              ),
          ]),
          const SizedBox(height: 24),

          // Group 2.5: DỮ LIỆU & ĐÁM MÂY
          _buildGroupTitle(context.tr('DỮ LIỆU & ĐÁM MÂY', 'DATA & CLOUD')),
          const SizedBox(height: 8),
          _buildSettingsContainer([
            _buildArrowTile(
              icon: Icons.cloud_sync_rounded,
              title: context.tr('Đồng bộ ảnh sang Cloudinary', 'Sync images to Cloudinary'),
              valueText: context.tr('Đồng bộ', 'Sync'),
              onTap: () => _showMigrationDialog(context),
            ),
            _divider(),
            _buildArrowTile(
              icon: Icons.cleaning_services_outlined,
              title: context.tr('Xóa bộ nhớ đệm ảnh', 'Clear image cache'),
              valueText: context.tr('Dọn dẹp', 'Clean up'),
              onTap: _clearImageCache,
            ),
          ]),
          const SizedBox(height: 24),

          // Group 3: THÔNG TIN
          _buildGroupTitle(context.tr('THÔNG TIN', 'ABOUT')),
          const SizedBox(height: 8),
          _buildSettingsContainer([
            _buildArrowTile(
              icon: null,
              title: context.tr('Điều khoản bảo mật', 'Privacy policy'),
              onTap: () {},
            ),
            _divider(),
            _buildValueTile(
              title: context.tr('Phiên bản ứng dụng', 'App version'),
              valueText: 'v2.4.1',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, thickness: 1, color: context.colors.border.withValues(alpha: 0.6));

  /// BottomSheet chọn ngôn ngữ giao diện (chỉ đổi nhãn Hub, không dịch dữ liệu người dùng)
  void _showLanguageSheet(AppSettingsProvider settings) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        Widget option(String code, String flag, String label, String sub) {
          final selected = settings.languageCode == code;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Text(flag, style: const TextStyle(fontSize: 26)),
            title: Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
            subtitle: Text(sub, style: GoogleFonts.inter(fontSize: 12.5, color: c.textMuted)),
            trailing: selected
                ? Icon(Icons.check_circle_rounded, color: c.primaryText)
                : Icon(Icons.circle_outlined, color: c.border),
            onTap: () {
              settings.setLanguage(code);
              Navigator.pop(sheetCtx);
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('Chọn ngôn ngữ', 'Choose language'),
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    context.tr(
                      'Áp dụng cho giao diện. Tên cây, nhật ký và bài viết giữ nguyên nội dung gốc.',
                      'Applies to the interface. Plant names, diaries and articles keep their original content.',
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12.5, color: c.textMuted, height: 1.4),
                  ),
                ),
                const SizedBox(height: 8),
                option('vi', '🇻🇳', 'Tiếng Việt', 'Vietnamese'),
                option('en', '🇬🇧', 'English', 'Tiếng Anh'),
              ],
            ),
          ),
        );
      },
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
          color: context.colors.textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: c.isDark ? 1 : 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.isDark ? c.border : const Color(0xFF4F9D69).withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: 0.04),
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
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: c.isDark ? c.primaryText : const Color(0xFF4F9D69), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: c.textPrimary,
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
            inactiveTrackColor: c.isDark ? c.border : Colors.grey[300],
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
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: c.isDark ? c.primaryText : const Color(0xFF4F9D69), size: 24),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (valueText != null) ...[
                  Text(
                    valueText,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.chevron_right, color: c.textMuted, size: 20),
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
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: c.textPrimary,
            ),
          ),
          Text(
            valueText,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
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
                    isError ? Icons.error_outline_rounded : Icons.mark_email_read_outlined,
                    color: isError ? const Color(0xFFFF8A80) : const Color(0xFF81C784),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      message,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3),
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

  /// Đổi mật khẩu: dùng lại luồng gửi email đặt lại mật khẩu giống màn hình Đăng nhập
  void _showChangePasswordDialog(BuildContext context, AuthProvider authProvider) {
    final email = authProvider.userEmail ?? '';
    final c = context.colors;
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: c.primaryText),
              const SizedBox(width: 8),
              Text(
                context.tr('Đổi mật khẩu', 'Change password'),
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  'Floria sẽ gửi một đường dẫn đổi mật khẩu đến email của bạn:',
                  'Floria will send a password reset link to your email:',
                ),
                style: GoogleFonts.inter(fontSize: 13.5, color: c.textMuted, height: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: c.isDark ? c.surfaceTint : const Color(0xFFEAF5EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.mail_outline_rounded, size: 18, color: c.primaryText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        email,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: c.isDark ? c.textPrimary : const Color(0xFF1E3A24)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr(
                  'Mở email và bấm vào đường dẫn để đặt mật khẩu mới. Nếu không thấy, hãy kiểm tra thư mục Spam.',
                  'Open the email and tap the link to set a new password. If you can\'t find it, check your Spam folder.',
                ),
                style: GoogleFonts.inter(fontSize: 12.5, color: c.textMuted, height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(dialogCtx),
              child: Text(context.tr('Hủy', 'Cancel'), style: GoogleFonts.inter(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isSending || email.isEmpty
                  ? null
                  : () async {
                      final sentMsg = context.tr(
                        'Đã gửi thư đổi mật khẩu về $email. Vui lòng kiểm tra hộp thư!',
                        'Password reset email sent to $email. Please check your inbox!',
                      );
                      setDialogState(() => isSending = true);
                      final error = await authProvider.resetPassword(email);
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      if (error == null) {
                        _showToast(sentMsg);
                      } else {
                        _showToast(error, isError: true);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E6F40),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isSending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(context.tr('Gửi email', 'Send email'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  /// Dọn bộ nhớ đệm ảnh đang giữ trong RAM (ảnh sẽ được tải lại khi cần)
  void _clearImageCache() {
    final cache = PaintingBinding.instance.imageCache;
    final count = cache.currentSize;
    cache.clear();
    cache.clearLiveImages();
    _showToast(context.tr('Đã dọn dẹp $count ảnh trong bộ nhớ đệm.', 'Cleared $count cached images.'));
  }

  void _showMigrationDialog(BuildContext context) {
    final c = context.colors;
    String status = context.tr(
      "Chuyển toàn bộ ảnh Unsplash, ảnh cũ và ảnh Base64 sang Cloudinary Cloud hoàn toàn miễn phí, lưu trữ vĩnh viễn và tối ưu tốc độ tải.",
      "Move all Unsplash, legacy and Base64 images to Cloudinary Cloud for free, permanent storage and faster loading.",
    );
    final connectingMsg = context.tr("Đang kết nối Cloudinary Cloud và tải ảnh...", "Connecting to Cloudinary Cloud and uploading...");
    final doneMsg = context.tr("Quá trình đồng bộ hoàn tất!", "Sync completed!");
    bool isRunning = false;
    Map<String, int>? result;

    showDialog(
      context: context,
      barrierDismissible: !isRunning,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: c.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.cloud_sync_rounded, color: c.primaryText),
                  const SizedBox(width: 8),
                  Text(
                    context.tr("Đồng bộ Cloudinary Cloud", "Cloudinary Cloud sync"),
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: c.isDark ? c.textSecondary : const Color(0xFF374151)),
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
                        color: c.isDark ? c.surfaceTint : const Color(0xFFEAF5EC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        context.tr(
                          "Đã chuyển đổi thành công:\n• ${result!['shop']} ảnh cửa hàng\n• ${result!['plants']} ảnh cây\n• ${result!['diaries']} bài nhật ký",
                          "Successfully migrated:\n• ${result!['shop']} shop images\n• ${result!['plants']} plant images\n• ${result!['diaries']} diary posts",
                        ),
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.isDark ? c.textPrimary : const Color(0xFF1E3A24)),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!isRunning && result == null)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text(context.tr("Hủy", "Cancel"), style: GoogleFonts.inter(color: Colors.grey)),
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
                            status = connectingMsg;
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
                            status = doneMsg;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E6F40),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    result != null
                        ? context.tr("Đóng", "Close")
                        : (isRunning ? context.tr("Đang xử lý...", "Processing...") : context.tr("Bắt đầu chuyển đổi", "Start migration")),
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
