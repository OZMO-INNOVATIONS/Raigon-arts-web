import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:raigon_art/core/constants/asset_constants.dart';
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
      throw Exception('Inbox API returned HTTP ${response.statusCode}.');
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
// WhatsApp data layer (unchanged)
// ─────────────────────────────────────────────────────────────

class WhatsAppInboxMessage {
  const WhatsAppInboxMessage({
    required this.id,
    required this.phone,
    required this.direction,
    required this.text,
    required this.createdAt,
    this.messageId,
    this.customerName,
    this.status,
    this.messageType = 'text',
    this.audioMediaId,
    this.audioMimeType,
    this.audioVoice = false,
    this.unreadCount = 0,
  });

  final int id;
  final String phone;
  final String direction;
  final String text;
  final DateTime createdAt;
  final String? messageId;
  final String? customerName;
  final String? status;
  final String messageType;
  final String? audioMediaId;
  final String? audioMimeType;
  final bool audioVoice;
  final int unreadCount;

  bool get isOutgoing => direction == 'outgoing';
  bool get isAudio =>
      messageType == 'audio' || (audioMediaId?.isNotEmpty ?? false);

  factory WhatsAppInboxMessage.fromJson(Map<String, dynamic> json) {
    return WhatsAppInboxMessage(
      id: int.tryParse('${json['id']}') ?? 0,
      phone: '${json['customer_phone'] ?? ''}',
      direction: '${json['direction'] ?? 'incoming'}',
      text: '${json['message_text'] ?? ''}',
      messageId: json['wa_message_id']?.toString(),
      customerName: json['customer_name']?.toString(),
      status: json['message_status']?.toString(),
      messageType: '${json['message_type'] ?? 'text'}',
      audioMediaId: json['audio_media_id']?.toString(),
      audioMimeType: json['audio_mime_type']?.toString(),
      audioVoice: json['audio_voice'] == true,
      unreadCount: int.tryParse('${json['unread_count'] ?? 0}') ?? 0,
      createdAt:
          DateTime.tryParse('${json['created_at'] ?? ''}')?.toLocal() ??
          DateTime.now(),
    );
  }
}

class WhatsAppInboxService {
  static const String endpoint =
      'https://nhqewkbztfmlophtzqmk.supabase.co/functions/v1/whatsapp_inbox';

  Future<Map<String, dynamic>> _request({
    required String method,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw Exception('Please sign in to access WhatsApp Inbox.');
    }

    final uri = Uri.parse(endpoint).replace(queryParameters: queryParameters);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${session.accessToken}',
    };

