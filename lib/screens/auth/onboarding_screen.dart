import 'package:flutter/material.dart';
import '../../core/utils/storage.dart';
import 'login_screen.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Enigma',
      'subtitle': 'Người bạn đồng hành thực tập',
      'desc': 'Hệ thống hỗ trợ sức khỏe tâm lý dành riêng cho sinh viên thực tập, giúp bạn vượt qua giai đoạn khó khăn.',
      'icon': 'spa_rounded',
    },
    {
      'title': '5 Trụ Cột Sức Khỏe',
      'subtitle': 'Phục hồi toàn diện',
      'desc': 'Theo dõi và cải thiện Tâm lý, Giấc ngủ, Thể chất, Kết nối và Định hướng nghề nghiệp mỗi ngày.',
      'icon': 'donut_large_rounded',
    },
    {
      'title': 'Trợ Lý AI & Cẩm Nang',
      'subtitle': 'Khám phá tri thức',
      'desc': 'Tương tác trực tiếp với AI và tra cứu kinh nghiệm từ các thế hệ cựu sinh viên đi trước.',
      'icon': 'smart_toy_rounded',
    },
  ];

  IconData _getIconData(String name) {
    switch (name) {
      case 'spa_rounded': return Icons.spa_rounded;
      case 'donut_large_rounded': return Icons.donut_large_rounded;
      case 'smart_toy_rounded': return Icons.smart_toy_rounded;
      default: return Icons.info_outline;
    }
  }

  void _finishOnboarding() async {
    await StorageUtil.setHasSeenOnboarding(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  final data = _onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIconData(data['icon']!),
                          size: 100,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          data['title']!,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['subtitle']!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data['desc']!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).primaryColor
                              : AppTheme.cardBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _onboardingData.length - 1) {
                        _finishOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    child: Text(_currentPage == _onboardingData.length - 1 ? 'Bắt đầu' : 'Tiếp theo'),
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
