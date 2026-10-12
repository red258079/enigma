import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'state/auth_state.dart';
import 'state/app_state.dart';
import 'state/theme_state.dart';
import 'state/notification_state.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/notifications_screen.dart';

class EnigmaApp extends StatelessWidget {
  final GlobalKey<NavigatorState>? navigatorKey;
  final Widget? home;

  const EnigmaApp({super.key, this.navigatorKey, this.home});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()..checkAuth()),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => ThemeState()),
        ChangeNotifierProvider(create: (_) => NotificationState()),
      ],
      child: Consumer<ThemeState>(
        builder: (context, themeState, child) {
          return MaterialApp(
            title: 'Enigma - Phục hồi Sức khỏe Tâm lý',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.themeMode,
            themeAnimationDuration: const Duration(milliseconds: 200),
            themeAnimationCurve: Curves.easeInOut,
            navigatorKey: navigatorKey,
            home: home ?? const SplashScreen(),
            // Named routes
            routes: {
              '/login': (_) => const LoginScreen(),
              '/notifications': (_) => const NotificationsScreen(),
            },
          );
        },
      ),
    );
  }
}
