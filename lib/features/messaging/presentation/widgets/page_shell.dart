import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';

class PageShell extends StatelessWidget {
  const PageShell({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.action,
    this.onRefresh,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? action;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 860;
    final gutter = narrow ? 18.0 : 28.0;

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Text(
            title!,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: p.textPrimary,
            ),
          ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(subtitle!, style: TextStyle(fontSize: 13.5, color: p.textMuted)),
        ],
      ],
    );

    final content = Expanded(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 36),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null || subtitle != null) ...[
                heading,
                const SizedBox(height: 16),
              ],
              child,
            ],
          ),
        ),
      ),
    );

    Widget layout = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [content],
    );

    if (onRefresh != null) {
      layout = RefreshIndicator(
        color: p.accent,
        onRefresh: onRefresh!,
        child: layout,
      );
    }

    return SizedBox(width: double.infinity, child: layout);
  }
}
