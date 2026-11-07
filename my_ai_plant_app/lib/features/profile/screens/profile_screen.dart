import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../garden/providers/garden_provider.dart';
import 'address_payment_screen.dart';
import 'settings_screen.dart';
import 'support_center_screen.dart';
import 'watering_reminders_screen.dart';
import '../../history/screens/history_screen.dart';
import '../../shop/screens/order_history_screen.dart';
import '../models/floria_avatar_preset.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigate; // Callback de chuyen tab tu trang ca nhan
  const ProfileScreen({super.key, this.onNavigate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  void _showModernToast(String message, {bool isError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        duration: const Duration(seconds: 3),
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? const Color(0xFF2D1618) : const Color(0xFF1E2D22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isError
                      ? const Color(0xFFFF6B6B).withValues(alpha: 0.35)
                      : const Color(0xFF66BB6A).withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isError
                          ? const Color(0xFFFF6B6B).withValues(alpha: 0.18)
                          : const Color(0xFF4CAF50).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isError ? Icons.error_outline_rounded : Icons.check_rounded,
                      color: isError ? const Color(0xFFFF8A80) : const Color(0xFF81C784),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                      ),
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

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 75,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.updateAvatar(bytes);

      if (!mounted) return;
      if (success) {
        _showModernToast("Cập nhật ảnh đại diện thành công!");
      } else {
        _showModernToast("Không thể lưu ảnh đại diện. Vui lòng thử lại!", isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showModernToast("Lỗi chọn ảnh: $e", isError: true);
    }
  }

  void _showAvatarOptions(BuildContext context, AuthProvider authProvider) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr("Ảnh đại diện", "Profile picture"),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.isDark ? c.surfaceTint : const Color(0xFF2E6F40).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.spa_rounded, color: c.primaryText),
              ),
              title: Text(
                context.tr("Bộ sưu tập Avatar Floria", "Floria Avatar presets"),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              subtitle: Text(
                context.tr("Chọn linh vật thực vật Floria (Mầm Xanh, Monstera, Sen Đá...)", "Choose a plant mascot (Sprout, Monstera, Succulent...)"),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: c.textMuted,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showFloriaPresetAvatarPicker(context, authProvider);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.isDark ? c.surfaceTint : const Color(0xFF3E8055).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt, color: c.primaryText),
              ),
              title: Text(
                context.tr("Chụp ảnh mới", "Take new photo"),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.isDark ? c.surfaceTint : const Color(0xFF3E8055).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library, color: c.primaryText),
              ),
              title: Text(
                context.tr("Chọn từ thư viện ảnh máy", "Choose from gallery"),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            if (authProvider.hasCustomAvatar)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restore, color: Colors.orange),
                ),
                title: Text(
                  context.tr("Dùng Avatar mặc định Floria", "Use default Floria avatar"),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                subtitle: Text(
                  context.tr("Quay về ảnh đại diện thực vật khởi đầu", "Revert to initial plant avatar"),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: c.textMuted,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await authProvider.resetToDefaultAvatar();
                  _showModernToast(context.tr("Đã chuyển về Avatar mặc định Floria!", "Reverted to default Floria avatar!"));
                },
              ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.isDark ? c.surfaceTint : const Color(0xFF4F9D69).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit_note, color: c.primaryText),
              ),
              title: Text(
                context.tr("Đổi tên & tiểu sử", "Edit name & bio"),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showEditProfileDialog(context, authProvider);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider) {
    final c = context.colors;
    final nameController = TextEditingController(text: authProvider.userName ?? "");
    final bioController = TextEditingController(
      text: authProvider.bio ?? context.tr("Chăm cây trong nhà theo nhịp nhẹ, đều và đẹp mắt.", "Caring for indoor plants with a steady, mindful routine."),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.isDark ? c.surfaceTint : const Color(0xFFE5F4EA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.edit_note_rounded, color: c.primaryText, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr("Đổi tên & tiểu sử", "Edit name & bio"),
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: GoogleFonts.inter(color: c.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: context.tr("Tên hiển thị", "Display name"),
                    prefixIcon: Icon(Icons.person_outline_rounded, color: c.primaryText, size: 20),
                    labelStyle: GoogleFonts.inter(color: c.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: c.surfaceMuted,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.isDark ? c.border : const Color(0xFF4F9D69).withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.primaryText, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  style: GoogleFonts.inter(color: c.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: context.tr("Tiểu sử / Giới thiệu hồ sơ", "Bio / Profile introduction"),
                    prefixIcon: Icon(Icons.eco_outlined, color: c.primaryText, size: 20),
                    labelStyle: GoogleFonts.inter(color: c.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: c.surfaceMuted,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.isDark ? c.border : const Color(0xFF4F9D69).withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.primaryText, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr("Hủy", "Cancel"), style: GoogleFonts.inter(color: c.textMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3E8055),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newName = nameController.text.trim();
              final newBio = bioController.text.trim();
              await authProvider.updateProfileInfo(
                name: newName,
                bio: newBio,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _showModernToast(context.tr("Đã cập nhật tên & tiểu sử!", "Profile updated successfully!"));
            },
            child: Text(context.tr("Lưu", "Save"), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(String photoUrl, String name) {
    if (photoUrl.startsWith('preset:')) {
      final preset = FloriaAvatarPreset.getById(photoUrl);
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: preset.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          preset.icon,
          size: 38,
          color: preset.iconColor,
        ),
      );
    }
    if (photoUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(photoUrl.split(',').last);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(name),
        );
      } catch (_) {
        return _buildDefaultAvatar(name);
      }
    }
    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint("❌ [ProfileScreen] Lỗi tải avatar: $error, URL: $photoUrl");
        return _buildDefaultAvatar(name);
      },
    );
  }

  Widget _buildDefaultAvatar(String name) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'F';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E6F40), Color(0xFF52B788)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 4,
            bottom: 4,
            child: Icon(
              Icons.spa_rounded,
              size: 26,
              color: Colors.white.withValues(alpha: 0.28),
            ),
          ),
          Text(
            initial,
            style: GoogleFonts.outfit(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showFloriaPresetAvatarPicker(BuildContext context, AuthProvider authProvider) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.isDark ? c.surfaceTint : const Color(0xFFE5F4EA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.spa_rounded, color: c.primaryText, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  context.tr("Bộ sưu tập Avatar Floria", "Floria Avatar presets"),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                "Chọn một biểu tượng thực vật làm ảnh đại diện cho trang cá nhân của bạn:",
                "Choose a plant mascot as your profile avatar:",
              ),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: c.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.88,
              ),
              itemCount: FloriaAvatarPreset.allPresets.length,
              itemBuilder: (context, index) {
                final preset = FloriaAvatarPreset.allPresets[index];
                final isSelected = authProvider.effectivePhotoUrl == 'preset:${preset.id}';

                return InkWell(
                  onTap: () async {
                    Navigator.pop(ctx);
                    final ok = await authProvider.selectPresetAvatar(preset.id);
                    if (ok) {
                      _showModernToast(context.tr("Đã chọn Avatar: ${preset.name}! 🌱", "Selected avatar: ${preset.name}! 🌱"));
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? (c.isDark ? c.surfaceTint : const Color(0xFFF0F7F2)) : c.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? c.primaryText : c.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: preset.gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: preset.gradientColors.first.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(preset.icon, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          preset.name,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final authProvider = Provider.of<AuthProvider>(context);
    final gardenProvider = Provider.of<GardenProvider>(context);
    final String name = authProvider.userName ?? "Nông Nghiệp Thông Minh";
    final String email = authProvider.userEmail ?? "user@example.com";
    final String bio = authProvider.bio ?? context.tr('Chăm cây trong nhà theo nhịp nhẹ, đều và đẹp mắt.', 'Caring for indoor plants with a steady, mindful routine.');
    final String? photoUrl = authProvider.effectivePhotoUrl;
    final int plantCount = gardenProvider.allUserPlants.length;
    final int needsWaterCount = gardenProvider.allUserPlants.where((p) => p.isNeedsWater).length;
    final int healthyCount = gardenProvider.allUserPlants.where((p) => p.healthStatus == 'Khỏe mạnh').length;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('TÀI KHOẢN CỦA BẠN', 'YOUR ACCOUNT'),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: c.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('Cá nhân', 'Profile'),
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.isDark ? c.surface : null,
                  gradient: c.isDark ? null : const LinearGradient(
                    colors: [Color(0xEEF7F1EE), Color(0xEBFFFFFF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.isDark ? c.border : const Color(0xFF4F9D69).withValues(alpha: 0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow.withValues(alpha: c.isDark ? 0.3 : 0.05),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _showAvatarOptions(context, authProvider),
                              child: Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: c.surfaceTint,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4F9D69).withValues(alpha: 0.24),
                                      blurRadius: 26,
                                      offset: const Offset(0, 16),
                                    )
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: authProvider.isUploadingAvatar
                                    ? const Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Color(0xFF3E8055),
                                          ),
                                        ),
                                      )
                                    : (photoUrl != null && photoUrl.isNotEmpty)
                                        ? _buildAvatarImage(photoUrl, name)
                                        : _buildDefaultAvatar(name),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _showAvatarOptions(context, authProvider),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: c.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: c.isDark ? c.border : const Color(0xFF4F9D69).withValues(alpha: 0.2)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: c.shadow.withValues(alpha: 0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 13,
                                    color: c.primaryText,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: c.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined, size: 16, color: c.textMuted),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: context.tr("Chỉnh sửa thông tin", "Edit profile"),
                                    onPressed: () => _showEditProfileDialog(context, authProvider),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: GoogleFonts.inter(fontSize: 13, color: c.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bio,
                                style: GoogleFonts.inter(fontSize: 13, color: c.textMuted),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildStatBox(context, context.tr('Đang chăm', 'Gardening'), plantCount.toString(), context.tr('cây', 'plants')),
                        const SizedBox(width: 12),
                        _buildStatBox(context, context.tr('Cần tưới', 'Need water'), needsWaterCount.toString(), context.tr('cây', 'plants')),
                        const SizedBox(width: 12),
                        _buildStatBox(context, context.tr('Khỏe mạnh', 'Healthy'), healthyCount.toString(), context.tr('cây', 'plants')),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Soft Card (Tóm tắt tuần này)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.surface.withValues(alpha: c.isDark ? 1.0 : 0.84),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.isDark ? c.border : const Color(0xFF4F9D69).withValues(alpha: 0.14)),
                  boxShadow: [
                    BoxShadow(color: c.shadow.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('TÓM TẮT TUẦN NÀY', 'THIS WEEK SUMMARY'),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                  color: c.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.tr('Nhịp chăm ổn định và gọn gàng', 'Steady and neat care routine'),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: c.isDark ? c.surfaceTint : const Color(0xFFE5F4EA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            context.tr('+120 điểm', '+120 pts'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr(
                        'Bạn đã hoàn thành 5 lần tưới đúng giờ, 2 lần quét lá và được tặng thêm điểm để đổi ưu đãi giảm giá.',
                        'You completed 5 on-time waterings, 2 plant scans and earned reward points for discounts.',
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: c.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Shortcuts
              Column(
                children: [
                  _buildShortcutRow(
                    context: context,
                    icon: Icons.local_shipping_outlined,
                    title: context.tr('Địa chỉ & Thanh toán', 'Address & Payment'),
                    desc: context.tr('Sổ địa chỉ nhận hàng và thẻ ngân hàng đã lưu.', 'Shipping addresses and saved cards.'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddressAndPaymentScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildShortcutRow(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    title: context.tr('Đơn hàng của tôi', 'My Orders'),
                    desc: context.tr('Theo dõi trạng thái giao hàng và lịch sử mua vật tư.', 'Track deliveries and supply purchases.'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildShortcutRow(
                    context: context,
                    icon: Icons.history,
                    title: context.tr('Lịch sử quét', 'Scan History'),
                    desc: context.tr('Xem lại các chẩn đoán và giống cây đã nhận diện.', 'Review past diagnoses and identified plants.'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildShortcutRow(
                    context: context,
                    icon: Icons.water_drop_outlined,
                    title: context.tr('Nhắc tưới', 'Watering Reminders'),
                    desc: context.tr('Việc chăm sóc hôm nay, quyền thiết bị và chế độ không làm phiền.', 'Today care tasks, permissions and DND.'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WateringRemindersScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildShortcutRow(
                    context: context,
                    icon: Icons.headset_mic_outlined,
                    title: context.tr('Trung tâm hỗ trợ', 'Support Center'),
                    desc: context.tr('Câu hỏi thường gặp và thông tin liên hệ hỗ trợ.', 'FAQ and contact information.'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SupportCenterScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildShortcutRow(
                    context: context,
                    icon: Icons.settings_outlined,
                    title: context.tr('Cài đặt', 'Settings'),
                    desc: context.tr('Thông báo, ngôn ngữ và quyền hiển thị.', 'Notifications, language and display.'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildShortcutRow(
                    context: context,
                    icon: Icons.logout_outlined,
                    title: context.tr('Đăng xuất', 'Sign out'),
                    desc: context.tr('Đăng xuất khỏi tài khoản trên thiết bị này.', 'Sign out of your account on this device.'),
                    onTap: () {
                      authProvider.logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(BuildContext context, String label, String value, String unit) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface.withValues(alpha: c.isDark ? 1.0 : 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.isDark ? c.border : const Color(0xFF4F9D69).withValues(alpha: 0.14)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: c.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: c.primaryText),
            ),
            Text(
              unit,
              style: GoogleFonts.inter(fontSize: 11, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
    bool isHighlight = false,
    bool isDestructive = false,
  }) {
    final c = context.colors;
    final Color iconColor = isDestructive ? Colors.red[400]! : (isHighlight ? const Color(0xFFD1A34D) : c.primaryText);
    final Color iconBgColor = isDestructive ? Colors.red.withValues(alpha: 0.1) : (isHighlight ? const Color(0xFFD1A34D).withValues(alpha: 0.1) : (c.isDark ? c.surfaceTint : const Color(0xFF4F9D69).withValues(alpha: 0.08)));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.surface.withValues(alpha: c.isDark ? 1.0 : 0.76),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.isDark ? c.border : const Color(0xFF4F9D69).withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red[400] : c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: c.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
