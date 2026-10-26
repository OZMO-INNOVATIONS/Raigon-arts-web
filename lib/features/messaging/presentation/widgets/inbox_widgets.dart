import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';

/// 12-hour clock label used by both inbox tabs.
String formatInboxTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

// ─────────────────────────────────────────────────────────────
// Avatar
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
                      color: Colors.white,
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
                return _fallback(t);
              },
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

// ─────────────────────────────────────────────────────────────
// Conversation list
// ─────────────────────────────────────────────────────────────

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.avatar,
    required this.name,
    required this.time,
    required this.preview,
    required this.selected,
    required this.wide,
    required this.onTap,
    this.previewLines = 1,
  });

  final Widget avatar;
  final String name, time, preview;
  final bool selected, wide;
  final VoidCallback onTap;
  final int previewLines;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      width: wide ? null : 240,
      margin: EdgeInsets.only(bottom: wide ? 6 : 0, right: wide ? 0 : 8),
      child: Material(
        color: selected ? p.accentSoft : Colors.transparent,
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
                    ? p.accent.withValues(alpha: .6)
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
                        style: TextStyle(
                          color: p.textMuted,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
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
    this.trailing,
  });
  final Widget avatar;
  final String title, subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 12),
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
                    fontSize: 15,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: p.textMuted, fontSize: 12),
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
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
