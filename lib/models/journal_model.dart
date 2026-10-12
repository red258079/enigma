class RiskAssessmentModel {
  final String level; // "GREEN", "YELLOW", "RED"
  final List<String> reasons;
  final bool triggerEmergency;
  final List<String> recommendedActions;

  RiskAssessmentModel({
    required this.level,
    this.reasons = const [],
    this.triggerEmergency = false,
    this.recommendedActions = const [],
  });

  factory RiskAssessmentModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return RiskAssessmentModel(level: 'GREEN');
    }
    return RiskAssessmentModel(
      level: json['level'] ?? 'GREEN',
      reasons: (json['reasons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      triggerEmergency: json['trigger_emergency'] ?? false,
      recommendedActions: (json['recommended_actions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class JournalEntryModel {
  final String id;
  final String journalDate;
  final int stressLevel;
  final double sleepHours;
  final List<String> physicalSymptoms;
  final String? note;
  final String? aiSentiment;
  final List<String>? aiKeywords;
  final RiskAssessmentModel? riskAssessment;

  JournalEntryModel({
    required this.id,
    required this.journalDate,
    required this.stressLevel,
    required this.sleepHours,
    this.physicalSymptoms = const [],
    this.note,
    this.aiSentiment,
    this.aiKeywords,
    this.riskAssessment,
  });

  factory JournalEntryModel.fromJson(Map<String, dynamic> json) {
    return JournalEntryModel(
      id: json['id']?.toString() ?? '',
      journalDate: json['journal_date'] ?? '',
      stressLevel: json['stress_level'] ?? 3,
      sleepHours: (json['sleep_hours'] as num?)?.toDouble() ?? 7.0,
      physicalSymptoms: (json['physical_symptoms'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      note: json['note'],
      aiSentiment: json['ai_sentiment'],
      aiKeywords: (json['ai_keywords'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      riskAssessment: json['risk_assessment'] != null
          ? RiskAssessmentModel.fromJson(json['risk_assessment'])
          : null,
    );
  }
}
