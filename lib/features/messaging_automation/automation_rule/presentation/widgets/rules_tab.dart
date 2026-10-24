import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/quick_start_cards.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/rule_card.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/stats_row.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/automation_rule_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_button.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_card.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/empty_state.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/section_title.dart';

class RulesTab extends StatelessWidget {
  const RulesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<AutomationRuleProvider>();
    final rules = r.visibleRules;

    final Widget content;
    if (r.loading && rules.isEmpty) {
      content = const AutoCard(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading automations…'),
          ],
        ),
      );
    } else if (r.error != null && rules.isEmpty) {
      content = AutoCard(
        child: EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Something went wrong',
          message: r.error!,
          action: AutoButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            onPressed: r.load,
          ),
        ),
      );
    } else if (rules.isEmpty) {
      content = const QuickStartCards();
    } else {
      content = Column(
        children: [
          for (final rule in rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RuleCard(key: ValueKey(rule.id), rule: rule),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Overview',
          size: 18,
          trailing: IconButton(
            tooltip: 'Refresh',
            onPressed: r.loading || !r.channel.isInstagram ? null : r.load,
            icon: r.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh_rounded,
                    color: AppPalette.of(context).textMuted),
          ),
        ),
        const SizedBox(height: 8),
        const StatsRow(),
        const SizedBox(height: 22),
        if (rules.isNotEmpty) ...[
          const SectionTitle(title: 'Your automations', size: 18),
          const SizedBox(height: 12),
        ],
        content,
      ],
    );
  }
}
