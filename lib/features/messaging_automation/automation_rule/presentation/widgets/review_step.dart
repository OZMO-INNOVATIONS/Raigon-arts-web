import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/flow_preview.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/summary_row.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/rule_builder_provider.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_card.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/keyword_chip.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/section_title.dart';

/// Step 3: check everything, tweak extras, go live.
class ReviewStep extends StatelessWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context) {
    final b = context.watch<RuleBuilderProvider>();
    final p = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Review and go live',
          subtitle:
              'Check the preview on the right. You can pause it any time.',
        ),
        const SizedBox(height: 16),
        AutoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SummaryRow(
                label: 'Name',
                child: Text(
                  b.ruleName,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (b.needsKeywords)
                SummaryRow(
                  label: 'Keywords',
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final k in b.keywords) KeywordChip(k)],
                  ),
                ),
              SummaryRow(
                label: 'Reply',
                child: Text(
                  b.message.trim(),
                  style: TextStyle(color: p.textPrimary, height: 1.4),
                ),
              ),
              if (b.linkLabel != null)
                SummaryRow(
                  label: 'Link',
                  child: Text(
                    '${b.linkLabel} · ${b.linkUrl}',
                    style: TextStyle(color: p.textPrimary),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionTitle(title: 'How it flows', size: 16),
        const SizedBox(height: 10),
        FlowPreview(
          channel: b.channel,
          trigger: b.trigger,
          keywords: b.keywords,
          hasLink: b.linkUrl != null,
        ),
      ],
    );
  }
}
