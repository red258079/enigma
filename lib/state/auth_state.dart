import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../core/utils/storage.dart';
import '../core/constants/app_constants.dart';
import '../core/api/api_client.dart';
import 'package:dio/dio.dart';

class AuthState extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: AppConstants.googleServerClientId,
  );

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isGuest => _user?.isGuest ?? false;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Guest Mode / Bỏ qua đăng nhập ─────────────────────────────────────────
  void continueAsGuest() {
    _user = User(
      id: 'guest',
      email: 'khach@enigma.vn',
      name: 'Khách',
      role: 'student',
      studentId: 'Khách trải nghiệm',
    );
    _error = null;
    notifyListeners();
  }

  // ── Startup: check stored token ──────────────────────────────────────────
  Future<void> checkAuth() async {
    // 1. Phục hồi ngay user từ cache (0ms delay) để giao diện hiển thị ngay lập tức
    final cached = StorageUtil.getCachedUser();
    if (cached != null) {
      _user = User.fromJson(cached);
      notifyListeners();
    }

    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageUtil.getToken();
      if (token != null) {
        if (AppConstants.useMockApi) {
          await Future.delayed(const Duration(milliseconds: 300));
          _user = User(
            id: 'u1',
            email: 'student@example.com',
            name: 'Nguyễn Văn A',
            role: 'student',
            studentId: 'SV123456',
          );
        } else {
          final response = await ApiClient.instance.get('/auth/me');
          _user = User.fromJson(response.data);
          await StorageUtil.saveCachedUser(_user!.toJson());
        }
      }

      // Nếu không có token hoặc token hết hạn, thử tự động đăng nhập
      // bằng credentials đã lưu từ "Ghi nhớ đăng nhập"
      if (_user == null) {
        await _tryAutoLogin();
      }
    } catch (e) {
      if (_user == null) {
        await StorageUtil.clearAllTokens();
        await StorageUtil.clearCachedUser();
        // Token lỗi/hết hạn → thử tự động đăng nhập lại
        await _tryAutoLogin();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tự động đăng nhập lại bằng credentials đã lưu (tính năng "Ghi nhớ đăng nhập")
  Future<void> _tryAutoLogin() async {
    try {
      final credentials = await StorageUtil.getRememberCredentials();
      if (credentials != null) {
        final email = credentials['email']!;
        final password = credentials['password']!;

        if (AppConstants.useMockApi) {
          await Future.delayed(const Duration(seconds: 1));
          if (email == 'admin@enigma.com') {
            _user = User(id: 'a1', email: email, name: 'Admin', role: 'admin');
          } else {
            _user = User(id: 'u1', email: email, name: 'Nguyễn Văn A', role: 'student', studentId: 'SV123456');
          }
          await StorageUtil.saveToken('mock_access_token_123');
          await StorageUtil.saveRefreshToken('mock_refresh_token_123');
        } else {
          final response = await ApiClient.instance.post('/auth/login', data: {
            'email': email,
            'password': password,
          });

          await StorageUtil.saveToken(response.data['access_token']);
          await StorageUtil.saveRefreshToken(response.data['refresh_token']);
          _user = User.fromJson(response.data['user']);
          await StorageUtil.saveCachedUser(_user!.toJson());
        }
      }
    } catch (e) {
      // Auto-login thất bại (sai mật khẩu, server lỗi...) → xóa credentials cũ
      debugPrint('Auto-login failed: $e');
      await StorageUtil.clearRememberCredentials();
      await StorageUtil.clearCachedUser();
      _user = null;
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (AppConstants.useMockApi) {
        await Future.delayed(const Duration(seconds: 2));
        if (email == 'admin@enigma.com') {
          _user = User(id: 'a1', email: email, name: 'Admin', role: 'admin');
        } else {
          _user = User(id: 'u1', email: email, name: 'Nguyễn Văn A', role: 'student', studentId: 'SV123456');
        }
        await StorageUtil.saveToken('mock_access_token_123');
        await StorageUtil.saveRefreshToken('mock_refresh_token_123');
      } else {
        final response = await ApiClient.instance.post('/auth/login', data: {
          'email': email,
          'password': password,
        });

        await StorageUtil.saveToken(response.data['access_token']);
        await StorageUtil.saveRefreshToken(response.data['refresh_token']);
        _user = User.fromJson(response.data['user']);
        await StorageUtil.saveCachedUser(_user!.toJson());
      }
      return true;
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
        final detail = e.response?.data['detail'];
        _error = detail is List ? detail.map((d) => d['msg']).join('\n') : detail.toString();
      } else {
        _error = 'Đăng nhập thất bại. Vui lòng kiểm tra lại email/mật khẩu.';
      }
      return false;
    } catch (e, stack) {
      debugPrint('Login exception: $e\n$stack');
      _error = 'Đã có lỗi xảy ra: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Google Sign-In (Login / Auto-Register) ──────────────────────────────────
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (AppConstants.useMockApi) {
        await Future.delayed(const Duration(seconds: 2));
        _user = User(
          id: 'u_gg_mock',
          email: 'google_student@gmail.com',
          name: 'Google Student',
          role: 'student',
          studentId: 'SV999888',
        );
        await StorageUtil.saveToken('mock_google_access_token');
        await StorageUtil.saveRefreshToken('mock_google_refresh_token');
        return true;
      }

      // Đăng xuất phiên cũ nếu có để cho phép user chọn tài khoản
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        // Người dùng tự đóng popup đăng nhập
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleAccount.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception("Không nhận được idToken từ Google. Vui lòng thử lại.");
      }

      final response = await ApiClient.instance.post('/auth/google', data: {
        'id_token': idToken,
      });

      await StorageUtil.saveToken(response.data['access_token']);
      await StorageUtil.saveRefreshToken(response.data['refresh_token']);
      _user = User.fromJson(response.data['user']);
      await StorageUtil.saveCachedUser(_user!.toJson());
      return true;
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
        final detail = e.response?.data['detail'];
        _error = detail is List ? detail.map((d) => d['msg']).join('\n') : detail.toString();
      } else if (e.type == DioExceptionType.connectionError) {
        _error = 'Không thể kết nối tới server backend.';
      } else {
        _error = 'Đăng nhập Google thất bại: ${e.message}';
      }
      return false;
    } catch (e, stack) {
      debugPrint('Google Sign-In exception: $e\n$stack');
      _error = 'Lỗi đăng nhập Google: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<bool> register(
    String name,
    String studentId,
    String email,
    String password, {
    String? university,
    String? major,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (AppConstants.useMockApi) {
        await Future.delayed(const Duration(seconds: 2));
        _user = User(id: 'u2', email: email, name: name, role: 'student', studentId: studentId);
        await StorageUtil.saveToken('mock_access_token_456');
        await StorageUtil.saveRefreshToken('mock_refresh_token_456');
      } else {
        final response = await ApiClient.instance.post('/auth/register', data: {
          'full_name':  name,
          'email':      email,
          'password':   password,
          'student_id': studentId.isEmpty ? null : studentId,
          'university': university,
          'major':      major,
        });

        await StorageUtil.saveToken(response.data['access_token']);
        await StorageUtil.saveRefreshToken(response.data['refresh_token']);
        _user = User.fromJson(response.data['user']);
        await StorageUtil.saveCachedUser(_user!.toJson());
      }
      return true;
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
        final detail = e.response?.data['detail'];
        _error = detail is List ? detail.map((d) => d['msg']).join('\n') : detail.toString();
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        _error = 'Hết thời gian kết nối máy chủ. Vui lòng thử lại.';
      } else if (e.type == DioExceptionType.connectionError) {
        _error = 'Không thể kết nối tới máy chủ backend. Vui lòng kiểm tra server.';
      } else {
        _error = e.message ?? 'Đăng ký thất bại. Vui lòng thử lại.';
      }
      return false;
    } catch (e, stack) {
      debugPrint('Register exception: $e\n$stack');
      _error = 'Đã có lỗi xảy ra: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    final refreshToken = await StorageUtil.getRefreshToken();
    // Gọi API logout để thu hồi refresh token (best-effort, ignore lỗi)
    if (!AppConstants.useMockApi && refreshToken != null) {
      try {
        await ApiClient.instance.post('/auth/logout', data: {'refresh_token': refreshToken});
      } catch (_) {}
    }
    await StorageUtil.clearAllTokens();
    await StorageUtil.clearCachedUser();
    _user = null;
    notifyListeners();
  }

  /// Gọi khi Dio interceptor phát hiện cả refresh token hết hạn
  void forceLogout() {
    StorageUtil.clearCachedUser();
    _user = null;
    notifyListeners();
  }

  // ── Forgot Password ───────────────────────────────────────────────────────
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (AppConstants.useMockApi) {
        await Future.delayed(const Duration(seconds: 1));
        return true; // Mock: luôn thành công
      }
      await ApiClient.instance.post('/auth/forgot-password', data: {'email': email});
      return true;
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
        _error = e.response?.data['detail'].toString();
      } else {
        _error = 'Không thể gửi mã xác nhận. Vui lòng thử lại.';
      }
      return false;
    } catch (e) {
      _error = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Reset Password ────────────────────────────────────────────────────────
  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (AppConstants.useMockApi) {
        await Future.delayed(const Duration(seconds: 1));
        if (otp == '123456') return true; // Mock: OTP test
        _error = 'Mã xác nhận không đúng.';
        return false;
      }
      await ApiClient.instance.post('/auth/reset-password', data: {
        'email':        email,
        'otp':          otp,
        'new_password': newPassword,
      });
      return true;
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
        _error = e.response?.data['detail'].toString();
      } else {
        _error = 'Mã xác nhận không đúng hoặc đã hết hạn.';
      }
      return false;
    } catch (e) {
      _error = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Refresh Profile from Server ──────────────────────────────────────────
  Future<void> refreshProfile() async {
    if (_user == null || _user!.isGuest) return;
    try {
      if (!AppConstants.useMockApi) {
        final response = await ApiClient.instance.get('/users/me');
        _user = User.fromJson(response.data);
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Update Profile ───────────────────────────────────────────────────────
  Future<bool> updateProfile({
    required String name,
    String? studentId,
    String? university,
    String? major,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (AppConstants.useMockApi || isGuest) {
        await Future.delayed(const Duration(milliseconds: 600));
        _user = _user?.copyWith(
          name: name,
          studentId: studentId,
          university: university,
          major: major,
          avatarUrl: avatarUrl ?? _user?.avatarUrl,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final Map<String, dynamic> data = {
        'full_name': name.trim(),
        'student_id': studentId?.trim(),
        'university': university?.trim(),
        'major': major?.trim(),
      };
      if (avatarUrl != null) {
        data['avatar_url'] = avatarUrl;
      }

      // Cập nhật ngay trên giao diện (Optimistic UI) để người dùng không phải chờ
      if (_user != null) {
        _user = _user!.copyWith(
          name: name,
          studentId: studentId,
          university: university,
          major: major,
          avatarUrl: avatarUrl ?? _user?.avatarUrl,
        );
        await StorageUtil.saveCachedUser(_user!.toJson());
        notifyListeners();
      }

      final response = await ApiClient.instance.put('/users/me', data: data);

      _user = User.fromJson(response.data);
      await StorageUtil.saveCachedUser(_user!.toJson());
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
        _error = e.response?.data['detail'].toString();
      } else {
        _error = 'Không thể cập nhật thông tin. Vui lòng kiểm tra lại.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Lỗi cập nhật: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Change Password ───────────────────────────────────────────────────────
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (AppConstants.useMockApi || isGuest) {
        await Future.delayed(const Duration(milliseconds: 600));
        _isLoading = false;
        notifyListeners();
        return true;
      }

      await ApiClient.instance.post('/users/change-password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
        _error = e.response?.data['detail'].toString();
      } else {
        _error = 'Đổi mật khẩu thất bại. Vui lòng kiểm tra lại mật khẩu cũ.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Đã có lỗi xảy ra: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

