import 'package:flutter/material.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/digital_pass/presentation/digital_pass_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/schedule/presentation/schedule_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import 'main_scaffold.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String sessions = '/sessions';
  static const String pass = '/pass';
  static const String profile = '/profile';
  static const String schedule = '/schedule';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        );
      case login:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        );
      case home:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainScaffold(initialIndex: 0),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        );
      case sessions:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainScaffold(initialIndex: 1),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        );
      case pass:
        return MaterialPageRoute(builder: (_) => const DigitalPassScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case schedule:
        return MaterialPageRoute(builder: (_) => const ScheduleScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
