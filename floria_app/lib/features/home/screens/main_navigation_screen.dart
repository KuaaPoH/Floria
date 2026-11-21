import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/menu_icon_helper.dart';
import '../../garden/providers/garden_provider.dart';
import 'home_screen.dart';
import '../../scan/screens/scan_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../garden/screens/garden_screen.dart';
import '../../shop/screens/shop_screen.dart';

class _NavTabConfig {
  final String route;
  final String titleVi;
  final String titleEn;
  final String iconName;
  final int order;

  const _NavTabConfig({
    required this.route,
    required this.titleVi,
    required this.titleEn,
    required this.iconName,
    required this.order,
  });
}

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const List<_NavTabConfig> _defaultTabs = [
    _NavTabConfig(route: 'home', titleVi: 'Trang chủ', titleEn: 'Home', iconName: 'Home', order: 1),
    _NavTabConfig(route: 'garden', titleVi: 'Khu vườn', titleEn: 'Garden', iconName: 'Eco', order: 2),
    _NavTabConfig(route: 'scan', titleVi: 'Camera', titleEn: 'Scan', iconName: 'CameraAlt', order: 3),
    _NavTabConfig(route: 'shop', titleVi: 'Cửa hàng', titleEn: 'Shop', iconName: 'ShoppingBag', order: 4),
    _NavTabConfig(route: 'profile', titleVi: 'Cá nhân', titleEn: 'Profile', iconName: 'Person', order: 5),
  ];

  late int _currentIndex;
  late final Map<String, Widget> _screenByRoute;
  List<_NavTabConfig> _tabs = _defaultTabs;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _menuSub;
  Timer? _notificationCheckTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screenByRoute = {
      'home': HomeScreen(
        isEmbedded: true,
        onNavigateToGarden: () => _navigateToRoute('garden'),
      ),
      'garden': const GardenScreen(),
      'scan': const ScanScreen(),
      'shop': const ShopScreen(),
      'profile': const ProfileScreen(),
    };

    _listenRemoteMenus();

    // Nạp sẵn giờ nhắc mặc định & khung Không làm phiền vào cache
    NotificationService.loadPreferences();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkReminders();
    });

    _notificationCheckTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _checkReminders();
    });
  }

  void _listenRemoteMenus() {
    _menuSub = FirebaseFirestore.instance
        .collection('MenuItems')
        .where('target', isEqualTo: 'mobile_app')
        .snapshots()
        .listen(
      (snap) {
        if (!mounted || snap.docs.isEmpty) return;
        final loaded = snap.docs
            .where((doc) => doc.data()['visible'] != false)
            .map((doc) {
              final d = doc.data();
              final route = (d['route'] ?? '').toString().trim();
              final titleVi = (d['title'] ?? '').toString().trim();
              final titleEn = (d['titleEn'] ?? titleVi).toString().trim();
              return _NavTabConfig(
                route: route,
                titleVi: titleVi.isNotEmpty ? titleVi : route,
                titleEn: titleEn.isNotEmpty ? titleEn : titleVi,
                iconName: (d['icon'] ?? 'Home').toString().trim(),
                order: (d['order'] is num) ? (d['order'] as num).toInt() : 99,
              );
            })
            .where((t) => _screenByRoute.containsKey(t.route))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        if (loaded.isNotEmpty) {
          setState(() {
            _tabs = loaded;
            if (_currentIndex >= _tabs.length) {
              _currentIndex = 0;
            }
          });
        }
      },
      onError: (_) {
        // Giữ nguyên _defaultTabs nếu không tải được Firestore
      },
    );
  }

  void _navigateToRoute(String route) {
    final idx = _tabs.indexWhere((t) => t.route == route);
    if (idx >= 0) {
      _onTabTapped(idx);
    }
  }

  void _checkReminders() {
    if (!mounted) return;
    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);
    NotificationService.checkAndNotifyPendingTasks(context, gardenProvider.allUserPlants);
  }

  @override
  void dispose() {
    _menuSub?.cancel();
    _notificationCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex.clamp(0, _tabs.length - 1);
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
    final screens = _tabs.map((t) => _screenByRoute[t.route]!).toList();
    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      backgroundColor: c.background,
      extendBody: false,
      body: SizedBox.expand(
        child: IndexedStack(
          index: safeIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 64,
          margin: const EdgeInsets.only(left: 18, right: 18, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: (c.isDark ? Colors.black : const Color(0xFF364534)).withValues(alpha: c.isDark ? 0.35 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: c.border,
                spreadRadius: 1,
              )
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              final int count = _tabs.length;

              if (count == 1) {
                final t = _tabs.first;
                final icons = MenuIconHelper.resolve(t.iconName);
                return Center(
                  child: _buildNavButton(
                    icons.normal,
                    icons.active,
                    context.tr(t.titleVi, t.titleEn),
                    0,
                    maxWidth,
                    maxWidth,
                  ),
                );
              }

              final double spacing = maxWidth * 0.035;
              final double availableWidth = maxWidth - (spacing * (count - 1));
              final double inactiveWidth = availableWidth / (count + 1.2);
              final double activeWidth = inactiveWidth * 2.2;

              double activeLeft = 0;
              for (int i = 0; i < safeIndex; i++) {
                activeLeft += inactiveWidth + spacing;
              }

              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    left: activeLeft,
                    width: activeWidth,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.surfaceTint,
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (int i = 0; i < count; i++)
                        Builder(
                          builder: (_) {
                            final t = _tabs[i];
                            final icons = MenuIconHelper.resolve(t.iconName);
                            return _buildNavButton(
                              icons.normal,
                              icons.active,
                              context.tr(t.titleVi, t.titleEn),
                              i,
                              activeWidth,
                              inactiveWidth,
                            );
                          },
                        ),
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
        height: 44.0,
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
                  size: isActive ? 20 : 22,
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
