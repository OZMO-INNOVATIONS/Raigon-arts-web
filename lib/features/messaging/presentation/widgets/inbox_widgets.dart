import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';
import 'package:raigon_art/features/messaging/models/channel.dart';

import 'channel_badge.dart';
import 'channel_style.dart';

// ─────────────────────────────────────────────────────────────
// Time / date helpers
// ─────────────────────────────────────────────────────────────

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// 12-hour clock label used inside message bubbles.
String formatInboxTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

bool isSameInboxDay(DateTime a, DateTime b) {
  final x = a.toLocal();
  final y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

/// Conversation list time: clock time for today, short date otherwise.
String formatInboxListTime(DateTime date) {
  final local = date.toLocal();
  if (isSameInboxDay(local, DateTime.now())) return formatInboxTime(local);
  return '${local.day} ${_months[local.month - 1]}';
}

/// Label for the date chip inside a thread, e.g. "Today, 26 Oct 2026".
String formatInboxDay(DateTime date) {
  final d = date.toLocal();
  final now = DateTime.now();
  final label = '${d.day} ${_months[d.month - 1]} ${d.year}';
  if (isSameInboxDay(d, now)) return 'Today, $label';
  if (isSameInboxDay(d, now.subtract(const Duration(days: 1)))) {
    return 'Yesterday, $label';
  }
  return label;
}

// ─────────────────────────────────────────────────────────────
// Avatars
// ─────────────────────────────────────────────────────────────

class ChatAvatar extends StatelessWidget {
  const ChatAvatar(
    this.label, {
    super.key,
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
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _fallback(t);
              },
              errorBuilder: (context, error, stackTrace) => _fallback(t),
            )
          : _fallback(t),
    );
  }

  Widget _fallback(String text) => Center(
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

/// Avatar with the small channel badge (Instagram only, like the reference).
class AvatarWithBadge extends StatelessWidget {
  const AvatarWithBadge({
    super.key,
    required this.label,
    required this.channel,
    this.size = 44,
    this.imageUrl,
  });

  final String label;
  final Channel channel;
  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final avatar = ChatAvatar(
      label,
      size: size,
      gradient: channel.isIg
          ? ChannelColors.igGradient
          : ChannelColors.waGradient,
      imageUrl: imageUrl,
    );
    if (!channel.isIg) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            padding: const EdgeInsets.all(1.6),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ChannelBadge(channel, size: size >= 44 ? 18 : 16),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Left panel: header, tabs, sort, section header
// ─────────────────────────────────────────────────────────────

class MessagesPanelHeader extends StatelessWidget {
  const MessagesPanelHeader({
    super.key,
    required this.filterActive,
    required this.onFilter,
  });

  final bool filterActive;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Instagram & WhatsApp conversations',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.textMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: filterActive ? 'Showing unread only' : 'Filter unread',
            child: Material(
              color: filterActive ? p.accentSoft : p.chipFill,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onFilter,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: filterActive
                          ? p.accent.withValues(alpha: .4)
                          : p.border,
                    ),
                  ),
                  child: Icon(
                    Icons.filter_list_rounded,
                    size: 20,
                    color: filterActive ? p.accent : p.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChannelTabs extends StatelessWidget {
  const ChannelTabs({
    super.key,
    required this.active,
    required this.onChanged,
    required this.badge,
  });

  final Channel active;
  final ValueChanged<Channel> onChanged;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Expanded(child: _tab(context, p, Channel.instagram)),
          const SizedBox(width: 4),
          Expanded(child: _tab(context, p, Channel.whatsapp)),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, AppPalette p, Channel channel) {
    final selected = channel == active;
    final isInstagram = channel.isIg;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final brandColor = isInstagram ? ChannelColors.ig : ChannelColors.waDeep;

    final brandGradient = channel.brandGradient;
    final label = isInstagram ? 'Instagram' : 'WhatsApp';

    final lightSelectedColor = isInstagram
        ? const Color(0xFFFCE7F3)
        : const Color(0xFFDCFCE7);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(channel),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? null : lightSelectedColor)
                : Colors.transparent,
            gradient: selected && isDark ? brandGradient : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? brandColor.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ChannelBadge(channel, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? (isDark ? Colors.white : brandColor)
                        : brandColor,
                  ),
                ),
              ),
              if (selected && badge > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: isDark ? null : brandGradient,
                    color: isDark ? Colors.white.withValues(alpha: 0.22) : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SortRow extends StatelessWidget {
  const SortRow({
    super.key,
    required this.count,
    required this.latestFirst,
    required this.onChanged,
  });

  final int count;
  final bool latestFirst;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            '$count conversation${count == 1 ? '' : 's'}',
            style: TextStyle(
              color: p.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        PopupMenuButton<bool>(
          tooltip: 'Sort conversations',
          initialValue: latestFirst,
          onSelected: onChanged,
          itemBuilder: (_) => const <PopupMenuEntry<bool>>[
            PopupMenuItem<bool>(value: true, child: Text('Latest')),
            PopupMenuItem<bool>(value: false, child: Text('Oldest')),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                latestFirst ? 'Latest' : 'Oldest',
                style: TextStyle(
                  color: p.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: p.textMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class InboxListHint extends StatelessWidget {
  const InboxListHint({
    super.key,
    required this.message,
    this.loading = false,
    this.onRetry,
  });

  final String message;
  final bool loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        children: [
          if (loading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: p.accent),
            )
          else
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMuted, fontSize: 12.5, height: 1.4),
            ),
          if (!loading && onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Conversation tile
// ─────────────────────────────────────────────────────────────

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.avatar,
    required this.name,
    required this.time,
    required this.preview,
    required this.selected,
    required this.onTap,
    this.unread = false,
    this.indicatorColor,
    this.previewLines = 1,
    this.unreadCount = 0,
    this.isInstagram = false,
  });

  final Widget avatar;
  final String name, time, preview;
  final bool selected, unread;
  final Color? indicatorColor;
  final VoidCallback onTap;
  final int previewLines;
  final int unreadCount;
  final bool isInstagram;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? p.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
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
                                fontWeight: unread
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                fontSize: 14,
                                color: p.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: TextStyle(
                              color: p.textMuted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              preview,
                              maxLines: previewLines,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unread
                                    ? p.textPrimary.withValues(alpha: .75)
                                    : p.textMuted,
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (unread)
                            isInstagram
                                ? Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFEDA75),
                                          Color(0xFFFA7E1E),
                                          Color(0xFFD62976),
                                          Color(0xFF962FBF),
                                          Color(0xFF4F5BD5),
                                        ],
                                      ),
                                    ),
                                  )
                                : Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF25D366),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                        ],
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

