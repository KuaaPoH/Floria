import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'camera_scanning_screen.dart';
import '../../history/screens/history_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_tr.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface.withValues(alpha: 0.8),
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Text(
          context.tr('Hướng dẫn chụp ảnh', 'Photo Guide'),
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: c.textPrimary),
            tooltip: context.tr('Lịch sử quét', 'Scan History'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildGuideSection(),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CameraScanningScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withValues(alpha: 0.25),
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
                        context.tr("Mở camera ngay", "Open Camera Now"),
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
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Để AI nhận diện tốt nhất', 'For Best AI Recognition'),
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.border),
              boxShadow: [
                BoxShadow(
                  color: c.shadow,
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
                        Icon(Icons.check_circle, color: c.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('Nên', 'Dos'),
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: c.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Ánh sáng tốt', 'Good Lighting'),
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary),
                          ),
                          Text(
                            context.tr('Đảm bảo đủ sáng tự nhiên.', 'Ensure adequate natural light.'),
                            style: GoogleFonts.inter(fontSize: 13, color: c.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('Đưa lá vào trung tâm', 'Center the Leaf'),
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary),
                          ),
                          Text(
                            context.tr('Chụp rõ một lá bệnh duy nhất.', 'Focus clearly on a single diseased leaf.'),
                            style: GoogleFonts.inter(fontSize: 13, color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: c.border, height: 1),
                ),
                // KHÔNG NÊN
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cancel, color: c.textMuted, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('Không nên', 'Don\'ts'),
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: c.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Chụp trong bóng râm', 'Shooting in Shadows'),
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary),
                          ),
                          Text(
                            context.tr('Tránh các vùng tối che khuất chi tiết.', 'Avoid dark areas obscuring details.'),
                            style: GoogleFonts.inter(fontSize: 13, color: c.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('Hình ảnh mờ nhòe', 'Blurry Images'),
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary),
                          ),
                          Text(
                            context.tr('Giữ chắc tay để AI nhận diện chính xác.', 'Hold steady for accurate AI diagnosis.'),
                            style: GoogleFonts.inter(fontSize: 13, color: c.textSecondary),
                          ),
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
}
