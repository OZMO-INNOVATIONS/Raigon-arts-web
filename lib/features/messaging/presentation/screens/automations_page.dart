import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:raigon_art/core/constants/asset_constants.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/features/messaging/models/automation.dart';
import 'package:raigon_art/features/messaging/models/channel.dart';
import 'package:raigon_art/features/messaging/models/trigger_type.dart';
import 'package:raigon_art/features/messaging/provider/messaging_provider.dart';

import '../widgets/channel_badge.dart';
import '../widgets/channel_style.dart';
import '../widgets/gradient_button.dart';
import '../widgets/page_shell.dart';
import '../widgets/phone_sim.dart';
import '../widgets/section_card.dart';
import 'builder_page.dart';

// Logger and navigation helpers

void _log(String message, {Object? error, StackTrace? stackTrace}) {
  if (!kDebugMode) return;
  debugPrint('[AutomationsPage] $message');
  if (error != null) {
    debugPrint('[AutomationsPage] ERROR: $error');
  }
  if (stackTrace != null) {
    debugPrintStack(stackTrace: stackTrace);
  }
}

// Opens builder screen for creating or editing an automation.
void openBuilder(
  BuildContext context,
  MessagingAutomationProvider s, {
  Automation? existing,
  TriggerType? preset,
}) {
  _log(
    'Opening builder (existing: ${existing?.id ?? "none"}, preset: ${preset?.name ?? "none"})',
  );
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => BuilderPage(s: s, existing: existing, preset: preset),
    ),
  );
}

