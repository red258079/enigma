import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import '../utils/storage.dart';
import '../services/sync_service.dart';

/// Repository cho Life Log APIs — nhật ký sinh hoạt, giờ ngủ, stress
/// Tích hợp cơ chế Offline-First: tự động lưu local và sao lưu lên server khi có mạng.
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
    final payload = {
      'stress_level': stressLevel,
      'sleep_hours': sleepHours,
      if (shiftType != null) 'shift_type': shiftType,
      'physical_symptoms': physicalSymptoms ?? [],
      if (moodNote != null) 'mood_note': moodNote,
      'activities_done': activitiesDone ?? [],
      if (waterIntakeMl != null) 'water_intake_ml': waterIntakeMl,
    };

    try {
      final response = await ApiClient.instance.post(
        '/life-logs',
        data: payload,
      );
      final resData = response.data as Map<String, dynamic>;

      // Lưu cache ngày hôm nay
      await StorageUtil.saveCachedTodayLifeLog({
        'has_log_today': true,
        'data': {
          ...payload,
          'wellbeing_score': resData['wellbeing_score'] ?? 80,
          'date': DateTime.now().toIso8601String(),
        },
      });

      return resData;
    } on DioException catch (e) {
      final isNetworkError =
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.unknown;

      if (isNetworkError) {
        debugPrint(
          '[LifeLogRepository] Mất mạng: Lưu nhật ký vào bộ nhớ máy và đưa vào SyncQueue.',
        );

        // Tính điểm sức khỏe ước tính offline
        int score =
            100 -
            (stressLevel - 1) * 12 -
            ((physicalSymptoms?.length ?? 0) * 5);
        if (sleepHours >= 7 && sleepHours <= 9) score += 5;
        score = score.clamp(30, 100);

        final localData = {
          'has_log_today': true,
          'data': {
            ...payload,
            'wellbeing_score': score,
            'date': DateTime.now().toIso8601String(),
          },
        };

        // Lưu local cache
        await StorageUtil.saveCachedTodayLifeLog(localData);

        // Cập nhật lại cached dashboard để Home Screen hiển thị điểm mới
        final cachedDash = StorageUtil.getCachedDashboard();
        if (cachedDash != null) {
          final today = Map<String, dynamic>.from(
            cachedDash['today'] as Map? ?? {},
          );
          today['wellbeing_score'] = score;
          today['stress_level'] = stressLevel;
          today['sleep_hours'] = sleepHours;
          cachedDash['today'] = today;
          await StorageUtil.saveCachedDashboard(cachedDash);
        }

        // Đưa vào hàng đợi sao lưu
        await SyncService.instance.enqueueSync(
          type: 'life_log',
          payload: payload,
        );

        return {
          'status': 'success',
          'wellbeing_score': score,
          'message': 'Đã lưu nhật ký ngoại tuyến. Sẽ tự động sao lưu lên máy chủ khi có mạng.',
          'is_offline': true,
        };
      }
      rethrow;
    } catch (e) {
      debugPrint('[LifeLogRepository] Lỗi: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getTodayLifeLog() async {
    try {
      final response = await ApiClient.instance.get('/life-logs/today');
      final data = response.data as Map<String, dynamic>;
      await StorageUtil.saveCachedTodayLifeLog(data);
      return data;
    } catch (_) {
      // Khi mất mạng, trả về dữ liệu đã lưu trong máy
      final cached = StorageUtil.getCachedTodayLifeLog();
      if (cached != null) {
        return cached;
      }
      return {'has_log_today': false, 'data': null};
    }
  }

  static Future<Map<String, dynamic>> getHistory({int days = 14}) async {
    try {
      final response = await ApiClient.instance.get(
        '/life-logs/history',
        queryParameters: {'days': days},
      );
      return response.data as Map<String, dynamic>;
    } catch (_) {
      // Khi mất mạng, trả về lịch sử nếu có trong cache
      final cachedToday = StorageUtil.getCachedTodayLifeLog();
      if (cachedToday != null && cachedToday['data'] != null) {
        return {
          'entries': [cachedToday['data']],
        };
      }
      return {'entries': []};
    }
  }

  static Future<Map<String, dynamic>> getAnalytics({int days = 7}) async {
    try {
      final response = await ApiClient.instance.get(
        '/life-logs/analytics',
        queryParameters: {'days': days},
      );
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return {
        'overall_risk_level': 'GREEN',
        'average_stress': 2.5,
        'average_sleep': 7.0,
      };
    }
  }

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final response = await ApiClient.instance.get('/life-logs/dashboard');
      final data = response.data as Map<String, dynamic>;
      await StorageUtil.saveCachedDashboard(data);
      return data;
    } catch (_) {
      // Khi mất mạng, đọc từ cache và hợp nhất với dữ liệu hôm nay
      final cached = StorageUtil.getCachedDashboard();
      if (cached != null) {
        final todayLog = StorageUtil.getCachedTodayLifeLog();
        final todayCheckin = StorageUtil.getCachedTodayCheckin();

        final today = Map<String, dynamic>.from(cached['today'] as Map? ?? {});
        if (todayLog != null && todayLog['data'] != null) {
          final logData = todayLog['data'] as Map<String, dynamic>;
          today['wellbeing_score'] = logData['wellbeing_score'];
          today['stress_level'] = logData['stress_level'];
          today['sleep_hours'] = logData['sleep_hours'];
        }
        if (todayCheckin != null && todayCheckin['has_checked_in'] == true) {
          today['has_checked_in'] = true;
        }
        cached['today'] = today;
        return cached;
      }

      // Default offline summary
      return {
        'today': {
          'wellbeing_score': 85,
          'sleep_hours': 7.5,
          'stress_level': 2,
          'has_checked_in':
              StorageUtil.getCachedTodayCheckin()?['has_checked_in'] ?? false,
        },
        'streak': {'current_streak': 3, 'longest_streak': 5},
        'weekly_analytics': {'overall_risk_level': 'GREEN'},
      };
    }
  }
}

