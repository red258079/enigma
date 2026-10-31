enum MoodLevel { great, good, neutral, stressed, overwhelmed }

class MoodOption {
  final MoodLevel level;
  final String label;
  final String emoji;

  const MoodOption({
    required this.level,
    required this.label,
    required this.emoji,
  });

  static const List<MoodOption> options = [
    MoodOption(level: MoodLevel.great, label: 'Rất tốt', emoji: '😄'),
    MoodOption(level: MoodLevel.good, label: 'Bình thường', emoji: '🙂'),
    MoodOption(level: MoodLevel.neutral, label: 'Hơi mệt', emoji: '😐'),
    MoodOption(level: MoodLevel.stressed, label: 'Căng thẳng', emoji: '😟'),
    MoodOption(
      level: MoodLevel.overwhelmed,
      label: 'Quá tải/Hụt hẫng',
      emoji: '😞',
    ),
  ];
}

class DailyCheckin {
  final String id;
  final DateTime timestamp;
  final MoodLevel mood;
  final List<String> stressFactors;
  final String note;

  DailyCheckin({
    required this.id,
    required this.timestamp,
    required this.mood,
    required this.stressFactors,
    this.note = '',
  });

  static List<String> commonStressFactors = [
    'Thiếu ngủ / Trằn trọc',
    'Đau mỏi vai gáy / Chân',
    'Lo âu bài tập / Thi cử',
    'Cảm giác chênh vênh, mất mục tiêu',
    'Áp lực tài chính',
    'Khó hòa nhập lại với bạn bè',
    'Băn khoăn về định hướng việc làm',
  ];
}

/// Shared mapping between the daily check-in API and the home summary.
extension CheckinMood on MoodLevel {
  String get apiKey => const {
    MoodLevel.great: 'great',
    MoodLevel.good: 'good',
    MoodLevel.neutral: 'neutral',
    MoodLevel.stressed: 'tired',
    MoodLevel.overwhelmed: 'stressed',
  }[this]!;

  String get checkinLabel => const {
    MoodLevel.great: 'Tuyệt vời',
    MoodLevel.good: 'Tốt',
    MoodLevel.neutral: 'Bình thường',
    MoodLevel.stressed: 'Mệt mỏi',
    MoodLevel.overwhelmed: 'Căng thẳng',
  }[this]!;

  static MoodLevel? fromApi(String? key) {
    for (final mood in MoodLevel.values) {
      if (mood.apiKey == key) return mood;
    }
    return null;
  }
}
