// import 'dart:async';
// import 'dart:convert';
// // ignore: avoid_web_libraries_in_flutter, deprecated_member_use
// import 'dart:html' as html;
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:raigon_art/core/theme/app_palette.dart';
// import 'package:raigon_art/core/theme/mx_theme.dart';
// import 'package:raigon_art/features/messaging/models/channel.dart';
// import 'package:raigon_art/features/messaging/provider/messaging_provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../widgets/channel_badge.dart';
// import '../widgets/channel_style.dart';

// // ─────────────────────────────────────────────────────────────
// // Shared UI pieces (private to the inbox)
// // ─────────────────────────────────────────────────────────────

// class _Avatar extends StatelessWidget {
//   const _Avatar(
//     this.label, {
//     required this.size,
//     required this.gradient,
//     this.imageUrl,
//   });

//   final String label;
//   final double size;
//   final Gradient gradient;
//   final String? imageUrl;

//   @override
//   Widget build(BuildContext context) {
//     final t = label.replaceFirst('@', '').replaceFirst('+', '').trim();
//     final url = imageUrl?.trim();

//     return Container(
//       width: size,
//       height: size,
//       alignment: Alignment.center,
//       clipBehavior: Clip.antiAlias,
//       decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
//       child: url != null && url.isNotEmpty
//           ? Image.network(
//               url,
//               width: size,
//               height: size,
//               fit: BoxFit.cover,
//               loadingBuilder: (context, child, loadingProgress) {
//                 if (loadingProgress == null) {
//                   debugPrint('Instagram avatar loaded successfully');
//                   return child;
//                 }

//                 return Center(
//                   child: SizedBox(
//                     width: size * 0.3,
//                     height: size * 0.3,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       value: loadingProgress.expectedTotalBytes != null
//                           ? loadingProgress.cumulativeBytesLoaded /
//                                 loadingProgress.expectedTotalBytes!
//                           : null,
//                     ),
//                   ),
//                 );
//               },
//               errorBuilder: (context, error, stackTrace) {
//                 debugPrint('Instagram avatar failed to load: $error');
//                 return _fallbackAvatar(t);
//               },
//             )
//           : _fallbackAvatar(t),
//     );
//   }

//   Widget _fallbackAvatar(String text) {
//     return Container(
//       width: size,
//       height: size,
//       alignment: Alignment.center,
//       decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
//       child: Text(
//         text.isEmpty ? '?' : text[0].toUpperCase(),
//         style: TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.w800,
//           fontSize: size * 0.42,
//         ),
//       ),
//     );
//   }
// }

// class _ConvTile extends StatelessWidget {
//   const _ConvTile({
//     required this.avatar,
//     required this.name,
//     required this.time,
//     required this.preview,
//     required this.selected,
//     required this.accent,
//     required this.wide,
//     required this.onTap,
//     this.previewLines = 1,
//   });

//   final Widget avatar;
//   final String name, time, preview;
//   final bool selected, wide;
//   final Color accent;
//   final VoidCallback onTap;
//   final int previewLines;

//   @override
//   Widget build(BuildContext context) {
//     final p = AppPalette.of(context);
//     return Container(
//       width: wide ? null : 240,
//       margin: EdgeInsets.only(bottom: wide ? 6 : 0, right: wide ? 0 : 8),
//       child: Material(
//         color: selected ? accent.withValues(alpha: .09) : Colors.transparent,
//         borderRadius: BorderRadius.circular(16),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(16),
//           onTap: onTap,
//           child: Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: selected
//                     ? accent.withValues(alpha: .55)
//                     : Colors.transparent,
//                 width: 1.3,
//               ),
//             ),
//             child: Row(
//               children: [
//                 avatar,
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,

//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               name,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 13.5,
//                                 color: p.textPrimary,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 6),
//                           Text(
//                             time,
//                             style: TextStyle(
//                               color: p.textMuted,
//                               fontSize: 10.5,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 3),
//                       Text(
//                         preview,
//                         maxLines: previewLines,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(color: p.textMuted, fontSize: 12.5),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _Toolbar extends StatelessWidget {
//   const _Toolbar({
//     required this.title,
//     required this.loading,
//     required this.onRefresh,
//     required this.color,
//     required this.tooltip,
//   });
//   final String title, tooltip;
//   final bool loading;
//   final VoidCallback onRefresh;
//   final Color color;

//   @override
//   Widget build(BuildContext context) {
//     final p = AppPalette.of(context);
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(24, 4, 14, 6),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               title,
//               style: TextStyle(
//                 color: p.textMuted,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           if (loading)
//             SizedBox(
//               width: 16,
//               height: 16,
//               child: CircularProgressIndicator(strokeWidth: 2, color: color),
//             ),
//           IconButton(
//             tooltip: tooltip,
//             onPressed: loading ? null : onRefresh,
//             icon: Icon(Icons.refresh_rounded, color: p.textMuted),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _InboxFrame extends StatelessWidget {
//   const _InboxFrame({required this.child});
//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     final p = AppPalette.of(context);
//     final narrow = MediaQuery.sizeOf(context).width < 860;
//     return Container(
//       margin: EdgeInsets.fromLTRB(narrow ? 12 : 20, 4, narrow ? 12 : 20, 20),
//       clipBehavior: Clip.antiAlias,
//       decoration: BoxDecoration(
//         color: p.surface,
//         borderRadius: BorderRadius.circular(22),
//         border: Border.all(color: p.border),
//         boxShadow: p.softShadow,
//       ),
//       child: child,
//     );
//   }
// }

// InputDecoration _pillField(AppPalette p, String hint, Color focus) {
//   OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
//     borderRadius: BorderRadius.circular(24),
//     borderSide: BorderSide(color: c, width: w),
//   );
//   return InputDecoration(
//     hintText: hint,
//     counterText: '',
//     filled: true,
//     fillColor: p.chipFill,
//     contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
//     border: b(Colors.transparent),
//     enabledBorder: b(Colors.transparent),
//     disabledBorder: b(Colors.transparent),
//     focusedBorder: b(focus, 1.4),
//   );
// }

// // ─────────────────────────────────────────────────────────────
// // Instagram
// // ─────────────────────────────────────────────────────────────

// class InstagramInboxMessage {
//   const InstagramInboxMessage({
//     required this.id,
//     required this.senderId,
//     this.senderUsername,
//     this.senderProfilePicture,
//     required this.messageId,
//     required this.text,
//     required this.direction,
//     required this.createdAt,
//   });

//   final int id;
//   final String senderId;
//   final String? senderUsername;
//   final String? senderProfilePicture;
//   final String messageId;
//   final String text;
//   final String direction;
//   final DateTime createdAt;

//   bool get fromBot => direction == 'outgoing';

//   factory InstagramInboxMessage.fromJson(Map<String, dynamic> json) {
//     debugPrint(
//       'Instagram inbox response: '
//       '${json['sender_username']} -> '
//       '${json['sender_profile_picture']}',
//     );
//     return InstagramInboxMessage(
//       id: int.tryParse('${json['id']}') ?? 0,
//       senderId: '${json['sender_id'] ?? ''}',
//       senderUsername: (json['sender_username'] as String?)?.trim(),
//       senderProfilePicture: json['sender_profile_picture']?.toString(),
//       messageId: '${json['message_id'] ?? ''}',
//       text: '${json['message_text'] ?? ''}',
//       direction: '${json['direction'] ?? 'incoming'}',
//       createdAt:
//           DateTime.tryParse('${json['created_at'] ?? ''}')?.toLocal() ??
//           DateTime.now(),
//     );
//   }
// }

// class InstagramInboxService {
//   static const String endpoint =
//       'https://nhqewkbztfmlophtzqmk.supabase.co'
//       '/functions/v1/instagram-inbox';

//   Future<List<InstagramInboxMessage>> fetchMessages() async {
//     final session = Supabase.instance.client.auth.currentSession;

//     if (session == null) {
//       throw Exception('Please sign in to access the Instagram Inbox.');
//     }

//     final uri = Uri.parse(endpoint).replace(
//       queryParameters: const {
//         'instagram_user_id': '17841415634351143',
//         'limit': '200',
//       },
//     );

//     final response = await http
//         .get(
//           uri,
//           headers: {
//             'Accept': 'application/json',
//             'Authorization': 'Bearer ${session.accessToken}',
//           },
//         )
//         .timeout(const Duration(seconds: 20));

//     if (response.statusCode != 200) {
//       throw Exception('Inbox API returned HTTP ${response.statusCode}.');
//     }

//     final decoded = jsonDecode(response.body);

//     if (decoded is! Map<String, dynamic> ||
//         decoded['success'] != true ||
//         decoded['messages'] is! List) {
//       throw Exception('Unexpected Inbox API response.');
//     }

//     return (decoded['messages'] as List)
//         .whereType<Map<String, dynamic>>()
//         .map(InstagramInboxMessage.fromJson)
//         .toList()
//       ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
//   }

//   Future<void> sendMessage({
//     required String recipientId,
//     required String message,
//   }) async {
//     final session = Supabase.instance.client.auth.currentSession;

//     if (session == null) {
//       throw Exception('Please sign in to send messages.');
//     }

//     final response = await http
//         .post(
//           Uri.parse(endpoint),
//           headers: {
//             'Accept': 'application/json',
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer ${session.accessToken}',
//           },
//           body: jsonEncode({'recipient_id': recipientId, 'message': message}),
//         )
//         .timeout(const Duration(seconds: 30));

//     final decoded = jsonDecode(response.body);

//     if (response.statusCode != 200 ||
//         decoded is! Map<String, dynamic> ||
//         decoded['success'] != true) {
//       final error = decoded is Map<String, dynamic>
//           ? decoded['error']?.toString()
//           : null;

//       throw Exception(error ?? 'Failed to send Instagram message.');
//     }

//     if (decoded['saved'] == false) {
//       throw Exception(
//         'Instagram accepted the message, but saving it to the inbox failed. '
//         'Refresh the inbox before trying again.',
//       );
//     }
//   }
// }

