import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'plant_detail_screen.dart';
import '../../../core/widgets/custom_image.dart';
import '../providers/garden_provider.dart';
import '../models/garden_plant.dart';
import '../../scan/screens/scan_screen.dart';

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
        final allPlants = gardenProvider.plants;
        final zones = gardenProvider.availableZones;
        if (_activeZoneIndex >= zones.length) {
          _activeZoneIndex = 0;
        }
        final currentZone = zones.isNotEmpty ? zones[_activeZoneIndex] : "Tất cả";

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
          backgroundColor: const Color(0xFFFBF9F6), // surface
          body: SafeArea(
            child: gardenProvider.isLoading && allPlants.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF364534)),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BỘ SƯU TẬP CỦA BẠN',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: const Color(0xFF6A756B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Quản lý khu vườn',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1B1C1A),
                                letterSpacing: -1,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF364534).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "${allPlants.length} Cây",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF364534),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE4E2DF)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF364534).withOpacity(0.03),
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
                            style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1B1C1A)),
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm cây, góc vườn...',
                              hintStyle: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF747871)),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF747871), size: 22),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18, color: Color(0xFF747871)),
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
                        _buildAttentionSection(context, gardenProvider),
                        const SizedBox(height: 32),
                        _buildMyGardensSection(context, allPlants.length),
                        const SizedBox(height: 32),
                        _buildZoneFilters(zones),
                        const SizedBox(height: 16),
                        _buildPlantGrid(context, allPlants, filteredPlants, currentZone),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildAttentionSection(BuildContext context, GardenProvider gardenProvider) {
    final attentionList = gardenProvider.attentionPlants;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cần chú ý',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B1C1A),
              ),
            ),
            if (attentionList.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE06C00).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${attentionList.length} cây cần tưới",
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
        if (attentionList.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8F3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4E8CE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF364534), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Tất cả cây trong vườn đều đang đủ nước và khỏe mạnh! 🌿",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF364534),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: attentionList.map((plant) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4E2DF)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF364534).withOpacity(0.05),
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
                              color: const Color(0xFF747871),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plant.nickname,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1B1C1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.water_drop, size: 14, color: Color(0xFFE06C00)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Đã đến hạn tưới (${plant.waterFrequencyDays} ngày/lần)',
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
                      decoration: const BoxDecoration(
                        color: Color(0xFF364534),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.check, color: Colors.white, size: 20),
                        tooltip: "Đã tưới nước",
                        onPressed: () async {
                          await gardenProvider.waterPlant(plant.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Đã tưới nước cho '${plant.nickname}'! 💧"),
                                backgroundColor: const Color(0xFF364534),
                                duration: const Duration(seconds: 2),
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

  Widget _buildMyGardensSection(BuildContext context, int plantCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khu vườn của tôi',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B1C1A),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _buildGardenCard(true, "Vườn của tôi", "$plantCount cây"),
              const SizedBox(width: 16),
              _buildAddGardenCard(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGardenCard(bool isActive, String title, String subtitle) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF364534) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isActive ? null : Border.all(color: const Color(0xFFE4E2DF)),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF364534).withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : const Color(0xFF1B1C1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: isActive ? Colors.white.withOpacity(0.8) : const Color(0xFF747871),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddGardenCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
      },
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFC4C8BF),
            width: 2,
          ),
          color: Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFE4E2DF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_a_photo_outlined, size: 18, color: Color(0xFF444842)),
            ),
            const SizedBox(height: 8),
            Text(
              'Quét thêm cây',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF444842),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneFilters(List<String> zones) {
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
                  color: isActive ? const Color(0xFF364534) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isActive ? null : Border.all(color: const Color(0xFFE4E2DF)),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF364534).withOpacity(0.15),
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
                    color: isActive ? Colors.white : const Color(0xFF444842),
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
    if (allPlants.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE4E2DF)),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF364534).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.yard_outlined, size: 36, color: Color(0xFF364534)),
            ),
            const SizedBox(height: 16),
            Text(
              "Khu vườn của bạn chưa có cây nào",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B1C1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Hãy chụp ảnh nhận diện cây cảnh bằng Floria AI và bấm 'Lưu vào vườn' để bắt đầu quản lý lịch tưới nhé!",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF747871),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
              },
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: Text("Quét cây đầu tiên ngay", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF364534),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4E2DF)),
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 40, color: Color(0xFF747871)),
            const SizedBox(height: 8),
            Text(
              "Không tìm thấy cây nào phù hợp trong '$currentZone'",
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF747871)),
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
          return _buildAddPlantCard(context);
        }
        return _buildPlantCard(context, filteredPlants[index]);
      },
    );
  }

  Widget _buildAddPlantCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD4E8CE).withOpacity(0.3), // secondary-container / 30
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF364534).withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF364534),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 24, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              'Thêm cây',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF364534),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantCard(BuildContext context, GardenPlant plant) {
    final statusColor = plant.isNeedsWater ? const Color(0xFFE06C00) : const Color(0xFF4CAF50);
    final statusText = plant.isNeedsWater ? "Cần tưới" : plant.healthStatus;
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4E2DF)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF364534).withOpacity(0.03),
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
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white),
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
                            statusText,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1B1C1A),
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
                      color: const Color(0xFF747871),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plant.nickname,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1B1C1A),
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
}
