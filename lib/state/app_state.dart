import 'package:flutter/material.dart';
import '../models/wellbeing_score.dart';
import '../models/recovery_task.dart';
import '../models/daily_checkin.dart';

class AppState extends ChangeNotifier {
  WellbeingScore _score = WellbeingScore.sampleInitial;
  bool _hasCompletedAssessment = false;
  int _streakDays = 3;
  int _currentDay = 1;

  final List<RecoveryTask> _tasks = RecoveryTask.defaultTasks;
  final List<DailyCheckin> _checkins = [];

  int _refreshCounter = 0;
  int get refreshCounter => _refreshCounter;

  void triggerRefresh() {
    _refreshCounter++;
    notifyListeners();
  }

  WellbeingScore get score => _score;
  bool get hasCompletedAssessment => _hasCompletedAssessment;
  int get streakDays => _streakDays;
  int get currentDay => _currentDay;
  List<RecoveryTask> get allTasks => List.unmodifiable(_tasks);
  List<DailyCheckin> get checkins => List.unmodifiable(_checkins);

  List<RecoveryTask> get todayTasks =>
      _tasks.where((t) => t.day == _currentDay || (t.day <= _currentDay && !t.isCompleted)).toList();

  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  double get recoveryProgress => _tasks.isEmpty ? 0 : completedCount / _tasks.length;

  DailyCheckin? get todayCheckin {
    final now = DateTime.now();
    for (final c in _checkins) {
      if (c.timestamp.year == now.year &&
          c.timestamp.month == now.month &&
          c.timestamp.day == now.day) {
        return c;
      }
    }
    return null;
  }

  void toggleTaskCompletion(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks[idx].isCompleted = !_tasks[idx].isCompleted;
      notifyListeners();
    }
  }

  void saveAssessment(WellbeingScore newScore) {
    _score = newScore;
    _hasCompletedAssessment = true;
    notifyListeners();
  }

  void recordCheckin(MoodLevel mood, List<String> stressFactors, String note) {
    final newCheckin = DailyCheckin(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      mood: mood,
      stressFactors: stressFactors,
      note: note,
    );
    _checkins.insert(0, newCheckin);
    _streakDays += 1;
    notifyListeners();
  }

  void setCurrentDay(int day) {
    _currentDay = day.clamp(1, 30);
    notifyListeners();
  }
}
