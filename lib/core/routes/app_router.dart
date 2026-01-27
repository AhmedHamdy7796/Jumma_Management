import 'package:flutter/material.dart';
import 'package:gomaa_management/core/routes/routes.dart';
import 'package:gomaa_management/features/auth/presentation/pages/login_screen.dart';
import 'package:gomaa_management/features/auth/presentation/pages/signup_screen.dart';
import 'package:gomaa_management/features/splash/presentation/pages/splash_screen.dart';
import 'package:gomaa_management/view/screens/main_navigation.dart';

class AppRouter {
  Route? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case Routes.signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case Routes.mainNavigation:
        return MaterialPageRoute(builder: (_) => const MainNavigation());
      default:
        return null;
    }
  }
}
