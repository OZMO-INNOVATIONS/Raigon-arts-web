import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';
import 'package:raigon_art/features/messaging/presentation/screens/inbox_page.dart';
import 'package:raigon_art/features/messaging/provider/messaging_provider.dart';

import 'automations_page.dart';

const _nav = [
  ('Automations', Icons.bolt_rounded),
  ('Messages', Icons.inbox_rounded),
  // ('Channels', Icons.hub_rounded),
];

class MessagingAutomationScreen extends StatefulWidget {
  const MessagingAutomationScreen({super.key});

  @override
  State<MessagingAutomationScreen> createState() =>
      _MessagingAutomationScreenState();
}

class _MessagingAutomationScreenState extends State<MessagingAutomationScreen> {
  late final MessagingAutomationProvider _messagingAutomationProvider;
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _messagingAutomationProvider = MessagingAutomationProvider();
    _initialization = _messagingAutomationProvider.load();
  }

  @override
  void dispose() {
    _messagingAutomationProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(child: CircularProgressIndicator(color: p.accent));
        }

        final s = _messagingAutomationProvider;

        return Material(
          type: MaterialType.transparency,
          child: ListenableBuilder(
            listenable: s,
            builder: (context, _) {
              final pages = [
                AutomationsPage(s: s),
                InboxPage(s: s),
                // ChannelsPage(s: s),
              ];
              return LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 860;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TopBar(s: s, narrow: narrow),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          child: KeyedSubtree(
                            key: ValueKey(s.tab),
                            child: pages[s.tab],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.s, required this.narrow});

  final MessagingAutomationProvider s;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    final tabs = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.chipFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _nav.length; i++)
            Expanded(
              child: _TabItem(s: s, index: i),
            ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        narrow ? 18 : 36,
        narrow ? 14 : 22,
        narrow ? 18 : 36,
        0,
      ),
      child: SizedBox(width: double.infinity, child: tabs),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.s, required this.index});
  final MessagingAutomationProvider s;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final selected = s.tab == index;
    final showBadge = index == 1 && s.convos.isNotEmpty;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => s.setTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? p.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? p.border : Colors.transparent),
            boxShadow: selected ? p.softShadow : null,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _nav[index].$2,
                    size: 18,
                    color: selected ? p.accent : p.textMuted,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _nav[index].$1,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? p.textPrimary : p.textMuted,
                    ),
                  ),
                  if (showBadge) ...[
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: p.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${s.convos.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: p.onAccent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
