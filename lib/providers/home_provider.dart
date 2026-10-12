import 'package:flutter/material.dart';

class HomeProvider extends ChangeNotifier {
  int currentStreak = 5;
  int longestStreak = 12;
  bool hasCheckedInToday = false;

  // 5 Pillars scores (0 - 100)
  int sleepScore = 68;
  int physicalScore = 62;
  int mentalScore = 75;
  int socialScore = 80;
  int careerScore = 88;

  String dailyQuote = '“Thích nghi là một kỹ năng, không phải là gánh nặng. Mỗi ca làm việc đều giúp bạn tích lũy bản lĩnh thực chiến.”';

  void updateStreak(int current, int longest, bool checkedIn) {
    currentStreak = current;
    longestStreak = longest;
    hasCheckedInToday = checkedIn;
    notifyListeners();
  }

  void updateScores({int? sleep, int? physical, int? mental, int? social, int? career}) {
    if (sleep != null) sleepScore = sleep;
    if (physical != null) physicalScore = physical;
    if (mental != null) mentalScore = mental;
    if (social != null) socialScore = social;
    if (career != null) careerScore = career;
    notifyListeners();
  }
}
