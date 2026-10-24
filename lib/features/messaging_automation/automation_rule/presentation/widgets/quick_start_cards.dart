import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/quick_start_card.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/automation_rule_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/section_title.dart';

/// Empty-state onboarding: pick a popular first automation.
class QuickStartCards extends StatelessWidget {
  const QuickStartCards({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<AutomationRuleProvider>();
    final ig = r.channel.isInstagram;

    final cards = <(AutomationTrigger, String, String, String)>[
      if (ig)
        (
          AutomationTrigger.commentLink,
          'Loved by creators',
          'Send a DM with your link every time someone comments on your post',
          '"link pls! 🖤"  →  "Here it is 👇"',
        ),
      (
        AutomationTrigger.welcome,
        'Great first impression',
        'Greet every new customer the moment they message you',
        '"Hi!"  →  "Welcome to Raigon Art 👋"',
      ),
      (
        AutomationTrigger.dmKeyword,
        'Boosts engagement',
        'Reply with custom answers when people ${r.channel.messageNoun} you a keyword',
        '"INFO"  →  "Here you go ✨"',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Create your first automation',
          subtitle: 'Pick a popular starting point. Preview first, go live when ready.',
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            const gap = 14.0;
            final columns = c.maxWidth >= 900 ? cards.length.clamp(1, 3) : (c.maxWidth >= 560 ? 2 : 1);
            final width = (c.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final (trigger, eyebrow, title, example) in cards)
                  SizedBox(
                    width: width,
                    child: QuickStartCard(
                      icon: trigger.icon,
                      eyebrow: eyebrow,
                      title: title,
                      example: example,
                      onStart: () => r.openBuilder(trigger),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
