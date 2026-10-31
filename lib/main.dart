import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/utils/storage.dart';
import 'core/api/api_client.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/reminder_service.dart';
import 'core/services/sync_service.dart';
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

  // Initialize Sync Service (Theo dõi kết nối mạng & tự động đồng bộ database)
  await SyncService.instance.init();

  // Khi sao lưu dữ liệu hoàn tất, tự động gửi thông báo đến thanh thông báo của điện thoại
  SyncService.instance.onSyncCompleted = (message) {
    PushNotificationService.showNotification(
      title: '☁️ Sao lưu dữ liệu thành công',
      body: message,
    );
  };

  // Initialize Firebase & Push Notification Service
  await PushNotificationService.init();

  // Initialize Daily Sleep Reminder Service
  await ReminderService.init();

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
