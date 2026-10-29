import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';

class PageShell extends StatelessWidget {
  const PageShell({
    super.key,
    // required this.title,
    // required this.subtitle,
    required this.child,
    this.action,
    this.onRefresh,
  });

  // final String title, subtitle;
  final Widget child;
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
        // Text(
        //   title,
        //   style: TextStyle(
        //     fontSize: narrow ? 26 : 30,
        //     fontWeight: FontWeight.w800,
        //     letterSpacing: -0.9,
        //     color: p.textPrimary,
        //   ),
        // ),
        // const SizedBox(height: 4),
        // Text(
        //   subtitle,
        //   style: TextStyle(color: p.textMuted, fontSize: 14, height: 1.35),
        // ),
      ],
    );

    // Header stays fixed above the scrollable content.
    final header = Padding(
      padding: EdgeInsets.fromLTRB(gutter, narrow ? 18 : 26, gutter, 0),
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
                ?action,
              ],
            ),
    );

    final content = Expanded(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(gutter, narrow ? 22 : 26, gutter, 36),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );

    Widget layout = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [header, content],
    );

    if (onRefresh != null) {
      layout = RefreshIndicator(
        color: p.accent,
        onRefresh: onRefresh!,
        child: layout,
      );
    }

    // On very wide screens keep the content in a readable column.
    return SizedBox(width: double.infinity, child: layout);
  }
}
