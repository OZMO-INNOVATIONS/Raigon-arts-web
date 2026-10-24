import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/connection/providers/connection_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_button.dart';

/// Shown while the user is exploring without a connected account.
class ConnectBanner extends StatelessWidget {
  const ConnectBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ConnectionProvider>();
    if (c.connected) return const SizedBox.shrink();
    final p = AppPalette.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.notifDueBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.orange.withValues(alpha: 0.35)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.info_outline, color: AppPalette.orange),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'You are exploring without a connected ${c.channel.label} account. '
              'Connect it to publish automations.',
              style: TextStyle(color: p.textPrimary, fontSize: 13.5),
            ),
          ),
          AutoButton(
            label: 'Connect ${c.channel.label}',
            onPressed: c.beginConnect,
          ),
        ],
      ),
    );
  }
}
