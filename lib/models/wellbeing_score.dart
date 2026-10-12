import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum PillarType { mental, sleep, physical, social, career }

class PillarInfo {
  final PillarType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const PillarInfo({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  static const Map<PillarType, PillarInfo> registry = {
    PillarType.mental: PillarInfo(
      type: PillarType.mental,
      title: 'Tâm lý',
      subtitle: 'Căng thẳng, cảm xúc và thích nghi tâm lý',
      icon: Icons.psychology_rounded,
      color: AppTheme.mentalColor,
    ),
    PillarType.sleep: PillarInfo(
      type: PillarType.sleep,
      title: 'Giấc ngủ',
      subtitle: 'Đồng bộ nhịp sinh học sau ca kíp nhà máy',
      icon: Icons.bedtime_rounded,
      color: AppTheme.sleepColor,
    ),
    PillarType.physical: PillarInfo(
      type: PillarType.physical,
      title: 'Thể chất',
      subtitle: 'Đau mỏi vai gáy và chăm sóc sức khỏe ca đứng',
      icon: Icons.fitness_center_rounded,
      color: AppTheme.physicalColor,
    ),
    PillarType.social: PillarInfo(
      type: PillarType.social,
      title: 'Kết nối',
      subtitle: 'Hòa nhập đồng nghiệp, mạng lưới thực tập',
      icon: Icons.people_alt_rounded,
      color: AppTheme.socialColor,
    ),
    PillarType.career: PillarInfo(
      type: PillarType.career,
      title: 'Định hướng',
      subtitle: 'Mục tiêu nghề nghiệp và an toàn lao động 5S',
      icon: Icons.explore_rounded,
      color: AppTheme.careerColor,
    ),
  };
}

class WellbeingScore {
  final double mental;   // 0 - 100
  final double sleep;    // 0 - 100
  final double physical; // 0 - 100
  final double social;   // 0 - 100
  final double career;   // 0 - 100
  final DateTime assessedAt;

  const WellbeingScore({
    required this.mental,
    required this.sleep,
    required this.physical,
    required this.social,
    required this.career,
    required this.assessedAt,
  });

  double get overall =>
      (mental * 0.25 + sleep * 0.25 + physical * 0.20 + social * 0.15 + career * 0.15);

  String get overallStatus {
    final score = overall;
    if (score >= 80) return 'Rất tốt (Ổn định)';
    if (score >= 65) return 'Khá ổn (Cần duy trì)';
    if (score >= 50) return 'Cần chú ý phục hồi';
    return 'Ưu tiên can thiệp sớm';
  }

  Color get overallColor {
    final score = overall;
    if (score >= 80) return AppTheme.accentMint;
    if (score >= 65) return AppTheme.secondary;
    if (score >= 50) return AppTheme.accentAmber;
    return AppTheme.accentCoral;
  }

  PillarType get priorityPillar {
    final scores = {
      PillarType.sleep: sleep,
      PillarType.mental: mental,
      PillarType.physical: physical,
      PillarType.social: social,
      PillarType.career: career,
    };
    var lowest = PillarType.sleep;
    var minVal = 100.0;
    scores.forEach((pillar, val) {
      if (val < minVal) {
        minVal = val;
        lowest = pillar;
      }
    });
    return lowest;
  }

  double scoreFor(PillarType type) {
    switch (type) {
      case PillarType.mental:
        return mental;
      case PillarType.sleep:
        return sleep;
      case PillarType.physical:
        return physical;
      case PillarType.social:
        return social;
      case PillarType.career:
        return career;
    }
  }

  // Điểm khởi đầu mặc định phản ánh tình trạng phổ biến của SV sau 3 tháng LGD
  static WellbeingScore get sampleInitial => WellbeingScore(
        mental: 62,
        sleep: 45,
        physical: 52,
        social: 68,
        career: 58,
        assessedAt: DateTime.now().subtract(const Duration(days: 3)),
      );
}