// class InstagramInboxContent extends StatefulWidget {
//   const InstagramInboxContent({super.key, required this.s});

//   final MessagingAutomationProvider s;

//   @override
//   State<InstagramInboxContent> createState() => _InstagramInboxContentState();
// }

// class _InstagramInboxContentState extends State<InstagramInboxContent> {
//   final InstagramInboxService _service = InstagramInboxService();

//   List<InstagramInboxMessage> _messages = [];
//   String? _error;
//   bool _loading = false;
//   String? _selectedSender;
//   int _requestVersion = 0;

//   final TextEditingController _messageController = TextEditingController();

//   bool _sendingMessage = false;
//   Timer? _instagramPollTimer;
//   bool _instagramPollRunning = false;

//   AppPalette get p => AppPalette.of(context);

//   @override
//   void initState() {
//     super.initState();
//     refreshMessages();

//     // Automatically check for new Instagram messages every 2 seconds.
//     _instagramPollTimer = Timer.periodic(const Duration(seconds: 0), (_) async {
//       if (!mounted || _instagramPollRunning || _loading || _sendingMessage) {
//         return;
//       }

//       _instagramPollRunning = true;
//       try {
//         await refreshMessages(silent: true);
//       } finally {
//         _instagramPollRunning = false;
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _instagramPollTimer?.cancel();
//     _messageController.dispose();
//     super.dispose();
//   }

//   Future<void> refreshMessages({bool silent = false}) async {
//     final requestVersion = ++_requestVersion;

//     if (mounted && !silent) {
//       setState(() {
//         _loading = true;
//         _error = null;
//       });
//     }

//     try {
//       final messages = await _service.fetchMessages();

//       if (!mounted || requestVersion != _requestVersion) return;

//       setState(() {
//         _messages = messages;
//         if (!silent) _loading = false;
//         _error = null;
//         final senders = _groupMessages(messages).keys.toList();

//         if (_selectedSender == null || !senders.contains(_selectedSender)) {
//           _selectedSender = senders.isEmpty ? null : senders.first;
//         }
//       });
//     } catch (e) {
//       if (!mounted || requestVersion != _requestVersion) return;

//       if (silent) {
//         debugPrint('Instagram auto-refresh failed: $e');
//         return;
//       }

//       setState(() {
//         _loading = false;
//         _error = e.toString();
//       });
//     }
//   }

//   Future<void> _sendMessage() async {
//     final recipientId = _selectedSender;
//     final message = _messageController.text.trim();

//     if (recipientId == null || recipientId.isEmpty) return;
//     if (message.isEmpty || _sendingMessage) return;

//     setState(() => _sendingMessage = true);

//     try {
//       await _service.sendMessage(recipientId: recipientId, message: message);

//       if (!mounted) return;

//       _messageController.clear();

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Instagram message sent successfully.')),
//       );

//       await refreshMessages();
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Could not send message: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() => _sendingMessage = false);
//       }
//     }
//   }

//   Map<String, List<InstagramInboxMessage>> _groupMessages(
//     List<InstagramInboxMessage> messages,
//   ) {
//     final groups = <String, List<InstagramInboxMessage>>{};

//     for (final message in messages) {
//       if (message.senderId.isEmpty) continue;

//       groups.putIfAbsent(message.senderId, () => []);
//       groups[message.senderId]!.add(message);
//     }

//     for (final group in groups.values) {
//       group.sort((a, b) => a.createdAt.compareTo(b.createdAt));
//     }

//     return groups;
//   }

//   String _senderDisplayName(
//     String senderId,
//     List<InstagramInboxMessage> messages,
//   ) {
//     for (final message in messages) {
//       final username = message.senderUsername?.trim();
//       if (username != null && username.isNotEmpty) {
//         return username.startsWith('@') ? username : '@$username';
//       }
//     }
//     return senderId;
//   }

//   String _time(DateTime date) {
//     final local = date.toLocal();
//     final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
//     final minute = local.minute.toString().padLeft(2, '0');
//     final period = local.hour >= 12 ? 'PM' : 'AM';
//     return '$hour:$minute $period';
//   }

//   Widget _statusView({
//     required IconData icon,
//     required String title,
//     required String message,
//     Widget? action,
//   }) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(28),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 84,
//               height: 84,
//               decoration: BoxDecoration(
//                 color: ChannelColors.ig.withValues(alpha: .10),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, size: 38, color: ChannelColors.ig),
//             ),
//             const SizedBox(height: 18),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w800,
//                 color: p.textPrimary,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: TextStyle(color: p.textMuted, height: 1.4),
//             ),
//             if (action != null) ...[const SizedBox(height: 18), action],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _tile(
//     String sender,
//     Map<String, List<InstagramInboxMessage>> groups,
//     String? selected,
//     bool wide,
//   ) {
//     final messages = groups[sender]!;
//     final latest = messages.last;
//     final display = _senderDisplayName(sender, messages);
//     return _ConvTile(
//       wide: wide,
//       selected: sender == selected,
//       accent: ChannelColors.ig,
//       name: display,
//       time: _time(latest.createdAt),
//       preview: latest.text,
//       onTap: () => setState(() => _selectedSender = sender),
//       avatar: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           _Avatar(
//             display,
//             size: 42,
//             gradient: ChannelColors.igGradient,
//             imageUrl: latest.senderProfilePicture,
//           ),
//           const Positioned(
//             right: -3,
//             bottom: -3,
//             child: ChannelBadge(Channel.instagram, size: 18),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _bubble(InstagramInboxMessage message) {
//     final bot = message.fromBot;
//     final who = message.senderUsername?.trim().isNotEmpty == true
//         ? (message.senderUsername!.startsWith('@')
//               ? message.senderUsername!
//               : '@${message.senderUsername}')
//         : '@${message.senderId}';
//     return Align(
//       alignment: bot ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 10),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//         constraints: const BoxConstraints(maxWidth: 420),
//         decoration: BoxDecoration(
//           gradient: bot ? ChannelColors.igBubble : null,
//           color: bot ? null : p.surface,
//           borderRadius: BorderRadius.only(
//             topLeft: const Radius.circular(18),
//             topRight: const Radius.circular(18),
//             bottomLeft: Radius.circular(bot ? 18 : 4),
//             bottomRight: Radius.circular(bot ? 4 : 18),
//           ),
//           border: bot ? null : Border.all(color: p.border),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               who,
//               style: TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w600,
//                 color: bot ? Colors.white70 : p.textMuted,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               message.text,
//               style: TextStyle(
//                 height: 1.35,
//                 color: bot ? Colors.white : p.textPrimary,
//               ),
//             ),
//             const SizedBox(height: 5),
//             Text(
//               _time(message.createdAt),
//               style: TextStyle(
//                 fontSize: 10,
//                 color: bot ? Colors.white70 : p.textMuted,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final groups = _groupMessages(_messages);
//     final senders = groups.keys.toList();
//     final selected = _selectedSender;
//     final conversation = selected == null
//         ? <InstagramInboxMessage>[]
//         : groups[selected] ?? [];

//     final wide = MediaQuery.sizeOf(context).width >= 860;

//     if (_loading && _messages.isEmpty) {
//       return const Center(
//         child: CircularProgressIndicator(color: ChannelColors.ig),
//       );
//     }

//     if (_error != null && _messages.isEmpty) {
//       return _statusView(
//         icon: Icons.cloud_off_outlined,
//         title: 'Could not load Inbox',
//         message: _error!,
//         action: TintedButton(
//           onPressed: refreshMessages,
//           icon: Icons.refresh,
//           label: 'Try again',
//           gradient: ChannelColors.igBubble,
//           color: ChannelColors.ig,
//         ),
//       );
//     }

//     if (_messages.isEmpty) {
//       return _statusView(
//         icon: Icons.forum_outlined,
//         title: 'No Instagram messages yet',
//         message:
//             _error ??
//             'New messages received by your connected Instagram account '
//                 'will appear here.',
//         action: TintedButton(
//           onPressed: refreshMessages,
//           icon: Icons.refresh,
//           label: 'Refresh Inbox',
//           gradient: ChannelColors.igBubble,
//           color: ChannelColors.ig,
//         ),
//       );
//     }

//     final conversationList = ListView(
//       padding: wide
//           ? const EdgeInsets.all(10)
//           : const EdgeInsets.fromLTRB(10, 10, 4, 10),
//       scrollDirection: wide ? Axis.vertical : Axis.horizontal,
//       children: [
//         for (final sender in senders) _tile(sender, groups, selected, wide),
//       ],
//     );

//     final selectedName = selected == null
//         ? 'Instagram conversation'
//         : _senderDisplayName(selected, groups[selected] ?? const []);

//     final thread = Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
//           decoration: BoxDecoration(
//             color: p.surface,
//             border: Border(bottom: BorderSide(color: p.border)),
//           ),
//           child: Row(
//             children: [
//               _Avatar(
//                 selectedName,
//                 size: 38,
//                 gradient: ChannelColors.igGradient,
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       selectedName,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontWeight: FontWeight.w800,
//                         fontSize: 15,
//                         color: p.textPrimary,
//                       ),
//                     ),
//                     Text(
//                       'Instagram DM',
//                       style: TextStyle(color: p.textMuted, fontSize: 12),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         if (_error != null)
//           MaterialBanner(
//             backgroundColor: p.amberSoft,
//             content: Text('Refresh failed: $_error'),
//             actions: [
//               TextButton(
//                 onPressed: refreshMessages,
//                 child: const Text('Retry'),
//               ),
//             ],
//           ),
//         Expanded(
//           child: ColoredBox(
//             color: p.pageBg,
//             child: ListView(
//               key: ValueKey(selected),
//               reverse: true,
//               padding: const EdgeInsets.all(20),
//               children: [
//                 for (final message in conversation.reversed) _bubble(message),
//               ],
//             ),
//           ),
//         ),
//         Container(
//           padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
//           decoration: BoxDecoration(
//             color: p.surface,
//             border: Border(top: BorderSide(color: p.border)),
//           ),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Expanded(
//                 child: TextField(
//                   controller: _messageController,
//                   minLines: 1,
//                   maxLines: 4,
//                   maxLength: 1000,
//                   textCapitalization: TextCapitalization.sentences,
//                   onSubmitted: (_) => _sendMessage(),
//                   decoration: _pillField(
//                     p,
//                     'Message on Instagram…',
//                     ChannelColors.ig,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               IconButton.filled(
//                 tooltip: 'Send Instagram message',
//                 onPressed: _sendingMessage ? null : _sendMessage,
//                 style: IconButton.styleFrom(
//                   backgroundColor: ChannelColors.ig,
//                   foregroundColor: Colors.white,
//                   disabledBackgroundColor: ChannelColors.ig.withValues(
//                     alpha: .3,
//                   ),
//                   padding: const EdgeInsets.all(14),
//                 ),
//                 icon: _sendingMessage
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.white,
//                         ),
//                       )
//                     : const Icon(Icons.send_rounded),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );

