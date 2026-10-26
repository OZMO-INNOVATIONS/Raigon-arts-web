import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';
import 'package:raigon_art/features/messaging/models/channel.dart';
import 'package:raigon_art/features/messaging/models/chat.dart';

class PhoneView extends StatefulWidget {
  const PhoneView({
    super.key,
    required this.channel,
    required this.handle,
    required this.msgs,
    this.onSend,
    this.typing = false,
    this.height = 600,
  });
  final Channel channel;
  final String handle;
  final List<ChatMsg> msgs;
  final ValueChanged<String>? onSend;
  final bool typing;
  final double height;
  @override
  State<PhoneView> createState() => _PhoneViewState();
}

class _PhoneViewState extends State<PhoneView> {
  final _c = TextEditingController();
  final _sc = ScrollController();

  AppPalette get p => AppPalette.of(context);

  @override
  void didUpdateWidget(covariant PhoneView old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sc.hasClients) {
        _sc.animateTo(
          _sc.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _sc.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _c.text.trim();
    if (t.isEmpty || widget.onSend == null) return;
    widget.onSend!(t);
    _c.clear();
  }

  bool get ig => widget.channel.isIg;
  Color get _bg => ig ? const Color(0xFF121212) : const Color(0xFFEFE7DD);
  Color get _fg => ig ? Colors.white : const Color(0xFF111B21);

  Widget _bubble(ChatMsg m) {
    final mine = !m.fromBot;
    final empty = m.text.trim().isEmpty;
    final bubbleColor = ig
        ? (mine ? p.accent : const Color(0xFF262626))
        : (mine ? const Color(0xFFD9FDD3) : Colors.white);
    final textColor = ig ? (mine ? p.onAccent : Colors.white) : _fg;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 210),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(ig ? 18 : 10),
              ),
              child: Text(
                empty ? 'Write a message' : m.text,
                style: TextStyle(
                  fontSize: 12.5,
                  color: textColor.withValues(alpha: empty ? .5 : 1),
                ),
              ),
            ),
            if (m.linkLabel.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxWidth: 210),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: ig ? const Color(0xFF363636) : Colors.white,
                  borderRadius: BorderRadius.circular(ig ? 18 : 10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 15,
                      color: ig ? Colors.white : const Color(0xFF027EB5),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        m.linkLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ig ? Colors.white : const Color(0xFF027EB5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _typing() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ig ? const Color(0xFF262626) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '•••',
        style: TextStyle(color: _fg.withValues(alpha: .5), letterSpacing: 2),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final enabled = widget.onSend != null;
    final headBg = ig ? const Color(0xFF121212) : p.waDark;
    return Container(
      width: 290,
      height: widget.height,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2030),
        borderRadius: BorderRadius.circular(44),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Container(
          color: _bg,
          child: Column(
            children: [
              Container(
                color: headBg,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '9:41',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(
                          Icons.signal_cellular_alt_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.wifi_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 3),
                        Icon(
                          Icons.battery_full_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                color: headBg,
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: ig ? Colors.black : Colors.white,
                      child: Text(
                        widget.handle.isEmpty
                            ? 'R'
                            : widget.handle
                                  .replaceAll(RegExp(r'[^A-Za-z0-9]'), 'R')
                                  .substring(0, 1)
                                  .toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: ig ? Colors.white : p.waDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.handle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!ig)
                            Text(
                              'online',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .7),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.call_outlined,
                      size: 17,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.videocam_outlined,
                      size: 19,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: _sc,
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final m in widget.msgs) _bubble(m),
                    if (widget.typing) _typing(),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                color: _bg,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ig ? const Color(0xFF262626) : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TextField(
                          controller: _c,
                          enabled: enabled,
                          onSubmitted: (_) => _submit(),
                          style: TextStyle(fontSize: 13, color: _fg),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            hintText: enabled
                                ? 'Type a test message'
                                : 'Message…',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: _fg.withValues(alpha: .45),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: enabled ? _submit : null,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: ig ? p.accent : p.wa,
                        child: Icon(
                          Icons.send_rounded,
                          size: 18,
                          color: ig ? p.onAccent : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
