class ApiConstants {
  // Cloud Backend URL (Render 24/7)
  static String get defaultBaseUrl => 'https://mentality-38jh.onrender.com';

  // Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  static const String checkinToday = '/checkins/today';
  static const String checkinPerform = '/checkins';

  static const String journalCreate = '/journals';
  static const String journalHistory = '/journals/history';

  static const String tasks = '/tasks';
  static String taskToggle(String taskId) => '/tasks/$taskId/toggle';

  static const String chatSessions = '/chat/sessions';
  static String chatMessages(String sessionId) => '/chat/sessions/$sessionId/messages';
}
