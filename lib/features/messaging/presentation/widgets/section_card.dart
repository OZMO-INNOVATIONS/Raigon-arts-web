import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';

/// The one card surface used across the messaging feature.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.borderColor,
    this.color,
    this.shadow = true,
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;
  final bool shadow;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? p.border),
        boxShadow: shadow ? p.softShadow : null,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: box,
      ),
    );
  }
}

/// Small rounded status label (Live, Paused, 12 replies …).
class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    required this.color,
    required this.soft,
    this.icon,
    this.iconSize = 12,
  });

  final String text;
  final Color color, soft;
  final IconData? icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded square that holds an icon. Defaults to the app's gold accent.
class IconTile extends StatelessWidget {
  const IconTile(
    this.icon, {
    super.key,
    this.size = 40,
    this.color,
    this.background,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? p.accentSoft,
        borderRadius: BorderRadius.circular(size * .32),
      ),
      child: Icon(icon, size: size * .5, color: color ?? p.accent),
    );
  }
}

/// Secondary button. Pass only [icon] for a compact icon button.
class SoftOutlineButton extends StatelessWidget {
  const SoftOutlineButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.color,
  });

  final VoidCallback? onPressed;
  final String? label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color ?? p.textPrimary,
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: EdgeInsets.symmetric(
          horizontal: label == null ? 16 : 20,
          vertical: 15,
        ),
        minimumSize: const Size(0, 48),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 18),
          if (icon != null && label != null) const SizedBox(width: 8),
          if (label != null)
            Flexible(
              child: Text(
                label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
