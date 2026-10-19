import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';

class AppPaginationFooter extends StatelessWidget {
  const AppPaginationFooter({
    super.key,
    required this.totalItems,
    required this.page,
    this.pageSize = defaultPageSize,
    required this.onPageChanged,
    this.itemLabel = 'customers',
  });
  static const int defaultPageSize = 10;

  final int totalItems;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final String itemLabel;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    final safePageSize = pageSize > 0 ? pageSize : defaultPageSize;
    final totalPages = math.max(1, (totalItems / safePageSize).ceil());
    final currentPage = page.clamp(1, totalPages);
    final start = totalItems == 0 ? 0 : (currentPage - 1) * safePageSize + 1;
    final end = math.min(currentPage * safePageSize, totalItems);
    final bold = TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary);

    Widget pageButton({
      required String label,
      required IconData icon,
      required bool enabled,
      required bool previous,
      required VoidCallback onTap,
    }) {
      final fg = enabled ? p.textPrimary : p.textMuted;

      return InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: p.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: previous
                ? [
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: fg,
                      ),
                    ),
                  ]
                : [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: fg,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(icon, size: 18, color: fg),
                  ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.rowDivider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pagination = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              pageButton(
                label: 'Previous',
                icon: Icons.chevron_left,
                enabled: currentPage > 1,
                previous: true,
                onTap: () => onPageChanged(currentPage - 1),
              ),
              const SizedBox(width: 14),
              Text(
                'Page $currentPage of $totalPages',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(width: 14),
              pageButton(
                label: 'Next',
                icon: Icons.chevron_right,
                enabled: currentPage < totalPages,
                previous: false,
                onTap: () => onPageChanged(currentPage + 1),
              ),
            ],
          );

          final count = Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 14.5, color: p.textMuted),
              children: [
                const TextSpan(text: 'Showing '),
                TextSpan(text: '$start–$end', style: bold),
                const TextSpan(text: ' of '),
                TextSpan(text: '$totalItems', style: bold),
                TextSpan(text: ' $itemLabel'),
              ],
            ),
          );

          if (constraints.maxWidth < 650) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                count,
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerRight, child: pagination),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: count),
              pagination,
            ],
          );
        },
      ),
    );
  }
}
