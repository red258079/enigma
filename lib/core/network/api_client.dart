import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../services/storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: getBaseUrl(),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.baseUrl = getBaseUrl();
          final token = StorageService.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // If unauthorized and we have a refresh token, attempt refresh
          if (error.response?.statusCode == 401) {
            final refreshToken = StorageService.getRefreshToken();
            if (refreshToken != null && !error.requestOptions.path.contains('/auth/')) {
              try {
                final refreshResponse = await Dio(
                  BaseOptions(baseUrl: getBaseUrl()),
                ).post(
                  ApiConstants.refresh,
                  data: {'refresh_token': refreshToken},
                );

                if (refreshResponse.statusCode == 200) {
                  final newAccessToken = refreshResponse.data['access_token'];
                  await StorageService.setTokens(
                    accessToken: newAccessToken,
                    refreshToken: refreshToken,
                  );

                  // Retry original request with new token
                  final opts = error.requestOptions;
                  opts.headers['Authorization'] = 'Bearer $newAccessToken';
                  final cloneReq = await dio.fetch(opts);
                  return handler.resolve(cloneReq);
                }
              } catch (_) {
                await StorageService.clearTokens();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  String getBaseUrl() {
    return StorageService.getCustomBaseUrl() ?? ApiConstants.defaultBaseUrl;
  }

  void updateBaseUrl(String newUrl) {
    dio.options.baseUrl = newUrl;
  }
}
