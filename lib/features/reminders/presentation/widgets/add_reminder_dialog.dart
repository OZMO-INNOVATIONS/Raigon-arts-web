import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/provider/customer_and_order_provider.dart';
import 'package:raigon_art/core/services/storage_service.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/app_action_dialog.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/features/authentication/services/auth_service.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/customers/presentation/widgets/order_voice_notes_section.dart';
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
  State<AddOrEditReminderDialog> createState() =>
      _AddOrEditReminderDialogState();
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
  List<OrderVoiceNote> _voiceNotes = [];

  @override
  void initState() {
    super.initState();
    final rem = widget.existingReminder;
    final cust = widget.initialCustomer;

    _titleCtrl = TextEditingController(
      text:
          rem?.title ??
          (cust != null
              ? 'Follow up with ${cust.name}'
              : 'Customer Contact Reminder'),
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
    _phoneCtrl = TextEditingController(text: rem?.phone ?? cust?.phone ?? '');
    _regionCtrl = TextEditingController(
      text: rem?.region ?? cust?.effectiveRegion ?? '',
    );
    _descCtrl = TextEditingController(text: rem?.description ?? '');

    _selectedDate =
        rem?.reminderDate ?? DateTime.now().add(const Duration(days: 1));
    _selectedTime = const TimeOfDay(hour: 10, minute: 0);
    _priority = rem?.priority ?? ReminderPriority.medium;
    _assignedStaff =
        rem?.assignedStaff ??
        (AuthService.isAdmin ? 'Admin' : 'Workshop Staff');

    _voiceNotes = rem != null
        ? List<OrderVoiceNote>.of(rem.effectiveVoiceNotes)
        : [];
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
      if (_titleCtrl.text.isEmpty ||
          _titleCtrl.text == 'Customer Contact Reminder') {
        _titleCtrl.text = 'Follow up with ${c.name}';
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.existingReminder != null;
    final customerName = _customerNameCtrl.text.trim();
    final timeStr = _selectedTime.format(context);

    // Show confirmation before saving.
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AppActionDialog(
          title: isEdit ? 'Confirm Changes' : 'Schedule Reminder?',
          message: isEdit
              ? 'Do you want to save the changes made to the reminder for $customerName?'
              : 'Are you sure you want to schedule a reminder for $customerName?',
          cancelLabel: 'Cancel',
          actionLabel: 'Save',
          icon: Icons.event_available_rounded,
          iconColor: AppColors.gold,
          iconBg: AppColors.gold.withValues(alpha: 0.12),
          actionColor: AppColors.gold,
          isDestructive: false,
          onCancel: () => Navigator.pop(dialogContext, false),
          onAction: () => Navigator.pop(dialogContext, true),
        );
      },
    );

    // Cancel: remain in the form with entered details.
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);

    try {
      final provider = context.read<ReminderProvider>();

      // Upload local voice notes.
      final updatedVoiceNotes = <OrderVoiceNote>[];

      for (var i = 0; i < _voiceNotes.length; i++) {
        final vn = _voiceNotes[i];

        if (vn.url.isEmpty &&
            vn.localBytes != null &&
            vn.localBytes!.isNotEmpty) {
          try {
            final fileName =
                'voice_rem_${DateTime.now().millisecondsSinceEpoch}_${i + 1}.m4a';

            final uploaded = await StorageService().uploadFile(
              vn.localBytes!,
              fileName,
            );

            if (uploaded.fileUrl.isNotEmpty) {
              updatedVoiceNotes.add(vn.copyWith(url: uploaded.fileUrl));
              continue;
            }
          } catch (e) {
            debugPrint(
              '[AddReminder] Storage voice upload notice: $e (stored locally)',
            );
          }
        }

        updatedVoiceNotes.add(vn);
      }

      final primaryUrl = updatedVoiceNotes.isNotEmpty
          ? updatedVoiceNotes.first.url
          : '';

      final primaryDuration = updatedVoiceNotes.isNotEmpty
          ? updatedVoiceNotes.first.durationSeconds
          : 0;

      if (isEdit) {
        final updated = widget.existingReminder!.copyWith(
          title: _titleCtrl.text.trim(),
          customerName: customerName,
          customerId: _customerIdCtrl.text.trim(),
          orderId: _orderIdCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          reminderDate: _selectedDate,
          reminderTime: timeStr,
          assignedStaff: _assignedStaff,
          priority: _priority,
          phone: _phoneCtrl.text.trim(),
          region: _regionCtrl.text.trim(),
          voiceUrl: primaryUrl,
          voiceDurationSeconds: primaryDuration,
          voiceNotes: updatedVoiceNotes,
        );

        await provider.updateReminder(updated);
      } else {
        await provider.createReminder(
          title: _titleCtrl.text.trim(),
          customerName: customerName,
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
          voiceUrl: primaryUrl,
          voiceDurationSeconds: primaryDuration,
          voiceNotes: updatedVoiceNotes,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop();

      AppSnackBar.success(
        context,
        isEdit
            ? 'Reminder updated successfully.'
            : 'Reminder scheduled for $customerName.',
      );
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.alarm_add_rounded,
                        color: AppColors.gold,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit
                                ? 'Edit Follow-up Reminder'
                                : 'Schedule Customer Reminder',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: p.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Text and voice reminders with automated alerts',
                            style: TextStyle(fontSize: 12, color: p.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: p.textMuted,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(height: 1, color: p.border),
                const SizedBox(height: 18),

                // Link to Existing Customer (Quick Fill)
                if (!isEdit && customers.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel(p, 'LINK TO CUSTOMER (OPTIONAL)'),
                      if (_customerIdCtrl.text.isNotEmpty)
                        Text(
                          'Linked: ${_customerIdCtrl.text}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: p.chipFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Customer>(
                        isExpanded: true,
                        hint: Text(
                          _customerIdCtrl.text.isNotEmpty
                              ? 'Customer: ${_customerNameCtrl.text}'
                              : 'Select a customer to auto-fill details...',
                          style: TextStyle(color: p.textMuted, fontSize: 13),
                        ),
                        items: [
                          for (final c in customers)
                            DropdownMenuItem(
                              value: c,
                              child: Text(
                                '${c.name} (${c.id}) • ${c.phone}',
                                style: TextStyle(
                                  color: p.textPrimary,
                                  fontSize: 13,
                                ),
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
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Reminder title is required'
                      : null,
                  style: TextStyle(color: p.textPrimary, fontSize: 14),
                  decoration: _buildInputDec(
                    p,
                    'e.g. Frame Preview Verification / Balance Collection',
                    prefixIcon: const Icon(Icons.title_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 16),

                // Customer Name & Phone
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(p, 'CUSTOMER NAME *'),
                          TextFormField(
                            controller: _customerNameCtrl,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Customer name is required'
                                : null,
                            style: TextStyle(
                              color: p.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: _buildInputDec(
                              p,
                              'e.g. Priya Sharma',
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(p, 'PHONE NUMBER'),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              color: p.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: _buildInputDec(
                              p,
                              '9998887776',
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date & Time Pickers
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(p, 'REMINDER DATE *'),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: p.chipFill,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: p.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    size: 18,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    dateFormatted,
                                    style: TextStyle(
                                      color: p.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
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
                          _buildLabel(p, 'REMINDER TIME *'),
                          InkWell(
                            onTap: _pickTime,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: p.chipFill,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: p.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 18,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    timeFormatted,
                                    style: TextStyle(
                                      color: p.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
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
                const SizedBox(height: 16),

                // Priority & Assigned Staff
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(p, 'PRIORITY LEVEL'),
                          Row(
                            children: [
                              for (final prio in ReminderPriority.values)
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: prio != ReminderPriority.high
                                          ? 6
                                          : 0,
                                    ),
                                    child: InkWell(
                                      onTap: () =>
                                          setState(() => _priority = prio),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        height: 38,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _priority == prio
                                              ? prio.color.withValues(
                                                  alpha: 0.18,
                                                )
                                              : p.chipFill,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: _priority == prio
                                                ? prio.color
                                                : p.border,
                                            width: _priority == prio ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Text(
                                          prio.label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _priority == prio
                                                ? prio.color
                                                : p.textMuted,
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
                _buildLabel(p, 'TEXT REMINDER / NOTES'),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  style: TextStyle(color: p.textPrimary, fontSize: 13.5),
                  decoration: _buildInputDec(
                    p,
                    'Add specific instructions or context for staff follow-up...',
                  ),
                ),
                const SizedBox(height: 16),

                // VOICE REMINDER (AUDIO MESSAGES)
                OrderVoiceNotesSection(
                  voiceNotes: _voiceNotes,
                  onChanged: (notes) {
                    setState(() => _voiceNotes = notes);
                  },
                  isEditable: true,
                  title: 'Voice Reminders (Audio Instructions)',
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: p.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.black,
                                  ),
                                ),
                              )
                            : Text(
                                isEdit ? 'Save Changes' : 'Schedule Reminder',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                ),
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

  Widget _buildLabel(AppPalette p, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: p.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  InputDecoration _buildInputDec(
    AppPalette p,
    String hint, {
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: p.textMuted.withValues(alpha: 0.6),
        fontSize: 13,
      ),
      prefixIcon: prefixIcon != null
          ? IconTheme(
              data: IconThemeData(color: p.textMuted, size: 18),
              child: prefixIcon,
            )
          : null,
      filled: true,
      fillColor: p.chipFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
    );
  }
}
