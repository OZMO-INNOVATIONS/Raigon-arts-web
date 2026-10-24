import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/link_dialog.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/rule_builder_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_button.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_card.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_text_field.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/section_title.dart';

/// Step 2: what gets sent back.
class ReplyStep extends StatefulWidget {
  const ReplyStep({super.key});

  @override
  State<ReplyStep> createState() => _ReplyStepState();
}

class _ReplyStepState extends State<ReplyStep> {
  late final TextEditingController _message;

  static const _templates = {
    AutomationTrigger.commentLink: [
      'Thanks for your comment! 💛 Here is the link you asked for 👇',
      'Hi! So glad you liked it ✨ Tap the link below to see more.',
    ],
    AutomationTrigger.dmKeyword: [
      'Hi! Thanks for reaching out ✨ Here is everything you need:',
      'Great question! Take a look at this 👇',
    ],
    AutomationTrigger.welcome: [
      'Welcome to Raigon Art 👋 Browse our frames and tell us how we can help!',
      'Hi there! Thanks for messaging us. We will get back to you shortly 💛',
    ],
  };

  @override
  void initState() {
    super.initState();
    _message = TextEditingController(
      text: context.read<RuleBuilderProvider>().message,
    );
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _useTemplate(RuleBuilderProvider b, String text) {
    _message.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    b.setMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final b = context.watch<RuleBuilderProvider>();
    final p = AppPalette.of(context);
    final noun = b.channel.messageNoun;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'They get a $noun back from you',
          subtitle: 'Write the reply, or start from a template. Add a link if you like.',
        ),
        const SizedBox(height: 16),
        AutoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Templates:',
                      style: TextStyle(color: p.textMuted, fontSize: 13)),
                  for (var i = 0; i < _templates[b.trigger]!.length; i++)
                    ActionChip(
                      label: Text('Template ${i + 1}'),
                      onPressed: () => _useTemplate(b, _templates[b.trigger]![i]),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              AutoTextField(
                controller: _message,
                onChanged: b.setMessage,
                label: 'Message',
                hint: 'Write your reply…',
                maxLines: 5,
                maxLength: 1000,
              ),
              const SizedBox(height: 10),
              if (b.linkLabel != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, color: AppColors.gold),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.linkLabel!,
                                style: TextStyle(
                                    color: p.textPrimary,
                                    fontWeight: FontWeight.w700)),
                            Text(b.linkUrl ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: p.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove link',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => b.setLink(null, null),
                      ),
                    ],
                  ),
                ),
              AutoButton(
                label: b.linkLabel == null ? 'Add a link' : 'Edit link',
                icon: b.linkLabel == null ? Icons.add_rounded : Icons.edit_outlined,
                filled: false,
                expand: true,
                onPressed: () => showLinkDialog(context, b),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
