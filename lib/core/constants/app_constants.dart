class AppConstants {
  static const bool useMockApi = false; // Set to false to use real FastAPI backend + PostgreSQL
  
  // Cloud Backend URL (Render 24/7)
  static const String apiBaseUrl = 'https://mentality-38jh.onrender.com'; 

  // Keys
  static const String tokenKey = 'jwt_token';
  static const String onboardedKey = 'has_seen_onboarding';

  // Google OAuth
  static const String googleServerClientId = '36729513984-esqq4r98jnm3utb4grbj6gu6if5l6cqi.apps.googleusercontent.com';
}
