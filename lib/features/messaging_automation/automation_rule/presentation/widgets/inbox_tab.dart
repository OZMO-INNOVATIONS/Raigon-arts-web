import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/conversation_view.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/automation_rule_provider.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/empty_state.dart';

class InboxTab extends StatelessWidget {
  const InboxTab({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<AutomationRuleProvider>();
    final p = AppPalette.of(context);

    if (r.threads.isEmpty) {
      return Container(
        decoration: p.card(),
        child: const EmptyState(
          icon: Icons.inbox_outlined,
          title: 'No conversations yet',
          message:
              'When customers message you, their chats and your automatic replies will show up here.',
        ),
      );
    }

    final list = ListView(
      children: [
        for (final t in r.threads)
          ListTile(
            selected: r.selectedThread == t,
            selectedTileColor: AppColors.gold.withValues(alpha: 0.12),
            onTap: () => r.selectThread(t),
            leading: CircleAvatar(
              backgroundColor: p.avatarBg,
              child: Text(t.name[0].toUpperCase(),
                  style: TextStyle(color: p.textPrimary)),
            ),
            title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(t.incoming, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(t.age, style: TextStyle(color: p.textMuted, fontSize: 12)),
          ),
      ],
    );

    return Container(
      height: 560,
      decoration: p.card(),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, c) {
          final selected = r.selectedThread;
          final detail = selected == null
              ? Center(
                  child: Text('Select a conversation',
                      style: TextStyle(color: p.textMuted)),
                )
              : ConversationView(
                  thread: selected,
                  onClose: () => r.selectThread(null),
                );

          if (c.maxWidth >= 720) {
            return Row(
              children: [
                SizedBox(width: 320, child: list),
                VerticalDivider(width: 1, color: p.border),
                Expanded(child: detail),
              ],
            );
          }
          return selected == null ? list : detail;
        },
      ),
    );
  }
}
