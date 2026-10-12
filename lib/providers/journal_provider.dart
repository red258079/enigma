import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/journal_model.dart';

class JournalProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool _isLoading = false;
  List<JournalEntryModel> _history = [];
  RiskAssessmentModel? _latestRisk;

  bool get isLoading => _isLoading;
  List<JournalEntryModel> get history => _history;
  RiskAssessmentModel? get latestRisk => _latestRisk;

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.dio.get(ApiConstants.journalHistory);
      if (res.statusCode == 200) {
        final list = res.data as List<dynamic>;
        _history = list.map((e) => JournalEntryModel.fromJson(e)).toList();
      }
    } catch (_) {
      if (_history.isEmpty) {
        // Mock sample history for demonstration
        _history = [
          JournalEntryModel(
            id: 'mock-1',
            journalDate: '2026-10-03',
            stressLevel: 4,
            sleepHours: 5.5,
            physicalSymptoms: ['Đau gan bàn chân (giày ESD)', 'Mỏi vai gáy'],
            note: 'Đổi từ ca ngày sang ca đêm, giấc ngủ chập chờn nhưng đã hoàn thành ca.',
            aiSentiment: 'Căng thẳng vừa',
            riskAssessment: RiskAssessmentModel(
              level: 'YELLOW',
              reasons: ['Thiếu ngủ do đổi ca', 'Đau chân do giày ESD'],
              recommendedActions: ['Kê cao chân khi ngủ', 'Uống trà ấm trước khi ngủ'],
            ),
          ),
          JournalEntryModel(
            id: 'mock-2',
            journalDate: '2026-10-02',
            stressLevel: 2,
            sleepHours: 7.0,
            physicalSymptoms: [],
            note: 'Hôm nay làm quen thêm bạn mới ở KTX, tinh thần khá tốt.',
            aiSentiment: 'Tích cực',
            riskAssessment: RiskAssessmentModel(level: 'GREEN'),
          ),
        ];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<JournalEntryModel?> submitJournal({
    required int stressLevel,
    required double sleepHours,
    List<String> physicalSymptoms = const [],
    String? note,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.dio.post(
        ApiConstants.journalCreate,
        data: {
          'stress_level': stressLevel,
          'sleep_hours': sleepHours,
          'physical_symptoms': physicalSymptoms,
          'note': note,
        },
      );

      if (res.statusCode == 200) {
        final entry = JournalEntryModel.fromJson(res.data);
        _latestRisk = entry.riskAssessment;
        _history.insert(0, entry);
        _isLoading = false;
        notifyListeners();
        return entry;
      }
    } catch (_) {
      // Local evaluation fallback (PHQ/PSS adapted)
      String riskLevel = 'GREEN';
      List<String> reasons = [];
      List<String> actions = [];

      if (stressLevel >= 4 || sleepHours < 5.0) {
        riskLevel = 'YELLOW';
        reasons.add('Chỉ số stress cao hoặc ngủ dưới 5 tiếng');
        actions.add('Thực hành bài tập thở Box Breathing 4-4-4-4');
        actions.add('Xem cẩm nang giảm đau chân khi mang giày ESD');
      }
      if (stressLevel == 5 && sleepHours < 4.0) {
        riskLevel = 'RED';
        reasons.add('Nguy cơ kiệt sức cấp tính (Acute Burnout)');
        actions.add('Nghỉ ngơi và liên hệ cố vấn / giảng viên phụ trách');
      }

      final mockEntry = JournalEntryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        journalDate: DateTime.now().toIso8601String().substring(0, 10),
        stressLevel: stressLevel,
        sleepHours: sleepHours,
        physicalSymptoms: physicalSymptoms,
        note: note,
        aiSentiment: stressLevel >= 4 ? 'Căng thẳng' : 'Ổn định',
        riskAssessment: RiskAssessmentModel(
          level: riskLevel,
          reasons: reasons,
          triggerEmergency: riskLevel == 'RED',
          recommendedActions: actions,
        ),
      );

      _latestRisk = mockEntry.riskAssessment;
      _history.insert(0, mockEntry);
      _isLoading = false;
      notifyListeners();
      return mockEntry;
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }
}
