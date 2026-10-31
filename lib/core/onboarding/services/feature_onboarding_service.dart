import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../utils/storage.dart';
import '../../api/api_client.dart';
import '../../services/sync_service.dart';

class FeatureOnboardingService extends ChangeNotifier {
  static final FeatureOnboardingService instance = FeatureOnboardingService._internal();
  factory FeatureOnboardingService() => instance;
  FeatureOnboardingService._internal();

  final Set<String> _completedFeatures = {};
  String? _currentUserId;
  bool _isInitialized = false;

  Set<String> get completedFeatures => Set.unmodifiable(_completedFeatures);
  bool get isInitialized => _isInitialized;

  String _getStorageKey(String? userId) => 'user_onboarded_features_${userId ?? "anonymous"}';

  /// Khởi tạo trạng thái cho tài khoản người dùng
  Future<void> initForUser(String? userId) async {
    _currentUserId = userId;
    _completedFeatures.clear();

    // 1. Tải trước từ Local Cache (Offline First)
    final cacheKey = _getStorageKey(userId);
    final cachedStr = StorageUtil.getString(cacheKey);
    if (cachedStr != null && cachedStr.isNotEmpty) {
      _completedFeatures.addAll(cachedStr.split(',').where((e) => e.isNotEmpty));
    }
    _isInitialized = true;
    notifyListeners();

    // 2. Nếu đã đăng nhập tài khoản thực, đồng bộ với Backend
    if (userId != null && userId != 'guest') {
      await fetchRemoteStatus();
    }
  }

  /// Tải trạng thái từ máy chủ
  Future<void> fetchRemoteStatus() async {
    if (_currentUserId == null || _currentUserId == 'guest') return;

    try {
      final response = await ApiClient.instance.get('/users/onboarding-status');
      if (response.statusCode == 200 && response.data is Map) {
        final List<dynamic> remoteList = response.data['completed_features'] ?? [];
        for (final item in remoteList) {
          _completedFeatures.add(item.toString());
        }
        await _saveToLocalCache();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[FeatureOnboardingService] Không thể tải trạng thái từ máy chủ (chế độ offline): $e');
    }
  }

  /// Kiểm tra xem tính năng này đã được xem/bỏ qua hướng dẫn chưa
  bool hasCompleted(String featureKey) {
    return _completedFeatures.contains(featureKey);
  }

  /// Đánh dấu đã hoàn thành hoặc bỏ qua hướng dẫn của một tính năng
  Future<void> markCompleted(String featureKey) async {
    if (_completedFeatures.contains(featureKey)) return;

    _completedFeatures.add(featureKey);
    await _saveToLocalCache();
    notifyListeners();

    // Đồng bộ lên server database
    if (_currentUserId != null && _currentUserId != 'guest') {
      try {
        await ApiClient.instance.post(
          '/users/onboarding-status',
          data: {'feature_key': featureKey, 'completed': true},
        );
      } on DioException catch (dioErr) {
        // Nếu lỗi mất mạng, đẩy vào hàng đợi sao lưu ngoại tuyến SyncService
        debugPrint('[FeatureOnboardingService] Mất mạng khi gửi trạng thái. Đẩy vào SyncQueue: $dioErr');
        await SyncService.instance.enqueueSync(
          type: 'onboarding_sync',
          payload: {'feature_key': featureKey, 'completed': true},
        );
      } catch (e) {
        debugPrint('[FeatureOnboardingService] Lỗi khi lưu trạng thái lên máy chủ: $e');
      }
    }
  }

  /// Đặt lại trạng thái của một tính năng (cho phép người dùng xem lại)
  Future<void> resetFeature(String featureKey) async {
    _completedFeatures.remove(featureKey);
    await _saveToLocalCache();
    notifyListeners();

    if (_currentUserId != null && _currentUserId != 'guest') {
      try {
        await ApiClient.instance.post(
          '/users/onboarding-status/reset',
          queryParameters: {'feature_key': featureKey},
        );
      } catch (_) {}
    }
  }

  /// Đặt lại toàn bộ trạng thái hướng dẫn (phục vụ test)
  Future<void> resetAll() async {
    _completedFeatures.clear();
    await _saveToLocalCache();
    notifyListeners();

    if (_currentUserId != null && _currentUserId != 'guest') {
      try {
        await ApiClient.instance.post('/users/onboarding-status/reset');
      } catch (_) {}
    }
  }

  Future<void> _saveToLocalCache() async {
    final cacheKey = _getStorageKey(_currentUserId);
    final joined = _completedFeatures.join(',');
    await StorageUtil.setString(cacheKey, joined);
  }
}
