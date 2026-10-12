import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../models/handbook_article.dart';
import '../../theme/app_theme.dart';
import '../screens/student/handbook_detail_screen.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(String)? onSuggestionTap;
  final Function(int feedback)? onFeedbackTap;

  const ChatBubble({
    super.key,
    required this.message,
    this.onSuggestionTap,
    this.onFeedbackTap,
  });

  void _openHandbookArticle(BuildContext context, RAGSource source) {
    final article = HandbookArticle(
      id: source.articleId,
      title: source.title,
      category: source.category,
      content: 'Nội dung chi tiết từ cẩm nang AI. Vui lòng tham khảo thêm tại tab Cẩm nang.',
      author: 'Enigma AI Knowledge Base',
      publishedAt: DateTime.now(),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => HandbookDetailScreen(article: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Icon(Icons.smart_toy_rounded, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? AppTheme.primary
                        : AppTheme.surfaceAltColor(context),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: message.isUser ? const Radius.circular(18) : const Radius.circular(4),
                      bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                    border: Border.all(
                      color: message.isUser ? Colors.transparent : AppTheme.borderColor(context),
                      width: 1,
                    ),
                  ),
                  child: message.isLoading
                      ? const SizedBox(
                          width: 40,
                          height: 20,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
                            ),
                          ),
                        )
                      : Text(
                          message.content,
                          style: TextStyle(
                            color: message.isUser ? Colors.white : AppTheme.onSurface(context),
                            height: 1.45,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.surfaceAltColor(context),
                  child: Icon(Icons.person, size: 20, color: AppTheme.onSurfaceSecondary(context)),
                ),
              ],
            ],
          ),

          // 🔗 RAG Source Chips (Trích dẫn Cẩm nang)
          if (!message.isUser && message.ragSources != null && message.ragSources!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 42.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_stories_rounded, size: 13, color: AppTheme.accentMint),
                      const SizedBox(width: 4),
                      Text(
                        'Nguồn tham khảo từ Cẩm nang LG Display:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceMuted(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: message.ragSources!.map((source) {
                      return InkWell(
                        onTap: () => _openHandbookArticle(context, source),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.accentMint.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.menu_book_rounded, size: 13, color: AppTheme.accentMint),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  source.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppTheme.accentMint, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          // Feedback Action Buttons (+1 / -1) for AI responses
          if (!message.isUser && !message.isLoading && message.id != 'typing') ...[
            Padding(
              padding: const EdgeInsets.only(left: 42.0, top: 6.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      message.feedback == 1 ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                      size: 16,
                      color: message.feedback == 1 ? AppTheme.accentMint : AppTheme.onSurfaceMuted(context),
                    ),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 16,
                    onPressed: () => onFeedbackTap?.call(1),
                  ),
                  IconButton(
                    icon: Icon(
                      message.feedback == -1 ? Icons.thumb_down_alt_rounded : Icons.thumb_down_alt_outlined,
                      size: 16,
                      color: message.feedback == -1 ? Colors.redAccent : AppTheme.onSurfaceMuted(context),
                    ),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 16,
                    onPressed: () => onFeedbackTap?.call(-1),
                  ),
                ],
              ),
            ),
          ],

          // Quick Replies
          if (!message.isUser && message.suggestedReplies != null && message.suggestedReplies!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 42.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.suggestedReplies!.map((reply) {
                  return ActionChip(
                    label: Text(reply),
                    onPressed: () => onSuggestionTap?.call(reply),
                    backgroundColor: AppTheme.surfaceColor(context),
                    side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.6)),
                    labelStyle: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                  );
                }).toList(),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
