import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/connection/providers/connection_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/channel_icon.dart';

/// Shows the active channel + account and lets the user switch channel.
class ConnectionPill extends StatelessWidget {
  const ConnectionPill({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ConnectionProvider>();
    final p = AppPalette.of(context);
    final color = c.connected ? AppPalette.statusGreen : AppPalette.orange;

    return Tooltip(
      message: 'Switch channel',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: c.openChannelPicker,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChannelIcon(c.channel, size: 28),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.connected ? '@${c.accountName}' : c.channel.label,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 7, color: color),
                      const SizedBox(width: 4),
                      Text(
                        c.connected ? 'Connected' : 'Not connected',
                        style: TextStyle(color: p.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Icon(Icons.unfold_more_rounded, size: 16, color: p.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
