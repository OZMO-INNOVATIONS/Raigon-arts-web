import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/activity_tile.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/automation_rule_provider.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_button.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/empty_state.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/section_title.dart';

class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<AutomationRuleProvider>();
    final p = AppPalette.of(context);
    final rules = r.visibleRules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Execution log',
          size: 18,
          trailing: rules.isEmpty
              ? null
              : AutoButton(
                  label: 'Send test',
                  icon: Icons.play_arrow_rounded,
                  filled: false,
                  onPressed: () => r.sendTest(rules.first),
                ),
        ),
        const SizedBox(height: 14),
        if (r.logs.isEmpty)
          Container(
            decoration: p.card(),
            child: const EmptyState(
              icon: Icons.history_rounded,
              title: 'No activity yet',
              message: 'Go live or send a test to see results here.',
            ),
          )
        else
          for (final log in r.logs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ActivityTile(log: log),
            ),
      ],
    );
  }
}
