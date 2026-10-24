import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/models/activity_log.dart';
import 'package:raigon_art/features/messaging_automation/shared/utils/formatters.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_card.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/keyword_chip.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.log});
  final ActivityLog log;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AutoCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            log.success ? Icons.check_circle_rounded : Icons.error_rounded,
            color: log.success ? AppPalette.statusGreen : AppPalette.statusRed,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        log.ruleName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (log.isTest) ...[
                      const SizedBox(width: 8),
                      const KeywordChip('TEST'),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.contact} · ${log.detail}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(timeAgo(log.time),
              style: TextStyle(color: p.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
