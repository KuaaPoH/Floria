import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'plant_diary_screen.dart';
import '../../../core/widgets/custom_image.dart';
import '../../scan/screens/scan_screen.dart';
import '../../chatbot/screens/ai_assistant_screen.dart';
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
    return Consumer<GardenProvider>(
      builder: (context, gardenProvider, child) {
        // Tìm cây mới nhất từ provider theo ID để đồng bộ thời gian thực
        final GardenPlant? currentGardenPlant = gardenPlant != null
            ? gardenProvider.plants.firstWhere(
                (p) => p.id == gardenPlant!.id,
                orElse: () => gardenPlant!,
              )
            : null;

        return Scaffold(
          backgroundColor: const Color(0xFFFBF9F6), // background
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    _buildHeroImage(context, currentGardenPlant),
                    Transform.translate(
                      offset: const Offset(0, -48), // Overlap image by 48px
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMainInfoCard(context, currentGardenPlant),
                            const SizedBox(height: 24),
                            _buildQuickActions(context, currentGardenPlant),
                            const SizedBox(height: 32),
                            _buildCareSchedule(context, currentGardenPlant),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildTopBar(context, currentGardenPlant),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, GardenPlant? currentPlant) {
    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);

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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Color(0xFF1B1C1A), size: 24),
                  padding: EdgeInsets.zero,
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  elevation: 10,
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Color(0xFFE4E2DF), width: 1),
                  ),
                  onSelected: (val) async {
                    if (currentPlant == null) return;

                    if (val == 'edit') {
                      _showEditPlantModal(context, currentPlant);
                    } else if (val == 'water') {
                      await gardenProvider.waterPlant(currentPlant.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Đã tưới nước cho '${currentPlant.nickname}'! 💧"),
                            backgroundColor: const Color(0xFF364534),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else if (val == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          surfaceTintColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text("Xóa khỏi vườn?", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1A))),
                          content: Text("Bạn có chắc muốn xóa cây '${currentPlant.nickname}' khỏi khu vườn của mình không?", style: GoogleFonts.inter(color: const Color(0xFF444842))),
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
                        await gardenProvider.removePlant(currentPlant.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Đã xóa '${currentPlant.nickname}' khỏi khu vườn."),
                              backgroundColor: const Color(0xFF364534),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (currentPlant != null) ...[
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF364534).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit_outlined, color: Color(0xFF364534), size: 16),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Chỉnh sửa cây",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1B1C1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'water',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF006D35).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.water_drop_outlined, color: Color(0xFF006D35), size: 16),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Đã tưới nước hôm nay",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1B1C1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Xóa khỏi vườn",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context, GardenPlant? currentPlant) {
    final imgUrl = currentPlant?.imageUrl ?? plant?["imageUrl"] ?? "https://picsum.photos/seed/plant4/400/400";
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.45)],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard(BuildContext context, GardenPlant? currentPlant) {
    final title = currentPlant?.nickname ?? plant?["title"] ?? "Cây cảnh";
    final sciName = currentPlant?.scientificName ?? plant?["scientificName"] ?? "";
    final location = currentPlant?.zone ?? plant?["location"] ?? "Phòng khách";
    final isWaterNeeded = currentPlant?.isNeedsWater ?? false;
    final healthStatus = currentPlant?.healthStatus ?? plant?["status"] ?? "Khỏe mạnh";
    final statusText = isWaterNeeded ? "Cần tưới nước" : healthStatus;

    Color statusBg = const Color(0xFFE8F2E3);
    Color statusFg = const Color(0xFF364534);
    IconData statusIcon = Icons.check_circle;

    if (isWaterNeeded || healthStatus == 'Cần tưới nước') {
      statusBg = const Color(0xFFFFF3E0);
      statusFg = const Color(0xFFE06C00);
      statusIcon = Icons.water_drop;
    } else if (healthStatus == 'Bị sâu bệnh' || healthStatus == 'Bị vàng lá') {
      statusBg = const Color(0xFFFFEBEE);
      statusFg = const Color(0xFFD32F2F);
      statusIcon = Icons.warning_amber_rounded;
    } else if (healthStatus == 'Cần chú ý') {
      statusBg = const Color(0xFFFFF8E1);
      statusFg = const Color(0xFFF57F17);
      statusIcon = Icons.priority_high;
    }

    final light = currentPlant?.wikiData['light'] ?? "Sáng yếu đến trung bình";
    final waterFreq = currentPlant != null
        ? "Mỗi ${currentPlant.waterFrequencyDays} ngày"
        : (plant?["waterFrequency"] ?? "Tưới 2-3 lần/tuần");
    final temp = currentPlant?.wikiData['temperature'] ?? "18-28°C";

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
                    Icon(statusIcon, color: statusFg, size: 14),
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
            width: 40,
            height: 40,
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

  Widget _buildQuickActions(BuildContext context, GardenPlant? currentPlant) {
    return Row(
      children: [
        // 1. Nút Chi tiết (Thông tin sinh học bách khoa của cây)
        Expanded(
          child: _buildActionBtn(
            icon: Icons.info_outline,
            label: "Chi tiết",
            isPrimary: false,
            onTap: () => _showPlantWikiModal(context, currentPlant),
          ),
        ),
        const SizedBox(width: 8),
        // 2. Nút Quét bệnh
        Expanded(
          child: _buildActionBtn(
            icon: Icons.photo_camera,
            label: "Quét bệnh",
            isPrimary: false,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
          ),
        ),
        const SizedBox(width: 8),
        // 3. Nút Nhật ký
        Expanded(
          child: _buildActionBtn(
            icon: Icons.menu_book,
            label: "Nhật ký",
            isPrimary: false,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantDiaryScreen())),
          ),
        ),
        const SizedBox(width: 8),
        // 4. Nút Floria AI (Tập trung chuyên sâu cho loài cây này)
        Expanded(
          child: _buildActionBtn(
            icon: Icons.auto_awesome,
            label: "Floria AI",
            isPrimary: true,
            iconColor: const Color(0xFFFFD700), // Gold star
            onTap: () {
              final plantName = currentPlant?.nameVi ?? plant?["title"] ?? "Cây cảnh";
              final sciName = currentPlant?.scientificName ?? plant?["scientificName"] ?? "";
              final status = currentPlant?.healthStatus ?? plant?["status"] ?? "Khỏe mạnh";
              final zone = currentPlant?.zone ?? plant?["location"] ?? "Phòng khách";
              final freq = currentPlant?.waterFrequencyDays ?? 3;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AiAssistantScreen(
                    plantNameVi: plantName,
                    scientificName: sciName,
                    diseaseContext: "Cây '$plantName' ở vị trí $zone, tình trạng: $status. Tần suất tưới: $freq ngày/lần.",
                  ),
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
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFF364534).withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ]
              : [
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
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : const Color(0xFF1B1C1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareSchedule(BuildContext context, GardenPlant? currentPlant) {
    final isWaterNeeded = currentPlant?.isNeedsWater ?? false;
    final waterStatusText = isWaterNeeded
        ? "Đã đến hạn tưới nước (Bấm để tưới)"
        : (currentPlant != null
            ? "Còn ${currentPlant.daysUntilWater} ngày đến lượt tưới"
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
            if (currentPlant != null)
              GestureDetector(
                onTap: () => _showEditPlantModal(context, currentPlant),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF364534).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_calendar_outlined, size: 14, color: Color(0xFF364534)),
                      const SizedBox(width: 4),
                      Text(
                        "Chỉnh sửa",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF364534),
                        ),
                      ),
                    ],
                  ),
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
                  if (currentPlant != null) {
                    await Provider.of<GardenProvider>(context, listen: false).waterPlant(currentPlant.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Đã tưới nước cho '${currentPlant.nickname}'! 💧 Lần tưới tiếp theo sau ${currentPlant.waterFrequencyDays} ngày."),
                          backgroundColor: const Color(0xFF364534),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: _buildTaskItem(
                  icon: Icons.water_drop,
                  title: "Tưới nước (${currentPlant?.waterFrequencyDays ?? 3} ngày/lần • ${currentPlant?.reminderTime ?? '07:00'})",
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

  // MODAL 1: CHỈNH SỬA TOÀN DIỆN THÔNG TIN CÂY (Tên, Vị trí, Tần suất tưới, Tình trạng, Giờ nhắc)
  void _showEditPlantModal(BuildContext context, GardenPlant plantItem) {
    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);

    final TextEditingController nameCtrl = TextEditingController(text: plantItem.nickname);
    final TextEditingController noteCtrl = TextEditingController(text: plantItem.notes);
    String selectedZone = plantItem.zone;
    String selectedHealth = plantItem.healthStatus;
    int frequencyDays = plantItem.waterFrequencyDays;
    String reminderTime = plantItem.reminderTime;

    final List<String> zoneSuggestions = [
      "Phòng khách",
      "Ban công",
      "Cửa sổ",
      "Bàn làm việc",
      "Sân thượng",
      "Phòng ngủ",
    ];

    final List<String> healthOptions = [
      "Khỏe mạnh",
      "Cần tưới nước",
      "Bị vàng lá",
      "Bị sâu bệnh",
      "Cần chú ý",
    ];

    final List<Map<String, String>> presetTimes = [
      {"label": "🌅 07:00", "time": "07:00"},
      {"label": "🌤️ 09:30", "time": "09:30"},
      {"label": "🌇 17:30", "time": "17:30"},
      {"label": "🌙 20:00", "time": "20:00"},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFFBF9F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4E8CE),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Chỉnh sửa cây trồng",
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B1C1A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF747871)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 1. Tên biệt danh
                    Text(
                      "Tên hiển thị / Biệt danh:",
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1B1C1A)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Ví dụ: Em sen đá nhỏ, Cây tài lộc...",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2DF))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2DF))),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Vị trí đặt cây
                    Text(
                      "Vị trí đặt cây (Góc vườn):",
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1B1C1A)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: zoneSuggestions.map((z) {
                        final isSelected = selectedZone == z;
                        return ChoiceChip(
                          label: Text(z),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedZone = z);
                          },
                          selectedColor: const Color(0xFF364534),
                          backgroundColor: Colors.white,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF1B1C1A),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isSelected ? const Color(0xFF364534) : const Color(0xFFE4E2DF)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 3. Tình trạng sức khỏe cây
                    Text(
                      "Tình trạng sức khỏe hiện tại:",
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1B1C1A)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: healthOptions.map((h) {
                        final isSelected = selectedHealth == h;
                        Color chipColor = const Color(0xFF364534);
                        if (h == 'Bị sâu bệnh' || h == 'Bị vàng lá') chipColor = const Color(0xFFD32F2F);
                        if (h == 'Cần tưới nước') chipColor = const Color(0xFFE06C00);

                        return ChoiceChip(
                          label: Text(h),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedHealth = h);
                          },
                          selectedColor: chipColor,
                          backgroundColor: Colors.white,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF1B1C1A),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isSelected ? chipColor : const Color(0xFFE4E2DF)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 4. Tần suất tưới nước
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tần suất tưới nước:",
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1B1C1A)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF364534).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "Mỗi $frequencyDays ngày / lần",
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF364534)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: frequencyDays.toDouble(),
                      min: 1,
                      max: 14,
                      divisions: 13,
                      activeColor: const Color(0xFF364534),
                      inactiveColor: const Color(0xFFE4E2DF),
                      label: "$frequencyDays ngày/lần",
                      onChanged: (val) {
                        setModalState(() => frequencyDays = val.round());
                      },
                    ),
                    const SizedBox(height: 12),

                    // 5. Khung giờ nhắc nhở tưới
                    Text(
                      "Khung giờ nhắc nhở:",
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1B1C1A)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: presetTimes.map((item) {
                        final isSelected = reminderTime == item["time"];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => reminderTime = item["time"]!),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF364534) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF364534) : const Color(0xFFE4E2DF),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                item["label"]!,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : const Color(0xFF1B1C1A),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 6. Ghi chú riêng
                    Text(
                      "Ghi chú chăm sóc:",
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1B1C1A)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Ví dụ: Đặt cạnh cửa sổ hướng đông, tưới buổi sáng...",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2DF))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2DF))),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nút Lưu thay đổi
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final newName = nameCtrl.text.trim();
                          final newNotes = noteCtrl.text.trim();
                          Navigator.pop(ctx);

                          final success = await gardenProvider.updatePlantInfo(
                            plantItem.id,
                            nickname: newName.isNotEmpty ? newName : plantItem.nameVi,
                            zone: selectedZone,
                            waterFrequencyDays: frequencyDays,
                            reminderTime: reminderTime,
                            healthStatus: selectedHealth,
                            notes: newNotes,
                          );

                          if (context.mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Đã cập nhật thông tin cây '${newName.isNotEmpty ? newName : plantItem.nameVi}' thành công! 🌿"),
                                  backgroundColor: const Color(0xFF364534),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF364534),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(
                          "Lưu thay đổi",
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // MODAL 2: XEM BÁCH KHOA TOÀN THƯ THỰC VẬT CỦA CÂY (Nút "Chi tiết")
  void _showPlantWikiModal(BuildContext context, GardenPlant? currentPlant) {
    final title = currentPlant?.nameVi ?? plant?["title"] ?? "Cây cảnh";
    final sciName = currentPlant?.scientificName ?? plant?["scientificName"] ?? "";
    final wiki = currentPlant?.wikiData ?? const {};

    final light = wiki['light'] ?? "Sáng yếu đến trung bình";
    final water = wiki['watering'] ?? "Tưới khi lớp đất mặt khô 2-3 cm";
    final temp = wiki['temperature'] ?? "18 - 28°C";
    final humidity = wiki['humidity'] ?? "50 - 70%";
    final soil = wiki['soil'] ?? "Đất tơi xốp, thoát nước tốt";
    final fertilizer = wiki['fertilizer'] ?? "Bón phân NPK pha loãng 1 tháng/lần";
    final toxicity = wiki['toxicity'] ?? "An toàn / Đang cập nhật";
    final difficulty = wiki['difficulty'] ?? "Dễ chăm sóc";
    final description = wiki['description'] ?? "Loài cây cảnh tuyệt đẹp giúp thanh lọc không khí và mang lại sinh khí tươi mới cho không gian sống của bạn.";
    final family = wiki['family'] ?? "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 28),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFFBF9F6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4E8CE),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B1C1A),
                            ),
                          ),
                          if (sciName.isNotEmpty)
                            Text(
                              sciName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: const Color(0xFF6A756B),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF747871)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Lưới 3 Thẻ Thông Tin Nổi Bật (Độ khó, Họ cây, Phân loại)
                () {
                  String shortDifficulty = "Trung bình";
                  Color diffBg = const Color(0xFFFFF3E0);
                  Color diffFg = const Color(0xFFE65100);

                  final lowerDiff = difficulty.toLowerCase();
                  if (lowerDiff.contains("khó")) {
                    shortDifficulty = "Khó";
                    diffBg = const Color(0xFFFFEBEE);
                    diffFg = const Color(0xFFD32F2F);
                  } else if (lowerDiff.contains("dễ")) {
                    shortDifficulty = "Dễ";
                    diffBg = const Color(0xFFE8F5E9);
                    diffFg = const Color(0xFF2E7D32);
                  } else if (lowerDiff.contains("trung bình")) {
                    shortDifficulty = "Trung bình";
                    diffBg = const Color(0xFFFFF8E1);
                    diffFg = const Color(0xFFF57F17);
                  }

                  String shortFamily = family.isNotEmpty ? family : "Chưa phân loại";
                  if (shortFamily.contains("(")) {
                    shortFamily = shortFamily.split("(").first.trim();
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _buildSummaryMiniCard(
                          icon: Icons.military_tech_outlined,
                          label: "ĐỘ KHÓ",
                          value: shortDifficulty,
                          badgeColor: diffBg,
                          textColor: diffFg,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryMiniCard(
                          icon: Icons.spa_outlined,
                          label: "HỌ THỰC VẬT",
                          value: shortFamily,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryMiniCard(
                          icon: Icons.category_outlined,
                          label: "PHÂN LOẠI",
                          value: currentPlant?.plantType ?? "Cây cảnh",
                        ),
                      ),
                    ],
                  );
                }(),
                const SizedBox(height: 10),

                // Thẻ lưu ý chi tiết về độ khó nếu có giải thích dài (đảm bảo thoáng đãng, không tràn viền)
                if (difficulty.trim().isNotEmpty && (difficulty.length > 15 || difficulty.contains("."))) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.tips_and_updates_outlined, color: Color(0xFFE65100), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Lưu ý về độ khó & môi trường:",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE65100),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                difficulty,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: const Color(0xFF5D4037),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Mô tả
                Text(
                  "Đặc tính sinh học",
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1B1C1A)),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: const Color(0xFF444842)),
                ),
                const SizedBox(height: 20),

                // Lưới thông số chăm sóc chuẩn
                Text(
                  "Yêu cầu sinh thái chuẩn bách khoa",
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1B1C1A)),
                ),
                const SizedBox(height: 12),

                _buildWikiInfoRow(Icons.light_mode_outlined, "Ánh sáng", light),
                _buildWikiInfoRow(Icons.water_drop_outlined, "Nước tưới", water),
                _buildWikiInfoRow(Icons.thermostat_outlined, "Nhiệt độ", temp),
                _buildWikiInfoRow(Icons.cloud_outlined, "Độ ẩm", humidity),
                _buildWikiInfoRow(Icons.terrain_outlined, "Đất trồng", soil),
                _buildWikiInfoRow(Icons.science_outlined, "Phân bón", fertilizer),
                _buildWikiInfoRow(Icons.pets_outlined, "Độc tính", toxicity),

                const SizedBox(height: 24),
                // Nút chuyển ngay sang AI hỏi thêm
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AiAssistantScreen(
                            plantNameVi: title,
                            scientificName: sciName,
                            diseaseContext: "Tôi cần hỏi chuyên sâu về đặc tính bách khoa của loài cây $title ($sciName).",
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 18),
                    label: Text(
                      "Hỏi Floria AI sâu hơn về loài cây này",
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF364534),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryMiniCard({
    required IconData icon,
    required String label,
    required String value,
    Color? badgeColor,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: badgeColor ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: textColor ?? const Color(0xFF364534)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF747871),
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor ?? const Color(0xFF1B1C1A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWikiInfoRow(IconData icon, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E2DF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF364534).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF364534), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1B1C1A)),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF444842)),
                ),
              ],
            ),
          ),
        ],
      ),
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
        color: isDone ? const Color(0xFFF5F3F0) : Colors.transparent,
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
              width: 40,
              height: 40,
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
            width: 24,
            height: 24,
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
