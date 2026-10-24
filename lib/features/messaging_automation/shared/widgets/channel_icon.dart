import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';

class ChannelIcon extends StatelessWidget {
  const ChannelIcon(this.channel, {super.key, this.size = 44});

  final AutomationChannel channel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ig = channel.isInstagram;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        color: ig ? null : AppColors.green,
        gradient: ig
            ? const LinearGradient(
                colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              )
            : null,
      ),
      child: Icon(
        ig ? Icons.camera_alt_outlined : Icons.chat_rounded,
        color: Colors.white,
        size: size * 0.55,
      ),
    );
  }
}
