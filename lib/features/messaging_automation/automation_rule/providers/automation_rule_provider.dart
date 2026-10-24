import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/services/automation_rule_service.dart';
import 'package:raigon_art/features/messaging_automation/models/activity_log.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_rule.dart';
import 'package:raigon_art/features/messaging_automation/models/inbox_thread.dart';
import 'package:raigon_art/features/messaging_automation/shared/utils/formatters.dart';

/// Dashboard state: rules, activity, inbox and which builder is open.
class AutomationRuleProvider extends ChangeNotifier {
  AutomationRuleProvider({AutomationRuleService? service})
      : _service = service ?? AutomationRuleService();

  final AutomationRuleService _service;

  // ───────────── channel (synced from ConnectionProvider) ─────────────
  AutomationChannel _channel = AutomationChannel.instagram;
  AutomationChannel get channel => _channel;

  void syncChannel(AutomationChannel c) {
    if (_channel == c) return;
    _channel = c;
    scheduleMicrotask(notifyListeners);
  }

  // ───────────── navigation ─────────────
  DashboardTab tab = DashboardTab.automations;
  AutomationTrigger? builderTrigger;

  void setTab(DashboardTab t) {
    tab = t;
    notifyListeners();
  }

  void openBuilder(AutomationTrigger t) {
    builderTrigger = t;
    notifyListeners();
  }

  void closeBuilder() {
    builderTrigger = null;
    notifyListeners();
  }

  // ───────────── rules ─────────────
  final List<AutomationRule> _rules = [];
  final List<ActivityLog> logs = [];
  bool loading = false;
  String? error;

  List<AutomationRule> get visibleRules =>
      _rules.where((r) => r.channel == _channel).toList();

  int get activeCount => visibleRules.where((r) => r.active).length;
  int get totalRuns => visibleRules.fold(0, (sum, r) => sum + r.runs);

  double get successRate {
    final real = logs.where((l) => l.isCustomerRun).toList();
    if (real.isEmpty) return 100;
    return real.where((l) => l.success).length / real.length * 100;
  }

  Future<void> load() async {
    if (loading || !_channel.isInstagram) return;
    loading = true;
    error = null;
    notifyListeners();

    try {
      final existing = _rules.where((r) => r.channel.isInstagram).toList();
      final loaded = await _service.fetchInstagramRules(existing: existing);
      _rules
        ..removeWhere((r) => r.channel.isInstagram)
        ..insertAll(0, loaded);
    } catch (e) {
      error = 'Could not load automations: ${cleanError(e)}';
      debugPrint(error);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void onRulePublished(AutomationRule rule) {
    _rules
      ..removeWhere((r) => r.id == rule.id)
      ..insert(0, rule);
    logs.insert(
      0,
      ActivityLog(ruleName: rule.name, contact: 'You', detail: 'Automation is live'),
    );
    tab = DashboardTab.automations;
    builderTrigger = null;
    notifyListeners();
  }

  Future<bool> toggle(AutomationRule rule, bool on) async {
    final previous = rule.active;
    rule.active = on;
    error = null;
    notifyListeners();

    try {
      if (rule.channel.isInstagram) await _service.setActive(rule, on);
      logs.insert(
        0,
        ActivityLog(
          ruleName: rule.name,
          contact: 'You',
          detail: on ? 'Resumed' : 'Paused',
        ),
      );
      return true;
    } catch (e) {
      rule.active = previous;
      error = 'Could not update automation: ${cleanError(e)}';
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> delete(AutomationRule rule) async {
    error = null;
    try {
      if (rule.channel.isInstagram) await _service.delete(rule.id);
      _rules.remove(rule);
      return true;
    } catch (e) {
      error = 'Could not delete automation: ${cleanError(e)}';
      return false;
    } finally {
      notifyListeners();
    }
  }

  void sendTest(AutomationRule rule) {
    rule.runs++;
    logs.insert(
      0,
      ActivityLog(
        ruleName: rule.name,
        contact: 'Test contact',
        detail: 'Reply sent: ${rule.message}',
        isTest: true,
      ),
    );
    notifyListeners();
  }

  // ───────────── inbox ─────────────
  final List<InboxThread> threads = [];
  InboxThread? selectedThread;

  void selectThread(InboxThread? t) {
    selectedThread = t;
    notifyListeners();
  }
}
