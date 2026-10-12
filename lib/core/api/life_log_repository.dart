import 'api_client.dart';

/// Repository cho Life Log APIs — nhật ký sinh hoạt, giờ ngủ, stress
class LifeLogRepository {
  static Future<Map<String, dynamic>> createLifeLog({
    required int stressLevel,
    required double sleepHours,
    String? shiftType,
    List<String>? physicalSymptoms,
    String? moodNote,
    List<String>? activitiesDone,
    int? waterIntakeMl,
  }) async {
    final response = await ApiClient.instance.post('/life-logs', data: {
      'stress_level': stressLevel,
      'sleep_hours': sleepHours,
      if (shiftType != null) 'shift_type': shiftType,
      'physical_symptoms': physicalSymptoms ?? [],
      if (moodNote != null) 'mood_note': moodNote,
      'activities_done': activitiesDone ?? [],
      if (waterIntakeMl != null) 'water_intake_ml': waterIntakeMl,
    });
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getTodayLifeLog() async {
    final response = await ApiClient.instance.get('/life-logs/today');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getHistory({int days = 14}) async {
    final response =
        await ApiClient.instance.get('/life-logs/history', queryParameters: {'days': days});
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAnalytics({int days = 7}) async {
    final response =
        await ApiClient.instance.get('/life-logs/analytics', queryParameters: {'days': days});
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await ApiClient.instance.get('/life-logs/dashboard');
    return response.data as Map<String, dynamic>;
  }
}

/// Repository cho Checkin APIs — điểm danh + gacha
class CheckinRepository {
  static Future<Map<String, dynamic>> performCheckin({
    required String mood,
    List<String>? stressFactors,
    String? note,
  }) async {
    final response = await ApiClient.instance.post('/checkins', data: {
      'mood': mood,
      'stress_factors': stressFactors ?? [],
      if (note != null) 'note': note,
    });
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getTodayStatus() async {
    final response = await ApiClient.instance.get('/checkins/today');
    return response.data as Map<String, dynamic>;
  }
}
