import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';
import 'package:raigon_art/features/messaging/models/channel.dart';
import 'package:raigon_art/features/messaging/provider/messaging_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/channel_badge.dart';
import '../widgets/channel_style.dart';
import '../widgets/page_shell.dart';
import '../widgets/section_card.dart';

class ChannelsPage extends StatelessWidget {
  const ChannelsPage({super.key, required this.s});

  final MessagingAutomationProvider s;

  Future<void> _connectChannel(BuildContext context, Channel channel) async {
    try {
      if (channel.isIg) {
        // First check whether Instagram is already connected.
        final username = await s.refreshInstagramConnection();

        if (!context.mounted) return;

        if (username != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Connected to @$username')));
          return;
        }

        // Start Instagram Login through the new Supabase Edge Function.
        final oauthUri = Uri.parse(
          'https://nhqewkbztfmlophtzqmk.supabase.co/'
          'functions/v1/instagram-oauth?action=start',
        );

        final launched = await launchUrl(
          oauthUri,
          mode: LaunchMode.externalApplication,
        );

        if (!context.mounted) return;

        if (!launched) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Instagram login.')),
          );
        }

        return;
      }

      // Keep the existing WhatsApp flow unchanged.
      final account = await s.refreshWhatsAppConnection();

      if (!context.mounted) return;

      if (account != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('WhatsApp connected: $account')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'WhatsApp account details were not returned. '
              'Check your whatsapp_inbox Edge Function.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not connect channel: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final total = Channel.values.length;
    final connected = Channel.values.where((c) => s.accounts[c] != null).length;

    return PageShell(
      title: 'Channels',
      subtitle: 'Connect the accounts Raigon Chat replies from.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            shadow: false,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: connected == total ? p.mintSoft : p.chipFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    connected == total
                        ? Icons.verified_rounded
                        : Icons.link_rounded,
                    size: 20,
                    color: connected == total ? p.mint : p.textMuted,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$connected of $total channels connected',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : connected / total,
                          minHeight: 5,
                          color: p.mint,
                          backgroundColor: p.border,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final c in Channel.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ChannelCard(
                channel: c,
                account: s.accounts[c],
                onConnect: () => _connectChannel(context, c),
                onDisconnect: () => s.disconnect(c),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.channel,
    required this.account,
    required this.onConnect,
    required this.onDisconnect,
  });

  final Channel channel;
  final String? account;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final c = channel;
    final isConnected = account != null;
    final perks = c.isIg
        ? const ['Keyword replies', 'Comment to DM', 'Story replies']
        : const ['Keyword replies', 'Voice notes', 'Shared inbox'];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: p.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(gradient: c.brandGradient),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ChannelBadge(c, size: 52),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16.5,
                              color: p.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isConnected
                                      ? p.mint
                                      : p.textMuted.withValues(alpha: .4),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  isConnected
                                      ? 'Connected · $account'
                                      : 'Not connected',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isConnected ? p.mint : p.textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (isConnected)
                      OutlinedButton(
                        onPressed: onDisconnect,
                        child: const Text('Disconnect'),
                      )
                    else
                      TintedButton(
                        label: 'Connect',
                        gradient: c.brandGradient,
                        color: c.brandColor,
                        onPressed: onConnect,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  c.blurb,
                  style: TextStyle(
                    color: p.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in perks)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: c.brandColor.withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: c.brandColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              t,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.brandColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}