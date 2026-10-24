import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/rule_builder_provider.dart';
import 'package:raigon_art/features/messaging_automation/connection/providers/connection_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/phone_preview.dart';

class BuilderPreviewPanel extends StatelessWidget {
  const BuilderPreviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final b = context.watch<RuleBuilderProvider>();
    final account = context.select<ConnectionProvider, String>((c) => c.accountName);
    final p = AppPalette.of(context);
    final welcome = b.trigger == AutomationTrigger.welcome;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: p.tileNeutral,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 18, color: AppColors.gold),
              const SizedBox(width: 8),
              Text('Live preview',
                  style: TextStyle(
                      color: p.textPrimary, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.border),
                ),
                child: Text(
                  b.trigger == AutomationTrigger.commentLink
                      ? 'Comment → ${b.channel.messageNoun}'
                      : b.channel.messageNoun,
                  style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          PhonePreview(
            channel: b.channel,
            account: account,
            userText: welcome
                ? 'Hi!'
                : (b.keywords.isEmpty ? '' : b.keywords.first),
            replyText: b.message,
            linkLabel: b.linkLabel,
          ),
        ],
      ),
    );
  }
}
