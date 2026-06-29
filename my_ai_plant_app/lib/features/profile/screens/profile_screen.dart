import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import 'premium_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigate; // Callback de chuyen tab tu trang ca nhan
  const ProfileScreen({super.key, this.onNavigate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final String name = authProvider.userName ?? "Mai Nguyễn";
    final String email = authProvider.userEmail ?? "mainguyen@example.com";

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
                  if (authProvider.isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F4EA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Premium',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3E8055),
                        ),
                      ),
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
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF4F9D69).withValues(alpha: 0.24), blurRadius: 26, offset: const Offset(0, 16))
                            ],
                            image: const DecorationImage(
                              image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuANPLjeFXrAvn9dHtMEZXQXJiU8Ol79-KlXfsIpwwj1E5CaTAz7DuisRoZDKPe1JzuZgYnS5K8Mgiu4FYC1VAkXEVyruaG7TeNOQg4xpKesRSLMhLI3JajuvB0AysglsresuKuJTKMHeIgCDtQCXwm24ls_3MXiNxCeTgEghtP_liQgKweDER5rpvvreR0eMHyCnZeQlQT_iu_M0QQwGIasimd6YfOlSe7cynmjqgra60Lxjn9DEbb7xQrkiBWPoRUOfTHh2PyJ4OY'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.12)),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF17231A).withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))
                              ],
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 12,
                              color: Color(0xFF3E8055),
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
                              Text(
                                name,
                                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1F2A21)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6A756B)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Chăm cây trong nhà theo nhịp nhẹ, đều và đẹp mắt.',
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
                        _buildStatBox('Đang chăm', '12', 'cây'),
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
                    icon: Icons.history,
                    title: 'Lịch sử quét',
                    desc: 'Xem lại các chẩn đoán và giống cây đã nhận diện.',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildShortcutRow(
                    icon: Icons.water_drop_outlined,
                    title: 'Nhắc tưới',
                    desc: 'Tinh chỉnh thời điểm cho từng chậu cây trong nhà.',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  if (!authProvider.isPremium) ...[
                    _buildShortcutRow(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Gói Premium',
                      desc: 'Theo dõi insight sâu hơn và mở khoá Floria 1.0 Pro.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PremiumScreen()),
                        );
                      },
                      isHighlight: true,
                    ),
                    const SizedBox(height: 12),
                  ],
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
