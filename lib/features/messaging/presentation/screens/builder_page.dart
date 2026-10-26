import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';
import 'package:raigon_art/features/messaging/models/automation.dart';
import 'package:raigon_art/features/messaging/models/channel.dart';
import 'package:raigon_art/features/messaging/models/chat.dart';
import 'package:raigon_art/features/messaging/models/trigger_type.dart';
import 'package:raigon_art/features/messaging/provider/messaging_provider.dart';

import '../widgets/channel_badge.dart';
import '../widgets/channel_style.dart';
import '../widgets/connect_dialog.dart';
import '../widgets/gradient_button.dart';
import '../widgets/phone_sim.dart';
import '../widgets/phone_view.dart';
import '../widgets/section_card.dart';

class BuilderPage extends StatefulWidget {
  const BuilderPage({super.key, required this.s, this.existing, this.preset});
  final MessagingAutomationProvider s;
  final Automation? existing;
  final TriggerType? preset;
  @override
  State<BuilderPage> createState() => _BuilderPageState();
}

class _BuilderPageState extends State<BuilderPage> {
  static const _titles = [
    'Where should it run?',
    'First, set a trigger',
    'Write the reply',
    'Review and go live',
  ];
  static const _subs = [
    'Pick the channel for this automation.',
    'Build your automation and see it come to life.',
    'They’ll get a DM back from you with a link.',
    'Test it in the preview, then publish.',
  ];
  static const _stepNames = ['Channel', 'Trigger', 'Reply', 'Review'];
  static const _templates = [
    'Thanks for reaching out! Here’s the link 👇',
    'Hi! Here’s what you asked for 🙌',
    'Thanks! Tap the button below to continue ✨',
  ];

  int step = 0, dir = 1;
  Channel? channel;
  TriggerType trigger = TriggerType.keyword;
  final kw = TextEditingController(),
      msg = TextEditingController(),
      label = TextEditingController(),
      url = TextEditingController(),
      name = TextEditingController();

  MessagingAutomationProvider get s => widget.s;
  AppPalette get p => AppPalette.of(context);

