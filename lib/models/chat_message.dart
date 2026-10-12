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
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;
  final List<String>? suggestedReplies;
  final List<RAGSource>? ragSources;
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
}
