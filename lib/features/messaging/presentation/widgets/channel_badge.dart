import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';
import 'package:raigon_art/features/messaging/models/channel.dart';

class ChannelBadge extends StatelessWidget {
  const ChannelBadge(this.channel, {super.key, this.size = 40});
  final Channel channel;
  final double size;

  // Instagram brand gradient (kept as brand identity).
  static const LinearGradient _igGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [
      Color(0xFFF58529),
      Color(0xFFDD2A7B),
      Color(0xFF8134AF),
      Color(0xFF515BD4),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final base = channel.isIg ? const Color(0xFFD62976) : p.wa;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: channel.isIg ? _igGradient : null,
        color: channel.isIg ? null : p.wa,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: size >= 34
            ? [
                BoxShadow(
                  color: base.withValues(alpha: .28),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Icon(channel.icon, color: Colors.white, size: size * 0.54),
    );
  }
}