  // The app theme (gold / black) drives the whole wizard. The channel's own
  // colour only shows up on its badge and in the preview panel.
  Color get _cc => p.accent;
  LinearGradient get _cg => p.brand;
  Color get _on => p.onBrand;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      channel = e.channel;
      trigger = e.trigger;
      kw.text = e.keywords.join(', ');
      msg.text = e.message;
      label.text = e.linkLabel;
      url.text = e.linkUrl;
      name.text = e.name;
    } else {
      trigger = widget.preset ?? TriggerType.keyword;
      if (trigger == TriggerType.postComment) channel = Channel.instagram;
      if (channel == null) {
        final connected = Channel.values
            .where((c) => s.accounts[c] != null)
            .toList();
        if (connected.length == 1) channel = connected.first;
      }
    }
  }

  @override
  void dispose() {
    for (final c in [kw, msg, label, url, name]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _keywords => kw.text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  bool get _urlOk =>
      Uri.tryParse(url.text.trim())?.hasAuthority == true &&
      url.text.trim().startsWith('http');
  String get _autoName =>
      '${(channel ?? Channel.instagram).label} · ${_keywords.isEmpty ? trigger.short : _keywords.first}';

  bool get _valid {
    switch (step) {
      case 0:
        return channel != null;
      case 1:
        return trigger != TriggerType.keyword || _keywords.isNotEmpty;
      case 2:
        final hasUrl = url.text.trim().isNotEmpty;
        return msg.text.trim().isNotEmpty &&
            (!hasUrl || (_urlOk && label.text.trim().isNotEmpty));
      default:
        return name.text.trim().isNotEmpty;
    }
  }

  Automation _draft({bool live = true}) => Automation(
    id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
    name: name.text.trim().isEmpty ? _autoName : name.text.trim(),
    channel: channel ?? Channel.instagram,
    trigger: trigger,
    keywords: _keywords,
    message: msg.text.trim(),
    linkLabel: label.text.trim(),
    linkUrl: url.text.trim(),
    live: live,
    runs: widget.existing?.runs ?? 0,
  );

  void _go(int d) {
    setState(() {
      dir = d;
      step += d;
      if (step == 3 && name.text.trim().isEmpty) name.text = _autoName;
    });
  }

  Future<void> _finish(bool live) async {
    if (!_valid) return;

    try {
      await s.upsertAsync(_draft(live: live));

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final snackBg = p.surface;
      final snackFg = p.textPrimary;
      Navigator.pop(context);

      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: snackBg,
          content: Text(
            live ? 'Published. Your automation is live.' : 'Saved as paused.',
            style: TextStyle(color: snackFg),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          content: Text('Could not save automation: $e'),
        ),
      );
    }
  }

  Future<void> _pickChannel(Channel c) async {
    if (s.accounts[c] == null) {
      final ok = await showConnectDialog(context, s, c);
      if (!ok || !mounted) return;
    }
    setState(() {
      channel = c;
      if (!trigger.allows(c)) trigger = TriggerType.keyword;
    });
  }

  IconData _triggerIcon(TriggerType t) => switch (t) {
    TriggerType.keyword => Icons.tag_rounded,
    TriggerType.anyMessage => Icons.mark_chat_unread_rounded,
    TriggerType.postComment => Icons.chat_bubble_outline_rounded,
    TriggerType.storyReply => Icons.auto_stories_rounded,
  };

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      t,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: p.textPrimary,
      ),
    ),
  );

  // ── step bodies ───────────────────────────────────────────────

  Widget _stepChannel() => Column(
    children: [
      for (final c in Channel.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OptionTile(
            selected: channel == c,
            onTap: () => _pickChannel(c),
            padding: const EdgeInsets.all(16),
            leading: ChannelBadge(c, size: 50),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.accounts[c] != null
                            ? p.mint
                            : p.textMuted.withValues(alpha: .4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        s.accounts[c] != null
                            ? 'Connected · ${s.accounts[c]}'
                            : 'Tap to connect',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: s.accounts[c] != null ? p.mint : p.textMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ],
  );

  Widget _stepTrigger() {
    final c = channel ?? Channel.instagram;
    final needs = trigger == TriggerType.keyword;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('When someone…'),
        for (final t in TriggerType.values.where((t) => t.allows(c)))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionTile(
              selected: trigger == t,
              onTap: () => setState(() => trigger = t),
              leading: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: trigger == t ? _cg : null,
                  color: trigger == t ? null : p.chipFill,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _triggerIcon(t),
                  size: 20,
                  color: trigger == t ? _on : p.textMuted,
                ),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.desc,
                    style: TextStyle(
                      color: p.textMuted,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (trigger == TriggerType.keyword ||
            trigger == TriggerType.postComment) ...[
          const SizedBox(height: 10),
          SectionCard(
            shadow: false,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tag_rounded, size: 18, color: _cc),
                    const SizedBox(width: 8),
                    Text(
                      needs
                          ? 'Words that trigger it'
                          : 'Words to match (optional)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: kw,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Enter a word or multiple',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use commas to separate words',
                  style: TextStyle(color: p.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Try:',
                      style: TextStyle(color: p.textMuted, fontSize: 12),
                    ),
                    for (final e in ['Price', 'Link', 'Shop'])
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => setState(
                            () => kw.text = kw.text.trim().isEmpty
                                ? e
                                : '${kw.text.trim().replaceAll(RegExp(r',\s*$'), '')}, $e',
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: p.accentSoft,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _cc.withValues(alpha: .35),
                              ),
                            ),
                            child: Text(
                              '+ $e',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _cc,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _stepReply() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('A DM with a link'),
      TextField(
        controller: msg,
        maxLines: 5,
        maxLength: 1000,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(hintText: 'Write a message'),
      ),
      if (msg.text.trim().isEmpty) ...[
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in _templates)
              ActionChip(
                label: Text(
                  t,
                  style: TextStyle(fontSize: 12.5, color: p.textPrimary),
                ),
                backgroundColor: p.accentSoft,
                side: BorderSide(color: _cc.withValues(alpha: .3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () => setState(() => msg.text = t),
              ),
          ],
        ),
      ],
      const SizedBox(height: 18),
      SectionCard(
        shadow: false,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link_rounded, size: 18, color: _cc),
                const SizedBox(width: 8),
                Text(
                  'Add a link button (optional)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: label,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Button label, e.g. Shop now',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: url,
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'https://yourshop.com',
                errorText: url.text.trim().isNotEmpty && !_urlOk
                    ? 'Start with http:// or https://'
                    : null,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _stepReview() {
    final d = _draft();
    Widget row(IconData i, String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(i, size: 32),
          const SizedBox(width: 12),
          SizedBox(
            width: 62,
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                k,
                style: TextStyle(color: p.textMuted, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                v,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: p.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: name,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Automation name'),
        ),
        const SizedBox(height: 14),
        SectionCard(
          shadow: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              row(Icons.hub_rounded, 'Channel', d.channel.label),
              Divider(height: 1, color: p.border),
              row(Icons.bolt_rounded, 'Trigger', d.summary),
              Divider(height: 1, color: p.border),
              row(Icons.chat_bubble_rounded, 'Reply', d.message),
              if (d.linkUrl.isNotEmpty) ...[
                Divider(height: 1, color: p.border),
                row(
                  Icons.link_rounded,
                  'Link',
                  '${d.linkLabel} → ${d.linkUrl}',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.accentSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cc.withValues(alpha: .25)),
          ),
          child: Row(
            children: [
              Icon(Icons.touch_app_rounded, size: 18, color: _cc),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  d.keywords.isEmpty
                      ? 'Send a message in the phone to test it.'
                      : 'Try typing “${d.keywords.first}” in the phone.',
                  style: TextStyle(fontSize: 13, color: p.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _body() {
    final w = switch (step) {
      0 => _stepChannel(),
      1 => _stepTrigger(),
      2 => _stepReply(),
      _ => _stepReview(),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      layoutBuilder: (cur, prev) =>
          Stack(alignment: Alignment.topLeft, children: [...prev, ?cur]),
      transitionBuilder: (child, anim) {
        final incoming = child.key == ValueKey(step);
        final begin = Offset((incoming ? 1 : -1) * 0.12 * dir, 0);
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: begin, end: Offset.zero).animate(anim),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(step), child: w),
    );
  }

  Widget _footer(bool narrow) {
    final back = step > 0
        ? SoftOutlineButton(
            onPressed: () => _go(-1),
            icon: Icons.arrow_back_rounded,
            label: narrow ? null : 'Back',
          )
        : null;
    final acts = <Widget>[
      if (step == 3) ...[
        SoftOutlineButton(
          onPressed: _valid ? () => _finish(false) : null,
          label: 'Save paused',
        ),
        GradientButton(
          label: 'Go live',
          icon: Icons.rocket_launch_rounded,
          onPressed: _valid ? () => _finish(true) : null,
        ),
      ] else
        GradientButton(
          label: 'Next',
          icon: Icons.arrow_forward_rounded,
          iconAfter: true,
          onPressed: _valid ? () => _go(1) : null,
        ),
    ];
    return Row(
      children: [
        if (back != null) ...[back, const SizedBox(width: 10)],
        if (!narrow) const Spacer(),
        for (var i = 0; i < acts.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          if (narrow) Expanded(child: acts[i]) else acts[i],
        ],
      ],
    );
  }

  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: p.accentSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Step ${step + 1} of 4',
          style: TextStyle(
            color: _cc,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        _titles[step],
        style: TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: p.textPrimary,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        _subs[step],
        style: TextStyle(color: p.textMuted, fontSize: 14, height: 1.35),
      ),
      const SizedBox(height: 24),
    ],
  );

  /// Numbered stepper in the app's gold.
  Widget _stepper(bool compact) {
    Widget dot(int i) {
      final done = i < step;
      final cur = i == step;
      final active = i <= step;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: active ? _cg : null,
              border: active ? null : Border.all(color: p.border, width: 1.5),
            ),
            child: done
                ? Icon(Icons.check_rounded, size: 15, color: _on)
                : Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? _on : p.textMuted,
                    ),
                  ),
          ),
          if (!compact || cur) ...[
            const SizedBox(width: 8),
            Text(
              _stepNames[i],
              style: TextStyle(
                fontSize: 13,
                fontWeight: cur ? FontWeight.w700 : FontWeight.w600,
                color: cur ? p.textPrimary : p.textMuted,
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: i <= step ? _cc : p.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          dot(i),
        ],
      ],
    );
  }

  Widget _previewTag() {
    final c = channel;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 14, 5),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (c != null) ...[
            ChannelBadge(c, size: 22),
            const SizedBox(width: 8),
          ] else ...[
            const SizedBox(width: 8),
          ],
          Text(
            c == null ? 'Live preview' : 'Live preview · ${c.label}',
            style: TextStyle(
              color: p.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview({double height = 600}) {
    final c = channel ?? Channel.instagram;
    final handle = s.accounts[c] ?? (c.isIg ? 'yourbrand' : 'Your business');
    if (step == 3) {
      return PhoneSim(
        key: ValueKey('sim-${c.name}'),
        auto: _draft(),
        handle: handle,
      );
    }
    final d = _draft();
    final sample = d.keywords.isNotEmpty
        ? d.keywords.first
        : switch (d.trigger) {
            TriggerType.postComment => 'Link please',
            TriggerType.storyReply => '🔥🔥',
            TriggerType.anyMessage => 'Hi',
            TriggerType.keyword => '',
          };
    return PhoneView(
      channel: c,
      handle: handle,
      height: height,
      msgs: [
        ChatMsg(sample, false),
        ChatMsg(d.message, true, linkLabel: d.linkLabel, linkUrl: d.linkUrl),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Panel tint follows the chosen channel; falls back to the app gold.
    final tint = channel?.brandColor ?? p.accent;
    return Theme(
      // Focus rings, selection and outlined buttons follow the app accent.
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(primary: _cc),
      ),
      child: Scaffold(
        backgroundColor: p.pageBg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 960;
              final top = Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: p.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: _stepper(c.maxWidth < 600)),
                  ],
                ),
              );
              if (wide) {
                return Column(
                  children: [
                    top,
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 560,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                40,
                                28,
                                40,
                                28,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _header(),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: _body(),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _footer(false),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.fromLTRB(0, 8, 20, 20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    tint.withValues(alpha: .12),
                                    tint.withValues(alpha: .03),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: tint.withValues(alpha: .16),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _previewTag(),
                                  const SizedBox(height: 14),
                                  _preview(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  top,
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      children: [
                        _header(),
                        _body(),
                        const SizedBox(height: 30),
                        Center(child: _previewTag()),
                        const SizedBox(height: 14),
                        Center(child: _preview(height: 520)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                    decoration: BoxDecoration(
                      color: p.surface,
                      border: Border(top: BorderSide(color: p.border)),
                    ),
                    child: _footer(true),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Selectable card used for channel and trigger choices.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.body,
    this.padding = const EdgeInsets.all(14),
  });
  final bool selected;
  final VoidCallback onTap;
  final Widget leading, body;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: padding,
          decoration: BoxDecoration(
            color: selected ? p.accentSoft : p.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? p.accent : p.border,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected ? p.softShadow : null,
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(child: body),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selected ? p.brand : null,
                  border: selected
                      ? null
                      : Border.all(color: p.border, width: 1.5),
                ),
                child: selected
                    ? Icon(Icons.check_rounded, size: 16, color: p.onBrand)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
