import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../firebase_options.dart';
import 'notification_service.dart';

/// Handler chạy nền khi ứng dụng đang tắt hoặc ở background (FCM).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    debugPrint('FCM Background Message: ${message.messageId} - ${message.notification?.title}');
  } catch (e) {
    debugPrint('FCM Background Handler error: $e');
  }
}

/// Quản lý Firebase Cloud Messaging (FCM): xin quyền, đăng ký topic broadcast,
/// hiển thị thông báo khi đang mở app và xử lý mở app khi chạm thông báo.
class PushNotificationService {
  static const String broadcastTopic = 'floria_broadcast';
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    _initialized = true;
    try {
      await NotificationService.initSystemNotifications();

      final messaging = FirebaseMessaging.instance;

      // Xin quyền nhận thông báo (iOS & Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('FCM permission status: ${settings.authorizationStatus}');

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Đăng ký nhận thông báo broadcast từ Admin
      await messaging.subscribeToTopic(broadcastTopic);

      // Lưu token thiết bị lên Firestore để Admin thống kê số máy đang nhận thông báo
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        unawaited(_saveDeviceToken(token));
      }

      messaging.onTokenRefresh.listen((newToken) {
        if (newToken.isNotEmpty) {
          unawaited(_saveDeviceToken(newToken));
        }
      });

      // Khi app đang mở (Foreground): hiển thị banner thông báo hệ thống qua flutter_local_notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ??
            message.data['title']?.toString() ??
            'Floria';
        final body = message.notification?.body ??
            message.data['body']?.toString() ??
            '';
        if (title.isEmpty && body.isEmpty) return;

        NotificationService.showSystemNotification(
          id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
          payload: message.data['deepLink']?.toString(),
        );
      });

      // Khi app đang chạy nền và người dùng chạm vào thông báo để mở app
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

      // Khi app đã tắt hẳn và được mở lên từ việc chạm vào thông báo
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationOpen(initialMessage);
      }
    } catch (e) {
      debugPrint('Lỗi khởi tạo PushNotificationService: $e');
    }
  }

  static Future<void> _saveDeviceToken(String token) async {
    try {
      await FirebaseFirestore.instance.collection('DeviceTokens').doc(token).set({
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'topic': broadcastTopic,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Không thể lưu FCM token: $e');
    }
  }

  static void _handleNotificationOpen(RemoteMessage message) {
    debugPrint(
      'Người dùng đã chạm thông báo mở Floria: '
      'title=${message.notification?.title ?? message.data['title']}, '
      'deepLink=${message.data['deepLink']}',
    );
  }
}
