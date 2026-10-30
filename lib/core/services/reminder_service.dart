import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../main.dart' show navigatorKey;
import '../utils/storage.dart';
import '../../screens/student/life_log_screen.dart';

/// Dịch vụ quản lý thông báo nhắc nhở ghi nhận nhật ký giấc ngủ mỗi ngày
/// Sử dụng inexact alarm (không cần SCHEDULE_EXACT_ALARM).
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int morningReminderId = 830;
  static const int noonReminderId = 1200;
  static const String notificationPayload = 'action:open_life_log';

  static const AndroidNotificationChannel _reminderChannel =
      AndroidNotificationChannel(
    'enigma_sleep_reminder_channel',
    'Nhắc nhở giấc ngủ Enigma',
    description: 'Thông báo nhắc nhở ghi nhận nhật ký giấc ngủ buổi sáng',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static bool _isInitialized = false;
  static bool _hasCheckedLaunchDetails = false;

  /// Khởi tạo service khi app khởi động
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Cấu hình Timezone
      tz.initializeTimeZones();
      try {
        final timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        debugPrint('[ReminderService] Không lấy được timezone hệ thống ($e), dùng Asia/Ho_Chi_Minh');
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
        } catch (_) {}
      }

      // 2. Cấu hình Local Notifications
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload == notificationPayload) {
            navigateToLifeLog();
          }
        },
      );

      // 3. Tạo Android Notification Channel
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_reminderChannel);
      }

      _isInitialized = true;

      // 4. Kiểm tra app launch từ terminated state
      if (!_hasCheckedLaunchDetails) {
        _hasCheckedLaunchDetails = true;
        final launchDetails = await _notifications.getNotificationAppLaunchDetails();
        if (launchDetails != null &&
            launchDetails.didNotificationLaunchApp &&
            launchDetails.notificationResponse?.payload == notificationPayload) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigateToLifeLog();
          });
        }
      }

      // 5. Lên lịch thông báo theo cài đặt hiện tại
      await rescheduleAll();
    } catch (e) {
      debugPrint('[ReminderService] Lỗi khởi tạo: $e');
    }
  }

  /// Kiểm tra xem hôm nay người dùng đã lưu nhật ký giấc ngủ chưa
  /// Tập trung toàn bộ logic "saved today" tại đây.
  static bool hasSavedToday() {
    try {
      final cached = StorageUtil.getCachedTodayLifeLog();
      if (cached == null) return false;
      final hasLog = cached['has_log_today'] as bool? ?? false;
      if (!hasLog) return false;
      final data = cached['data'] as Map?;
      final dateStr = data?['date'] as String?;
      if (dateStr == null) return false;

      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    } catch (e) {
      debugPrint('[ReminderService] Lỗi kiểm tra saved today: $e');
      return false;
    }
  }

  /// Điều hướng tới màn hình LifeLogScreen
  static void navigateToLifeLog() {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.push(MaterialPageRoute(builder: (_) => const LifeLogScreen()));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const LifeLogScreen()),
        );
      });
    }
  }

  /// Xin quyền gửi thông báo (Android 13+ & iOS) kèm hộp thoại giải thích lần đầu
  static Future<bool> requestPermission({BuildContext? context}) async {
    // Nếu có context và chưa từng hỏi, hiển thị popup giải thích ngắn trước
    final hasAskedBefore = StorageUtil.getBool('reminder_permission_asked') ?? false;
    if (context != null && !hasAskedBefore && context.mounted) {
      final agreed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.bedtime_rounded, color: Colors.indigo, size: 24),
              SizedBox(width: 8),
              Text('Nhắc nhở giấc ngủ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
          content: const Text(
            'Enigma cần quyền gửi thông báo để nhắc bạn ghi nhận số giờ ngủ mỗi sáng lúc 08:30, giúp theo dõi sức khỏe và hồi phục tốt nhất chỉ với 1 chạm.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Để sau', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Đồng ý', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      await StorageUtil.setBool('reminder_permission_asked', true);
      if (agreed != true) return false;
    }

    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidPlugin?.requestNotificationsPermission();
        return granted ?? false;
      } else if (Platform.isIOS) {
        final iosPlugin = _notifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('[ReminderService] Lỗi xin quyền: $e');
    }
    return false;
  }

  /// Kiểm tra quyền thông báo của ứng dụng
  static Future<bool> isPermissionGranted() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final areEnabled = await androidPlugin?.areNotificationsEnabled();
        return areEnabled ?? false;
      } else if (Platform.isIOS) {
        return true;
      }
    } catch (_) {}
    return true;
  }

  /// Lên lịch lại toàn bộ thông báo dựa trên cài đặt và trạng thái "saved today"
  static Future<void> rescheduleAll() async {
    final isEnabled = StorageUtil.isSleepReminderEnabled;
    if (!isEnabled) {
      await cancelAll();
      return;
    }

    // Chỉ lên lịch khi đã bật nhắc nhở VÀ đã được cấp quyền thông báo
    final hasPermission = await isPermissionGranted();
    if (!hasPermission) {
      debugPrint('[ReminderService] Quyền thông báo chưa được cấp -> Không lên lịch');
      await cancelAll();
      return;
    }

    final hour = StorageUtil.sleepReminderHour;
    final minute = StorageUtil.sleepReminderMinute;
    final isNoonEnabled = StorageUtil.isNoonReminderEnabled;

    final alreadySavedToday = hasSavedToday();

    // 1. Morning reminder (08:30 hoặc giờ đã chọn)
    await _scheduleDailyNotification(
      id: morningReminderId,
      title: 'Nhắc nhở giấc ngủ 💤',
      body: 'Đêm qua bạn ngủ ổn không? Mở Enigma bấm lưu giấc ngủ, chỉ mất 1 chạm.',
      hour: hour,
      minute: minute,
      forceTomorrow: alreadySavedToday,
    );

    // 2. Optional noon reminder (12:00) nếu chưa lưu
    if (isNoonEnabled) {
      await _scheduleDailyNotification(
        id: noonReminderId,
        title: 'Nhắc nhở giấc ngủ 💤',
        body: 'Bạn chưa lưu giấc ngủ hôm nay. Mở Enigma để cập nhật chỉ với 1 chạm nhé.',
        hour: 12,
        minute: 0,
        forceTomorrow: alreadySavedToday,
      );
    } else {
      await _notifications.cancel(noonReminderId);
    }
  }

  /// Khi người dùng lưu nhật ký thành công:
  /// Hủy thông báo của hôm nay và giữ lịch của ngày mai
  static Future<void> onLifeLogSaved() async {
    try {
      debugPrint('[ReminderService] Life log đã lưu thành công -> Hủy thông báo hôm nay và lên lịch ngày mai');
      // Hủy thông báo hiện tại (bỏ qua nhắc nhở 12h hôm nay), sau đó lên lịch lại bắt đầu từ ngày mai
      await cancelAll();
      await rescheduleAll();
    } catch (e) {
      debugPrint('[ReminderService] Lỗi khi xử lý onLifeLogSaved: $e');
    }
  }

  /// Hủy toàn bộ thông báo nhắc nhở
  static Future<void> cancelAll() async {
    try {
      await _notifications.cancel(morningReminderId);
      await _notifications.cancel(noonReminderId);
    } catch (e) {
      debugPrint('[ReminderService] Lỗi hủy thông báo: $e');
    }
  }

  /// Lên lịch một thông báo lặp hàng ngày bằng inexact schedule
  static Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required bool forceTomorrow,
  }) async {
    try {
      final scheduledDate = _nextInstanceOfTime(hour, minute, forceTomorrow: forceTomorrow);

      const androidDetails = AndroidNotificationDetails(
        'enigma_sleep_reminder_channel',
        'Nhắc nhở giấc ngủ Enigma',
        channelDescription: 'Thông báo nhắc nhở ghi nhận nhật ký giấc ngủ buổi sáng',
        importance: Importance.high,
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

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: notificationPayload,
      );

      debugPrint('[ReminderService] Đã lên lịch reminder (id: $id) lúc $scheduledDate (lặp daily)');
    } catch (e) {
      debugPrint('[ReminderService] Lỗi zonedSchedule id $id: $e');
    }
  }

  /// Tính toán thời điểm tiếp theo cho giờ và phút
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute, {required bool forceTomorrow}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (forceTomorrow || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
