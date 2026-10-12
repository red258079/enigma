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
    _dio.interceptors.add(
      InterceptorsWrapper(
        // ── Attach access token ────────────────────────────────────────────
        onRequest: (options, handler) async {
          final token = await StorageUtil.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },

        onResponse: (response, handler) => handler.next(response),

        // ── Auto-fallback host on connection error & Auto-refresh on 401 ────
        onError: (DioException e, handler) async {
          // 1. Tự động chuyển đổi giữa 127.0.0.1 và 10.0.2.2 nếu lỗi kết nối trên Android Emulator
          if (e.type == DioExceptionType.connectionError ||
              e.message?.contains('Connection refused') == true) {
            final currentBase = _dio.options.baseUrl;
            final altBase = currentBase.contains('127.0.0.1')
                ? currentBase.replaceAll('127.0.0.1', '10.0.2.2')
                : currentBase.replaceAll('10.0.2.2', '127.0.0.1');

            if (currentBase != altBase && !e.requestOptions.extra.containsKey('retried_alt_host')) {
              _dio.options.baseUrl = altBase;
              final retryOpts = e.requestOptions;
              retryOpts.extra['retried_alt_host'] = true;
              retryOpts.path = retryOpts.path.replaceAll(currentBase, altBase);
              try {
                final retryResp = await _dio.fetch(retryOpts);
                return handler.resolve(retryResp);
              } catch (_) {}
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

  static Dio get instance => _dio;
}
