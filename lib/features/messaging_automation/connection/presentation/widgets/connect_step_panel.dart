import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/connection/providers/connection_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_button.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_card.dart';

/// Right-hand panel of the "Connect ChanneL>" screen.
class ConnectStepPanel extends StatelessWidget {
  const ConnectStepPanel({super.key});

  static const _steps = [
    ('Authorize', 'Sign in to Meta and pick the account to link.'),
    ('Set permissions', 'Allow Raigon Art to read and reply to messages.'),
    ('Start automating', 'Build your first reply in about 3 minutes.'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ConnectionProvider>();
    final p = AppPalette.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How it works',
          style: TextStyle(
            color: p.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: p.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_steps[i].$1,
                          style: TextStyle(
                              color: p.textPrimary,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(_steps[i].$2,
                          style: TextStyle(
                              color: p.textMuted, fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        if (c.error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppPalette.statusRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppPalette.statusRed.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline,
                    color: AppPalette.statusRed, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(c.error!,
                      style: TextStyle(color: p.textPrimary, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        AutoButton(
          label: c.channel.isInstagram
              ? 'Connect via Meta'
              : 'Connect WhatsApp Business',
          icon: Icons.link_rounded,
          expand: true,
          loading: c.connecting,
          onPressed: c.connect,
        ),
        const SizedBox(height: 14),
        AutoCard(
          radius: 14,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: AppColors.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Official Meta Business Platform connection. You can disconnect any time from Meta settings.',
                  style: TextStyle(color: p.textMuted, fontSize: 12.5, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: c.exploreFirst,
            child: const Text('Look around first'),
          ),
        ),
      ],
    );
  }
}
