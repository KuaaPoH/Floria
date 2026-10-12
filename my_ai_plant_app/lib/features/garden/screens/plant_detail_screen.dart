import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'plant_diary_screen.dart';
import '../../../core/widgets/custom_image.dart';
import '../../scan/screens/scan_screen.dart';
import '../models/garden_plant.dart';
import '../providers/garden_provider.dart';

class PlantDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? plant;
  final GardenPlant? gardenPlant;

  const PlantDetailScreen({
    super.key,
    this.plant,
    this.gardenPlant,
  });

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
                        _buildCareSchedule(context),
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
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Color(0xFF1B1C1A), size: 24),
                  padding: EdgeInsets.zero,
                  onSelected: (val) async {
                    if (val == 'delete' && gardenPlant != null) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text("Xóa khỏi vườn?", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          content: Text("Bạn có chắc muốn xóa cây '${gardenPlant!.nickname}' khỏi khu vườn của mình không?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text("Hủy", style: GoogleFonts.inter(color: Colors.grey.shade700)),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text("Xóa", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await Provider.of<GardenProvider>(context, listen: false).removePlant(gardenPlant!.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Đã xóa '${gardenPlant!.nickname}' khỏi khu vườn."),
                              backgroundColor: const Color(0xFF364534),
                            ),
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (gardenPlant != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text("Xóa khỏi vườn", style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    final imgUrl = gardenPlant?.imageUrl ?? plant?["imageUrl"] ?? "https://picsum.photos/seed/plant4/400/400";
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: Stack(
        children: [
          SizedBox(
            height: 360,
            width: double.infinity,
            child: CustomImage(
              imageUrl: imgUrl,
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
    final title = gardenPlant?.nickname ?? plant?["title"] ?? "Cây cảnh";
    final sciName = gardenPlant?.scientificName ?? plant?["scientificName"] ?? "";
    final location = gardenPlant?.zone ?? plant?["location"] ?? "Phòng khách";
    final isWaterNeeded = gardenPlant?.isNeedsWater ?? false;
    final statusText = isWaterNeeded ? "Cần tưới nước" : (gardenPlant?.healthStatus ?? plant?["status"] ?? "Khỏe mạnh");
    final statusBg = isWaterNeeded ? const Color(0xFFFFF3E0) : const Color(0xFFE8F2E3);
    final statusFg = isWaterNeeded ? const Color(0xFFE06C00) : const Color(0xFF364534);

    final light = gardenPlant?.wikiData['light'] ?? "Nắng bán phần";
    final waterFreq = gardenPlant != null
        ? "Mỗi ${gardenPlant!.waterFrequencyDays} ngày"
        : (plant?["waterFrequency"] ?? "Tưới 2-3 lần/tuần");
    final temp = gardenPlant?.wikiData['temperature'] ?? "18-30°C";

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
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B1C1A),
                      ),
                    ),
                    if (sciName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        sciName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF6A756B),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Color(0xFF747871)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Vị trí: $location",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF747871),
                              fontWeight: FontWeight.w500,
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
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isWaterNeeded ? Icons.water_drop : Icons.check_circle,
                      color: statusFg,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusFg,
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
              _buildMetricItem(Icons.light_mode, light),
              _buildMetricItem(Icons.water_drop, waterFreq),
              _buildMetricItem(Icons.device_thermostat, temp),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Trợ lý AI Gemini sắp ra mắt trong bản cập nhật tới! 🤖🌱"),
                  backgroundColor: Color(0xFF364534),
                ),
              );
            },
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

  Widget _buildCareSchedule(BuildContext context) {
    final isWaterNeeded = gardenPlant?.isNeedsWater ?? false;
    final waterStatusText = isWaterNeeded
        ? "Đã đến hạn tưới nước (Bấm để tưới)"
        : (gardenPlant != null
            ? "Còn ${gardenPlant!.daysUntilWater} ngày đến lượt tưới"
            : "Hôm nay");
    final timeColor = isWaterNeeded ? const Color(0xFFEA580C) : const Color(0xFF364534);

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
              GestureDetector(
                onTap: () async {
                  if (gardenPlant != null) {
                    await Provider.of<GardenProvider>(context, listen: false).waterPlant(gardenPlant!.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Đã tưới nước cho '${gardenPlant!.nickname}'! 💧 Lần tưới tiếp theo sau ${gardenPlant!.waterFrequencyDays} ngày."),
                          backgroundColor: const Color(0xFF364534),
                        ),
                      );
                    }
                  }
                },
                child: _buildTaskItem(
                  icon: Icons.water_drop,
                  title: "Tưới nước (${gardenPlant?.waterFrequencyDays ?? 3} ngày/lần)",
                  time: waterStatusText,
                  timeIcon: isWaterNeeded ? Icons.warning_amber_rounded : Icons.schedule,
                  timeColor: timeColor,
                  isDone: !isWaterNeeded,
                  isLast: false,
                ),
              ),
              _buildTaskItem(
                icon: Icons.eco,
                title: "Kiểm tra sâu bệnh",
                time: "Định kỳ hôm nay",
                timeIcon: Icons.done,
                timeColor: const Color(0xFF747871),
                isDone: true,
                isLast: true,
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
