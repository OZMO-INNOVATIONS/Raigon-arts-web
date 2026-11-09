import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging/models/channel.dart';
import 'package:raigon_art/features/messaging/provider/messaging_provider.dart';

import 'channel_badge.dart';
import 'gradient_button.dart';

Future<bool> showConnectDialog(
  BuildContext context,
  MessagingAutomationProvider s,
) async {
  final ctrl = TextEditingController();

  final ok =
      await showDialog<bool>(
        context: context,
        builder: (_) => _ConnectDialog(ctrl: ctrl),
      ) ??
      false;

  if (ok) {
    s.connect(Channel.instagram, ctrl.text.trim().replaceFirst('@', ''));
  }

  ctrl.dispose();
  return ok;
}

class _ConnectDialog extends StatefulWidget {
  const _ConnectDialog({required this.ctrl});

  final TextEditingController ctrl;

  @override
  State<_ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends State<_ConnectDialog> {
  bool busy = false;
  String? err;

  Future<void> _go() async {
    final username = widget.ctrl.text.trim().replaceFirst('@', '');

    if (username.length < 2) {
      setState(() => err = 'Enter your Instagram username.');
      return;
    }

    setState(() {
      err = null;
      busy = true;
    });

    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return AlertDialog(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: p.border),
      ),
      contentPadding: const EdgeInsets.fromLTRB(26, 26, 26, 14),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ChannelBadge(size: 56),
            const SizedBox(height: 16),
            Text(
              'Connect Instagram',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'We’ll take you to Meta to set permissions, then link your Instagram account.',
              style: TextStyle(color: p.textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: widget.ctrl,
              autofocus: true,
              keyboardType: TextInputType.text,
              onSubmitted: (_) => _go(),
              decoration: InputDecoration(
                labelText: 'Instagram username',
                hintText: '@yourbrand',
                errorText: err,
              ),
            ),
            const SizedBox(height: 20),
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
                style: TextButton.styleFrom(foregroundColor: p.textMuted),
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
