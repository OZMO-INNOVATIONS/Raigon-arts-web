import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/features/messaging/models/channel.dart';
import 'package:raigon_art/features/messaging/provider/messaging_provider.dart';
import 'package:raigon_art/features/messaging/services/inbox_read_state_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/channel_style.dart';
import '../widgets/inbox_widgets.dart';

// ─────────────────────────────────────────────────────────────
// Instagram data layer (unchanged)
// ─────────────────────────────────────────────────────────────

class InstagramInboxMessage {
  const InstagramInboxMessage({
    required this.id,
    required this.senderId,
    this.senderUsername,
    this.senderProfilePicture,
    required this.messageId,
    required this.text,
    required this.direction,
    required this.createdAt,
  });

  final int id;
  final String senderId;
  final String? senderUsername;
  final String? senderProfilePicture;
  final String messageId;
  final String text;
  final String direction;
  final DateTime createdAt;

  bool get fromBot => direction == 'outgoing';

  factory InstagramInboxMessage.fromJson(Map<String, dynamic> json) {
    return InstagramInboxMessage(
      id: int.tryParse('${json['id']}') ?? 0,
      senderId: '${json['sender_id'] ?? ''}',
      senderUsername: (json['sender_username'] as String?)?.trim(),
      senderProfilePicture: json['sender_profile_picture']?.toString(),
      messageId: '${json['message_id'] ?? ''}',
      text: '${json['message_text'] ?? ''}',
      direction: '${json['direction'] ?? 'incoming'}',
      createdAt:
          DateTime.tryParse('${json['created_at'] ?? ''}')?.toLocal() ??
          DateTime.now(),
    );
  }
}

class InstagramInboxService {
  static const String endpoint =
      'https://nhqewkbztfmlophtzqmk.supabase.co'
      '/functions/v1/instagram-inbox';

  Future<List<InstagramInboxMessage>> fetchMessages() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      throw Exception('Please sign in to access the Instagram Inbox.');
    }

    final uri = Uri.parse(endpoint)
        .replace(queryParameters: const {'limit': '200'});

    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${session.accessToken}',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      dynamic errorBody;
      try {
        errorBody = jsonDecode(response.body);
      } catch (_) {}
      final errorMsg = errorBody is Map ? errorBody['error']?.toString() : null;
      throw Exception(
        errorMsg ?? 'Inbox API returned HTTP ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic> ||
        decoded['success'] != true ||
        decoded['messages'] is! List) {
      throw Exception('Unexpected Inbox API response.');
    }

    return (decoded['messages'] as List)
        .whereType<Map<String, dynamic>>()
        .map(InstagramInboxMessage.fromJson)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> sendMessage({
    required String recipientId,
    required String message,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      throw Exception('Please sign in to send messages.');
    }

    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${session.accessToken}',
          },
          body: jsonEncode({'recipient_id': recipientId, 'message': message}),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200 ||
        decoded is! Map<String, dynamic> ||
        decoded['success'] != true) {
      final error = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;

      throw Exception(error ?? 'Failed to send Instagram message.');
    }

    if (decoded['saved'] == false) {
      throw Exception(
        'Instagram accepted the message, but saving it to the inbox failed. '
        'Refresh the inbox before trying again.',
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Inbox page
// ─────────────────────────────────────────────────────────────

/// Inbox page. The "Inbox" page header is unchanged; everything below it
/// is the new Messages workspace (list panel + thread).
class InboxPage extends StatelessWidget {
  const InboxPage({super.key, required this.s});

  final MessagingAutomationProvider s;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(28, 24, 28, 14)),
          const Expanded(child: _InboxWorkspace()),
        ],
      ),
    );
  }
}

/// One row in the Instagram conversation list.
class _Convo {
  const _Convo({
    required this.channel,
    required this.key,
    required this.name,
    required this.preview,
    required this.time,
    required this.incoming,
    this.avatarUrl,
  });

  final Channel channel;
  final String key; // Instagram sender ID
  final String name;
  final String preview;
  final DateTime time;
  final bool incoming; // latest message came from the customer
  final String? avatarUrl;

  String get id => 'instagram:$key';
}

class _InboxWorkspace extends StatefulWidget {
  const _InboxWorkspace();

  @override
  State<_InboxWorkspace> createState() => _InboxWorkspaceState();
}

class _InboxWorkspaceState extends State<_InboxWorkspace> {
  static const _pollEvery = Duration(seconds: 3);

  final InstagramInboxService _igService = InstagramInboxService();
  final InboxReadStateService _readStateService = InboxReadStateService();

  final Map<String, DateTime> _readAt = {};
  bool _readStatesLoaded = false;

