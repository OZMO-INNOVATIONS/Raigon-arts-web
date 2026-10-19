import 'package:flutter/material.dart';
import 'package:raigon_art/features/messaging_automation/presentation/screens/automation_ui.dart';
import 'package:raigon_art/features/messaging_automation/providers/messaging_automation_provider.dart';

/// Live phone mockup. Instagram = dark DM look, WhatsApp = green chat look.
class PhonePreview extends StatelessWidget {
  const PhonePreview({
    super.key,
    required this.channel,
    required this.account,
    required this.userText,
    required this.replyText,
    this.linkLabel,
  });

  final AutomationChannel channel;
  final String account;
  final String userText;
  final String replyText;
  final String? linkLabel;

  @override
  Widget build(BuildContext context) {
    final wa = channel == AutomationChannel.whatsapp;
    final bg = wa ? const Color(0xFF0B141A) : const Color(0xFF111111);
    final mine = wa ? const Color(0xFF005C4B) : AutoInk.purple;
    final theirs = wa ? const Color(0xFF202C33) : const Color(0xFF262626);

    return Container(
      width: 290,
      height: 560,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF141B2D),
        borderRadius: BorderRadius.circular(44),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 12)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Container(
          color: bg,
          child: Column(
            children: [
              // status bar
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
                child: Row(
                  children: [
                    const Text('9:41',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Container(
                      width: 70,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.signal_cellular_alt, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    const Icon(Icons.battery_full, color: Colors.white, size: 14),
                  ],
                ),
              ),
              // header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                    const SizedBox(width: 10),
                    _avatar(account, 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        account,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    const Icon(Icons.call_outlined, color: Colors.white, size: 18),
                    const SizedBox(width: 12),
                    const Icon(Icons.videocam_outlined, color: Colors.white, size: 20),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              // messages
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: _bubble(userText, mine, 'Write a message'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _avatar(account, 12),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _bubble(replyText, theirs, 'Write a message'),
                              if (linkLabel != null && linkLabel!.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.link, color: Colors.white, size: 14),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(linkLabel!,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      ),
                                    ],
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
              // input
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: wa ? AutoInk.whatsapp : AutoInk.blue,
                      child: Icon(wa ? Icons.add : Icons.camera_alt, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Message...',
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ),
                    const Icon(Icons.image_outlined, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    const Icon(Icons.add_circle_outline, color: Colors.white70, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(String name, double r) => CircleAvatar(
        radius: r,
        backgroundColor: Colors.black,
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(color: Colors.white, fontSize: r * 0.9, fontWeight: FontWeight.w700),
        ),
      );

  Widget _bubble(String text, Color color, String placeholder) {
    final empty = text.trim().isEmpty;
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      child: Text(
        empty ? placeholder : text,
        style: TextStyle(color: empty ? Colors.white60 : Colors.white, fontSize: 12.5, height: 1.3),
      ),
    );
  }
}
