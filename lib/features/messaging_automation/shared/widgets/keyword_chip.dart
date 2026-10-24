import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';

class KeywordChip extends StatelessWidget {
  const KeywordChip(this.label, {super.key, this.onTap, this.onDeleted});

  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final text = p.isDark ? AppColors.goldSoft : const Color(0xFF7A6A35);

    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(12, 5, onDeleted == null ? 12 : 6, 5),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.14),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onDeleted != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDeleted,
                  child: Icon(Icons.close_rounded, size: 15, color: text),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
