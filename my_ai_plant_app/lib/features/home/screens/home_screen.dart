import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../scan/screens/scan_screen.dart';
import '../../chatbot/screens/ai_assistant_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isEmbedded;
  const HomeScreen({super.key, this.isEmbedded = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeTab = 0; // 0: Phong Khach, 1: Ban Cong
  
  // Danh sach cac task va trang thai hoan thanh
  final List<Map<String, dynamic>> _tasks = [
    {
      "id": 1,
      "title": "Tưới nước - Cây Trầu Bà",
      "subtitle": "Còn 2 giờ",
      "isCompleted": false,
      "icon": Icons.water_drop,
      "color": Color(0xFF0F9D58)
    },
    {
      "id": 2,
      "title": "Phơi nắng - Xương rồng",
      "subtitle": "Hoàn thành lúc 08:00",
      "isCompleted": true,
      "icon": Icons.wb_sunny,
      "color": Colors.orange
    }
  ];

  @override
  Widget build(BuildContext context) {
    // Lay kich thuoc man hinh de responsive
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SafeArea(
        child: widget.isEmbedded
            ? SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 30, top: 10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 25),
                      _buildQuickActions(context),
                      const SizedBox(height: 28),
                      _buildMyGardenSection(context, isTablet),
                      const SizedBox(height: 28),
                      _buildAIAssistantSection(context),
                      const SizedBox(height: 28),
                      _buildTodayScheduleSection(context),
                    ],
                  ),
                ),
              )
            : Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100, top: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 25),
                          _buildQuickActions(context),
                          const SizedBox(height: 28),
                          _buildMyGardenSection(context, isTablet),
                          const SizedBox(height: 28),
                          _buildAIAssistantSection(context),
                          const SizedBox(height: 28),
                          _buildTodayScheduleSection(context),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomNavBar(context),
                  ),
                ],
              ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              // Profile Image (Avatar)
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuBoEP6Mw3WISxPYa4X52x0k_gQNHNxat7gcgrO6ci0m5cWStQlqJPFAhUSe9Y7YlU4sUBaTyj3mxy1f9UCb7jXwsVswvaF8ZkXCnLVEOrESdgMfTwm9VykZNpmJKviiLAYGieV6_4FoRAO9Vfzzc3CMDWr9II79MptIOEdNyFlBSNd_PNDAC1FYQN8n767Fi3qLyNHTXSGrHaptO0TxUNkzbbhTlLGxaNdRehSIdypMSRSPxjcz5QI34PO48rd-B-QQJWn_AEFCxLY'
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào,',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Nông Nghiệp Thông Minh',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF006D35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Nút chuông thông báo
        Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E676).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 20, color: Color(0xFF0F9D58)),
                onPressed: () {},
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E676),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00E676),
                      blurRadius: 4,
                    )
                  ],
                ),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        // Nut 1: Nhan dien cay
        Expanded(
          child: _buildActionCard(
            context: context,
            title: "Nhận Diện Cây",
            icon: Icons.eco,
            iconColor: const Color(0xFF0F9D58),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScanScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 15),
        // Nut 2: Chan doan benh
        Expanded(
          child: _buildActionCard(
            context: context,
            title: "Chẩn Đoán Bệnh",
            icon: Icons.medical_services,
            iconColor: Colors.red[400]!,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScanScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.beVietnamPro(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyGardenSection(BuildContext context, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Khu Vườn Của Tôi",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                "XEM TẤT CẢ",
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F9D58),
                  letterSpacing: 0.8,
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 12),
        // Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTabButton(0, "Phòng Khách"),
              const SizedBox(width: 12),
              _buildTabButton(1, "Ban Công"),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // List grid cay trong (Responsive dua tren screen width)
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isTablet ? 4 : 2, // 4 cot cho tablet/web, 2 cot cho dien thoai
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.72, // Ty le hop ly tranh tran text tren dien thoai
          children: [
            // Card 1
            _buildPlantCard(
              title: "Cây Trầu Bà",
              subtitle: "Độ ẩm: 65%",
              status: "Khỏe mạnh",
              statusColor: const Color(0xFF0F9D58),
              imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuCLGMdnfgKQ5S7ZECtDqeuf1IhHTvTo1FIYMIwNWeVOwPom0eRMjmGU03CE_GaeP7nXSJ5Lo1j-F451SHDIJP6a0jD_F0MsdBtVTOOLQiSIB2URye-f_HasLaO1kM9fkOcvmrA4MznRm8kpHUJuFA2-oTdAWt6tXEJ55CZPyHB_zsus40DkbtutxRImn5Xa1X2Hahhh67mDNtL3zg2ukZWMcwXrJ1Al7uz9ceWXNCxrXQzULlQJl3mj5KBC-Q6CsYWrpoDC8OH4kaI",
            ),
            // Card 2
            _buildPlantCard(
              title: "Bàng Singapore",
              subtitle: "Đất quá khô",
              status: "Cần chú ý",
              statusColor: const Color(0xFFBA1A1A),
              imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuBZUCeHemsEgwfzLEodiC6qzr-XC6YUd82qCkFV1ls7RXRfJSOmQtgC6FNhyEIoHsOhkx8PjO9Bg1qidgjgG8NgW7lYkHY56joGIbWFovJxVulUFoWyBDleu59WkHqSlIizXN4w8mSIIIG7WcYzg0CG2iE9pVw7M8Tp7JyNzoQyrRn_UTJNohxluCHoZjeRwDsVtl_VsMph2ft100MFnJA0oM1mdS2mwzI_YTfXeFkU-zkdtuxPKNEXouGJruyU1FxgYSyqKhkTYe4",
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTabButton(int index, String title) {
    final bool isActive = _activeTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF006D35) : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.white.withValues(alpha: 0.5),
            width: 0.5,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: const Color(0xFF006D35).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
          ],
        ),
        child: Text(
          title,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildPlantCard({
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required String imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor == const Color(0xFFBA1A1A) 
              ? const Color(0xFFBA1A1A).withValues(alpha: 0.2) 
              : Colors.white.withValues(alpha: 0.5),
          width: statusColor == const Color(0xFFBA1A1A) ? 1.0 : 0.5,
        ),
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
          // Anh cua cay va tag status
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Tag trang thai
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.2),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Ten cay
          Text(
            title,
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Thong so do am / dat kho
          Text(
            subtitle,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor == const Color(0xFFBA1A1A) ? const Color(0xFFBA1A1A) : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAssistantSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy, color: Color(0xFF006D35), size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Trợ Lý AI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF006D35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Xin chào, tôi là trợ lý chăm sóc cây trồng của bạn, tôi có thể giúp gì cho bạn?',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              color: const Color(0xFF3B4A3D),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AiAssistantScreen()),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
              label: Text(
                'Trò chuyện mới',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006D35),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF006D35).withValues(alpha: 0.4),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTodayScheduleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Lịch Chăm Sóc Hôm Nay",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final task = _tasks[index];
            final bool isDone = task["isCompleted"];

            return AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isDone ? 0.6 : 1.0,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.01),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // Icon task
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDone ? Colors.grey[200] : task["color"].withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              task["icon"],
                              color: isDone ? Colors.grey[500] : task["color"],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Thong tin task
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task["title"],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDone ? Colors.black38 : Colors.black87,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Thoi gian con lai
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 13,
                                      color: isDone ? Colors.black26 : const Color(0xFF0F9D58),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        task["subtitle"],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDone ? Colors.black26 : const Color(0xFF0F9D58),
                                        ),
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
                    // Checkbox nut tron
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          task["isCompleted"] = !task["isCompleted"];
                          if (task["isCompleted"]) {
                            task["subtitle"] = "Hoàn thành lúc 20:00";
                          } else {
                            task["subtitle"] = task["id"] == 1 ? "Còn 2 giờ" : "Còn 4 giờ";
                          }
                        });
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFF0F9D58) : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDone ? Colors.transparent : Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: isDone
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        )
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 72,
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavButton(Icons.home, "Trang Chủ", true),
          _buildNavButton(Icons.eco, "Khu Vườn", false),
          
          // Nut chup anh noi o giua
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScanScreen()),
              );
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFF0F9D58),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF0F9D58),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: const Icon(Icons.photo_camera, color: Colors.white, size: 26),
            ),
          ),
          
          _buildNavButton(Icons.shopping_cart, "Cửa Hàng", false),
          _buildNavButton(Icons.person, "Cá Nhân", false),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String label, bool isActive) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF0F9D58) : Colors.black38,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFF0F9D58) : Colors.black38,
            ),
          )
        ],
      ),
    );
  }
}