//     return Column(
//       children: [
//         _Toolbar(
//           title:
//               '${senders.length} conversation${senders.length == 1 ? '' : 's'}',
//           loading: _loading,
//           onRefresh: refreshMessages,
//           color: ChannelColors.ig,
//           tooltip: 'Refresh Inbox',
//         ),
//         Expanded(
//           child: _InboxFrame(
//             child: wide
//                 ? Row(
//                     children: [
//                       SizedBox(width: 320, child: conversationList),
//                       VerticalDivider(width: 1, color: p.border),
//                       Expanded(child: thread),
//                     ],
//                   )
//                 : Column(
//                     children: [
//                       SizedBox(height: 86, child: conversationList),
//                       Divider(height: 1, color: p.border),
//                       Expanded(child: thread),
//                     ],
//                   ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// // Inbox page (tabs)
// // ─────────────────────────────────────────────────────────────

// /// Shared Inbox page with independent Instagram and WhatsApp tabs.
// /// Instagram uses the existing InstagramInboxService and implementation below.
// /// WhatsApp uses the separate whatsapp_inbox Edge Function.
// class InboxPage extends StatelessWidget {
//   const InboxPage({super.key, required this.s});

//   final MessagingAutomationProvider s;

//   @override
//   Widget build(BuildContext context) {
//     final p = AppPalette.of(context);

//     Widget tab(IconData icon, String text, Color c) => Tab(
//       height: 40,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, size: 17, color: c),
//           const SizedBox(width: 8),
//           Text(text),
//         ],
//       ),
//     );

//     return DefaultTabController(
//       length: 2,
//       child: SizedBox(
//         width: double.infinity,
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Inbox',
//                           style: TextStyle(
//                             fontSize: 26,
//                             fontWeight: FontWeight.w800,
//                             letterSpacing: -0.8,
//                             color: p.textPrimary,
//                           ),
//                         ),
//                         const SizedBox(height: 3),
//                         Text(
//                           'Manage Instagram DMs and WhatsApp conversations',
//                           style: TextStyle(color: p.textMuted, fontSize: 13),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: ConstrainedBox(
//                   constraints: const BoxConstraints(maxWidth: 380),
//                   child: Container(
//                     padding: const EdgeInsets.all(4),
//                     decoration: BoxDecoration(
//                       color: p.chipFill,
//                       border: Border.all(color: p.border),
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     child: TabBar(
//                       dividerColor: Colors.transparent,
//                       indicatorSize: TabBarIndicatorSize.tab,
//                       overlayColor: const WidgetStatePropertyAll(
//                         Colors.transparent,
//                       ),
//                       indicator: BoxDecoration(
//                         color: p.surface,
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: p.border),
//                         boxShadow: p.softShadow,
//                       ),
//                       labelColor: p.textPrimary,
//                       unselectedLabelColor: p.textMuted,
//                       labelStyle: const TextStyle(
//                         fontWeight: FontWeight.w800,
//                         fontSize: 13,
//                       ),
//                       unselectedLabelStyle: const TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 13,
//                       ),
//                       tabs: [
//                         tab(
//                           Icons.camera_alt_outlined,
//                           'Instagram',
//                           ChannelColors.ig,
//                         ),
//                         tab(
//                           Icons.chat_bubble_outline_rounded,
//                           'WhatsApp',
//                           ChannelColors.waDeep,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 10),
//             Expanded(
//               child: TabBarView(
//                 // Swiping would fight with the horizontal conversation list.
//                 physics: const NeverScrollableScrollPhysics(),
//                 children: [
//                   InstagramInboxContent(s: s),
//                   const WhatsAppInboxContent(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// // WhatsApp
// // ─────────────────────────────────────────────────────────────

// class WhatsAppInboxMessage {
//   const WhatsAppInboxMessage({
//     required this.id,
//     required this.phone,
//     required this.direction,
//     required this.text,
//     required this.createdAt,
//     this.messageId,
//     this.customerName,
//     this.status,
//     this.messageType = 'text',
//     this.audioMediaId,
//     this.audioMimeType,
//     this.audioVoice = false,
//   });

//   final int id;
//   final String phone;
//   final String direction;
//   final String text;
//   final DateTime createdAt;
//   final String? messageId;
//   final String? customerName;
//   final String? status;
//   final String messageType;
//   final String? audioMediaId;
//   final String? audioMimeType;
//   final bool audioVoice;

//   bool get isOutgoing => direction == 'outgoing';
//   bool get isAudio =>
//       messageType == 'audio' || (audioMediaId?.isNotEmpty ?? false);

//   factory WhatsAppInboxMessage.fromJson(Map<String, dynamic> json) {
//     return WhatsAppInboxMessage(
//       id: int.tryParse('${json['id']}') ?? 0,
//       phone: '${json['customer_phone'] ?? ''}',
//       direction: '${json['direction'] ?? 'incoming'}',
//       text: '${json['message_text'] ?? ''}',
//       messageId: json['wa_message_id']?.toString(),
//       customerName: json['customer_name']?.toString(),
//       status: json['message_status']?.toString(),
//       messageType: '${json['message_type'] ?? 'text'}',
//       audioMediaId: json['audio_media_id']?.toString(),
//       audioMimeType: json['audio_mime_type']?.toString(),
//       audioVoice: json['audio_voice'] == true,
//       createdAt:
//           DateTime.tryParse('${json['created_at'] ?? ''}')?.toLocal() ??
//           DateTime.now(),
//     );
//   }
// }

// class WhatsAppInboxService {
//   static const String endpoint =
//       'https://nhqewkbztfmlophtzqmk.supabase.co/functions/v1/whatsapp_inbox';

//   Future<Map<String, dynamic>> _request({
//     required String method,
//     Map<String, String>? queryParameters,
//     Map<String, dynamic>? body,
//   }) async {
//     final session = Supabase.instance.client.auth.currentSession;
//     if (session == null) {
//       throw Exception('Please sign in to access WhatsApp Inbox.');
//     }

//     final uri = Uri.parse(endpoint).replace(queryParameters: queryParameters);
//     final headers = <String, String>{
//       'Accept': 'application/json',
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer ${session.accessToken}',
//     };

//     late http.Response response;
//     if (method == 'POST') {
//       response = await http
//           .post(uri, headers: headers, body: jsonEncode(body ?? {}))
//           .timeout(const Duration(seconds: 30));
//     } else {
//       response = await http
//           .get(uri, headers: headers)
//           .timeout(const Duration(seconds: 20));
//     }

//     dynamic decoded;
//     try {
//       decoded = jsonDecode(response.body);
//     } catch (_) {
//       throw Exception(
//         'Invalid WhatsApp server response (${response.statusCode}).',
//       );
//     }

//     if (decoded is! Map) {
//       throw Exception('Unexpected WhatsApp server response.');
//     }
//     final data = Map<String, dynamic>.from(decoded);

//     if (response.statusCode < 200 || response.statusCode >= 300) {
//       throw Exception(
//         data['error']?.toString() ??
//             'WhatsApp request failed (${response.statusCode}).',
//       );
//     }
//     return data;
//   }

//   Future<List<WhatsAppInboxMessage>> fetchConversations() async {
//     final data = await _request(
//       method: 'GET',
//       queryParameters: const {'limit': '500'},
//     );
//     if (data['success'] != true || data['conversations'] is! List) {
//       throw Exception('Unexpected WhatsApp conversations response.');
//     }

//     final items = (data['conversations'] as List)
//         .whereType<Map>()
//         .map((e) => WhatsAppInboxMessage.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//     items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
//     return items;
//   }

//   Future<List<WhatsAppInboxMessage>> fetchMessages(String phone) async {
//     final data = await _request(
//       method: 'GET',
//       queryParameters: {'phone': phone, 'limit': '500'},
//     );
//     if (data['success'] != true || data['messages'] is! List) {
//       throw Exception('Unexpected WhatsApp message history response.');
//     }

//     final items = (data['messages'] as List)
//         .whereType<Map>()
//         .map((e) => WhatsAppInboxMessage.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//     items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
//     return items;
//   }

//   Future<void> sendAudio({
//     required String phone,
//     required Uint8List bytes,
//     required String mimeType,
//     bool voice = true,
//   }) async {
//     final data = await _request(
//       method: 'POST',
//       body: {
//         'action': 'send_audio',
//         'to': phone,
//         'audio_base64': base64Encode(bytes),
//         'mime_type': mimeType,
//         'voice': voice,
//       },
//     );
//     if (data['success'] != true) {
//       throw Exception(
//         data['error']?.toString() ?? 'Failed to send WhatsApp audio.',
//       );
//     }
//     if (data['saved'] == false) {
//       throw Exception(
//         'WhatsApp accepted the audio, but saving it to the inbox failed. Refresh the conversation.',
//       );
//     }
//   }

