import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/rule_builder_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_card.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_text_field.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/keyword_chip.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/section_title.dart';

/// Step 1: what starts this automation.
class TriggerStep extends StatefulWidget {
  const TriggerStep({super.key});

  @override
  State<TriggerStep> createState() => _TriggerStepState();
}

class _TriggerStepState extends State<TriggerStep> {
  late final TextEditingController _keywords;

  @override
  void initState() {
    super.initState();
    _keywords = TextEditingController(
      text: context.read<RuleBuilderProvider>().keywordsText,
    );
  }

  @override
  void dispose() {
    _keywords.dispose();
    super.dispose();
  }

  void _syncField(RuleBuilderProvider b) {
    _keywords.value = TextEditingValue(
      text: b.keywordsText,
      selection: TextSelection.collapsed(offset: b.keywordsText.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = context.watch<RuleBuilderProvider>();
    final p = AppPalette.of(context);
    final ig = b.channel.isInstagram;

    final title = switch (b.trigger) {
      AutomationTrigger.dmKeyword =>
        'When someone ${ig ? 'DMs' : 'messages'} you with…',
      AutomationTrigger.commentLink => 'When someone comments with…',
      AutomationTrigger.welcome => 'When someone messages you first',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: title,
          subtitle: b.needsKeywords
              ? 'Add one or more words. We reply when a message contains any of them.'
              : 'This runs once, the first time a new person messages you.',
        ),
        const SizedBox(height: 16),
        if (!b.needsKeywords)
          AutoCard(
            child: Row(
              children: [
                Icon(Icons.waving_hand_outlined, color: AppColors.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No keywords needed. Continue to write your welcome message.',
                    style: TextStyle(color: p.textPrimary, height: 1.4),
                  ),
                ),
              ],
            ),
          )
        else
          AutoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (b.trigger == AutomationTrigger.commentLink) ...[
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Any post'),
                        selected: b.anyPost,
                        selectedColor: AppColors.gold.withValues(alpha: 0.3),
                        onSelected: (_) => b.setAnyPost(true),
                      ),
                      const ChoiceChip(
                        label: Text('Specific post · soon'),
                        selected: false,
                        onSelected: null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                AutoTextField(
                  controller: _keywords,
                  onChanged: b.setKeywords,
                  label: 'Keywords',
                  hint: 'e.g. price, link, shop',
                  prefixIcon: Icons.tag_rounded,
                ),
                const SizedBox(height: 8),
                Text('Separate words with commas.',
                    style: TextStyle(color: p.textMuted, fontSize: 12)),
                if (b.keywords.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final k in b.keywords)
                        KeywordChip(
                          k,
                          onDeleted: () {
                            b.removeKeyword(k);
                            _syncField(b);
                          },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Suggestions:',
                        style: TextStyle(color: p.textMuted, fontSize: 13)),
                    for (final w in const ['Price', 'Link', 'Shop', 'Info'])
                      ActionChip(
                        label: Text(w),
                        onPressed: () {
                          b.addKeyword(w);
                          _syncField(b);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
