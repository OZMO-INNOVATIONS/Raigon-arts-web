import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_rule.dart';

/// Talks to the `automation-rules` edge function.
class AutomationRuleService {
  SupabaseClient get _client => Supabase.instance.client;

  void _requireSession() {
    if (_client.auth.currentSession == null) {
      throw Exception('Please sign in to manage automations.');
    }
  }

  Map _unwrap(FunctionResponse response, String fallback) {
    final data = response.data;
    if (response.status < 200 || response.status >= 300 || data is! Map) {
      throw Exception(data is Map ? '${data['error'] ?? fallback}' : fallback);
    }
    return data;
  }

  Future<List<AutomationRule>> fetchInstagramRules({
    List<AutomationRule> existing = const [],
  }) async {
    _requireSession();
    final response = await _client.functions.invoke(
      'automation-rules',
      method: HttpMethod.get,
    );
    final data = _unwrap(response, 'Invalid automation list response.');
    final list = data['automations'];
    if (list is! List) throw Exception('Invalid automation list response.');

    final previous = {for (final r in existing) r.id: r};
    return [
      for (final item in list)
        if (item is Map && item['id'] != null)
          AutomationRule.fromJson(
            Map<String, dynamic>.from(item),
            previous: previous[item['id'].toString()],
          ),
    ];
  }

  Future<AutomationRule> createRule({
    required AutomationChannel channel,
    required String name,
    required AutomationTrigger trigger,
    required List<String> keywords,
    required String message,
    String? linkLabel,
    String? linkUrl,
  }) async {
    // WhatsApp stays a local demo until its backend is available.
    if (!channel.isInstagram) {
      return AutomationRule(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        channel: channel,
        trigger: trigger,
        keywords: keywords,
        message: message,
        linkLabel: linkLabel,
        linkUrl: linkUrl,
      );
    }

    _requireSession();
    final response = await _client.functions.invoke(
      'automation-rules',
      body: {
        'rule': {
          'name': name,
          'channel': 'instagram',
          'trigger_type': trigger.backendValue,
          'keywords': keywords,
          'reply_message': message,
          'is_active': true,
        },
      },
    );
    final data = _unwrap(response, 'Could not save the automation.');
    final saved = data['automation'];
    if (saved is! Map) {
      throw Exception('The server did not return the saved automation.');
    }

    final rule = AutomationRule.fromJson(Map<String, dynamic>.from(saved));
    return AutomationRule(
      id: rule.id,
      name: rule.name,
      channel: rule.channel,
      trigger: rule.trigger,
      keywords: rule.keywords.isEmpty ? keywords : rule.keywords,
      message: rule.message.isEmpty ? message : rule.message,
      linkLabel: linkLabel,
      linkUrl: linkUrl,
      active: rule.active,
    );
  }

  Future<void> setActive(AutomationRule rule, bool on) async {
    _requireSession();
    final response = await _client.functions.invoke(
      'automation-rules',
      body: {
        'rule': {
          'id': rule.id,
          'name': rule.name,
          'trigger_type': rule.trigger.backendValue,
          'keywords': rule.keywords,
          'reply_message': rule.message,
          'is_active': on,
        },
      },
    );
    _unwrap(response, 'Could not update the automation.');
  }

  Future<void> delete(String id) async {
    _requireSession();
    final response = await _client.functions.invoke(
      'automation-rules',
      body: {'action': 'delete', 'id': id},
    );
    _unwrap(response, 'Could not delete the automation.');
  }
}
