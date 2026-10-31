class RAGSource {
  final String articleId;
  final String title;
  final String category;
  final double similarityScore;

  RAGSource({
    required this.articleId,
    required this.title,
    required this.category,
    this.similarityScore = 0.0,
  });

  factory RAGSource.fromJson(Map<String, dynamic> json) {
    return RAGSource(
      articleId: json['article_id']?.toString() ?? '',
      title: json['title'] ?? 'Cẩm nang thực tập',
      category: json['category'] ?? 'general',
      similarityScore: (json['similarity_score'] is num) ? (json['similarity_score'] as num).toDouble() : 0.0,
    );
  }
}

class ChatMessage {
  String id;
  String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;
  final List<String>? suggestedReplies;
  List<RAGSource>? ragSources;
  int? feedback; // 1 = Thumbs Up, -1 = Thumbs Down, null = Unrated

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
    this.suggestedReplies,
    this.ragSources,
    this.feedback,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    List<RAGSource>? sources;
    if (json['rag_sources'] is List) {
      sources = (json['rag_sources'] as List)
          .map((s) => RAGSource.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] ?? '',
      isUser: json['is_user'] == true,
      timestamp: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      feedback: json['feedback'] is int ? json['feedback'] as int : null,
      ragSources: sources,
    );
  }
}

class ChatSessionItem {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChatSessionItem({
    required this.id,
    required this.title,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChatSessionItem.fromJson(Map<String, dynamic> json) {
    return ChatSessionItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Tư vấn Enigma AI',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal()
          : null,
    );
  }
}
