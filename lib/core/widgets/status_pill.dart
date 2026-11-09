import 'package:flutter/material.dart';
import 'package:raigon_art/core/models/status.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.compact = false});

  final Status status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (textColor, bgColor, borderColor, dotColor) = switch (status) {
      Status.pending =>
        isDark
            ? (
                const Color(0xFFFBBF24),
                const Color(0x33FBBF24),
                const Color(0x66FBBF24),
                const Color(0xFFFBBF24),
              )
            : (
                const Color(0xFF92400E),
                const Color(0xFFFEF3C7),
                const Color(0xFFFDE68A),
                const Color(0xFFD97706),
              ),
      Status.confirmed =>
        isDark
            ? (
                const Color(0xFF60A5FA),
                const Color(0x333B82F6),
                const Color(0x663B82F6),
                const Color(0xFF60A5FA),
              )
            : (
                const Color(0xFF1E40AF),
                const Color(0xFFDBEAFE),
                const Color(0xFFBFDBFE),
                const Color(0xFF2563EB),
              ),
      Status.onHold =>
        isDark
            ? (
                const Color(0xFFFB923C),
                const Color(0x33EA580C),
                const Color(0x66EA580C),
                const Color(0xFFFB923C),
              )
            : (
                const Color(0xFF9A3412),
                const Color(0xFFFFEDD5),
                const Color(0xFFFED7AA),
                const Color(0xFFEA580C),
              ),
      Status.cancelled =>
        isDark
            ? (
                const Color(0xFFF87171),
                const Color(0x33F87171),
                const Color(0x66F87171),
                const Color(0xFFF87171),
              )
            : (
                const Color(0xFF7F1D1D),
                const Color(0xFFFEE2E2),
                const Color(0xFFFCA5A5),
                const Color(0xFFDC2626),
              ),
      Status.editingProgress =>
        isDark
            ? (
                const Color(0xFFA78BFA),
                const Color(0x337C3AED),
                const Color(0x667C3AED),
                const Color(0xFFA78BFA),
              )
            : (
                const Color(0xFF5B21B6),
                const Color(0xFFEDE9FE),
                const Color(0xFFDDD6FE),
                const Color(0xFF7C3AED),
              ),
      Status.dispatchForPrinting =>
        isDark
            ? (
                const Color(0xFF2DD4BF),
                const Color(0x330D9488),
                const Color(0x660D9488),
                const Color(0xFF2DD4BF),
              )
            : (
                const Color(0xFF115E59),
                const Color(0xFFCCFBF1),
                const Color(0xFF99F6E4),
                const Color(0xFF0D9488),
              ),
      Status.printReceived =>
        isDark
            ? (
                const Color(0xFF38BDF8),
                const Color(0x330284C7),
                const Color(0x660284C7),
                const Color(0xFF38BDF8),
              )
            : (
                const Color(0xFF075985),
                const Color(0xFFE0F2FE),
                const Color(0xFFBAE6FD),
                const Color(0xFF0284C7),
              ),
      Status.framingProcess =>
        isDark
            ? (
                const Color(0xFFFDE047),
                const Color(0x33D97706),
                const Color(0x66D97706),
                const Color(0xFFFDE047),
              )
            : (
                const Color(0xFF78350F),
                const Color(0xFFFEF9C3),
                const Color(0xFFFDE047),
                const Color(0xFFB45309),
              ),
      Status.completed =>
        isDark
            ? (
                const Color(0xFF4ADE80),
                const Color(0x334ADE80),
                const Color(0x664ADE80),
                const Color(0xFF4ADE80),
              )
            : (
                const Color(0xFF14532D),
                const Color(0xFFDCFCE7),
                const Color(0xFF86EFAC),
                const Color(0xFF16A34A),
              ),
      Status.inProgress =>
        isDark
            ? (
                const Color(0xFFFDE047),
                const Color(0x33FDE047),
                const Color(0x66FDE047),
                const Color(0xFFFDE047),
              )
            : (
                const Color(0xFF78350F),
                const Color(0xFFFEF9C3),
                const Color(0xFFFDE047),
                const Color(0xFFB45309),
              ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5.5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 7.5,
            height: compact ? 6 : 7.5,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5.5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: compact ? 11 : 12.5,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
