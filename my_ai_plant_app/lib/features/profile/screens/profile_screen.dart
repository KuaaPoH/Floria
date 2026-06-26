import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import 'premium_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigate; // Callback de chuyen tab tu trang ca nhan
  const ProfileScreen({super.key, this.onNavigate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final String name = authProvider.userName ?? "Tuấn Nguyễn";
    final String email = authProvider.userEmail ?? "tuan@example.com";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuANPLjeFXrAvn9dHtMEZXQXJiU8Ol79-KlXfsIpwwj1E5CaTAz7DuisRoZDKPe1JzuZgYnS5K8Mgiu4FYC1VAkXEVyruaG7TeNOQg4xpKesRSLMhLI3JajuvB0AysglsresuKuJTKMHeIgCDtQCXwm24ls_3MXiNxCeTgEghtP_liQgKweDER5rpvvreR0eMHyCnZeQlQT_iu_M0QQwGIasimd6YfOlSe7cynmjqgra60Lxjn9DEbb7xQrkiBWPoRUOfTHh2PyJ4OY'
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(width: 16),
                  // User Details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (authProvider.isPremium) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.workspace_premium, // Biểu tượng vương miện / huy hiệu VIP
                              color: Color(0xFFFFD700), // Màu vàng kim
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Premium CTA Banner (Chỉ hiển thị khi CHƯA nâng cấp lên PRO)
            if (!authProvider.isPremium) ...[
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0C5216), Color(0xFF002203)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F9D58).withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Floria Pro',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.lock,
                          color: Color(0xFFFFD700),
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bạn đang dùng bản Miễn Phí. Nâng cấp để mở khóa mô hình Floria 1.0 Pro.',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PremiumScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: const Color(0xFF2D1600),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Đăng Ký Trả Phí',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),

            // 3. Settings Groups
            _buildGroupTitle("TÙY CHỈNH"),
            const SizedBox(height: 8),
            _buildSettingsContainer([
              _buildSettingTile(
                icon: Icons.edit_outlined,
                title: "Chỉnh sửa hồ sơ",
                onTap: () {},
              ),
              _buildSettingTile(
                icon: Icons.notifications_none_outlined,
                title: "Cài đặt thông báo",
                suffixWidget: Switch(
                  value: _notificationEnabled,
                  activeThumbColor: const Color(0xFF00E676),
                  onChanged: (val) {
                    setState(() {
                      _notificationEnabled = val;
                    });
                  },
                ),
              ),
              _buildSettingTile(
                icon: Icons.language_outlined,
                title: "Ngôn ngữ",
                valueText: "Tiếng Việt",
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),

            _buildGroupTitle("HỖ TRỢ & CỘNG ĐỒNG"),
            const SizedBox(height: 8),
            _buildSettingsContainer([
              _buildSettingTile(
                icon: Icons.headset_mic_outlined,
                title: "Trung tâm hỗ trợ",
                onTap: () {},
              ),
              _buildSettingTile(
                icon: Icons.star_outline,
                title: "Đánh giá ứng dụng",
                suffixWidget: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                    Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                    Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                    Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                    Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                  ],
                ),
              ),
              _buildSettingTile(
                icon: Icons.share_outlined,
                title: "Chia sẻ ứng dụng",
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),

            _buildGroupTitle("TÀI KHOẢN"),
            const SizedBox(height: 8),
            _buildSettingsContainer([
              _buildSettingTile(
                icon: Icons.logout_outlined,
                title: "Đăng xuất",
                titleColor: Colors.red[700],
                iconColor: Colors.red[700],
                iconBgColor: Colors.red[50],
                showArrow: false,
                onTap: () {
                  authProvider.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false, // Xoa sach stack man hinh de quay lai Login
                  );
                },
              ),
            ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
     ),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Text(
        title,
        style: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black38,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    Color? titleColor,
    Color? iconColor,
    Color? iconBgColor,
    String? valueText,
    Widget? suffixWidget,
    bool showArrow = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBgColor ?? const Color(0xFFF2FCEF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? const Color(0xFF0F9D58),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (valueText != null) ...[
                  Text(
                    valueText,
                    style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.black45),
                  ),
                  const SizedBox(width: 8),
                ],
                ?suffixWidget,
                if (showArrow && suffixWidget == null)
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.black26,
                    size: 20,
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