// Displays interactive phone simulator dialog to test an automation.
void showTest(
  BuildContext context,
  MessagingAutomationProvider s,
  Automation a,
) {
  _log('Showing test preview for: ${a.name} (${a.id})');
  final p = AppPalette.of(context);
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Center(
            child: PhoneSim(auto: a, s: s),
          ),
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

// Maps trigger types to display labels.
String _triggerLabel(TriggerType t) {
  switch (t) {
    case TriggerType.keyword:
      return 'Keyword';
    case TriggerType.anyMessage:
      return 'Any message';
    case TriggerType.postComment:
      return 'Post comment';
    case TriggerType.storyReply:
      return 'Story reply';
  }
}

// Main automations page

class AutomationsPage extends StatefulWidget {
  const AutomationsPage({super.key, required this.s});
  final MessagingAutomationProvider s;

  @override
  State<AutomationsPage> createState() => _AutomationsPageState();
}

class _AutomationsPageState extends State<AutomationsPage> {
  final TextEditingController _search = TextEditingController();
  int _status = 0; // 0 = all, 1 = active, 2 = paused
  Channel? _channel; // null = all channels
  String _query = '';

  MessagingAutomationProvider get s => widget.s;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _isLive(Automation a) => a.live && s.accounts[a.channel] != null;

  List<Automation> _filtered() {
    final q = _query.trim().toLowerCase();
    return s.automations.where((a) {
      final live = _isLive(a);
      if (_status == 1 && !live) return false;
      if (_status == 2 && live) return false;
      if (_channel != null && a.channel != _channel) return false;
      if (q.isEmpty) return true;
      return a.name.toLowerCase().contains(q) ||
          a.summary.toLowerCase().contains(q) ||
          a.keywords.any((k) => k.toLowerCase().contains(q));
    }).toList();
  }

  void _clearFilters() {
    _log('Clearing filters');
    setState(() {
      _status = 0;
      _channel = null;
      _query = '';
      _search.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final empty = s.automations.isEmpty;
    final firstLoad = empty && s.loadingAutomations;
    final shown = _filtered();

    return PageShell(
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
          _ConnectPanel(s: s),
          const SizedBox(height: 22),
          if (!firstLoad)
            if (empty)
              _EmptyState(s: s)
            else ...[
              _FilterBar(
                status: _status,
                channel: _channel,
                controller: _search,
                onStatus: (v) => setState(() => _status = v),
                onChannel: (v) => setState(() => _channel = v),
                onQuery: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 16),
              if (shown.isEmpty)
                _NoMatches(onClear: _clearFilters)
              else
                for (final a in shown) _AutoCard(s: s, a: a),
            ],
        ],
      ),
    );
  }
}

// Connect channels panel

class _ConnectPanel extends StatelessWidget {
  const _ConnectPanel({required this.s});
  final MessagingAutomationProvider s;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect Your Channels',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Link your Instagram and WhatsApp to start automating conversations.',
          style: TextStyle(color: p.textMuted, fontSize: 13.5),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, c) {
            Widget card(Channel ch) => _ChannelCard(
              channel: ch,
              account: s.accounts[ch],
              onConnect: () async {
                _log(
                  'Connecting channel ${ch.name} (switchAccount: ${ch.isIg && s.accounts[ch] != null})',
                );
                try {
                  await s.connectChannel(
                    context,
                    ch,
                    switchAccount: ch.isIg && s.accounts[ch] != null,
                  );
                } catch (e, stack) {
                  _log(
                    'Failed to connect ${ch.name}',
                    error: e,
                    stackTrace: stack,
                  );
                  if (context.mounted) {
                    AppSnackBar.error(context, 'Could not connect channel: $e');
                  }
                }
              },
              onDisconnect: () {
                _log('Disconnecting channel ${ch.name}');
                try {
                  s.disconnect(ch);
                  if (context.mounted) {
                    AppSnackBar.success(
                      context,
                      '${ch.isIg ? 'Instagram' : 'WhatsApp'} disconnected.',
                    );
                  }
                } catch (e, stack) {
                  _log(
                    'Failed to disconnect ${ch.name}',
                    error: e,
                    stackTrace: stack,
                  );
                  if (context.mounted) {
                    AppSnackBar.error(
                      context,
                      'Could not disconnect channel: $e',
                    );
                  }
                }
              },
            );

            final wa = card(Channel.whatsapp);
            final ig = card(Channel.instagram);
            const why = _WhyConnect();

            if (c.maxWidth >= 980) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: wa),
                    const SizedBox(width: 14),
                    Expanded(flex: 5, child: ig),
                    const SizedBox(width: 14),
                    const Expanded(flex: 4, child: why),
                  ],
                ),
              );
            }

            if (c.maxWidth >= 700) {
              return Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: wa),
                        const SizedBox(width: 14),
                        Expanded(child: ig),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  why,
                ],
              );
            }

            return Column(
              children: [
                wa,
                const SizedBox(height: 14),
                ig,
                const SizedBox(height: 14),
                why,
              ],
            );
          },
        ),
      ],
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
    final connected = account != null;
    final title = c.isIg ? 'Instagram' : 'WhatsApp Business';
    final accountText = connected
        ? (c.isIg && !account!.startsWith('@') ? '@$account' : account!)
        : 'Not connected';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
        boxShadow: p.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChannelBadge(c, size: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    connected
                        ? Pill('Connected', color: p.mint, soft: p.mintSoft)
                        : Pill(
                            'Not connected',
                            color: p.textMuted,
                            soft: p.chipFill,
                          ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  c.blurb,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.textMuted,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      connected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 15,
                      color: connected ? p.mint : p.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        accountText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: connected ? p.textPrimary : p.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Spacer(),
                    connected
                        ? _PillButton(
                            label: c.isIg ? 'Switch account' : 'Disconnect',
                            icon: c.isIg
                                ? Icons.swap_horiz_rounded
                                : Icons.link_off_rounded,
                            foreground: c.isIg
                                ? p.onBrand
                                : AppPalette.statusRed,
                            background: c.isIg
                                ? null
                                : AppPalette.statusRed.withValues(alpha: .10),
                            gradient: c.isIg ? p.brand : null,
                            onPressed: c.isIg ? onConnect : onDisconnect,
                          )
                        : _PillButton(
                            label: 'Connect',
                            icon: Icons.link_rounded,
                            foreground: p.onBrand,
                            gradient: p.brand,
                            onPressed: onConnect,
                          ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: connected ? null : onConnect,
              child: Tooltip(
                message: 'Check connection',
                child: Icon(Icons.chevron_right_rounded, color: p.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.onPressed,
    this.background,
    this.gradient,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color? background;
  final Gradient? gradient;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: background,
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: foreground),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WhyConnect extends StatelessWidget {
  const _WhyConnect();

  static const List<String> _items = [
    'Auto-reply to messages',
    'Trigger workflows & automations',
    'Collect customer data',
    'Track performance & analytics',
  ];

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: p.isDark ? .6 : .7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.mint.withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: p.chipFill,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.border),
                ),
                child: Icon(Icons.link_rounded, size: 19, color: p.textPrimary),
              ),
              const SizedBox(width: 12),
              Text(
                'Why Connect?',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final t in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: p.mint),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: TextStyle(fontSize: 12.5, color: p.textMuted),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Filter bar and controls

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.status,
    required this.channel,
    required this.controller,
    required this.onStatus,
    required this.onChannel,
    required this.onQuery,
  });

  final int status;
  final Channel? channel;
  final TextEditingController controller;
  final ValueChanged<int> onStatus;
  final ValueChanged<Channel?> onChannel;
  final ValueChanged<String> onQuery;

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(26),
    borderSide: BorderSide(color: c),
  );

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    final segmented = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilterSegment(
            selected: status == 0,
            label: 'All',
            onTap: () => onStatus(0),
          ),
          _FilterSegment(
            selected: status == 1,
            label: 'Active',
            dotColor: p.mint,
            onTap: () => onStatus(1),
          ),
          _FilterSegment(
            selected: status == 2,
            label: 'Paused',
            dotColor: p.textMuted,
            onTap: () => onStatus(2),
          ),
        ],
      ),
    );

    final search = TextField(
      controller: controller,
      onChanged: onQuery,
      decoration: InputDecoration(
        hintText: 'Search automations…',
        hintStyle: TextStyle(color: p.textMuted, fontSize: 13.5),
        prefixIcon: Icon(Icons.search_rounded, size: 20, color: p.textMuted),
        filled: true,
        fillColor: p.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: _border(p.border),
        enabledBorder: _border(p.border),
        focusedBorder: _border(p.accent),
      ),
    );

    final filter = PopupMenuButton<int>(
      tooltip: 'Filter by channel',
      onSelected: (v) {
        _log('Filtering channel by value: $v');
        onChannel(
          v == 0 ? null : (v == 1 ? Channel.instagram : Channel.whatsapp),
        );
      },
      itemBuilder: (_) => const <PopupMenuEntry<int>>[
        PopupMenuItem<int>(value: 0, child: Text('All channels')),
        PopupMenuItem<int>(value: 1, child: Text('Instagram')),
        PopupMenuItem<int>(value: 2, child: Text('WhatsApp')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: channel == null ? p.surface : p.accentSoft,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: channel == null ? p.border : p.accent.withValues(alpha: .4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_outlined, size: 18, color: p.textPrimary),
            const SizedBox(width: 8),
            Text(
              channel == null
                  ? 'Filter'
                  : (channel == Channel.instagram ? 'Instagram' : 'WhatsApp'),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: p.textMuted,
            ),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 760) {
          return Row(
            children: [
              segmented,
              const Spacer(),
              SizedBox(width: 320, child: search),
              const SizedBox(width: 12),
              filter,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            segmented,
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 10),
                filter,
              ],
            ),
          ],
        );
      },
    );
  }
}

