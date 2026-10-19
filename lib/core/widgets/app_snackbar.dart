import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_colors.dart';

class AppSnackBar {
  AppSnackBar._();

  static const double _width = 340;
  static void success(BuildContext context, String message) =>
      _show(context, message, isError: false);
  static void error(BuildContext context, String message) =>
      _show(context, message, isError: true);

  static void _show(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.snackbar,
          elevation: 0,
          duration: const Duration(seconds: 3),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          margin: isWide
              ? EdgeInsets.only(
                  left: screenWidth - _width - 24,
                  right: 24,
                  bottom: 24,
                )
              : const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Row(
            children: [
              Icon(
                isError ? Icons.error : Icons.check_circle,
                color: isError ? AppColors.error : AppColors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
