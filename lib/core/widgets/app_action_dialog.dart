import 'package:flutter/material.dart';
import 'package:raigon_art/core/widgets/customer_dialog_kit.dart';
import 'package:raigon_art/core/widgets/form_kit.dart';
import 'package:remixicon/remixicon.dart';

class AppActionDialog extends StatelessWidget {
  const AppActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.actionLabel,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.actionColor,
    this.onCancel,
    this.onAction,
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String cancelLabel;
  final String actionLabel;

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color actionColor;

  final VoidCallback? onCancel;
  final VoidCallback? onAction;

  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final c = FormColors.of(context);
    final p = c.p;

    return DialogBackdrop(
      maxWidth: 400,
      child: Material(
        color: c.modalBg,
        elevation: 20,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 19, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(false),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.chipFill,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        RemixIcons.close_line,
                        size: 17,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: p.border),

            // Message
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.4,
                  color: p.textPrimary,
                ),
              ),
            ),

            // Actions
            Container(
              color: c.footerBg,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel button
                  InkWell(
                    onTap: onCancel ?? () => Navigator.of(context).pop(false),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: p.isDark ? p.chipFill : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: p.border),
                      ),
                      child: Text(
                        cancelLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Action button
                  InkWell(
                    onTap: onAction,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: actionColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: actionColor.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        actionLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
