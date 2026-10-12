import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/constants/app_constants.dart';
import '../models/notification_item.dart';

class NotificationState extends ChangeNotifier {
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch notifications from backend
  Future<void> fetchNotifications({bool unreadOnly = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (AppConstants.useMockApi) {
        await Future.delayed(const Duration(milliseconds: 300));
        _notifications = [
          NotificationItem(
            id: 'n1',
            type: 'reminder_checkin',
            title: 'Bắt đầu ngày mới cùng Enigma! 🌅',
            body: 'Dành 1 phút check-in tâm trạng hôm nay để nhận điểm streak nhé.',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
          ),
          NotificationItem(
            id: 'n2',
            type: 'task_unlock',
            title: 'Nhiệm vụ mới đã mở khóa! 🎯',
            body: 'Bài tập: Quy tắc 5S và An toàn lao động tại nhà máy đã sẵn sàng.',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          NotificationItem(
            id: 'n3',
            type: 'new_article',
            title: 'Cẩm nang mới: Bí quyết ngủ ngon ca đêm 🌙',
            body: 'Khám phá mẹo cân bằng nhịp sinh học từ các anh chị cựu sinh viên.',
            isRead: true,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];
        _unreadCount = _notifications.where((n) => !n.isRead).length;
      } else {
        final response = await ApiClient.instance.get(
          '/notifications',
          queryParameters: {'unread_only': unreadOnly, 'limit': 50},
        );
        final data = response.data;
        final List<dynamic> items = data['items'] ?? [];
        _notifications = items.map((json) => NotificationItem.fromJson(json)).toList();
        _unreadCount = data['unread_count'] ?? 0;
      }
    } on DioException catch (e) {
      _error = e.response?.data?['detail'] ?? 'Không thể tải danh sách thông báo.';
      debugPrint('Fetch notifications error: ');
    } catch (e) {
      _error = 'Đã có lỗi xảy ra: ';
      debugPrint('Fetch notifications unexpected: ');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch unread count for badge
  Future<void> fetchUnreadCount() async {
    try {
      if (AppConstants.useMockApi) {
        _unreadCount = _notifications.where((n) => !n.isRead).length;
      } else {
        final response = await ApiClient.instance.get('/notifications/unread-count');
        _unreadCount = response.data['unread_count'] ?? 0;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch unread count error: ');
    }
  }

  /// Mark single notification as read
  Future<void> markAsRead(String notifId) async {
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
      notifyListeners();

      if (!AppConstants.useMockApi) {
        try {
          await ApiClient.instance.put('/notifications//read');
        } catch (e) {
          debugPrint('Mark read error: ');
        }
      }
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    if (!AppConstants.useMockApi) {
      try {
        await ApiClient.instance.put('/notifications/read-all');
      } catch (e) {
        debugPrint('Mark all read error: ');
      }
    }
  }

  /// Update FCM device token on backend
  Future<void> updateFCMToken(String token) async {
    if (AppConstants.useMockApi) return;
    try {
      await ApiClient.instance.post(
        '/notifications/fcm-token',
        data: {'fcm_token': token},
      );
      debugPrint('[FCM] Device token registered to backend: ');
    } catch (e) {
      debugPrint('[FCM] Register device token error: ');
    }
  }
}
