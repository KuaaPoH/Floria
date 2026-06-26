import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'plant_detail_screen.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  int _activeTabIndex = 0;
  final List<String> _tabs = ["Tất cả", "Phòng khách", "Ban công", "Bàn làm việc"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 10, bottom: 30, left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 25),
              _buildStatusWidget(context),
              const SizedBox(height: 25),
              _buildFilterTabs(context),
              const SizedBox(height: 20),
              _buildPlantGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Khu Vườn Của Bạn',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF006D35),
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withValues(alpha: 0.2),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676).withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 0),
              )
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF006D35)),
            onPressed: () {},
          ),
        )
      ],
    );
  }

  Widget _buildStatusWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop, color: Color(0xFF006D35)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CẦN CHĂM SÓC',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B4A3D),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Trạng thái: 2 cây cần tưới nước hôm nay',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF151E16),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isActive = _activeTabIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeTabIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF00E676) : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: const Color(0xFF00E676).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 0),
                  )
                ] : null,
              ),
              child: Text(
                _tabs[index],
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? const Color(0xFF00612E) : const Color(0xFF3B4A3D),
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
    
    // Fake data matching the HTML
    final List<Map<String, dynamic>> plants = [
      {
        "title": "Cây Trầu Bà",
        "location": "Phòng khách",
        "status": "Khỏe",
        "statusColor": const Color(0xFF00E676),
        "imageUrl": "https://lh3.googleusercontent.com/aida-public/AB6AXuA88Aldot9yyznxt0McJxoduq5TmNHos1QLXh8vg7BmIEmQaGvpHggrJs_krzQf0jPFYthMHCfeBadBnCpyHvkbEgLJP4PU1JWpBcpQZeMH8wwpuQd9vbHE2F1EJNwEMs5NihKPJS_pYGdshl-KRmJ43l5av0ZKnlS_ouSUw5kcMX9xFUv2arPvnllUysZJvcfeDaZcLE4tD62GNnnSj_VO2EWELEUANSmnaAb92T7RRxqN0sJfOABROsngEW7M_WxZAVhYxzultm4",
      },
      {
        "title": "Cây Kim Tiền",
        "location": "Ban công",
        "status": "Cần chú ý",
        "statusColor": Colors.orange,
        "imageUrl": "https://lh3.googleusercontent.com/aida-public/AB6AXuCG3csOpdf8jP6MfGzXsp1r9g1vbgSLMDdLJLz2LlzHCwFQ7f55zhBeK6P1-5v8Wl-2JJO1LZRuugc_oFFv977RAeDtr2E15WZARNLbvxDi0oNVDTAmz3Y-P6GWjWRxt5mcQiJNfdkHStuzHnS1f59Ld2Z1Brl4bOynyNowbpucDefNoSueLd9_0SDQ39dK7X04dRQ96PMrlVjKsDHexqNV0HnB4eYWtLkiJU8Wvz600k8IojBb64fM7QnZyQugd9WLn_NE0eZA0pM",
      },
      {
        "title": "Cây Trầu Bà Nam Mỹ",
        "location": "Phòng khách",
        "status": "Khỏe",
        "statusColor": const Color(0xFF00E676),
        "imageUrl": "https://lh3.googleusercontent.com/aida-public/AB6AXuAHkPVhh2WQZrXjsl0HcyIMdTjbeQcORXv7cjsIza-AFNrti0vsxHcFrg10w02V2Wt2ZuKb4Zn0KLnRGdpw8B5oVZtITRynuWFHjcjzPRb0NKpXEenw2twDkSY4a5vbwmvVP1alqgoJITUeV7vGAi34ykbvXeANrS7b47Frl9hPlmgwdXwr3dPGVU0o3xYa39mS5_sD9YKHBned_vQmz7IqeR1bONLzUbNDh9JERA82NvVtU-zkaOj6gJTHxSoudQag16ksO5p9icI",
      },
      {
        "title": "Cây Lưỡi Hổ",
        "location": "Bàn làm việc",
        "status": "Cần chú ý",
        "statusColor": Colors.orange,
        "imageUrl": "https://lh3.googleusercontent.com/aida-public/AB6AXuChj1RU6v8wi9Ca9ACTZ4ll-zYCTsBn1lpv0zDufZNrS-MRhm_KKDnqAJwuocIDs-rMl3vXKh4VKr84c1l-dSc_o4hMyukIH7VxS18Yq46WGKFlIY4xLKwkssO-5aTg_1uEkmSCtFRqatdsQdds9i7ygpjgWvuPjHjxOACO7YIN1JdfAdXGUsAEhBFW9GSc-FGwI1zpWnTF7P2eunoqRo8ltUDNJeU2Lcsv95RXoAaS1KFIwB3OyBMW3eAmOD00VdaZXb2fSvQhzqw",
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75, // Adjust according to image size
      ),
      itemCount: plants.length,
      itemBuilder: (context, index) {
        final plant = plants[index];
        return _buildPlantCard(context, plant);
      },
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
        padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
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
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(plant["imageUrl"]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: plant["statusColor"],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: plant["statusColor"].withOpacity(0.5),
                                blurRadius: 4,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          plant["status"].toUpperCase(),
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3B4A3D),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            plant["title"],
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF151E16),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            plant["location"],
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              color: const Color(0xFF3B4A3D),
            ),
          ),
        ],
      ),
    ));
  }
}
