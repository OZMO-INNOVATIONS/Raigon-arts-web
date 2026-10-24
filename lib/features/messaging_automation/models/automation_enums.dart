import 'package:flutter/material.dart';

enum AutomationChannel { instagram, whatsapp }

extension AutomationChannelX on AutomationChannel {
  String get label =>
      this == AutomationChannel.instagram ? 'Instagram' : 'WhatsApp';
  String get messageNoun =>
      this == AutomationChannel.instagram ? 'DM' : 'message';
  bool get isInstagram => this == AutomationChannel.instagram;

  /// Triggers that can be created on this channel.
  List<AutomationTrigger> get triggers => isInstagram
      ? AutomationTrigger.values
      : const [AutomationTrigger.welcome, AutomationTrigger.dmKeyword];
}

enum AutomationTrigger { dmKeyword, commentLink, welcome }

extension AutomationTriggerX on AutomationTrigger {
  String get backendValue => switch (this) {
        AutomationTrigger.dmKeyword => 'keyword',
        AutomationTrigger.commentLink => 'postComment',
        AutomationTrigger.welcome => 'firstMessage',
      };

  static AutomationTrigger fromBackend(dynamic value) => switch (value) {
        'keyword' => AutomationTrigger.dmKeyword,
        'postComment' => AutomationTrigger.commentLink,
        'firstMessage' || 'anyMessage' => AutomationTrigger.welcome,
        _ => AutomationTrigger.dmKeyword,
      };

  String get shortLabel => switch (this) {
        AutomationTrigger.dmKeyword => 'Keyword reply',
        AutomationTrigger.commentLink => 'Comment → link',
        AutomationTrigger.welcome => 'Welcome message',
      };

  IconData get icon => switch (this) {
        AutomationTrigger.dmKeyword => Icons.chat_bubble_outline_rounded,
        AutomationTrigger.commentLink => Icons.mode_comment_outlined,
        AutomationTrigger.welcome => Icons.waving_hand_outlined,
      };
}

enum DashboardTab { automations, inbox, activity }

enum BuilderStep { trigger, reply, review }

enum DraftOption { followUp, askEmail, businessHours, humanHandover }

extension DraftOptionX on DraftOption {
  String get label => switch (this) {
        DraftOption.followUp => 'Follow up after 24h',
        DraftOption.askEmail => 'Ask for an email',
        DraftOption.businessHours => 'Business hours only',
        DraftOption.humanHandover => 'Human handover',
      };

  String get info => switch (this) {
        DraftOption.followUp => 'Re-engage people who went quiet and build trust.',
        DraftOption.askEmail => 'Collect emails in chat to keep in touch beyond social.',
        DraftOption.businessHours => 'Only auto-reply during your business hours.',
        DraftOption.humanHandover => 'Hand over to a person when no keyword matches.',
      };
}
