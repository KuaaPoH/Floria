import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../garden/providers/garden_provider.dart';
import 'address_payment_screen.dart';
import 'settings_screen.dart';
import '../../history/screens/history_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigate; // Callback de chuyen tab tu trang ca nhan
  const ProfileScreen({super.key, this.onNavigate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Ảnh đại diện",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2A21),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E8055).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF3E8055)),
              ),
              title: Text(
                "Chụp ảnh mới",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2A21),
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
                  color: const Color(0xFF3E8055).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library, color: Color(0xFF3E8055)),
              ),
              title: Text(
                "Chọn từ thư viện",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2A21),
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
                  "Dùng lại ảnh Google mặc định",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2A21),
                  ),
                ),
                subtitle: Text(
                  "Xóa ảnh đại diện riêng và hiển thị ảnh tài khoản Google ban đầu",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6A756B),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await authProvider.resetToDefaultAvatar();
                  _showModernToast("Đã chuyển về ảnh đại diện Google mặc định!");
                },
              ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F9D69).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_note, color: Color(0xFF4F9D69)),
              ),
              title: Text(
                "Đổi tên & tiểu sử",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2A21),
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
    final nameController = TextEditingController(text: authProvider.userName ?? "");
    final bioController = TextEditingController(
      text: authProvider.bio ?? "Chăm cây trong nhà theo nhịp nhẹ, đều và đẹp mắt.",
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F4EA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_note_rounded, color: Color(0xFF3E8055), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Đổi tên & tiểu sử",
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2A21),
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
                  style: GoogleFonts.inter(color: const Color(0xFF1F2A21), fontSize: 14),
                  decoration: InputDecoration(
                    labelText: "Tên hiển thị",
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF3E8055), size: 20),
                    labelStyle: GoogleFonts.inter(color: const Color(0xFF6A756B), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF5F7F3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFF4F9D69).withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3E8055), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  style: GoogleFonts.inter(color: const Color(0xFF1F2A21), fontSize: 14),
                  decoration: InputDecoration(
                    labelText: "Tiểu sử / Giới thiệu hồ sơ",
                    prefixIcon: const Icon(Icons.eco_outlined, color: Color(0xFF3E8055), size: 20),
                    labelStyle: GoogleFonts.inter(color: const Color(0xFF6A756B), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF5F7F3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFF4F9D69).withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3E8055), width: 1.5),
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
            child: Text("Hủy", style: GoogleFonts.inter(color: const Color(0xFF6A756B), fontWeight: FontWeight.w600)),
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
              _showModernToast("Đã cập nhật tên & tiểu sử!");
            },
            child: Text("Lưu", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(String photoUrl, String name) {
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
      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(name),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'F';
    return Container(
      color: const Color(0xFFE5F4EA),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF3E8055),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final gardenProvider = Provider.of<GardenProvider>(context);
    final String name = authProvider.userName ?? "Nông Nghiệp Thông Minh";
    final String email = authProvider.userEmail ?? "user@example.com";
    final String bio = authProvider.bio ?? 'Chăm cây trong nhà theo nhịp nhẹ, đều và đẹp mắt.';
    final String? photoUrl = authProvider.effectivePhotoUrl;
    final int plantCount = gardenProvider.allUserPlants.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
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
                        'TÀI KHOẢN CỦA BẠN',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: const Color(0xFF6A756B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cá nhân',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                          color: const Color(0xFF1F2A21),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xEEF7F1EE), Color(0xEBFFFFFF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF17231A).withValues(alpha: 0.05),
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
                                  color: const Color(0xFFE5F4EA),
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
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.2)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF17231A).withValues(alpha: 0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 13,
                                    color: Color(0xFF3E8055),
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
                                        color: const Color(0xFF1F2A21),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF6A756B)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: "Chỉnh sửa thông tin",
                                    onPressed: () => _showEditProfileDialog(context, authProvider),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6A756B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bio,
                                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6A756B)),
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
                        _buildStatBox('Đang chăm', plantCount.toString(), 'cây'),
                        const SizedBox(width: 12),
                        _buildStatBox('Streak', '27', 'ngày'),
                        const SizedBox(width: 12),
                        _buildStatBox('Điểm', '1.280', 'điểm'),
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
                  color: Colors.white.withValues(alpha: 0.84),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.14)),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF17231A).withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8))
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
                                'TÓM TẮT TUẦN NÀY',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                  color: const Color(0xFF6A756B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Nhịp chăm ổn định và gọn gàng',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F2A21),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F4EA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '+120 điểm',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3E8055),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bạn đã hoàn thành 5 lần tưới đúng giờ, 2 lần quét lá và được tặng thêm điểm để đổi ưu đãi giảm giá.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6A756B),
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
                    icon: Icons.local_shipping_outlined,
                    title: 'Địa chỉ & Thanh toán',
                    desc: 'Sổ địa chỉ nhận hàng và thẻ ngân hàng đã lưu.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddressAndPaymentScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildShortcutRow(
                    icon: Icons.history,
                    title: 'Lịch sử quét',
                    desc: 'Xem lại các chẩn đoán và giống cây đã nhận diện.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildShortcutRow(
                    icon: Icons.water_drop_outlined,
                    title: 'Nhắc tưới',
                    desc: 'Tinh chỉnh thời điểm cho từng chậu cây trong nhà.',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildShortcutRow(
                    icon: Icons.headset_mic_outlined,
                    title: 'Trung tâm hỗ trợ',
                    desc: 'Liên hệ với chúng tôi để được giải đáp thắc mắc.',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildShortcutRow(
                    icon: Icons.settings_outlined,
                    title: 'Cài đặt',
                    desc: 'Thông báo, ngôn ngữ và quyền hiển thị.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildShortcutRow(
                    icon: Icons.logout_outlined,
                    title: 'Đăng xuất',
                    desc: 'Đăng xuất khỏi tài khoản trên thiết bị này.',
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

  Widget _buildStatBox(String label, String value, String unit) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.14)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6A756B)),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF3E8055)),
            ),
            Text(
              unit,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6A756B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutRow({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
    bool isHighlight = false,
    bool isDestructive = false,
  }) {
    final Color iconColor = isDestructive ? Colors.red[600]! : (isHighlight ? const Color(0xFFD1A34D) : const Color(0xFF3E8055));
    final Color iconBgColor = isDestructive ? Colors.red.withValues(alpha: 0.08) : (isHighlight ? const Color(0xFFD1A34D).withValues(alpha: 0.1) : const Color(0xFF4F9D69).withValues(alpha: 0.08));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.14)),
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
                      color: isDestructive ? Colors.red[700] : const Color(0xFF1F2A21),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF6A756B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF6A756B), size: 20),
          ],
        ),
      ),
    );
  }
}
