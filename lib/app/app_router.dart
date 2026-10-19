import 'package:flutter/material.dart';
import 'package:raigon_art/core/widgets/app_shell.dart';
import 'package:raigon_art/features/authentication/presentation/screens/authentication_screen.dart';

class AppRouter {
  AppRouter._();

  static const String auth = '/auth';
  static const String dashboard = '/dashboard';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case auth:
        return MaterialPageRoute(builder: (_) => const AuthScreen());

      case dashboard:
        return MaterialPageRoute(builder: (_) => const AppShell());

      default:
        return MaterialPageRoute(builder: (_) => const AuthScreen());
    }
  }
}
