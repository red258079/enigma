import 'package:flutter/material.dart';
import '../models/handbook_model.dart';

class HandbookProvider extends ChangeNotifier {
  final List<HandbookArticle> _allArticles = HandbookArticle.initialArticles;
  String _selectedCategory = 'all'; // all, sleep, physical, mental, social, career
  String _searchQuery = '';

  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  List<HandbookArticle> get filteredArticles {
    return _allArticles.where((article) {
      final matchesCategory = _selectedCategory == 'all' || article.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.summary.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.content.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