//   Future<Uint8List> fetchAudioBytes(String messageId) async {
//     final session = Supabase.instance.client.auth.currentSession;
//     if (session == null) throw Exception('Please sign in to play audio.');
//     final uri = Uri.parse(endpoint)
//         .replace(queryParameters: {'audio_message_id': messageId});
//     final response = await http
//         .get(
//           uri,
//           headers: {
//             'Accept': '*/*',
//             'Authorization': 'Bearer ${session.accessToken}',
//           },
//         )
//         .timeout(const Duration(seconds: 30));
//     if (response.statusCode < 200 || response.statusCode >= 300) {
//       throw Exception('Could not load voice message (${response.statusCode}).');
//     }
//     return response.bodyBytes;
//   }

//   Future<void> sendMessage({
//     required String phone,
//     required String message,
//   }) async {
//     final data = await _request(
//       method: 'POST',
//       body: {'action': 'send', 'to': phone, 'message': message},
//     );
//     if (data['success'] != true) {
//       throw Exception(
//         data['error']?.toString() ?? 'Failed to send WhatsApp message.',
//       );
//     }
//     if (data['saved'] == false) {
//       throw Exception(
//         'Meta accepted the message, but saving it to the inbox failed. '
//         'Refresh the conversation before sending again.',
//       );
//     }
//   }
// }

// class WhatsAppInboxContent extends StatefulWidget {
//   const WhatsAppInboxContent({super.key});

//   @override
//   State<WhatsAppInboxContent> createState() => _WhatsAppInboxContentState();
// }

// class _WhatsAppInboxContentState extends State<WhatsAppInboxContent> {
//   final WhatsAppInboxService _service = WhatsAppInboxService();
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();

//   List<WhatsAppInboxMessage> _conversations = [];
//   List<WhatsAppInboxMessage> _messages = [];
//   String? _selectedPhone;
//   String? _error;
//   bool _loading = false;
//   bool _loadingMessages = false;
//   bool _sending = false;
//   int _requestVersion = 0;
//   dynamic _realtimeChannel;
//   Timer? _realtimeDebounce;
//   Timer? _pollTimer;
//   bool _pollRequestRunning = false;
//   html.MediaStream? _recordingStream;
//   html.MediaRecorder? _mediaRecorder;
//   final List<html.Blob> _recordingChunks = [];
//   bool _recording = false;
//   bool _sendingAudio = false;
//   DateTime? _recordingStartedAt;
//   Timer? _recordingTimer;
//   int _recordingSeconds = 0;
//   final Map<String, String> _audioObjectUrls = {};
//   final Set<String> _playingAudio = {};

//   AppPalette get p => AppPalette.of(context);

//   @override
//   void initState() {
//     super.initState();
//     refreshInbox();
//     _subscribeToWhatsAppUpdates();

//     // Fallback in case Supabase Realtime is not enabled/configured correctly.
//     // The inbox checks for new rows every 2 seconds without user interaction.
//     _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
//       if (!mounted ||
//           _pollRequestRunning ||
//           _loading ||
//           _loadingMessages ||
//           _sending) {
//         return;
//       }
//       _pollRequestRunning = true;
//       try {
//         await refreshInbox(silent: true);
//       } finally {
//         _pollRequestRunning = false;
//       }
//     });
//   }

//   void _subscribeToWhatsAppUpdates() {
//     // Listen for new incoming/outgoing messages and status updates in Supabase.
//     // Realtime must be enabled for public.whatsapp_inbox_messages.
//     _realtimeChannel = Supabase.instance.client
//         .channel('whatsapp-inbox-live-updates')
//         .onPostgresChanges(
//           event: PostgresChangeEvent.all,
//           schema: 'public',
//           table: 'whatsapp_inbox_messages',
//           callback: (payload) {
//             // Coalesce bursts (e.g. message insert + status updates) into one fetch.
//             _realtimeDebounce?.cancel();
//             _realtimeDebounce = Timer(const Duration(milliseconds: 250), () {
//               if (mounted) refreshInbox(silent: true);
//             });
//           },
//         )
//         .subscribe();
//   }

//   @override
//   void dispose() {
//     _realtimeDebounce?.cancel();
//     _pollTimer?.cancel();
//     if (_realtimeChannel != null) {
//       Supabase.instance.client.removeChannel(_realtimeChannel);
//     }
//     _recordingTimer?.cancel();
//     _stopTracks();
//     for (final url in _audioObjectUrls.values) {
//       html.Url.revokeObjectUrl(url);
//     }
//     _controller.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> refreshInbox({bool silent = false}) async {
//     final version = ++_requestVersion;
//     if (!mounted) return;
//     if (!silent) {
//       setState(() {
//         _loading = true;
//         _error = null;
//       });
//     }

//     try {
//       final rows = await _service.fetchConversations();
//       if (!mounted || version != _requestVersion) return;

//       final oldPhone = _selectedPhone;
//       final phones = rows.map((e) => e.phone).toSet();
//       final nextPhone = oldPhone != null && phones.contains(oldPhone)
//           ? oldPhone
//           : (rows.isEmpty ? null : rows.first.phone);

//       setState(() {
//         _conversations = rows;
//         _selectedPhone = nextPhone;
//         if (!silent) _loading = false;
//       });

//       if (nextPhone != null) {
//         await _loadMessages(nextPhone, silent: silent);
//       } else {
//         setState(() {
//           _messages = [];
//           if (!silent) _loading = false;
//         });
//       }
//     } catch (e) {
//       if (!mounted || version != _requestVersion) return;
//       setState(() {
//         if (!silent) _loading = false;
//         _error = e.toString();
//       });
//     }
//   }

//   Future<void> _selectPhone(String phone) async {
//     if (_selectedPhone == phone) return;
//     setState(() {
//       _selectedPhone = phone;
//       _messages = [];
//       _error = null;
//     });
//     await _loadMessages(phone);
//   }

//   Future<void> _loadMessages(String phone, {bool silent = false}) async {
//     if (!mounted) return;
//     if (!silent) setState(() => _loadingMessages = true);
//     try {
//       final rows = await _service.fetchMessages(phone);
//       if (!mounted || _selectedPhone != phone) return;
//       setState(() {
//         _messages = rows;
//         if (!silent) _loadingMessages = false;
//         if (silent) _error = null;
//       });
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (_scrollController.hasClients) {
//           _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
//         }
//       });
//     } catch (e) {
//       if (!mounted || _selectedPhone != phone) return;
//       setState(() {
//         if (!silent) _loadingMessages = false;
//         _error = e.toString();
//       });
//     }
//   }

//   Future<void> _sendMessage() async {
//     final phone = _selectedPhone;
//     final text = _controller.text.trim();
//     if (phone == null || text.isEmpty || _sending) return;

//     setState(() => _sending = true);
//     try {
//       await _service.sendMessage(phone: phone, message: text);
//       if (!mounted) return;
//       _controller.clear();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('WhatsApp message sent successfully.')),
//       );
//       await refreshInbox();
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Could not send WhatsApp message: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _sending = false);
//     }
//   }

//   void _stopTracks() {
//     try {
//       _recordingStream?.getTracks().forEach((track) => track.stop());
//     } catch (_) {}
//     _recordingStream = null;
//   }

//   String? _supportedRecordingMime() {
//     const candidates = [
//       'audio/mp4',
//       'audio/ogg;codecs=opus',
//       'audio/ogg',
//       'audio/mpeg',
//       'audio/aac',
//       'audio/3gpp',
//     ];
//     for (final type in candidates) {
//       try {
//         if (html.MediaRecorder.isTypeSupported(type)) return type;
//       } catch (_) {}
//     }
//     return null;
//   }

//   Future<void> _startRecording() async {
//     if (_recording || _sendingAudio || _selectedPhone == null) return;
//     final mimeType = _supportedRecordingMime();
//     if (mimeType == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'This browser cannot record a WhatsApp-compatible audio format. Try Safari or use an audio file in a supported format.',
//           ),
//         ),
//       );
//       return;
//     }
//     try {
//       final stream = await html.window.navigator.mediaDevices!.getUserMedia({
//         'audio': true,
//       });
//       final recorder = html.MediaRecorder(stream, {'mimeType': mimeType});
//       _recordingChunks.clear();
//       // Use DOM event listeners because dart:html's MediaRecorder stream
//       // accessors are not exposed consistently by the current Dart SDK.
//       recorder.addEventListener('dataavailable', (html.Event event) {
//         final data = (event as dynamic).data as html.Blob?;
//         if (data != null && data.size > 0) {
//           _recordingChunks.add(data);
//         }
//       });
//       _recordingStream = stream;
//       _mediaRecorder = recorder;
//       recorder.start();
//       if (!mounted) return;
//       setState(() {
//         _recording = true;
//         _recordingSeconds = 0;
//         _recordingStartedAt = DateTime.now();
//       });
//       _recordingTimer?.cancel();
//       _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//         if (mounted && _recordingStartedAt != null) {
//           setState(
//             () => _recordingSeconds = DateTime.now()
//                 .difference(_recordingStartedAt!)
//                 .inSeconds,
//           );
//         }
//       });
//     } catch (e) {
//       _stopTracks();
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Microphone access failed: $e')));
//     }
//   }

