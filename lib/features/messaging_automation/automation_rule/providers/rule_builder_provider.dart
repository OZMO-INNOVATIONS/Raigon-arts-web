import 'package:flutter/foundation.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/services/automation_rule_service.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_rule.dart';
import 'package:raigon_art/features/messaging_automation/shared/utils/formatters.dart';

/// Draft state for the 3-step builder: Trigger → Reply → Review.
class RuleBuilderProvider extends ChangeNotifier {
  RuleBuilderProvider({
    required this.channel,
    required this.trigger,
    AutomationRuleService? service,
  }) : _service = service ?? AutomationRuleService();

  final AutomationChannel channel;
  final AutomationTrigger trigger;
  final AutomationRuleService _service;

  BuilderStep step = BuilderStep.trigger;
  String keywordsText = '';
  String message = '';
  String? linkLabel;
  String? linkUrl;
  bool anyPost = true;
  final Set<DraftOption> options = {};

  bool publishing = false;
  String? error;

  // ───────────── derived ─────────────
  List<String> get keywords => keywordsText
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  bool get needsKeywords => trigger != AutomationTrigger.welcome;
  bool get triggerValid => !needsKeywords || keywords.isNotEmpty;
  bool get replyValid => message.trim().isNotEmpty;
  bool get canGoLive => triggerValid && replyValid;
  bool get isDirty =>
      keywordsText.isNotEmpty || message.isNotEmpty || linkLabel != null;

  bool get canContinue => switch (step) {
        BuilderStep.trigger => triggerValid,
        BuilderStep.reply => replyValid,
        BuilderStep.review => canGoLive,
      };

  String get ruleName => switch (trigger) {
        AutomationTrigger.welcome => 'Welcome message',
        AutomationTrigger.commentLink =>
          'Comment → "${keywords.isEmpty ? '…' : keywords.first}"',
        AutomationTrigger.dmKeyword =>
          '${channel.messageNoun} → "${keywords.isEmpty ? '…' : keywords.first}"',
      };

  /// Message sent to the backend, with the link appended so it is delivered.
  String get composedMessage {
    final base = message.trim();
    if (linkUrl == null || linkUrl!.isEmpty) return base;
    final label = (linkLabel?.isNotEmpty ?? false) ? '$linkLabel: ' : '';
    return '$base\n\n$label$linkUrl';
  }

  // ───────────── steps ─────────────
  bool canOpen(BuilderStep target) => switch (target) {
        BuilderStep.trigger => true,
        BuilderStep.reply => triggerValid,
        BuilderStep.review => triggerValid && replyValid,
      };

  void goTo(BuilderStep target) {
    if (!canOpen(target)) return;
    step = target;
    notifyListeners();
  }

  void next() {
    if (!canContinue) return;
    if (step == BuilderStep.trigger) {
      step = BuilderStep.reply;
    } else if (step == BuilderStep.reply) {
      step = BuilderStep.review;
    }
    notifyListeners();
  }

  void back() {
    if (step == BuilderStep.review) {
      step = BuilderStep.reply;
    } else if (step == BuilderStep.reply) {
      step = BuilderStep.trigger;
    }
    notifyListeners();
  }

  // ───────────── editing ─────────────
  void setKeywords(String v) {
    keywordsText = v;
    notifyListeners();
  }

  void addKeyword(String word) {
    if (keywords.any((k) => k.toLowerCase() == word.toLowerCase())) return;
    keywordsText = [...keywords, word].join(', ');
    notifyListeners();
  }

  void removeKeyword(String word) {
    keywordsText = keywords.where((k) => k != word).join(', ');
    notifyListeners();
  }

  void setMessage(String v) {
    message = v;
    notifyListeners();
  }

  void setLink(String? label, String? url) {
    linkLabel = label;
    linkUrl = url;
    notifyListeners();
  }

  void setAnyPost(bool v) {
    anyPost = v;
    notifyListeners();
  }

  void toggleOption(DraftOption o, bool on) {
    on ? options.add(o) : options.remove(o);
    notifyListeners();
  }

  // ───────────── publish ─────────────
  Future<AutomationRule?> publish() async {
    if (!canGoLive || publishing) return null;
    publishing = true;
    error = null;
    notifyListeners();

    try {
      return await _service.createRule(
        channel: channel,
        name: ruleName,
        trigger: trigger,
        keywords: keywords,
        message: composedMessage,
        linkLabel: linkLabel,
        linkUrl: linkUrl,
      );
    } catch (e) {
      error = 'Could not save automation: ${cleanError(e)}';
      debugPrint(error);
      return null;
    } finally {
      publishing = false;
      notifyListeners();
    }
  }
}
