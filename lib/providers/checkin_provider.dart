import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/checkin_model.dart';

class CheckinProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool _isLoading = false;
  CheckinStatusModel? _status;
  String? _lastGachaMessage;

  bool get isLoading => _isLoading;
  CheckinStatusModel? get status => _status;
  String? get lastGachaMessage => _lastGachaMessage ?? _status?.gachaMessage;

  Future<void> fetchTodayStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.dio.get(ApiConstants.checkinToday);
      if (res.statusCode == 200) {
        _status = CheckinStatusModel.fromJson(res.data);
        if (_status?.gachaMessage != null) {
          _lastGachaMessage = _status?.gachaMessage;
        }
      }
    } catch (_) {
      // Local fallback
      _status ??= CheckinStatusModel(
        hasCheckedIn: false,
        currentStreak: 5,
        longestStreak: 12,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> submitCheckin({
    required String mood,
    List<String> stressFactors = const [],
    String? note,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.dio.post(
        ApiConstants.checkinPerform,
        data: {
          'mood': mood,
          'stress_factors': stressFactors,
          'note': note,
        },
      );

      if (res.statusCode == 200) {
        final data = res.data;
        _lastGachaMessage = data['gacha_message'];
        _status = CheckinStatusModel(
          hasCheckedIn: true,
          gachaMessage: _lastGachaMessage,
          currentStreak: data['current_streak'] ?? (_status?.currentStreak ?? 0) + 1,
          longestStreak: data['longest_streak'] ?? (_status?.longestStreak ?? 0) + 1,
        );
        _isLoading = false;
        notifyListeners();
        return _lastGachaMessage;
      }
    } catch (_) {
      // Fallback local gacha message
      final localQuotes = [
        '✨ "Bạn đang làm rất tốt! Một ngày đứng máy vất vả nhưng bạn đã hoàn thành trọn vẹn."',
        '🌟 "Hãy nhớ ngâm chân nước ấm và kê cao chân khi ngủ tối nay nhé."',
        '💪 "Kỷ luật 5S hôm nay là nền tảng tác phong kỹ sư chuyên nghiệp ngày mai."',
        '🌿 "Hít thở sâu 4 nhịp (Box Breathing) trước khi bắt đầu ca làm mới nhé!"',
      ];
      _lastGachaMessage = (localQuotes..shuffle()).first;
      _status = CheckinStatusModel(
        hasCheckedIn: true,
        gachaMessage: _lastGachaMessage,
        currentStreak: (_status?.currentStreak ?? 5) + 1,
        longestStreak: (_status?.longestStreak ?? 12) + 1,
      );
      _isLoading = false;
      notifyListeners();
      return _lastGachaMessage;
    }

    _isLoading = false;
    notifyListeners();
    return _lastGachaMessage;
  }
}
