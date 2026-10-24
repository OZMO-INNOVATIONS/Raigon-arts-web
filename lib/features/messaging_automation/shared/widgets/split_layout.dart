import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';

/// Two-pane layout: hero on the left, content on the right.
/// Stacks vertically on narrow screens.
class SplitLayout extends StatelessWidget {
  const SplitLayout({super.key, required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 860) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [left, const SizedBox(height: 28), right],
            ),
          );
        }
        final h = c.maxHeight.isFinite ? c.maxHeight : 640.0;
        return Row(
          children: [
            Expanded(
              child: Container(
                height: h,
                margin: const EdgeInsets.fromLTRB(24, 8, 0, 24),
                decoration: BoxDecoration(
                  color: p.tileNeutral,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: h - 96),
                    child: Align(alignment: Alignment.centerLeft, child: left),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: h),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: right,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
