import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/stat_tile.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/automation_rule_provider.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<AutomationRuleProvider>();
    final p = AppPalette.of(context);

    return LayoutBuilder(
      builder: (context, c) {
        const gap = 12.0;
        final columns = c.maxWidth >= 720 ? 3 : (c.maxWidth >= 460 ? 2 : 1);
        final width = (c.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: StatTile(
                label: 'Active automations',
                value: '${r.activeCount}',
                icon: Icons.bolt_rounded,
                tint: p.tileNeutral,
              ),
            ),
            SizedBox(
              width: width,
              child: StatTile(
                label: 'Total runs',
                value: '${r.totalRuns}',
                icon: Icons.play_circle_outline_rounded,
                tint: p.tileTeal,
                iconColor: AppPalette.teal,
              ),
            ),
            SizedBox(
              width: width,
              child: StatTile(
                label: 'Success rate',
                value: '${r.successRate.toStringAsFixed(0)}%',
                icon: Icons.check_circle_outline_rounded,
                tint: p.tileGreen,
                iconColor: AppPalette.statusGreen,
              ),
            ),
          ],
        );
      },
    );
  }
}