// ─────────────────────────────────────────────────────────────
// Frame, toolbar, thread header
// ─────────────────────────────────────────────────────────────

/// Kept for compatibility; the redesigned inbox no longer uses it.
class InboxToolbar extends StatelessWidget {
  const InboxToolbar({
    super.key,
    required this.title,
    required this.loading,
    required this.onRefresh,
    required this.tooltip,
  });
  final String title, tooltip;
  final bool loading;
  final VoidCallback onRefresh;

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
              child: CircularProgressIndicator(strokeWidth: 2, color: p.accent),
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

class InboxFrame extends StatelessWidget {
  const InboxFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 860;
    return Container(
      margin: EdgeInsets.fromLTRB(narrow ? 12 : 24, 4, narrow ? 12 : 24, 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border),
        boxShadow: p.softShadow,
      ),
      child: child,
    );
  }
}

class ThreadHeader extends StatelessWidget {
  const ThreadHeader({
    super.key,
    required this.avatar,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
  });
  final Widget avatar;
  final String title, subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 4)],
          avatar,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(color: p.textMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Thread: date chip + message card
// ─────────────────────────────────────────────────────────────

class DateChip extends StatelessWidget {
  const DateChip(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 18),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: p.chipFill,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: p.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// White rounded message card with sender, time and a "…" menu.
class InboxBubble extends StatelessWidget {
  const InboxBubble({
    super.key,
    required this.outgoing,
    required this.time,
    this.text = '',
    this.body,
    this.sender,
    this.status,
    this.avatar,
    this.outgoingGradient,
    this.outgoingColor,
    this.outgoingText = Colors.white,
    this.outgoingMeta = Colors.white70,
  });

  final bool outgoing;
  final String time;
  final String text;
  final Widget? body;
  final String? sender;
  final String? status;
  final Widget? avatar;
  final Gradient? outgoingGradient;
  final Color? outgoingColor;
  final Color outgoingText;
  final Color outgoingMeta;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final fg = outgoing ? outgoingText : p.textPrimary;
    final meta = outgoing ? outgoingMeta : p.textMuted;
    final canCopy = text.trim().isNotEmpty;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sender != null) ...[
          Text(
            sender!,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: meta,
            ),
          ),
          const SizedBox(height: 5),
        ],
        body ??
            Text(
              text,
              style: TextStyle(color: fg, height: 1.35, fontSize: 14.5),
            ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(time, style: TextStyle(fontSize: 11, color: meta)),
            if (outgoing && status != null) ...[
              const SizedBox(width: 6),
              Text(status!, style: TextStyle(fontSize: 11, color: meta)),
            ],
          ],
        ),
      ],
    );

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: EdgeInsets.fromLTRB(16, 11, canCopy ? 8 : 16, 9),
      decoration: BoxDecoration(
        gradient: outgoing ? outgoingGradient : null,
        color: outgoing
            ? (outgoingGradient == null ? outgoingColor : null)
            : p.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: const Radius.circular(16),
          bottomRight: Radius.circular(outgoing ? 4 : 16),
        ),
        border: outgoing
            ? null
            : Border.all(color: p.border.withValues(alpha: .6)),
        boxShadow: outgoing ? null : p.softShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(child: content),
          if (canCopy) ...[
            const SizedBox(width: 22),
            PopupMenuButton<String>(
              tooltip: 'More',
              padding: EdgeInsets.zero,
              color: p.surface,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.14),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: p.border, width: 1),
              ),
              onSelected: (value) {
                if (value == 'copy') {
                  Clipboard.setData(ClipboardData(text: text));
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'copy',
                  height: 42,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 17, color: p.textPrimary),
                      const SizedBox(width: 10),
                      Text(
                        'Copy text',
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.more_horiz_rounded, size: 18, color: meta),
              ),
            ),
          ],
        ],
      ),
    );

    if (outgoing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Align(alignment: Alignment.centerRight, child: bubble),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (avatar != null) ...[avatar!, const SizedBox(width: 12)],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty / error state
// ─────────────────────────────────────────────────────────────

class InboxEmptyState extends StatelessWidget {
  const InboxEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Color color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted, height: 1.45),
              ),
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Composer
// ─────────────────────────────────────────────────────────────

InputDecoration inboxPillField(AppPalette p, String hint) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    hintText: hint,
    counterText: '',
    filled: true,
    fillColor: p.chipFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
    border: b(Colors.transparent),
    enabledBorder: b(Colors.transparent),
    disabledBorder: b(Colors.transparent),
    focusedBorder: b(p.accent, 1.4),
  );
}

class ComposerBar extends StatelessWidget {
  const ComposerBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: child,
    );
  }
}

class SendButton extends StatelessWidget {
  const SendButton({
    super.key,
    required this.onPressed,
    required this.tooltip,
    this.busy = false,
  });
  final VoidCallback? onPressed;
  final String tooltip;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        disabledBackgroundColor: p.accent.withValues(alpha: .3),
        padding: const EdgeInsets.all(14),
      ),
      icon: busy
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: p.onAccent,
              ),
            )
          : const Icon(Icons.send_rounded),
    );
  }
}
