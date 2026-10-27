import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:raigon_art/core/widgets/customer_dialog_kit.dart';
import 'package:raigon_art/core/widgets/form_kit.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';

/// Shows a standardized, compact confirmation dialog.
Future<bool> showAppConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  IconData icon = RemixIcons.error_warning_line,
  Color iconColor = const Color(0xFFE05C58),
  Color? iconBg,
  Color confirmColor = const Color(0xFFE05C58),
  bool isDestructive = true,
}) async {
  final result = await showCustomerDialog<bool>(
    context,
    label: title,
    builder: (ctx) => AppConfirmationDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
      iconColor: iconColor,
      iconBg: iconBg ?? iconColor.withValues(alpha: 0.12),
      confirmColor: confirmColor,
      isDestructive: isDestructive,
    ),
  );
  return result ?? false;
}

/// Confirmation dialog for user logout with short standard text.
Future<bool> showLogoutConfirmationDialog(BuildContext context) {
  return showAppConfirmationDialog(
    context,
    title: 'Log Out',
    message: 'Are you sure you want to log out?',
    confirmLabel: 'Log Out',
    cancelLabel: 'Cancel',
    icon: RemixIcons.logout_box_r_line,
  );
}

/// Confirmation dialog for deleting a customer with short standard text.
Future<bool> showDeleteCustomerConfirmationDialog(
  BuildContext context,
  Customer customer,
) {
  return showAppConfirmationDialog(
    context,
    title: 'Delete Customer',
    message: 'Are you sure you want to delete ${customer.name}?',
    confirmLabel: 'Delete',
    cancelLabel: 'Cancel',
    icon: RemixIcons.delete_bin_line,
  );
}

/// Confirmation dialog for deleting an order with short standard text.
Future<bool> showDeleteOrderConfirmationDialog(
  BuildContext context,
  Customer order,
) {
  return showAppConfirmationDialog(
    context,
    title: 'Delete Order',
    message: 'Are you sure you want to delete order #${order.id}?',
    confirmLabel: 'Delete',
    cancelLabel: 'Cancel',
    icon: RemixIcons.delete_bin_line,
  );
}

/// Reusable compact confirmation dialog widget.
class AppConfirmationDialog extends StatelessWidget {
  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.confirmColor,
    required this.isDestructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color confirmColor;
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
                      child: Icon(RemixIcons.close_line, size: 17, color: p.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: p.border),
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
            Container(
              color: c.footerBg,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(false),
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
                  InkWell(
                    onTap: () => Navigator.of(context).pop(true),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: confirmColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: confirmColor.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        confirmLabel,
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
