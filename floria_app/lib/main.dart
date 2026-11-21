import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_settings_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/scan/providers/scan_provider.dart';
import 'features/garden/providers/garden_provider.dart';
import 'features/history/providers/history_provider.dart';
import 'features/shop/providers/shop_provider.dart';
import 'features/chatbot/providers/chat_provider.dart';
import 'firebase_options.dart';
import 'features/splash/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    unawaited(PushNotificationService.initialize());
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // Đọc sẵn cài đặt Giao diện tối & Ngôn ngữ + nạp trước Google Fonts + phiên bản app
  final appSettings = AppSettingsProvider();
  await Future.wait([
    appSettings.load(),
    AppConstants.loadAppVersion(),
    GoogleFonts.pendingFonts([
      GoogleFonts.outfit(fontWeight: FontWeight.bold),
      GoogleFonts.inter(fontWeight: FontWeight.w400),
      GoogleFonts.inter(fontWeight: FontWeight.w500),
      GoogleFonts.inter(fontWeight: FontWeight.w600),
      GoogleFonts.inter(fontWeight: FontWeight.w700),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
    ]).timeout(const Duration(milliseconds: 1500), onTimeout: () => []),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        ChangeNotifierProvider(create: (_) => GardenProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    return MaterialApp(
      navigatorKey: PushNotificationService.navigatorKey,
      title: 'Floria',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode, // Người dùng chọn trong Cài đặt > Giao diện tối
      locale: settings.locale, // Ngôn ngữ giao diện Hub (vi / en)
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        const double designWidth = 430.0;
        final mq = MediaQuery.of(context);
        if (mq.size.width > 0 && mq.size.width < 600) {
          final double scale = mq.size.width / designWidth;
          final Size scaledSize = Size(designWidth, mq.size.height / scale);
          return FittedBox(
            fit: BoxFit.fill,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: scaledSize.width,
              height: scaledSize.height,
              child: MediaQuery(
                data: mq.copyWith(
                  size: scaledSize,
                  textScaler: const TextScaler.linear(1.0),
                  padding: mq.padding / scale,
                  viewPadding: mq.viewPadding / scale,
                  viewInsets: mq.viewInsets / scale,
                  systemGestureInsets: mq.systemGestureInsets / scale,
                ),
                child: child!,
              ),
            ),
          );
        }
        return MediaQuery(
          data: mq.copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
