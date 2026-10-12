import 'journal_model.dart';

class ChatMessageModel {
  final String id;
  final bool isUser;
  final String content;
  final List<dynamic>? ragSources;
  final DateTime createdAt;
  final RiskAssessmentModel? riskAssessment;

  ChatMessageModel({
    required this.id,
    required this.isUser,
    required this.content,
    this.ragSources,
    required this.createdAt,
    this.riskAssessment,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: json['is_user'] ?? false,
      content: json['content'] ?? '',
      ragSources: json['rag_sources'] as List<dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      riskAssessment: json['risk_assessment'] != null
          ? RiskAssessmentModel.fromJson(json['risk_assessment'])
          : null,
    );
  }
}

class ChatSessionModel {
  final String id;
  final String title;
  final DateTime createdAt;

  ChatSessionModel({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Tư vấn Enigma AI',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
