import 'package:dio/dio.dart';
import '../utils/storage.dart';
import '../constants/app_constants.dart';

/// Dio HTTP Client với JWT Auto-refresh Interceptor.
///
/// Luồng xử lý 401:
///  1. Request đầu tiên thất bại với HTTP 401 (access token hết hạn).
///  2. Interceptor tự động gọi POST /auth/refresh với refresh_token.
///  3. Nếu refresh thành công → lưu access_token mới → retry request gốc.
///  4. Nếu refresh thất bại (refresh token hết hạn) → xóa tất cả token
///     → broadcast sự kiện để navigator đưa người dùng về màn Login.
class ApiClient {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Content-Type': 'application/json'},
  ));

  // Callback để trigger navigation tới LoginScreen từ ngoài context
  static void Function()? onUnauthorized;

  static void init() {
    _dio.options.baseUrl = AppConstants.apiBaseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        // ── Attach access token ────────────────────────────────────────────
        onRequest: (options, handler) async {
          // Luôn đảm bảo dùng đúng API URL (chuyển 127.0.0.1 sang IP LAN trên máy thật)
          if (options.baseUrl.isEmpty || options.baseUrl.contains('127.0.0.1')) {
            options.baseUrl = AppConstants.apiBaseUrl;
          }
          final token = await StorageUtil.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },

        onResponse: (response, handler) => handler.next(response),

        // ── Auto-fallback host on connection error & Auto-refresh on 401 ────
        onError: (DioException e, handler) async {
          // 1. Tự động thử các host dự phòng (LAN IP, 127.0.0.1, 10.0.2.2) nếu lỗi kết nối hoặc timeout
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.message?.contains('Connection refused') == true ||
              e.message?.contains('took longer') == true) {
            final candidates = [
              'http://192.168.43.25:8000',
              'http://127.0.0.1:8000',
              'http://10.0.2.2:8000',
            ];
            final currentBase = e.requestOptions.baseUrl.isNotEmpty 
                ? e.requestOptions.baseUrl 
                : _dio.options.baseUrl;
            final remaining = candidates.where((c) => c != currentBase).toList();

            if (!e.requestOptions.extra.containsKey('retried_alt_host')) {
              for (final altBase in remaining) {
                _dio.options.baseUrl = altBase;
                final retryOpts = e.requestOptions;
                retryOpts.extra['retried_alt_host'] = true;
                retryOpts.baseUrl = altBase;
                retryOpts.connectTimeout = const Duration(seconds: 4);
                if (retryOpts.path.startsWith('http')) {
                  retryOpts.path = retryOpts.path.replaceAll(currentBase, altBase);
                }
                try {
                  final retryResp = await _dio.fetch(retryOpts);
                  return handler.resolve(retryResp);
                } catch (_) {}
              }
            }
          }

          if (e.response?.statusCode != 401) {
            return handler.next(e);
          }

          // Tránh vòng lặp vô hạn: không retry chính endpoint /auth/refresh
          final path = e.requestOptions.path;
          if (path.contains('/auth/refresh') || path.contains('/auth/login')) {
            await StorageUtil.clearAllTokens();
            onUnauthorized?.call();
            return handler.next(e);
          }

          // Thử dùng refresh token lấy access token mới
          final refreshToken = await StorageUtil.getRefreshToken();
          if (refreshToken == null) {
            await StorageUtil.clearAllTokens();
            onUnauthorized?.call();
            return handler.next(e);
          }

          try {
            final refreshResp = await _dio.post(
              '/auth/refresh',
              data: {'refresh_token': refreshToken},
              options: Options(headers: {}), // không attach cũ token
            );

            final newAccessToken = refreshResp.data['access_token'] as String;
            await StorageUtil.saveToken(newAccessToken);

            // Retry request gốc với token mới
            final retryOpts = e.requestOptions;
            retryOpts.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResp = await _dio.fetch(retryOpts);
            return handler.resolve(retryResp);
          } catch (_) {
            // Refresh thất bại → bắt buộc đăng nhập lại
            await StorageUtil.clearAllTokens();
            onUnauthorized?.call();
            return handler.next(e);
          }
        },
      ),
    );
  }

  static Dio get instance {
    _dio.options.baseUrl = AppConstants.apiBaseUrl;
    return _dio;
  }
}