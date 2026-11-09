import 'package:flutter/material.dart';

enum Channel { instagram }

extension ChannelX on Channel {
  bool get isIg => this == Channel.instagram;
  String get label => 'Instagram';
  IconData get icon => Icons.camera_alt_rounded;
  String get idLabel => 'Instagram username';
  String get idHint => 'yourbrand';
  String get blurb => 'Reply to DMs, post comments and story replies.';
}
