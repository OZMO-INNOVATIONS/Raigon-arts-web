import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/builder_footer.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/builder_header.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/builder_preview_panel.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/builder_stepper.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/reply_step.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/review_step.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/trigger_step.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/automation_rule_provider.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/rule_builder_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';

/// 3-step builder (Trigger → Reply → Review) with a live phone preview.
class RuleBuilderScreen extends StatelessWidget {
  const RuleBuilderScreen({super.key, required this.trigger});

  final AutomationTrigger trigger;

  @override
  Widget build(BuildContext context) {
    final channel = context.read<AutomationRuleProvider>().channel;

    return ChangeNotifierProvider(
      create: (_) => RuleBuilderProvider(channel: channel, trigger: trigger),
      builder: (context, _) {
        final step = context.select<RuleBuilderProvider, BuilderStep>((b) => b.step);

        final stepView = AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(
            key: ValueKey(step),
            child: switch (step) {
              BuilderStep.trigger => const TriggerStep(),
              BuilderStep.reply => const ReplyStep(),
              BuilderStep.review => const ReviewStep(),
            },
          ),
        );

        return LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= 960) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const BuilderHeader(),
                          const SizedBox(height: 16),
                          const BuilderStepper(),
                          const SizedBox(height: 20),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(right: 12, bottom: 12),
                              child: stepView,
                            ),
                          ),
                          const BuilderFooter(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    const SizedBox(
                      width: 380,
                      child: SingleChildScrollView(child: BuilderPreviewPanel()),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const BuilderHeader(),
                  const SizedBox(height: 16),
                  const BuilderStepper(),
                  const SizedBox(height: 20),
                  stepView,
                  const SizedBox(height: 8),
                  const BuilderFooter(),
                  const SizedBox(height: 16),
                  const BuilderPreviewPanel(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
