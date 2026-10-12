import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/storage_service.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.timeline_outlined,
      'color': AppColors.primary,
      'title': 'Định hướng 3 Chặng Thực tập',
      'subtitle': 'Hành trình vượt qua "Sốc thực tế"',
      'desc': 'Từ chuẩn bị hành trang, hòa nhập tháng đầu tại nhà máy, đến duy trì hiệu suất công việc và bảo vệ sức khỏe bền bỉ.',
    },
    {
      'icon': Icons.favorite_outline,
      'color': AppColors.secondary,
      'title': 'Cân bằng 5 Trụ cột Sức khỏe',
      'subtitle': 'Giấc ngủ • Thể chất • Tinh thần • Xã hội • Nghề nghiệp',
      'desc': 'Theo dõi nhịp sinh học, thời gian ngủ khi làm ca kíp và điểm danh nhận thông điệp tích cực (Gacha) mỗi ngày.',
    },
    {
      'icon': Icons.smart_toy_outlined,
      'color': AppColors.accent,
      'title': 'Trợ lý AI & Cẩm nang Thực chiến',
      'subtitle': 'Dựa trên tri thức cựu sinh viên & RAG',
      'desc': 'Tư vấn giải pháp tức thì: xử lý đau chân khi mang giày ESD, thở Box Breathing giảm stress và thích nghi ca đêm.',
    },
  ];

  void _finishOnboarding() async {
    await StorageService.setOnboardingCompleted();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: _finishOnboarding,
            child: const Text('Bỏ qua', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (page['color'] as Color).withOpacity(0.15),
                            border: Border.all(
                              color: (page['color'] as Color).withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            page['icon'] as IconData,
                            size: 54,
                            color: page['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          page['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          page['subtitle'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: page['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          page['desc'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (idx) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentIndex == idx ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == idx ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Next / Start Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentIndex < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: Text(
                      _currentIndex == _pages.length - 1 ? 'Bắt đầu ngay' : 'Tiếp tục',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