//   Future<void> _stopRecordingAndSend() async {
//     final recorder = _mediaRecorder;
//     final phone = _selectedPhone;
//     if (recorder == null || phone == null || !_recording || _sendingAudio) {
//       return;
//     }
//     final stopped = Completer<void>();
//     recorder.addEventListener('stop', (html.Event _) {
//       if (!stopped.isCompleted) stopped.complete();
//     });
//     try {
//       recorder.stop();
//       await stopped.future.timeout(const Duration(seconds: 5));
//       _recordingTimer?.cancel();
//       final chunks = List<html.Blob>.from(_recordingChunks);
//       final recordedMimeType = recorder.mimeType;
//       final mimeType = recordedMimeType != null && recordedMimeType.isNotEmpty
//           ? recordedMimeType.split(';').first
//           : (_supportedRecordingMime() ?? 'audio/mp4').split(';').first;
//       _stopTracks();
//       if (chunks.isEmpty) {
//         throw Exception('No audio was recorded. Please try again.');
//       }
//       final blob = html.Blob(chunks, mimeType);
//       final reader = html.FileReader();
//       reader.readAsArrayBuffer(blob);
//       await reader.onLoad.first;
//       final result = reader.result;
//       if (result is! ByteBuffer) {
//         throw Exception('Could not read the recorded audio.');
//       }
//       final bytes = Uint8List.view(result);
//       if (!mounted) return;
//       setState(() {
//         _recording = false;
//         _sendingAudio = true;
//       });
//       await _service.sendAudio(
//         phone: phone,
//         bytes: bytes,
//         mimeType: mimeType,
//         voice: true,
//       );
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('WhatsApp voice message sent.')),
//       );
//       await refreshInbox();
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Could not send voice message: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       _recordingTimer?.cancel();
//       _stopTracks();
//       if (mounted) {
//         setState(() {
//           _recording = false;
//           _sendingAudio = false;
//           _recordingStartedAt = null;
//           _recordingSeconds = 0;
//           _mediaRecorder = null;
//           _recordingChunks.clear();
//         });
//       }
//     }
//   }

//   Future<void> _cancelRecording() async {
//     try {
//       _mediaRecorder?.stop();
//     } catch (_) {}
//     _recordingTimer?.cancel();
//     _stopTracks();
//     if (mounted) {
//       setState(() {
//         _recording = false;
//         _recordingStartedAt = null;
//         _recordingSeconds = 0;
//         _mediaRecorder = null;
//         _recordingChunks.clear();
//       });
//     }
//   }

//   String _durationLabel(int seconds) {
//     final m = (seconds ~/ 60).toString().padLeft(2, '0');
//     final s = (seconds % 60).toString().padLeft(2, '0');
//     return '$m:$s';
//   }

//   Future<void> _playAudio(WhatsAppInboxMessage message) async {
//     final id = message.messageId;
//     if (id == null || id.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('This audio message has no WhatsApp message ID.'),
//         ),
//       );
//       return;
//     }
//     try {
//       String? objectUrl = _audioObjectUrls[id];
//       if (objectUrl == null) {
//         final bytes = await _service.fetchAudioBytes(id);
//         final blob = html.Blob([bytes], message.audioMimeType ?? 'audio/ogg');
//         objectUrl = html.Url.createObjectUrlFromBlob(blob);
//         _audioObjectUrls[id] = objectUrl;
//       }
//       final audio = html.AudioElement(objectUrl);
//       audio.controls = true;
//       audio.autoplay = true;
//       await audio.play();
//       if (!mounted) return;
//       setState(() => _playingAudio.add(id));
//       audio.onEnded.first.then((_) {
//         if (mounted) setState(() => _playingAudio.remove(id));
//       });
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Playing voice message.')));
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Could not play voice message: $e')),
//       );
//     }
//   }

//   String _name(WhatsAppInboxMessage m) {
//     final name = m.customerName?.trim();
//     return name != null && name.isNotEmpty ? name : '+${m.phone}';
//   }

//   String _time(DateTime date) {
//     final d = date.toLocal();
//     final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
//     final minute = d.minute.toString().padLeft(2, '0');
//     return '$hour:$minute ${d.hour >= 12 ? 'PM' : 'AM'}';
//   }

//   Widget _empty(String title, String subtitle) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 76,
//               height: 76,
//               decoration: BoxDecoration(
//                 color: ChannelColors.waDeep.withValues(alpha: .10),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.chat_bubble_outline,
//                 size: 34,
//                 color: ChannelColors.waDeep,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w800,
//                 color: p.textPrimary,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               subtitle,
//               textAlign: TextAlign.center,
//               style: TextStyle(color: p.textMuted, height: 1.4),
//             ),
//             const SizedBox(height: 16),
//             TintedButton(
//               onPressed: refreshInbox,
//               icon: Icons.refresh,
//               label: 'Refresh WhatsApp',
//               gradient: ChannelColors.waGradient,
//               color: ChannelColors.waDeep,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _conversationList(bool wide) {
//     return ListView(
//       padding: wide
//           ? const EdgeInsets.all(10)
//           : const EdgeInsets.fromLTRB(10, 10, 4, 10),
//       scrollDirection: wide ? Axis.vertical : Axis.horizontal,
//       children: [
//         for (final item in _conversations)
//           _ConvTile(
//             wide: wide,
//             selected: item.phone == _selectedPhone,
//             accent: ChannelColors.waDeep,
//             name: _name(item),
//             time: _time(item.createdAt),
//             preview: item.isAudio
//                 ? '🎤 Voice message'
//                 : (item.text.isEmpty ? 'No text preview' : item.text),
//             previewLines: 2,
//             onTap: () => _selectPhone(item.phone),
//             avatar: _Avatar(
//               _name(item),
//               size: 42,
//               gradient: ChannelColors.waGradient,
//             ),
//           ),
//       ],
//     );
//   }

//   // WhatsApp-style bubbles: soft green outgoing (deep green in dark mode).
//   Color get _outBubble =>
//       p.isDark ? const Color(0xFF005C4B) : const Color(0xFFDCF8C6);
//   Color get _outText => p.isDark ? Colors.white : const Color(0xFF17212B);
//   Color get _outMeta => p.isDark ? Colors.white70 : const Color(0xFF607078);

//   Widget _bubble(WhatsAppInboxMessage message) {
//     final outgoing = message.isOutgoing;

//     if (message.isAudio) {
//       return Align(
//         alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
//         child: Container(
//           margin: const EdgeInsets.only(bottom: 10),
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//           constraints: const BoxConstraints(maxWidth: 430),
//           decoration: BoxDecoration(
//             color: outgoing ? _outBubble : p.surface,
//             borderRadius: BorderRadius.circular(16),
//             border: outgoing ? null : Border.all(color: p.border),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               IconButton(
//                 tooltip: 'Play voice message',
//                 onPressed: message.messageId == null
//                     ? null
//                     : () => _playAudio(message),
//                 icon: const Icon(
//                   Icons.play_circle_fill_rounded,
//                   size: 36,
//                   color: ChannelColors.waDeep,
//                 ),
//               ),
//               const SizedBox(width: 4),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     'Voice message',
//                     style: TextStyle(
//                       fontWeight: FontWeight.w700,
//                       color: outgoing ? _outText : p.textPrimary,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     _time(message.createdAt),
//                     style: TextStyle(
//                       fontSize: 10,
//                       color: outgoing ? _outMeta : p.textMuted,
//                     ),
//                   ),
//                   if (outgoing && message.status != null)
//                     Text(
//                       message.status!,
//                       style: TextStyle(fontSize: 10, color: _outMeta),
//                     ),
//                 ],
//               ),
//               const SizedBox(width: 8),
//             ],
//           ),
//         ),
//       );
//     }

