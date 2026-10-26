import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging/models/channel.dart';
import 'package:raigon_art/features/messaging/provider/messaging_provider.dart';

import 'channel_badge.dart';
import 'gradient_button.dart';

Future<bool> showConnectDialog(
  BuildContext context,
  MessagingAutomationProvider s,
  Channel c,
) async {
  final ctrl = TextEditingController();
  final ok =
      await showDialog<bool>(
        context: context,
        builder: (_) => _ConnectDialog(channel: c, ctrl: ctrl),
      ) ??
      false;
  if (ok) s.connect(c, ctrl.text.trim().replaceFirst('@', ''));
  return ok;
}

class _ConnectDialog extends StatefulWidget {
  const _ConnectDialog({required this.channel, required this.ctrl});
  final Channel channel;
  final TextEditingController ctrl;
  @override
  State<_ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends State<_ConnectDialog> {
  bool busy = false;
  String? err;

  Future<void> _go() async {
    final v = widget.ctrl.text.trim().replaceFirst('@', '');
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (widget.channel.isIg ? v.length < 2 : digits.length < 8) {
      setState(
        () => err = widget.channel.isIg
            ? 'Enter your Instagram username.'
            : 'Enter your number with country code.',
      );
      return;
    }
    setState(() {
      err = null;
      busy = true;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final c = widget.channel;
    return AlertDialog(
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChannelBadge(c, size: 56),
            const SizedBox(height: 16),
            Text(
              'Connect ${c.label}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'We’ll take you to Meta to set permissions, then link your account.',
              style: TextStyle(color: p.textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: widget.ctrl,
              autofocus: true,
              keyboardType: c.isIg ? TextInputType.text : TextInputType.phone,
              onSubmitted: (_) => _go(),
              decoration: InputDecoration(
                labelText: c.idLabel,
                hintText: c.idHint,
                errorText: err,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: 'Connect via Meta',
                busy: busy,
                onPressed: _go,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: busy ? null : () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}