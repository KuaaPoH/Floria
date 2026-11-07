import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_tr.dart';
import '../../../core/theme/app_colors.dart';
import 'plant_detail_screen.dart';
import 'create_garden_screen.dart';
import 'add_plant_to_garden_screen.dart';
import '../../../core/widgets/custom_image.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/garden_provider.dart';
import '../models/garden_plant.dart';
import '../models/user_garden.dart';
import '../../../core/services/notification_service.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  int _activeZoneIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GardenProvider>(
      builder: (context, gardenProvider, child) {
        final c = context.colors;
        final allPlants = gardenProvider.plants;
        final zones = gardenProvider.availableZones;
        if (_activeZoneIndex >= zones.length) {
          _activeZoneIndex = 0;
        }
        final currentZone = zones.isNotEmpty ? zones[_activeZoneIndex] : context.tr("Tất cả", "All");

        List<GardenPlant> filteredPlants = gardenProvider.getPlantsByZone(currentZone);
        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.toLowerCase().trim();
          filteredPlants = filteredPlants.where((p) {
            return p.nickname.toLowerCase().contains(q) ||
                p.nameVi.toLowerCase().contains(q) ||
                p.scientificName.toLowerCase().contains(q) ||
                p.zone.toLowerCase().contains(q);
          }).toList();
        }

        return Scaffold(
          backgroundColor: c.background,
          body: SafeArea(
            child: gardenProvider.isLoading && allPlants.isEmpty && !gardenProvider.hasGarden
                ? _buildGardenSkeleton(context)
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('BỘ SƯU TẬP CỦA BẠN', 'YOUR COLLECTION'),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: c.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr('Quản lý khu vườn', 'Garden Management'),
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                                letterSpacing: -1,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: c.isDark ? c.surfaceTint : const Color(0xFF364534).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "${allPlants.length} ${context.tr('Cây', 'Plants')}",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: c.primaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Thanh tìm kiếm
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: c.border),
                            boxShadow: [
                              BoxShadow(
                                color: c.shadow.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            style: GoogleFonts.inter(fontSize: 15, color: c.textPrimary),
                            decoration: InputDecoration(
                              hintText: context.tr('Tìm kiếm cây, góc vườn...', 'Search plants, zones...'),
                              hintStyle: GoogleFonts.inter(fontSize: 15, color: c.textMuted),
                              prefixIcon: Icon(Icons.search, color: c.textMuted, size: 22),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, size: 18, color: c.textMuted),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 1. Phần Cần chú ý (CHỈ hiển thị khi có cây cần chú ý)
                        if (gardenProvider.attentionPlants.isNotEmpty) ...[
                          _buildAttentionSection(context, gardenProvider),
                          const SizedBox(height: 32),
                        ],
                        // 2. Phần Khu vườn của tôi
                        _buildMyGardensSection(context, gardenProvider, allPlants.length),
                        // 3. Nếu đã có khu vườn thì mới hiển thị bộ lọc khu vực & danh sách cây
                        if (gardenProvider.hasGarden) ...[
                          const SizedBox(height: 32),
                          _buildZoneFilters(context, zones),
                          const SizedBox(height: 16),
                          _buildPlantGrid(context, allPlants, filteredPlants, currentZone),
                        ],
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildAttentionSection(BuildContext context, GardenProvider gardenProvider) {
    final c = context.colors;
    final attentionList = gardenProvider.attentionPlants;
    if (attentionList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('Cần chú ý', 'Needs Attention'),
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE06C00).withValues(alpha: c.isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${attentionList.length} ${context.tr('cây cần tưới', 'need water')}",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE06C00),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: attentionList.map((plant) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
                boxShadow: [
                  BoxShadow(
                    color: c.shadow.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Row(
                children: [
                  CustomImage(
                    imageUrl: plant.imageUrl ?? plant.wikiData['imageUrl'] ?? 'https://picsum.photos/seed/plant1/400/400',
                    width: 72,
                    height: 72,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.zone.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: c.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plant.nickname,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.water_drop, size: 14, color: Color(0xFFE06C00)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "${context.tr('Đã đến hạn tưới', 'Watering due')} (${plant.waterFrequencyDays} ${context.tr('ngày/lần', 'days/time')})",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFE06C00),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.isDark ? c.primaryText : const Color(0xFF364534),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.check, color: c.isDark ? Colors.black : Colors.white, size: 20),
                      tooltip: context.tr("Đã tưới nước", "Watered"),
                      onPressed: () async {
                        await gardenProvider.waterPlant(plant.id);
                        NotificationService.silenceForToday(plant.id, 'water');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF1E3A24),
                              elevation: 8,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
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
                                          "${context.tr('Đã tưới nước cho', 'Watered')} '${plant.nickname}'! 💧",
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${context.tr('Lần tưới tiếp theo: sau', 'Next watering in')} ${plant.waterFrequencyDays} ${context.tr('ngày.', 'days.')}",
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
                      },
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMyGardensSection(BuildContext context, GardenProvider gardenProvider, int plantCount) {
    final c = context.colors;
    if (!gardenProvider.hasGarden) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Khu vườn của tôi', 'My Garden'),
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.border),
              boxShadow: [
                BoxShadow(
                  color: c.shadow.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: c.surfaceTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.yard_outlined, size: 36, color: c.primaryText),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr("Bạn chưa có khu vườn nào", "You have no gardens yet"),
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    "Hãy tạo khu vườn đầu tiên để thiết lập môi trường, ánh sáng và bắt đầu phân loại không gian chăm sóc cây cảnh nhé!",
                    "Create your first garden to configure lighting and start organizing plant care spaces!",
                  ),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: c.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateGardenScreen()),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: Text(
                    context.tr("Tạo khu vườn ngay", "Create garden now"),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E6F40),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final gardens = gardenProvider.gardens;
    final selectedId = gardenProvider.selectedGarden?.id ?? (gardens.isNotEmpty ? gardens.first.id : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('Khu vườn của tôi', 'My Garden'),
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGardenScreen()),
                );
              },
              child: Text(
                context.tr('+ Thêm vườn', '+ Add garden'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.primaryText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              ...gardens.map((g) {
                final isActive = g.id == selectedId;
                final gCount = gardenProvider.allUserPlants
                    .where((p) => p.gardenId == g.id || (p.gardenId.isEmpty && g.id == gardens.first.id))
                    .length;
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: GestureDetector(
                    onTap: () => gardenProvider.selectGarden(g),
                    child: _buildUserGardenCard(context, isActive, g, "$gCount ${context.tr('cây', 'plants')}"),
                  ),
                );
              }),
              _buildAddGardenCard(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserGardenCard(BuildContext context, bool isActive, UserGarden garden, String plantCountText) {
    final c = context.colors;
    IconData envIcon;
    switch (garden.environment) {
      case 'Ngoài trời':
        envIcon = Icons.park_outlined;
        break;
      case 'Văn phòng':
        envIcon = Icons.business_outlined;
        break;
      case 'Nhà kính':
        envIcon = Icons.grass_outlined;
        break;
      default:
        envIcon = Icons.home_outlined;
    }

    return Container(
      width: 175,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? (c.isDark ? c.surfaceTint : const Color(0xFF364534)) : c.surface,
        borderRadius: BorderRadius.circular(20),
        border: isActive ? Border.all(color: c.primaryText, width: 1.5) : Border.all(color: c.border),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF364534).withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            : [
                BoxShadow(
                  color: c.shadow.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.15)
                      : (c.isDark ? c.surfaceMuted : const Color(0xFF364534).withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      envIcon,
                      size: 13,
                      color: isActive ? Colors.white : c.primaryText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      garden.environment,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : c.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            garden.name,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : c.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            garden.lightCondition,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: isActive ? Colors.white.withValues(alpha: 0.75) : c.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            plantCountText,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white.withValues(alpha: 0.9) : c.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddGardenCard(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateGardenScreen()),
        );
      },
      child: Container(
        width: 140,
        height: 142,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: c.border,
            width: 1.5,
          ),
          color: Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.surfaceTint,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_business_outlined, size: 20, color: c.primaryText),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('Thêm khu vườn', 'Add garden'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneFilters(BuildContext context, List<String> zones) {
    final c = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: List.generate(zones.length, (index) {
          final isActive = _activeZoneIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeZoneIndex = index),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isActive ? (c.isDark ? c.primaryText : const Color(0xFF364534)) : c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: isActive ? null : Border.all(color: c.border),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF364534).withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  zones[index],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? (c.isDark ? Colors.black : Colors.white) : c.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPlantGrid(
    BuildContext context,
    List<GardenPlant> allPlants,
    List<GardenPlant> filteredPlants,
    String currentZone,
  ) {
    final c = context.colors;
    if (allPlants.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.surfaceTint,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.yard_outlined, size: 36, color: c.primaryText),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr("Khu vườn của bạn chưa có cây nào", "Your garden has no plants yet"),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(
                "Hãy chụp ảnh nhận diện cây cảnh cùng Trợ lý Floria và bấm 'Lưu vào vườn' để bắt đầu quản lý lịch tưới nhé!",
                "Identify plants with Floria and tap 'Save to garden' to start managing your watering schedule!",
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: c.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddPlantToGardenScreen(initialZone: currentZone)),
                );
              },
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: Text(context.tr("Thêm cây đầu tiên ngay", "Add first plant now"), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E6F40),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ],
        ),
      );
    }

    if (filteredPlants.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 40, color: c.textMuted),
            const SizedBox(height: 8),
            Text(
              "${context.tr('Không tìm thấy cây nào phù hợp trong', 'No matching plants found in')} '$currentZone'",
              style: GoogleFonts.inter(fontSize: 14, color: c.textMuted),
            ),
          ],
        ),
      );
    }

    final bool isTablet = MediaQuery.of(context).size.width > 600;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: filteredPlants.length + 1, // +1 for "Thêm cây"
      itemBuilder: (context, index) {
        if (index == filteredPlants.length) {
          return _buildAddPlantCard(context, currentZone);
        }
        return _buildPlantCard(context, filteredPlants[index]);
      },
    );
  }

  Widget _buildAddPlantCard(BuildContext context, String currentZone) {
    final c = context.colors;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddPlantToGardenScreen(initialZone: currentZone)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceTint.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: c.primaryText.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.isDark ? c.primaryText : const Color(0xFF364534),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, size: 24, color: c.isDark ? Colors.black : Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('Thêm cây', 'Add plant'),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantCard(BuildContext context, GardenPlant plant) {
    final c = context.colors;
    final statusText = plant.effectiveStatusText;
    Color statusColor;
    if (statusText.startsWith('Bị') || statusText == 'Cần điều trị') {
      statusColor = const Color(0xFFDC2626);
    } else if (statusText == 'Cần tưới nước') {
      statusColor = const Color(0xFFE06C00);
    } else if (statusText == 'Cần bón phân' || statusText == 'Cần kiểm tra' || statusText == 'Cần chú ý') {
      statusColor = const Color(0xFFD97706);
    } else if (statusText == 'Đang phục hồi') {
      statusColor = const Color(0xFF2563EB);
    } else {
      statusColor = const Color(0xFF15803D);
    }

    String displayStatus = statusText;
    if (statusText == 'Khỏe mạnh') {
      displayStatus = context.tr('Khỏe mạnh', 'Healthy');
    } else if (statusText == 'Cần tưới nước') {
      displayStatus = context.tr('Cần tưới nước', 'Needs water');
    } else if (statusText == 'Cần bón phân') {
      displayStatus = context.tr('Cần bón phân', 'Needs feed');
    } else if (statusText == 'Cần kiểm tra') {
      displayStatus = context.tr('Cần kiểm tra', 'Needs check');
    } else if (statusText == 'Cần chú ý') {
      displayStatus = context.tr('Cần chú ý', 'Attention');
    } else if (statusText == 'Cần điều trị') {
      displayStatus = context.tr('Cần điều trị', 'Treatment');
    } else if (statusText == 'Đang phục hồi') {
      displayStatus = context.tr('Đang phục hồi', 'Recovering');
    }

    final imgUrl = plant.imageUrl ?? plant.wikiData['imageUrl'] ?? 'https://picsum.photos/seed/plant2/400/400';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlantDetailScreen(gardenPlant: plant)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: c.shadow.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  CustomImage(
                    imageUrl: imgUrl,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.isDark ? c.surface.withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            displayStatus,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.zone.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: c.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plant.nickname,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGardenSkeleton(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(width: 140, height: 12),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerLoading(width: 180, height: 28),
              ShimmerLoading(
                width: 60,
                height: 24,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Thẻ vườn mẫu skeleton
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                const ShimmerLoading(width: 50, height: 50, shape: BoxShape.circle),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoading(width: 120, height: 16),
                      SizedBox(height: 8),
                      ShimmerLoading(width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Chips skeleton
          Row(
            children: const [
              ShimmerLoading(
                width: 70,
                height: 32,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              SizedBox(width: 8),
              ShimmerLoading(
                width: 90,
                height: 32,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              SizedBox(width: 8),
              ShimmerLoading(
                width: 80,
                height: 32,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Grid plant cards skeleton
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: ShimmerLoading(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerLoading(width: 90, height: 14),
                          SizedBox(height: 6),
                          ShimmerLoading(width: 60, height: 11),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
