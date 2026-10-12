import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import '../api/api_client.dart';
import '../utils/storage.dart';
import '../../main.dart' show navigatorKey;

// Top-level background handler required by Firebase
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM BG] Received message:  - ');
}

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'enigma_high_importance_channel',
    'Thông báo Enigma',
    description: 'Kênh thông báo nhắc nhở check-in tâm trạng, nhiệm vụ và cẩm nang',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static Future<void> init() async {
    try {
      // 1. Initialize Firebase App
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Request permissions (iOS & Android 13+)
      await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // 4. Initialize Local Notifications for Heads-Up popup
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          if (details.payload != null) {
            _handleNotificationPayload(details.payload!);
          }
        },
      );

      // 5. Create Android Channel
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
      }

      // 6. Foreground message listener (Displays Heads-up banner on phone)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] Received: ');
        final notif = message.notification;
        if (notif != null) {
          showNotification(
            title: notif.title ?? 'Enigma',
            body: notif.body ?? '',
            payload: jsonEncode(message.data),
          );
        }
      });

      // 7. Message clicked from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM AppOpened] Tapped: ');
        _handleNotificationPayload(jsonEncode(message.data));
      });

      // 8. Message clicked when app was terminated
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationPayload(jsonEncode(initialMessage.data));
      }

      // 9. Sync token
      await syncTokenWithBackend();

      // 10. Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(newToken);
      });

    } catch (e) {
      debugPrint('[FCM] Init error (continuing in safe mode): ');
    }
  }

  /// Hiển thị thông báo nổi (Heads-up Notification Banner) trên thanh trạng thái điện thoại
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'enigma_high_importance_channel',
      'Thông báo Enigma',
      channelDescription: 'Kênh thông báo nhắc nhở check-in tâm trạng, nhiệm vụ và cẩm nang',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// Lấy FCM Token của máy và gửi lên backend để nhận push
  static Future<void> syncTokenWithBackend() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        debugPrint('[FCM] Device Token: ');
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('[FCM] Get token error: ');
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
    final authToken = await StorageUtil.getToken();
    if (authToken == null) return; // Chưa login thì không sync vội

    try {
      await ApiClient.instance.post(
        '/notifications/fcm-token',
        data: {'fcm_token': token},
      );
      debugPrint('[FCM] Synced device token to backend successfully');
    } catch (e) {
      debugPrint('[FCM] Sync token error: ');
    }
  }

  static void _handleNotificationPayload(String rawPayload) {
    try {
      debugPrint('[FCM] Handling payload: ');
      navigatorKey.currentState?.pushNamed('/notifications');
    } catch (e) {
      debugPrint('[FCM] Navigation error: ');
    }
  }
}
