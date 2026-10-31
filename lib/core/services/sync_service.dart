import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../utils/storage.dart';
import '../api/api_client.dart';

enum SyncStatus { idle, syncing, completed, error }

class SyncService extends ChangeNotifier {
  static final SyncService instance = SyncService._internal();

  factory SyncService() => instance;

  SyncService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicCheckTimer;

  bool _isOnline = true;
  bool _isSyncing = false;
  SyncStatus _syncStatus = SyncStatus.idle;
  String? _lastSyncMessage;
  DateTime? _lastSyncTime;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  SyncStatus get syncStatus => _syncStatus;
  String? get lastSyncMessage => _lastSyncMessage;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingCount => StorageUtil.getPendingSyncCount();

  // Callback to display global notifications or snackbars when sync completes
  void Function(String message)? onSyncCompleted;

  /// Khởi tạo theo dõi kết nối mạng và thiết lập đồng bộ tự động
  Future<void> init() async {
    // Kiểm tra trạng thái mạng hiện tại
    final results = await _connectivity.checkConnectivity();
    _isOnline = _hasConnection(results);

    // Lắng nghe thay đổi kết nối mạng
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) async {
      final hasConn = _hasConnection(results);
      final wasOffline = !_isOnline;
      _isOnline = hasConn;
      notifyListeners();

      if (hasConn && wasOffline) {
        debugPrint('[SyncService] Mạng đã kết nối trở lại. Đang tự động sao lưu dữ liệu...');
        await syncPendingData();
      }
    });

    // Định kỳ 60 giây kiểm tra và đồng bộ lại nếu còn dữ liệu tồn đọng trong queue
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      if (_isOnline && pendingCount > 0 && !_isSyncing) {
        await syncPendingData();
      }
    });

    // Thử đồng bộ ngay lúc khởi động nếu có mạng
    if (_isOnline && pendingCount > 0) {
      syncPendingData();
    }
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    for (final result in results) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet) {
        return true;
      }
    }
    return false;
  }

  /// Kiểm tra xem thiết bị có thực sự kết nối được với internet hay không
  Future<bool> checkActualInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _isOnline = true;
        notifyListeners();
        return true;
      }
    } catch (_) {
      // Offline hoặc timeout
    }
    _isOnline = false;
    notifyListeners();
    return false;
  }

  /// Thêm tác vụ vào hàng đợi sao lưu dữ liệu ngoại tuyến
  Future<void> enqueueSync({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final item = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': type,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await StorageUtil.addToSyncQueue(item);
    debugPrint('[SyncService] Đã thêm tác vụ vào SyncQueue: $type (Tổng chờ: $pendingCount)');
    notifyListeners();

    // Nếu hiện tại đang có mạng, thử đồng bộ ngay
    if (_isOnline && !_isSyncing) {
      syncPendingData();
    }
  }

  /// Đồng bộ toàn bộ dữ liệu đang chờ trong hàng đợi lên server database
  Future<bool> syncPendingData() async {
    if (_isSyncing) return false;

    final queue = StorageUtil.getSyncQueue();
    if (queue.isEmpty) {
      _syncStatus = SyncStatus.idle;
      notifyListeners();
      return true;
    }

    _isSyncing = true;
    _syncStatus = SyncStatus.syncing;
    notifyListeners();

    int successCount = 0;
    int failCount = 0;

    debugPrint('[SyncService] Bắt đầu đồng bộ ${queue.length} tác vụ lên máy chủ...');

    for (final item in List<Map<String, dynamic>>.from(queue)) {
      final id = item['id'] as String;
      final type = item['type'] as String;
      final payload = Map<String, dynamic>.from(item['payload'] as Map);

      try {
        bool itemSuccess = false;

        switch (type) {
          case 'checkin':
            await ApiClient.instance.post('/checkins', data: payload);
            itemSuccess = true;
            break;

          case 'life_log':
            await ApiClient.instance.post('/life-logs', data: payload);
            itemSuccess = true;
            break;

          case 'task_toggle':
            final taskId = payload['task_id'];
            await ApiClient.instance.post('/tasks/$taskId/toggle');
            itemSuccess = true;
            break;

          case 'onboarding_sync':
            await ApiClient.instance.post('/users/onboarding-status', data: payload);
            itemSuccess = true;
            break;

          default:
            debugPrint('[SyncService] Loại tác vụ không xác định: $type');
            itemSuccess = true; // Bỏ qua tác vụ lỗi format
            break;
        }

        if (itemSuccess) {
          await StorageUtil.removeSyncQueueItem(id);
          successCount++;
        }
      } on DioException catch (dioErr) {
        // Nếu lỗi kết nối/timeout, dừng lại chờ lần có mạng kế tiếp
        if (dioErr.type == DioExceptionType.connectionError ||
            dioErr.type == DioExceptionType.connectionTimeout ||
            dioErr.type == DioExceptionType.sendTimeout ||
            dioErr.type == DioExceptionType.receiveTimeout) {
          _isOnline = false;
          failCount++;
          debugPrint('[SyncService] Mất kết nối trong khi đồng bộ item $id: ${dioErr.message}');
          break;
        } else {
          // Lỗi HTTP 4xx/5xx (ví dụ dữ liệu đã checkin rồi hoặc trùng lặp), xóa khỏi queue để tránh nghẽn
          debugPrint('[SyncService] Server từ chối item $id (${dioErr.response?.statusCode}): ${dioErr.response?.data}');
          await StorageUtil.removeSyncQueueItem(id);
          failCount++;
        }
      } catch (e) {
        debugPrint('[SyncService] Lỗi không xác định khi đồng bộ item $id: $e');
        await StorageUtil.removeSyncQueueItem(id);
        failCount++;
      }
    }

    _isSyncing = false;
    _lastSyncTime = DateTime.now();

    if (successCount > 0) {
      _lastSyncMessage = 'Đã sao lưu $successCount mục dữ liệu lên hệ thống thành công!';
      _syncStatus = SyncStatus.completed;
      onSyncCompleted?.call(_lastSyncMessage!);

      // Tự động ẩn trạng thái thành công sau 4 giây
      Timer(const Duration(seconds: 4), () {
        if (_syncStatus == SyncStatus.completed) {
          _syncStatus = SyncStatus.idle;
          notifyListeners();
        }
      });
    } else if (failCount > 0) {
      _lastSyncMessage = 'Không thể đồng bộ một số dữ liệu. Sẽ thử lại khi có mạng ổn định.';
      _syncStatus = SyncStatus.error;
    } else {
      _syncStatus = SyncStatus.idle;
    }

    notifyListeners();
    return successCount > 0;
  }

  /// Kích hoạt đồng bộ thủ công từ giao diện
  Future<void> syncNow() async {
    await syncPendingData();
  }

  /// Dừng các timer (hữu ích khi test hoặc cleanup)
  void cancelTimers() {
    _connectivitySubscription?.cancel();
    _periodicCheckTimer?.cancel();
  }

  @override
  void dispose() {
    cancelTimers();
    super.dispose();
  }
}
