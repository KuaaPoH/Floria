import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'plant_detail_screen.dart';
import '../../../core/widgets/custom_image.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  int _activeZoneIndex = 0;
  final List<String> _zones = ["Tất cả", "Phòng khách", "Ban công"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F6), // surface
      body: SafeArea(
        child: SingleChildScrollView(
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
              Text(
                'Quản lý khu vườn',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B1C1A),
                  letterSpacing: -1,
                ),
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
                  ]
                ),
                child: TextField(
                  style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1B1C1A)),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm cây, góc vườn...',
                    hintStyle: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF747871)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF747871), size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildAttentionSection(),
              const SizedBox(height: 32),
              _buildMyGardensSection(),
              const SizedBox(height: 32),
              _buildZoneFilters(),
              const SizedBox(height: 16),
              _buildPlantGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttentionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cần chú ý',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B1C1A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
                imageUrl: 'https://picsum.photos/seed/plant1/400/400',
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
                      'NHÀ BỐ MẸ • BAN CÔNG',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF747871),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bàng Singapore',
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
                            'Đất quá khô, cần tưới',
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
                  onPressed: () {},
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildMyGardensSection() {
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
              _buildGardenCard(true, "Nhà của tôi", "12 cây"),
              const SizedBox(width: 16),
              _buildGardenCard(false, "Nhà bố mẹ", "5 cây"),
              const SizedBox(width: 16),
              _buildAddGardenCard(),
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
        boxShadow: isActive ? [
          BoxShadow(
            color: const Color(0xFF364534).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ] : null,
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

  Widget _buildAddGardenCard() {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
            width: 32, height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFE4E2DF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 20, color: Color(0xFF444842)),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm vườn',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF444842),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: List.generate(_zones.length, (index) {
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
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: const Color(0xFF364534).withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ] : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _zones[index],
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

  Widget _buildPlantGrid(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width > 600;
    
    final List<Map<String, dynamic>> plants = [
      {
        "title": "Monstera",
        "location": "Phòng khách",
        "status": "Khỏe mạnh",
        "statusColor": const Color(0xFF4CAF50),
        "imageUrl": "https://picsum.photos/seed/plant2/400/400",
      },
      {
        "title": "Lưỡi hổ",
        "location": "Ban công",
        "status": "Khỏe mạnh",
        "statusColor": const Color(0xFF4CAF50),
        "imageUrl": "https://picsum.photos/seed/plant3/400/400",
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85, 
      ),
      itemCount: plants.length + 1, // +1 for "Thêm cây"
      itemBuilder: (context, index) {
        if (index == plants.length) {
          return _buildAddPlantCard();
        }
        return _buildPlantCard(context, plants[index]);
      },
    );
  }

  Widget _buildAddPlantCard() {
    return Container(
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
            width: 48, height: 48,
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
    );
  }

  Widget _buildPlantCard(BuildContext context, Map<String, dynamic> plant) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlantDetailScreen(plant: plant)),
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
                    imageUrl: plant["imageUrl"],
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: plant["statusColor"],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            plant["status"],
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1B1C1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant["location"].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF747871),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plant["title"],
                    style: GoogleFonts.inter(
                      fontSize: 15,
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
