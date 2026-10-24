import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/automation_rule_provider.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/rule_builder_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_button.dart';

class BuilderFooter extends StatelessWidget {
  const BuilderFooter({super.key});

  Future<void> _goLive(BuildContext context) async {
    final b = context.read<RuleBuilderProvider>();
    final rules = context.read<AutomationRuleProvider>();

    final rule = await b.publish();
    if (!context.mounted) return;

    if (rule == null) {
      AppSnackBar.error(context, b.error ?? 'Could not publish automation.');
      return;
    }
    AppSnackBar.success(context, 'Your automation is live 🎉');
    rules.onRulePublished(rule);
  }

  @override
  Widget build(BuildContext context) {
    final b = context.watch<RuleBuilderProvider>();
    final p = AppPalette.of(context);
    final first = b.step == BuilderStep.trigger;
    final last = b.step == BuilderStep.review;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          if (!first)
            AutoButton(
              label: 'Back',
              icon: Icons.arrow_back_rounded,
              filled: false,
              onPressed: b.back,
            ),
          const Spacer(),
          if (!last)
            AutoButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              onPressed: b.canContinue ? b.next : null,
            )
          else
            AutoButton(
              label: 'Go live',
              icon: Icons.rocket_launch_outlined,
              loading: b.publishing,
              onPressed: b.canGoLive ? () => _goLive(context) : null,
            ),
        ],
      ),
    );
  }
}
