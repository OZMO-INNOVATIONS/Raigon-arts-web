import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';

class AutoTextField extends StatelessWidget {
  const AutoTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final line = p.isDark ? p.border : AppColors.fieldBorder;

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: TextStyle(color: p.textPrimary, fontSize: 14, height: 1.4),
      cursorColor: AppColors.gold,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: p.textMuted),
        hintStyle: TextStyle(color: p.textMuted.withValues(alpha: 0.7)),
        prefixIcon:
            prefixIcon == null ? null : Icon(prefixIcon, size: 20, color: p.textMuted),
        filled: true,
        fillColor: p.isDark ? p.chipFill : AppColors.fieldFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: border(line),
        enabledBorder: border(line),
        focusedBorder: border(AppColors.gold, 1.6),
      ),
    );
  }
}
