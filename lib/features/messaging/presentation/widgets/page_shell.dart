import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';

class PageShell extends StatelessWidget {
  const PageShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
    this.onRefresh,
  });

  final String title, subtitle;
  final Widget child;
  final Widget? action;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 860;

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: narrow ? 26 : 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: p.textMuted, fontSize: 14)),
      ],
    );

    // Keep the header fixed above the scrollable content.
    final header = Padding(
      padding: EdgeInsets.fromLTRB(
        narrow ? 18 : 26,
        narrow ? 18 : 26,
        narrow ? 18 : 26,
        0,
      ),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                if (action != null) ...[const SizedBox(height: 16), action!],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: heading),
                if (action != null) action!,
              ],
            ),
    );

    final content = Expanded(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(narrow ? 18 : 26),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );

    Widget layout = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        SizedBox(height: narrow ? 22 : 28),
        content,
      ],
    );

    if (onRefresh != null) {
      layout = RefreshIndicator(
        color: p.accent,
        onRefresh: onRefresh!,
        child: layout,
      );
    }

    return layout;
  }
}
