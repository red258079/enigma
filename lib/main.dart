import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/utils/storage.dart';
import 'core/api/api_client.dart';
import 'core/services/push_notification_service.dart';
import 'theme/app_theme.dart';
import 'app.dart';

/// Global navigator key để ApiClient có thể điều hướng về LoginScreen
/// khi refresh token hết hạn (không cần BuildContext).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage & secure storage
  await StorageUtil.init();

  // Initialize API Client interceptors
  ApiClient.init();

  // Initialize Firebase & Push Notification Service
  await PushNotificationService.init();

  // Kết nối callback: khi cả refresh token hết hạn → tự động về LoginScreen
  ApiClient.onUnauthorized = () {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
  };

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.bgSurface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(EnigmaApp(navigatorKey: navigatorKey));
}
