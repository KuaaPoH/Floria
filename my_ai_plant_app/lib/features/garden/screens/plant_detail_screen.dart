import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'plant_diary_screen.dart';
import '../../scan/screens/scan_screen.dart';

class PlantDetailScreen extends StatelessWidget {
  final Map<String, dynamic> plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActionRow(context),
                  const SizedBox(height: 30),
                  _buildBiologyGrid(context),
                  const SizedBox(height: 30),
                  _buildReminders(context),
                  const SizedBox(height: 30),
                  _buildStats(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: const Color(0xFFF5F7FA),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.black, size: 20),
              onPressed: () {},
            ),
          ),
        )
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              plant["imageUrl"] ?? "https://lh3.googleusercontent.com/aida-public/AB6AXuBiZs5eUGXmj0jlx6gFHEYNBjCo7qFQPjazLiMR7P_kGJSgq9_swlNr_-j08tqMX1KACvRRzHnOd2N_FQQPvOx4mF3AqGrBNXI-kHcJJVH2rbFj3FHfzbwmcX-IjO0kXdPEtj62UqrPh9UsQgAisEnQvAPxam024yQMHeuKcR2myhxMw9zn-3hZtLUqF0XgWKEOEr5jEZfETawOHYhRbBhP1jsl2Qn9KasfcCUPvqmjdaXezxB9EKD85pd6eHhZTI52uRGSXZlXelo",
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFFF5F7FA).withValues(alpha: 1),
                    const Color(0xFFF5F7FA).withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.4],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, color: Color(0xFF006D35), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "Sức khỏe: Tốt 98%",
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF006D35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plant["title"] ?? "Cây Trầu Bà",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanScreen()));
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_camera, color: Color(0xFF006D35)),
                  const SizedBox(width: 8),
                  Text(
                    "Quét Bệnh",
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF006D35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PlantDiaryScreen()));
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book, color: Color(0xFF006D35)),
                  const SizedBox(width: 8),
                  Text(
                    "Nhật Ký",
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF006D35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBiologyGrid(BuildContext context) {
    return Row(
      children: [
        _buildBioCard(Icons.wb_sunny, "Ánh sáng", "Ưa bóng râm", const Color(0xFFFDB878), const Color(0xFF86521B)),
        const SizedBox(width: 12),
        _buildBioCard(Icons.water_drop, "Tưới nước", "3 ngày/lần", const Color(0xFF91D78A), const Color(0xFF2A6B2C)),
        const SizedBox(width: 12),
        _buildBioCard(Icons.thermostat, "Nhiệt độ", "20-25°C", const Color(0xFF62FF96), const Color(0xFF006D35)),
      ],
    );
  }

  Widget _buildBioCard(IconData icon, String title, String value, Color bgColor, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bgColor.withValues(alpha: 0.3), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.beVietnamPro(fontSize: 10, color: const Color(0xFF3B4A3D), letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminders(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Lịch Chăm Sóc",
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            Text(
              "Xem tất cả",
              style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF006D35)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildReminderItem(Icons.water_drop, "Tưới nước", "Hôm nay, 08:00 AM", const Color(0xFF006D35), true),
        const SizedBox(height: 12),
        _buildReminderItem(Icons.eco, "Bón phân NPK", "Còn 3 ngày nữa", const Color(0xFF86521B), false),
      ],
    );
  }

  Widget _buildReminderItem(IconData icon, String title, String time, Color color, bool isDone) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: GoogleFonts.beVietnamPro(fontSize: 13, color: const Color(0xFF3B4A3D)),
                ),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDone ? color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: isDone ? color : Colors.grey.shade400, width: 2),
            ),
            child: isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
          )
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 140,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tăng trưởng", style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF3B4A3D))),
                    const Spacer(),
                    Text("+12%", style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF006D35))),
                    Text("So với tháng trước", style: GoogleFonts.beVietnamPro(fontSize: 11, color: const Color(0xFF3B4A3D))),
                  ],
                ),
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(Icons.trending_up, size: 80, color: Colors.black.withValues(alpha: 0.03)),
                )
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 140,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Độ ẩm đất", style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF3B4A3D))),
                    const Spacer(),
                    Text("65%", style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF2A6B2C))),
                    Text("Mức lý tưởng", style: GoogleFonts.beVietnamPro(fontSize: 11, color: const Color(0xFF3B4A3D))),
                  ],
                ),
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(Icons.water_drop, size: 80, color: Colors.black.withValues(alpha: 0.03)),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
