import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/flow_preview.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/automation_rule_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_rule.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_card.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/channel_icon.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/confirm_dialog.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/keyword_chip.dart';

class RuleCard extends StatefulWidget {
  const RuleCard({super.key, required this.rule});
  final AutomationRule rule;

  @override
  State<RuleCard> createState() => _RuleCardState();
}

class _RuleCardState extends State<RuleCard> {
  bool _showFlow = false;

  Future<void> _toggle(bool on) async {
    final r = context.read<AutomationRuleProvider>();
    final ok = await r.toggle(widget.rule, on);
    if (!ok && mounted) {
      AppSnackBar.error(context, r.error ?? 'Could not update automation.');
    }
  }

  Future<void> _onMenu(String action) async {
    final r = context.read<AutomationRuleProvider>();
    if (action == 'test') {
      r.sendTest(widget.rule);
      AppSnackBar.success(context, 'Test reply logged in Activity.');
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete automation?',
      message:
          '"${widget.rule.name}" will stop replying and can\'t be restored.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final ok = await r.delete(widget.rule);
    if (!mounted) return;
    ok
        ? AppSnackBar.success(context, 'Automation deleted.')
        : AppSnackBar.error(context, r.error ?? 'Could not delete automation.');
  }

  @override
  Widget build(BuildContext context) {
    final rule = widget.rule;
    final p = AppPalette.of(context);

    return AutoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChannelIcon(rule.channel, size: 42),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(rule.trigger.icon, size: 14, color: p.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          rule.trigger.shortLabel,
                          style: TextStyle(color: p.textMuted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: rule.active,
                    onChanged: _toggle,
                    activeTrackColor: AppColors.gold,
                    thumbColor: const WidgetStatePropertyAll(Colors.white),
                  ),
                  Text(
                    rule.active ? 'Active' : 'Paused',
                    style: TextStyle(
                      color: rule.active ? AppPalette.statusGreen : p.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: _onMenu,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'test', child: Text('Send test')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.tileNeutral,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              rule.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.textPrimary, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final k in rule.keywords) KeywordChip(k),
              Text(
                '${rule.runs} runs',
                style: TextStyle(color: p.textMuted, fontSize: 12),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _showFlow = !_showFlow),
                icon: Icon(
                  _showFlow ? Icons.expand_less : Icons.account_tree_outlined,
                  size: 16,
                ),
                label: Text(_showFlow ? 'Hide flow' : 'View flow'),
              ),
            ],
          ),
          if (_showFlow) ...[
            const SizedBox(height: 8),
            FlowPreview(
              channel: rule.channel,
              trigger: rule.trigger,
              keywords: rule.keywords,
              hasLink: rule.linkUrl != null,
            ),
          ],
        ],
      ),
    );
  }
}
