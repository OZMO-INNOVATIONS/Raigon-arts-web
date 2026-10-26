import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';
import 'package:raigon_art/features/messaging/models/automation.dart';
import 'package:raigon_art/features/messaging/models/trigger_type.dart';
import 'package:raigon_art/features/messaging/provider/messaging_provider.dart';

import '../widgets/channel_badge.dart';
import '../widgets/channel_style.dart';
import '../widgets/gradient_button.dart';
import '../widgets/page_shell.dart';
import '../widgets/phone_sim.dart';
import '../widgets/section_card.dart';
import 'builder_page.dart';

void openBuilder(
  BuildContext context,
  MessagingAutomationProvider s, {
  Automation? existing,
  TriggerType? preset,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => BuilderPage(s: s, existing: existing, preset: preset),
    ),
  );
}

void showTest(
  BuildContext context,
  MessagingAutomationProvider s,
  Automation a,
) {
  final p = AppPalette.of(context);
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Center(child: PhoneSim(auto: a, s: s)),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: p.surface,
              foregroundColor: p.textPrimary,
            ),
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    ),
  );
}

class AutomationsPage extends StatelessWidget {
  const AutomationsPage({super.key, required this.s});
  final MessagingAutomationProvider s;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final empty = s.automations.isEmpty;
    final firstLoad = empty && s.loadingAutomations;
    final liveCount = s.automations
        .where((a) => a.live && s.accounts[a.channel] != null)
        .length;
    final replies = s.automations.fold<int>(0, (t, a) => t + a.runs);

    return PageShell(
      title: empty ? 'Let’s get started' : 'Automations',
      subtitle: empty
          ? 'Pick a popular first move. You can preview before going live.'
          : 'Replies that run on their own, around the clock.',
      onRefresh: s.loadAutomations,
      action: empty
          ? null
          : GradientButton(
              onPressed: () => openBuilder(context, s),
              icon: Icons.add_rounded,
              label: 'New automation',
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.automationError != null)
            _Banner(
              text: 'Couldn’t sync with the server. Showing saved data.',
              onRetry: s.loadAutomations,
            ),
          if (s.loadingAutomations)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: p.accent,
                  backgroundColor: p.accentSoft,
                ),
              ),
            ),
          if (!firstLoad)
            if (empty)
              _EmptyState(s: s)
            else ...[
              _StatsStrip(
                total: s.automations.length,
                live: liveCount,
                replies: replies,
              ),
              const SizedBox(height: 22),
              for (final a in s.automations) _AutoCard(s: s, a: a),
            ],
        ],
      ),
    );
  }
}