//     return Align(
//       alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 10),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//         constraints: const BoxConstraints(maxWidth: 430),
//         decoration: BoxDecoration(
//           color: outgoing ? _outBubble : p.surface,
//           borderRadius: BorderRadius.only(
//             topLeft: const Radius.circular(16),
//             topRight: const Radius.circular(16),
//             bottomLeft: Radius.circular(outgoing ? 16 : 4),
//             bottomRight: Radius.circular(outgoing ? 4 : 16),
//           ),
//           border: outgoing ? null : Border.all(color: p.border),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               message.text,
//               style: TextStyle(
//                 color: outgoing ? _outText : p.textPrimary,
//                 height: 1.35,
//               ),
//             ),
//             const SizedBox(height: 5),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   _time(message.createdAt),
//                   style: TextStyle(
//                     fontSize: 10,
//                     color: outgoing ? _outMeta : p.textMuted,
//                   ),
//                 ),
//                 if (outgoing && message.status != null) ...[
//                   const SizedBox(width: 6),
//                   Text(
//                     message.status!,
//                     style: TextStyle(fontSize: 10, color: _outMeta),
//                   ),
//                 ],
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _thread() {
//     final phone = _selectedPhone;
//     final selected = _conversations.where((e) => e.phone == phone);
//     final display = selected.isEmpty
//         ? (phone == null ? 'WhatsApp conversation' : '+$phone')
//         : _name(selected.first);

//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           decoration: BoxDecoration(
//             color: p.surface,
//             border: Border(bottom: BorderSide(color: p.border)),
//           ),
//           child: Row(
//             children: [
//               _Avatar(display, size: 40, gradient: ChannelColors.waGradient),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       display,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontWeight: FontWeight.w800,
//                         fontSize: 15,
//                         color: p.textPrimary,
//                       ),
//                     ),
//                     const SizedBox(height: 3),
//                     Text(
//                       '+$_selectedPhone',
//                       style: TextStyle(color: p.textMuted, fontSize: 12),
//                     ),
//                   ],
//                 ),
//               ),
//               IconButton(
//                 tooltip: 'Refresh messages',
//                 onPressed: phone == null || _loadingMessages
//                     ? null
//                     : () => _loadMessages(phone),
//                 icon: Icon(Icons.refresh_rounded, color: p.textMuted),
//               ),
//             ],
//           ),
//         ),
//         if (_error != null)
//           MaterialBanner(
//             backgroundColor: p.amberSoft,
//             content: Text(_error!),
//             actions: [
//               TextButton(onPressed: refreshInbox, child: const Text('Retry')),
//             ],
//           ),
//         Expanded(
//           child: ColoredBox(
//             color: p.isDark
//                 ? p.pageBg
//                 : const Color(0xFFEFE7DD).withValues(alpha: .55),
//             child: _loadingMessages && _messages.isEmpty
//                 ? const Center(
//                     child: CircularProgressIndicator(
//                       color: ChannelColors.waDeep,
//                     ),
//                   )
//                 : _messages.isEmpty
//                 ? _empty(
//                     'No messages yet',
//                     'Messages saved by your WhatsApp webhook will appear here.',
//                   )
//                 : ListView(
//                     controller: _scrollController,
//                     padding: const EdgeInsets.all(20),
//                     children: _messages.map(_bubble).toList(),
//                   ),
//           ),
//         ),
//         Container(
//           padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
//           decoration: BoxDecoration(
//             color: p.surface,
//             border: Border(top: BorderSide(color: p.border)),
//           ),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               if (_recording)
//                 IconButton(
//                   tooltip: 'Cancel recording',
//                   onPressed: _cancelRecording,
//                   icon: const Icon(Icons.close_rounded, color: Colors.red),
//                 )
//               else
//                 IconButton(
//                   tooltip: 'Record voice message',
//                   onPressed: phone == null || _sending || _sendingAudio
//                       ? null
//                       : _startRecording,
//                   icon: const Icon(
//                     Icons.mic_none_rounded,
//                     color: ChannelColors.waDeep,
//                   ),
//                 ),
//               if (_recording)
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 14,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.red.withValues(alpha: .10),
//                       borderRadius: BorderRadius.circular(24),
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(
//                           Icons.fiber_manual_record,
//                           size: 12,
//                           color: Colors.red,
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             'Recording ${_durationLabel(_recordingSeconds)}',
//                             style: TextStyle(color: p.textPrimary),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 )
//               else
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     minLines: 1,
//                     maxLines: 4,
//                     maxLength: 4096,
//                     enabled: phone != null && !_sending,
//                     textCapitalization: TextCapitalization.sentences,
//                     onSubmitted: (_) => _sendMessage(),
//                     decoration: _pillField(
//                       p,
//                       phone == null
//                           ? 'Select a conversation'
//                           : 'Message on WhatsApp…',
//                       ChannelColors.wa,
//                     ),
//                   ),
//                 ),
//               const SizedBox(width: 10),
//               IconButton.filled(
//                 tooltip: _recording
//                     ? 'Send voice message'
//                     : 'Send WhatsApp message',
//                 onPressed: phone == null || _sending || _sendingAudio
//                     ? null
//                     : (_recording ? _stopRecordingAndSend : _sendMessage),
//                 style: IconButton.styleFrom(
//                   backgroundColor: ChannelColors.waDeep,
//                   foregroundColor: Colors.white,
//                   disabledBackgroundColor: ChannelColors.waDeep.withValues(
//                     alpha: .3,
//                   ),
//                   padding: const EdgeInsets.all(14),
//                 ),
//                 icon: (_sending || _sendingAudio)
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.white,
//                         ),
//                       )
//                     : const Icon(Icons.send_rounded),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final wide = MediaQuery.sizeOf(context).width >= 860;

//     if (_loading && _conversations.isEmpty) {
//       return const Center(
//         child: CircularProgressIndicator(color: ChannelColors.waDeep),
//       );
//     }
//     if (_error != null && _conversations.isEmpty) {
//       return _empty('Could not load WhatsApp Inbox', _error!);
//     }
//     if (_conversations.isEmpty) {
//       return _empty(
//         'No WhatsApp conversations yet',
//         'When your WhatsApp webhook saves incoming messages to Supabase, customers will appear here.',
//       );
//     }

//     return Column(
//       children: [
//         _Toolbar(
//           title:
//               '${_conversations.length} conversation${_conversations.length == 1 ? '' : 's'}',
//           loading: _loading,
//           onRefresh: refreshInbox,
//           color: ChannelColors.waDeep,
//           tooltip: 'Refresh WhatsApp',
//         ),
//         Expanded(
//           child: _InboxFrame(
//             child: wide
//                 ? Row(
//                     children: [
//                       SizedBox(width: 320, child: _conversationList(true)),
//                       VerticalDivider(width: 1, color: p.border),
//                       Expanded(child: _thread()),
//                     ],
//                   )
//                 : Column(
//                     children: [
//                       SizedBox(height: 92, child: _conversationList(false)),
//                       Divider(height: 1, color: p.border),
//                       Expanded(child: _thread()),
//                     ],
//                   ),
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';
import 'package:raigon_art/features/messaging/models/channel.dart';
import 'package:raigon_art/features/messaging/provider/messaging_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/channel_badge.dart';
import '../widgets/channel_style.dart';

// ─────────────────────────────────────────────────────────────
// Shared UI pieces (private to the inbox)
// ─────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar(
    this.label, {
    required this.size,
    required this.gradient,
    this.imageUrl,
  });

  final String label;
  final double size;
  final Gradient gradient;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final t = label.replaceFirst('@', '').replaceFirst('+', '').trim();
    final url = imageUrl?.trim();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  debugPrint('Instagram avatar loaded successfully');
                  return child;
                }

                return Center(
                  child: SizedBox(
                    width: size * 0.3,
                    height: size * 0.3,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Instagram avatar failed to load: $error');
                return _fallbackAvatar(t);
              },
            )
          : _fallbackAvatar(t),
    );
  }

  Widget _fallbackAvatar(String text) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
      child: Text(
        text.isEmpty ? '?' : text[0].toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

class _ConvTile extends StatelessWidget {
  const _ConvTile({
    required this.avatar,
    required this.name,
    required this.time,
    required this.preview,
    required this.selected,
    required this.accent,
    required this.wide,
    required this.onTap,
    this.previewLines = 1,
  });

  final Widget avatar;
  final String name, time, preview;
  final bool selected, wide;
  final Color accent;
  final VoidCallback onTap;
  final int previewLines;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      width: wide ? null : 240,
      margin: EdgeInsets.only(bottom: wide ? 6 : 0, right: wide ? 0 : 8),
      child: Material(
        color: selected ? accent.withValues(alpha: .09) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: .55)
                    : Colors.transparent,
                width: 1.3,
              ),
            ),
            child: Row(
              children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: p.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            time,
                            style: TextStyle(
                              color: p.textMuted,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        preview,
                        maxLines: previewLines,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.textMuted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.title,
    required this.loading,
    required this.onRefresh,
    required this.color,
    required this.tooltip,
  });
  final String title, tooltip;
  final bool loading;
  final VoidCallback onRefresh;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: p.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (loading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            ),
          IconButton(
            tooltip: tooltip,
            onPressed: loading ? null : onRefresh,
            icon: Icon(Icons.refresh_rounded, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

class _InboxFrame extends StatelessWidget {
  const _InboxFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 860;
    return Container(
      margin: EdgeInsets.fromLTRB(narrow ? 12 : 20, 4, narrow ? 12 : 20, 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
        boxShadow: p.softShadow,
      ),
      child: child,
    );
  }
}

InputDecoration _pillField(AppPalette p, String hint, Color focus) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    hintText: hint,
    counterText: '',
    filled: true,
    fillColor: p.chipFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    border: b(Colors.transparent),
    enabledBorder: b(Colors.transparent),
    disabledBorder: b(Colors.transparent),
    focusedBorder: b(focus, 1.4),
  );
}

// ─────────────────────────────────────────────────────────────
// Instagram
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
    debugPrint(
      'Instagram inbox response: '
      '${json['sender_username']} -> '
      '${json['sender_profile_picture']}',
    );
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

    final uri = Uri.parse(endpoint).replace(
      queryParameters: const {
        'instagram_user_id': '17841415634351143',
        'limit': '200',
      },
    );

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

class InstagramInboxContent extends StatefulWidget {
  const InstagramInboxContent({super.key, required this.s});

  final MessagingAutomationProvider s;

  @override
  State<InstagramInboxContent> createState() => _InstagramInboxContentState();
}

class _InstagramInboxContentState extends State<InstagramInboxContent> {
  final InstagramInboxService _service = InstagramInboxService();

  List<InstagramInboxMessage> _messages = [];
  String? _error;
  bool _loading = false;
  String? _selectedSender;
  int _requestVersion = 0;

  final TextEditingController _messageController = TextEditingController();

  bool _sendingMessage = false;
  Timer? _instagramPollTimer;
  bool _instagramPollRunning = false;
  dynamic _instagramRealtimeChannel;
  Timer? _instagramRealtimeDebounce;

  AppPalette get p => AppPalette.of(context);

  @override
  void initState() {
    super.initState();
    refreshMessages();
    _subscribeToInstagramUpdates();

    // Keep polling as a fallback if Realtime is unavailable.
    _instagramPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || _instagramPollRunning || _loading || _sendingMessage) {
        return;
      }

