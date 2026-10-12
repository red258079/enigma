class AppConstants {
  static const bool useMockApi = false; // Set to false to use real FastAPI backend + PostgreSQL
  
  // Real backend URL (qua ADB reverse port forwarding, hoạt động 100% không lo lỗi mạng/Firewall)
  static const String apiBaseUrl = 'http://127.0.0.1:8000'; 

  // Keys
  static const String tokenKey = 'jwt_token';
  static const String onboardedKey = 'has_seen_onboarding';

  // Google OAuth
  static const String googleServerClientId = '1028134720370-g39rh2ojgtdkl3646cc0uacjaq9k31mr.apps.googleusercontent.com';
}
