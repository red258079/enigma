import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../theme/app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/student/tasks_screen.dart';
import '../screens/student/checkin_gacha_screen.dart';
import '../screens/student/handbook_screen.dart';
import '../screens/student/chat_screen.dart';

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
  double _accumulatedDelta = 0;
  static const double _scrollThreshold = 22.0;

  void switchToTab(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
        _isNavVisible = true;
        _accumulatedDelta = 0;
      });
    }
  }

  void setNavVisible(bool visible) {
    if (mounted && _isNavVisible != visible) {
      setState(() {
        _isNavVisible = visible;
        _accumulatedDelta = 0;
      });
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    // Chỉ phản hồi các cuộn trục dọc
    if (notification.metrics.axis != Axis.vertical) return false;

    // Nếu nội dung màn hình ngắn không cần cuộn, luôn hiện thanh nav
    if (notification.metrics.maxScrollExtent <= 10) {
      if (!_isNavVisible) {
        setState(() => _isNavVisible = true);
      }
      return false;
    }

    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle) {
        _accumulatedDelta = 0;
      }
    } else if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;

      // Khi chạm gần đỉnh (pixels <= 20), luôn hiện lại thanh điều hướng
      if (notification.metrics.pixels <= 20) {
        _accumulatedDelta = 0;
        if (!_isNavVisible) {
          setState(() => _isNavVisible = true);
        }
        return false;
      }

      // Đảo hướng cuộn thì reset mức tích lũy
      if ((delta > 0 && _accumulatedDelta < 0) || (delta < 0 && _accumulatedDelta > 0)) {
        _accumulatedDelta = 0;
      }
      _accumulatedDelta += delta;

      // 👆 Vuốt lên (nội dung trôi xuống -> delta > 0): người dùng đang đọc tiếp -> Ẩn nav
      if (_accumulatedDelta > _scrollThreshold && _isNavVisible) {
        setState(() {
          _isNavVisible = false;
          _accumulatedDelta = 0;
        });
      }
      // 👇 Vuốt xuống (nội dung trôi lên -> delta < 0): người dùng muốn điều hướng -> Hiện nav
      else if (_accumulatedDelta < -_scrollThreshold && !_isNavVisible) {
        setState(() {
          _isNavVisible = true;
          _accumulatedDelta = 0;
        });
      }
    }

    return false;
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
    return Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            for (int i = 0; i < _screens.length; i++)
              TickerMode(
                enabled: _currentIndex == i,
                child: _screens[i],
              ),
          ],
        ),
      ),
      bottomNavigationBar: RepaintBoundary(
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 260),
          curve: Curves.fastOutSlowIn,
          offset: _isNavVisible ? Offset.zero : const Offset(0, 1.4),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            opacity: _isNavVisible ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !_isNavVisible,
              child: _buildLiquidGlassBottomNav(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidGlassBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 18),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : const Color(0xFF8C6A3C).withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.60),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF1E283C).withValues(alpha: 0.70),
                            const Color(0xFF111726).withValues(alpha: 0.60),
                            const Color(0xFF090D16).withValues(alpha: 0.50),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.90),
                            const Color(0xFFFFFBF2).withValues(alpha: 0.75),
                            const Color(0xFFF6EAD7).withValues(alpha: 0.60),
                          ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.85),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Tổng quan')),
                    Expanded(child: _buildNavItem(1, Icons.fact_check_rounded, Icons.fact_check_outlined, 'Nhiệm vụ')),
                    Expanded(child: _buildCenterNavItem(2, Icons.auto_awesome_rounded, 'Điểm danh')),
                    Expanded(child: _buildNavItem(3, Icons.menu_book_rounded, Icons.menu_book_outlined, 'Cẩm nang')),
                    Expanded(child: _buildNavItem(4, Icons.smart_toy_rounded, Icons.smart_toy_outlined, 'AI Chat')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? AppTheme.textMuted : AppTheme.textSecondaryLight;
    final activeColor = AppTheme.primary;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(20),
      splashColor: AppTheme.primary.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: isDark ? 0.20 : 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(
                    color: activeColor.withValues(alpha: 0.30),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? activeColor : inactiveColor,
                size: 21,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.8,
                  letterSpacing: -0.2,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? AppTheme.textMuted : AppTheme.textSecondaryLight;
    final activeColor = AppTheme.primary;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(24),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accentAmber],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: isSelected ? 0.50 : 0.25),
                    blurRadius: isSelected ? 12 : 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 19),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.8,
                letterSpacing: -0.2,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
