import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/core/widgets/app_confirmation_dialog.dart';

Future<bool> showDeleteCustomerDialog(
  BuildContext context,
  Customer customer,
) {
  return showDeleteCustomerConfirmationDialog(context, customer);
}

class DeleteCustomerDialog extends StatelessWidget {
  const DeleteCustomerDialog({super.key, required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return AppConfirmationDialog(
      title: 'Delete Customer',
      message: 'Are you sure you want to delete ${customer.name}?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      icon: RemixIcons.delete_bin_line,
      iconColor: const Color(0xFFE05C58),
      iconBg: const Color(0xFFE05C58).withValues(alpha: 0.12),
      confirmColor: const Color(0xFFE05C58),
      isDestructive: true,
    );
  }
}
