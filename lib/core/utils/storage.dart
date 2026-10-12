import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageUtil {
  static late SharedPreferences _prefs;
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Generic Preferences
  static Future<bool> setString(String key, String value) async => await _prefs.setString(key, value);
  static String? getString(String key) => _prefs.getString(key);

  static Future<bool> setBool(String key, bool value) async => await _prefs.setBool(key, value);
  static bool? getBool(String key) => _prefs.getBool(key);

  static Future<bool> remove(String key) async => await _prefs.remove(key);
  static Future<bool> clear() async => await _prefs.clear();

  // ── Secure Token Storage ──────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'access_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  static Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'access_token');
  }

  static Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: 'refresh_token', value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  static Future<void> deleteRefreshToken() async {
    await _secureStorage.delete(key: 'refresh_token');
  }

  /// Clear cả access + refresh token khi logout
  static Future<void> clearAllTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  // ── Biometric & Remember Login Helpers ─────────────────────────────────────
  static bool get isBiometricEnabled => _prefs.getBool('biometric_enabled') ?? false;
  static Future<void> setBiometricEnabled(bool value) async =>
      await _prefs.setBool('biometric_enabled', value);

  static Future<void> saveBiometricCredentials(String email, String password) async {
    await _secureStorage.write(key: 'bio_email', value: email);
    await _secureStorage.write(key: 'bio_password', value: password);
  }

  static Future<Map<String, String>?> getBiometricCredentials() async {
    final email = await _secureStorage.read(key: 'bio_email');
    final password = await _secureStorage.read(key: 'bio_password');
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  static Future<void> clearBiometricCredentials() async {
    await _secureStorage.delete(key: 'bio_email');
    await _secureStorage.delete(key: 'bio_password');
  }

  // App specific helpers
  static bool get hasSeenOnboarding => _prefs.getBool('has_seen_onboarding') ?? false;
  static Future<void> setHasSeenOnboarding(bool value) async =>
      await _prefs.setBool('has_seen_onboarding', value);

  // ── Remember Login Credentials (Secure) ────────────────────────────────────
  /// Lưu email + password vào secure storage cho tính năng "Ghi nhớ đăng nhập"
  static Future<void> saveRememberCredentials(String email, String password) async {
    await _secureStorage.write(key: 'remember_email', value: email);
    await _secureStorage.write(key: 'remember_password', value: password);
  }

  /// Đọc credentials đã lưu cho tính năng "Ghi nhớ đăng nhập"
  static Future<Map<String, String>?> getRememberCredentials() async {
    final email = await _secureStorage.read(key: 'remember_email');
    final password = await _secureStorage.read(key: 'remember_password');
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  /// Xóa credentials khi user tắt "Ghi nhớ đăng nhập" hoặc logout
  static Future<void> clearRememberCredentials() async {
    await _secureStorage.delete(key: 'remember_email');
    await _secureStorage.delete(key: 'remember_password');
  }

  // ── Cached User Profile (Instant UI Startup) ──────────────────────────────
  static const String _cachedUserKey = 'cached_user_json';

  static Future<void> saveCachedUser(Map<String, dynamic> userJson) async {
    await _prefs.setString(_cachedUserKey, jsonEncode(userJson));
  }

  static Map<String, dynamic>? getCachedUser() {
    final raw = _prefs.getString(_cachedUserKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  static Future<void> clearCachedUser() async {
    await _prefs.remove(_cachedUserKey);
  }
}