  // ── shared UI state
  bool _unreadOnly = false;
  bool _latestFirst = true;
  bool _mobileThread = false; // narrow layout: showing thread instead of list
  // user has picked a conversation themselves
  // Chats opened while the unread filter is on stay in the list; only their
  // unread dot is cleared.
  final Set<String> _keepVisible = {};

  // ── Instagram
  List<InstagramInboxMessage> _igMessages = [];
  String? _igError;
  bool _igLoading = false;
  String? _igSelected;
  int _igVersion = 0;
  final TextEditingController _igText = TextEditingController();
  bool _igSending = false;
  Timer? _igPoll;
  bool _igPolling = false;
  dynamic _igChannel;
  Timer? _igDebounce;

  AppPalette get p => AppPalette.of(context);

  // ───────────────────────── lifecycle ─────────────────────────

  @override
  void initState() {
    super.initState();

    _loadReadStates();
    _subscribeIg();
    _refreshIg();

    // Polling is a fallback in case Supabase Realtime is unavailable.
    _igPoll = Timer.periodic(_pollEvery, (_) async {
      if (!mounted || _igPolling || _igLoading || _igSending) return;
      _igPolling = true;
      try {
        await _refreshIg(silent: true);
      } finally {
        _igPolling = false;
      }
    });
  }

  @override
  void dispose() {
    _igDebounce?.cancel();
    _igPoll?.cancel();
    if (_igChannel != null) {
      Supabase.instance.client.removeChannel(_igChannel);
    }
    _igText.dispose();
    super.dispose();
  }

  void _subscribeIg() {
    // Realtime must be enabled for public.instagram_messages.
    _igChannel = Supabase.instance.client
        .channel('instagram-inbox-live-updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'instagram_messages',
          callback: (payload) {
            _igDebounce?.cancel();
            _igDebounce = Timer(const Duration(milliseconds: 250), () {
              if (mounted) _refreshIg(silent: true);
            });
          },
        )
        .subscribe();
  }

  Future<void> _loadReadStates() async {
    try {
      final states = await _readStateService.loadReadStates();

      if (!mounted) return;

      setState(() {
        _readAt
          ..clear()
          ..addAll(states);
        _readStatesLoaded = true;
      });
    } catch (e) {
      debugPrint('Could not load inbox read states: $e');
    }
  }

