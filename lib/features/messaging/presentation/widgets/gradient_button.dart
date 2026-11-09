import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconAfter = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool iconAfter;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final enabled = onPressed != null && !busy;
    final ic = icon == null ? null : Icon(icon, size: 19, color: p.onBrand);
    return Opacity(
      opacity: onPressed == null ? .45 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: p.brand,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled ? p.glow : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (busy)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: p.onBrand,
                        ),
                      )
                    else ...[
                      if (ic != null && !iconAfter) ...[
                        ic,
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: p.onBrand,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (ic != null && iconAfter) ...[
                        const SizedBox(width: 8),
                        ic,
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}