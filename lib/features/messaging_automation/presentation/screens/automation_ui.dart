import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/providers/messaging_automation_provider.dart';

class AutoInk {
  static Color text(BuildContext c) => AppPalette.of(c).textPrimary;
  static Color muted(BuildContext c) => AppPalette.of(c).textMuted;
  static Color panel(BuildContext c) =>
      Theme.of(c).colorScheme.onSurface.withValues(alpha: 0.05);
  static Color line(BuildContext c) =>
      Theme.of(c).colorScheme.onSurface.withValues(alpha: 0.12);
  static Color card(BuildContext c) => Theme.of(c).colorScheme.surface;

  static const blue = Color(0xFF0866FF);
  static const purple = Color(0xFF6C47FF);
  static const whatsapp = Color(0xFF25D366);
  static const lavender = Color(0xFFF1EDFB);
  static const instagram = [
    Color(0xFFF58529),
    Color(0xFFDD2A7B),
    Color(0xFF8134AF),
  ];
}

class AutoPanel extends StatelessWidget {
  const AutoPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: AutoInk.panel(context),
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

class AutoCard extends StatelessWidget {
  const AutoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AutoInk.card(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AutoInk.line(context)),
    ),
    child: child,
  );
}

class AutoButton extends StatelessWidget {
  const AutoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AutoInk.text(context);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: 18),
        if (loading || icon != null) const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    final btn = filled
        ? FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AutoInk.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: shape,
            ),
            onPressed: loading ? null : onPressed,
            child: content,
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: fg,
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              side: BorderSide(color: AutoInk.line(context)),
              shape: shape,
            ),
            onPressed: loading ? null : onPressed,
            child: content,
          );
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class ChannelIcon extends StatelessWidget {
  const ChannelIcon(this.channel, {super.key, this.size = 44});
  final AutomationChannel channel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ig = channel == AutomationChannel.instagram;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        color: ig ? null : AutoInk.whatsapp,
        gradient: ig
            ? const LinearGradient(
                colors: AutoInk.instagram,
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              )
            : null,
      ),
      child: Icon(
        ig ? Icons.camera_alt_outlined : Icons.chat_rounded,
        color: Colors.white,
        size: size * 0.55,
      ),
    );
  }
}

class AutoChip extends StatelessWidget {
  const AutoChip(this.label, {super.key, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AutoInk.blue.withValues(alpha: 0.08),
        border: Border.all(color: AutoInk.blue.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AutoInk.blue, fontSize: 13),
      ),
    ),
  );
}
