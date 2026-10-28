// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:raigon_art/core/constants/asset_constants.dart';
// import 'package:raigon_art/core/theme/app_colors.dart';
// import 'package:raigon_art/core/theme/app_palette.dart';
// import 'package:raigon_art/core/theme/mx_theme.dart';
// import 'package:raigon_art/features/messaging/models/automation.dart';
// import 'package:raigon_art/features/messaging/models/channel.dart';
// import 'package:raigon_art/features/messaging/models/trigger_type.dart';
// import 'package:raigon_art/features/messaging/provider/messaging_provider.dart';

// import '../widgets/channel_badge.dart';
// import '../widgets/channel_style.dart';
// import '../widgets/gradient_button.dart';
// import '../widgets/page_shell.dart';
// import '../widgets/phone_sim.dart';
// import '../widgets/section_card.dart';
// import 'builder_page.dart';

// void openBuilder(
//   BuildContext context,
//   MessagingAutomationProvider s, {
//   Automation? existing,
//   TriggerType? preset,
// }) {
//   Navigator.of(context).push(
//     MaterialPageRoute(
//       fullscreenDialog: true,
//       builder: (_) => BuilderPage(s: s, existing: existing, preset: preset),
//     ),
//   );
// }

// void showTest(
//   BuildContext context,
//   MessagingAutomationProvider s,
//   Automation a,
// ) {
//   final p = AppPalette.of(context);
//   showDialog(
//     context: context,
//     builder: (ctx) => Dialog(
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       child: Stack(
//         alignment: Alignment.topRight,
//         children: [
//           Center(
//             child: PhoneSim(auto: a, s: s),
//           ),
//           IconButton.filled(
//             style: IconButton.styleFrom(
//               backgroundColor: p.surface,
//               foregroundColor: p.textPrimary,
//             ),
//             onPressed: () => Navigator.pop(ctx),
//             icon: const Icon(Icons.close_rounded),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// String _triggerLabel(TriggerType t) {
//   switch (t) {
//     case TriggerType.keyword:
//       return 'Keyword';
//     case TriggerType.anyMessage:
//       return 'Any message';
//     case TriggerType.postComment:
//       return 'Post comment';
//     case TriggerType.storyReply:
//       return 'Story reply';
//   }
// }

// // ─────────────────────────────────────────────────────────────
// // Page
// // ─────────────────────────────────────────────────────────────

// class AutomationsPage extends StatefulWidget {
//   const AutomationsPage({super.key, required this.s});
//   final MessagingAutomationProvider s;

//   @override
//   State<AutomationsPage> createState() => _AutomationsPageState();
// }

// class _AutomationsPageState extends State<AutomationsPage> {
//   final TextEditingController _search = TextEditingController();
//   int _status = 0; // 0 all, 1 active, 2 paused
//   Channel? _channel; // null = all channels
//   String _query = '';

//   MessagingAutomationProvider get s => widget.s;

//   @override
//   void dispose() {
//     _search.dispose();
//     super.dispose();
//   }

//   bool _isLive(Automation a) => a.live && s.accounts[a.channel] != null;

//   List<Automation> _filtered() {
//     final q = _query.trim().toLowerCase();
//     return s.automations.where((a) {
//       final live = _isLive(a);
//       if (_status == 1 && !live) return false;
//       if (_status == 2 && live) return false;
//       if (_channel != null && a.channel != _channel) return false;
//       if (q.isEmpty) return true;
//       return a.name.toLowerCase().contains(q) ||
//           a.summary.toLowerCase().contains(q) ||
//           a.keywords.any((k) => k.toLowerCase().contains(q));
//     }).toList();
//   }

//   void _clearFilters() {
//     setState(() {
//       _status = 0;
//       _channel = null;
//       _query = '';
//       _search.clear();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final p = AppPalette.of(context);
//     final empty = s.automations.isEmpty;
//     final firstLoad = empty && s.loadingAutomations;
//     final shown = _filtered();

//     return PageShell(
//       title: empty ? 'Let’s get started' : 'Automations',
//       subtitle: empty
//           ? 'Pick a popular first move. You can preview before going live.'
//           : 'Replies that run on their own, around the clock.',
//       onRefresh: s.loadAutomations,
//       action: empty
//           ? null
//           : GradientButton(
//               onPressed: () => openBuilder(context, s),
//               icon: Icons.add_rounded,
//               label: 'New automation',
//             ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (s.automationError != null)
//             _Banner(
//               text: 'Couldn’t sync with the server. Showing saved data.',
//               onRetry: s.loadAutomations,
//             ),
//           if (s.loadingAutomations)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 16),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(4),
//                 child: LinearProgressIndicator(
//                   minHeight: 3,
//                   color: p.accent,
//                   backgroundColor: p.accentSoft,
//                 ),
//               ),
//             ),
//           _ConnectPanel(s: s),
//           const SizedBox(height: 22),
//           if (!firstLoad)
//             if (empty)
//               _EmptyState(s: s)
//             else ...[
//               _FilterBar(
//                 status: _status,
//                 channel: _channel,
//                 controller: _search,
//                 onStatus: (v) => setState(() => _status = v),
//                 onChannel: (v) => setState(() => _channel = v),
//                 onQuery: (v) => setState(() => _query = v),
//               ),
//               const SizedBox(height: 16),
//               if (shown.isEmpty)
//                 _NoMatches(onClear: _clearFilters)
//               else
//                 for (final a in shown) _AutoCard(s: s, a: a),
//             ],
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// // Connect Your Channels panel
// // ─────────────────────────────────────────────────────────────

// class _ConnectPanel extends StatelessWidget {
//   const _ConnectPanel({required this.s});
//   final MessagingAutomationProvider s;

//   @override
//   Widget build(BuildContext context) {
//     final p = AppPalette.of(context);

//     return Container(
//       padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             p.mintSoft.withValues(alpha: p.isDark ? .55 : .8),
//             p.surface,
//           ],
//         ),
//         borderRadius: BorderRadius.circular(28),
//         border: Border.all(color: p.mint.withValues(alpha: .25)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Connect Your Channels',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.w800,
//               letterSpacing: -0.4,
//               color: p.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Link your Instagram and WhatsApp to start automating conversations.',
//             style: TextStyle(color: p.textMuted, fontSize: 13.5),
//           ),
//           const SizedBox(height: 18),
//           LayoutBuilder(
//             builder: (context, c) {
//               Widget card(Channel ch) => _ChannelCard(
//                 channel: ch,
//                 account: s.accounts[ch],
//                 onConnect: () => s.connectChannel(context, ch),
//                 onDisconnect: () => s.disconnect(ch),
//               );

//               final wa = card(Channel.whatsapp);
//               final ig = card(Channel.instagram);
//               const why = _WhyConnect();

//               if (c.maxWidth >= 980) {
//                 return IntrinsicHeight(
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       Expanded(flex: 5, child: wa),
//                       const SizedBox(width: 14),
//                       Expanded(flex: 5, child: ig),
//                       const SizedBox(width: 14),
//                       const Expanded(flex: 4, child: why),
//                     ],
//                   ),
//                 );
//               }

//               if (c.maxWidth >= 700) {
//                 return Column(
//                   children: [
//                     IntrinsicHeight(
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           Expanded(child: wa),
//                           const SizedBox(width: 14),
//                           Expanded(child: ig),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 14),
//                     why,
//                   ],
//                 );
//               }

//               return Column(
//                 children: [
//                   wa,
//                   const SizedBox(height: 14),
//                   ig,
//                   const SizedBox(height: 14),
//                   why,
//                 ],
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ChannelCard extends StatelessWidget {
//   const _ChannelCard({
//     required this.channel,
//     required this.account,
//     required this.onConnect,
//     required this.onDisconnect,
//   });

//   final Channel channel;
//   final String? account;
//   final VoidCallback onConnect;
//   final VoidCallback onDisconnect;

//   @override
//   Widget build(BuildContext context) {
//     final p = AppPalette.of(context);
//     final c = channel;
//     final connected = account != null;
//     final title = c.isIg ? 'Instagram' : 'WhatsApp Business';
//     final accountText = connected
//         ? (c.isIg && !account!.startsWith('@') ? '@$account' : account!)
//         : 'Not connected';

//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: p.surface,
//         borderRadius: BorderRadius.circular(22),
//         border: Border.all(color: p.border),
//         boxShadow: p.softShadow,
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           ChannelBadge(c, size: 60),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Flexible(
//                       child: Text(
//                         title,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           fontWeight: FontWeight.w800,
//                           fontSize: 16,
//                           color: p.textPrimary,
//                         ),
//                       ),
//                     ),
//                     const Spacer(),
//                     connected
//                         ? Pill('Connected', color: p.mint, soft: p.mintSoft)
//                         : Pill(
//                             'Not connected',
//                             color: p.textMuted,
//                             soft: p.chipFill,
//                           ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   c.blurb,
//                   maxLines: 3,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: p.textMuted,
//                     fontSize: 12.5,
//                     height: 1.45,
//                   ),
//                 ),
//                 const SizedBox(height: 14),
//                 Row(
//                   children: [
//                     Icon(
//                       connected
//                           ? Icons.check_circle_rounded
//                           : Icons.circle_outlined,
//                       size: 15,
//                       color: connected ? p.mint : p.textMuted,
//                     ),
//                     const SizedBox(width: 6),
//                     Flexible(
//                       child: Text(
//                         accountText,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           fontSize: 12.5,
//                           fontWeight: FontWeight.w700,
//                           color: connected ? p.textPrimary : p.textMuted,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     const Spacer(),
//                     connected
//                         ? _PillButton(
//                             label: 'Disconnect',
//                             icon: Icons.link_off_rounded,
//                             foreground: AppPalette.statusRed,
//                             background: AppPalette.statusRed.withValues(
//                               alpha: .10,
//                             ),
//                             onPressed: onDisconnect,
//                           )
//                         : _PillButton(
//                             label: 'Connect',
//                             icon: Icons.link_rounded,
//                             foreground: p.onBrand,
//                             gradient: p.brand,
//                             onPressed: onConnect,
//                           ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 6),
//           Padding(
//             padding: const EdgeInsets.only(top: 40),
//             child: InkWell(
//               borderRadius: BorderRadius.circular(20),
//               onTap: connected ? null : onConnect,
//               child: Tooltip(
//                 message: 'Check connection',
//                 child: Icon(Icons.chevron_right_rounded, color: p.textMuted),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PillButton extends StatelessWidget {
//   const _PillButton({
//     required this.label,
//     required this.icon,
//     required this.foreground,
//     required this.onPressed,
//     this.background,
//     this.gradient,
//   });

//   final String label;
//   final IconData icon;
//   final Color foreground;
//   final Color? background;
//   final Gradient? gradient;
//   final VoidCallback onPressed;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       child: Ink(
//         decoration: BoxDecoration(
//           color: background,
//           gradient: gradient,
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(20),
//           onTap: onPressed,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(icon, size: 15, color: foreground),
//                 const SizedBox(width: 6),
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 12.5,
//                     fontWeight: FontWeight.w700,
//                     color: foreground,
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

// class _WhyConnect extends StatelessWidget {
//   const _WhyConnect();

//   @override
//   Widget build(BuildContext context) {
//     final p = AppPalette.of(context);
//     const items = [
//       'Auto-reply to messages',
//       'Trigger workflows & automations',
//       'Collect customer data',
//       'Track performance & analytics',
//     ];

//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: p.surface.withValues(alpha: p.isDark ? .6 : .7),
//         borderRadius: BorderRadius.circular(22),
//         border: Border.all(color: p.mint.withValues(alpha: .25)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 38,
//                 height: 38,
//                 decoration: BoxDecoration(
//                   color: p.chipFill,
//                   shape: BoxShape.circle,
//                   border: Border.all(color: p.border),
//                 ),
//                 child: Icon(Icons.link_rounded, size: 19, color: p.textPrimary),
//               ),
//               const SizedBox(width: 12),
//               Text(
//                 'Why Connect?',
//                 style: TextStyle(
//                   fontWeight: FontWeight.w800,
//                   fontSize: 15.5,
//                   color: p.textPrimary,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 14),
//           for (final t in items)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 9),
//               child: Row(
//                 children: [
//                   Icon(Icons.check_circle_rounded, size: 16, color: p.mint),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: Text(
//                       t,
//                       style: TextStyle(fontSize: 12.5, color: p.textMuted),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// // Filter bar
// // ─────────────────────────────────────────────────────────────

// class _FilterBar extends StatelessWidget {
//   const _FilterBar({
//     required this.status,
//     required this.channel,
//     required this.controller,
//     required this.onStatus,
//     required this.onChannel,
//     required this.onQuery,
//   });

//   final int status;
//   final Channel? channel;
//   final TextEditingController controller;
//   final ValueChanged<int> onStatus;
//   final ValueChanged<Channel?> onChannel;
//   final ValueChanged<String> onQuery;

//   @override
//   Widget build(BuildContext context) {
//     final p = AppPalette.of(context);

//     final segmented = Container(
//       padding: const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         color: p.surface,
//         borderRadius: BorderRadius.circular(26),
//         border: Border.all(color: p.border),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _seg(p, 0, 'All', null),
//           _seg(p, 1, 'Active', p.mint),
//           _seg(p, 2, 'Paused', p.textMuted),
//         ],
//       ),
//     );

//     final search = TextField(
//       controller: controller,
//       onChanged: onQuery,
//       decoration: InputDecoration(
//         hintText: 'Search automations…',
//         hintStyle: TextStyle(color: p.textMuted, fontSize: 13.5),
//         prefixIcon: Icon(Icons.search_rounded, size: 20, color: p.textMuted),
//         filled: true,
//         fillColor: p.surface,
//         isDense: true,
//         contentPadding: const EdgeInsets.symmetric(vertical: 14),
//         border: _border(p.border),
//         enabledBorder: _border(p.border),
//         focusedBorder: _border(p.accent),
//       ),
//     );

//     final filter = PopupMenuButton<int>(
//       tooltip: 'Filter by channel',
//       onSelected: (v) => onChannel(
//         v == 0 ? null : (v == 1 ? Channel.instagram : Channel.whatsapp),
//       ),
//       itemBuilder: (_) => const <PopupMenuEntry<int>>[
//         PopupMenuItem<int>(value: 0, child: Text('All channels')),
//         PopupMenuItem<int>(value: 1, child: Text('Instagram')),
//         PopupMenuItem<int>(value: 2, child: Text('WhatsApp')),
//       ],
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
//         decoration: BoxDecoration(
//           color: channel == null ? p.surface : p.accentSoft,
//           borderRadius: BorderRadius.circular(26),
//           border: Border.all(
//             color: channel == null ? p.border : p.accent.withValues(alpha: .4),
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.filter_alt_outlined, size: 18, color: p.textPrimary),
//             const SizedBox(width: 8),
//             Text(
//               channel == null
//                   ? 'Filter'
//                   : (channel == Channel.instagram ? 'Instagram' : 'WhatsApp'),
//               style: TextStyle(
//                 fontSize: 13.5,
//                 fontWeight: FontWeight.w600,
//                 color: p.textPrimary,
//               ),
//             ),
//             const SizedBox(width: 4),
//             Icon(
//               Icons.keyboard_arrow_down_rounded,
//               size: 18,
//               color: p.textMuted,
//             ),
//           ],
//         ),
//       ),
//     );

//     return LayoutBuilder(
//       builder: (context, c) {
//         if (c.maxWidth >= 760) {
//           return Row(
//             children: [
//               segmented,
//               const Spacer(),
//               SizedBox(width: 320, child: search),
//               const SizedBox(width: 12),
//               filter,
//             ],
//           );
//         }
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             segmented,
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(child: search),
//                 const SizedBox(width: 10),
//                 filter,
//               ],
//             ),
//           ],
//         );
//       },
//     );
//   }

//   OutlineInputBorder _border(Color c) => OutlineInputBorder(
//     borderRadius: BorderRadius.circular(26),
//     borderSide: BorderSide(color: c),
//   );

//   Widget _seg(AppPalette p, int value, String label, Color? dot) {
//     final selected = status == value;
//     final bg = p.isDark ? p.accent : AppColors.black;
//     final fg = selected
//         ? (p.isDark ? AppColors.black : Colors.white)
//         : p.textMuted;

//     return MouseRegion(
//       cursor: SystemMouseCursors.click,
//       child: GestureDetector(
//         behavior: HitTestBehavior.opaque,
//         onTap: () => onStatus(value),
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 160),
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
//           decoration: BoxDecoration(
//             color: selected ? bg : Colors.transparent,
//             borderRadius: BorderRadius.circular(22),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (dot != null) ...[
//                 Container(
//                   width: 7,
//                   height: 7,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: selected ? dot : dot.withValues(alpha: .8),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//               ],
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 13.5,
//                   fontWeight: FontWeight.w700,
//                   color: fg,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _NoMatches extends StatelessWidget {
//   const _NoMatches({required this.onClear});
//   final VoidCallback onClear;

//   @override
//   Widget build(BuildContext context) {
//     final p = AppPalette.of(context);
//     return SectionCard(
//       padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
//       child: Center(
//         child: Column(
//           children: [
//             Icon(Icons.search_off_rounded, size: 32, color: p.textMuted),
//             const SizedBox(height: 10),
//             Text(
//               'No automations match your filters',
//               style: TextStyle(
//                 fontWeight: FontWeight.w700,
//                 color: p.textPrimary,
//               ),
//             ),
//             const SizedBox(height: 6),
//             TextButton(
//               onPressed: onClear,
//               style: TextButton.styleFrom(foregroundColor: p.accent),
//               child: const Text('Clear filters'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// // Banner + empty state (unchanged behaviour)
// // ─────────────────────────────────────────────────────────────

// class _Banner extends StatelessWidget {
//   const _Banner({required this.text, required this.onRetry});
//   final String text;
//   final Future<void> Function() onRetry;

//   @override
//   Widget build(BuildContext context) {
//     final p = AppPalette.of(context);
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
//       decoration: BoxDecoration(
//         color: p.amberSoft,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: p.amber.withValues(alpha: .4)),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.cloud_off_rounded, color: p.amber, size: 20),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               text,
//               style: TextStyle(fontSize: 13, color: p.textPrimary),
//             ),
//           ),
//           TextButton(
//             onPressed: onRetry,
//             style: TextButton.styleFrom(foregroundColor: p.accent),
//             child: const Text('Retry'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _EmptyState extends StatelessWidget {
//   const _EmptyState({required this.s});
//   final MessagingAutomationProvider s;

//   @override
//   Widget build(BuildContext context) {
//     final p = AppPalette.of(context);
//     const gold = Color(0xFFCDBB88);

//     Widget step(int n, String t) => Container(
//       padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
//       decoration: BoxDecoration(
//         color: Colors.white.withValues(alpha: .12),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 20,
//             height: 20,
//             alignment: Alignment.center,
//             decoration: const BoxDecoration(
//               color: gold,
//               shape: BoxShape.circle,
//             ),
//             child: Text(
//               '$n',
//               style: const TextStyle(
//                 color: Colors.black,
//                 fontSize: 11,
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Text(
//             t,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 12.5,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         ClipRRect(
//           borderRadius: BorderRadius.circular(28),
//           child: Container(
//             width: double.infinity,
//             decoration: BoxDecoration(gradient: p.brandDeep, boxShadow: p.glow),
//             child: Stack(
//               children: [
//                 Positioned(
//                   right: -50,
//                   top: -50,
//                   child: Container(
//                     width: 190,
//                     height: 190,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: gold.withValues(alpha: .10),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(28),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Reply to every DM, automatically',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 26,
//                           height: 1.15,
//                           fontWeight: FontWeight.w800,
//                           letterSpacing: -0.7,
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       Text(
//                         'Set a trigger, write the reply, test it in a phone preview, then go live.',
//                         style: TextStyle(
//                           color: Colors.white.withValues(alpha: .78),
//                           fontSize: 14,
//                           height: 1.45,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Wrap(
//                         spacing: 8,
//                         runSpacing: 8,
//                         children: [
//                           step(1, 'Channel'),
//                           step(2, 'Trigger'),
//                           step(3, 'Reply'),
//                           step(4, 'Go live'),
//                         ],
//                       ),
//                       const SizedBox(height: 24),
//                       FilledButton.icon(
//                         style: FilledButton.styleFrom(
//                           backgroundColor: gold,
//                           foregroundColor: Colors.black,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(14),
//                           ),
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 22,
//                             vertical: 16,
//                           ),
//                         ),
//                         onPressed: () => openBuilder(context, s),
//                         icon: const Icon(Icons.add_rounded),
//                         label: const Text(
//                           'Create automation',
//                           style: TextStyle(fontWeight: FontWeight.w700),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 30),
//         Text(
//           'Or start from a popular idea',
//           style: TextStyle(
//             fontSize: 17,
//             fontWeight: FontWeight.w800,
//             color: p.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 14),
//         LayoutBuilder(
//           builder: (context, c) {
//             final w = c.maxWidth >= 640 ? (c.maxWidth - 18) / 2 : c.maxWidth;
//             return Wrap(
//               spacing: 18,
//               runSpacing: 18,
//               children: [
//                 _StartCard(
//                   width: w,
//                   tag: 'Loved by creators',
//                   tagColor: ChannelColors.ig,
//                   gradient: ChannelColors.igBubble,
//                   icon: AssetConstants.instagram,
//                   title: 'Send a DM with your link every time someone comments on your post',
//                   cta: 'Send a link from comments',
//                   user: 'link pls!',
//                   bot: 'Here it is',
//                   onTap: () =>
//                       openBuilder(context, s, preset: TriggerType.postComment),
//                 ),
//                 _StartCard(
//                   width: w,
//                   tag: 'Boosts engagement',
//                   tagColor: ChannelColors.waDeep,
//                   gradient: ChannelColors.waGradient,
//                   icon: AssetConstants.whatsApp,
//                   title: 'Send customized replies when people DM you specific keywords',
//                   cta: 'Respond to your DMs',
//                   user: 'INFO',
//                   bot: 'Here you go',
//                   onTap: () =>
//                       openBuilder(context, s, preset: TriggerType.keyword),
//                 ),
//               ],
//             );
//           },
//         ),
//       ],
//     );
//   }
// }

// class _StartCard extends StatelessWidget {
//   const _StartCard({
//     required this.width,
//     required this.tag,
//     required this.tagColor,
//     required this.gradient,
//     required this.icon,
//     required this.title,
//     required this.cta,
//     required this.user,
//     required this.bot,
//     required this.onTap,
//   });
//   final double width;
//   final String tag, title, cta, user, bot;
//   final Color tagColor;
//   final LinearGradient gradient;
//   final String icon;
//   final VoidCallback onTap;

//   Widget _bubble(AppPalette p, String t, {bool right = false}) => Align(
//     alignment: right ? Alignment.centerRight : Alignment.centerLeft,
//     child: Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
//       decoration: BoxDecoration(
//         gradient: right ? gradient : null,
//         color: right ? null : p.surface,
//         border: right ? null : Border.all(color: p.border),
//         borderRadius: BorderRadius.circular(18),
//       ),
//       child: Text(
//         t,
//         style: TextStyle(
//           fontSize: 13,
//           color: right ? Colors.white : p.textPrimary,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     ),
//   );

//   @override
//   Widget build(BuildContext context) {
//     final p = AppPalette.of(context);
//     return SizedBox(
//       width: width,
//       child: SectionCard(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SvgPicture.asset(icon, width: 20, height: 20, fit: BoxFit.contain),
//             const SizedBox(height: 12),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w700,
//                 height: 1.35,
//                 color: p.textPrimary,
//               ),
//             ),
//             const SizedBox(height: 18),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: tagColor.withValues(alpha: .07),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 children: [
//                   _bubble(p, user),
//                   const SizedBox(height: 10),
//                   _bubble(p, bot, right: true),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 18),
//             SizedBox(
//               width: double.infinity,
//               child: GradientButton(label: cta, onPressed: onTap),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// // Automation card
// // ─────────────────────────────────────────────────────────────

// class _AutoCard extends StatelessWidget {
//   const _AutoCard({required this.s, required this.a});

//   final MessagingAutomationProvider s;
//   final Automation a;

//   @override
//   Widget build(BuildContext context) {
//     final p = AppPalette.of(context);
//     final connected = s.accounts[a.channel] != null;
//     final isLive = a.live && connected;

//     // Fixed-size tile with the SVG badge centered.
//     final tile = SizedBox(
//       width: 60,
//       height: 60,
//       child: Center(child: ChannelBadge(a.channel, size: 60)),
//     );
//     final info = Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Wrap(
//           spacing: 10,
//           runSpacing: 4,
//           crossAxisAlignment: WrapCrossAlignment.center,
//           children: [
//             Text(
//               a.name,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 fontWeight: FontWeight.w800,
//                 fontSize: 15,
//                 color: p.textPrimary,
//               ),
//             ),
//             isLive
//                 ? Pill(
//                     'Active',
//                     color: p.mint,
//                     soft: p.mintSoft,
//                     icon: Icons.circle,
//                     iconSize: 7,
//                   )
//                 : Pill(
//                     'Paused',
//                     color: p.textMuted,
//                     soft: p.chipFill,
//                     icon: Icons.pause_rounded,
//                   ),
//           ],
//         ),
//         const SizedBox(height: 5),
//         Text(
//           a.summary,
//           maxLines: 2,
//           overflow: TextOverflow.ellipsis,
//           style: TextStyle(color: p.textMuted, fontSize: 12.5, height: 1.4),
//         ),
//         const SizedBox(height: 10),
//         Wrap(
//           spacing: 8,
//           runSpacing: 8,
//           crossAxisAlignment: WrapCrossAlignment.center,
//           children: [
//             _Tag(a.channel.isIg ? 'Instagram' : 'WhatsApp'),
//             _Tag(_triggerLabel(a.trigger)),
//             for (final k in a.keywords.take(2)) _Tag(k),
//             if (!connected)
//               GestureDetector(
//                 onTap: () => s.setTab(2),
//                 child: Pill(
//                   'Channel disconnected · Fix',
//                   color: p.amber,
//                   soft: p.amberSoft,
//                   icon: Icons.link_off_rounded,
//                 ),
//               ),
//           ],
//         ),
//       ],
//     );

//     Widget stat(IconData icon, String value, String label) {
//       return _Stat(icon: icon, value: value, label: label);
//     }

//     Widget vline() => Container(
//       width: 1,
//       height: 40,
//       margin: const EdgeInsets.symmetric(horizontal: 14),
//       color: p.border,
//     );

//     final statReplies = stat(
//       Icons.chat_bubble_outline_rounded,
//       '${a.runs}',
//       'Replies',
//     );

//     final statTrigger = stat(
//       Icons.bolt_rounded,
//       _triggerLabel(a.trigger),
//       'Trigger',
//     );

//     final statStatus = stat(
//       Icons.power_settings_new_rounded,
//       isLive ? 'Live' : 'Paused',
//       'Status',
//     );

//     final toggle = Switch(
//       value: isLive,
//       activeThumbColor: Colors.white,
//       activeTrackColor: p.mint,
//       onChanged: connected
//           ? (_) async {
//               try {
//                 await s.toggleAsync(a);
//                 if (!context.mounted) return;
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Automation status updated.')),
//                 );
//               } catch (e) {
//                 if (!context.mounted) return;
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Could not update automation: $e')),
//                 );
//               }
//             }
//           : null,
//     );

//     final menu = _menu(context, p);

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 14),
//       child: SectionCard(
//         radius: 22,
//         padding: const EdgeInsets.fromLTRB(20, 18, 10, 18),
//         child: LayoutBuilder(
//           builder: (context, c) {
//             if (c.maxWidth >= 900) {
//               return Row(
//                 children: [
//                   tile,
//                   const SizedBox(width: 20),
//                   Expanded(child: info),
//                   const SizedBox(width: 18),
//                   Container(width: 1, height: 52, color: p.border),
//                   const SizedBox(width: 18),
//                   SizedBox(width: 118, child: statReplies),
//                   vline(),
//                   SizedBox(width: 128, child: statTrigger),
//                   vline(),
//                   SizedBox(width: 110, child: statStatus),
//                   const SizedBox(width: 20),
//                   toggle,
//                   menu,
//                 ],
//               );
//             }

//             return Column(
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     tile,
//                     const SizedBox(width: 16),
//                     Expanded(child: info),
//                     toggle,
//                     menu,
//                   ],
//                 ),
//                 const SizedBox(height: 14),
//                 Divider(height: 1, color: p.border),
//                 const SizedBox(height: 14),
//                 Padding(
//                   padding: const EdgeInsets.only(right: 10),
//                   child: Row(
//                     children: [
//                       Expanded(child: statReplies),
//                       vline(),
//                       Expanded(child: statTrigger),
//                       vline(),
//                       Expanded(child: statStatus),
//                     ],
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _menu(BuildContext context, AppPalette p) {
//     return PopupMenuButton<String>(
//       icon: Icon(Icons.more_vert_rounded, color: p.textMuted),
//       onSelected: (v) async {
//         if (v == 'test') showTest(context, s, a);
//         if (v == 'edit') openBuilder(context, s, existing: a);

//         if (v == 'delete') {
//           final ok = await showDialog<bool>(
//             context: context,
//             builder: (ctx) => AlertDialog(
//               title: const Text('Delete automation?'),
//               content: Text('“${a.name}” will stop replying and be removed.'),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(ctx, false),
//                   child: const Text('Keep'),
//                 ),
//                 TextButton(
//                   style: TextButton.styleFrom(foregroundColor: Colors.red),
//                   onPressed: () => Navigator.pop(ctx, true),
//                   child: const Text('Delete'),
//                 ),
//               ],
//             ),
//           );

//           if (ok == true) {
//             try {
//               await s.removeAsync(a);
//               if (!context.mounted) return;
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Automation deleted.')),
//               );
//             } catch (e) {
//               if (!context.mounted) return;
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text('Could not delete automation: $e')),
//               );
//             }
//           }
//         }
//       },
//       itemBuilder: (_) => const [
//         PopupMenuItem(
//           value: 'test',
//           child: ListTile(
//             dense: true,
//             contentPadding: EdgeInsets.zero,
//             leading: Icon(Icons.phone_iphone_rounded),
//             title: Text('Test in preview'),
//           ),
//         ),
//         PopupMenuItem(
//           value: 'edit',
//           child: ListTile(
//             dense: true,
//             contentPadding: EdgeInsets.zero,
//             leading: Icon(Icons.edit_rounded),
//             title: Text('Edit'),
//           ),
//         ),
//         PopupMenuItem(
//           value: 'delete',
//           child: ListTile(
//             dense: true,
//             contentPadding: EdgeInsets.zero,
//             leading: Icon(Icons.delete_outline_rounded),
//             title: Text('Delete'),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _Tag extends StatelessWidget {
//   const _Tag(this.text);
//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     final p = AppPalette.of(context);
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
//       decoration: BoxDecoration(
//         color: p.chipFill,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           fontSize: 11.5,
//           fontWeight: FontWeight.w600,
//           color: p.textMuted,
//         ),
//       ),
//     );
//   }
// }

// class _Stat extends StatelessWidget {
//   const _Stat({required this.icon, required this.value, required this.label});
//   final IconData icon;
//   final String value, label;

//   @override
//   Widget build(BuildContext context) {
//     final p = AppPalette.of(context);
//     return Row(
//       children: [
//         Icon(icon, size: 19, color: p.textMuted),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 value,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   fontWeight: FontWeight.w800,
//                   fontSize: 14,
//                   color: p.textPrimary,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(label, style: TextStyle(fontSize: 12, color: p.textMuted)),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:raigon_art/core/constants/asset_constants.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';
import 'package:raigon_art/features/messaging/models/automation.dart';
import 'package:raigon_art/features/messaging/models/channel.dart';
import 'package:raigon_art/features/messaging/models/trigger_type.dart';
import 'package:raigon_art/features/messaging/provider/messaging_provider.dart';

import '../widgets/channel_badge.dart';
import '../widgets/channel_style.dart';
import '../widgets/gradient_button.dart';
import '../widgets/page_shell.dart';
import '../widgets/phone_sim.dart';
import '../widgets/section_card.dart';
import 'builder_page.dart';

void openBuilder(
  BuildContext context,
  MessagingAutomationProvider s, {
  Automation? existing,
  TriggerType? preset,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => BuilderPage(s: s, existing: existing, preset: preset),
    ),
  );
}

void showTest(
  BuildContext context,
  MessagingAutomationProvider s,
  Automation a,
) {
  final p = AppPalette.of(context);
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Center(
            child: PhoneSim(auto: a, s: s),
          ),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: p.surface,
              foregroundColor: p.textPrimary,
            ),
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    ),
  );
}

