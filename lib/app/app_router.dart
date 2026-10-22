import 'package:flutter/material.dart';
import 'package:raigon_art/core/network/auth_token_manager.dart';
import 'package:raigon_art/core/widgets/app_shell.dart';
import 'package:raigon_art/features/authentication/presentation/screens/authentication_screen.dart';

class AppRouter {
  AppRouter._();

  static const String auth = '/auth';
  static const String dashboard = '/dashboard';

  static String get initialRoute =>
      AuthTokenManager.instance.isAuthenticated ? dashboard : auth;

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    final isAuthenticated = AuthTokenManager.instance.isAuthenticated;

    switch (routeSettings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) =>
              isAuthenticated ? const AppShell() : const AuthScreen(),
        );

      case auth:
        if (isAuthenticated) {
          return MaterialPageRoute(builder: (_) => const AppShell());
        }
        return MaterialPageRoute(builder: (_) => const AuthScreen());

      case dashboard:
        if (!isAuthenticated) {
          return MaterialPageRoute(builder: (_) => const AuthScreen());
        }
        return MaterialPageRoute(builder: (_) => const AppShell());

      default:
        return MaterialPageRoute(
          builder: (_) =>
              isAuthenticated ? const AppShell() : const AuthScreen(),
        );
    }
  }
}
