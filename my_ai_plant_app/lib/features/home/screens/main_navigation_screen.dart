import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../garden/providers/garden_provider.dart';
import 'home_screen.dart';
import '../../scan/screens/scan_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../garden/screens/garden_screen.dart';
import '../../shop/screens/shop_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  late final List<Widget> _screens;
  Timer? _notificationCheckTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = [
      HomeScreen(
        isEmbedded: true,
        onNavigateToGarden: () => _onTabTapped(1),
      ),
      const GardenScreen(),
      const ScanScreen(),
      const ShopScreen(),
      const ProfileScreen(),
    ];

    // Nạp sẵn giờ nhắc mặc định & khung Không làm phiền vào cache
    NotificationService.loadPreferences();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkReminders();
    });

    _notificationCheckTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _checkReminders();
    });
  }

  void _checkReminders() {
    if (!mounted) return;
    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);
    NotificationService.checkAndNotifyPendingTasks(context, gardenProvider.allUserPlants);
  }

  @override
  void dispose() {
    _notificationCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background, // surface color
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
            color: c.surface, // Solid color, no glass effect to prevent content bleeding
            borderRadius: BorderRadius.circular(36), // Bo tron
            boxShadow: [
              BoxShadow(
                color: (c.isDark ? Colors.black : const Color(0xFF364534)).withValues(alpha: c.isDark ? 0.35 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: c.border,
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
                        color: c.surfaceTint, // Màu nền khi active
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  // Các nút bấm nằm đè lên trên
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavButton(Icons.home_outlined, Icons.home, context.tr("Trang chủ", "Home"), 0, activeWidth, inactiveWidth),
                      _buildNavButton(Icons.eco_outlined, Icons.eco, context.tr("Khu vườn", "Garden"), 1, activeWidth, inactiveWidth),
                      _buildNavButton(Icons.camera_alt_outlined, Icons.camera_alt, context.tr("Camera", "Scan"), 2, activeWidth, inactiveWidth),
                      _buildNavButton(Icons.shopping_bag_outlined, Icons.shopping_bag, context.tr("Cửa hàng", "Shop"), 3, activeWidth, inactiveWidth),
                      _buildNavButton(Icons.person_outline, Icons.person, context.tr("Cá nhân", "Profile"), 4, activeWidth, inactiveWidth),
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
    final c = context.colors;
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
                  color: isActive ? (c.isDark ? c.primaryText : const Color(0xFF364534)) : c.textMuted,
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
                          color: c.isDark ? c.primaryText : const Color(0xFF364534),
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
