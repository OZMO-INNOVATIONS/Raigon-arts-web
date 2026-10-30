import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/provider/customer_and_order_provider.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/features/authentication/services/auth_service.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/reminders/models/reminder_model.dart';
import 'package:raigon_art/features/reminders/providers/reminder_provider.dart';

Future<void> showAddOrEditReminderDialog({
  required BuildContext context,
  Customer? initialCustomer,
  CustomerReminder? existingReminder,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AddOrEditReminderDialog(
      initialCustomer: initialCustomer,
      existingReminder: existingReminder,
    ),
  );
}

class AddOrEditReminderDialog extends StatefulWidget {
  const AddOrEditReminderDialog({
    super.key,
    this.initialCustomer,
    this.existingReminder,
  });

  final Customer? initialCustomer;
  final CustomerReminder? existingReminder;

  @override
  State<AddOrEditReminderDialog> createState() => _AddOrEditReminderDialogState();
}

class _AddOrEditReminderDialogState extends State<AddOrEditReminderDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _customerNameCtrl;
  late TextEditingController _customerIdCtrl;
  late TextEditingController _orderIdCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _regionCtrl;
  late TextEditingController _descCtrl;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late ReminderPriority _priority;
  late String _assignedStaff;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final rem = widget.existingReminder;
    final cust = widget.initialCustomer;

    _titleCtrl = TextEditingController(
      text: rem?.title ??
          (cust != null ? 'Follow up with ${cust.name}' : 'Customer Contact Reminder'),
    );
    _customerNameCtrl = TextEditingController(
      text: rem?.customerName ?? cust?.name ?? '',
    );
    _customerIdCtrl = TextEditingController(
      text: rem?.customerId ?? cust?.id ?? '',
    );
    _orderIdCtrl = TextEditingController(
      text: rem?.orderId ?? (cust != null ? '#${cust.id}' : ''),
    );
    _phoneCtrl = TextEditingController(
      text: rem?.phone ?? cust?.phone ?? '',
    );
    _regionCtrl = TextEditingController(
      text: rem?.region ?? cust?.effectiveRegion ?? '',
    );
    _descCtrl = TextEditingController(
      text: rem?.description ?? '',
    );

    _selectedDate = rem?.reminderDate ?? DateTime.now().add(const Duration(days: 1));
    _selectedTime = const TimeOfDay(hour: 10, minute: 0);
    _priority = rem?.priority ?? ReminderPriority.medium;
    _assignedStaff = rem?.assignedStaff ?? (AuthService.isAdmin ? 'Admin' : 'Workshop Staff');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _customerNameCtrl.dispose();
    _customerIdCtrl.dispose();
    _orderIdCtrl.dispose();
    _phoneCtrl.dispose();
    _regionCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        final p = AppPalette.of(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: AppColors.black,
              surface: p.surface,
              onSurface: p.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        final p = AppPalette.of(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: AppColors.black,
              surface: p.surface,
              onSurface: p.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _onCustomerSelected(Customer c) {
    setState(() {
      _customerNameCtrl.text = c.name;
      _customerIdCtrl.text = c.id;
      _orderIdCtrl.text = '#${c.id}';
      _phoneCtrl.text = c.phone;
      _regionCtrl.text = c.effectiveRegion;
      if (_titleCtrl.text.isEmpty || _titleCtrl.text == 'Customer Contact Reminder') {
        _titleCtrl.text = 'Follow up with ${c.name}';
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<ReminderProvider>();
    final isEdit = widget.existingReminder != null;
    final timeStr = _selectedTime.format(context);

    try {
      if (isEdit) {
        final updated = widget.existingReminder!.copyWith(
          title: _titleCtrl.text.trim(),
          customerName: _customerNameCtrl.text.trim(),
          customerId: _customerIdCtrl.text.trim(),
          orderId: _orderIdCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          reminderDate: _selectedDate,
          reminderTime: timeStr,
          assignedStaff: _assignedStaff,
          priority: _priority,
          phone: _phoneCtrl.text.trim(),
          region: _regionCtrl.text.trim(),
        );
        await provider.updateReminder(updated);
        if (mounted) {
          Navigator.of(context).pop();
          AppSnackBar.success(context, 'Reminder updated successfully.');
        }
      } else {
        await provider.createReminder(
          title: _titleCtrl.text.trim(),
          customerName: _customerNameCtrl.text.trim(),
          customerId: _customerIdCtrl.text.trim(),
          orderId: _orderIdCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          reminderDate: _selectedDate,
          reminderTime: timeStr,
          assignedStaff: _assignedStaff,
          priority: _priority,
          createdBy: AuthService.isAdmin ? 'Admin' : 'Workshop Staff',
          phone: _phoneCtrl.text.trim(),
          region: _regionCtrl.text.trim(),
        );
        if (mounted) {
          Navigator.of(context).pop();
          AppSnackBar.success(context, 'Reminder scheduled for ${_customerNameCtrl.text.trim()}.');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to save reminder: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final customers = context.watch<CustomerAndOrderProvider>().customers;
    final isEdit = widget.existingReminder != null;

    final dateFormatted =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    final timeFormatted = _selectedTime.format(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: p.border.withValues(alpha: 0.9),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: p.isDark ? 0.45 : 0.15),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: p.goldAccentGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.alarm_add_rounded,
                        color: AppColors.black,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Edit Reminder' : 'Create New Reminder',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: p.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Schedule a date-based contact or follow-up notice',
                            style: TextStyle(
                              fontSize: 12,
                              color: p.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: p.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Customer selection helper dropdown
                if (!isEdit && customers.isNotEmpty) ...[
                  Text(
                    'SELECT EXISTING CUSTOMER (OPTIONAL)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: p.isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: p.isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Customer>(
                        isExpanded: true,
                        hint: Text(
                          'Choose customer from list...',
                          style: TextStyle(fontSize: 13.5, color: p.textMuted),
                        ),
                        dropdownColor: p.surface,
                        items: [
                          for (final c in customers.take(25))
                            DropdownMenuItem(
                              value: c,
                              child: Text(
                                '${c.name} (#${c.id}) • ${c.phone}',
                                style: TextStyle(fontSize: 13.5, color: p.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (c) {
                          if (c != null) _onCustomerSelected(c);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Reminder Title
                _buildLabel(p, 'REMINDER TITLE *'),
                TextFormField(
                  controller: _titleCtrl,
                  style: TextStyle(color: p.textPrimary, fontSize: 14),
                  decoration: _buildInputDec(p, 'e.g. Call regarding wooden frame delivery'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 14),

                // Customer Name & Customer ID Row
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(p, 'CUSTOMER NAME *'),
                          TextFormField(
                            controller: _customerNameCtrl,
                            style: TextStyle(color: p.textPrimary, fontSize: 14),
                            decoration: _buildInputDec(p, 'Full name'),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(p, 'CUSTOMER ID'),
                          TextFormField(
                            controller: _customerIdCtrl,
                            style: TextStyle(color: p.textPrimary, fontSize: 14),
                            decoration: _buildInputDec(p, 'e.g. RA-1002'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Phone & Region Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(p, 'PHONE NUMBER'),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(color: p.textPrimary, fontSize: 14),
                            decoration: _buildInputDec(p, '+91 9876543210'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(p, 'REGION / CITY'),
                          TextFormField(
                            controller: _regionCtrl,
                            style: TextStyle(color: p.textPrimary, fontSize: 14),
                            decoration: _buildInputDec(p, 'e.g. Kochi / Ernakulam'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date & Time Picker Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(p, 'REMINDER DATE *'),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                              decoration: BoxDecoration(
                                color: p.isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: p.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.gold),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      dateFormatted,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: p.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(p, 'TIME'),
                          InkWell(
                            onTap: _pickTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                              decoration: BoxDecoration(
                                color: p.isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: p.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 18, color: AppColors.gold),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      timeFormatted,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: p.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Quick Date Preset Chips
                Wrap(
                  spacing: 6,
                  children: [
                    _buildQuickChip('Today', DateTime.now()),
                    _buildQuickChip('Tomorrow', DateTime.now().add(const Duration(days: 1))),
                    _buildQuickChip('In 3 Days', DateTime.now().add(const Duration(days: 3))),
                    _buildQuickChip('In 1 Week', DateTime.now().add(const Duration(days: 7))),
                  ],
                ),
                const SizedBox(height: 16),

                // Priority & Assigned Staff Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(p, 'PRIORITY'),
                          Row(
                            children: [
                              for (final prio in ReminderPriority.values)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: InkWell(
                                      onTap: () => setState(() => _priority = prio),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _priority == prio
                                              ? prio.color.withValues(alpha: 0.2)
                                              : (p.isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6)),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _priority == prio ? prio.color : p.border,
                                            width: _priority == prio ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: Text(
                                          prio.label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _priority == prio ? prio.color : p.textMuted,
                                          ),
                                        ),
                                      ),
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
                const SizedBox(height: 16),

                // Notes / Description
                _buildLabel(p, 'DESCRIPTION / NOTES'),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  style: TextStyle(color: p.textPrimary, fontSize: 13.5),
                  decoration: _buildInputDec(
                    p,
                    'Add any notes or context for staff follow-up...',
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: p.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                                ),
                              )
                            : Text(
                                isEdit ? 'Save Changes' : 'Schedule Reminder',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, DateTime targetDate) {
    final isSelected = DateUtils.isSameDay(_selectedDate, targetDate);
    final p = AppPalette.of(context);
    return InkWell(
      onTap: () => setState(() => _selectedDate = targetDate),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.2)
              : (p.isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.gold : p.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(AppPalette p, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
          color: p.isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
        ),
      ),
    );
  }

  InputDecoration _buildInputDec(AppPalette p, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: p.textMuted, fontSize: 13),
      filled: true,
      fillColor: p.isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.statusRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.statusRed, width: 1.5),
      ),
    );
  }
}
