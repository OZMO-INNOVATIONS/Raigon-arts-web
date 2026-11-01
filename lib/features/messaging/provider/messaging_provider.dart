import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:raigon_art/core/utils/helper.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
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
          for (final item in savedAutomations) {
            try {
              final automation = Automation.fromJson(
                Map<String, dynamic>.from(item),
              );
              if (automation.channel == Channel.instagram) {
                automations.add(automation);
              }
            } catch (error) {
              // Ignore legacy entries for channels no longer supported.
              debugPrint('Skipping unsupported saved automation: $error');
            }
          }
        }
      } catch (error) {
        debugPrint('Local AppState load failed: $error');
      }
    }

    // Refresh the Instagram username from Supabase so a newly authorized
    // account replaces any stale locally cached username after the app reloads.
    try {
      await refreshInstagramConnection();
    } catch (error) {
      // Keep the app usable if Instagram is not connected or the inbox is
      // temporarily unavailable. The existing cached state is preserved.
      debugPrint('Instagram connection refresh during load failed: $error');
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
    final stopwatch = Stopwatch()..start();

    Helper.igLog(
      'CHECK_START',
      details: 'Checking Instagram connection using instagram-inbox',
    );

    try {
      final client = _supabase;
      final session = client.auth.currentSession;

      Helper.igLog(
        'AUTH_CHECK',
        details: 'Supabase session available: ${session != null}',
      );

      if (session == null) {
        throw Exception('Please sign in first.');
      }

      Helper.igLog(
        'REQUEST_START',
        details: 'Function=instagram-inbox, method=GET, limit=1',
      );

      final response = await client.functions.invoke(
        'instagram-inbox',
        method: HttpMethod.get,
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        queryParameters: {'limit': '1'},
      );

      Helper.igLog(
        'REQUEST_RESPONSE',
        details:
            'HTTP ${response.status}; '
            'responseType=${response.data.runtimeType}',
      );

      if (response.status < 200 || response.status >= 300) {
        final data = response.data;
        final message = data is Map ? data['error']?.toString() : null;

        throw Exception(
          message ??
              'Instagram connection check failed: HTTP ${response.status}',
        );
      }

      if (response.data is! Map) {
        throw Exception('Unexpected Instagram inbox response.');
      }

      final data = Map<String, dynamic>.from(response.data as Map);

      Helper.igLog(
        'RESPONSE_FIELDS',
        details: 'Fields returned: ${data.keys.join(', ')}',
      );

      final rawUsername = data['account_username']?.toString().trim();

      if (rawUsername == null || rawUsername.isEmpty) {
        accounts.remove(Channel.instagram);
        await _save();
        notifyListeners();

        Helper.igLog(
          'CHECK_COMPLETE',
          details:
              'No account_username returned; '
              'elapsed=${stopwatch.elapsedMilliseconds}ms',
        );

        return null;
      }

      final username = rawUsername.startsWith('@')
          ? rawUsername.substring(1)
          : rawUsername;

      accounts[Channel.instagram] = username;

      await _save();
      notifyListeners();

      Helper.igLog(
        'CHECK_COMPLETE',
        details:
            'Connected account=@$username; '
            'elapsed=${stopwatch.elapsedMilliseconds}ms',
      );

      return username;
    } catch (error, stackTrace) {
      Helper.igLog(
        'CHECK_FAILED',
        details: 'elapsed=${stopwatch.elapsedMilliseconds}ms',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    } finally {
      stopwatch.stop();
    }
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

      // Audit information
      createdBy: row['created_by']?.toString(),
      createdByRole: row['created_by_role']?.toString(),
      updatedBy: row['updated_by']?.toString(),
      updatedByRole: row['updated_by_role']?.toString(),
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'].toString())
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.tryParse(row['updated_at'].toString())
          : null,
    );
  }

  String _automationFunctionName() => 'instagram-automations';

  Future<Map<String, dynamic>> _callAutomationFunction({
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final session = _supabase.auth.currentSession;

    if (session == null) {
      throw Exception('Please sign in to Supabase first.');
    }

    final response = await _supabase.functions.invoke(
      _automationFunctionName(),
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
    try {
      final result = await _callAutomationFunction();
      final rows = result['automations'];

      if (rows is! List) {
        throw Exception('The server did not return automation rules.');
      }

      serverRules.addAll(
        rows.whereType<Map>().map(
          (row) => _fromServerRule(
            Map<String, dynamic>.from(row),
            Channel.instagram,
          ),
        ),
      );

      automations.removeWhere(
        (automation) => automation.channel == Channel.instagram,
      );
      automations.addAll(serverRules);
      await _save();
    } catch (error) {
      automationError = error.toString();
      debugPrint('Loading Instagram automations failed: $error');
    }

    loadingAutomations = false;
    notifyListeners();
  }

  Future<void> _saveAutomationToServer(Automation automation) async {
    final rule = _toServerRule(automation);
    final exists = await _findServerRule(automation.id);

    if (!exists) {
      rule.remove('id');
    }

    await _callAutomationFunction(method: 'POST', body: {'rule': rule});
  }

  Future<bool> _findServerRule(String id) async {
    final result = await _callAutomationFunction();
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
    const contact = '@test_customer';
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

  Future<void> connectChannel(
    BuildContext context,
    Channel channel, {
    bool switchAccount = false,
  }) async {
    Helper.igLog(
      'CONNECT_START',
      details: 'Instagram; switchAccount=$switchAccount',
    );

    try {
      String? account;

      try {
        account = await refreshInstagramConnection();
      } catch (error, stackTrace) {
        Helper.igLog(
          'CONNECTION_CHECK_ERROR',
          details: 'Instagram connection check failed',
          error: error,
          stackTrace: stackTrace,
        );

        // Do not silently start a new OAuth flow if the check failed.
        rethrow;
      }

      if (!context.mounted) return;

      if (account != null && account.isNotEmpty && !switchAccount) {
        Helper.igLog(
          'ALREADY_CONNECTED',
          details: 'Instagram account=@$account',
        );

        AppSnackBar.success(context, 'Instagram already connected: @$account');
        return;
      }

      Helper.igLog(
        'OAUTH_START',
        details: switchAccount
            ? 'Opening Instagram OAuth to switch accounts'
            : 'No connected account found; opening Instagram OAuth',
      );

      final oauthUri = Uri.parse(
        'https://nhqewkbztfmlophtzqmk.supabase.co/'
        'functions/v1/instagram-oauth?action=start',
      );

      Helper.igLog(
        'OAUTH_URL',
        details: '${oauthUri.origin}${oauthUri.path}?action=start',
      );

      final launched = await launchUrl(
        oauthUri,
        mode: LaunchMode.externalApplication,
      );

      Helper.igLog(
        'OAUTH_LAUNCH_RESULT',
        details: 'launchUrl returned: $launched',
      );

      if (!context.mounted) return;

      if (!launched) {
        AppSnackBar.error(context, 'Could not open Instagram login.');
      } else if (switchAccount) {
        AppSnackBar.success(
          context,
          'Complete Instagram authorization in the opened tab, '
          'then return to Raigon Art and refresh the page.',
        );
      }
    } catch (error, stackTrace) {
      Helper.igLog(
        'CONNECT_FAILED',
        details: 'Channel=instagram',
        error: error,
        stackTrace: stackTrace,
      );

      if (!context.mounted) return;

      AppSnackBar.error(context, 'Could not connect Instagram: $error');
    }
  }
}
