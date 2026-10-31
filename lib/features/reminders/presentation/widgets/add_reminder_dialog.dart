import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/provider/customer_and_order_provider.dart';
import 'package:raigon_art/core/services/storage_service.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/features/authentication/services/auth_service.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/reminders/models/reminder_model.dart';
import 'package:raigon_art/features/reminders/providers/reminder_provider.dart';
import 'package:raigon_art/features/reminders/services/reminder_audio_service.dart';

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

  final ReminderAudioService _audioService = ReminderAudioService();
  String _voiceUrl = '';
  int _voiceDurationSeconds = 0;
  Uint8List? _voiceBytes;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  bool _isPlaying = false;
  StreamSubscription? _recSub;
  StreamSubscription? _playerSub;

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

    _voiceUrl = rem?.voiceUrl ?? '';
    _voiceDurationSeconds = rem?.voiceDurationSeconds ?? 0;
    _voiceBytes = rem?.voiceBytes;

    _recSub = _audioService.onRecordSecondsChanged.listen((sec) {
      if (mounted) setState(() => _recordingSeconds = sec);
    });

    _playerSub = _audioService.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _recSub?.cancel();
    _playerSub?.cancel();
    _audioService.dispose();
    _titleCtrl.dispose();
    _customerNameCtrl.dispose();
    _customerIdCtrl.dispose();
    _orderIdCtrl.dispose();
    _phoneCtrl.dispose();
    _regionCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final ok = await _audioService.startRecording();
    if (ok) {
      setState(() => _isRecording = true);
    } else {
      if (mounted) {
        AppSnackBar.error(context, 'Microphone permission denied or recording unavailable.');
      }
    }
  }

  Future<void> _stopRecording() async {
    final result = await _audioService.stopRecording();
    setState(() {
      _isRecording = false;
      if (result != null) {
        _voiceBytes = result.bytes;
        _voiceDurationSeconds = result.durationSeconds;
        _voiceUrl = '';
      }
    });
  }

  Future<void> _cancelRecording() async {
    await _audioService.cancelRecording();
    setState(() => _isRecording = false);
  }

  Future<void> _pickAudioFile() async {
    try {
      final res = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'webm'],
      );
      if (res.isNotEmpty) {
        final bytes = await res.first.readAsBytes();
        setState(() {
          _voiceBytes = bytes;
          _voiceDurationSeconds = 10;
          _voiceUrl = '';
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to pick audio file: $e');
      }
    }
  }

  Future<void> _toggleAudioPlayback() async {
    if (_isPlaying) {
      await _audioService.pause();
    } else {
      if (_voiceBytes != null && _voiceBytes!.isNotEmpty) {
        await _audioService.playBytes(_voiceBytes!);
      } else if (_voiceUrl.isNotEmpty) {
        await _audioService.playUrl(_voiceUrl);
      }
    }
  }

  void _clearVoice() {
    _audioService.stop();
    setState(() {
      _voiceBytes = null;
      _voiceUrl = '';
      _voiceDurationSeconds = 0;
    });
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

    // If audio bytes are present but not yet uploaded, upload to storage
    if (_voiceBytes != null && _voiceBytes!.isNotEmpty && _voiceUrl.isEmpty) {
      try {
        final fileName = 'voice_rem_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final uploaded = await StorageService().uploadFile(_voiceBytes!, fileName);
        if (uploaded.fileUrl.isNotEmpty) {
          _voiceUrl = uploaded.fileUrl;
        }
      } catch (e) {
        debugPrint('[AddReminder] Storage voice upload notice: $e (stored locally)');
      }
    }

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
          voiceUrl: _voiceUrl,
          voiceDurationSeconds: _voiceDurationSeconds,
          voiceBytes: _voiceBytes,
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
          voiceUrl: _voiceUrl,
          voiceDurationSeconds: _voiceDurationSeconds,
          voiceBytes: _voiceBytes,
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

    final hasVoice = _voiceUrl.isNotEmpty || (_voiceBytes != null && _voiceBytes!.isNotEmpty);

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
                            isEdit ? 'Edit Follow-up Reminder' : 'Schedule Customer Reminder',
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
                                style: TextStyle(color: p.textPrimary, fontSize: 13),
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
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Reminder title is required' : null,
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
                            style: TextStyle(color: p.textPrimary, fontSize: 14),
                            decoration: _buildInputDec(
                              p,
                              'e.g. Priya Sharma',
                              prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
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
                            style: TextStyle(color: p.textPrimary, fontSize: 14),
                            decoration: _buildInputDec(
                              p,
                              '9998887776',
                              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: p.chipFill,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: p.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.gold),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: p.chipFill,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: p.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 18, color: AppColors.gold),
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
                                      right: prio != ReminderPriority.high ? 6 : 0,
                                    ),
                                    child: InkWell(
                                      onTap: () => setState(() => _priority = prio),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        height: 38,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _priority == prio
                                              ? prio.color.withValues(alpha: 0.18)
                                              : p.chipFill,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _priority == prio ? prio.color : p.border,
                                            width: _priority == prio ? 1.5 : 1,
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

                // VOICE MESSAGE SUPPORT
                _buildLabel(p, 'VOICE REMINDER (AUDIO MESSAGE)'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.chipFill.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasVoice ? AppColors.gold.withValues(alpha: 0.6) : p.border,
                      width: hasVoice ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isRecording) ...[
                        // Live recording indicator
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Recording... ${_formatDuration(_recordingSeconds)}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _stopRecording,
                              icon: const Icon(Icons.stop_circle_rounded, color: Colors.red),
                              label: const Text('Stop & Attach', style: TextStyle(color: Colors.red)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: _cancelRecording,
                              tooltip: 'Cancel recording',
                            ),
                          ],
                        ),
                      ] else if (hasVoice) ...[
                        // Audio preview & playback
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: AppColors.gold,
                                  size: 20,
                                ),
                                onPressed: _toggleAudioPlayback,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.mic, size: 14, color: AppColors.gold),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Voice Message Attached',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: p.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _voiceDurationSeconds > 0
                                        ? 'Duration: ${_formatDuration(_voiceDurationSeconds)}'
                                        : 'Audio ready for playback',
                                    style: TextStyle(fontSize: 11, color: p.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _clearVoice,
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                              label: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 11)),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Action buttons to record or upload
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _startRecording,
                                icon: const Icon(Icons.mic_rounded, size: 16),
                                label: const Text('Record Voice'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                                  foregroundColor: AppColors.gold,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(color: AppColors.gold, width: 1),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickAudioFile,
                                icon: const Icon(Icons.upload_file_rounded, size: 16),
                                label: const Text('Upload Audio'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: p.textPrimary,
                                  side: BorderSide(color: p.border),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
      hintStyle: TextStyle(color: p.textMuted.withValues(alpha: 0.6), fontSize: 13),
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

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
