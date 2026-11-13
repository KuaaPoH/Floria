import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../garden/providers/garden_provider.dart';
import '../../home/screens/main_navigation_screen.dart';
import '../../home/services/handbook_service.dart';
import '../../home/services/realtime_weather_service.dart';
import '../../home/services/weather_widget_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _didPrecacheAssets = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _prepareAndNavigate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didPrecacheAssets) {
      _didPrecacheAssets = true;
      // Nạp & giải mã trước ảnh logo + mascot vào ImageCache để không bị trễ khung hình
      precacheImage(const AssetImage('assets/images/logo.png'), context).catchError((_) {});
      precacheImage(const AssetImage('assets/images/mascot_chao_mung.png'), context).catchError((_) {});
      precacheImage(const AssetImage('assets/images/mascot_huong_dan.png'), context).catchError((_) {});
    }
  }

  Future<void> _prepareAndNavigate() async {
    // Giữ màn hình chờ tối thiểu 1.5s cho hiệu ứng mượt mà
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 1500));

    try {
      if (mounted) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        if (auth.isLoggedIn) {
          // Nạp trước dữ liệu trang chủ & ảnh nền (tối đa 4.5s để không bị kẹt khi mạng yếu)
          await Future.wait([
            minDelay,
            _preloadHomeData().timeout(
              const Duration(milliseconds: 4500),
              onTimeout: () {},
            ),
          ]);
        } else {
          // Đảm bảo ảnh màn hình chào mừng (LoginScreen) đã giải mã xong trước khi chuyển trang
          await Future.wait([
            Future<void>.delayed(const Duration(milliseconds: 1800)),
            precacheImage(const AssetImage('assets/images/mascot_chao_mung.png'), context)
                .timeout(const Duration(milliseconds: 2500), onTimeout: () {})
                .catchError((_) {}),
          ]);
        }
      }
    } catch (e) {
      debugPrint('Splash preload error: $e');
      await minDelay;
    }

    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            auth.isLoggedIn ? const MainNavigationScreen() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  Future<void> _preloadHomeData() async {
    if (!mounted) return;
    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);

    final List<Future<void>> tasks = [
      // 1. Chờ dữ liệu khu vườn & cây trồng từ Firestore
      _waitForGardenProvider(gardenProvider),
      // 2. Nạp trước thời tiết thực tế vào bộ nhớ đệm
      RealtimeWeatherService.fetchCurrentWeather().then((_) {}).catchError((_) {}),
      // 3. Nạp cấu hình widget thời tiết & precache ảnh nền hero
      WeatherWidgetService.streamConfigs().first.then((configs) async {
        if (!mounted) return;
        final cfg = WeatherWidgetService.getConfigForHour(configs, DateTime.now().hour);
        if (cfg.heroImageUrl.isNotEmpty) {
          await precacheImage(NetworkImage(cfg.heroImageUrl), context).catchError((_) {});
        }
      }).catchError((_) {}),
      // 4. Nạp danh sách cẩm nang & precache ảnh bìa đầu tiên
      HandbookService.streamArticles().first.then((articles) async {
        if (!mounted) return;
        await Future.wait(
          articles.take(3).where((a) => a.coverImage.isNotEmpty).map(
                (a) => precacheImage(NetworkImage(a.coverImage), context).catchError((_) {}),
              ),
        );
      }).catchError((_) {}),
    ];

    await Future.wait(tasks);

    // Precache nhanh một vài ảnh cây trong vườn nếu đã tải xong
    if (mounted && gardenProvider.allUserPlants.isNotEmpty) {
      await Future.wait(
        gardenProvider.allUserPlants
            .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
            .take(4)
            .map((p) => precacheImage(NetworkImage(p.imageUrl!), context).catchError((_) {})),
      );
    }
  }

  Future<void> _waitForGardenProvider(GardenProvider provider) {
    if (!provider.isLoading) return Future.value();
    final completer = Completer<void>();
    late VoidCallback listener;
    listener = () {
      if (!provider.isLoading && !completer.isCompleted) {
        provider.removeListener(listener);
        completer.complete();
      }
    };
    provider.addListener(listener);
    return completer.future.whenComplete(() => provider.removeListener(listener));
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF5F7F3);
    const primaryGreen = Color(0xFF2E6F40);
    const textSecondary = Color(0xFF364534);
    const textMuted = Color(0xFF6A756B);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Decor Orbs đồng nhất với login_screen.dart và web/index.html
          Positioned(
            top: -150,
            right: -150,
            child: IgnorePointer(
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryGreen.withValues(alpha: 0.07),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -120,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryGreen.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),

          // Nội dung chính ở giữa màn hình
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFE0EAE1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF17231A).withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 116,
                        height: 116,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/logo.jpg',
                            width: 116,
                            height: 116,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Floria',
                    style: GoogleFonts.outfit(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hỗ trợ quản lý chăm sóc cây trồng của bạn',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      color: textSecondary,
                      letterSpacing: 0.2,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const _ThreeDotsLoader(),
                  const SizedBox(height: 14),
                  Text(
                    'Đang vào khu vườn...',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: primaryGreen.withValues(alpha: 0.85),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Phiên bản hiện tại ở dưới cùng
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Center(
                child: Text(
                  'Phiên bản 0.0.1',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreeDotsLoader extends StatefulWidget {
  const _ThreeDotsLoader();

  @override
  State<_ThreeDotsLoader> createState() => _ThreeDotsLoaderState();
}

class _ThreeDotsLoaderState extends State<_ThreeDotsLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.18;
            final t = (_dotsController.value - delay) % 1.0;
            // Sóng nảy mượt trong khoảng t thuộc [0, 0.6]
            double wave = 0.0;
            if (t >= 0.0 && t <= 0.6) {
              wave = (t <= 0.3) ? (t / 0.3) : (1.0 - (t - 0.3) / 0.3);
              wave = Curves.easeInOut.transform(wave);
            }
            final scale = 0.75 + 0.33 * wave;
            final opacity = 0.38 + 0.62 * wave;
            final dy = -6.0 * wave;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.5),
              child: Transform.translate(
                offset: Offset(0, dy),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2E6F40).withValues(alpha: opacity),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
