import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_tr.dart';
import '../../../core/services/ai_config_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../garden/providers/garden_provider.dart';
import '../../home/screens/main_navigation_screen.dart';
import '../../home/services/handbook_service.dart';
import '../../home/services/realtime_weather_service.dart';
import '../../home/services/weather_widget_service.dart';
import '../widgets/mascot_speed_lines.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const _totalDuration = Duration(milliseconds: 5200);
  static const _brandLetters = ['F', 'l', 'o', 'r', 'i', 'a'];

  late final AnimationController _mascotController;
  late final AnimationController _contentController;

  // Chuỗi chuyển động của Mascot (~5.2s): Trái (0-1.2s) -> Giữa (1.2-4.0s) -> Phải (4.0-5.2s)
  late final Animation<Offset> _mascotSlide;
  late final Animation<double> _mascotFade;

  // Chuỗi xuất hiện từng ký tự của "Floria" & Slogan
  late final List<Animation<double>> _letterInProgress;
  late final Animation<double> _sloganInFade;
  late final Animation<Offset> _sloganInSlide;

  // Chuỗi biến mất (4.0-5.2s): mờ dần + dịch chuyển nhẹ lên trên
  late final Animation<double> _brandOutProgress;
  late final Animation<double> _sloganOutFade;
  late final Animation<Offset> _sloganOutSlide;

  bool _started = false;

  @override
  void initState() {
    super.initState();

    _mascotController = AnimationController(vsync: this, duration: _totalDuration);
    _contentController = AnimationController(vsync: this, duration: _totalDuration);

    // 1. Mascot Animation (0 -> 5200ms)
    _mascotSlide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-1.6, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 23.0, // 0 - 1200ms
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset.zero),
        weight: 54.0, // 1200 - 4000ms
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(1.6, 0.0),
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 23.0, // 4000 - 5200ms
      ),
    ]).animate(_mascotController);

    _mascotFade = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 17.0, // 0 - 880ms
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 70.0, // 880 - 4520ms
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 13.0, // 4520 - 5200ms
      ),
    ]).animate(_mascotController);

    // 2. Content In Animation (1050 - 3200ms => 0.20 - 0.62)
    // Dùng easeOutQuart + stagger mượt (0.025/ký tự) để sóng chữ "Floria" trôi cực êm
    _letterInProgress = List.generate(_brandLetters.length, (i) {
      final start = 0.20 + i * 0.026;
      final end = (start + 0.24).clamp(0.0, 0.62);
      return CurvedAnimation(
        parent: _contentController,
        curve: Interval(start, end, curve: Curves.easeOutQuart),
      );
    });

    _sloganInFade = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.42, 0.64, curve: Curves.easeOutCubic),
    );
    _sloganInSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.42, 0.64, curve: Curves.easeOutQuart),
      ),
    );

    // 3. Content Out Animation (4000 - 5200ms => 0.77 - 1.00)
    _brandOutProgress = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.77, 0.95, curve: Curves.easeInOutCubic),
    );

    _sloganOutFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.81, 0.99, curve: Curves.easeInOutCubic),
      ),
    );
    _sloganOutSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -0.22),
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.81, 1.00, curve: Curves.easeInOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_started) {
        _started = true;
        _startSplashSequence();
      }
    });
  }

  @override
  void dispose() {
    _mascotController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _startSplashSequence() async {
    // Giải mã trước ảnh Mascot để khung hình đầu tiên không bị giật
    await precacheImage(const AssetImage('assets/images/mascot_run.png'), context)
        .catchError((_) {});
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final Future<void> preloadTask = auth.isLoggedIn
        ? _preloadHomeData().timeout(
            const Duration(milliseconds: 5500),
            onTimeout: () {},
          )
        : Future.wait([
            precacheImage(const AssetImage('assets/images/mascot_chao_mung.png'), context)
                .timeout(const Duration(milliseconds: 3000), onTimeout: () {})
                .catchError((_) {}),
            precacheImage(const AssetImage('assets/images/google_logo.png'), context)
                .timeout(const Duration(milliseconds: 3000), onTimeout: () {})
                .catchError((_) {}),
          ]);

    try {
      await Future.wait([
        _mascotController.forward().orCancel,
        _contentController.forward().orCancel,
        AiConfigService.loadOnAppStart(),
        preloadTask,
      ]);
    } on TickerCanceled {
      return;
    } catch (e) {
      debugPrint('Splash sequence error: $e');
    }

    if (!mounted) return;
    final targetScreen = auth.isLoggedIn ? const MainNavigationScreen() : const LoginScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  Future<void> _preloadHomeData() async {
    if (!mounted) return;
    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);

    final List<Future<void>> tasks = [
      _waitForGardenProvider(gardenProvider),
      RealtimeWeatherService.fetchCurrentWeather().then((_) {}).catchError((_) {}),
      WeatherWidgetService.streamConfigs().first.then((configs) async {
        if (!mounted) return;
        final cfg = WeatherWidgetService.getConfigForHour(configs, DateTime.now().hour);
        if (cfg.heroImageUrl.isNotEmpty) {
          await precacheImage(NetworkImage(cfg.heroImageUrl), context).catchError((_) {});
        }
      }).catchError((_) {}),
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
          // Background Decor Orbs đồng nhất 1:1 với web/index.html & login_screen.dart
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

          // Khu vực chính: Mascot + Tên ứng dụng Stagger Animation
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Mascot chạy từ trái -> giữa -> phải kèm vệt tốc độ phía sau
                  MascotWithSpeedLines(
                    controller: _mascotController,
                    mascotSlide: _mascotSlide,
                    mascotFade: _mascotFade,
                    child: SizedBox(
                      height: 235,
                      child: Image.asset(
                        'assets/images/mascot_run.png',
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Tên ứng dụng (sóng từng chữ mượt mà) + Fade Out êm
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, _) {
                      final outT = _brandOutProgress.value;
                      return Transform.translate(
                        offset: Offset(0.0, -14.0 * outT),
                        child: Opacity(
                          opacity: (1.0 - outT).clamp(0.0, 1.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(_brandLetters.length, (i) {
                              final t = _letterInProgress[i].value;
                              final dy = 20.0 * (1.0 - t);
                              final scale = 0.92 + 0.08 * t;
                              return Transform.translate(
                                offset: Offset(0.0, dy),
                                child: Transform.scale(
                                  scale: scale,
                                  child: Opacity(
                                    opacity: t.clamp(0.0, 1.0),
                                    child: Text(
                                      _brandLetters[i],
                                      style: GoogleFonts.outfit(
                                        fontSize: 44,
                                        fontWeight: FontWeight.bold,
                                        color: primaryGreen,
                                        letterSpacing: 1.0,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // 3. Slogan xuất hiện nối tiếp và biến mất sau tên thương hiệu
                  SlideTransition(
                    position: _sloganOutSlide,
                    child: FadeTransition(
                      opacity: _sloganOutFade,
                      child: SlideTransition(
                        position: _sloganInSlide,
                        child: FadeTransition(
                          opacity: _sloganInFade,
                          child: Text(
                            context.tr(
                              'Hỗ trợ quản lý chăm sóc cây trồng của bạn',
                              'Your smart companion for plant care',
                            ),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              color: textSecondary,
                              letterSpacing: 0.2,
                              height: 1.4,
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

          // Phiên bản hiện tại ở dưới cùng
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Center(
                child: Text(
                  context.tr('Phiên bản ${AppConstants.appVersion}', 'Version ${AppConstants.appVersion}'),
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
