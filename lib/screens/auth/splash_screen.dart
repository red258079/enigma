import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../core/utils/storage.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import '../../navigation/student_nav.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Hiển thị splash tối đa 800ms để trải nghiệm mượt mà không bị trễ
    final splashDelay = Future.delayed(const Duration(milliseconds: 800));

    // Chờ AuthState.checkAuth() hoàn tất (isLoading chuyển thành false)
    final authState = context.read<AuthState>();
    await _waitForAuthCheck(authState);

    // Chờ nốt animation splash nếu auth check xong sớm
    await splashDelay;

    if (!mounted) return;

    final hasSeenOnboarding = StorageUtil.hasSeenOnboarding;

    if (authState.isAuthenticated) {
      if (authState.user?.role == 'admin') {
        // TODO: Navigate to Admin Dashboard
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StudentNav()),
        );
      }
    } else {
      if (!hasSeenOnboarding) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  /// Chờ cho đến khi AuthState.checkAuth() hoàn tất
  /// (isLoading chuyển từ true → false)
  Future<void> _waitForAuthCheck(AuthState authState) async {
    if (!authState.isLoading) return; // Đã xong rồi

    final completer = Completer<void>();

    void listener() {
      if (!authState.isLoading) {
        authState.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      }
    }

    authState.addListener(listener);

    // Double-check phòng trường hợp isLoading đã false ngay trước addListener
    if (!authState.isLoading) {
      authState.removeListener(listener);
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/icons/app_icon.png',
                width: 96,
                height: 96,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enigma',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ENIGMA TEAM',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
