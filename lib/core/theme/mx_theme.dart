import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';

/// so this feature follows the same light / dark theme as the dashboard.
extension MxPalette on AppPalette {
  // Primary accent (gold family)
  Color get accent => isDark ? AppColors.gold : AppPalette.statusGold;
  Color get accentSoft =>
      isDark ? AppColors.gold.withValues(alpha: .16) : tileNeutral;
  Color get onAccent => isDark ? AppColors.black : AppColors.white;

  // Brand gradients
  LinearGradient get brand => isDark
      ? const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.gold, AppColors.goldSoft],
        )
      : AppColors.darkGradient;
  Color get onBrand => isDark ? AppColors.black : AppColors.white;

  LinearGradient get brandDeep => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.black,
      const Color(0xFF3A3425),
      Color.lerp(AppColors.gold, AppColors.black, .4)!,
    ],
  );

  // Shadows
  List<BoxShadow> get glow => [
    BoxShadow(
      color: AppColors.gold.withValues(alpha: isDark ? .22 : .35),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];
  List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Semantic colors
  Color get mint => AppColors.green;
  Color get mintSoft => tileGreen;
  Color get pink => AppPalette.orange;
  Color get pinkSoft => tileOrange;
  Color get sky => AppPalette.teal;
  Color get skySoft => tileTeal;
  Color get amber => AppPalette.orange;
  Color get amberSoft => tileOrange;

  // WhatsApp brand colors
  Color get wa => const Color(0xFF25D366);
  Color get waDark => const Color(0xFF075E54);
}
