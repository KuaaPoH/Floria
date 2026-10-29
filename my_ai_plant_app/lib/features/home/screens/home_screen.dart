import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/providers/auth_provider.dart';
import '../../garden/providers/garden_provider.dart';
import '../../garden/models/garden_plant.dart';
import '../../garden/models/user_garden.dart';
import '../../garden/screens/plant_detail_screen.dart';
import '../../garden/screens/garden_screen.dart';
import '../../chatbot/screens/ai_assistant_screen.dart';
import '../models/handbook_article.dart';
import '../services/handbook_service.dart';
import '../models/weather_widget_config.dart';
import '../services/weather_widget_service.dart';

class HomeScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onNavigateToGarden;

  const HomeScreen({
    super.key,
    this.isEmbedded = false,
    this.onNavigateToGarden,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Bộ lọc vườn đang chọn trên trang chủ: null là xem "Tất cả các vườn"
  String? _selectedGardenFilterId;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final gardenProvider = Provider.of<GardenProvider>(context);

    // Tính toán số lượng việc cần làm hôm nay từ tất cả các cây của người dùng
    final List<GardenPlant> allPlants = gardenProvider.allUserPlants;
    final List<Map<String, dynamic>> todayTasks = [];
    for (final plant in allPlants) {
      if (plant.isNeedsWater) {
        todayTasks.add({
          "plant": plant,
          "taskType": "water",
          "title": "Tưới nước cho ${plant.nickname}",
          "tag": "Tưới nước",
          "tagColor": const Color(0xFF0284C7),
          "tagBg": const Color(0xFFE0F2FE),
          "icon": Icons.water_drop_rounded,
        });
      }
      if (plant.isNeedsFertilizer) {
        todayTasks.add({
          "plant": plant,
          "taskType": "fertilize",
          "title": "Bón phân cho ${plant.nickname}",
          "tag": "Bón phân",
          "tagColor": const Color(0xFFD97706),
          "tagBg": const Color(0xFFFEF3C7),
          "icon": Icons.science_rounded,
        });
      }
      if (plant.isNeedsClean) {
        todayTasks.add({
          "plant": plant,
          "taskType": "pest",
          "title": "Kiểm tra sâu bệnh cho ${plant.nickname}",
          "tag": "Sâu bệnh & Lau lá",
          "tagColor": const Color(0xFF15803D),
          "tagBg": const Color(0xFFDCFCE7),
          "icon": Icons.shield_outlined,
        });
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32, top: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Chào hỏi & Đếm việc
                _buildHeader(context, authProvider, todayTasks.length),
                const SizedBox(height: 20),

                // 2. Widget thời tiết (ảnh nền & câu thoại lưu trữ Firestore)
                _buildWeatherHeroCard(context),
                const SizedBox(height: 30),

                // 3. Khu vườn của tôi (Hiển thị đầy đủ tất cả các vườn & chuyển tab tự động)
                _buildMyGardenSection(context, gardenProvider),
                const SizedBox(height: 30),

                // 4. Lịch chăm sóc hôm nay (Chỉ hiện lịch, bấm vào mở sang khu vườn)
                _buildTodayScheduleSection(context, todayTasks),
                const SizedBox(height: 30),

                // 5. Trợ lý Floria
                _buildAIAssistantSection(context),
                const SizedBox(height: 30),

                // 6. Cẩm nang chăm sóc cây (Lưu trữ Firestore & hỗ trợ chèn ảnh mọi đoạn)
                _buildCamNangBlogSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. Header Chào hỏi cá nhân hóa theo buổi & đếm việc cần làm thật
  Widget _buildHeader(BuildContext context, AuthProvider authProvider, int totalTasks) {
    final now = DateTime.now();
    String greeting;
    if (now.hour >= 5 && now.hour < 12) {
      greeting = "Chào buổi sáng ☀️";
    } else if (now.hour >= 12 && now.hour < 18) {
      greeting = "Chào buổi chiều 🌤️";
    } else {
      greeting = "Chào buổi tối 🌙";
    }

    String displayName = authProvider.userName?.trim() ?? '';
    if (displayName.isEmpty || displayName == "Nông Nghiệp Thông Minh") {
      final email = authProvider.userEmail;
      if (email != null && email.contains('@')) {
        displayName = email.split('@').first;
      } else {
        displayName = "Bạn yêu cây";
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6A756B),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              displayName,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B1C1A),
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4E2DF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Hôm nay có',
                    style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w500, color: const Color(0xFF747871)),
                  ),
                  Text(
                    'việc cần làm',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1B1C1A)),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF364534),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  totalTasks < 10 ? "0$totalTasks" : "$totalTasks",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  // 2. Widget Hero Thời tiết sinh thái có ảnh nền & câu thoại lưu trữ Firestore
  Widget _buildWeatherHeroCard(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;

    return StreamBuilder<List<WeatherWidgetConfig>>(
      stream: WeatherWidgetService.streamConfigs(),
      builder: (context, snapshot) {
        final config = WeatherWidgetService.getConfigForHour(snapshot.data, hour);
        // 1. Ảnh nền và câu thoại biên tập tùy biến lưu từ Firestore
        final heroImage = config.heroImageUrl;
        final badgeText = config.badgeText;
        final mainTitle = config.mainTitle;

        // 2. Các chỉ số thời tiết, nhiệt độ, độ ẩm động theo thời gian thực tế của thiết bị
        String weatherText;
        String statHumidity;
        String statLight;
        if (hour >= 5 && hour < 11) {
          weatherText = "Nắng sớm • 27°C";
          statHumidity = "Độ ẩm: 75%";
          statLight = "Ánh sáng: Mềm dịu";
        } else if (hour >= 11 && hour < 15) {
          weatherText = "Nắng gắt • 32°C";
          statHumidity = "Độ ẩm: 62%";
          statLight = "Ánh sáng: Nắng gắt (Cần che)";
        } else if (hour >= 15 && hour < 18) {
          weatherText = "Thoáng đãng • 29°C";
          statHumidity = "Độ ẩm: 70%";
          statLight = "Ánh sáng: Tán xạ";
        } else {
          weatherText = "Mát mẻ • 25°C";
          statHumidity = "Độ ẩm: 82%";
          statLight = "Ánh sáng: Đèn phòng";
        }

        final statNextWater = (hour >= 18 || hour < 5) ? "Lần tưới: Sáng mai" : "Lần tưới: Hôm nay";

        return Container(
          width: double.infinity,
          height: 290,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: DecorationImage(
              image: NetworkImage(heroImage),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF364534).withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.1),
              Colors.black.withValues(alpha: 0.4),
              const Color(0xFF1B1C1A).withValues(alpha: 0.88),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge thời tiết mờ kính
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF364534).withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFDE047), size: 12),
                      const SizedBox(width: 5),
                      Text(
                        weatherText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tiêu đề chính
            Text(
              mainTitle,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 14),

            // Đường gạch mờ
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),

            // Các chỉ số sinh thái
            Row(
              children: [
                _buildHeroStat(Icons.water_drop_outlined, statHumidity),
                const SizedBox(width: 16),
                _buildHeroStat(Icons.schedule, statNextWater),
              ],
            ),
            const SizedBox(height: 6),
            _buildHeroStat(Icons.wb_sunny_outlined, statLight),
            if (config.advice.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates_outlined, color: Color(0xFFFDE047), size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        config.advice,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: Colors.white.withValues(alpha: 0.95),
                          fontStyle: FontStyle.italic,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildHeroStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 13),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  // 3. Khôi phục lại khối Trợ lý Floria
  Widget _buildAIAssistantSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD6E8CF),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8F2E3),
            Color(0xFFD4E8CE),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.auto_awesome,
              size: 140,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF364534),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Trợ lý Floria',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B1C1A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Chẩn đoán bệnh qua ảnh và nhận\nlời khuyên chăm cây cá nhân hóa.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF444842),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AiAssistantScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF364534),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Hỏi ngay',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // 4. Lịch chăm sóc hôm nay (Chỉ hiện lịch, bấm vào mở sang khu vườn)
  Widget _buildTodayScheduleSection(BuildContext context, List<Map<String, dynamic>> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Lịch chăm sóc hôm nay",
                  style: GoogleFonts.inter(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1C1A),
                  ),
                ),
                Text(
                  "Chạm vào mục để xem và thao tác trong vườn",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF747871),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                _navigateToGardenTab(context);
              },
              child: Text(
                "Đến khu vườn ➔",
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF364534),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4E2DF)),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline, size: 40, color: Color(0xFF15803D)),
                const SizedBox(height: 10),
                Text(
                  "Hôm nay khu vườn đã đủ ẩm và dinh dưỡng!",
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1B1C1A)),
                ),
                const SizedBox(height: 4),
                Text(
                  "Chưa có chậu cây nào đến hạn cần chăm sóc thêm.",
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF747871)),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final task = tasks[index];
              final GardenPlant plant = task["plant"];
              final Color tagColor = task["tagColor"];
              final Color tagBg = task["tagBg"];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlantDetailScreen(gardenPlant: plant),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE4E2DF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Thumbnail ảnh cây
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: plant.imageUrl != null && plant.imageUrl!.isNotEmpty
                            ? Image.network(
                                plant.imageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  width: 50,
                                  height: 50,
                                  color: const Color(0xFFE8F2E3),
                                  child: const Icon(Icons.local_florist, color: Color(0xFF364534), size: 24),
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                color: const Color(0xFFE8F2E3),
                                child: const Icon(Icons.local_florist, color: Color(0xFF364534), size: 24),
                              ),
                      ),
                      const SizedBox(width: 12),

                      // Thông tin lịch
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task["title"],
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1B1C1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  plant.zone,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF747871),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text("•", style: TextStyle(color: Color(0xFF747871), fontSize: 10)),
                                const SizedBox(width: 6),
                                Text(
                                  plant.reminderTime,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF364534),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Tag phân loại nhiệm vụ
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: tagBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          task["tag"],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: tagColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF9E9E9E), size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // 5. Khu vườn của tôi (Hiển thị đầy đủ tất cả các vườn & chuyển tab tự động)
  Widget _buildMyGardenSection(BuildContext context, GardenProvider gardenProvider) {
    final List<UserGarden> gardens = gardenProvider.gardens;
    final List<GardenPlant> allPlants = gardenProvider.allUserPlants;

    // Lọc danh sách cây dựa theo vườn được chọn trên trang chủ
    final List<GardenPlant> displayedPlants = _selectedGardenFilterId == null
        ? allPlants
        : allPlants.where((p) => p.gardenId == _selectedGardenFilterId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Khu vườn của tôi",
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B1C1A),
              ),
            ),
            TextButton(
              onPressed: () {
                _navigateToGardenTab(context);
              },
              child: Text(
                "Xem tất cả",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF364534),
                ),
              ),
            ),
          ],
        ),

        // Hàng chip danh sách TẤT CẢ các khu vườn để người dùng lọc xem đầy đủ
        if (gardens.length > 1) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _buildGardenChip(
                  label: "Tất cả các vườn",
                  isSelected: _selectedGardenFilterId == null,
                  onTap: () {
                    setState(() {
                      _selectedGardenFilterId = null;
                    });
                  },
                ),
                ...gardens.map((g) {
                  final isSel = _selectedGardenFilterId == g.id;
                  return _buildGardenChip(
                    label: g.name,
                    isSelected: isSel,
                    onTap: () {
                      setState(() {
                        _selectedGardenFilterId = g.id;
                      });
                    },
                  );
                }),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),
        if (displayedPlants.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4E2DF)),
            ),
            child: Column(
              children: [
                const Icon(Icons.yard_outlined, size: 40, color: Color(0xFF364534)),
                const SizedBox(height: 8),
                Text(
                  "Chưa có chậu cây nào trong mục này",
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    _navigateToGardenTab(context);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Khám phá khu vườn"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF364534),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: displayedPlants.map((plant) {
                // Xác định màu và icon tình trạng thực tế (kết hợp bệnh lý & lịch chăm sóc đến hạn)
                Color healthColor;
                IconData healthIcon;
                final status = plant.effectiveStatusText;
                if (status.startsWith('Bị') || status == 'Cần điều trị') {
                  healthColor = const Color(0xFFDC2626);
                  healthIcon = Icons.warning_amber_rounded;
                } else if (status == 'Cần tưới nước') {
                  healthColor = const Color(0xFFE06C00);
                  healthIcon = Icons.water_drop_rounded;
                } else if (status == 'Cần bón phân') {
                  healthColor = const Color(0xFFD97706);
                  healthIcon = Icons.science_rounded;
                } else if (status == 'Cần kiểm tra') {
                  healthColor = const Color(0xFFD97706);
                  healthIcon = Icons.shield_outlined;
                } else if (status == 'Cần chú ý') {
                  healthColor = const Color(0xFFD97706);
                  healthIcon = Icons.warning_amber_rounded;
                } else if (status == 'Đang phục hồi') {
                  healthColor = const Color(0xFF2563EB);
                  healthIcon = Icons.autorenew_rounded;
                } else {
                  healthColor = const Color(0xFF15803D);
                  healthIcon = Icons.check_circle_rounded;
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlantDetailScreen(gardenPlant: plant),
                      ),
                    );
                  },
                  child: Container(
                    width: 175,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE4E2DF)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ảnh chậu cây + Chip tình trạng sức khỏe (DUY NHẤT TÌNH TRẠNG SỨC KHỎE)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                              child: plant.imageUrl != null && plant.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      plant.imageUrl!,
                                      height: 125,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => Container(
                                        height: 125,
                                        color: const Color(0xFFE8F2E3),
                                        child: const Icon(Icons.local_florist, color: Color(0xFF364534), size: 36),
                                      ),
                                    )
                                  : Container(
                                      height: 125,
                                      color: const Color(0xFFE8F2E3),
                                      child: const Icon(Icons.local_florist, color: Color(0xFF364534), size: 36),
                                    ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(healthIcon, size: 12, color: healthColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      status,
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: healthColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Thông tin cây
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plant.nickname,
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B1C1A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.place_outlined, size: 13, color: Color(0xFF747871)),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      plant.zone,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
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
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildGardenChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        checkmarkColor: Colors.white,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFF364534),
        backgroundColor: Colors.white,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF444842),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected ? const Color(0xFF364534) : const Color(0xFFE4E2DF),
          ),
        ),
      ),
    );
  }

  // 6. Cẩm nang chăm sóc cây (Dạng Blog kiến thức chuyên sâu - Lưu trữ Firestore)
  Widget _buildCamNangBlogSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Cẩm nang chăm sóc cây",
                  style: GoogleFonts.inter(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1C1A),
                  ),
                ),
                Text(
                  "Kinh nghiệm thực chiến từ chuyên gia thực vật",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF747871),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Stream danh sách bài viết từ CSDL Firestore
        StreamBuilder<List<HandbookArticle>>(
          stream: HandbookService.streamArticles(),
          builder: (context, snapshot) {
            final articles = snapshot.data ?? HandbookService.defaultSampleArticles;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: articles.map((article) {
                  return GestureDetector(
                    onTap: () => _openBlogDetailModal(context, article),
                    child: Container(
                      width: 250,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE4E2DF)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ảnh bìa bài viết
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                            child: Stack(
                              children: [
                                Image.network(
                                  article.coverImage,
                                  height: 130,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Container(
                                    height: 130,
                                    color: const Color(0xFFE4E2DF),
                                    child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF364534).withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      article.category,
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      article.readTime,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Tiêu đề & tóm tắt
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  article.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1B1C1A),
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  article.summary,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: const Color(0xFF6B7280),
                                    height: 1.35,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      "Đọc bài viết",
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF364534),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF364534)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  // Chuyển tab sang Khu vườn
  void _navigateToGardenTab(BuildContext context) {
    if (widget.onNavigateToGarden != null) {
      widget.onNavigateToGarden!();
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const GardenScreen()));
    }
  }

  // Hộp thoại đọc bài viết Blog chi tiết - Hỗ trợ chèn ảnh vào bất kỳ đoạn nào!
  void _openBlogDetailModal(BuildContext context, HandbookArticle article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFFBF9F6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Thanh kéo nhỏ
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4E8CE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Nội dung bài viết có thể cuộn
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chip danh mục & thời gian đọc
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF364534).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              article.category,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF364534),
                              ),
                            ),
                          ),
                          Text(
                            article.readTime,
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF747871)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Tiêu đề bài viết
                      Text(
                        article.title,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B1C1A),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tác giả: ${article.author}",
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF4A554A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Ảnh bìa lớn bài viết
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          article.coverImage,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const SizedBox(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Hộp tóm tắt nổi bật
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F2E3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCFE5CE)),
                        ),
                        child: Text(
                          article.summary,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E3A24),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Các khối nội dung linh hoạt (cho phép chèn ảnh vào bất kỳ đoạn nào!)
                      ...article.blocks.map((block) {
                        if (block.type == 'image') {
                          // Khối ảnh minh họa chèn giữa bài viết
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    block.value,
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Container(
                                      width: double.infinity,
                                      height: 140,
                                      color: const Color(0xFFE4E2DF),
                                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                if (block.caption != null && block.caption!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    block.caption!,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontStyle: FontStyle.italic,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        } else if (block.type == 'tip') {
                          // Khối mẹo hay nổi bật
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Text(
                              block.value,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF92400E),
                                height: 1.45,
                              ),
                            ),
                          );
                        } else {
                          // Khối đoạn văn bản
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text(
                              block.value,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF374151),
                                height: 1.55,
                              ),
                            ),
                          );
                        }
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Nút Đóng
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF364534),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      "Đóng bài viết",
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
