import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Default base URL depending on platform:
  // Android Emulator uses 10.0.2.2 to access host machine
  // Windows / Web / iOS uses localhost
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'http://localhost:8000';
  }

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
