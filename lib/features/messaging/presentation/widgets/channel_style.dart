import 'package:flutter/material.dart';

class ChannelColors {
  ChannelColors._();

  static const ig = Color(0xFFDD2A7B);
  static const igDeep = Color(0xFF8134AF);

  static const igGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFF58529), ig, igDeep],
  );

  /// Softer two-stop gradient for chat bubbles and buttons.
  static const igBubble = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [ig, igDeep],
  );
}

/// Gradient button using the Instagram brand colors.
class TintedButton extends StatelessWidget {
  const TintedButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.gradient,
    required this.color,
    this.icon,
    this.iconAfter = false,
    this.onColor = Colors.white,
  });

  final String label;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final Color color;
  final IconData? icon;
  final bool iconAfter;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final ic = icon == null ? null : Icon(icon, size: 19, color: onColor);

    return Opacity(
      opacity: enabled ? 1 : .45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: .30),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                          color: onColor,
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
