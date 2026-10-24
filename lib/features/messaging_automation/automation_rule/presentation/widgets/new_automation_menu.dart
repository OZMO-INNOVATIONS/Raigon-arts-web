import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/automation_rule_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_button.dart';

class NewAutomationMenu extends StatelessWidget {
  const NewAutomationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final rules = context.read<AutomationRuleProvider>();

    return PopupMenuButton<AutomationTrigger>(
      tooltip: 'Create a new automation',
      onSelected: rules.openBuilder,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        for (final t in rules.channel.triggers)
          PopupMenuItem(
            value: t,
            child: Row(
              children: [
                Icon(t.icon, size: 18),
                const SizedBox(width: 10),
                Text(t.shortLabel),
              ],
            ),
          ),
      ],
      child: IgnorePointer(
        child: AutoButton(
          label: 'New automation',
          icon: Icons.add_rounded,
          onPressed: () {},
        ),
      ),
    );
  }
}
