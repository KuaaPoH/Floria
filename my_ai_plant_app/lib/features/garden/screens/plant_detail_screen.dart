import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'plant_diary_screen.dart';
import '../../../core/widgets/custom_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_tr.dart';
import '../../scan/screens/diagnosis_report_screen.dart';
import '../../scan/providers/scan_provider.dart';
import '../../chatbot/screens/ai_assistant_screen.dart';
import '../models/garden_plant.dart';
import '../providers/garden_provider.dart';
import '../../../core/services/notification_service.dart';

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

        final c = context.colors;

        return Scaffold(
          backgroundColor: c.background,
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
    final c = context.colors;
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
                  color: c.surface.withValues(alpha: c.isDark ? 0.95 : 0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow.withValues(alpha: c.isDark ? 0.4 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.keyboard_arrow_left, color: c.textPrimary, size: 24),
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
                  color: c.surface.withValues(alpha: c.isDark ? 0.95 : 0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow.withValues(alpha: c.isDark ? 0.4 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: c.textPrimary, size: 24),
                  padding: EdgeInsets.zero,
                  color: c.surface,
                  surfaceTintColor: c.surface,
                  elevation: 10,
                  shadowColor: c.shadow.withValues(alpha: 0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: c.border, width: 1),
                  ),
                  onSelected: (val) async {
                    if (currentPlant == null) return;

                    if (val == 'edit') {
                      _showEditPlantModal(context, currentPlant);
                    } else if (val == 'water') {
                      await gardenProvider.waterPlant(currentPlant.id);
                      NotificationService.silenceForToday(currentPlant.id, 'water');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF1E3A24),
                            elevation: 8,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            content: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.water_drop_rounded, color: Color(0xFF38BDF8), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${context.tr("Đã tưới nước cho", "Watered")} '${currentPlant.nickname}'! 💧",
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${context.tr("Lần tưới tiếp theo: sau", "Next watering in")} ${currentPlant.waterFrequencyDays} ${context.tr("ngày", "days")}.",
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFFB4F4C2),
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } else if (val == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: c.surface,
                          surfaceTintColor: c.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text(
                            context.tr("Xóa khỏi vườn?", "Delete from garden?"),
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: c.textPrimary),
                          ),
                          content: Text(
                            context.tr(
                              "Bạn có chắc muốn xóa cây '${currentPlant.nickname}' khỏi khu vườn của mình không?",
                              "Are you sure you want to remove '${currentPlant.nickname}' from your garden?",
                            ),
                            style: GoogleFonts.inter(color: c.textSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(context.tr("Hủy", "Cancel"), style: GoogleFonts.inter(color: c.textMuted)),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(context.tr("Xóa", "Delete"), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
                              content: Text(
                                "${context.tr("Đã xóa", "Deleted")} '${currentPlant.nickname}' ${context.tr("khỏi khu vườn.", "from garden.")}",
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
                              ),
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
                                color: c.surfaceTint,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.edit_outlined, color: c.textSecondary, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.tr("Chỉnh sửa cây", "Edit plant"),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
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
                                color: const Color(0xFF006D35).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.water_drop_outlined, color: Color(0xFF006D35), size: 16),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.tr("Đã tưới nước hôm nay", "Watered today"),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
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
                                color: Colors.red.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.tr("Xóa khỏi vườn", "Delete from garden"),
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
    final c = context.colors;
    final title = currentPlant?.nickname ?? plant?["title"] ?? "Cây cảnh";
    final sciName = currentPlant?.scientificName ?? plant?["scientificName"] ?? "";
    final location = currentPlant?.zone ?? plant?["location"] ?? "Phòng khách";
    final statusText = currentPlant?.effectiveStatusText ?? plant?["status"] ?? "Khỏe mạnh";

    Color statusBg = c.surfaceTint;
    Color statusFg = c.primaryText;
    IconData statusIcon = Icons.check_circle;

    if (statusText.startsWith('Bị') || statusText == 'Cần điều trị') {
      statusBg = c.isDark ? const Color(0xFF3E1E22) : const Color(0xFFFFEBEE);
      statusFg = const Color(0xFFEF5350);
      statusIcon = Icons.warning_amber_rounded;
    } else if (statusText == 'Cần tưới nước') {
      statusBg = c.isDark ? const Color(0xFF3E2D1A) : const Color(0xFFFFF3E0);
      statusFg = const Color(0xFFFFA726);
      statusIcon = Icons.water_drop;
    } else if (statusText == 'Cần bón phân') {
      statusBg = c.isDark ? const Color(0xFF3E3218) : const Color(0xFFFEF3C7);
      statusFg = const Color(0xFFFBBF24);
      statusIcon = Icons.science_rounded;
    } else if (statusText == 'Cần kiểm tra' || statusText == 'Cần chú ý') {
      statusBg = c.isDark ? const Color(0xFF3E3618) : const Color(0xFFFFF8E1);
      statusFg = const Color(0xFFFFCA28);
      statusIcon = Icons.shield_outlined;
    } else if (statusText == 'Đang phục hồi') {
      statusBg = c.isDark ? const Color(0xFF1E2D40) : const Color(0xFFDBEAFE);
      statusFg = const Color(0xFF60A5FA);
      statusIcon = Icons.autorenew_rounded;
    }

    String translatedStatus = statusText;
    if (context.isEnglish) {
      if (statusText == 'Khỏe mạnh') translatedStatus = 'Healthy';
      else if (statusText == 'Cần tưới nước') translatedStatus = 'Needs water';
      else if (statusText == 'Cần bón phân') translatedStatus = 'Needs fertilizer';
      else if (statusText == 'Cần kiểm tra') translatedStatus = 'Needs check';
      else if (statusText == 'Cần chú ý') translatedStatus = 'Needs attention';
      else if (statusText == 'Đang phục hồi') translatedStatus = 'Recovering';
      else if (statusText == 'Bị vàng lá') translatedStatus = 'Yellow leaves';
      else if (statusText == 'Bị sâu bệnh') translatedStatus = 'Pests detected';
      else if (statusText == 'Cần điều trị') translatedStatus = 'Needs treatment';
    }

    final light = currentPlant?.wikiData['light'] ?? (context.tr("Sáng yếu đến trung bình", "Low to medium light"));
    final waterFreq = currentPlant != null
        ? "${context.tr("Mỗi", "Every")} ${currentPlant.waterFrequencyDays} ${context.tr("ngày", "days")}"
        : (plant?["waterFrequency"] ?? (context.tr("Tưới 2-3 lần/tuần", "2-3 times/week")));
    final temp = currentPlant?.wikiData['temperature'] ?? "18-28°C";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: c.isDark ? 0.35 : 0.08),
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
                        color: c.textPrimary,
                      ),
                    ),
                    if (sciName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        sciName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: c.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: c.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "${context.tr("Vị trí:", "Location:")} $location",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: c.textSecondary,
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
                      translatedStatus,
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: c.border, height: 1),
          ),
          Row(
            children: [
              _buildMetricItem(context, Icons.light_mode, light),
              _buildMetricItem(context, Icons.water_drop, waterFreq),
              _buildMetricItem(context, Icons.device_thermostat, temp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(BuildContext context, IconData icon, String text) {
    final c = context.colors;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: c.surfaceTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: c.textSecondary, size: 20),
          ),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
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
            context,
            icon: Icons.info_outline,
            label: context.tr("Chi tiết", "Details"),
            isPrimary: false,
            onTap: () => _showPlantWikiModal(context, currentPlant),
          ),
        ),
        const SizedBox(width: 8),
        // 2. Nút Quét bệnh
        Expanded(
          child: _buildActionBtn(
            context,
            icon: Icons.photo_camera,
            label: context.tr("Quét bệnh", "Scan"),
            isPrimary: false,
            onTap: () => _showDiseaseScanModal(context, currentPlant),
          ),
        ),
        const SizedBox(width: 8),
        // 3. Nút Nhật ký
        Expanded(
          child: _buildActionBtn(
            context,
            icon: Icons.menu_book,
            label: context.tr("Nhật ký", "Diary"),
            isPrimary: false,
            onTap: () => _openPlantDiarySubpage(context, currentPlant),
          ),
        ),
        const SizedBox(width: 8),
        // 4. Nút Trợ lý Floria (Tập trung chuyên sâu cho loài cây này)
        Expanded(
          child: _buildActionBtn(
            context,
            icon: Icons.auto_awesome,
            label: context.tr("Trợ lý Floria", "Floria AI"),
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
                    plantId: currentPlant?.id,
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

  // Mở trang nhật ký như một subpage trượt từ phải sang trái, chừa lại 1 khoảng bên trái để lộ trang detail
  void _openPlantDiarySubpage(BuildContext context, GardenPlant? currentPlant) {
    final c = context.colors;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) {
          final screenWidth = MediaQuery.of(context).size.width;
          // Chừa lại ~50px bên trái trên mobile hoặc cân đối trên màn hình lớn để nhìn thấy trang detail
          final leftOffset = screenWidth > 500 ? (screenWidth - 460) : 48.0;

          return Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(left: leftOffset),
              child: Container(
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 28,
                      offset: const Offset(-8, 0),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: PlantDiaryScreen(
                  plant: currentPlant,
                  isSubpage: true,
                ),
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    );
  }

  // Modal chẩn đoán bệnh lá cho cây trong vườn
  void _showDiseaseScanModal(BuildContext context, GardenPlant? currentPlant) {
    final c = context.colors;
    final plantName = currentPlant?.nameVi ?? plant?["title"] ?? (context.tr("cây cảnh", "plant"));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.surfaceTint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.coronavirus_outlined, color: c.textSecondary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${context.tr("Chẩn đoán bệnh lá:", "Leaf disease diagnosis:")} $plantName",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          context.tr("Chụp cận cảnh chiếc lá nghi ngờ bị mầm bệnh", "Take a close-up photo of the suspected leaf"),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: c.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.surfaceTint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: c.textSecondary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr(
                          "Floria sẽ phân tích các vết đốm, mầm bệnh thán thư, cháy lá vi khuẩn hoặc phấn trắng và đề xuất phác đồ điều trị.",
                          "Floria will analyze spots, anthracnose, leaf blight, or powdery mildew and suggest a treatment plan.",
                        ),
                        style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handlePickAndDiagnose(context, ctx, ImageSource.camera, currentPlant),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.camera_alt, size: 20),
                      label: Text(context.tr("Chụp ảnh lá", "Take leaf photo"), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handlePickAndDiagnose(context, ctx, ImageSource.gallery, currentPlant),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.textPrimary,
                        side: BorderSide(color: c.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.photo_library, size: 20),
                      label: Text(context.tr("Chọn từ album", "Choose from gallery"), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePickAndDiagnose(
    BuildContext context,
    BuildContext modalCtx,
    ImageSource source,
    GardenPlant? currentPlant,
  ) async {
    Navigator.pop(modalCtx);
    final scanProvider = Provider.of<ScanProvider>(context, listen: false);
    await scanProvider.pickImage(source);
    if (scanProvider.selectedImage != null && context.mounted) {
      final plantName = currentPlant?.nameVi ?? plant?["title"];
      final plantId = currentPlant?.id;

      // Mở ngay màn hình báo cáo bệnh (màn hình sẽ có shimmer loading khi đang xử lý)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiagnosisReportScreen(
            isDiseaseScan: true,
            currentPlant: currentPlant,
          ),
        ),
      );

      // Gửi request chẩn đoán lên Backend Spring Boot & AI Engine
      scanProvider.uploadAndDiagnoseDisease(
        plantName: plantName,
        plantId: plantId,
      );
    }
  }

  Widget _buildActionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isPrimary,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? c.primary : c.surface,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: c.border),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ]
              : [
                  BoxShadow(
                    color: c.shadow.withValues(alpha: c.isDark ? 0.2 : 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: iconColor ?? (isPrimary ? Colors.white : c.textSecondary),
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : c.textPrimary,
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
    final c = context.colors;
    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);

    final isWaterNeeded = currentPlant?.isNeedsWater ?? false;
    final isFertDisabled = (currentPlant?.fertilizeFrequencyDays ?? 20) <= 0;
    final isFertNeeded = currentPlant?.isNeedsFertilizer ?? false;
    final isCleanNeeded = currentPlant?.isNeedsClean ?? false;

    final moisture = currentPlant?.estimatedSoilMoisture ?? 0.8;
    final moistureLabel = currentPlant?.soilMoistureLabel ?? "Độ ẩm tốt (70-80%)";

    Color moistureBarColor = const Color(0xFF2E6F40);
    if (moisture < 0.3) {
      moistureBarColor = const Color(0xFFDC2626); // Đỏ cảnh báo khô
    } else if (moisture < 0.6) {
      moistureBarColor = const Color(0xFFF59E0B); // Vàng ẩm vừa
    }

    String trMoistureLabel = moistureLabel;
    if (context.isEnglish) {
      if (moistureLabel.contains("Độ ẩm tốt")) trMoistureLabel = "Good moisture (70-80%)";
      else if (moistureLabel.contains("Đất khô")) trMoistureLabel = "Dry soil (<30%)";
      else if (moistureLabel.contains("Độ ẩm trung bình")) trMoistureLabel = "Medium moisture (30-60%)";
    }

    final hasPendingTasksToday = isWaterNeeded || isFertNeeded || isCleanNeeded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  context.tr("Lịch chăm sóc thực tế", "Actual care schedule"),
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasPendingTasksToday
                        ? (c.isDark ? const Color(0xFF3E3218) : const Color(0xFFFEF3C7))
                        : (c.isDark ? const Color(0xFF1E3A24) : const Color(0xFFDCFCE7)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasPendingTasksToday
                          ? (c.isDark ? const Color(0xFF5A4820) : const Color(0xFFFDE68A))
                          : (c.isDark ? const Color(0xFF2A5034) : const Color(0xFFBBF7D0)),
                    ),
                  ),
                  child: Text(
                    hasPendingTasksToday
                        ? context.tr("Có việc cần làm", "Tasks pending")
                        : context.tr("Đã chu toàn", "All caught up"),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: hasPendingTasksToday
                          ? (c.isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
                          : (c.isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D)),
                    ),
                  ),
                ),
              ],
            ),
            if (currentPlant != null)
              GestureDetector(
                onTap: () => _showEditPlantModal(context, currentPlant),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: c.surfaceTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 14, color: c.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        context.tr("Tùy chỉnh", "Customize"),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // 1. THANH ĐO ĐỘ ẨM ĐẤT DỰ BÁO (SOIL MOISTURE GAUGE)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
            boxShadow: [
              BoxShadow(
                color: c.shadow.withValues(alpha: c.isDark ? 0.2 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.opacity_rounded, size: 16, color: moistureBarColor),
                      const SizedBox(width: 6),
                      Text(
                        context.tr("Độ ẩm đất dự kiến:", "Estimated soil moisture:"),
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    trMoistureLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: moistureBarColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: moisture,
                  minHeight: 8,
                  backgroundColor: c.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(moistureBarColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. DANH SÁCH 3 TÁC VỤ NÔNG HỌC THỰC TẾ
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              // Tác vụ 1: Tưới nước
              GestureDetector(
                onTap: () async {
                  if (currentPlant == null) return;
                  if (!isWaterNeeded) {
                    _showActionToast(
                      context,
                      title: "${context.tr("Cây", "Plant")} '${currentPlant.nickname}' ${context.tr("chưa đến hạn tưới! 🌱", "does not need water yet! 🌱")}",
                      subtitle: "${context.tr("Độ ẩm đất vẫn tốt. Còn", "Soil moisture is good. Still")} ${currentPlant.daysUntilWater} ${context.tr("ngày nữa mới cần tưới tiếp.", "days until next watering.")}",
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xFF38BDF8),
                    );
                    return;
                  }
                  await gardenProvider.waterPlant(currentPlant.id);
                  NotificationService.silenceForToday(currentPlant.id, 'water');
                  if (context.mounted) {
                    _showActionToast(
                      context,
                      title: "${context.tr("Đã tưới nước cho", "Watered")} '${currentPlant.nickname}'! 💧",
                      subtitle: "${context.tr("Lần tưới tiếp theo: sau", "Next watering in")} ${currentPlant.waterFrequencyDays} ${context.tr("ngày.", "days.")}",
                      icon: Icons.water_drop_rounded,
                      iconColor: const Color(0xFF38BDF8),
                    );
                  }
                },
                child: _buildTaskItem(
                  context,
                  icon: Icons.water_drop_rounded,
                  title: "${context.tr("Tưới nước", "Watering")} (${currentPlant?.waterFrequencyDays ?? 3} ${context.tr("ngày/lần", "days/time")} • ${currentPlant?.reminderTime ?? '07:00'})",
                  time: isWaterNeeded
                      ? context.tr("Đã đến hạn tưới", "Due for watering")
                      : "${context.tr("Còn", "In")} ${currentPlant?.daysUntilWater ?? 0} ${context.tr("ngày đến lượt", "days")}",
                  timeIcon: isWaterNeeded ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                  timeColor: isWaterNeeded ? const Color(0xFFDC2626) : const Color(0xFF2E6F40),
                  isDone: !isWaterNeeded,
                  isLast: false,
                ),
              ),

              // Tác vụ 2: Bón phân dinh dưỡng (Tự động ẩn hoàn toàn nếu đã tắt trong tùy chỉnh)
              if (!isFertDisabled)
                GestureDetector(
                  onTap: () async {
                    if (currentPlant == null) return;
                    if (!isFertNeeded) {
                      _showActionToast(
                        context,
                        title: context.tr("Cây đã nạp đủ dưỡng chất! 🧪", "Plant already well fertilized! 🧪"),
                        subtitle: "${context.tr("Tránh bón quá liều gây sót rễ. Còn", "Avoid overfeeding. In")} ${currentPlant.daysUntilFertilizer} ${context.tr("ngày nữa mới cần bón tiếp.", "days until next fertilization.")}",
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFFF59E0B),
                      );
                      return;
                    }
                    await gardenProvider.fertilizePlant(currentPlant.id);
                    NotificationService.silenceForToday(currentPlant.id, 'fertilize');
                    if (context.mounted) {
                      _showActionToast(
                        context,
                        title: "${context.tr("Đã bón phân cho", "Fertilized")} '${currentPlant.nickname}'! 🧪",
                        subtitle: "${context.tr("Cây đã nạp đủ vi lượng. Lần tới: sau", "Nutrients added. Next:")} ${currentPlant.fertilizeFrequencyDays} ${context.tr("ngày.", "days.")}",
                        icon: Icons.science_rounded,
                        iconColor: const Color(0xFFF59E0B),
                      );
                    }
                  },
                  child: _buildTaskItem(
                    context,
                    icon: Icons.science_rounded,
                    title: "${context.tr("Bón phân vi lượng", "Fertilization")} (${currentPlant?.fertilizeFrequencyDays ?? 20} ${context.tr("ngày/lần", "days/time")})",
                    time: isFertNeeded
                        ? context.tr("Đã đến hạn bón phân", "Due for fertilization")
                        : "${context.tr("Còn", "In")} ${currentPlant?.daysUntilFertilizer ?? 0} ${context.tr("ngày đến lượt", "days")}",
                    timeIcon: isFertNeeded ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                    timeColor: isFertNeeded ? const Color(0xFFEA580C) : c.textMuted,
                    isDone: !isFertNeeded,
                    isLast: false,
                  ),
                ),

              // Tác vụ 3: Kiểm tra sâu bệnh & Lau bụi lá
              GestureDetector(
                onTap: () async {
                  if (currentPlant == null) return;
                  if (!isCleanNeeded) {
                    _showActionToast(
                      context,
                      title: context.tr("Mặt lá vẫn sạch sẽ! 🍃", "Leaves are clean! 🍃"),
                      subtitle: "${context.tr("Đã kiểm tra gần đây. Còn", "Checked recently. Still")} ${currentPlant.daysUntilCheckPest} ${context.tr("ngày nữa đến lượt kiểm tra tiếp theo.", "days until next inspection.")}",
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xFF4ADE80),
                    );
                    return;
                  }
                  await gardenProvider.cleanPlant(currentPlant.id);
                  NotificationService.silenceForToday(currentPlant.id, 'clean');
                  if (context.mounted) {
                    _showActionToast(
                      context,
                      title: context.tr("Đã kiểm tra & lau sạch lá cho cây! 🍃", "Inspected & cleaned plant leaves! 🍃"),
                      subtitle: context.tr("Bề mặt lá sạch bụi giúp cây quang hợp tối đa.", "Dust-free leaves optimize photosynthesis."),
                      icon: Icons.eco_rounded,
                      iconColor: const Color(0xFF4ADE80),
                    );
                  }
                },
                child: _buildTaskItem(
                  context,
                  icon: Icons.eco_rounded,
                  title: "${context.tr("Kiểm tra sâu bệnh & Lau lá", "Check pests & Clean leaves")} (${currentPlant?.checkPestFrequencyDays ?? 3} ${context.tr("ngày/lần", "days/time")})",
                  time: isCleanNeeded
                      ? context.tr("Đã đến hạn kiểm tra", "Due for inspection")
                      : "${context.tr("Còn", "In")} ${currentPlant?.daysUntilCheckPest ?? 0} ${context.tr("ngày đến lượt", "days")}",
                  timeIcon: isCleanNeeded ? Icons.warning_amber_rounded : Icons.done_all_rounded,
                  timeColor: isCleanNeeded ? const Color(0xFFDC2626) : c.textMuted,
                  isDone: !isCleanNeeded,
                  isLast: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. NÚT HOÀN TẤT MỌI VIỆC HÔM NAY (QUICK COMPLETE ALL TODAY)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: hasPendingTasksToday && currentPlant != null
                ? () async {
                    await gardenProvider.completeAllToday(currentPlant.id);
                    NotificationService.silenceForToday(currentPlant.id, 'water');
                    NotificationService.silenceForToday(currentPlant.id, 'fertilize');
                    NotificationService.silenceForToday(currentPlant.id, 'clean');
                    if (context.mounted) {
                      _showActionToast(
                        context,
                        title: context.tr("Tuyệt vời! Đã chu toàn mọi việc hôm nay! 🌟", "Awesome! All tasks finished today! 🌟"),
                        subtitle: "${context.tr("Mọi tác vụ đến hạn của", "All due tasks for")} '${currentPlant.nickname}' ${context.tr("đã được xử lý xong.", "are completed.")}",
                        icon: Icons.task_alt_rounded,
                        iconColor: const Color(0xFF4ADE80),
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: c.primary,
              disabledBackgroundColor: c.surfaceMuted,
              foregroundColor: Colors.white,
              disabledForegroundColor: c.textMuted,
              elevation: hasPendingTasksToday ? 3 : 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: Icon(
              hasPendingTasksToday ? Icons.done_all_rounded : Icons.check_circle_rounded,
              size: 20,
              color: hasPendingTasksToday ? Colors.white : c.textMuted,
            ),
            label: Text(
              hasPendingTasksToday
                  ? context.tr("Hoàn tất mọi việc hôm nay", "Complete all tasks today")
                  : context.tr("Đã hoàn thành mọi việc hôm nay", "All tasks completed today"),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: hasPendingTasksToday ? Colors.white : c.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showActionToast(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E3A24),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB4F4C2),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // MODAL 1: CHỈNH SỬA TOÀN DIỆN THÔNG TIN CÂY (Tên, Vị trí, Tần suất tưới, Tình trạng, Giờ nhắc)
  void _showEditPlantModal(BuildContext context, GardenPlant plantItem) {
    final c = context.colors;
    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);

    final TextEditingController nameCtrl = TextEditingController(text: plantItem.nickname);
    String initialNote = plantItem.notes;
    if (initialNote.contains("Chẩn đoán AI")) {
      initialNote = initialNote.replaceAll("Chẩn đoán AI", "Chẩn đoán Trợ lý Floria");
    }
    final TextEditingController noteCtrl = TextEditingController(text: initialNote);
    String selectedZone = plantItem.zone;
    String selectedHealth = plantItem.healthStatus;
    int frequencyDays = plantItem.waterFrequencyDays;
    int fertilizeDays = plantItem.fertilizeFrequencyDays;
    bool enableFertilizer = fertilizeDays > 0;
    if (fertilizeDays <= 0) fertilizeDays = 20;
    int checkPestDays = plantItem.checkPestFrequencyDays;
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
      {"label": "07:00", "time": "07:00"},
      {"label": "09:30", "time": "09:30"},
      {"label": "17:30", "time": "17:30"},
      {"label": "20:00", "time": "20:00"},
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
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                          color: c.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr("Chỉnh sửa cây trồng", "Edit plant"),
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: c.textMuted),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 1. Tên biệt danh
                    Text(
                      context.tr("Tên hiển thị / Biệt danh:", "Display name / Nickname:"),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: c.surfaceMuted,
                        hintText: context.tr("Ví dụ: Em sen đá nhỏ, Cây tài lộc...", "e.g., Little succulent, Money tree..."),
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: c.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.primary, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Vị trí đặt cây
                    Text(
                      context.tr("Vị trí đặt cây (Góc vườn):", "Plant location (Garden spot):"),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: zoneSuggestions.map((z) {
                        final isSelected = selectedZone == z;
                        String trZ = z;
                        if (context.isEnglish) {
                          if (z == 'Phòng khách') trZ = 'Living room';
                          else if (z == 'Ban công') trZ = 'Balcony';
                          else if (z == 'Cửa sổ') trZ = 'Window';
                          else if (z == 'Bàn làm việc') trZ = 'Desk';
                          else if (z == 'Sân thượng') trZ = 'Rooftop';
                          else if (z == 'Phòng ngủ') trZ = 'Bedroom';
                        }
                        return ChoiceChip(
                          label: Text(trZ),
                          selected: isSelected,
                          checkmarkColor: Colors.white,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedZone = z);
                          },
                          selectedColor: c.primary,
                          backgroundColor: c.surfaceMuted,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : c.textPrimary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isSelected ? c.primary : c.border),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 3. Tình trạng sức khỏe cây
                    Text(
                      context.tr("Tình trạng sức khỏe hiện tại:", "Current health status:"),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: healthOptions.map((h) {
                        final isSelected = selectedHealth == h;
                        Color chipColor = c.primary;
                        if (h == 'Bị sâu bệnh' || h == 'Bị vàng lá') chipColor = const Color(0xFFD32F2F);
                        if (h == 'Cần tưới nước') chipColor = const Color(0xFFE06C00);

                        String trH = h;
                        if (context.isEnglish) {
                          if (h == 'Khỏe mạnh') trH = 'Healthy';
                          else if (h == 'Cần tưới nước') trH = 'Needs water';
                          else if (h == 'Bị vàng lá') trH = 'Yellow leaves';
                          else if (h == 'Bị sâu bệnh') trH = 'Pests detected';
                          else if (h == 'Cần chú ý') trH = 'Needs attention';
                        }

                        return ChoiceChip(
                          label: Text(trH),
                          selected: isSelected,
                          checkmarkColor: Colors.white,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedHealth = h);
                          },
                          selectedColor: chipColor,
                          backgroundColor: c.surfaceMuted,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : c.textPrimary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isSelected ? chipColor : c.border),
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
                          context.tr("Tần suất tưới nước:", "Watering frequency:"),
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: c.surfaceTint,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.border),
                          ),
                          child: Text(
                            "${context.tr("Mỗi", "Every")} $frequencyDays ${context.tr("ngày / lần", "days")}",
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: c.primaryText),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: c.primary,
                        inactiveTrackColor: c.surfaceMuted,
                        thumbColor: c.primary,
                        overlayColor: c.primary.withValues(alpha: 0.15),
                        valueIndicatorColor: c.primary,
                        valueIndicatorTextStyle: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        showValueIndicator: ShowValueIndicator.onDrag,
                      ),
                      child: Slider(
                        value: frequencyDays.toDouble(),
                        min: 1,
                        max: 14,
                        divisions: 13,
                        label: "$frequencyDays ${context.tr("ngày/lần", "days")}",
                        onChanged: (val) {
                          setModalState(() => frequencyDays = val.round());
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 5. Chu kỳ bón phân dinh dưỡng (Hỗ trợ Radio Button Bật/Tắt cho cây không cần phân)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr("Yêu cầu bón phân dinh dưỡng:", "Fertilization requirement:"),
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: enableFertilizer
                                ? (c.isDark ? const Color(0xFF3E3218) : const Color(0xFFFEF3C7))
                                : c.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: enableFertilizer
                                  ? (c.isDark ? const Color(0xFF5A4820) : const Color(0xFFFDE68A))
                                  : c.border,
                            ),
                          ),
                          child: Text(
                            enableFertilizer
                                ? "${context.tr("Mỗi", "Every")} $fertilizeDays ${context.tr("ngày / lần", "days")}"
                                : context.tr("Không áp dụng", "Not applicable"),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: enableFertilizer
                                  ? (c.isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
                                  : c.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Nhóm Radio Button (Bật / Tắt chức năng bón phân)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                enableFertilizer = true;
                                if (fertilizeDays <= 0) fertilizeDays = 20;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(
                                color: enableFertilizer
                                    ? (c.isDark ? const Color(0xFF3E3218) : const Color(0xFFFEF3C7))
                                    : c.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: enableFertilizer ? const Color(0xFFF59E0B) : c.border,
                                  width: enableFertilizer ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Radio<bool>(
                                    value: true,
                                    groupValue: enableFertilizer,
                                    activeColor: const Color(0xFFD97706),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    onChanged: (val) {
                                      if (val == true) {
                                        setModalState(() {
                                          enableFertilizer = true;
                                          if (fertilizeDays <= 0) fertilizeDays = 20;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      context.tr("Cần bón phân", "Needs fertilizer"),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: enableFertilizer
                                            ? (c.isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E))
                                            : c.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                enableFertilizer = false;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(
                                color: !enableFertilizer
                                    ? (c.isDark ? const Color(0xFF2E332F) : const Color(0xFFF3F4F6))
                                    : c.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !enableFertilizer
                                      ? (c.isDark ? c.primaryText : const Color(0xFF9CA3AF))
                                      : c.border,
                                  width: !enableFertilizer ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Radio<bool>(
                                    value: false,
                                    groupValue: enableFertilizer,
                                    activeColor: c.textSecondary,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    onChanged: (val) {
                                      if (val == false) {
                                        setModalState(() {
                                          enableFertilizer = false;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      context.tr("Không cần bón", "No fertilizer"),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: !enableFertilizer ? c.textPrimary : c.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (enableFertilizer) ...[
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFFF59E0B),
                          inactiveTrackColor: c.surfaceMuted,
                          thumbColor: const Color(0xFFF59E0B),
                          overlayColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          valueIndicatorColor: const Color(0xFF78350F),
                          valueIndicatorTextStyle: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          showValueIndicator: ShowValueIndicator.onDrag,
                        ),
                        child: Slider(
                          value: fertilizeDays.toDouble().clamp(7, 60),
                          min: 7,
                          max: 60,
                          divisions: 53,
                          label: "$fertilizeDays ${context.tr("ngày/lần", "days")}",
                          onChanged: (val) {
                            setModalState(() => fertilizeDays = val.round());
                          },
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 8),
                        child: Text(
                          context.tr(
                            "💡 Loài cây này không yêu cầu phân bón (ví dụ: cây không khí, sen đá giai đoạn nghỉ...). Tác vụ bón phân sẽ được tắt khỏi lịch nhắc việc.",
                            "💡 This plant doesn't require fertilizer (e.g., air plants, dormant succulents). Fertilizing tasks will be disabled.",
                          ),
                          style: GoogleFonts.inter(fontSize: 11.5, color: c.textMuted, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                    // 6. Chu kỳ kiểm tra sâu bệnh & lau lá
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr("Chu kỳ kiểm tra sâu bệnh & lau lá:", "Pest check & clean frequency:"),
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: c.isDark ? const Color(0xFF1E2D40) : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.isDark ? const Color(0xFF2A4260) : const Color(0xFFBAE6FD)),
                          ),
                          child: Text(
                            "${context.tr("Mỗi", "Every")} $checkPestDays ${context.tr("ngày / lần", "days")}",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: c.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0369A1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF0284C7),
                        inactiveTrackColor: c.surfaceMuted,
                        thumbColor: const Color(0xFF0284C7),
                        overlayColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        valueIndicatorColor: const Color(0xFF0C4A6E),
                        valueIndicatorTextStyle: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        showValueIndicator: ShowValueIndicator.onDrag,
                      ),
                      child: Slider(
                        value: checkPestDays.toDouble().clamp(1, 14),
                        min: 1,
                        max: 14,
                        divisions: 13,
                        label: "$checkPestDays ${context.tr("ngày/lần", "days")}",
                        onChanged: (val) {
                          setModalState(() => checkPestDays = val.round());
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 7. Khung giờ nhắc nhở tưới
                    Text(
                      context.tr("Khung giờ nhắc nhở:", "Reminder time:"),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary),
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
                                color: isSelected ? c.primary : c.surfaceMuted,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? c.primary : c.border,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                item["label"]!,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : c.textPrimary,
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
                      context.tr("Ghi chú chăm sóc:", "Care notes:"),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: c.surfaceMuted,
                        hintText: context.tr("Ví dụ: Đặt cạnh cửa sổ hướng đông, tưới buổi sáng...", "e.g., Near east window, water in morning..."),
                        hintStyle: GoogleFonts.inter(fontSize: 12.5, color: c.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.primary, width: 1.5)),
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
                            fertilizeFrequencyDays: enableFertilizer ? fertilizeDays : 0,
                            checkPestFrequencyDays: checkPestDays,
                            reminderTime: reminderTime,
                            healthStatus: selectedHealth,
                            notes: newNotes,
                          );

                          if (context.mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFF1E3A24),
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  content: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${context.tr("Đã cập nhật cây", "Updated plant")} '${newName.isNotEmpty ? newName : plantItem.nameVi}'",
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              context.tr("Thông tin và lịch chăm sóc mới đã được lưu thành công.", "Care information and new schedule have been saved successfully."),
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFFB4F4C2),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(
                          context.tr("Lưu thay đổi", "Save changes"),
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
    final c = context.colors;
    final title = currentPlant?.nameVi ?? plant?["title"] ?? "Cây cảnh";
    final sciName = currentPlant?.scientificName ?? plant?["scientificName"] ?? "";
    final wiki = currentPlant?.wikiData ?? const {};

    final light = wiki['light'] ?? context.tr("Sáng yếu đến trung bình", "Low to medium light");
    final water = wiki['watering'] ?? context.tr("Tưới khi lớp đất mặt khô 2-3 cm", "Water when top 2-3 cm of soil is dry");
    final temp = wiki['temperature'] ?? "18 - 28°C";
    final humidity = wiki['humidity'] ?? "50 - 70%";
    final soil = wiki['soil'] ?? context.tr("Đất tơi xốp, thoát nước tốt", "Porous, well-draining soil");
    final fertilizer = wiki['fertilizer'] ?? context.tr("Bón phân NPK pha loãng 1 tháng/lần", "Diluted NPK fertilizer once a month");
    final toxicity = wiki['toxicity'] ?? context.tr("An toàn / Đang cập nhật", "Safe / Updating");
    final difficulty = wiki['difficulty'] ?? context.tr("Dễ chăm sóc", "Easy care");
    final description = wiki['description'] ?? context.tr("Loài cây cảnh tuyệt đẹp giúp thanh lọc không khí và mang lại sinh khí tươi mới cho không gian sống của bạn.", "A beautiful houseplant that purifies the air and adds fresh vibrancy to your living space.");
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
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                      color: c.border,
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
                              color: c.textPrimary,
                            ),
                          ),
                          if (sciName.isNotEmpty)
                            Text(
                              sciName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: c.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: c.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Lưới 3 Thẻ Thông Tin Nổi Bật (Độ khó, Họ cây, Phân loại)
                () {
                  String shortDifficulty = context.tr("Trung bình", "Medium");
                  Color diffBg = c.isDark ? const Color(0xFF3E3618) : const Color(0xFFFFF3E0);
                  Color diffFg = const Color(0xFFFFB74D);

                  final lowerDiff = difficulty.toLowerCase();
                  if (lowerDiff.contains("khó") || lowerDiff.contains("hard") || lowerDiff.contains("difficult")) {
                    shortDifficulty = context.tr("Khó", "Hard");
                    diffBg = c.isDark ? const Color(0xFF3E1E22) : const Color(0xFFFFEBEE);
                    diffFg = const Color(0xFFEF5350);
                  } else if (lowerDiff.contains("dễ") || lowerDiff.contains("easy")) {
                    shortDifficulty = context.tr("Dễ", "Easy");
                    diffBg = c.isDark ? const Color(0xFF1E3A24) : const Color(0xFFE8F5E9);
                    diffFg = const Color(0xFF4ADE80);
                  } else if (lowerDiff.contains("trung bình") || lowerDiff.contains("medium")) {
                    shortDifficulty = context.tr("Trung bình", "Medium");
                    diffBg = c.isDark ? const Color(0xFF3E3618) : const Color(0xFFFFF8E1);
                    diffFg = const Color(0xFFFFB74D);
                  }

                  String shortFamily = family.isNotEmpty ? family : context.tr("Chưa phân loại", "Unclassified");
                  if (shortFamily.contains("(")) {
                    shortFamily = shortFamily.split("(").first.trim();
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _buildSummaryMiniCard(
                          context,
                          icon: Icons.military_tech_outlined,
                          label: context.tr("ĐỘ KHÓ", "DIFFICULTY"),
                          value: shortDifficulty,
                          badgeColor: diffBg,
                          textColor: diffFg,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryMiniCard(
                          context,
                          icon: Icons.spa_outlined,
                          label: context.tr("HỌ THỰC VẬT", "FAMILY"),
                          value: shortFamily,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryMiniCard(
                          context,
                          icon: Icons.category_outlined,
                          label: context.tr("PHÂN LOẠI", "TYPE"),
                          value: currentPlant?.plantType ?? context.tr("Cây cảnh", "Houseplant"),
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
                      color: c.warningBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.isDark ? const Color(0xFF5A4820) : const Color(0xFFFFE082)),
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
                                context.tr("Lưu ý về độ khó & môi trường:", "Care difficulty & environment note:"),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: c.isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                difficulty,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: c.isDark ? c.textSecondary : const Color(0xFF5D4037),
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
                  context.tr("Đặc tính sinh học", "Biological characteristics"),
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: c.textSecondary),
                ),
                const SizedBox(height: 20),

                // Lưới thông số chăm sóc chuẩn
                Text(
                  context.tr("Yêu cầu sinh thái chuẩn bách khoa", "Standard botanical requirements"),
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary),
                ),
                const SizedBox(height: 12),

                _buildWikiInfoRow(context, Icons.light_mode_outlined, context.tr("Ánh sáng", "Light"), light),
                _buildWikiInfoRow(context, Icons.water_drop_outlined, context.tr("Nước tưới", "Watering"), water),
                _buildWikiInfoRow(context, Icons.thermostat_outlined, context.tr("Nhiệt độ", "Temperature"), temp),
                _buildWikiInfoRow(context, Icons.cloud_outlined, context.tr("Độ ẩm", "Humidity"), humidity),
                _buildWikiInfoRow(context, Icons.terrain_outlined, context.tr("Đất trồng", "Soil"), soil),
                _buildWikiInfoRow(context, Icons.science_outlined, context.tr("Phân bón", "Fertilizer"), fertilizer),
                _buildWikiInfoRow(context, Icons.pets_outlined, context.tr("Độc tính", "Toxicity"), toxicity),

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
                            plantId: currentPlant?.id,
                            plantNameVi: title,
                            scientificName: sciName,
                            diseaseContext: "Tôi cần hỏi chuyên sâu về đặc tính bách khoa của loài cây $title ($sciName).",
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 18),
                    label: Text(
                      context.tr("Hỏi Trợ lý Floria sâu hơn về loài cây này", "Ask Floria AI more about this plant"),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
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

  Widget _buildSummaryMiniCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? badgeColor,
    Color? textColor,
  }) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: badgeColor ?? c.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: c.isDark ? 0.2 : 0.02),
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
              Icon(icon, size: 14, color: textColor ?? c.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: c.textMuted,
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
              color: textColor ?? c.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWikiInfoRow(BuildContext context, IconData icon, String title, String desc) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: c.surfaceTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: c.textSecondary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: c.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String time,
    required IconData timeIcon,
    required Color timeColor,
    required bool isDone,
    required bool isLast,
  }) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone ? (c.isDark ? c.surfaceMuted.withValues(alpha: 0.5) : const Color(0xFFF5F3F0)) : Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isLast ? 0 : 16),
          topRight: Radius.circular(isLast ? 0 : 16),
          bottomLeft: Radius.circular(isLast ? 16 : 0),
          bottomRight: Radius.circular(isLast ? 16 : 0),
        ),
        border: isLast ? null : Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: isDone ? 0.6 : 1.0,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.surfaceTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: c.textSecondary, size: 20),
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
                      color: c.textPrimary,
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
              color: isDone ? c.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: isDone ? c.primary : c.textMuted, width: 2),
            ),
            child: isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
          ),
        ],
      ),
    );
  }
}
