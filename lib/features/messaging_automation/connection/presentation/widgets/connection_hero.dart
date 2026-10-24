import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';

/// Left-hand hero: leading visual, big title, supporting text, optional footer.
class ConnectionHero extends StatelessWidget {
  const ConnectionHero({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.footer,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leading,
        const SizedBox(height: 28),
        Text(
          title,
          style: TextStyle(
            color: p.textPrimary,
            fontSize: 36,
            height: 1.15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          subtitle,
          style: TextStyle(color: p.textMuted, fontSize: 15, height: 1.5),
        ),
        if (footer != null) ...[const SizedBox(height: 32), footer!],
      ],
    );
  }
}