/// Repository cho Checkin APIs — điểm danh + gacha
/// Hỗ trợ hoàn toàn ngoại tuyến và tự động sao lưu.
class CheckinRepository {
  static Future<Map<String, dynamic>> performCheckin({
    required String mood,
    List<String>? stressFactors,
    String? note,
  }) async {
    final payload = {
      'mood': mood,
      'stress_factors': stressFactors ?? [],
      if (note != null) 'note': note,
    };

    try {
      final response = await ApiClient.instance.post(
        '/checkins',
        data: payload,
      );
      final resData = response.data as Map<String, dynamic>;

      await StorageUtil.saveCachedTodayCheckin({
        'has_checked_in': true,
        'mood': resData['mood'] ?? mood,
        'stress_factors': resData['stress_factors'] ?? stressFactors ?? [],
        'note': resData['note'] ?? note ?? '',
        'gacha_message': resData['gacha_message'],
        'current_streak': resData['current_streak'],
        'longest_streak': resData['longest_streak'],
        'date': DateTime.now().toIso8601String(),
      });

      return resData;
    } on DioException catch (e) {
      final isNetworkError =
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.unknown;

      if (isNetworkError) {
        debugPrint(
          '[CheckinRepository] Mất mạng: Điểm danh lưu local và đưa vào SyncQueue.',
        );

        const gachaMessages = [
          '⭐ Hôm nay bạn đã làm rất tốt! Hãy tiếp tục vững bước nhé.',
          '🌿 Hít một hơi thật sâu, ngày mai sẽ là một khởi đầu tuyệt vời mới.',
          '✨ Bạn mạnh mẽ hơn bạn nghĩ. Đừng quên chăm sóc bản thân nhé!',
          '🌻 Hãy tự thưởng cho mình một tách trà ấm và nghỉ ngơi đủ giấc hôm nay.',
        ];
        final randomMsg =
            gachaMessages[DateTime.now().second % gachaMessages.length];

        final cachedCheckin = StorageUtil.getCachedTodayCheckin();
        final currentStreak =
            ((cachedCheckin?['current_streak'] as num?)?.toInt() ?? 2) + 1;

        await StorageUtil.saveCachedTodayCheckin({
          'has_checked_in': true,
          'mood': mood,
          'stress_factors': stressFactors ?? [],
          'note': note ?? '',
          'gacha_message': randomMsg,
          'current_streak': currentStreak,
          'longest_streak': currentStreak,
          'date': DateTime.now().toIso8601String(),
        });

        // Cập nhật cached dashboard
        final cachedDash = StorageUtil.getCachedDashboard();
        if (cachedDash != null) {
          final today = Map<String, dynamic>.from(
            cachedDash['today'] as Map? ?? {},
          );
          today['has_checked_in'] = true;
          cachedDash['today'] = today;
          final streak = Map<String, dynamic>.from(
            cachedDash['streak'] as Map? ?? {},
          );
          streak['current_streak'] = currentStreak;
          cachedDash['streak'] = streak;
          await StorageUtil.saveCachedDashboard(cachedDash);
        }

        // Đưa vào hàng đợi sao lưu
        await SyncService.instance.enqueueSync(
          type: 'checkin',
          payload: payload,
        );

        return {
          'already_checked_in': false,
          'gacha_message': randomMsg,
          'current_streak': currentStreak,
          'longest_streak': currentStreak,
          'checkin_id': 'offline_${DateTime.now().millisecondsSinceEpoch}',
          'is_offline': true,
        };
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getTodayStatus() async {
    try {
      final response = await ApiClient.instance.get('/checkins/today');
      final data = response.data as Map<String, dynamic>;
      await StorageUtil.saveCachedTodayCheckin({
        ...data,
        'date': DateTime.now().toIso8601String(),
      });
      return data;
    } catch (_) {
      final cached = StorageUtil.getCachedTodayCheckin();
      if (cached != null &&
          (cached['date'] as String? ?? '').startsWith(
            DateTime.now().toIso8601String().substring(0, 10),
          )) {
        return cached;
      }
      return {
        'has_checked_in': false,
        'gacha_message': null,
        'current_streak': 0,
        'longest_streak': 0,
      };
    }
  }
}