  Future<void> _markConversationRead(_Convo c) async {
    final latestIncoming = _latestIncomingAt(c);
    if (latestIncoming == null) return;

    final previousRead = _readAt[c.id];

    // Don't save the same timestamp repeatedly.
    if (previousRead != null && !latestIncoming.isAfter(previousRead)) {
      return;
    }

    // Update immediately so the badge disappears without waiting for
    // the database request.
    setState(() {
      _readAt[c.id] = latestIncoming;
    });

    try {
      await _readStateService.markRead(
        channel: c.channel.name,
        conversationKey: c.key,
        lastReadAt: latestIncoming,
      );
    } catch (e) {
      debugPrint('Could not save inbox read state: $e');
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;

    if (error) {
      AppSnackBar.error(context, message);
    } else {
      AppSnackBar.success(context, message);
    }
  }

  // ───────────────────────── Instagram logic ─────────────────────────

  Map<String, List<InstagramInboxMessage>> _igGroups(
    List<InstagramInboxMessage> messages,
  ) {
    final groups = <String, List<InstagramInboxMessage>>{};
    for (final message in messages) {
      if (message.senderId.isEmpty) continue;
      groups.putIfAbsent(message.senderId, () => []).add(message);
    }
    for (final group in groups.values) {
      group.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    return groups;
  }

  String _igName(String senderId, List<InstagramInboxMessage> messages) {
    for (final message in messages) {
      final username = message.senderUsername?.trim();
      if (username != null && username.isNotEmpty) {
        return username.startsWith('@') ? username : '@$username';
      }
    }
    return senderId;
  }

  String? _igAvatar(List<InstagramInboxMessage> messages) {
    for (final message in messages.reversed) {
      final url = message.senderProfilePicture?.trim();
      if (url != null && url.isNotEmpty && url != 'null') return url;
    }
    return null;
  }

  String? _latestIgSender(List<InstagramInboxMessage> messages) {
    for (final message in messages.reversed) {
      if (message.senderId.isNotEmpty) return message.senderId;
    }
    return null;
  }

  Future<void> _refreshIg({bool silent = false}) async {
    final version = ++_igVersion;

    if (mounted && !silent) {
      setState(() {
        _igLoading = true;
        _igError = null;
      });
    }

    try {
      final messages = await _igService.fetchMessages();
      if (!mounted || version != _igVersion) return;

      setState(() {
        _igMessages = messages;
        _igLoading = false;
        _igError = null;

        final ids = _igGroups(messages).keys.toSet();
        if (_igSelected == null || !ids.contains(_igSelected)) {
          _igSelected = _latestIgSender(messages);
        }
      });
    } catch (e) {
      if (!mounted || version != _igVersion) return;

      if (silent) {
        debugPrint('Instagram auto-refresh failed: $e');
        return;
      }

      setState(() {
        _igLoading = false;
        _igError = e.toString();
      });
    }
  }

  Future<void> _sendIg() async {
    final recipientId = _igSelected;
    final message = _igText.text.trim();

    if (recipientId == null || recipientId.isEmpty) return;
    if (message.isEmpty || _igSending) return;

    setState(() => _igSending = true);

    try {
      await _igService.sendMessage(recipientId: recipientId, message: message);
      if (!mounted) return;
      _igText.clear();
      _snack('Instagram message sent successfully.');
      await _refreshIg();
    } catch (e) {
      _snack('Could not send message: $e', error: true);
    } finally {
      if (mounted) setState(() => _igSending = false);
    }
  }

  List<_Convo> _igItems() {
    final items = <_Convo>[];
    _igGroups(_igMessages).forEach((id, messages) {
      final last = messages.last;
      items.add(
        _Convo(
          channel: Channel.instagram,
          key: id,
          name: _igName(id, messages),
          preview: last.text.isEmpty ? 'Message' : last.text,
          time: last.createdAt,
          incoming: !last.fromBot,
          avatarUrl: _igAvatar(messages),
        ),
      );
    });
    return items;
  }

  // ───────────────────────── list state helpers ─────────────────────────

  DateTime? _latestIncomingAt(_Convo c) {
    final messages =
        _igGroups(_igMessages)[c.key] ?? const <InstagramInboxMessage>[];

    DateTime? latest;
    for (final message in messages) {
      if (message.fromBot) continue;
      if (latest == null || message.createdAt.isAfter(latest)) {
        latest = message.createdAt;
      }
    }
    return latest;
  }

  bool _isUnread(_Convo c) => _unreadMessageCount(c) > 0;

  List<_Convo> _view(List<_Convo> items) {
    final list = _unreadOnly
        ? items
              .where((c) => _isUnread(c) || _keepVisible.contains(c.id))
              .toList()
        : [...items];
    list.sort(
      (a, b) =>
          _latestFirst ? b.time.compareTo(a.time) : a.time.compareTo(b.time),
    );
    return list;
  }

  void _select(_Convo c) {
    _keepVisible.add(c.id);
    setState(() {
      _igSelected = c.key;
      _mobileThread = true;
    });
    _markConversationRead(c);
  }

  // ───────────────────────── left panel ─────────────────────────

  Widget _tile(_Convo c) {
    final selected = c.key == _igSelected;
    final unreadCount = _unreadMessageCount(c);

    return ConversationTile(
      selected: selected,
      unread: unreadCount > 0,
      unreadCount: unreadCount,
      isInstagram: true,
      name: c.name,
      time: formatInboxListTime(c.time),
      preview: c.preview,
      indicatorColor: p.accent,
      onTap: () => _select(c),
      avatar: AvatarWithBadge(
        label: c.name,
        channel: c.channel,
        imageUrl: c.avatarUrl,
      ),
    );
  }

  int _unreadMessageCount(_Convo c) {
    if (!_readStatesLoaded) return 0;
    final lastRead = _readAt[c.id];

    return _igMessages.where((message) {
      if (message.senderId != c.key || message.fromBot) return false;
      return lastRead == null || message.createdAt.isAfter(lastRead);
    }).length;
  }

  Widget _channelHint(List<_Convo> all) {
    if (all.isEmpty && _igLoading) {
      return const InboxListHint(message: '', loading: true);
    }
    if (all.isEmpty && _igError != null) {
      return InboxListHint(message: _igError!, onRetry: _refreshIg);
    }
    if (all.isEmpty) {
      return const InboxListHint(message: 'No Instagram messages yet.');
    }
    return const InboxListHint(message: 'No unread conversations.');
  }

  Widget _listPanel() {
    final activeAll = _igItems();
    final active = _view(activeAll);

    return ColoredBox(
      color: p.surface,
      child: Column(
        children: [
          MessagesPanelHeader(
            filterActive: _unreadOnly,
            onFilter: () => setState(() {
              _unreadOnly = !_unreadOnly;
              _keepVisible.clear();
            }),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: SortRow(
              count: active.length,
              latestFirst: _latestFirst,
              onChanged: (v) => setState(() => _latestFirst = v),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 18),
              children: [
                if (active.isEmpty)
                  _channelHint(activeAll)
                else
                  for (final c in active) _tile(c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── thread ─────────────────────────

  List<Widget> _dayList<T>(
    List<T> items,
    DateTime Function(T) at,
    Widget Function(T) build,
  ) {
    final out = <Widget>[];
    DateTime? previous;
    for (final item in items) {
      final date = at(item);
      if (previous == null || !isSameInboxDay(previous, date)) {
        out.add(DateChip(formatInboxDay(date)));
      }
      out.add(build(item));
      previous = date;
    }
    // The thread ListView is reversed so it opens at the newest message.
    return out.reversed.toList();
  }

  Widget _igBubble(InstagramInboxMessage m, String display, String? avatarUrl) {
    final bot = m.fromBot;
    return InboxBubble(
      outgoing: bot,
      sender: bot ? null : display,
      text: m.text,
      time: formatInboxTime(m.createdAt),
      outgoingGradient: ChannelColors.igBubble,
      avatar: bot
          ? null
          : AvatarWithBadge(
              label: display,
              channel: Channel.instagram,
              size: 38,
              imageUrl: avatarUrl,
            ),
    );
  }

  Widget _backButton() => IconButton(
    tooltip: 'Back to messages',
    onPressed: () => setState(() => _mobileThread = false),
    icon: Icon(Icons.arrow_back_rounded, color: p.textPrimary),
  );

  Widget _thread(bool narrow) {
    final key = _igSelected;
    const accent = ChannelColors.ig;

    if (key == null) {
      return ColoredBox(
        color: p.pageBg,
        child: Column(
          children: [
            if (narrow)
              Align(alignment: Alignment.centerLeft, child: _backButton()),
            Expanded(
              child: _igLoading
                  ? Center(child: CircularProgressIndicator(color: p.accent))
                  : InboxEmptyState(
                      icon: Icons.forum_outlined,
                      title: 'No conversation selected',
                      message:
                          'New messages received by your connected Instagram '
                          'account will appear here.',
                      color: accent,
                      action: TintedButton(
                        onPressed: _refreshIg,
                        icon: Icons.refresh,
                        label: 'Refresh',
                        gradient: ChannelColors.igBubble,
                        color: accent,
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    final messages =
        _igGroups(_igMessages)[key] ?? const <InstagramInboxMessage>[];
    final display = _igName(key, messages);
    final avatarUrl = _igAvatar(messages);
    final subtitle = 'Instagram DM';
    final error = _igError == null ? null : 'Refresh failed: $_igError';
    final items = _dayList<InstagramInboxMessage>(
      messages,
      (m) => m.createdAt,
      (m) => _igBubble(m, display, avatarUrl),
    );

    final Widget body = items.isEmpty
        ? InboxEmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'No messages yet',
            message: 'Messages from this Instagram user will appear here.',
            color: accent,
          )
        : ListView(
            key: ValueKey('instagram:$key'),
            reverse: true,
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 12),
            children: items,
          );

    return Column(
      children: [
        ThreadHeader(
          leading: narrow ? _backButton() : null,
          avatar: AvatarWithBadge(
            label: display,
            channel: Channel.instagram,
            size: 48,
            imageUrl: avatarUrl,
          ),
          title: display,
          subtitle: subtitle,
        ),
        if (error != null)
          MaterialBanner(
            backgroundColor: p.amberSoft,
            content: Text(error),
            actions: [
              TextButton(onPressed: _refreshIg, child: const Text('Retry')),
            ],
          ),
        Expanded(
          child: ColoredBox(color: p.pageBg, child: body),
        ),
        _composer(),
      ],
    );
  }

  Widget _composer() {
    final ready = _igSelected != null;
    return ComposerBar(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _igText,
              minLines: 1,
              maxLines: 4,
              maxLength: 1000,
              enabled: ready && !_igSending,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              keyboardType: TextInputType.text,
              onSubmitted: (_) => _sendIg(),
              decoration: inboxPillField(p, 'Message on Instagram…'),
            ),
          ),
          const SizedBox(width: 10),
          SendButton(
            tooltip: 'Send Instagram message',
            busy: _igSending,
            onPressed: !ready || _igSending ? null : _sendIg,
          ),
        ],
      ),
    );
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 860;

    return InboxFrame(
      child: narrow
          ? (_mobileThread ? _thread(true) : _listPanel())
          : Row(
              children: [
                SizedBox(width: 344, child: _listPanel()),
                VerticalDivider(width: 1, color: p.border),
                Expanded(child: _thread(false)),
              ],
            ),
    );
  }
}