/// One card with three divided stats.
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.total,
    required this.live,
    required this.replies,
  });
  final int total, live, replies;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    Widget stat(
      IconData icon,
      String label,
      String value,
      Color c,
      Color soft,
    ) {
      return Expanded(
        child: Column(
          children: [
            IconTile(icon, size: 38, color: c, background: soft),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    Widget divider() => Container(width: 1, height: 64, color: p.border);

    return SectionCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Row(
        children: [
          stat(
            Icons.layers_rounded,
            'Automations',
            '$total',
            p.tileNeutralIcon,
            p.tileNeutral,
          ),
          divider(),
          stat(Icons.bolt_rounded, 'Live now', '$live', p.mint, p.mintSoft),
          divider(),
          stat(
            Icons.reply_all_rounded,
            'Replies sent',
            '$replies',
            p.sky,
            p.skySoft,
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.onRetry});
  final String text;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: p.amberSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.amber.withValues(alpha: .4)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: p.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: p.textPrimary),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: p.accent),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.s});
  final MessagingAutomationProvider s;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    const gold = Color(0xFFCDBB88);

    Widget step(int n, String t) => Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: gold,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$n',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            t,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: p.brandDeep,
              boxShadow: p.glow,
            ),
            child: Stack(
              children: [
                // One quiet decorative circle, nothing else.
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gold.withValues(alpha: .10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reply to every DM, automatically',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Set a trigger, write the reply, test it in a phone preview, then go live.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .78),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          step(1, 'Channel'),
                          step(2, 'Trigger'),
                          step(3, 'Reply'),
                          step(4, 'Go live'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 16,
                          ),
                        ),
                        onPressed: () => openBuilder(context, s),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text(
                          'Create automation',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'Or start from a popular idea',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth >= 640 ? (c.maxWidth - 18) / 2 : c.maxWidth;
            return Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                _StartCard(
                  width: w,
                  tag: 'Loved by creators',
                  tagColor: ChannelColors.ig,
                  gradient: ChannelColors.igBubble,
                  icon: Icons.camera_alt_rounded,
                  title:
                      'Send a DM with your link every time someone comments on your post',
                  cta: 'Send a link from comments',
                  user: 'link pls!',
                  bot: 'Here it is',
                  onTap: () =>
                      openBuilder(context, s, preset: TriggerType.postComment),
                ),
                _StartCard(
                  width: w,
                  tag: 'Boosts engagement',
                  tagColor: ChannelColors.waDeep,
                  gradient: ChannelColors.waGradient,
                  icon: Icons.chat_rounded,
                  title:
                      'Send customized replies when people DM you specific keywords',
                  cta: 'Respond to your DMs',
                  user: 'INFO',
                  bot: 'Here you go',
                  onTap: () =>
                      openBuilder(context, s, preset: TriggerType.keyword),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({
    required this.width,
    required this.tag,
    required this.tagColor,
    required this.gradient,
    required this.icon,
    required this.title,
    required this.cta,
    required this.user,
    required this.bot,
    required this.onTap,
  });
  final double width;
  final String tag, title, cta, user, bot;
  final Color tagColor;
  final LinearGradient gradient;
  final IconData icon;
  final VoidCallback onTap;

  Widget _bubble(AppPalette p, String t, {bool right = false}) => Align(
    alignment: right ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        gradient: right ? gradient : null,
        color: right ? null : p.surface,
        border: right ? null : Border.all(color: p.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        t,
        style: TextStyle(
          fontSize: 13,
          color: right ? Colors.white : p.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SizedBox(
      width: width,
      child: SectionCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Pill(tag, color: tagColor, soft: tagColor.withValues(alpha: .12), icon: icon),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _bubble(p, user),
                  const SizedBox(height: 10),
                  _bubble(p, bot, right: true),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: GradientButton(label: cta, onPressed: onTap),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoCard extends StatelessWidget {
  const _AutoCard({required this.s, required this.a});
  final MessagingAutomationProvider s;
  final Automation a;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final connected = s.accounts[a.channel] != null;
    final isLive = a.live && connected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Row(
          children: [
            ChannelBadge(a.channel, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          a.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: p.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      isLive
                          ? Pill(
                              'Live',
                              color: p.mint,
                              soft: p.mintSoft,
                              icon: Icons.circle,
                              iconSize: 8,
                            )
                          : Pill(
                              'Paused',
                              color: p.textMuted,
                              soft: p.chipFill,
                              icon: Icons.pause_rounded,
                            ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    a.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Pill(
                        '${a.runs} replies',
                        color: p.textMuted,
                        soft: p.chipFill,
                        icon: Icons.reply_rounded,
                      ),
                      if (!connected)
                        GestureDetector(
                          onTap: () => s.setTab(2),
                          child: Pill(
                            'Channel disconnected · Fix',
                            color: p.amber,
                            soft: p.amberSoft,
                            icon: Icons.link_off_rounded,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Switch(
              value: a.live && connected,
              activeThumbColor: Colors.white,
              activeTrackColor: p.mint,
              onChanged: connected
                  ? (_) async {
                      try {
                        await s.toggleAsync(a);

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Automation status updated.'),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not update automation: $e'),
                          ),
                        );
                      }
                    }
                  : null,
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: p.textMuted),
              onSelected: (v) async {
                if (v == 'test') showTest(context, s, a);
                if (v == 'edit') openBuilder(context, s, existing: a);
                if (v == 'delete') {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete automation?'),
                      content: Text(
                        '“${a.name}” will stop replying and be removed.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Keep'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (ok == true) {
                    try {
                      await s.removeAsync(a);

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Automation deleted.')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Could not delete automation: $e'),
                        ),
                      );
                    }
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'test',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.phone_iphone_rounded),
                    title: Text('Test in preview'),
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_rounded),
                    title: Text('Edit'),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline_rounded),
                    title: Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
