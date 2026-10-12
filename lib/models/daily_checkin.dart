enum MoodLevel { great, good, neutral, stressed, overwhelmed }

class MoodOption {
  final MoodLevel level;
  final String label;
  final String emoji;

  const MoodOption({required this.level, required this.label, required this.emoji});

  static const List<MoodOption> options = [
    MoodOption(level: MoodLevel.great, label: 'Rất tốt', emoji: '😄'),
    MoodOption(level: MoodLevel.good, label: 'Bình thường', emoji: '🙂'),
    MoodOption(level: MoodLevel.neutral, label: 'Hơi mệt', emoji: '😐'),
    MoodOption(level: MoodLevel.stressed, label: 'Căng thẳng', emoji: '😟'),
    MoodOption(level: MoodLevel.overwhelmed, label: 'Quá tải/Hụt hẫng', emoji: '😞'),
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
