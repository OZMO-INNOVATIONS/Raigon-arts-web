import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:raigon_art/core/theme/app_colors.dart';

enum _SnackBarType { success, info, error, offline }

class AppSnackBar {
  AppSnackBar._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static const double _width = 360;

  static const String offlineMessage =
      'No internet connection. Please check your network and try again.';

  static DateTime? _lastOfflineSnackbarTime;

  static void success(
    BuildContext? context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) => _show(
    context,
    message,
    type: _SnackBarType.success,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static void info(
    BuildContext? context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) => _show(
    context,
    message,
    type: _SnackBarType.info,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static void error(
    BuildContext? context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) => _show(
    context,
    message,
    type: _SnackBarType.error,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static void showOffline([BuildContext? context]) {
    final now = DateTime.now();
    if (_lastOfflineSnackbarTime != null &&
        now.difference(_lastOfflineSnackbarTime!) <
            const Duration(milliseconds: 2500)) {
      return;
    }
    _lastOfflineSnackbarTime = now;
    _show(
      context,
      offlineMessage,
      type: _SnackBarType.offline,
    );
  }

  static void showRestored([BuildContext? context]) {
    _lastOfflineSnackbarTime = null;
    success(
      context,
      'Internet connection restored.',
    );
  }

  static void _show(
    BuildContext? context,
    String message, {
    required _SnackBarType type,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = context != null
        ? ScaffoldMessenger.maybeOf(context) ?? messengerKey.currentState
        : messengerKey.currentState;
    if (messenger == null) return;

    final mediaQuery = context != null ? MediaQuery.maybeOf(context) : null;
    final screenWidth = mediaQuery?.size.width ?? 400;
    final isWide = screenWidth >= 600;

    final Color bgColor;
    final Color borderColor;
    final Color iconColor;
    final IconData iconData;

    switch (type) {
      case _SnackBarType.success:
        bgColor = const Color(0xFF065F46); // Rich deep emerald green
        borderColor = const Color(0xFF10B981); // Bright emerald accent
        iconColor = const Color(0xFF34D399); // Soft mint/green check
        iconData = RemixIcons.checkbox_circle_fill;
        break;
      case _SnackBarType.offline:
      case _SnackBarType.error:
        bgColor = const Color(0xFFDC2626); // High-visibility standard red
        borderColor = const Color(0xFFEF4444); // Vibrant red border
        iconColor = Colors.white;
        iconData = type == _SnackBarType.offline
            ? RemixIcons.wifi_off_line
            : RemixIcons.error_warning_fill;
        break;
      case _SnackBarType.info:
        bgColor = AppColors.snackbar;
        borderColor = AppColors.gold.withValues(alpha: 0.3);
        iconColor = AppColors.gold;
        iconData = RemixIcons.information_fill;
        break;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: bgColor,
          elevation: 6,
          duration: const Duration(seconds: 3),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          margin: isWide
              ? EdgeInsets.only(
                  left: screenWidth - _width - 24,
                  right: 24,
                  bottom: 24,
                )
              : const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: borderColor, width: 1.2),
          ),
          content: Row(
            children: [
              Icon(
                iconData,
                color: iconColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: type == _SnackBarType.success
                        ? const Color(0xFFA7F3D0)
                        : AppColors.gold,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
  }
}
