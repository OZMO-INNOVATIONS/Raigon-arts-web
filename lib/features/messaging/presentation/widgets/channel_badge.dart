import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:raigon_art/core/constants/asset_constants.dart';
import 'package:raigon_art/features/messaging/models/channel.dart';

class ChannelBadge extends StatelessWidget {
  const ChannelBadge(
    this.channel, {
    super.key,
    this.size = 30,
  });

  final Channel channel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isInstagram = channel == Channel.instagram;

    return SvgPicture.asset(
      isInstagram
          ? AssetConstants.instagram
          : AssetConstants.whatsApp,
      width: size * 0.60,
      height: size * 0.60,
      fit: BoxFit.contain,
    );
  }
}