    late http.Response response;
    if (method == 'POST') {
      response = await http
          .post(uri, headers: headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 30));
    } else {
      response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Invalid WhatsApp server response (${response.statusCode}).',
      );
    }

    if (decoded is! Map) {
      throw Exception('Unexpected WhatsApp server response.');
    }
    final data = Map<String, dynamic>.from(decoded);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['error']?.toString() ??
            'WhatsApp request failed (${response.statusCode}).',
      );
    }
    return data;
  }

  Future<List<WhatsAppInboxMessage>> fetchConversations() async {
    final data = await _request(
      method: 'GET',
      queryParameters: const {'limit': '500'},
    );
    if (data['success'] != true || data['conversations'] is! List) {
      throw Exception('Unexpected WhatsApp conversations response.');
    }

    final items = (data['conversations'] as List)
        .whereType<Map>()
        .map((e) => WhatsAppInboxMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<List<WhatsAppInboxMessage>> fetchMessages(String phone) async {
    final data = await _request(
      method: 'GET',
      queryParameters: {'phone': phone, 'limit': '500'},
    );
    if (data['success'] != true || data['messages'] is! List) {
      throw Exception('Unexpected WhatsApp message history response.');
    }

    final items = (data['messages'] as List)
        .whereType<Map>()
        .map((e) => WhatsAppInboxMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  Future<void> sendAudio({
    required String phone,
    required Uint8List bytes,
    required String mimeType,
    bool voice = true,
  }) async {
    final data = await _request(
      method: 'POST',
      body: {
        'action': 'send_audio',
        'to': phone,
        'audio_base64': base64Encode(bytes),
        'mime_type': mimeType,
        'voice': voice,
      },
    );
    if (data['success'] != true) {
      throw Exception(
        data['error']?.toString() ?? 'Failed to send WhatsApp audio.',
      );
    }
    if (data['saved'] == false) {
      throw Exception(
        'WhatsApp accepted the audio, but saving it to the inbox failed. Refresh the conversation.',
      );
    }
  }

  Future<Uint8List> fetchAudioBytes(String messageId) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Please sign in to play audio.');
    final uri = Uri.parse(endpoint)
        .replace(queryParameters: {'audio_message_id': messageId});
    final response = await http
        .get(
          uri,
          headers: {
            'Accept': '*/*',
            'Authorization': 'Bearer ${session.accessToken}',
          },
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Could not load voice message (${response.statusCode}).');
    }
    return response.bodyBytes;
  }

  Future<void> sendMessage({
    required String phone,
    required String message,
  }) async {
    final data = await _request(
      method: 'POST',
      body: {'action': 'send', 'to': phone, 'message': message},
    );
    if (data['success'] != true) {
      throw Exception(
        data['error']?.toString() ?? 'Failed to send WhatsApp message.',
      );
    }
    if (data['saved'] == false) {
      throw Exception(
        'Meta accepted the message, but saving it to the inbox failed. '
        'Refresh the conversation before sending again.',
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

/// One row of the left conversation list (either channel).x
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
  final String key; // Instagram sender id / WhatsApp phone
  final String name;
  final String preview;
  final DateTime time;
  final bool incoming; // latest message came from the customer
  final String? avatarUrl;

  String get id => '${channel.name}:$key';
}

class _InboxWorkspace extends StatefulWidget {
  const _InboxWorkspace();

  @override
  State<_InboxWorkspace> createState() => _InboxWorkspaceState();
}

class _InboxWorkspaceState extends State<_InboxWorkspace> {
  static const _pollEvery = Duration(seconds: 3);

  final InstagramInboxService _igService = InstagramInboxService();
  final WhatsAppInboxService _waService = WhatsAppInboxService();
  final InboxReadStateService _readStateService = InboxReadStateService();

  final Map<String, DateTime> _readAt = {};
  bool _readStatesLoaded = false;

  // ── shared UI state
  Channel _tab = Channel.instagram; // which list is the primary one
  Channel _open = Channel.instagram; // which thread is on screen
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

  // ── WhatsApp
  List<WhatsAppInboxMessage> _waConvos = [];
  List<WhatsAppInboxMessage> _waMessages = [];
  String? _waSelected;
  String? _waError;
  bool _waLoading = false;
  bool _waLoadingMessages = false;
  bool _waSending = false;
  int _waVersion = 0;
  final TextEditingController _waText = TextEditingController();
  dynamic _waChannel;
  Timer? _waDebounce;
  Timer? _waPoll;
  bool _waPolling = false;
  html.MediaStream? _recordingStream;
  html.MediaRecorder? _mediaRecorder;
  final List<html.Blob> _recordingChunks = [];
  bool _recording = false;
  bool _sendingAudio = false;
  DateTime? _recordingStartedAt;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  final Map<String, String> _audioObjectUrls = {};
  final Set<String> _playingAudio = {};

  AppPalette get p => AppPalette.of(context);

  // ───────────────────────── lifecycle ─────────────────────────

  @override
  void initState() {
    super.initState();

    _loadReadStates();
    _refreshWa();
    _subscribeIg();
    _subscribeWa();
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

    _waPoll = Timer.periodic(_pollEvery, (_) async {
      if (!mounted ||
          _waPolling ||
          _waLoading ||
          _waLoadingMessages ||
          _waSending) {
        return;
      }
      _waPolling = true;
      try {
        await _refreshWa(silent: true);
      } finally {
        _waPolling = false;
      }
    });
  }

  @override
  void dispose() {
    _igDebounce?.cancel();
    _waDebounce?.cancel();
    _igPoll?.cancel();
    _waPoll?.cancel();
    if (_igChannel != null) {
      Supabase.instance.client.removeChannel(_igChannel);
    }
    if (_waChannel != null) {
      Supabase.instance.client.removeChannel(_waChannel);
    }
    _recordingTimer?.cancel();
    _stopTracks();
    for (final url in _audioObjectUrls.values) {
      html.Url.revokeObjectUrl(url);
    }
    _igText.dispose();
    _waText.dispose();
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

  void _subscribeWa() {
    // Realtime must be enabled for public.whatsapp_inbox_messages.
    _waChannel = Supabase.instance.client
        .channel('whatsapp-inbox-live-updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'whatsapp_inbox_messages',
          callback: (payload) {
            _waDebounce?.cancel();
            _waDebounce = Timer(const Duration(milliseconds: 250), () {
              if (mounted) _refreshWa(silent: true);
            });
          },
        )
        .subscribe();
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

  // ───────────────────────── WhatsApp logic ─────────────────────────

  String _waName(WhatsAppInboxMessage m) {
    final name = m.customerName?.trim();
    return name != null && name.isNotEmpty ? name : '+${m.phone}';
  }

  List<_Convo> _waItems() {
    return [
      for (final m in _waConvos)
        _Convo(
          channel: Channel.whatsapp,
          key: m.phone,
          name: _waName(m),
          preview: m.isAudio
              ? '🎤 Voice message'
              : (m.text.isEmpty ? 'No text preview' : m.text),
          time: m.createdAt,
          incoming: !m.isOutgoing,
        ),
    ];
  }

  Future<void> _refreshWa({bool silent = false}) async {
    final version = ++_waVersion;
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _waLoading = true;
        _waError = null;
      });
    }

    try {
      final rows = await _waService.fetchConversations();
      if (!mounted || version != _waVersion) return;

      final oldPhone = _waSelected;
      final phones = rows.map((e) => e.phone).toSet();
      final nextPhone = oldPhone != null && phones.contains(oldPhone)
          ? oldPhone
          : (rows.isEmpty ? null : rows.first.phone);

      setState(() {
        _waConvos = rows;
        _waSelected = nextPhone;
        _waLoading = false;
      });

      if (nextPhone != null) {
        await _loadWaMessages(nextPhone, silent: silent);
      } else if (mounted) {
        setState(() => _waMessages = []);
      }
    } catch (e) {
      if (!mounted || version != _waVersion) return;
      setState(() {
        _waLoading = false;
        _waError = e.toString();
      });
    }
  }

  Future<void> _loadWaMessages(String phone, {bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _waLoadingMessages = true);
    try {
      final rows = await _waService.fetchMessages(phone);
      if (!mounted || _waSelected != phone) return;
      setState(() {
        _waMessages = rows;
        _waLoadingMessages = false;
        _waError = null;
      });
    } catch (e) {
      if (!mounted || _waSelected != phone) return;
      setState(() {
        _waLoadingMessages = false;
        _waError = e.toString();
      });
    }
  }

  Future<void> _sendWa() async {
    final phone = _waSelected;
    final text = _waText.text.trim();
    if (phone == null || text.isEmpty || _waSending) return;

    setState(() => _waSending = true);
    try {
      await _waService.sendMessage(phone: phone, message: text);
      if (!mounted) return;
      _waText.clear();
      _snack('WhatsApp message sent successfully.');
      await _refreshWa();
    } catch (e) {
      _snack('Could not send WhatsApp message: $e', error: true);
    } finally {
      if (mounted) setState(() => _waSending = false);
    }
  }

  // ── voice recording / playback (web)

  void _stopTracks() {
    try {
      _recordingStream?.getTracks().forEach((track) => track.stop());
    } catch (_) {}
    _recordingStream = null;
  }

  String? _supportedRecordingMime() {
    const candidates = [
      'audio/mp4',
      'audio/ogg;codecs=opus',
      'audio/ogg',
      'audio/mpeg',
      'audio/aac',
      'audio/3gpp',
    ];
    for (final type in candidates) {
      try {
        if (html.MediaRecorder.isTypeSupported(type)) return type;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _startRecording() async {
    if (_recording || _sendingAudio || _waSelected == null) return;
    final mimeType = _supportedRecordingMime();
    if (mimeType == null) {
      _snack(
        'This browser cannot record a WhatsApp-compatible audio format. '
        'Try Safari or use an audio file in a supported format.',
      );
      return;
    }
    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'audio': true,
      });
      final recorder = html.MediaRecorder(stream, {'mimeType': mimeType});
      _recordingChunks.clear();
      // DOM listeners: dart:html's MediaRecorder stream accessors are not
      // exposed consistently by the current Dart SDK.
      recorder.addEventListener('dataavailable', (html.Event event) {
        final data = (event as dynamic).data as html.Blob?;
        if (data != null && data.size > 0) {
          _recordingChunks.add(data);
        }
      });
      _recordingStream = stream;
      _mediaRecorder = recorder;
      recorder.start();
      if (!mounted) return;
      setState(() {
        _recording = true;
        _recordingSeconds = 0;
        _recordingStartedAt = DateTime.now();
      });
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _recordingStartedAt != null) {
          setState(
            () => _recordingSeconds = DateTime.now()
                .difference(_recordingStartedAt!)
                .inSeconds,
          );
        }
      });
    } catch (e) {
      _stopTracks();
      _snack('Microphone access failed: $e');
    }
  }

  Future<void> _stopRecordingAndSend() async {
    final recorder = _mediaRecorder;
    final phone = _waSelected;
    if (recorder == null || phone == null || !_recording || _sendingAudio) {
      return;
    }
    final stopped = Completer<void>();
    recorder.addEventListener('stop', (html.Event _) {
      if (!stopped.isCompleted) stopped.complete();
    });
    try {
      recorder.stop();
      await stopped.future.timeout(const Duration(seconds: 5));
      _recordingTimer?.cancel();
      final chunks = List<html.Blob>.from(_recordingChunks);
      final recordedMimeType = recorder.mimeType;
      final mimeType = recordedMimeType != null && recordedMimeType.isNotEmpty
          ? recordedMimeType.split(';').first
          : (_supportedRecordingMime() ?? 'audio/mp4').split(';').first;
      _stopTracks();
      if (chunks.isEmpty) {
        throw Exception('No audio was recorded. Please try again.');
      }
      final blob = html.Blob(chunks, mimeType);
      final reader = html.FileReader();
      reader.readAsArrayBuffer(blob);
      await reader.onLoad.first;
      final result = reader.result;
      if (result is! ByteBuffer) {
        throw Exception('Could not read the recorded audio.');
      }
      final bytes = Uint8List.view(result);
      if (!mounted) return;
      setState(() {
        _recording = false;
        _sendingAudio = true;
      });
      await _waService.sendAudio(
        phone: phone,
        bytes: bytes,
        mimeType: mimeType,
        voice: true,
      );
      _snack('WhatsApp voice message sent.');
      await _refreshWa();
    } catch (e) {
      _snack('Could not send voice message: $e', error: true);
    } finally {
      _recordingTimer?.cancel();
      _stopTracks();
      if (mounted) {
        setState(() {
          _recording = false;
          _sendingAudio = false;
          _recordingStartedAt = null;
          _recordingSeconds = 0;
          _mediaRecorder = null;
          _recordingChunks.clear();
        });
      }
    }
  }

  Future<void> _cancelRecording() async {
    try {
      _mediaRecorder?.stop();
    } catch (_) {}
    _recordingTimer?.cancel();
    _stopTracks();
    if (mounted) {
      setState(() {
        _recording = false;
        _recordingStartedAt = null;
        _recordingSeconds = 0;
        _mediaRecorder = null;
        _recordingChunks.clear();
      });
    }
  }

  String _durationLabel(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _playAudio(WhatsAppInboxMessage message) async {
    final id = message.messageId;
    if (id == null || id.isEmpty) {
      _snack('This audio message has no WhatsApp message ID.');
      return;
    }
    try {
      String? objectUrl = _audioObjectUrls[id];
      if (objectUrl == null) {
        final bytes = await _waService.fetchAudioBytes(id);
        final blob = html.Blob([bytes], message.audioMimeType ?? 'audio/ogg');
        objectUrl = html.Url.createObjectUrlFromBlob(blob);
        _audioObjectUrls[id] = objectUrl;
      }
      final audio = html.AudioElement(objectUrl);
      audio.controls = true;
      audio.autoplay = true;
      await audio.play();
      if (!mounted) return;
      setState(() => _playingAudio.add(id));
      audio.onEnded.first.then((_) {
        if (mounted) setState(() => _playingAudio.remove(id));
      });
      _snack('Playing voice message.');
    } catch (e) {
      _snack('Could not play voice message: $e');
    }
  }

  // ───────────────────────── list state helpers ─────────────────────────

  DateTime? _latestIncomingAt(_Convo c) {
    if (c.channel == Channel.instagram) {
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

    // WhatsApp's full message history is available for the open conversation.
    if (_waSelected == c.key) {
      DateTime? latest;

      for (final message in _waMessages) {
        if (message.isOutgoing) continue;

        if (latest == null || message.createdAt.isAfter(latest)) {
          latest = message.createdAt;
        }
      }

      return latest;
    }

    // For other WhatsApp conversations, the list endpoint only provides
    // the conversation row, so use it when its latest message is incoming.
    return c.incoming ? c.time : null;
  }

  bool _isUnread(_Convo c) => _unreadMessageCount(c) > 0;

  int _unreadCount(List<_Convo> items) => items.where(_isUnread).length;

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

    if (c.channel == Channel.instagram) {
      setState(() {
        _open = Channel.instagram;
        _igSelected = c.key;
        _mobileThread = true;
      });

      // Save the incoming-message timestamp for this conversation.
      _markConversationRead(c);
      return;
    }

    final changed = _waSelected != c.key;

    setState(() {
      _open = Channel.whatsapp;
      _waSelected = c.key;
      _mobileThread = true;

      if (changed) {
        _waMessages = [];
        _waError = null;
      }
    });

    // Load the actual WhatsApp history before marking messages as read.
    _loadWaMessages(c.key).then((_) {
      if (!mounted || _waSelected != c.key || _open != Channel.whatsapp) {
        return;
      }

      for (final conversation in _waItems()) {
        if (conversation.key == c.key) {
          _markConversationRead(conversation);
          break;
        }
      }
    });
  }

  void _setTab(Channel channel) {
    setState(() {
      _tab = channel;
      _open = channel;
    });
  }

  // ───────────────────────── left panel ─────────────────────────

  Widget _tile(_Convo c) {
    final selectedKey = c.channel == Channel.instagram
        ? _igSelected
        : _waSelected;
    final selected = c.channel == _open && c.key == selectedKey;
    final unreadCount = _unreadMessageCount(c);

    return ConversationTile(
      selected: selected,
      unread: unreadCount > 0,
      unreadCount: unreadCount,
      isInstagram: c.channel == Channel.instagram,
      name: c.name,
      time: formatInboxListTime(c.time),
      preview: c.preview,
      indicatorColor: c.channel.isIg ? p.accent : ChannelColors.wa,
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

    // Instagram: show an unread dot if any incoming message
    // arrived after the conversation was last read.
    if (c.channel == Channel.instagram) {
      return _igMessages.where((message) {
        if (message.senderId != c.key || message.fromBot) {
          return false;
        }

        return lastRead == null || message.createdAt.isAfter(lastRead);
      }).length;
    }

    // WhatsApp: count incoming messages only.
    // Automatic replies and other outgoing messages must not
    // clear or increase the unread count.

    if (c.channel == Channel.whatsapp) {
      final lastRead = _readAt[c.id];

      // Use loaded history for the selected conversation so the
      // badge clears immediately when its read state is saved.
      if (_waSelected == c.key && _waMessages.isNotEmpty) {
        return _waMessages.where((message) {
          if (message.isOutgoing) return false;

          return lastRead == null || message.createdAt.isAfter(lastRead);
        }).length;
      }

      // Other conversations use the accurate backend count.
      final conversation = _waConvos.where((message) => message.phone == c.key);

      if (conversation.isNotEmpty) {
        return conversation.first.unreadCount;
      }

      return 0;
    }

    return 0;
  }

  Widget _channelHint(Channel channel, List<_Convo> all) {
    final isIg = channel == Channel.instagram;
    final loading = isIg ? _igLoading : _waLoading;
    final error = isIg ? _igError : _waError;

    if (all.isEmpty && loading) {
      return const InboxListHint(message: '', loading: true);
    }
    if (all.isEmpty && error != null) {
      return InboxListHint(
        message: error,
        onRetry: isIg ? _refreshIg : _refreshWa,
      );
    }
    if (all.isEmpty) {
      return InboxListHint(
        message: isIg
            ? 'No Instagram messages yet.'
            : 'No WhatsApp conversations yet.',
      );
    }
    return const InboxListHint(message: 'No unread conversations.');
  }

  Widget _listPanel() {
    final activeAll = _tab == Channel.instagram ? _igItems() : _waItems();
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ChannelTabs(
              active: _tab,
              onChanged: _setTab,
              badge: _unreadCount(activeAll),
            ),
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
                  _channelHint(_tab, activeAll)
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

  // WhatsApp-style outgoing bubble: soft green (deep green in dark mode).
  Color get _outBubble =>
      p.isDark ? const Color(0xFF005C4B) : const Color(0xFFDCF8C6);
  Color get _outText => p.isDark ? Colors.white : const Color(0xFF17212B);
  Color get _outMeta => p.isDark ? Colors.white70 : const Color(0xFF607078);

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

  Widget _audioBody(WhatsAppInboxMessage m) {
    final out = m.isOutgoing;
    final playing = m.messageId != null && _playingAudio.contains(m.messageId);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Play voice message',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          onPressed: m.messageId == null ? null : () => _playAudio(m),
          icon: Icon(
            playing ? Icons.graphic_eq_rounded : Icons.play_circle_fill_rounded,
            size: 34,
            color: ChannelColors.waDeep,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Voice message',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: out ? _outText : p.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _waBubble(WhatsAppInboxMessage m, String display) {
    final out = m.isOutgoing;
    return InboxBubble(
      outgoing: out,
      sender: out ? null : display,
      text: m.isAudio ? '' : m.text,
      body: m.isAudio ? _audioBody(m) : null,
      time: formatInboxTime(m.createdAt),
      status: m.status,
      outgoingColor: _outBubble,
      outgoingText: _outText,
      outgoingMeta: _outMeta,
      avatar: out
          ? null
          : AvatarWithBadge(
              label: display,
              channel: Channel.whatsapp,
              size: 38,
            ),
    );
  }

  Widget _backButton() => IconButton(
    tooltip: 'Back to messages',
    onPressed: () => setState(() => _mobileThread = false),
    icon: Icon(Icons.arrow_back_rounded, color: p.textPrimary),
  );

  Widget _thread(bool narrow) {
    final isIg = _open == Channel.instagram;
    final key = isIg ? _igSelected : _waSelected;
    final accent = isIg ? ChannelColors.ig : ChannelColors.waDeep;

    if (key == null) {
      final loading = isIg ? _igLoading : _waLoading;
      return ColoredBox(
        color: p.pageBg,
        child: Column(
          children: [
            if (narrow)
              Align(alignment: Alignment.centerLeft, child: _backButton()),
            Expanded(
              child: loading
                  ? Center(child: CircularProgressIndicator(color: p.accent))
                  : InboxEmptyState(
                      icon: isIg
                          ? Icons.forum_outlined
                          : Icons.chat_bubble_outline,
                      title: 'No conversation selected',
                      message: isIg
                          ? 'New messages received by your connected Instagram '
                                'account will appear here.'
                          : 'When your WhatsApp webhook saves incoming messages '
                                'to Supabase, customers will appear here.',
                      color: accent,
                      action: TintedButton(
                        onPressed: isIg ? _refreshIg : _refreshWa,
                        icon: Icons.refresh,
                        label: 'Refresh',
                        gradient: isIg
                            ? ChannelColors.igBubble
                            : ChannelColors.waGradient,
                        color: accent,
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    late final String display;
    late final String? avatarUrl;
    late final List<Widget> items;
    late final String subtitle;
    late final String? error;
    var loadingMessages = false;

    if (isIg) {
      final messages =
          _igGroups(_igMessages)[key] ?? const <InstagramInboxMessage>[];
      display = _igName(key, messages);
      avatarUrl = _igAvatar(messages);
      subtitle = 'Instagram DM';
      error = _igError == null ? null : 'Refresh failed: $_igError';
      items = _dayList<InstagramInboxMessage>(
        messages,
        (m) => m.createdAt,
        (m) => _igBubble(m, display, avatarUrl),
      );
    } else {
      final match = _waConvos.where((e) => e.phone == key);
      display = match.isEmpty ? '+$key' : _waName(match.first);
      avatarUrl = null;
      subtitle = 'WhatsApp · +$key';
      error = _waError;
      loadingMessages = _waLoadingMessages;
      items = _dayList<WhatsAppInboxMessage>(
        _waMessages,
        (m) => m.createdAt,
        (m) => _waBubble(m, display),
      );
    }

    Widget body;
    if (loadingMessages && items.isEmpty) {
      body = Center(child: CircularProgressIndicator(color: p.accent));
    } else if (items.isEmpty) {
      body = InboxEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No messages yet',
        message: isIg
            ? 'Messages from this Instagram user will appear here.'
            : 'Messages saved by your WhatsApp webhook will appear here.',
        color: accent,
      );
    } else {
      body = ListView(
        key: ValueKey('${_open.name}:$key'),
        reverse: true,
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 12),
        children: items,
      );
    }

    return Column(
      children: [
        ThreadHeader(
          leading: narrow ? _backButton() : null,
          avatar: AvatarWithBadge(
            label: display,
            channel: _open,
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
              TextButton(
                onPressed: isIg ? _refreshIg : _refreshWa,
                child: const Text('Retry'),
              ),
            ],
          ),

        Expanded(
          child: isIg
              ? ColoredBox(color: p.pageBg, child: body)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: p.pageBg),
                    Opacity(
                      opacity: 0.50,
                      child: Image.asset(
                        Theme.of(context).brightness == Brightness.dark
                            ? AssetConstants.whatsappChatbgDark
                            : AssetConstants.whatsappChatbgLight,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    body,
                  ],
                ),
        ),

        _composer(),
      ],
    );
  }

  Widget _composer() {
    if (_open == Channel.instagram) {
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
                enabled: _igSelected != null && !_igSending,
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

    final phone = _waSelected;
    return ComposerBar(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_recording)
            IconButton(
              tooltip: 'Cancel recording',
              onPressed: _cancelRecording,
              icon: const Icon(Icons.close_rounded, color: Colors.red),
            )
          else
            IconButton(
              tooltip: 'Record voice message',
              onPressed: phone == null || _waSending || _sendingAudio
                  ? null
                  : _startRecording,
              icon: Icon(Icons.mic_none_rounded, color: p.accent),
            ),
          if (_recording)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fiber_manual_record,
                      size: 12,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recording ${_durationLabel(_recordingSeconds)}',
                        style: TextStyle(color: p.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: TextField(
                controller: _waText,
                minLines: 1,
                maxLines: 4,
                maxLength: 4096,
                enabled: phone != null && !_waSending && !_sendingAudio,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                keyboardType: TextInputType.text,
                onSubmitted: (_) => _sendWa(),
                decoration: inboxPillField(
                  p,
                  phone == null
                      ? 'Select a conversation'
                      : 'Message on WhatsApp…',
                ),
              ),
            ),
          const SizedBox(width: 10),
          SendButton(
            tooltip: _recording
                ? 'Send voice message'
                : 'Send WhatsApp message',
            busy: _waSending || _sendingAudio,
            onPressed: phone == null || _waSending || _sendingAudio
                ? null
                : (_recording ? _stopRecordingAndSend : _sendWa),
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
