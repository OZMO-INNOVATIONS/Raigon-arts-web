import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging/models/automation.dart';
import 'package:raigon_art/features/messaging/models/chat.dart';
import 'package:raigon_art/features/messaging/provider/messaging_provider.dart';

import 'phone_view.dart';

class PhoneSim extends StatefulWidget {
  const PhoneSim({super.key, required this.auto, this.s, this.handle});
  final Automation auto;
  final MessagingAutomationProvider? s; 
  final String? handle;
  @override
  State<PhoneSim> createState() => _PhoneSimState();
}

class _PhoneSimState extends State<PhoneSim> {
  final msgs = <ChatMsg>[];
  bool typing = false;

  Future<void> _send(String t) async {
    final a = widget.auto;
    final user = ChatMsg(t, false);
    setState(() => msgs.add(user));
    widget.s?.log(a.channel, user);
    if (!a.matches(t)) return;
    setState(() => typing = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final bot = ChatMsg(a.message, true, linkLabel: a.linkLabel, linkUrl: a.linkUrl);
    setState(() {
      typing = false;
      msgs.add(bot);
    });
    widget.s?.log(a.channel, bot);
    widget.s?.countRun(a);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final a = widget.auto;
    final h = math.min(600.0, MediaQuery.sizeOf(context).height - 150);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      PhoneView(
        channel: a.channel,
        handle: widget.handle ?? widget.s?.accounts[a.channel] ?? 'yourbrand',
        msgs: msgs,
        typing: typing,
        onSend: _send,
        height: h,
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: p.chipFill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          a.keywords.isEmpty ? 'Type any message' : 'Try: ${a.keywords.first}',
          style: TextStyle(fontSize: 12, color: p.textMuted),
        ),
      ),
    ]);
  }
}