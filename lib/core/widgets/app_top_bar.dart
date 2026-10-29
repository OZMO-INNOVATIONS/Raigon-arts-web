import 'package:flutter/material.dart';
import 'package:raigon_art/core/widgets/shell_scope.dart';
import 'package:remixicon/remixicon.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/mx_theme.dart';
import 'package:raigon_art/core/theme/theme_controller.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.notificationCount,
    required this.onBellTap,
  });

  final int notificationCount;
  final VoidCallback onBellTap;

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _greeting(int hour) {
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
  }

  String _dateLine(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final now = DateTime.now();

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: p.card(radius: 18),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 760;

          return Row(
            children: [
              // ── Greeting ──
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting(now.hour)} Raigon 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.15,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _dateLine(now),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // ── Theme switch ──
              _ThemeSwitch(showLabels: !compact),
              const SizedBox(width: 12),

              // ── Notifications ──
              _BellButton(count: notificationCount, onTap: onBellTap),

              const SizedBox(width: 16),
              Container(width: 1, height: 28, color: p.border),
              const SizedBox(width: 16),

              // ── Profile ──
              _ProfileChip(compact: compact),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Light / Dark segmented switch
// ─────────────────────────────────────────────────────────────

class _ThemeSwitch extends StatelessWidget {
  const _ThemeSwitch({required this.showLabels});
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.chipFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeOption(
            icon: RemixIcons.sun_line,
            label: 'Light',
            showLabel: showLabels,
            selected: !p.isDark,
            onTap: () => ThemeController.mode.value = ThemeMode.light,
          ),
          _ThemeOption(
            icon: RemixIcons.moon_line,
            label: 'Dark',
            showLabel: showLabels,
            selected: p.isDark,
            onTap: () => ThemeController.mode.value = ThemeMode.dark,
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.showLabel,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool showLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final fg = selected ? p.onBrand : p.textMuted;

    return Tooltip(
      message: '$label mode',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: selected ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 34,
            padding: EdgeInsets.symmetric(horizontal: showLabel ? 14 : 11),
            decoration: BoxDecoration(
              gradient: selected ? p.brand : null,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: fg),
                if (showLabel) ...[
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bell with count badge
// ─────────────────────────────────────────────────────────────

class _BellButton extends StatefulWidget {
  const _BellButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  State<_BellButton> createState() => _BellButtonState();
}

class _BellButtonState extends State<_BellButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Tooltip(
      message: 'Notifications',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hover ? p.chipFill : p.surface,
                    border: Border.all(
                      color: _hover ? p.accent.withValues(alpha: .5) : p.border,
                    ),
                  ),
                  child: Icon(
                    RemixIcons.notification_3_line,
                    size: 20,
                    color: p.textPrimary,
                  ),
                ),
                if (widget.count > 0)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: IgnorePointer(
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 19,
                          minHeight: 19,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5484D),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: p.surface, width: 2),
                        ),
                        child: Text(
                          widget.count > 99 ? '99+' : '${widget.count}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
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
// Profile pill
// ─────────────────────────────────────────────────────────────

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Tooltip(
      message: 'Business Profile',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            ShellScope.of(context).goTo(NavDestination.profile);
          },
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.avatarBg,
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: const Text(
              'RA',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
