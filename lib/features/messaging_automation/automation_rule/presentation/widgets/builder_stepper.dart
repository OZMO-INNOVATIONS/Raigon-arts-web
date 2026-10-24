import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/rule_builder_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';

class BuilderStepper extends StatelessWidget {
  const BuilderStepper({super.key});

  @override
  Widget build(BuildContext context) {
    final b = context.watch<RuleBuilderProvider>();
    final p = AppPalette.of(context);
    const labels = {
      BuilderStep.trigger: 'Trigger',
      BuilderStep.reply: 'Reply',
      BuilderStep.review: 'Review',
    };

    return Row(
      children: [
        for (final s in BuilderStep.values) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => b.goTo(s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 4,
                    decoration: BoxDecoration(
                      color: s.index <= b.step.index
                          ? AppColors.gold
                          : p.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        s.index < b.step.index
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 15,
                        color: s.index <= b.step.index
                            ? AppColors.gold
                            : p.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${s.index + 1}. ${labels[s]}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: s == b.step ? FontWeight.w800 : FontWeight.w500,
                          color: s == b.step ? p.textPrimary : p.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (s != BuilderStep.review) const SizedBox(width: 10),
        ],
      ],
    );
  }
}
