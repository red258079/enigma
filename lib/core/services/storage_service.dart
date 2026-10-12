import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyAccessToken = 'enigma_access_token';
  static const String _keyRefreshToken = 'enigma_refresh_token';
  static const String _keyUserData = 'enigma_user_data';
  static const String _keyBaseUrl = 'enigma_custom_base_url';
  static const String _keyOnboardingDone = 'enigma_onboarding_done';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> setTokens({required String accessToken, required String refreshToken}) async {
    await _prefs?.setString(_keyAccessToken, accessToken);
    await _prefs?.setString(_keyRefreshToken, refreshToken);
  }

  static String? getAccessToken() => _prefs?.getString(_keyAccessToken);
  static String? getRefreshToken() => _prefs?.getString(_keyRefreshToken);

  static Future<void> clearTokens() async {
    await _prefs?.remove(_keyAccessToken);
    await _prefs?.remove(_keyRefreshToken);
    await _prefs?.remove(_keyUserData);
  }

  static Future<void> setUserData(String jsonString) async {
    await _prefs?.setString(_keyUserData, jsonString);
  }

  static String? getUserData() => _prefs?.getString(_keyUserData);

  static Future<void> setCustomBaseUrl(String url) async {
    await _prefs?.setString(_keyBaseUrl, url);
  }

  static String? getCustomBaseUrl() => _prefs?.getString(_keyBaseUrl);

  static Future<void> setOnboardingCompleted() async {
    await _prefs?.setBool(_keyOnboardingDone, true);
  }

  static bool isOnboardingCompleted() => _prefs?.getBool(_keyOnboardingDone) ?? false;
}