      _instagramPollRunning = true;
      try {
        await refreshMessages(silent: true);
      } finally {
        _instagramPollRunning = false;
      }
    });
  }

  void _subscribeToInstagramUpdates() {
    // Listen for new messages and message changes saved by the Instagram webhook.
    // Realtime must be enabled for public.instagram_messages.
    _instagramRealtimeChannel = Supabase.instance.client
        .channel('instagram-inbox-live-updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'instagram_messages',
          callback: (payload) {
            // Coalesce nearby INSERT/UPDATE events into one inbox refresh.
            _instagramRealtimeDebounce?.cancel();
            _instagramRealtimeDebounce = Timer(
              const Duration(milliseconds: 250),
              () {
                if (mounted) refreshMessages(silent: true);
              },
            );
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _instagramRealtimeDebounce?.cancel();
    _instagramPollTimer?.cancel();
    if (_instagramRealtimeChannel != null) {
      Supabase.instance.client.removeChannel(_instagramRealtimeChannel);
    }
    _messageController.dispose();
    super.dispose();
  }

  Future<void> refreshMessages({bool silent = false}) async {
    final requestVersion = ++_requestVersion;

    if (mounted && !silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final messages = await _service.fetchMessages();

      if (!mounted || requestVersion != _requestVersion) return;

      setState(() {
        _messages = messages;
        if (!silent) _loading = false;
        _error = null;
        final senders = _groupMessages(messages).keys.toList();

        if (_selectedSender == null || !senders.contains(_selectedSender)) {
          _selectedSender = senders.isEmpty ? null : senders.first;
        }
      });
    } catch (e) {
      if (!mounted || requestVersion != _requestVersion) return;

      if (silent) {
        debugPrint('Instagram auto-refresh failed: $e');
        return;
      }

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _sendMessage() async {
    final recipientId = _selectedSender;
    final message = _messageController.text.trim();

    if (recipientId == null || recipientId.isEmpty) return;
    if (message.isEmpty || _sendingMessage) return;

    setState(() => _sendingMessage = true);

    try {
      await _service.sendMessage(recipientId: recipientId, message: message);

      if (!mounted) return;

      _messageController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Instagram message sent successfully.')),
      );

      await refreshMessages();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingMessage = false);
      }
    }
  }

  Map<String, List<InstagramInboxMessage>> _groupMessages(
    List<InstagramInboxMessage> messages,
  ) {
    final groups = <String, List<InstagramInboxMessage>>{};

    for (final message in messages) {
      if (message.senderId.isEmpty) continue;

      groups.putIfAbsent(message.senderId, () => []);
      groups[message.senderId]!.add(message);
    }

    for (final group in groups.values) {
      group.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return groups;
  }

  String _senderDisplayName(
    String senderId,
    List<InstagramInboxMessage> messages,
  ) {
    for (final message in messages) {
      final username = message.senderUsername?.trim();
      if (username != null && username.isNotEmpty) {
        return username.startsWith('@') ? username : '@$username';
      }
    }
    return senderId;
  }

  String _time(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _statusView({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: ChannelColors.ig.withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: ChannelColors.ig),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMuted, height: 1.4),
            ),
            if (action != null) ...[const SizedBox(height: 18), action],
          ],
        ),
      ),
    );
  }

  Widget _tile(
    String sender,
    Map<String, List<InstagramInboxMessage>> groups,
    String? selected,
    bool wide,
  ) {
    final messages = groups[sender]!;
    final latest = messages.last;
    final display = _senderDisplayName(sender, messages);
    return _ConvTile(
      wide: wide,
      selected: sender == selected,
      accent: ChannelColors.ig,
      name: display,
      time: _time(latest.createdAt),
      preview: latest.text,
      onTap: () => setState(() => _selectedSender = sender),
      avatar: Stack(
        clipBehavior: Clip.none,
        children: [
          _Avatar(
            display,
            size: 42,
            gradient: ChannelColors.igGradient,
            imageUrl: latest.senderProfilePicture,
          ),
          const Positioned(
            right: -3,
            bottom: -3,
            child: ChannelBadge(Channel.instagram, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _bubble(InstagramInboxMessage message) {
    final bot = message.fromBot;
    final who = message.senderUsername?.trim().isNotEmpty == true
        ? (message.senderUsername!.startsWith('@')
              ? message.senderUsername!
              : '@${message.senderUsername}')
        : '@${message.senderId}';
    return Align(
      alignment: bot ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          gradient: bot ? ChannelColors.igBubble : null,
          color: bot ? null : p.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(bot ? 18 : 4),
            bottomRight: Radius.circular(bot ? 4 : 18),
          ),
          border: bot ? null : Border.all(color: p.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              who,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: bot ? Colors.white70 : p.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.text,
              style: TextStyle(
                height: 1.35,
                color: bot ? Colors.white : p.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _time(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: bot ? Colors.white70 : p.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupMessages(_messages);
    final senders = groups.keys.toList();
    final selected = _selectedSender;
    final conversation = selected == null
        ? <InstagramInboxMessage>[]
        : groups[selected] ?? [];

    final wide = MediaQuery.sizeOf(context).width >= 860;

    if (_loading && _messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: ChannelColors.ig),
      );
    }

    if (_error != null && _messages.isEmpty) {
      return _statusView(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load Inbox',
        message: _error!,
        action: TintedButton(
          onPressed: refreshMessages,
          icon: Icons.refresh,
          label: 'Try again',
          gradient: ChannelColors.igBubble,
          color: ChannelColors.ig,
        ),
      );
    }

    if (_messages.isEmpty) {
      return _statusView(
        icon: Icons.forum_outlined,
        title: 'No Instagram messages yet',
        message:
            _error ??
            'New messages received by your connected Instagram account '
                'will appear here.',
        action: TintedButton(
          onPressed: refreshMessages,
          icon: Icons.refresh,
          label: 'Refresh Inbox',
          gradient: ChannelColors.igBubble,
          color: ChannelColors.ig,
        ),
      );
    }

    final conversationList = ListView(
      padding: wide
          ? const EdgeInsets.all(10)
          : const EdgeInsets.fromLTRB(10, 10, 4, 10),
      scrollDirection: wide ? Axis.vertical : Axis.horizontal,
      children: [
        for (final sender in senders) _tile(sender, groups, selected, wide),
      ],
    );

    final selectedName = selected == null
        ? 'Instagram conversation'
        : _senderDisplayName(selected, groups[selected] ?? const []);

    final thread = Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: Row(
            children: [
              _Avatar(
                selectedName,
                size: 38,
                gradient: ChannelColors.igGradient,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: p.textPrimary,
                      ),
                    ),
                    Text(
                      'Instagram DM',
                      style: TextStyle(color: p.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_error != null)
          MaterialBanner(
            backgroundColor: p.amberSoft,
            content: Text('Refresh failed: $_error'),
            actions: [
              TextButton(
                onPressed: refreshMessages,
                child: const Text('Retry'),
              ),
            ],
          ),
        Expanded(
          child: ColoredBox(
            color: p.pageBg,
            child: ListView(
              key: ValueKey(selected),
              reverse: true,
              padding: const EdgeInsets.all(20),
              children: [
                for (final message in conversation.reversed) _bubble(message),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(top: BorderSide(color: p.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: _pillField(
                    p,
                    'Message on Instagram…',
                    ChannelColors.ig,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: 'Send Instagram message',
                onPressed: _sendingMessage ? null : _sendMessage,
                style: IconButton.styleFrom(
                  backgroundColor: ChannelColors.ig,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: ChannelColors.ig.withValues(
                    alpha: .3,
                  ),
                  padding: const EdgeInsets.all(14),
                ),
                icon: _sendingMessage
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );

    return Column(
      children: [
        _Toolbar(
          title:
              '${senders.length} conversation${senders.length == 1 ? '' : 's'}',
          loading: _loading,
          onRefresh: refreshMessages,
          color: ChannelColors.ig,
          tooltip: 'Refresh Inbox',
        ),
        Expanded(
          child: _InboxFrame(
            child: wide
                ? Row(
                    children: [
                      SizedBox(width: 320, child: conversationList),
                      VerticalDivider(width: 1, color: p.border),
                      Expanded(child: thread),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(height: 86, child: conversationList),
                      Divider(height: 1, color: p.border),
                      Expanded(child: thread),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Inbox page (tabs)
// ─────────────────────────────────────────────────────────────

/// Shared Inbox page with independent Instagram and WhatsApp tabs.
/// Instagram uses the existing InstagramInboxService and implementation below.
/// WhatsApp uses the separate whatsapp_inbox Edge Function.
class InboxPage extends StatelessWidget {
  const InboxPage({super.key, required this.s});

  final MessagingAutomationProvider s;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    Widget tab(IconData icon, String text, Color c) => Tab(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: c),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );

    return DefaultTabController(
      length: 2,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inbox',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Manage Instagram DMs and WhatsApp conversations',
                          style: TextStyle(color: p.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: p.chipFill,
                      border: Border.all(color: p.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      overlayColor: const WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                      indicator: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.border),
                        boxShadow: p.softShadow,
                      ),
                      labelColor: p.textPrimary,
                      unselectedLabelColor: p.textMuted,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      tabs: [
                        tab(
                          Icons.camera_alt_outlined,
                          'Instagram',
                          ChannelColors.ig,
                        ),
                        tab(
                          Icons.chat_bubble_outline_rounded,
                          'WhatsApp',
                          ChannelColors.waDeep,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                // Swiping would fight with the horizontal conversation list.
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  InstagramInboxContent(s: s),
                  const WhatsAppInboxContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WhatsApp
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

class WhatsAppInboxContent extends StatefulWidget {
  const WhatsAppInboxContent({super.key});

  @override
  State<WhatsAppInboxContent> createState() => _WhatsAppInboxContentState();
}

class _WhatsAppInboxContentState extends State<WhatsAppInboxContent> {
  final WhatsAppInboxService _service = WhatsAppInboxService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<WhatsAppInboxMessage> _conversations = [];
  List<WhatsAppInboxMessage> _messages = [];
  String? _selectedPhone;
  String? _error;
  bool _loading = false;
  bool _loadingMessages = false;
  bool _sending = false;
  int _requestVersion = 0;
  dynamic _realtimeChannel;
  Timer? _realtimeDebounce;
  Timer? _pollTimer;
  bool _pollRequestRunning = false;
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

  @override
  void initState() {
    super.initState();
    refreshInbox();
    _subscribeToWhatsAppUpdates();

    // Fallback in case Supabase Realtime is not enabled/configured correctly.
    // The inbox checks for new rows every 2 seconds without user interaction.
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted ||
          _pollRequestRunning ||
          _loading ||
          _loadingMessages ||
          _sending) {
        return;
      }
      _pollRequestRunning = true;
      try {
        await refreshInbox(silent: true);
      } finally {
        _pollRequestRunning = false;
      }
    });
  }

  void _subscribeToWhatsAppUpdates() {
    // Listen for new incoming/outgoing messages and status updates in Supabase.
    // Realtime must be enabled for public.whatsapp_inbox_messages.
    _realtimeChannel = Supabase.instance.client
        .channel('whatsapp-inbox-live-updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'whatsapp_inbox_messages',
          callback: (payload) {
            // Coalesce bursts (e.g. message insert + status updates) into one fetch.
            _realtimeDebounce?.cancel();
            _realtimeDebounce = Timer(const Duration(milliseconds: 250), () {
              if (mounted) refreshInbox(silent: true);
            });
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
    _pollTimer?.cancel();
    if (_realtimeChannel != null) {
      Supabase.instance.client.removeChannel(_realtimeChannel);
    }
    _recordingTimer?.cancel();
    _stopTracks();
    for (final url in _audioObjectUrls.values) {
      html.Url.revokeObjectUrl(url);
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> refreshInbox({bool silent = false}) async {
    final version = ++_requestVersion;
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final rows = await _service.fetchConversations();
      if (!mounted || version != _requestVersion) return;

      final oldPhone = _selectedPhone;
      final phones = rows.map((e) => e.phone).toSet();
      final nextPhone = oldPhone != null && phones.contains(oldPhone)
          ? oldPhone
          : (rows.isEmpty ? null : rows.first.phone);

      setState(() {
        _conversations = rows;
        _selectedPhone = nextPhone;
        if (!silent) _loading = false;
      });

      if (nextPhone != null) {
        await _loadMessages(nextPhone, silent: silent);
      } else {
        setState(() {
          _messages = [];
          if (!silent) _loading = false;
        });
      }
    } catch (e) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        if (!silent) _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _selectPhone(String phone) async {
    if (_selectedPhone == phone) return;
    setState(() {
      _selectedPhone = phone;
      _messages = [];
      _error = null;
    });
    await _loadMessages(phone);
  }

  Future<void> _loadMessages(String phone, {bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _loadingMessages = true);
    try {
      final rows = await _service.fetchMessages(phone);
      if (!mounted || _selectedPhone != phone) return;
      setState(() {
        _messages = rows;
        if (!silent) _loadingMessages = false;
        if (silent) _error = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      if (!mounted || _selectedPhone != phone) return;
      setState(() {
        if (!silent) _loadingMessages = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _sendMessage() async {
    final phone = _selectedPhone;
    final text = _controller.text.trim();
    if (phone == null || text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await _service.sendMessage(phone: phone, message: text);
      if (!mounted) return;
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp message sent successfully.')),
      );
      await refreshInbox();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send WhatsApp message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

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
    if (_recording || _sendingAudio || _selectedPhone == null) return;
    final mimeType = _supportedRecordingMime();
    if (mimeType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This browser cannot record a WhatsApp-compatible audio format. Try Safari or use an audio file in a supported format.',
          ),
        ),
      );
      return;
    }
    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'audio': true,
      });
      final recorder = html.MediaRecorder(stream, {'mimeType': mimeType});
      _recordingChunks.clear();
      // Use DOM event listeners because dart:html's MediaRecorder stream
      // accessors are not exposed consistently by the current Dart SDK.
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Microphone access failed: $e')));
    }
  }

  Future<void> _stopRecordingAndSend() async {
    final recorder = _mediaRecorder;
    final phone = _selectedPhone;
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
      await _service.sendAudio(
        phone: phone,
        bytes: bytes,
        mimeType: mimeType,
        voice: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp voice message sent.')),
      );
      await refreshInbox();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send voice message: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This audio message has no WhatsApp message ID.'),
        ),
      );
      return;
    }
    try {
      String? objectUrl = _audioObjectUrls[id];
      if (objectUrl == null) {
        final bytes = await _service.fetchAudioBytes(id);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Playing voice message.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not play voice message: $e')),
      );
    }
  }

  String _name(WhatsAppInboxMessage m) {
    final name = m.customerName?.trim();
    return name != null && name.isNotEmpty ? name : '+${m.phone}';
  }

  String _time(DateTime date) {
    final d = date.toLocal();
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  Widget _empty(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: ChannelColors.waDeep.withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 34,
                color: ChannelColors.waDeep,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMuted, height: 1.4),
            ),
            const SizedBox(height: 16),
            TintedButton(
              onPressed: refreshInbox,
              icon: Icons.refresh,
              label: 'Refresh WhatsApp',
              gradient: ChannelColors.waGradient,
              color: ChannelColors.waDeep,
            ),
          ],
        ),
      ),
    );
  }

  Widget _conversationList(bool wide) {
    return ListView(
      padding: wide
          ? const EdgeInsets.all(10)
          : const EdgeInsets.fromLTRB(10, 10, 4, 10),
      scrollDirection: wide ? Axis.vertical : Axis.horizontal,
      children: [
        for (final item in _conversations)
          _ConvTile(
            wide: wide,
            selected: item.phone == _selectedPhone,
            accent: ChannelColors.waDeep,
            name: _name(item),
            time: _time(item.createdAt),
            preview: item.isAudio
                ? '🎤 Voice message'
                : (item.text.isEmpty ? 'No text preview' : item.text),
            previewLines: 2,
            onTap: () => _selectPhone(item.phone),
            avatar: _Avatar(
              _name(item),
              size: 42,
              gradient: ChannelColors.waGradient,
            ),
          ),
      ],
    );
  }

  // WhatsApp-style bubbles: soft green outgoing (deep green in dark mode).
  Color get _outBubble =>
      p.isDark ? const Color(0xFF005C4B) : const Color(0xFFDCF8C6);
  Color get _outText => p.isDark ? Colors.white : const Color(0xFF17212B);
  Color get _outMeta => p.isDark ? Colors.white70 : const Color(0xFF607078);

  Widget _bubble(WhatsAppInboxMessage message) {
    final outgoing = message.isOutgoing;

    if (message.isAudio) {
      return Align(
        alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          constraints: const BoxConstraints(maxWidth: 430),
          decoration: BoxDecoration(
            color: outgoing ? _outBubble : p.surface,
            borderRadius: BorderRadius.circular(16),
            border: outgoing ? null : Border.all(color: p.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Play voice message',
                onPressed: message.messageId == null
                    ? null
                    : () => _playAudio(message),
                icon: const Icon(
                  Icons.play_circle_fill_rounded,
                  size: 36,
                  color: ChannelColors.waDeep,
                ),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Voice message',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: outgoing ? _outText : p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _time(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: outgoing ? _outMeta : p.textMuted,
                    ),
                  ),
                  if (outgoing && message.status != null)
                    Text(
                      message.status!,
                      style: TextStyle(fontSize: 10, color: _outMeta),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 430),
        decoration: BoxDecoration(
          color: outgoing ? _outBubble : p.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(outgoing ? 16 : 4),
            bottomRight: Radius.circular(outgoing ? 4 : 16),
          ),
          border: outgoing ? null : Border.all(color: p.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: outgoing ? _outText : p.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _time(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: outgoing ? _outMeta : p.textMuted,
                  ),
                ),
                if (outgoing && message.status != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    message.status!,
                    style: TextStyle(fontSize: 10, color: _outMeta),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _thread() {
    final phone = _selectedPhone;
    final selected = _conversations.where((e) => e.phone == phone);
    final display = selected.isEmpty
        ? (phone == null ? 'WhatsApp conversation' : '+$phone')
        : _name(selected.first);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: Row(
            children: [
              _Avatar(display, size: 40, gradient: ChannelColors.waGradient),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '+$_selectedPhone',
                      style: TextStyle(color: p.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh messages',
                onPressed: phone == null || _loadingMessages
                    ? null
                    : () => _loadMessages(phone),
                icon: Icon(Icons.refresh_rounded, color: p.textMuted),
              ),
            ],
          ),
        ),
        if (_error != null)
          MaterialBanner(
            backgroundColor: p.amberSoft,
            content: Text(_error!),
            actions: [
              TextButton(onPressed: refreshInbox, child: const Text('Retry')),
            ],
          ),
        Expanded(
          child: ColoredBox(
            color: p.isDark
                ? p.pageBg
                : const Color(0xFFEFE7DD).withValues(alpha: .55),
            child: _loadingMessages && _messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ChannelColors.waDeep,
                    ),
                  )
                : _messages.isEmpty
                ? _empty(
                    'No messages yet',
                    'Messages saved by your WhatsApp webhook will appear here.',
                  )
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    children: _messages.map(_bubble).toList(),
                  ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(top: BorderSide(color: p.border)),
          ),
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
                  onPressed: phone == null || _sending || _sendingAudio
                      ? null
                      : _startRecording,
                  icon: const Icon(
                    Icons.mic_none_rounded,
                    color: ChannelColors.waDeep,
                  ),
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
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 4096,
                    enabled: phone != null && !_sending,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: _pillField(
                      p,
                      phone == null
                          ? 'Select a conversation'
                          : 'Message on WhatsApp…',
                      ChannelColors.wa,
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: _recording
                    ? 'Send voice message'
                    : 'Send WhatsApp message',
                onPressed: phone == null || _sending || _sendingAudio
                    ? null
                    : (_recording ? _stopRecordingAndSend : _sendMessage),
                style: IconButton.styleFrom(
                  backgroundColor: ChannelColors.waDeep,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: ChannelColors.waDeep.withValues(
                    alpha: .3,
                  ),
                  padding: const EdgeInsets.all(14),
                ),
                icon: (_sending || _sendingAudio)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 860;

    if (_loading && _conversations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: ChannelColors.waDeep),
      );
    }
    if (_error != null && _conversations.isEmpty) {
      return _empty('Could not load WhatsApp Inbox', _error!);
    }
    if (_conversations.isEmpty) {
      return _empty(
        'No WhatsApp conversations yet',
        'When your WhatsApp webhook saves incoming messages to Supabase, customers will appear here.',
      );
    }

    return Column(
      children: [
        _Toolbar(
          title:
              '${_conversations.length} conversation${_conversations.length == 1 ? '' : 's'}',
          loading: _loading,
          onRefresh: refreshInbox,
          color: ChannelColors.waDeep,
          tooltip: 'Refresh WhatsApp',
        ),
        Expanded(
          child: _InboxFrame(
            child: wide
                ? Row(
                    children: [
                      SizedBox(width: 320, child: _conversationList(true)),
                      VerticalDivider(width: 1, color: p.border),
                      Expanded(child: _thread()),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(height: 92, child: _conversationList(false)),
                      Divider(height: 1, color: p.border),
                      Expanded(child: _thread()),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
