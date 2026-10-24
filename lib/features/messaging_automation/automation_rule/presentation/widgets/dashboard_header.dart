import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/connection_pill.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/new_automation_menu.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 14,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Messaging Automation',
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Reply to customers instantly, even while you sleep.',
              style: TextStyle(color: p.textMuted, fontSize: 14),
            ),
          ],
        ),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConnectionPill(),
            SizedBox(width: 12),
            NewAutomationMenu(),
          ],
        ),
      ],
    );
  }
}