class _FilterSegment extends StatelessWidget {
  const _FilterSegment({
    required this.selected,
    required this.label,
    required this.onTap,
    this.dotColor,
  });

  final bool selected;
  final String label;
  final Color? dotColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final bg = p.isDark ? p.accent : AppColors.black;
    final fg = selected
        ? (p.isDark ? AppColors.black : Colors.white)
        : p.textMuted;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? bg : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? dotColor
                        : dotColor!.withValues(alpha: .8),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SectionCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 32, color: p.textMuted),
            const SizedBox(height: 10),
            Text(
              'No automations match your filters',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(foregroundColor: p.accent),
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

// Sync error banner

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
            onPressed: () async {
              _log('Retrying automations load from error banner');
              try {
                await onRetry();
              } catch (e, stack) {
                _log('Retry failed', error: e, stackTrace: stack);
                if (context.mounted) {
                  AppSnackBar.error(context, 'Could not sync automations: $e');
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: p.accent),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// Empty state and starters

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.s});
  final MessagingAutomationProvider s;

  static const Color _gold = Color(0xFFCDBB88);

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(gradient: p.brandDeep, boxShadow: p.glow),
            child: Stack(
              children: [
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _gold.withValues(alpha: .10),
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
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StepBadge(number: 1, title: 'Channel'),
                          _StepBadge(number: 2, title: 'Trigger'),
                          _StepBadge(number: 3, title: 'Reply'),
                          _StepBadge(number: 4, title: 'Go live'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _gold,
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
                  icon: AssetConstants.instagram,
                  title: 'Send a DM with your link every time someone comments on your post',
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
                  icon: AssetConstants.whatsApp,
                  title: 'Send customized replies when people DM you specific keywords',
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

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.number, required this.title});
  final int number;
  final String title;

  static const Color _gold = Color(0xFFCDBB88);

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: _gold,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
  final String icon;
  final VoidCallback onTap;

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
            SvgPicture.asset(icon, width: 20, height: 20, fit: BoxFit.contain),
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
                  _ChatPreviewBubble(text: user, isSender: false),
                  const SizedBox(height: 10),
                  _ChatPreviewBubble(
                    text: bot,
                    isSender: true,
                    gradient: gradient,
                  ),
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

class _ChatPreviewBubble extends StatelessWidget {
  const _ChatPreviewBubble({
    required this.text,
    required this.isSender,
    this.gradient,
  });

  final String text;
  final bool isSender;
  final LinearGradient? gradient;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: isSender ? gradient : null,
          color: isSender ? null : p.surface,
          border: isSender ? null : Border.all(color: p.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isSender ? Colors.white : p.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// Automation item card

class _AutoCard extends StatelessWidget {
  const _AutoCard({required this.s, required this.a});

  final MessagingAutomationProvider s;
  final Automation a;

  Widget _buildVerticalDivider(Color borderColor) => Container(
    width: 1,
    height: 40,
    margin: const EdgeInsets.symmetric(horizontal: 14),
    color: borderColor,
  );

  Widget _buildInfo(
    BuildContext context,
    AppPalette p,
    bool connected,
    bool isLive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              a.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: p.textPrimary,
              ),
            ),
            isLive
                ? Pill(
                    'Active',
                    color: p.mint,
                    soft: p.mintSoft,
                    icon: Icons.circle,
                    iconSize: 7,
                  )
                : Pill(
                    'Paused',
                    color: p.textMuted,
                    soft: p.chipFill,
                    icon: Icons.pause_rounded,
                  ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          a.summary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: p.textMuted, fontSize: 12.5, height: 1.4),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Tag(a.channel.isIg ? 'Instagram' : 'WhatsApp'),
            _Tag(_triggerLabel(a.trigger)),
            for (final k in a.keywords.take(2)) _Tag(k),
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
    );
  }

  Widget _buildSwitch(
    BuildContext context,
    AppPalette p,
    bool connected,
    bool isLive,
  ) {
    return Switch(
      value: isLive,
      activeThumbColor: Colors.white,
      activeTrackColor: p.mint,
      onChanged: connected
          ? (value) async {
              _log('Toggling automation "${a.name}" (id: ${a.id}) to $value');
              try {
                await s.toggleAsync(a);
                if (!context.mounted) return;
                AppSnackBar.success(context, 'Automation status updated.');
              } catch (e, stack) {
                _log(
                  'Failed to toggle automation "${a.name}"',
                  error: e,
                  stackTrace: stack,
                );
                if (!context.mounted) return;
                AppSnackBar.error(context, 'Could not update automation: $e');
              }
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final connected = s.accounts[a.channel] != null;
    final isLive = a.live && connected;

    final tile = SizedBox(
      width: 60,
      height: 60,
      child: Center(child: ChannelBadge(a.channel, size: 60)),
    );

    final info = _buildInfo(context, p, connected, isLive);

    final statTrigger = _Stat(
      icon: Icons.bolt_rounded,
      value: _triggerLabel(a.trigger),
      label: 'Trigger',
    );

    final statStatus = _Stat(
      icon: Icons.power_settings_new_rounded,
      value: isLive ? 'Live' : 'Paused',
      label: 'Status',
    );

    final toggle = _buildSwitch(context, p, connected, isLive);
    final menu = _buildMenu(context, p);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SectionCard(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(20, 18, 10, 18),
        child: LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= 900) {
              return Row(
                children: [
                  tile,
                  const SizedBox(width: 20),
                  Expanded(child: info),
                  SizedBox(width: 128, child: statTrigger),
                  _buildVerticalDivider(p.border),
                  SizedBox(width: 110, child: statStatus),
                  const SizedBox(width: 20),
                  toggle,
                  menu,
                ],
              );
            }

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tile,
                    const SizedBox(width: 16),
                    Expanded(child: info),
                    toggle,
                    menu,
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: p.border),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    children: [
                      Expanded(child: statTrigger),
                      _buildVerticalDivider(p.border),
                      Expanded(child: statStatus),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, AppPalette p) {
    return PopupMenuButton<String>(
      tooltip: 'Automation options',
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: p.border),
      ),
      icon: Icon(Icons.more_vert_rounded, color: p.textMuted),
      onSelected: (v) async {
        if (v == 'test') {
          showTest(context, s, a);
        } else if (v == 'edit') {
          openBuilder(context, s, existing: a);
        } else if (v == 'delete') {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: p.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: p.border),
              ),
              title: Text(
                'Delete automation?',
                style: TextStyle(
                  color: p.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Text(
                '“${a.name}” will stop replying and be removed.',
                style: TextStyle(color: p.textMuted),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(foregroundColor: p.textMuted),
                  child: const Text('Keep'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(
                    foregroundColor: AppPalette.statusRed,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );

          if (ok == true) {
            _log('Deleting automation "${a.name}" (id: ${a.id})');
            try {
              await s.removeAsync(a);
              if (!context.mounted) return;
              AppSnackBar.success(context, 'Automation deleted.');
            } catch (e, stack) {
              _log(
                'Failed to delete automation "${a.name}"',
                error: e,
                stackTrace: stack,
              );
              if (!context.mounted) return;
              AppSnackBar.error(context, 'Could not delete automation: $e');
            }
          }
        }
      },
      itemBuilder: (_) => [
        _popupItem(
          value: 'test',
          icon: Icons.phone_iphone_rounded,
          label: 'Test in preview',
          p: p,
        ),
        _popupItem(
          value: 'edit',
          icon: Icons.edit_rounded,
          label: 'Edit',
          p: p,
        ),
        _popupItem(
          value: 'delete',
          icon: Icons.delete_outline_rounded,
          label: 'Delete',
          p: p,
          danger: true,
        ),
      ],
    );
  }

  PopupMenuItem<String> _popupItem({
    required String value,
    required IconData icon,
    required String label,
    required AppPalette p,
    bool danger = false,
  }) {
    final color = danger ? AppPalette.statusRed : p.textPrimary;

    return PopupMenuItem<String>(
      value: value,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Shared micro widgets

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: p.chipFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: p.textMuted,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        Icon(icon, size: 19, color: p.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 12, color: p.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}
