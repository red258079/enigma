import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../models/daily_checkin.dart';
import '../screens/student/tasks_screen.dart';
import '../screens/student/checkin_gacha_screen.dart';
import '../screens/student/handbook_screen.dart';
import '../screens/student/chat_screen.dart';
import '../widgets/sync_status_banner.dart';

class StudentNav extends StatefulWidget {
  const StudentNav({super.key});

  static StudentNavState? of(BuildContext context) =>
      context.findAncestorStateOfType<StudentNavState>();

  static void switchToTab(BuildContext context, int index) {
    context.findAncestorStateOfType<StudentNavState>()?.switchToTab(index);
  }

  static void setNavVisible(BuildContext context, bool visible) {
    context.findAncestorStateOfType<StudentNavState>()?.setNavVisible(visible);
  }

  @override
  State<StudentNav> createState() => StudentNavState();
}

class StudentNavState extends State<StudentNav> {
  int _currentIndex = 0;
  bool _isNavVisible = true;
  void switchToTab(int index) {
    if (!mounted || index < 0 || index >= _screens.length) return;
    setState(() {
      _currentIndex = index;
      _isNavVisible = true;
    });
  }

  void openCheckin(MoodLevel mood) {
    setState(() {
      _screens[2] = CheckinGachaScreen(initialMood: mood);
      _currentIndex = 2;
      _isNavVisible = true;
    });
  }

  void setNavVisible(bool visible) {
    if (mounted && _isNavVisible != visible) {
      setState(() => _isNavVisible = visible);
    }
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const TasksScreen(),
    const CheckinGachaScreen(),
    const HandbookScreen(),
    const ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: Column(
        children: [
          const SafeArea(bottom: false, child: SyncStatusBanner()),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                for (int i = 0; i < _screens.length; i++)
                  TickerMode(enabled: _currentIndex == i, child: _screens[i]),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isNavVisible && !isKeyboardOpen
          ? NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: switchToTab,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Trang chủ',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fact_check_outlined),
                  selectedIcon: Icon(Icons.fact_check_rounded),
                  label: 'Nhiệm vụ',
                ),
                NavigationDestination(
                  icon: Icon(Icons.check_circle_outline),
                  selectedIcon: Icon(Icons.check_circle),
                  label: 'Điểm danh',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_rounded),
                  label: 'Cẩm nang',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'Trò chuyện',
                ),
              ],
            )
          : null,
    );
  }
}
