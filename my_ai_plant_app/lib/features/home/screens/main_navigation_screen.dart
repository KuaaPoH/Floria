import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import '../../scan/screens/scan_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../garden/screens/garden_screen.dart';
import '../../shop/screens/shop_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(isEmbedded: true),
      const GardenScreen(),
      const ScanScreen(),
      const ShopScreen(),
      const ProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F6), // surface color
      extendBody: false, // Tắt để không cho nội dung cuộn luồn ra sau thanh Nav Menu
      body: SizedBox.expand(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 72,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF9F6), // Solid color, no glass effect to prevent content bleeding
            borderRadius: BorderRadius.circular(36), // Bo tron
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF364534).withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: const Color(0xFFE4E2DF),
                spreadRadius: 1, // Vien mong
              )
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              
              // Sử dụng khoảng cách linh hoạt (vd: 3% chiều rộng) để các icon không bị dính vào nhau
              final double spacing = maxWidth * 0.035; 
              final double availableWidth = maxWidth - (spacing * 4);
              
              // Giảm tỷ lệ active xuống 2.2 để các nút inactive có thêm không gian thở
              final double inactiveWidth = availableWidth / 6.2;
              final double activeWidth = inactiveWidth * 2.2;

              double activeLeft = 0;
              for (int i = 0; i < _currentIndex; i++) {
                activeLeft += inactiveWidth + spacing;
              }

              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Viên thuốc trượt (Sliding Pill)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    left: activeLeft,
                    width: activeWidth,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEEEA), // Màu nền khi active
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  // Các nút bấm nằm đè lên trên
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavButton(Icons.home_outlined, Icons.home, "Trang chủ", 0, activeWidth, inactiveWidth),
                      _buildNavButton(Icons.eco_outlined, Icons.eco, "Khu vườn", 1, activeWidth, inactiveWidth),
                      _buildNavButton(Icons.camera_alt_outlined, Icons.camera_alt, "Camera", 2, activeWidth, inactiveWidth),
                      _buildNavButton(Icons.shopping_bag_outlined, Icons.shopping_bag, "Cửa hàng", 3, activeWidth, inactiveWidth),
                      _buildNavButton(Icons.person_outline, Icons.person, "Cá nhân", 4, activeWidth, inactiveWidth),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData normalIcon, IconData activeIcon, String label, int index, double activeWidth, double inactiveWidth) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        width: isActive ? activeWidth : inactiveWidth,
        height: 48.0,
        alignment: Alignment.center,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  isActive ? activeIcon : normalIcon,
                  key: ValueKey<bool>(isActive),
                  color: isActive ? const Color(0xFF364534) : const Color(0xFF747871),
                  size: isActive ? 22 : 24,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: isActive ? null : 0,
                  child: ClipRect(
                    child: Padding(
                      padding: EdgeInsets.only(left: isActive ? 6.0 : 0.0),
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF364534),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
