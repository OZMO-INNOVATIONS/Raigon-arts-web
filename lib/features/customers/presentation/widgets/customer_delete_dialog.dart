import 'package:flutter/material.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/core/widgets/customer_dialog_kit.dart';
import 'package:raigon_art/core/widgets/form_kit.dart';

Future<bool> showDeleteCustomerDialog(
  BuildContext context,
  Customer customer,
) async {
  final result = await showCustomerDialog<bool>(
    context,
    label: 'Delete customer',
    builder: (_) => DeleteCustomerDialog(customer: customer),
  );
  return result ?? false;
}

class DeleteCustomerDialog extends StatelessWidget {
  const DeleteCustomerDialog({super.key, required this.customer});

  final Customer customer;

  static const _red = Color(0xFFE05C58);

  @override
  Widget build(BuildContext context) {
    final c = FormColors.of(context);
    final p = c.p;
    return DialogBackdrop(
      maxWidth: 440,
      child: Material(
        color: c.modalBg,
        elevation: 24,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Delete Customer Record',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(false),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: p.chipFill,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 20, color: p.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: p.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Text(
                'Are you sure you want to delete customer '
                '"${customer.name}" (${customer.id})? '
                'This action cannot be undone.',
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.45,
                  color: p.textPrimary,
                ),
              ),
            ),
            Container(
              color: c.footerBg,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(false),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      decoration: p.isDark
                          ? BoxDecoration(
                              color: p.chipFill,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: p.border),
                            )
                          : null,
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(true),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Delete Customer',
                        style: TextStyle(
                          fontSize: 15.5,
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
