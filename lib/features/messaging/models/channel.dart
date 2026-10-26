import 'package:flutter/material.dart';

enum Channel { instagram, whatsapp }

extension ChannelX on Channel {
  bool get isIg => this == Channel.instagram;
  String get label => isIg ? 'Instagram' : 'WhatsApp';
  IconData get icon => isIg ? Icons.camera_alt_rounded : Icons.chat_rounded;
  String get idLabel => isIg ? 'Instagram username' : 'WhatsApp number';
  String get idHint => isIg ? 'yourbrand' : '+91 98765 43210';
  String get blurb => isIg
      ? 'Reply to DMs, post comments and story replies.'
      : 'Reply to customer messages on WhatsApp Business.';
}
