class AppConstants {
  static const bool useMockApi = false; // Set to false to use real FastAPI backend + PostgreSQL
  
  // Real backend URL (IP máy tính trong mạng Wi-Fi để điện thoại thật kết nối trực tiếp)
  static const String apiBaseUrl = 'http://192.168.43.25:8000'; 

  // Keys
  static const String tokenKey = 'jwt_token';
  static const String onboardedKey = 'has_seen_onboarding';

  // Google OAuth
  static const String googleServerClientId = '36729513984-esqq4r98jnm3utb4grbj6gu6if5l6cqi.apps.googleusercontent.com';
}
