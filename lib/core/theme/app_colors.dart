import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color black = Color(0xFF0B0B0B);
  static const Color gold = Color(0xFFCDBB88);
  static const Color goldSoft = Color(0xFFE9DFC0);
  static const Color white = Color(0xFFFFFFFF);

  static const Color cream = Color(0xFFFCF4DC);
  static const Color blush = Color(0xFFEDE3E3);
  static const Color gridLine = Color(0x14CDBB88);

  static const Color textPrimary = Color(0xFF0B0B0B);
  static const Color textLabel = Color(0xFF3F3D56);
  static const Color textMuted = Color(0xFF8A8A9A);
  static const Color textHint = Color(0xFFB4B3C0);

  static const Color fieldFill = Color(0xFFF9F9FB);
  static const Color fieldFillDisabled = Color(0xFFF3F3F8);
  static const Color fieldBorder = Color(0xFFE4E4EA);
  static const Color fieldIcon = Color(0xFF9A98A8);
  static const Color otpPanelFill = Color(0xFFFAF8F3);

  static const Color green = Color(0xFF62CB6F);
  static const Color greenDark = Color(0xFF3F8F7D);
  static const Color greenButton = Color(0xFF5DBF73);
  static const Color greenButtonDark = Color(0xFF4E9F60);
  static const Color greenSoft = Color(0xFFE9F7EE);

  static const Color snackbar = Color(0xFF2B2A3D);
  static const Color error = Color(0xFFFF8A8A);

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [black, Color(0xFF3A3425), gold],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [green, greenDark],
  );

  static const LinearGradient greenSolidGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [greenButton, greenButtonDark],
  );

  static const LinearGradient iconDarkGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [black, gold],
  );

  static const LinearGradient iconGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [green, greenDark],
  );
}
