import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';

class AutoButton extends StatelessWidget {
  const AutoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final bg = p.isDark ? AppColors.gold : AppColors.black;
    final onBg = p.isDark ? AppColors.black : AppColors.white;
    final fg = filled ? onBg : p.textPrimary;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: 18),
        if (loading || icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );

    final button = filled
        ? FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: onBg,
              disabledBackgroundColor: bg.withValues(alpha: 0.3),
              disabledForegroundColor: onBg.withValues(alpha: 0.7),
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: shape,
            ),
            onPressed: loading ? null : onPressed,
            child: content,
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: p.textPrimary,
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              side: BorderSide(color: AppColors.gold.withValues(alpha: 0.7)),
              shape: shape,
            ),
            onPressed: loading ? null : onPressed,
            child: content,
          );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
