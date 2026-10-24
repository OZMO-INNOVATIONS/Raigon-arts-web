import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';

class AutomationRule {
  AutomationRule({
    required this.id,
    required this.name,
    required this.channel,
    required this.trigger,
    required this.keywords,
    required this.message,
    this.linkLabel,
    this.linkUrl,
    this.active = true,
    this.runs = 0,
  });

  final String id;
  final String name;
  final AutomationChannel channel;
  final AutomationTrigger trigger;
  final List<String> keywords;
  final String message;
  final String? linkLabel;
  final String? linkUrl;
  bool active;
  int runs;

  /// Builds a rule from the `automation-rules` edge function payload.
  /// [previous] keeps local-only fields (link label/url, test run count).
  factory AutomationRule.fromJson(
    Map<String, dynamic> json, {
    AutomationRule? previous,
  }) {
    final rawKeywords = json['keywords'];
    return AutomationRule(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? 'Automation',
      channel: AutomationChannel.instagram,
      trigger: AutomationTriggerX.fromBackend(json['trigger_type']),
      keywords: rawKeywords is List
          ? rawKeywords.map((e) => e.toString()).toList()
          : <String>[],
      message: json['reply_message']?.toString() ?? '',
      active: json['is_active'] == true,
      linkLabel: previous?.linkLabel,
      linkUrl: previous?.linkUrl,
      runs: previous?.runs ?? 0,
    );
  }
}
