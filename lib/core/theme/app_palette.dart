import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_colors.dart';

class AppPalette {
  const AppPalette({
    required this.isDark,
    required this.pageBg,
    required this.sidebarBg,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.headerText,
    required this.tableHeaderBg,
    required this.rowDivider,
    required this.chipFill,
    required this.avatarBg,
    required this.navText,
    required this.tileNeutral,
    required this.tileNeutralIcon,
    required this.tileTeal,
    required this.tileGreen,
    required this.tileOrange,
    required this.notifCompletedBg,
    required this.notifDueBg,
    required this.softButtonFill,
    required this.panelFooterBg,
  });

  final bool isDark;
  final Color pageBg;
  final Color sidebarBg;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color headerText;
  final Color tableHeaderBg;
  final Color rowDivider;
  final Color chipFill;
  final Color avatarBg;
  final Color navText;
  final Color tileNeutral;
  final Color tileNeutralIcon;
  final Color tileTeal;
  final Color tileGreen;
  final Color tileOrange;
  final Color notifCompletedBg;
  final Color notifDueBg;
  final Color softButtonFill;
  final Color panelFooterBg;

  static const Color teal = Color(0xFF2BB3C6);
  static const Color orange = Color(0xFFF28C38);
  static const Color red = Color(0xFFE4572E);
  static const Color statusGold = Color(0xFFB49A55);
  static const Color statusGreen = Color(0xFF4CBF6B);
  static const Color statusRed = Color(0xFFE0605E);

  static const AppPalette light = AppPalette(
    isDark: false,
    pageBg: Color(0xFFF8F6F2),
    sidebarBg: Color(0xFFF9F8F5),
    surface: AppColors.white,
    border: Color(0xFFEFEBE2),
    textPrimary: AppColors.black,
    textMuted: Color(0xFF7C7B8C),
    headerText: AppColors.textLabel,
    tableHeaderBg: Color(0xFFF7F3EA),
    rowDivider: Color(0xFFF0ECE4),
    chipFill: Color(0xFFF3F1EC),
    avatarBg: Color(0xFFF5F0E6),
    navText: Color(0xFF1E1E2E),
    tileNeutral: Color(0xFFF5F0E6),
    tileNeutralIcon: AppColors.black,
    tileTeal: Color(0xFFDDF4F7),
    tileGreen: Color(0xFFE3F6EA),
    tileOrange: Color(0xFFFDEBDD),
    notifCompletedBg: Color(0xFFF0FAF3),
    notifDueBg: Color(0xFFFFF4E8),
    softButtonFill: Color(0xFFF1EFEA),
    panelFooterBg: Color(0xFFF7F3EA),
  );

  static const AppPalette dark = AppPalette(
    isDark: true,
    pageBg: Color(0xFF14141F),
    sidebarBg: Color(0xFF1B1B2A),
    surface: Color(0xFF2A2C42),
    border: Color(0xFF3A3C55),
    textPrimary: Color(0xFFF4F4F8),
    textMuted: Color(0xFF9C9DB3),
    headerText: Color(0xFFC9C9DA),
    tableHeaderBg: Color(0xFF25273A),
    rowDivider: Color(0xFF383A52),
    chipFill: Color(0xFF30324A),
    avatarBg: Color(0xFF3E3F52),
    navText: Color(0xFFE6E6F0),
    tileNeutral: Color(0xFF3A3B66),
    tileNeutralIcon: Color(0xFF9C9BF5),
    tileTeal: Color(0xFF2B4B60),
    tileGreen: Color(0xFF285247),
    tileOrange: Color(0xFF54402F),
    notifCompletedBg: Color(0xFF22493F),
    notifDueBg: Color(0xFF4A3A2A),
    softButtonFill: Color(0xFF2F3A48),
    panelFooterBg: Color(0xFF2A2C42),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  BoxDecoration card({double radius = 18}) => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
