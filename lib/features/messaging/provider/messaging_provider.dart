import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:raigon_art/features/messaging/models/trigger_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/automation.dart';
import '../models/channel.dart';
import '../models/chat.dart';

class MessagingAutomationProvider extends ChangeNotifier {
  final Map<Channel, String> accounts = {};
  final List<Automation> automations = [];
  final List<Convo> convos = [];

  int tab = 0;
  bool loadingAutomations = false;
  String? automationError;

  static const _key = 'raigon_chat_v1';

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);

    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;

        final savedAccounts = data['accounts'];
        if (savedAccounts is Map) {
          savedAccounts.forEach((key, value) {
            try {
              accounts[Channel.values.byName(key.toString())] = value
                  .toString();
            } catch (_) {}
          });
        }

        final savedAutomations = data['automations'];
        if (savedAutomations is List) {
          automations.addAll(
            savedAutomations.map(
              (item) => Automation.fromJson(Map<String, dynamic>.from(item)),
            ),
          );
        }
      } catch (error) {
        debugPrint('Local AppState load failed: $error');
      }
    }

    await loadAutomations();
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _key,
      jsonEncode({
        'accounts': accounts.map((key, value) => MapEntry(key.name, value)),
        'automations': automations
            .map((automation) => automation.toJson())
            .toList(),
      }),
    );
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  Future<String?> refreshInstagramConnection() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    if (session == null) {
      throw Exception('Please sign in first.');
    }

    final response = await client.functions.invoke(
      'instagram-inbox',
      method: HttpMethod.get,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
      queryParameters: {'limit': '1'},
    );

    if (response.status != 200) {
      throw Exception('Could not check the Instagram connection.');
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    final username = data['account_username']?.toString().trim();

    if (username == null || username.isEmpty) {
      accounts.remove(Channel.instagram);
      _changed();
      return null;
    }

    accounts[Channel.instagram] = username;
    _changed();

    return username;
  }

  Future<String?> refreshWhatsAppConnection() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    if (session == null) {
      throw Exception('Please sign in first.');
    }

    final response = await client.functions.invoke(
      'whatsapp_inbox',
      method: HttpMethod.get,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
      queryParameters: {'account': 'true', 'limit': '1'},
    );

    if (response.status < 200 || response.status >= 300) {
      final data = response.data;
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(message ?? 'Could not load the WhatsApp inbox.');
    }

    if (response.data is! Map) {
      throw Exception('Unexpected WhatsApp inbox response.');
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    final accountName = data['account_name']?.toString().trim();
    final displayPhone = data['display_phone_number']?.toString().trim();

    final account = (accountName != null && accountName.isNotEmpty)
        ? accountName
        : displayPhone;

    if (account == null || account.isEmpty) {
      accounts.remove(Channel.whatsapp);
      _changed();
      return null;
    }

    accounts[Channel.whatsapp] = account;
    _changed();

    return account;
  }

  Map<String, dynamic> _toServerRule(Automation automation) {
    return {
      'id': automation.id,
      'name': automation.name,
      'channel': automation.channel.name,
      'trigger_type': _serverTrigger(automation.trigger),
      'keywords': automation.keywords,
      'reply_message': automation.message,
      'is_active': automation.live,
    };
  }

  String _serverTrigger(TriggerType trigger) {
    switch (trigger) {
      case TriggerType.keyword:
        return 'keyword';
      case TriggerType.anyMessage:
        return 'anyMessage';
      case TriggerType.postComment:
        return 'postComment';
      case TriggerType.storyReply:
        return 'storyReply';
    }
  }

  TriggerType _localTrigger(dynamic value) {
    switch (value?.toString()) {
      case 'keyword':
        return TriggerType.keyword;
      case 'anyMessage':
      case 'any_message':
        return TriggerType.anyMessage;
      case 'postComment':
      case 'post_comment':
        return TriggerType.postComment;
      case 'storyReply':
      case 'story_reply':
        return TriggerType.storyReply;
      default:
        return TriggerType.keyword;
    }
  }

  Automation _fromServerRule(Map<String, dynamic> row, Channel channel) {
    final keywords = row['keywords'];

    return Automation(
      id: row['id'].toString(),
      name: (row['name'] ?? '').toString(),
      channel: channel,
      trigger: _localTrigger(row['trigger_type']),
      keywords: keywords is List
          ? keywords.map((keyword) => keyword.toString()).toList()
          : <String>[],
      message: (row['reply_message'] ?? '').toString(),
      live: row['is_active'] == true,
      runs: 0,
    );
  }

  String _automationFunctionName(Channel channel) {
    return channel == Channel.instagram
        ? 'instagram-automations'
        : 'whatsapp-automations';
  }

  Future<Map<String, dynamic>> _callAutomationFunction({
    Channel channel = Channel.instagram,
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final session = _supabase.auth.currentSession;

    if (session == null) {
      throw Exception('Please sign in to Supabase first.');
    }

    final response = await _supabase.functions.invoke(
      _automationFunctionName(channel),
      method: HttpMethod.values.firstWhere(
        (httpMethod) => httpMethod.name.toUpperCase() == method,
        orElse: () => HttpMethod.get,
      ),
      body: body,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );

    final data = response.data;

    if (response.status < 200 || response.status >= 300) {
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(message ?? 'Automation request failed.');
    }

    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    throw Exception('Unexpected response from automation server.');
  }

  Future<void> loadAutomations() async {
    loadingAutomations = true;
    automationError = null;
    notifyListeners();

    final serverRules = <Automation>[];
    final errors = <String>[];

    // Load each channel independently so one endpoint failure does not block the other.
    for (final channel in Channel.values) {
      try {
        final result = await _callAutomationFunction(channel: channel);
        final rows = result['automations'];

        if (rows is! List) {
          throw Exception('The server did not return automation rules.');
        }

        serverRules.addAll(
          rows.whereType<Map>().map(
            (row) => _fromServerRule(Map<String, dynamic>.from(row), channel),
          ),
        );
      } catch (error) {
        errors.add('${channel.name}: $error');
        debugPrint('Loading ${channel.name} automations failed: $error');
      }
    }

    if (errors.length < Channel.values.length) {
      final successfullyLoaded = Channel.values
          .where(
            (channel) =>
                !errors.any((error) => error.startsWith('${channel.name}:')),
          )
          .toSet();

      automations.removeWhere(
        (automation) => successfullyLoaded.contains(automation.channel),
      );
      automations.addAll(
        serverRules.where(
          (automation) => successfullyLoaded.contains(automation.channel),
        ),
      );
      await _save();
    }

    final instagramErrors = errors.where(
      (error) => error.startsWith('instagram:'),
    );
    automationError = instagramErrors.isEmpty
        ? null
        : instagramErrors.join('\n');

    debugPrint('Automation load errors: ${errors.join(' | ')}');

    loadingAutomations = false;
    notifyListeners();
  }

  Future<void> _saveAutomationToServer(Automation automation) async {
    if (automation.channel == Channel.whatsapp &&
        automation.trigger != TriggerType.keyword &&
        automation.trigger != TriggerType.anyMessage) {
      throw Exception(
        'WhatsApp supports keyword and any-message triggers only.',
      );
    }

    final rule = _toServerRule(automation);
    final exists = await _findServerRule(automation.channel, automation.id);

    if (!exists) {
      rule.remove('id');
    }

    await _callAutomationFunction(
      channel: automation.channel,
      method: 'POST',
      body: {'rule': rule},
    );
  }

  Future<bool> _findServerRule(Channel channel, String id) async {
    final result = await _callAutomationFunction(channel: channel);
    final rows = result['automations'];

    if (rows is! List) return false;

    return rows.any((row) => row is Map && row['id']?.toString() == id);
  }

  Future<void> upsertAsync(Automation automation) async {
    final index = automations.indexWhere((item) => item.id == automation.id);

    if (index >= 0) {
      automations[index] = automation;
    } else {
      automations.insert(0, automation);
    }

    _changed();

    try {
      await _saveAutomationToServer(automation);
      await loadAutomations();
    } catch (error) {
      automationError = error.toString();
      debugPrint('Saving automation failed: $error');
      notifyListeners();
      rethrow;
    }
  }

  // Use upsertAsync when the builder must wait for server sync.
  void upsert(Automation automation) {
    final index = automations.indexWhere((item) => item.id == automation.id);

    if (index >= 0) {
      automations[index] = automation;
    } else {
      automations.insert(0, automation);
    }

    _changed();
  }

  Future<void> toggleAsync(Automation automation) async {
    final previousValue = automation.live;
    automation.live = !previousValue;
    _changed();

    try {
      await _saveAutomationToServer(automation);
      await loadAutomations();
    } catch (error) {
      automation.live = previousValue;
      automationError = error.toString();
      _changed();
      rethrow;
    }
  }

  void toggle(Automation automation) {
    automation.live = !automation.live;
    _changed();
  }

  Future<void> removeAsync(Automation automation) async {
    automations.removeWhere((item) => item.id == automation.id);
    _changed();

    try {
      await _callAutomationFunction(
        channel: automation.channel,
        method: 'POST',
        body: {'action': 'delete', 'id': automation.id},
      );
      await loadAutomations();
    } catch (error) {
      automationError = error.toString();
      debugPrint('Deleting automation failed: $error');
      await loadAutomations();
      rethrow;
    }
  }

  void remove(Automation automation) {
    automations.removeWhere((item) => item.id == automation.id);
    _changed();
  }

  void countRun(Automation automation) {
    automation.runs++;
    _changed();
  }

  void setTab(int index) {
    tab = index;
    notifyListeners();
  }

  void connect(Channel channel, String id) {
    accounts[channel] = id;
    _changed();
  }

  void disconnect(Channel channel) {
    accounts.remove(channel);

    for (final automation in automations.where(
      (item) => item.channel == channel,
    )) {
      automation.live = false;
    }

    _changed();
  }

  void log(Channel channel, ChatMsg message) {
    final contact = channel.isIg ? '@test_customer' : '+91 90000 00000';
    var conversation = convos
        .where((item) => item.channel == channel)
        .firstOrNull;

    if (conversation == null) {
      conversation = Convo(channel, contact);
      convos.insert(0, conversation);
    }

    conversation.msgs.add(message);
    notifyListeners();
  }

  Future<void> connectChannel(BuildContext context, Channel channel) async {
    try {
      if (channel.isIg) {
        // First check whether Instagram is already connected.
        final username = await refreshInstagramConnection();

        if (!context.mounted) return;

        if (username != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Connected to @$username')));
          return;
        }

        // Start Instagram Login through the new Supabase Edge Function.
        final oauthUri = Uri.parse(
          'https://nhqewkbztfmlophtzqmk.supabase.co/'
          'functions/v1/instagram-oauth?action=start',
        );

        final launched = await launchUrl(
          oauthUri,
          mode: LaunchMode.externalApplication,
        );

        if (!context.mounted) return;

        if (!launched) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Instagram login.')),
          );
        }

        return;
      }

      // Keep the existing WhatsApp flow unchanged.
      final account = await refreshWhatsAppConnection();

      if (!context.mounted) return;

      if (account != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('WhatsApp connected: $account')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'WhatsApp account details were not returned. '
              'Check your whatsapp_inbox Edge Function.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not connect channel: $e')));
    }
  }
}
