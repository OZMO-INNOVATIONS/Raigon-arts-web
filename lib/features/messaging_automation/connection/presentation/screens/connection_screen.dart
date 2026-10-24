import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/features/messaging_automation/connection/presentation/widgets/channel_option_card.dart';
import 'package:raigon_art/features/messaging_automation/connection/presentation/widgets/connect_step_panel.dart';
import 'package:raigon_art/features/messaging_automation/connection/presentation/widgets/connection_hero.dart';
import 'package:raigon_art/features/messaging_automation/connection/providers/connection_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/channel_icon.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/split_layout.dart';

/// Step 1: choose a channel. Step 2: connect it.
class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ConnectionProvider>();

    if (c.step == ConnectionStep.channelSelect) {
      return SplitLayout(
        left: ConnectionHero(
          leading: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(Icons.forum_rounded, size: 40, color: AppColors.gold),
          ),
          title: 'Where would you\nlike to start?',
          subtitle:
              'Pick a channel to automate. You can connect the others later.',
          footer: (c.connected || c.exploring)
              ? TextButton.icon(
                  onPressed: c.cancelSwitching,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back to dashboard'),
                )
              : null,
        ),
        right: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChannelOptionCard(
              channel: AutomationChannel.instagram,
              subtitle:
                  'Reply to DMs and comments automatically with Instagram Automation.',
              badge: c.connected && c.channel.isInstagram ? 'Connected' : null,
              onTap: () => c.selectChannel(AutomationChannel.instagram),
            ),
            const SizedBox(height: 16),
            ChannelOptionCard(
              channel: AutomationChannel.whatsapp,
              subtitle: 'Reach customers on the most popular messaging app.',
              badge: c.connected && !c.channel.isInstagram ? 'Connected' : null,
              onTap: () => c.selectChannel(AutomationChannel.whatsapp),
            ),
          ],
        ),
      );
    }

    final ig = c.channel.isInstagram;
    return SplitLayout(
      left: ConnectionHero(
        leading: ChannelIcon(c.channel, size: 84),
        title: 'Connect ${c.channel.label}',
        subtitle: ig
            ? 'Use your Instagram account to connect to Raigon Art.'
            : 'Use your WhatsApp Business number to connect to Raigon Art.',
        footer: TextButton.icon(
          onPressed: c.backToChannels,
          icon: const Icon(Icons.chevron_left, size: 18),
          label: const Text('Choose another channel'),
        ),
      ),
      right: const ConnectStepPanel(),
    );
  }
}
