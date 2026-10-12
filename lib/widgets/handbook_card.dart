import 'package:flutter/material.dart';
import '../../models/handbook_article.dart';
import '../../theme/app_theme.dart';

class HandbookCard extends StatelessWidget {
  final HandbookArticle article;
  final VoidCallback onTap;

  const HandbookCard({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecorationFor(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    article.category,
                    style: const TextStyle(fontSize: 12, color: AppTheme.primaryLight, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                Icon(Icons.thumb_up_alt_outlined, size: 14, color: AppTheme.onSurfaceMuted(context)),
                const SizedBox(width: 4),
                Text('${article.helpfulCount}', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted(context))),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              article.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              article.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: AppTheme.onSurfaceSecondary(context)),
                const SizedBox(width: 4),
                Text(article.author, style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceSecondary(context))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
