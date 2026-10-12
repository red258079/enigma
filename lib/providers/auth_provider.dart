import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  final ApiClient _api = ApiClient();

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = StorageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        // Try fetching user profile from server
        try {
          final res = await _api.dio.get(ApiConstants.me);
          if (res.statusCode == 200) {
            _currentUser = UserModel.fromJson(res.data);
            await StorageService.setUserData(jsonEncode(_currentUser!.toJson()));
          }
        } catch (_) {
          // If offline, try reading cached user data
          final cached = StorageService.getUserData();
          if (cached != null) {
            _currentUser = UserModel.fromJson(jsonDecode(cached));
          }
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.dio.post(
        ApiConstants.login,
        data: {'email': email.trim(), 'password': password},
      );

      if (res.statusCode == 200) {
        final accessToken = res.data['access_token'];
        final refreshToken = res.data['refresh_token'];
        final userData = res.data['user'];

        await StorageService.setTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        _currentUser = UserModel.fromJson(userData);
        await StorageService.setUserData(jsonEncode(_currentUser!.toJson()));
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Đăng nhập không thành công. Vui lòng kiểm tra lại email/mật khẩu hoặc kết nối server.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String? studentId,
    String? university,
    String? major,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.dio.post(
        ApiConstants.register,
        data: {
          'full_name': fullName.trim(),
          'email': email.trim(),
          'password': password,
          'student_id': studentId?.trim(),
          'university': university?.trim(),
          'major': major?.trim(),
        },
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final accessToken = res.data['access_token'];
        final refreshToken = res.data['refresh_token'];
        final userData = res.data['user'];

        await StorageService.setTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        _currentUser = UserModel.fromJson(userData);
        await StorageService.setUserData(jsonEncode(_currentUser!.toJson()));
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Đăng ký thất bại. Email có thể đã tồn tại hoặc server không phản hồi.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// One-tap demo login for rapid testing & evaluation
  Future<void> demoLogin() async {
    _isLoading = true;
    notifyListeners();

    // First try standard test account against backend
    final success = await login('student@enigma.edu.vn', '123456');
    if (!success) {
      // Fallback to local demo profile if backend not seeded yet
      _currentUser = UserModel(
        id: 'demo-student-uuid-2026',
        email: 'sinhvien@enigma.edu.vn',
        fullName: 'Nguyễn Văn An',
        role: 'student',
        studentId: 'SV2026001',
        university: 'Đại học Bách Khoa',
        major: 'Kỹ thuật Điện tử',
        companyName: 'LG Display Hải Phòng',
        currentPhase: 'adaptation',
      );
      await StorageService.setUserData(jsonEncode(_currentUser!.toJson()));
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      final refresh = StorageService.getRefreshToken();
      if (refresh != null) {
        await _api.dio.post(ApiConstants.logout, data: {'refresh_token': refresh});
      }
    } catch (_) {}

    await StorageService.clearTokens();
    _currentUser = null;
    notifyListeners();
  }
}
