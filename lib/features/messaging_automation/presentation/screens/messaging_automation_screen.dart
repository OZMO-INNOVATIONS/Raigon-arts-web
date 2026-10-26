import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/features/messaging_automation/presentation/screens/automation_ui.dart';
import 'package:raigon_art/features/messaging_automation/presentation/screens/flow_canvas.dart';
import 'package:raigon_art/features/messaging_automation/providers/messaging_automation_provider.dart';
import 'package:raigon_art/features/messaging_automation/presentation/screens/phone_preview.dart';
import 'package:remixicon/remixicon.dart';

class MessagingAutomationScreen extends StatelessWidget {
  const MessagingAutomationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagingAutomationProvider>(
      builder: (context, p, _) {
        final Widget body = switch (p.stage) {
          AutomationStage.channelSelect => const _ChannelSelectView(),
          AutomationStage.connect => const _ConnectView(),
          AutomationStage.firstMove => const _FirstMoveView(),
          AutomationStage.builder => const _BuilderView(),
          AutomationStage.dashboard => const _DashboardView(),
        };
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(key: ValueKey(p.stage), child: body),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Shared two-pane layout (left hero, right content)
// ═══════════════════════════════════════════════════════════
class _TwoPane extends StatelessWidget {
  const _TwoPane({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 820;
        final h = c.maxHeight.isFinite ? c.maxHeight : 640.0;
        if (wide) {
          return SingleChildScrollView(
            child: SizedBox(
              height: h < 560 ? 560 : h,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      color: AutoInk.panel(context),
                      padding: const EdgeInsets.all(48),
                      alignment: Alignment.centerLeft,
                      child: left,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: right,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [left, const SizedBox(height: 28), right],
          ),
        );
      },
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: 84,
    height: 84,
    decoration: BoxDecoration(
      color: const Color(0xFFD9F2F0),
      borderRadius: BorderRadius.circular(26),
    ),
    child: child,
  );
}

// ═══════════════════════════════════════════════════════════
// 1. Where would you like to start?
// ═══════════════════════════════════════════════════════════
class _ChannelSelectView extends StatelessWidget {
  const _ChannelSelectView();

  @override
  Widget build(BuildContext context) {
    final p = context.read<MessagingAutomationProvider>();
    return _TwoPane(
      left: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroBadge(
            child: Icon(RemixIcons.message_3_line, size: 40, color: AutoInk.purple),
          ),
          const SizedBox(height: 28),
          Text(
            'Where would you\nlike to start?',
            style: TextStyle(
              color: AutoInk.text(context),
              fontSize: 38,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Don't worry, you can connect other channels later.",
            style: TextStyle(color: AutoInk.muted(context), fontSize: 15),
          ),
        ],
      ),
      right: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChannelCard(
            channel: AutomationChannel.instagram,
            subtitle: 'Reply to DMs and comments automatically with Instagram Automation.',
            onTap: () => p.selectChannel(AutomationChannel.instagram),
          ),
          const SizedBox(height: 16),
          _ChannelCard(
            channel: AutomationChannel.whatsapp,
            subtitle: 'Reach customers on the most popular messaging app.',
            onTap: () => p.selectChannel(AutomationChannel.whatsapp),
          ),
        ],
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.channel,
    required this.subtitle,
    required this.onTap,
  });
  final AutomationChannel channel;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: AutoCard(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          ChannelIcon(channel, size: 52),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.label,
                  style: TextStyle(
                    color: AutoInk.text(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: AutoInk.muted(context), fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(RemixIcons.arrow_right_s_line, color: AutoInk.muted(context)),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
// 2. Connect channel
// ═══════════════════════════════════════════════════════════
class _ConnectView extends StatefulWidget {
  const _ConnectView();
  @override
  State<_ConnectView> createState() => _ConnectViewState();
}

class _ConnectViewState extends State<_ConnectView> {
  bool _more = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MessagingAutomationProvider>();
    final ig = p.channel == AutomationChannel.instagram;
    final options = ig
        ? ['Connect Via Instagram', 'Meta Business Suite']
        : ['Use WhatsApp Cloud API number', 'Use WhatsApp Business app'];

    return _TwoPane(
      left: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChannelIcon(p.channel, size: 84),
          const SizedBox(height: 28),
          Text(
            'Connect ${p.channel.label}',
            style: TextStyle(
              color: AutoInk.text(context),
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ig
                ? 'Use your Instagram account to connect to Raigon Art.'
                : 'Use your WhatsApp Business number to connect to Raigon Art.',
            style: TextStyle(color: AutoInk.muted(context), fontSize: 15),
          ),
          const SizedBox(height: 40),
          TextButton.icon(
            onPressed: p.backToChannels,
            icon: const Icon(RemixIcons.arrow_left_s_line, size: 18),
            label: const Text('Choose Another Channel'),
          ),
        ],
      ),
      right: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A few steps in',
            style: TextStyle(
              color: AutoInk.text(context),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll take you to Meta to connect. Just set your permissions, and your "
            '${p.channel.label} account will be linked to Raigon Art.',
            style: TextStyle(color: AutoInk.muted(context), height: 1.4),
          ),
          const SizedBox(height: 18),
          AutoButton(
            label: ig ? 'Connect Via Meta' : 'Connect WhatsApp Business',
            expand: true,
            loading: p.connecting,
            onPressed: p.connect,
          ),
          const SizedBox(height: 14),
          AutoPanel(
            child: Row(
              children: [
                const Icon(RemixIcons.shield_check_line, color: AutoInk.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Official Meta Business Platform connection',
                    style: TextStyle(color: AutoInk.text(context)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => setState(() => _more = !_more),
            icon: Icon(_more ? RemixIcons.arrow_up_s_line : RemixIcons.arrow_down_s_line, size: 18),
            label: const Text('See More Options'),
          ),
          if (_more)
            for (final o in options) ...[
              AutoButton(
                label: o,
                filled: false,
                expand: true,
                onPressed: p.connect,
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 6),
          Text(
            'Automated customer messaging connected via Raigon Arts API.',
            style: TextStyle(color: AutoInk.muted(context), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 3. Pick a popular first move
// ═══════════════════════════════════════════════════════════
class _FirstMoveView extends StatelessWidget {
  const _FirstMoveView();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MessagingAutomationProvider>();
    final ig = p.channel == AutomationChannel.instagram;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: p.skipToDashboard,
              child: const Text('Look Around First'),
            ),
          ),
          const SizedBox(height: 24),
          Text('Welcome,', style: TextStyle(color: AutoInk.muted(context))),
          const SizedBox(height: 8),
          Text(
            "Let's start! Pick a popular first move:",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AutoInk.text(context),
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              if (ig)
                _MoveCard(
                  eyebrow: 'Loved by Creators',
                  title: 'Send a DM with your link every time someone comments on your post',
                  button: 'Send A Link From Comments',
                  kind: _Mini.comment,
                  onTap: () => p.startBuilder(AutomationTrigger.commentLink),
                )
              else
                _MoveCard(
                  eyebrow: 'Great first impression',
                  title: 'Greet every new customer the moment they message you',
                  button: 'Send A Welcome Message',
                  kind: _Mini.welcome,
                  onTap: () => p.startBuilder(AutomationTrigger.welcome),
                ),
              _MoveCard(
                eyebrow: 'Boosts engagement',
                title:
                    'Send customized replies when people ${ig ? 'DM' : 'message'} you specific keywords',
                button: 'Respond To All Your ${ig ? 'DMs' : 'Messages'}',
                kind: _Mini.keyword,
                onTap: () => p.startBuilder(AutomationTrigger.dmKeyword),
              ),
            ],
          ),
          const SizedBox(height: 36),
          const Wrap(
            spacing: 36,
            runSpacing: 16,
            children: [
              _Perk(
                RemixIcons.fire_line,
                'Most popular\nautomations',
              ),
              _Perk(RemixIcons.time_line, 'Publish in 3 minutes'),
              _Perk(RemixIcons.edit_line, 'Preview first, go live\nwhen ready'),
            ],
          ),
        ],
      ),
    );
  }
}

enum _Mini { comment, keyword, welcome }

class _MoveCard extends StatelessWidget {
  const _MoveCard({
    required this.eyebrow,
    required this.title,
    required this.button,
    required this.kind,
    required this.onTap,
  });
  final String eyebrow, title, button;
  final _Mini kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 400,
    child: AutoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: TextStyle(color: AutoInk.muted(context), fontSize: 13),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AutoInk.text(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _MiniIllustration(kind),
          const SizedBox(height: 18),
          AutoButton(label: button, onPressed: onTap),
        ],
      ),
    ),
  );
}

class _MiniIllustration extends StatelessWidget {
  const _MiniIllustration(this.kind);
  final _Mini kind;

  Widget _b(String t, {bool right = false, bool pill = false}) => Align(
    alignment: right ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: pill ? const Color(0xFFD7B8E6) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pill) const Icon(RemixIcons.link, size: 16),
          if (pill) const SizedBox(width: 6),
          Text(t, style: const TextStyle(color: Colors.black87, fontSize: 13)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final rows = switch (kind) {
      _Mini.comment => [
        _b('link pls! 🖤'),
        _b('Here it is 👇', right: true),
        _b('Link', right: true, pill: true),
      ],
      _Mini.keyword => [
        _b('INFO'),
        _b('Here you go ✨', right: true),
        _b('Link 1', right: true, pill: true),
      ],
      _Mini.welcome => [
        _b('Hi!'),
        _b('Welcome to Raigon Art 👋', right: true),
        _b('Browse frames', right: true, pill: true),
      ],
    };
    return Container(
      height: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AutoInk.lavender,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1D8F3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: rows,
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AutoInk.card(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AutoInk.line(context)),
        ),
        child: Icon(icon, color: AutoInk.purple, size: 22),
      ),
      const SizedBox(width: 10),
      Text(
        label,
        style: TextStyle(color: AutoInk.muted(context), fontSize: 12),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════
// 4. Builder: keyword → reply, with live phone preview
// ═══════════════════════════════════════════════════════════
class _BuilderView extends StatelessWidget {
  const _BuilderView();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MessagingAutomationProvider>();
    final isWelcome = p.draftTrigger == AutomationTrigger.welcome;
    final kws = p.draftKeywordList;

    final preview = Container(
      color: AutoInk.panel(context),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Text('Preview', style: TextStyle(color: AutoInk.muted(context))),
              const Spacer(),
              AutoButton(
                label: 'Go Live',
                filled: false,
                onPressed: () {
                  if (!p.canGoLive) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isWelcome
                              ? 'Write a message first'
                              : 'Add a keyword and a message first',
                        ),
                      ),
                    );
                    return;
                  }
                  p.goLive();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          PhonePreview(
            channel: p.channel,
            account: p.accountName,
            userText: isWelcome ? 'Hi!' : (kws.isEmpty ? '' : kws.first),
            replyText: p.draftMessage,
            linkLabel: p.draftLinkLabel,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: AutoInk.card(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AutoInk.line(context)),
            ),
            child: Text(
              p.draftTrigger == AutomationTrigger.commentLink
                  ? 'Comment → DM'
                  : 'DM',
              style: TextStyle(
                color: AutoInk.text(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 860;
        final left = _BuilderLeft(key: ValueKey(p.draftTrigger));
        if (wide) {
          return Row(
            children: [
              SizedBox(width: 440, child: left),
              Expanded(child: SingleChildScrollView(child: preview)),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 760, child: left),
              preview,
            ],
          ),
        );
      },
    );
  }
}

class _BuilderLeft extends StatefulWidget {
  const _BuilderLeft({super.key});
  @override
  State<_BuilderLeft> createState() => _BuilderLeftState();
}

class _BuilderLeftState extends State<_BuilderLeft> {
  late final TextEditingController _kw;
  late final TextEditingController _msg;

  @override
  void initState() {
    super.initState();
    final p = context.read<MessagingAutomationProvider>();
    _kw = TextEditingController(text: p.draftKeywords);
    _msg = TextEditingController(text: p.draftMessage);
  }

  @override
  void dispose() {
    _kw.dispose();
    _msg.dispose();
    super.dispose();
  }

  Widget _h(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 8),
    child: Text(
      t,
      style: TextStyle(
        color: AutoInk.text(context),
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Future<void> _linkDialog(MessagingAutomationProvider p) async {
    final label = TextEditingController(text: p.draftLinkLabel ?? '');
    final url = TextEditingController(text: p.draftLinkUrl ?? 'https://');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: label,
              decoration: const InputDecoration(
                labelText: 'Button label (e.g. Shop frames)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: url,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (label.text.trim().isNotEmpty) {
                p.setLink(label.text.trim(), url.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    label.dispose();
    url.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MessagingAutomationProvider>();
    final t = p.draftTrigger;
    final ig = p.channel == AutomationChannel.instagram;

    final title = switch (t) {
      AutomationTrigger.dmKeyword =>
        'When someone ${ig ? 'DMs' : 'messages'} you with',
      AutomationTrigger.commentLink =>
        'When someone comments on your post with',
      AutomationTrigger.welcome =>
        'When someone messages you for the first time',
    };

    const optionInfo = {
      DraftOption.followUp: 'Follow up after 24h to re-engage and build trust',
      DraftOption.askEmail:
          'Ask for emails in chat to keep in touch beyond social',
      DraftOption.businessHours: 'Only auto-reply during business hours',
      DraftOption.humanHandover: 'Hand over to a human when no keyword matches',
    };

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: p.closeBuilder,
              icon: const Icon(RemixIcons.arrow_left_line),
            ),
            const SizedBox(width: 4),
            ChannelIcon(p.channel, size: 28),
            const SizedBox(width: 8),
            Text(
              'New ${p.channel.label} automation',
              style: TextStyle(color: AutoInk.muted(context), fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _h(title),
        if (t != AutomationTrigger.welcome)
          AutoPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (t == AutomationTrigger.commentLink) ...[
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Any post'),
                        selected: p.draftAnyPost,
                        onSelected: (_) => p.setAnyPost(true),
                      ),
                      ChoiceChip(
                        label: const Text('Specific post'),
                        selected: !p.draftAnyPost,
                        onSelected: (_) => p.setAnyPost(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'a specific word or words',
                  style: TextStyle(color: AutoInk.text(context)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _kw,
                  onChanged: p.setKeywords,
                  decoration: const InputDecoration(
                    hintText: 'Enter a word or multiple',
                    filled: true,
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use commas to separate words',
                  style: TextStyle(color: AutoInk.muted(context), fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'For example:',
                      style: TextStyle(
                        color: AutoInk.muted(context),
                        fontSize: 13,
                      ),
                    ),
                    for (final w in const ['Price', 'Link', 'Shop'])
                      AutoChip(
                        w,
                        onTap: () {
                          _kw.text = w;
                          p.setKeywords(w);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        _h("They'll get a ${ig ? 'DM' : 'message'} back from you with a link"),
        AutoPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'a ${ig ? 'DM' : 'message'} with a link',
                style: TextStyle(color: AutoInk.text(context)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _msg,
                onChanged: p.setMessage,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Write a message',
                  filled: true,
                  border: OutlineInputBorder(),
                ),
              ),
              if (p.draftLinkLabel != null)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(RemixIcons.link, color: AutoInk.blue),
                  title: Text(p.draftLinkLabel!),
                  subtitle: Text(
                    p.draftLinkUrl ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(RemixIcons.close_line),
                    onPressed: () => p.setLink(null, null),
                  ),
                ),
              const SizedBox(height: 4),
              AutoButton(
                label: p.draftLinkLabel == null ? 'Add A Link' : 'Edit Link',
                icon: RemixIcons.add_line,
                filled: false,
                expand: true,
                onPressed: () => _linkDialog(p),
              ),
            ],
          ),
        ),
        _h('Other things to automate'),
        for (final o in DraftOption.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AutoPanel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      optionInfo[o]!,
                      style: TextStyle(
                        color: AutoInk.text(context),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Switch(
                    value: p.draftOptions.contains(o),
                    onChanged: (v) => p.toggleOption(o, v),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 5. Dashboard: Automations · Inbox · Flow builder · Activity
// ═══════════════════════════════════════════════════════════
class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MessagingAutomationProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 14,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Messaging Automation',
                    style: TextStyle(
                      color: AutoInk.text(context),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage customer conversations in one place.',
                    style: TextStyle(
                      color: AutoInk.muted(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ConnectionChip(p),
                  const SizedBox(width: 12),
                  AutoButton(
                    label: 'New automation',
                    icon: RemixIcons.add_line,
                    onPressed: () =>
                        p.startBuilder(AutomationTrigger.dmKeyword),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          _TabBar(p),
          const SizedBox(height: 20),
          switch (p.tab) {
            DashboardTab.automations => const _AutomationsTab(),
            DashboardTab.inbox => const _InboxTab(),
            DashboardTab.flow => const FlowCanvas(),
            DashboardTab.activity => const _ActivityTab(),
          },
        ],
      ),
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  const _ConnectionChip(this.p);
  final MessagingAutomationProvider p;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: p.backToChannels,
    child: Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
      decoration: BoxDecoration(
        border: Border.all(color: AutoInk.line(context)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChannelIcon(p.channel, size: 26),
          const SizedBox(width: 8),
          Text(
            '${p.channel.label} · ${p.connected ? 'Connected' : 'Not connected'}',
            style: TextStyle(color: AutoInk.text(context), fontSize: 13),
          ),
          const SizedBox(width: 6),
          Icon(
            RemixIcons.circle_fill,
            size: 9,
            color: p.connected ? AutoInk.whatsapp : Colors.orange,
          ),
        ],
      ),
    ),
  );
}

class _TabBar extends StatelessWidget {
  const _TabBar(this.p);
  final MessagingAutomationProvider p;
  @override
  Widget build(BuildContext context) {
    const items = {
      DashboardTab.automations: ('Automations', RemixIcons.flashlight_line),
      DashboardTab.inbox: ('Inbox', RemixIcons.inbox_line),
      DashboardTab.flow: ('Flow builder', RemixIcons.git_branch_line),
      DashboardTab.activity: ('Activity', RemixIcons.history_line),
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final e in items.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => p.setTab(e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: p.tab == e.key
                        ? AutoInk.blue.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: p.tab == e.key
                          ? AutoInk.blue
                          : AutoInk.line(context),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        e.value.$2,
                        size: 18,
                        color: p.tab == e.key
                            ? AutoInk.blue
                            : AutoInk.muted(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        e.value.$1,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: p.tab == e.key
                              ? AutoInk.blue
                              : AutoInk.text(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

// ───────────── Automations tab ─────────────
class _AutomationsTab extends StatelessWidget {
  const _AutomationsTab();

  Widget _stat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) => Expanded(
    child: AutoPanel(
      child: Row(
        children: [
          Icon(icon, color: AutoInk.purple),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: AutoInk.text(context),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: AutoInk.muted(context), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MessagingAutomationProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _stat(context, 'Active', '${p.activeCount}', RemixIcons.flashlight_line),
            const SizedBox(width: 12),
            _stat(
              context,
              'Total runs',
              '${p.totalRuns}',
              RemixIcons.play_circle_line,
            ),
            const SizedBox(width: 12),
            _stat(
              context,
              'Success rate',
              '${p.successRate.toStringAsFixed(0)}%',
              RemixIcons.checkbox_circle_line,
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (p.flows.isEmpty)
          AutoCard(
            padding: const EdgeInsets.all(40),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const Icon(RemixIcons.flashlight_line, size: 40, color: AutoInk.purple),
                  const SizedBox(height: 12),
                  Text(
                    'No automations yet',
                    style: TextStyle(
                      color: AutoInk.text(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create your first keyword reply in about 3 minutes.',
                    style: TextStyle(color: AutoInk.muted(context)),
                  ),
                  const SizedBox(height: 18),
                  AutoButton(
                    label: 'Create automation',
                    onPressed: () =>
                        p.startBuilder(AutomationTrigger.dmKeyword),
                  ),
                ],
              ),
            ),
          )
        else
          for (final f in p.flows)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AutoCard(
                child: Row(
                  children: [
                    ChannelIcon(f.channel, size: 40),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.name,
                            style: TextStyle(
                              color: AutoInk.text(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            f.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AutoInk.muted(context),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final k in f.keywords) AutoChip(k),
                              Text(
                                '${f.runs} runs',
                                style: TextStyle(
                                  color: AutoInk.muted(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Switch(
                          value: f.active,
                          onChanged: (v) => p.toggleFlow(f, v),
                        ),
                        Text(
                          f.active ? 'Active' : 'Paused',
                          style: TextStyle(
                            color: AutoInk.muted(context),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) =>
                          v == 'test' ? p.testFlow(f) : p.deleteFlow(f),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'test', child: Text('Send test')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

// ───────────── Inbox tab ─────────────
class _InboxTab extends StatelessWidget {
  const _InboxTab();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MessagingAutomationProvider>();
    Widget sideItem(IconData i, String t, {String? trail, bool sel = false}) =>
        Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? AutoInk.line(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(i, size: 18, color: AutoInk.muted(context)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t,
                  style: TextStyle(
                    color: AutoInk.text(context),
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (trail != null)
                Text(trail, style: TextStyle(color: AutoInk.muted(context))),
            ],
          ),
        );

    Widget filter(String t, {bool active = false}) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AutoInk.blue.withValues(alpha: 0.08) : Colors.transparent,
          border: Border.all(
            color: active ? AutoInk.blue : AutoInk.line(context),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          t,
          style: TextStyle(
            fontSize: 13,
            color: active ? AutoInk.blue : AutoInk.text(context),
          ),
        ),
      ),
    );

    final list = Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              filter('Closed Chats', active: true),
              filter('Unread'),
              filter('Sort: Newest'),
              filter('All Channels'),
              filter('+ Filter'),
            ],
          ),
        ),
        Divider(height: 1, color: AutoInk.line(context)),
        Expanded(
          child: p.threads.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          RemixIcons.inbox_line,
                          size: 40,
                          color: AutoInk.muted(context),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AutoInk.text(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Incoming messages and replies will appear here.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AutoInk.muted(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  children: [
                    for (final t in p.threads)
                      ListTile(
                        selected: p.selectedThread == t,
                        onTap: () => p.selectThread(t),
                        leading: CircleAvatar(
                          backgroundColor:
                              AutoInk.purple.withValues(alpha: 0.15),
                          child: Text(t.name[0].toUpperCase()),
                        ),
                        title: Text(
                          t.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(t.incoming),
                        trailing: Text(
                          t.age,
                          style: TextStyle(color: AutoInk.muted(context)),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );

    Widget detail() {
      final t = p.selectedThread;
      if (t == null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                RemixIcons.repeat_line,
                size: 56,
                color: AutoInk.purple,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Save time with Auto-Assignment',
                    style: TextStyle(
                      color: AutoInk.text(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AutoInk.purple,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Chats get assigned to team members\nbased on rules you set.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AutoInk.muted(context)),
              ),
              const SizedBox(height: 16),
              AutoButton(
                label: 'Try It',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auto-assignment coming soon')),
                ),
              ),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  t.name,
                  style: TextStyle(
                    color: AutoInk.text(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => p.selectThread(null),
                  icon: const Icon(RemixIcons.close_line),
                ),
              ],
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(label: Text(t.incoming)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Chip(
                backgroundColor: AutoInk.purple.withValues(alpha: 0.15),
                label: Text('🤖 ${t.reply}'),
              ),
            ),
            const Spacer(),
          ],
        ),
      );
    }

    return Container(
      height: 560,
      decoration: BoxDecoration(
        border: Border.all(color: AutoInk.line(context)),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 900;
          final mid = c.maxWidth >= 620;
          return Row(
            children: [
              if (wide)
                Container(
                  width: 200,
                  color: AutoInk.panel(context),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sideItem(
                        RemixIcons.inbox_line,
                        'All chats',
                        trail: '0',
                        sel: true,
                      ),
                      sideItem(RemixIcons.time_line, 'Reminders'),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 8),
                        child: Text(
                          'Labels',
                          style: TextStyle(
                            color: AutoInk.muted(context),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      sideItem(RemixIcons.heart_line, 'Favorites'),
                    ],
                  ),
                ),
              SizedBox(
                width: mid ? 340 : c.maxWidth - (wide ? 200 : 0),
                child: list,
              ),
              VerticalDivider(width: 1, color: AutoInk.line(context)),
              if (mid) Expanded(child: detail()),
            ],
          );
        },
      ),
    );
  }
}

// ───────────── Activity tab ─────────────
class _ActivityTab extends StatelessWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MessagingAutomationProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Execution log',
              style: TextStyle(
                color: AutoInk.text(context),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (p.flows.isNotEmpty)
              AutoButton(
                label: 'Send test',
                icon: RemixIcons.play_line,
                filled: false,
                onPressed: () => p.testFlow(p.flows.first),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (p.logs.isEmpty)
          AutoPanel(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No activity yet. Go live or send a test to see results here.',
                style: TextStyle(color: AutoInk.muted(context)),
              ),
            ),
          )
        else
          for (final l in p.logs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AutoCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      l.success ? RemixIcons.checkbox_circle_line : RemixIcons.error_warning_line,
                      color: l.success ? AutoInk.whatsapp : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  l.flowName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AutoInk.text(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (l.isTest) ...[
                                const SizedBox(width: 8),
                                const AutoChip('TEST'),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${l.contact} · ${l.detail}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AutoInk.muted(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _ago(l.time),
                      style: TextStyle(
                        color: AutoInk.muted(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
