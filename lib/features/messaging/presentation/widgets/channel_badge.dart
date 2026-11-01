import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:raigon_art/core/constants/asset_constants.dart';

class ChannelBadge extends StatelessWidget {
  const ChannelBadge({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AssetConstants.instagram,
      width: size * 0.60,
      height: size * 0.60,
      fit: BoxFit.contain,
    );
  }
}
