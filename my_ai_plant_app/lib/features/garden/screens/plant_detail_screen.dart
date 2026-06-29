import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'plant_diary_screen.dart';
import '../../../core/widgets/custom_image.dart';
import '../../scan/screens/scan_screen.dart';

class PlantDetailScreen extends StatelessWidget {
  final Map<String, dynamic> plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F6), // background
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                _buildHeroImage(context),
                Transform.translate(
                  offset: const Offset(0, -48), // Overlap image by 48px
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMainInfoCard(),
                        const SizedBox(height: 24),
                        _buildQuickActions(context),
                        const SizedBox(height: 32),
                        _buildCareSchedule(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildTopBar(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.keyboard_arrow_left, color: Color(0xFF1B1C1A), size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_horiz, color: Color(0xFF1B1C1A), size: 24),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: Stack(
        children: [
          SizedBox(
            height: 360,
            width: double.infinity,
            child: CustomImage(
              imageUrl: plant["imageUrl"] ?? "https://picsum.photos/seed/plant4/400/400",
              width: double.infinity,
              height: 360,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE4E2DF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF364534).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
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
                      plant["title"] ?? "Bàng Singapore",
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B1C1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Color(0xFF747871)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Nhà của tôi • ${plant["location"] ?? 'Ban công'}",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF747871),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2E3), // Light green bg
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF364534), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      plant["status"] ?? "Khỏe mạnh",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF364534),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFE4E2DF), height: 1),
          ),
          Row(
            children: [
              _buildMetricItem(Icons.light_mode, "Nắng bán phần"),
              _buildMetricItem(Icons.water_drop, "Tưới 2 lần/tuần"),
              _buildMetricItem(Icons.device_thermostat, "18-28°C"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String text) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40, height: 40,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F8F3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF364534), size: 20),
          ),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1B1C1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionBtn(
            icon: Icons.photo_camera,
            label: "Quét bệnh",
            isPrimary: false,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionBtn(
            icon: Icons.menu_book,
            label: "Nhật ký",
            isPrimary: false,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantDiaryScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionBtn(
            icon: Icons.auto_awesome,
            label: "Floria AI",
            isPrimary: true,
            iconColor: const Color(0xFFFFD700), // Gold star
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required bool isPrimary,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF364534) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: const Color(0xFFE4E2DF)),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: const Color(0xFF364534).withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: iconColor ?? (isPrimary ? Colors.white : const Color(0xFF364534)),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isPrimary ? Colors.white : const Color(0xFF1B1C1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Lịch chăm sóc",
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B1C1A),
              ),
            ),
            Row(
              children: [
                Text(
                  "Xem tất cả",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF364534),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: Color(0xFF364534)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E2DF)),
          ),
          child: Column(
            children: [
              _buildTaskItem(
                icon: Icons.water_drop,
                title: "Tưới nước",
                time: "16:00 Hôm nay",
                timeIcon: Icons.schedule,
                timeColor: const Color(0xFFEA580C), // orange-600
                isDone: false,
                isLast: false,
              ),
              _buildTaskItem(
                icon: Icons.eco,
                title: "Bón phân",
                time: "Đã hoàn thành lúc 08:30",
                timeIcon: Icons.done,
                timeColor: const Color(0xFF747871),
                isDone: true,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFC4C8BF),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: Color(0xFF747871), size: 18),
              const SizedBox(width: 8),
              Text(
                "Thiết lập lịch định kỳ",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF747871),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem({
    required IconData icon,
    required String title,
    required String time,
    required IconData timeIcon,
    required Color timeColor,
    required bool isDone,
    required bool isLast,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF5F3F0) : Colors.transparent, // surface-container-low
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isLast ? 0 : 16),
          topRight: Radius.circular(isLast ? 0 : 16),
          bottomLeft: Radius.circular(isLast ? 16 : 0),
          bottomRight: Radius.circular(isLast ? 16 : 0),
        ),
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFE4E2DF))),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: isDone ? 0.6 : 1.0,
            child: Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE4E2DF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF364534), size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Opacity(
              opacity: isDone ? 0.6 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1B1C1A),
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(timeIcon, size: 14, color: timeColor),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: timeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFF364534) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: isDone ? const Color(0xFF364534) : const Color(0xFF747871), width: 2),
            ),
            child: isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
          ),
        ],
      ),
    );
  }
}
