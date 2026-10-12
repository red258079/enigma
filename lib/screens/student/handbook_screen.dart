import 'package:flutter/material.dart';
import '../../models/handbook_article.dart';
import '../../widgets/handbook_card.dart';
import 'handbook_detail_screen.dart';
import '../../theme/app_theme.dart';

class HandbookScreen extends StatefulWidget {
  const HandbookScreen({super.key});

  @override
  State<HandbookScreen> createState() => _HandbookScreenState();
}

class _HandbookScreenState extends State<HandbookScreen> {
  final List<HandbookArticle> _articles = HandbookArticle.mockArticles;
  String _selectedCategory = 'Tất cả';
  final List<String> _categories = ['Tất cả', 'Tâm lý', 'Ăn uống', 'Sức khỏe', 'Quyền lợi', 'Nhà trọ', 'An toàn'];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredArticles = _articles.where((a) {
      final matchCat = _selectedCategory == 'Tất cả' || a.category == _selectedCategory;
      if (!matchCat) return false;
      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.toLowerCase().trim();
      return a.title.toLowerCase().contains(query) ||
          a.content.toLowerCase().contains(query) ||
          a.category.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Tìm cẩm nang (5S, ca đêm, OT, trọ...)...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
              )
            : const Text('Cẩm Nang Thực Tập'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedCategory = cat);
                    },
                    selectedColor: AppTheme.primary,
                    checkmarkColor: Colors.white,
                    backgroundColor: AppTheme.surfaceColor(context),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.onSurface(context),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : AppTheme.borderColor(context),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),

          // Articles List
          Expanded(
            child: filteredArticles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 54, color: AppTheme.onSurfaceMuted(context)),
                        const SizedBox(height: 12),
                        Text(
                          'Không tìm thấy bài viết nào phù hợp',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hãy thử từ khóa khác hoặc chọn danh mục "Tất cả"',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.onSurfaceMuted(context),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredArticles.length,
                    itemBuilder: (context, index) {
                      final article = filteredArticles[index];
                      return HandbookCard(
                        key: ValueKey(article.id),
                        article: article,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HandbookDetailScreen(article: article),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
