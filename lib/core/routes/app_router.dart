import 'package:flutter/material.dart';
import 'package:gomaa_management/core/routes/routes.dart';
import 'package:gomaa_management/screens/auth/login_screen.dart';
import 'package:gomaa_management/screens/auth/signup_screen.dart';
import 'package:gomaa_management/screens/splash/splash_screen.dart';
import 'package:gomaa_management/screens/navigation/main_navigation.dart';

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