String _triggerLabel(TriggerType t) {
  switch (t) {
    case TriggerType.keyword:
      return 'Keyword';
    case TriggerType.anyMessage:
      return 'Any message';
    case TriggerType.postComment:
      return 'Post comment';
    case TriggerType.storyReply:
      return 'Story reply';
  }
}

// ─────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────

class AutomationsPage extends StatefulWidget {
  const AutomationsPage({super.key, required this.s});
  final MessagingAutomationProvider s;

  @override
  State<AutomationsPage> createState() => _AutomationsPageState();
}

class _AutomationsPageState extends State<AutomationsPage> {
  final TextEditingController _search = TextEditingController();
  int _status = 0; // 0 all, 1 active, 2 paused
  Channel? _channel; // null = all channels
  String _query = '';

  MessagingAutomationProvider get s => widget.s;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _isLive(Automation a) => a.live && s.accounts[a.channel] != null;

  List<Automation> _filtered() {
    final q = _query.trim().toLowerCase();
    return s.automations.where((a) {
      final live = _isLive(a);
      if (_status == 1 && !live) return false;
      if (_status == 2 && live) return false;
      if (_channel != null && a.channel != _channel) return false;
      if (q.isEmpty) return true;
      return a.name.toLowerCase().contains(q) ||
          a.summary.toLowerCase().contains(q) ||
          a.keywords.any((k) => k.toLowerCase().contains(q));
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _status = 0;
      _channel = null;
      _query = '';
      _search.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final empty = s.automations.isEmpty;
    final firstLoad = empty && s.loadingAutomations;
    final shown = _filtered();

    return PageShell(
      title: empty ? 'Let’s get started' : 'Automations',
      subtitle: empty
          ? 'Pick a popular first move. You can preview before going live.'
          : 'Replies that run on their own, around the clock.',
      onRefresh: s.loadAutomations,
      action: empty
          ? null
          : GradientButton(
              onPressed: () => openBuilder(context, s),
              icon: Icons.add_rounded,
              label: 'New automation',
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.automationError != null)
            _Banner(
              text: 'Couldn’t sync with the server. Showing saved data.',
              onRetry: s.loadAutomations,
            ),
          if (s.loadingAutomations)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: p.accent,
                  backgroundColor: p.accentSoft,
                ),
              ),
            ),
          _ConnectPanel(s: s),
          const SizedBox(height: 22),
          if (!firstLoad)
            if (empty)
              _EmptyState(s: s)
            else ...[
              _FilterBar(
                status: _status,
                channel: _channel,
                controller: _search,
                onStatus: (v) => setState(() => _status = v),
                onChannel: (v) => setState(() => _channel = v),
                onQuery: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 16),
              if (shown.isEmpty)
                _NoMatches(onClear: _clearFilters)
              else
                for (final a in shown) _AutoCard(s: s, a: a),
            ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Connect Your Channels panel
// ─────────────────────────────────────────────────────────────

class _ConnectPanel extends StatelessWidget {
  const _ConnectPanel({required this.s});
  final MessagingAutomationProvider s;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.mintSoft.withValues(alpha: p.isDark ? .55 : .8),
            p.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: p.mint.withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect Your Channels',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Link your Instagram and WhatsApp to start automating conversations.',
            style: TextStyle(color: p.textMuted, fontSize: 13.5),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              Widget card(Channel ch) => _ChannelCard(
                channel: ch,
                account: s.accounts[ch],
                onConnect: () => s.connectChannel(
                  context,
                  ch,
                  switchAccount: ch.isIg && s.accounts[ch] != null,
                ),
                onDisconnect: () => s.disconnect(ch),
              );

              final wa = card(Channel.whatsapp);
              final ig = card(Channel.instagram);
              const why = _WhyConnect();

              if (c.maxWidth >= 980) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: wa),
                      const SizedBox(width: 14),
                      Expanded(flex: 5, child: ig),
                      const SizedBox(width: 14),
                      const Expanded(flex: 4, child: why),
                    ],
                  ),
                );
              }

              if (c.maxWidth >= 700) {
                return Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: wa),
                          const SizedBox(width: 14),
                          Expanded(child: ig),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    why,
                  ],
                );
              }

              return Column(
                children: [
                  wa,
                  const SizedBox(height: 14),
                  ig,
                  const SizedBox(height: 14),
                  why,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.channel,
    required this.account,
    required this.onConnect,
    required this.onDisconnect,
  });

  final Channel channel;
  final String? account;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final c = channel;
    final connected = account != null;
    final title = c.isIg ? 'Instagram' : 'WhatsApp Business';
    final accountText = connected
        ? (c.isIg && !account!.startsWith('@') ? '@$account' : account!)
        : 'Not connected';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
        boxShadow: p.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChannelBadge(c, size: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    connected
                        ? Pill('Connected', color: p.mint, soft: p.mintSoft)
                        : Pill(
                            'Not connected',
                            color: p.textMuted,
                            soft: p.chipFill,
                          ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  c.blurb,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.textMuted,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      connected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 15,
                      color: connected ? p.mint : p.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        accountText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: connected ? p.textPrimary : p.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Spacer(),
                    connected
                        ? _PillButton(
                            label: c.isIg ? 'Switch account' : 'Disconnect',
                            icon: c.isIg
                                ? Icons.swap_horiz_rounded
                                : Icons.link_off_rounded,
                            foreground: c.isIg
                                ? p.onBrand
                                : AppPalette.statusRed,
                            background: c.isIg
                                ? null
                                : AppPalette.statusRed.withValues(alpha: .10),
                            gradient: c.isIg ? p.brand : null,
                            onPressed: c.isIg ? onConnect : onDisconnect,
                          )
                        : _PillButton(
                            label: 'Connect',
                            icon: Icons.link_rounded,
                            foreground: p.onBrand,
                            gradient: p.brand,
                            onPressed: onConnect,
                          ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: connected ? null : onConnect,
              child: Tooltip(
                message: 'Check connection',
                child: Icon(Icons.chevron_right_rounded, color: p.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.onPressed,
    this.background,
    this.gradient,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color? background;
  final Gradient? gradient;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: background,
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: foreground),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: foreground,
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

class _WhyConnect extends StatelessWidget {
  const _WhyConnect();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    const items = [
      'Auto-reply to messages',
      'Trigger workflows & automations',
      'Collect customer data',
      'Track performance & analytics',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: p.isDark ? .6 : .7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.mint.withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: p.chipFill,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.border),
                ),
                child: Icon(Icons.link_rounded, size: 19, color: p.textPrimary),
              ),
              const SizedBox(width: 12),
              Text(
                'Why Connect?',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final t in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: p.mint),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: TextStyle(fontSize: 12.5, color: p.textMuted),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Filter bar
// ─────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.status,
    required this.channel,
    required this.controller,
    required this.onStatus,
    required this.onChannel,
    required this.onQuery,
  });

  final int status;
  final Channel? channel;
  final TextEditingController controller;
  final ValueChanged<int> onStatus;
  final ValueChanged<Channel?> onChannel;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    final segmented = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg(p, 0, 'All', null),
          _seg(p, 1, 'Active', p.mint),
          _seg(p, 2, 'Paused', p.textMuted),
        ],
      ),
    );

    final search = TextField(
      controller: controller,
      onChanged: onQuery,
      decoration: InputDecoration(
        hintText: 'Search automations…',
        hintStyle: TextStyle(color: p.textMuted, fontSize: 13.5),
        prefixIcon: Icon(Icons.search_rounded, size: 20, color: p.textMuted),
        filled: true,
        fillColor: p.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: _border(p.border),
        enabledBorder: _border(p.border),
        focusedBorder: _border(p.accent),
      ),
    );

    final filter = PopupMenuButton<int>(
      tooltip: 'Filter by channel',
      onSelected: (v) => onChannel(
        v == 0 ? null : (v == 1 ? Channel.instagram : Channel.whatsapp),
      ),
      itemBuilder: (_) => const <PopupMenuEntry<int>>[
        PopupMenuItem<int>(value: 0, child: Text('All channels')),
        PopupMenuItem<int>(value: 1, child: Text('Instagram')),
        PopupMenuItem<int>(value: 2, child: Text('WhatsApp')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: channel == null ? p.surface : p.accentSoft,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: channel == null ? p.border : p.accent.withValues(alpha: .4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_outlined, size: 18, color: p.textPrimary),
            const SizedBox(width: 8),
            Text(
              channel == null
                  ? 'Filter'
                  : (channel == Channel.instagram ? 'Instagram' : 'WhatsApp'),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: p.textMuted,
            ),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 760) {
          return Row(
            children: [
              segmented,
              const Spacer(),
              SizedBox(width: 320, child: search),
              const SizedBox(width: 12),
              filter,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            segmented,
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 10),
                filter,
              ],
            ),
          ],
        );
      },
    );
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(26),
    borderSide: BorderSide(color: c),
  );

  Widget _seg(AppPalette p, int value, String label, Color? dot) {
    final selected = status == value;
    final bg = p.isDark ? p.accent : AppColors.black;
    final fg = selected
        ? (p.isDark ? AppColors.black : Colors.white)
        : p.textMuted;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onStatus(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? bg : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? dot : dot.withValues(alpha: .8),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SectionCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 32, color: p.textMuted),
            const SizedBox(height: 10),
            Text(
              'No automations match your filters',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(foregroundColor: p.accent),
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Banner + empty state (unchanged behaviour)
// ─────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.onRetry});
  final String text;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: p.amberSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.amber.withValues(alpha: .4)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: p.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: p.textPrimary),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: p.accent),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.s});
  final MessagingAutomationProvider s;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    const gold = Color(0xFFCDBB88);

    Widget step(int n, String t) => Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: gold,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$n',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            t,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(gradient: p.brandDeep, boxShadow: p.glow),
            child: Stack(
              children: [
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gold.withValues(alpha: .10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reply to every DM, automatically',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Set a trigger, write the reply, test it in a phone preview, then go live.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .78),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          step(1, 'Channel'),
                          step(2, 'Trigger'),
                          step(3, 'Reply'),
                          step(4, 'Go live'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 16,
                          ),
                        ),
                        onPressed: () => openBuilder(context, s),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text(
                          'Create automation',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'Or start from a popular idea',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth >= 640 ? (c.maxWidth - 18) / 2 : c.maxWidth;
            return Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                _StartCard(
                  width: w,
                  tag: 'Loved by creators',
                  tagColor: ChannelColors.ig,
                  gradient: ChannelColors.igBubble,
                  icon: AssetConstants.instagram,
                  title: 'Send a DM with your link every time someone comments on your post',
                  cta: 'Send a link from comments',
                  user: 'link pls!',
                  bot: 'Here it is',
                  onTap: () =>
                      openBuilder(context, s, preset: TriggerType.postComment),
                ),
                _StartCard(
                  width: w,
                  tag: 'Boosts engagement',
                  tagColor: ChannelColors.waDeep,
                  gradient: ChannelColors.waGradient,
                  icon: AssetConstants.whatsApp,
                  title: 'Send customized replies when people DM you specific keywords',
                  cta: 'Respond to your DMs',
                  user: 'INFO',
                  bot: 'Here you go',
                  onTap: () =>
                      openBuilder(context, s, preset: TriggerType.keyword),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({
    required this.width,
    required this.tag,
    required this.tagColor,
    required this.gradient,
    required this.icon,
    required this.title,
    required this.cta,
    required this.user,
    required this.bot,
    required this.onTap,
  });
  final double width;
  final String tag, title, cta, user, bot;
  final Color tagColor;
  final LinearGradient gradient;
  final String icon;
  final VoidCallback onTap;

  Widget _bubble(AppPalette p, String t, {bool right = false}) => Align(
    alignment: right ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        gradient: right ? gradient : null,
        color: right ? null : p.surface,
        border: right ? null : Border.all(color: p.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        t,
        style: TextStyle(
          fontSize: 13,
          color: right ? Colors.white : p.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SizedBox(
      width: width,
      child: SectionCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(icon, width: 20, height: 20, fit: BoxFit.contain),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _bubble(p, user),
                  const SizedBox(height: 10),
                  _bubble(p, bot, right: true),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: GradientButton(label: cta, onPressed: onTap),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Automation card
// ─────────────────────────────────────────────────────────────

class _AutoCard extends StatelessWidget {
  const _AutoCard({required this.s, required this.a});

  final MessagingAutomationProvider s;
  final Automation a;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final connected = s.accounts[a.channel] != null;
    final isLive = a.live && connected;

    // Fixed-size tile with the SVG badge centered.
    final tile = SizedBox(
      width: 60,
      height: 60,
      child: Center(child: ChannelBadge(a.channel, size: 60)),
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              a.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: p.textPrimary,
              ),
            ),
            isLive
                ? Pill(
                    'Active',
                    color: p.mint,
                    soft: p.mintSoft,
                    icon: Icons.circle,
                    iconSize: 7,
                  )
                : Pill(
                    'Paused',
                    color: p.textMuted,
                    soft: p.chipFill,
                    icon: Icons.pause_rounded,
                  ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          a.summary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: p.textMuted, fontSize: 12.5, height: 1.4),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Tag(a.channel.isIg ? 'Instagram' : 'WhatsApp'),
            _Tag(_triggerLabel(a.trigger)),
            for (final k in a.keywords.take(2)) _Tag(k),
            if (!connected)
              GestureDetector(
                onTap: () => s.setTab(2),
                child: Pill(
                  'Channel disconnected · Fix',
                  color: p.amber,
                  soft: p.amberSoft,
                  icon: Icons.link_off_rounded,
                ),
              ),
          ],
        ),
      ],
    );

    Widget stat(IconData icon, String value, String label) {
      return _Stat(icon: icon, value: value, label: label);
    }

    Widget vline() => Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: p.border,
    );

    final statReplies = stat(
      Icons.chat_bubble_outline_rounded,
      '${a.runs}',
      'Replies',
    );

    final statTrigger = stat(
      Icons.bolt_rounded,
      _triggerLabel(a.trigger),
      'Trigger',
    );

    final statStatus = stat(
      Icons.power_settings_new_rounded,
      isLive ? 'Live' : 'Paused',
      'Status',
    );

    final toggle = Switch(
      value: isLive,
      activeThumbColor: Colors.white,
      activeTrackColor: p.mint,
      onChanged: connected
          ? (_) async {
              try {
                await s.toggleAsync(a);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Automation status updated.')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not update automation: $e')),
                );
              }
            }
          : null,
    );

    final menu = _menu(context, p);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SectionCard(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(20, 18, 10, 18),
        child: LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= 900) {
              return Row(
                children: [
                  tile,
                  const SizedBox(width: 20),
                  Expanded(child: info),
                  const SizedBox(width: 18),
                  Container(width: 1, height: 52, color: p.border),
                  const SizedBox(width: 18),
                  SizedBox(width: 118, child: statReplies),
                  vline(),
                  SizedBox(width: 128, child: statTrigger),
                  vline(),
                  SizedBox(width: 110, child: statStatus),
                  const SizedBox(width: 20),
                  toggle,
                  menu,
                ],
              );
            }

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tile,
                    const SizedBox(width: 16),
                    Expanded(child: info),
                    toggle,
                    menu,
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: p.border),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    children: [
                      Expanded(child: statReplies),
                      vline(),
                      Expanded(child: statTrigger),
                      vline(),
                      Expanded(child: statStatus),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _menu(BuildContext context, AppPalette p) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: p.textMuted),
      onSelected: (v) async {
        if (v == 'test') showTest(context, s, a);
        if (v == 'edit') openBuilder(context, s, existing: a);

        if (v == 'delete') {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete automation?'),
              content: Text('“${a.name}” will stop replying and be removed.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Keep'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );

          if (ok == true) {
            try {
              await s.removeAsync(a);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Automation deleted.')),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not delete automation: $e')),
              );
            }
          }
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'test',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.phone_iphone_rounded),
            title: Text('Test in preview'),
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_rounded),
            title: Text('Edit'),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline_rounded),
            title: Text('Delete'),
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: p.chipFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: p.textMuted,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value, label;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        Icon(icon, size: 19, color: p.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 12, color: p.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}
