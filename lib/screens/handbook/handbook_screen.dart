import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/handbook_model.dart';
import '../../providers/handbook_provider.dart';
import 'handbook_detail_screen.dart';

class HandbookScreen extends StatelessWidget {
  const HandbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final handbook = Provider.of<HandbookProvider>(context);

    final categories = [
      {'key': 'all', 'label': 'Tất cả'},
      {'key': 'physical', 'label': 'Thể chất & Giày ESD'},
      {'key': 'sleep', 'label': 'Giấc ngủ & Lệch ca'},
      {'key': 'mental', 'label': 'Tinh thần & Stress'},
      {'key': 'social', 'label': 'KTX & Bạn trọ'},
      {'key': 'career', 'label': '5S & Quyền lợi'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cẩm nang Thực tập Sinh viên'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: TextField(
                onChanged: (val) => handbook.setSearchQuery(val),
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm: đau chân ESD, đổi ca, thở 4 nhịp, 5S...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                ),
              ),
            ),

            // Category Filter Pills
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = handbook.selectedCategory == cat['key'];
                  return ChoiceChip(
                    label: Text(cat['label']!),
                    selected: isSelected,
                    onSelected: (_) => handbook.setCategory(cat['key']!),
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Articles List
            Expanded(
              child: handbook.filteredArticles.isEmpty
                  ? const Center(
                      child: Text(
                        'Không tìm thấy bài viết phù hợp.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      itemCount: handbook.filteredArticles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final article = handbook.filteredArticles[index];
                        return _buildArticleCard(context, article);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, HandbookArticle article) {
    Color catColor = AppColors.primary;
    switch (article.category) {
      case 'physical':
        catColor = AppColors.pillarPhysical;
        break;
      case 'sleep':
        catColor = AppColors.pillarSleep;
        break;
      case 'mental':
        catColor = AppColors.pillarMental;
        break;
      case 'social':
        catColor = AppColors.pillarSocial;
        break;
      case 'career':
        catColor = AppColors.pillarCareer;
        break;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HandbookDetailScreen(article: article)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    article.categoryName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: catColor,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${article.readTimeMinutes} phút đọc',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              article.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              article.summary,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Xem chi tiết',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 11, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
