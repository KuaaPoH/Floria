import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'camera_scanning_screen.dart';
import '../../profile/screens/premium_screen.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String _selectedModel = 'floria_vision';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F6).withOpacity(0.8),
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Text(
          'Hướng dẫn chụp ảnh',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B1C1A),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildGuideSection(),
            const SizedBox(height: 32),
            _buildAiModelSection(),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CameraScanningScreen(selectedModel: _selectedModel)));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF364534), // primary
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF364534).withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_camera, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        "Mở camera ngay",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Để AI nhận diện tốt nhất',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1B1C1A)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE4E2DF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // NÊN
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF364534), size: 18),
                        const SizedBox(width: 8),
                        Text('Nên', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF364534))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ánh sáng tốt', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1B1C1A))),
                          Text('Đảm bảo đủ sáng tự nhiên.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF444842))),
                          const SizedBox(height: 12),
                          Text('Đưa lá vào trung tâm', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1B1C1A))),
                          Text('Chụp rõ một lá bệnh duy nhất.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF444842))),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Color(0xFFE4E2DF), height: 1),
                ),
                // KHÔNG NÊN
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cancel, color: Color(0xFF444842), size: 18),
                        const SizedBox(width: 8),
                        Text('Không nên', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF444842))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chụp trong bóng râm', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1B1C1A))),
                          Text('Tránh các vùng tối che khuất chi tiết.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF444842))),
                          const SizedBox(height: 12),
                          Text('Hình ảnh mờ nhòe', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1B1C1A))),
                          Text('Giữ chắc tay để AI nhận diện chính xác.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF444842))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiModelSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chọn mô hình AI',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1B1C1A)),
              ),
              const Icon(Icons.info, color: Color(0xFF747871), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          _buildModelItem(
            id: 'floria_flash',
            title: 'Floria Flash',
            subtitle: 'Nhanh & Cơ bản',
            icon: Icons.bolt,
            iconColor: Colors.orange,
            iconBg: Colors.orange.shade50,
          ),
          const SizedBox(height: 12),
          _buildModelItem(
            id: 'floria_vision',
            title: 'Floria Vision',
            subtitle: 'Cân bằng nhất',
            icon: Icons.visibility,
            iconColor: const Color(0xFF364534), // Primary
            iconBg: Colors.white,
          ),
          const SizedBox(height: 12),
          _buildModelItem(
            id: 'floria_pro',
            title: 'Floria Pro',
            subtitle: 'Phân tích sâu',
            icon: Icons.psychology,
            iconColor: Colors.purple,
            iconBg: Colors.purple.shade50,
          ),
          const SizedBox(height: 12),
          _buildModelItem(
            id: 'floria_platinum',
            title: 'Floria Platinum',
            subtitle: 'Độ chính xác 99%',
            icon: Icons.diamond,
            iconColor: Colors.yellow.shade400,
            iconBg: Colors.white.withOpacity(0.1),
            isPremium: true,
          ),
        ],
      ),
    );
  }

  Widget _buildModelItem({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    bool isPremium = false,
  }) {
    final bool active = _selectedModel == id;

    return GestureDetector(
      onTap: () {
        if (isPremium) {
           Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
           return;
        }
        setState(() {
          _selectedModel = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPremium ? const Color(0xFF1F2937) : (active ? const Color(0xFFF4F8F3) : Colors.white),
          gradient: isPremium ? const LinearGradient(colors: [Color(0xFF111827), Color(0xFF374151)]) : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? const Color(0xFF364534) : (isPremium ? Colors.transparent : const Color(0xFFE4E2DF)),
            width: active || isPremium ? 2 : 1,
          ),
          boxShadow: active && !isPremium ? [
            BoxShadow(
              color: const Color(0xFF364534).withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPremium ? Colors.white.withOpacity(0.1) : iconBg,
                shape: BoxShape.circle,
                boxShadow: active || isPremium ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isPremium ? Colors.white : (active ? const Color(0xFF364534) : const Color(0xFF1B1C1A)),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isPremium ? Colors.grey.shade300 : (active ? const Color(0xFF364534).withOpacity(0.8) : const Color(0xFF444842)),
                    ),
                  ),
                ],
              ),
            ),
            if (active && !isPremium)
              const Icon(Icons.check_circle, color: Color(0xFF364534), size: 24),
            if (isPremium)
              Icon(Icons.star, color: Colors.yellow.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
