import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/automation_rule_provider.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/rule_builder_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/channel_icon.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/confirm_dialog.dart';

class BuilderHeader extends StatelessWidget {
  const BuilderHeader({super.key});

  Future<void> _close(BuildContext context) async {
    final b = context.read<RuleBuilderProvider>();
    final rules = context.read<AutomationRuleProvider>();
    if (b.isDirty) {
      final discard = await showConfirmDialog(
        context,
        title: 'Discard this draft?',
        message: 'Your changes have not been published yet.',
        confirmLabel: 'Discard',
        destructive: true,
      );
      if (!discard) return;
    }
    rules.closeBuilder();
  }

  @override
  Widget build(BuildContext context) {
    final b = context.watch<RuleBuilderProvider>();
    final p = AppPalette.of(context);

    return Row(
      children: [
        IconButton(
          tooltip: 'Back to dashboard',
          onPressed: () => _close(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 4),
        ChannelIcon(b.channel, size: 30),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New ${b.channel.label} automation',
                style: TextStyle(
                  color: p.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              Text(
                b.trigger.shortLabel,
                style: TextStyle(color: p.textMuted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
