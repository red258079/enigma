class CheckinStatusModel {
  final bool hasCheckedIn;
  final String? gachaMessage;
  final int currentStreak;
  final int longestStreak;

  CheckinStatusModel({
    required this.hasCheckedIn,
    this.gachaMessage,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory CheckinStatusModel.fromJson(Map<String, dynamic> json) {
    return CheckinStatusModel(
      hasCheckedIn: json['has_checked_in'] ?? json['already_checked_in'] ?? false,
      gachaMessage: json['gacha_message'],
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
    );
  }
}
