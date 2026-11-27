import 'dart:math' as math;
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:raigon_art/core/utils/image_url_helper.dart';
import 'package:raigon_art/core/widgets/app_confirmation_dialog.dart';
import 'package:raigon_art/core/widgets/app_image_viewer.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/app_primary_button.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/customers/models/frame_spec.dart';
import 'package:raigon_art/core/widgets/customer_dialog_kit.dart';
import 'package:raigon_art/core/widgets/form_kit.dart';
import 'package:raigon_art/features/customers/presentation/widgets/frame_spec_fields.dart';
import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/core/provider/customer_and_order_provider.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/features/customers/service/customer_whatsapp_service.dart';
import 'package:raigon_art/core/network/api_exception.dart';
import 'package:raigon_art/core/services/storage_service.dart';
import 'package:raigon_art/features/customers/presentation/widgets/order_voice_notes_section.dart';
import 'package:raigon_art/features/frame_sizes/providers/frame_size_provider.dart';
import 'package:raigon_art/core/widgets/app_image_cropper.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showAddCustomerDialog(BuildContext context) async {
  await context.read<FrameSizeProvider>().init();

  if (!context.mounted) return;

  final result = await showGeneralDialog<Customer>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Add customer',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => const AddCustomerDialog(),
    transitionBuilder: (_, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );

  if (result == null || !context.mounted) return;

  try {
    var finalResult = result;
    if (result.voiceNotes.isNotEmpty) {
      final updatedNotes = <OrderVoiceNote>[];
      for (var i = 0; i < result.voiceNotes.length; i++) {
        final vn = result.voiceNotes[i];
        if (vn.url.isEmpty &&
            vn.localBytes != null &&
            vn.localBytes!.isNotEmpty) {
          try {
            final fileName =
                'voice_order_${result.id}_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.m4a';
            final uploaded = await StorageService().uploadFile(
              vn.localBytes!,
              fileName,
            );
            if (uploaded.fileUrl.isNotEmpty) {
              updatedNotes.add(vn.copyWith(url: uploaded.fileUrl));
              continue;
            }
          } catch (e) {
            debugPrint('[OrderSave] Voice note upload notice: $e');
          }
        }
        updatedNotes.add(vn);
      }
      finalResult = result.copyWith(voiceNotes: updatedNotes);
    }

    if (finalResult.quotationDocuments.isNotEmpty) {
      final updatedDocs = <QuotationDocument>[];
      for (var i = 0; i < finalResult.quotationDocuments.length; i++) {
        final doc = finalResult.quotationDocuments[i];
        if (doc.url.isEmpty && doc.bytes != null && doc.bytes!.isNotEmpty) {
          try {
            final ext = doc.name.contains('.')
                ? doc.name.split('.').last.toLowerCase()
                : 'pdf';
            final fileName =
                'doc_order_${finalResult.id}_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.$ext';
            final uploaded = await StorageService().uploadFile(
              doc.bytes!,
              fileName,
            );
            if (uploaded.fileUrl.isNotEmpty) {
              updatedDocs.add(doc.copyWith(url: uploaded.fileUrl));
              continue;
            }
          } catch (e) {
            debugPrint('[OrderSave] Document upload notice: $e');
          }
        }
        updatedDocs.add(doc);
      }
      finalResult = finalResult.copyWith(quotationDocuments: updatedDocs);
    }

    if (!context.mounted) return;

    // Save the customer first.
    await context.read<CustomerAndOrderProvider>().add(finalResult);

    if (!context.mounted) return;

    AppSnackBar.success(context, 'Customer & frame order saved successfully.');

    // Automatically open WhatsApp order confirmation receipt.
    try {
      final opened = await CustomerWhatsAppService.openOrderConfirmation(
        finalResult,
      );

      if (!opened && context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) {
            final p = AppPalette.of(ctx);
            return AlertDialog(
              backgroundColor: p.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: p.border),
              ),
              title: Row(
                children: [
                  const Icon(
                    RemixIcons.whatsapp_fill,
                    color: AppColors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Open WhatsApp Receipt',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Customer ${result.name} is saved. Tap below to send the order confirmation receipt on WhatsApp.',
                style: TextStyle(fontSize: 14, color: p.textPrimary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Close', style: TextStyle(color: p.textMuted)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    CustomerWhatsAppService.openOrderConfirmation(result);
                  },
                  icon: const Icon(RemixIcons.whatsapp_fill, size: 16),
                  label: const Text(
                    'Open WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      debugPrint('WhatsApp confirmation failed: $error');
    }
  } catch (error) {
    debugPrint('Customer save failed: $error');

    if (context.mounted) {
      final msg = error is ApiException
          ? error.userFriendlyMessage
          : 'Could not save customer: ${error.toString().replaceAll('Exception:', '').trim()}';
      AppSnackBar.error(context, msg);
    }
  }
}

Future<void> showEditCustomerDialog(
  BuildContext context,
  Customer customer,
) async {
  final result = await showCustomerDialog<Customer>(
    context,
    label: 'Edit customer',
    builder: (_) => AddCustomerDialog(existing: customer),
  );

  if (result == null || !context.mounted) return;

  try {
    var finalResult = result;
    if (result.voiceNotes.isNotEmpty) {
      final updatedNotes = <OrderVoiceNote>[];
      for (var i = 0; i < result.voiceNotes.length; i++) {
        final vn = result.voiceNotes[i];
        if (vn.url.isEmpty &&
            vn.localBytes != null &&
            vn.localBytes!.isNotEmpty) {
          try {
            final fileName =
                'voice_order_${result.id}_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.m4a';
            final uploaded = await StorageService().uploadFile(
              vn.localBytes!,
              fileName,
            );
            if (uploaded.fileUrl.isNotEmpty) {
              updatedNotes.add(vn.copyWith(url: uploaded.fileUrl));
              continue;
            }
          } catch (e) {
            debugPrint('[OrderUpdate] Voice note upload notice: $e');
          }
        }
        updatedNotes.add(vn);
      }
      finalResult = result.copyWith(voiceNotes: updatedNotes);
    }

    if (finalResult.quotationDocuments.isNotEmpty) {
      final updatedDocs = <QuotationDocument>[];
      for (var i = 0; i < finalResult.quotationDocuments.length; i++) {
        final doc = finalResult.quotationDocuments[i];
        if (doc.url.isEmpty && doc.bytes != null && doc.bytes!.isNotEmpty) {
          try {
            final ext = doc.name.contains('.')
                ? doc.name.split('.').last.toLowerCase()
                : 'pdf';
            final fileName =
                'doc_order_${finalResult.id}_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.$ext';
            final uploaded = await StorageService().uploadFile(
              doc.bytes!,
              fileName,
            );
            if (uploaded.fileUrl.isNotEmpty) {
              updatedDocs.add(doc.copyWith(url: uploaded.fileUrl));
              continue;
            }
          } catch (e) {
            debugPrint('[OrderSave] Document upload notice: $e');
          }
        }
        updatedDocs.add(doc);
      }
      finalResult = finalResult.copyWith(quotationDocuments: updatedDocs);
    }

    if (!context.mounted) return;

    await context.read<CustomerAndOrderProvider>().update(finalResult);

    if (context.mounted) {
      AppSnackBar.success(context, 'Customer updated successfully.');
    }
  } catch (error) {
    if (context.mounted) {
      final msg = error is ApiException
          ? error.userFriendlyMessage
          : 'Could not update customer: ${error.toString().replaceAll('Exception:', '').trim()}';
      AppSnackBar.error(context, msg);
    }
  }
}

enum FrameMode { same, individual }

class _ExistingPhotoItem {
  _ExistingPhotoItem({required this.url, required this.name});
  final String url;
  final String name;
}

class _FrameEntry {
  _FrameEntry({this.photo, this.existingUrl, this.existingName});
  PickedPhoto? photo;
  String? existingUrl;
  String? existingName;
  final FrameSpecData spec = FrameSpecData();
}

class AddCustomerDialog extends StatefulWidget {
  final Customer? existing;
  const AddCustomerDialog({super.key, this.existing});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  static const _paymentOptions = ['Unpaid', 'Partial', 'Paid'];

  final _scroll = ScrollController();
  final _totalFocus = FocusNode(debugLabel: 'order_total');
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _alt = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _pin = TextEditingController();
  final _total = TextEditingController();
  final _advance = TextEditingController();
  final _balance = TextEditingController();
  final List<PickedPhoto> _photos = [];
  final List<_ExistingPhotoItem> _existingPhotos = [];
  List<OrderVoiceNote> _voiceNotes = [];
  List<QuotationDocument> _quotationDocuments = [];
  bool _isTotalManuallyAdjusted = false;
  final FrameSpecData _shared = FrameSpecData();
  final List<_FrameEntry> _entries = [];
  FrameMode _mode = FrameMode.same;
  bool _dragging = false;

  DateTime _orderDate = DateUtils.dateOnly(DateTime.now());
  DateTime? _delivery;
  String _payment = 'Unpaid';
  bool _paymentTouched = false;
  Status _status = Status.pending;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    if (c != null) _load(c);
  }

  void _load(Customer c) {
    _name.text = c.name;
    _phone.text = c.phone;
    _alt.text = c.altPhone;
    _city.text = c.city;
    _address.text = c.address;
    _pin.text = c.pincode;
    _total.text = c.total > 0 ? '${c.total}' : '';
    _advance.text = c.advance > 0 ? '${c.advance}' : '';
    _balance.text = (c.total == 0 && c.advance == 0)
        ? ''
        : '${math.max(0, c.balance)}';
    _orderDate = DateUtils.dateOnly(c.orderDate);
    _delivery = c.expectedDelivery;
    _payment = c.paymentStatus;
    _status = c.status;
    _voiceNotes = List<OrderVoiceNote>.of(c.voiceNotes);
    _quotationDocuments = List<QuotationDocument>.of(c.quotationDocuments);
    _isTotalManuallyAdjusted = c.isTotalManuallyAdjusted ||
        (c.total > 0 &&
            c.calculatedFramesTotal > 0 &&
            (c.total - c.calculatedFramesTotal).abs() > 0.01) ||
        (c.total > 0 && c.calculatedFramesTotal == 0);

    final frames = c.effectiveFrames;
    if (frames.length > 1) {
      _mode = FrameMode.individual;
      for (final f in frames) {
        final b = f.photoBytes;
        _entries.add(
          _FrameEntry(
            existingUrl: f.photoUrl,
            existingName: f.photoName,
            photo: b == null
                ? null
                : PickedPhoto(
                    name: f.photoName ?? 'Photo',
                    bytes: b,
                    size: b.length,
                  ),
          )..spec.loadSpec(f),
        );
      }
    } else {
      for (var i = 0; i < c.photoUrls.length; i++) {
        final u = c.photoUrls[i];
        if (u.trim().isNotEmpty) {
          final n = i < c.photoNames.length
              ? c.photoNames[i]
              : 'Photo_${i + 1}.webp';
          _existingPhotos.add(_ExistingPhotoItem(url: u, name: n));
        }
      }
      for (var i = 0; i < c.photoBytes.length; i++) {
        final b = c.photoBytes[i];
        _photos.add(
          PickedPhoto(
            name: i < c.photoNames.length
                ? c.photoNames[i]
                : 'Photo_${i + 1}.jpg',
            bytes: b,
            size: b.length,
          ),
        );
      }
      if (frames.isNotEmpty) {
        _shared.loadSpec(frames.first);
        if (frames.first.photoUrl != null &&
            frames.first.photoUrl!.isNotEmpty &&
            !_existingPhotos.any((e) => e.url == frames.first.photoUrl)) {
          _existingPhotos.add(
            _ExistingPhotoItem(
              url: frames.first.photoUrl!,
              name: frames.first.photoName ?? 'Frame_Photo.webp',
            ),
          );
        }
      }
      if (c.frames.isEmpty) {
        _shared.qty.text = c.photoCount > 1 ? '1' : '${c.qty}';
      }
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _totalFocus.dispose();
    for (final c in [
      _name,
      _phone,
      _alt,
      _city,
      _address,
      _pin,
      _total,
      _advance,
      _balance,
    ]) {
      c.dispose();
    }
    _shared.dispose();
    for (final e in _entries) {
      e.spec.dispose();
    }
    super.dispose();
  }

  void _recalculatePaymentAmounts() {
    final total = double.tryParse(_total.text) ?? 0;
    final advance = double.tryParse(_advance.text) ?? 0;

    _balance.text = math.max(0, total - advance).round().toString();
  }

  Future<List<PickedPhoto>> _pick({bool multiple = true}) async {
    try {
      debugPrint('========== FILE PICK START ==========');
      debugPrint('Multiple: $multiple');

      final List<PlatformFile> files;

      if (multiple) {
        files = await FilePicker.pickFiles(type: FileType.image);
      } else {
        final file = await FilePicker.pickFile(type: FileType.image);

        if (file == null) {
          debugPrint('File picking cancelled.');
          return [];
        }

        files = [file];
      }

      debugPrint('Files selected: ${files.length}');

      final result = <PickedPhoto>[];

      for (final file in files) {
        debugPrint('Reading: ${file.name}');

        final bytes = await file.readAsBytes();

        result.add(
          PickedPhoto(name: file.name, bytes: bytes, size: bytes.length),
        );
      }

      debugPrint('========== FILE PICK SUCCESS: ${result.length} ==========');

      return result;
    } catch (error) {
      debugPrint('[CustomerImages] File selection failed: $error');
      rethrow;
    }
  }

  Future<void> _browseSame() async {
    final picked = await _pick();
    if (!mounted || picked.isEmpty) return;
    setState(() {
      _photos.addAll(picked);
      _syncCalculatedTotal();
    });
  }

  Future<void> _onDrop(DropDoneDetails d) async {
    setState(() => _dragging = false);
    final list = <PickedPhoto>[];
    var skipped = false;
    for (final f in d.files) {
      final n = f.name.toLowerCase();
      final ok =
          n.endsWith('.jpg') ||
          n.endsWith('.jpeg') ||
          n.endsWith('.png') ||
          n.endsWith('.webp');
      if (!ok) {
        skipped = true;
        continue;
      }
      final bytes = await f.readAsBytes();
      list.add(PickedPhoto(name: f.name, bytes: bytes, size: bytes.length));
    }
    if (!mounted) return;
    if (skipped) {
      AppSnackBar.error(
        context,
        'Only JPG, PNG and WEBP photos are supported.',
      );
    }
    if (list.isNotEmpty) {
      setState(() {
        _photos.addAll(list);
        _syncCalculatedTotal();
      });
    }
  }

  void _setMode(FrameMode mode) {
    if (mode == _mode) return;
    setState(() {
      if (mode == FrameMode.individual && _entries.isEmpty) {
        if (_photos.isEmpty) {
          _entries.add(_FrameEntry());
        } else {
          for (final p in _photos) {
            _entries.add(_FrameEntry(photo: p));
          }
        }
      }
      if (mode == FrameMode.same && _photos.isEmpty) {
        _photos.addAll([
          for (final e in _entries)
            if (e.photo != null) e.photo!,
        ]);
      }
      _mode = mode;
      _syncCalculatedTotal();
    });
  }

  void _addIndividual() {
    setState(() {
      _entries.add(_FrameEntry());
      _syncCalculatedTotal();
    });

    // Scroll to the newly added card.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _addWithPhotos() async {
    final picked = await _pick();
    if (!mounted || picked.isEmpty) return;
    setState(() {
      var pIndex = 0;
      if (_entries.length == 1 &&
          _entries.first.photo == null &&
          (_entries.first.existingUrl == null ||
              _entries.first.existingUrl!.isEmpty) &&
          _entries.first.spec.width.text.isEmpty &&
          _entries.first.spec.height.text.isEmpty &&
          _entries.first.spec.notes.text.isEmpty &&
          _entries.first.spec.customerNote.text.isEmpty) {
        _entries.first.photo = picked.first;
        pIndex = 1;
      }
      for (var i = pIndex; i < picked.length; i++) {
        _entries.add(_FrameEntry(photo: picked[i]));
      }
      _syncCalculatedTotal();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _replace(_FrameEntry e) async {
    final picked = await _pick(multiple: false);
    if (!mounted || picked.isEmpty) return;
    setState(() {
      e.photo = picked.first;
      e.existingUrl = null;
      e.existingName = null;
    });
  }

  void _clearPhoto(_FrameEntry e) {
    setState(() {
      e.photo = null;
      e.existingUrl = null;
      e.existingName = null;
    });
  }

  void _removeEntry(_FrameEntry e) {
    setState(() {
      e.spec.dispose();
      _entries.remove(e);
      if (_entries.isEmpty) _entries.add(_FrameEntry());
      _syncCalculatedTotal();
    });
  }

  double get _calculatedTotal {
    if (_mode == FrameMode.same) {
      final unitPrice = _shared.unitPriceValue;
      final specQty = _shared.qtyValue;
      final photoCount = math.max(1, _existingPhotos.length + _photos.length);
      final effectiveQty = specQty * photoCount;
      return unitPrice * effectiveQty;
    } else {
      double sum = 0.0;
      for (final e in _entries) {
        sum += e.spec.subtotalValue;
      }
      return sum;
    }
  }

  void _syncCalculatedTotal({bool force = false}) {
    final calc = _calculatedTotal;
    if (force || !_isTotalManuallyAdjusted) {
      if (calc > 0 || force) {
        _total.text = calc > 0
            ? (calc.truncateToDouble() == calc
                ? calc.toInt().toString()
                : calc.toStringAsFixed(2))
            : (force ? '0' : '');
      }
      _recalc();
    }
  }

  void _resetToCalculated() {
    setState(() {
      _isTotalManuallyAdjusted = false;
      _syncCalculatedTotal(force: true);
    });
  }

  Future<void> _pickQuotationDocuments() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'rtf',
          'png',
          'jpg',
          'jpeg',
          'webp',
        ],
      );
      if (files.isEmpty) return;

      final newDocs = <QuotationDocument>[];
      for (final f in files) {
        final bytes = await f.readAsBytes();
        if (bytes.isNotEmpty) {
          final ext =
              f.name.contains('.') ? f.name.split('.').last.toLowerCase() : '';
          String mime = 'application/octet-stream';
          if (ext == 'pdf') {
            mime = 'application/pdf';
          } else if (ext == 'doc') {
            mime = 'application/msword';
          } else if (ext == 'docx') {
            mime =
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          } else if (['png', 'jpg', 'jpeg', 'webp'].contains(ext)) {
            mime = 'image/$ext';
          } else if (ext == 'txt') {
            mime = 'text/plain';
          }

          newDocs.add(
            QuotationDocument(
              id:
                  'doc_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}',
              name: f.name,
              url: '',
              sizeBytes: bytes.length,
              mimeType: mime,
              bytes: bytes,
              createdAt: DateTime.now(),
            ),
          );
        }
      }

      if (mounted && newDocs.isNotEmpty) {
        setState(() {
          _quotationDocuments.addAll(newDocs);
        });
      }
    } catch (e) {
      debugPrint('[QuotationPick] Error: $e');
      if (mounted) {
        AppSnackBar.error(context, 'Failed to pick quotation file: $e');
      }
    }
  }

  Future<void> _viewOrOpenQuotation(QuotationDocument doc) async {
    if (doc.url.isNotEmpty) {
      final uri = Uri.parse(ImageUrlHelper.resolve(doc.url));
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Could not launch doc URL: $e');
      }
    } else if (doc.bytes != null) {
      final ext =
          doc.name.contains('.') ? doc.name.split('.').last.toLowerCase() : '';
      if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        showSingleImageViewer(
          context: context,
          bytes: doc.bytes,
          title: doc.name,
          subtitle: doc.sizeLabel,
        );
      } else {
        AppSnackBar.info(
          context,
          '${doc.name} (${doc.sizeLabel}) is attached and will be uploaded on save.',
        );
      }
    }
  }

  void _recalc() {
    final total = double.tryParse(_total.text) ?? 0;
    final adv = double.tryParse(_advance.text) ?? 0;
    setState(() {
      _balance.text = (_total.text.isEmpty && _advance.text.isEmpty)
          ? ''
          : math.max(0, total - adv).round().toString();
      if (!_paymentTouched) {
        _payment = adv <= 0
            ? 'Unpaid'
            : (total > 0 && adv >= total ? 'Paid' : 'Partial');
      }
    });
  }

  String _join(List<String> v) => v.isEmpty
      ? '—'
      : (v.length == 1 ? v.first : '${v.first} +${v.length - 1} more');

  Future<void> _save() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();

    if (name.isEmpty) {
      AppSnackBar.error(context, 'Enter the customer name.');
      return;
    }

    if (phone.length != 10) {
      AppSnackBar.error(context, 'Enter a valid 10-digit phone number.');
      return;
    }

    final total = (double.tryParse(_total.text) ?? 0).round();
    final enteredAdvance = (double.tryParse(_advance.text) ?? 0).round();

    final advance = _payment == 'Paid'
        ? total
        : _payment == 'Unpaid'
        ? 0
        : enteredAdvance;
    if (total > 0 && advance > total) {
      AppSnackBar.error(
        context,
        'Advance paid cannot exceed the total amount.',
      );
      return;
    }

    final isEdit = widget.existing != null;

    // Confirmation before creating or updating customer.
    final confirmed = await showAppConfirmationDialog(
      context,
      title: isEdit ? 'Update Customer?' : 'Create Customer?',
      message: isEdit
          ? 'Are you sure you want to save the changes for $name?'
          : 'Are you sure you want to create a customer profile for $name?',
      cancelLabel: 'Cancel',
      confirmLabel: 'Save',
      icon: RemixIcons.user_line,
      iconColor: AppColors.gold,
      iconBg: AppColors.gold.withValues(alpha: 0.12),
      confirmColor: AppColors.gold,
      isDestructive: false,
    );

    if (!confirmed) return;
    // Cancel: stay on the form with all entered details.
    if (confirmed != true || !mounted) return;

    final same = _mode == FrameMode.same;

    final photos = same
        ? List<PickedPhoto>.of(_photos)
        : [
            for (final e in _entries)
              if (e.photo != null) e.photo!,
          ];

    final frames = same
        ? [_shared.toSpec()]
        : [for (final e in _entries) e.spec.toSpec(e.photo)];

    final int qty = same
        ? frames.first.qty *
              math.max(1, _existingPhotos.length + photos.length).toInt()
        : frames.fold<int>(0, (a, f) => a + f.qty);

    final remainingUrls = same
        ? [for (final e in _existingPhotos) e.url]
        : [
            for (final e in _entries)
              if (e.photo == null &&
                  e.existingUrl != null &&
                  e.existingUrl!.isNotEmpty)
                e.existingUrl!,
          ];

    final remainingNames = same
        ? [for (final e in _existingPhotos) e.name]
        : [
            for (final e in _entries)
              if (e.photo == null &&
                  e.existingName != null &&
                  e.existingName!.isNotEmpty)
                e.existingName!,
          ];

    final newPhotoNames = [for (final p in photos) p.name];
    final allPhotoNames = [...remainingNames, ...newPhotoNames];
    final totalPhotoCount = remainingUrls.length + photos.length;

    final customer = Customer(
      id:
          widget.existing?.id ??
          context.read<CustomerAndOrderProvider>().nextId(),
      name: name,
      city: _city.text.trim(),
      phone: phone,
      altPhone: _alt.text.trim(),
      address: _address.text.trim(),
      pincode: _pin.text.trim(),
      photoNames: allPhotoNames.isNotEmpty
          ? allPhotoNames
          : (widget.existing?.photoNames ?? const []),
      photoCount: totalPhotoCount > 0
          ? totalPhotoCount
          : (widget.existing?.photoCount ?? 0),
      photoBytes: [
        for (final p in photos)
          if (p.bytes != null) p.bytes!,
      ],
      frameSize: _join([for (final f in frames) f.sizeLabel]),
      frameType: _join([for (final f in frames) f.frameType]),
      qty: qty,
      total: total,
      advance: advance,
      paymentStatus: _payment,
      status: _status,
      orderDate: _orderDate,
      expectedDelivery: _delivery,
      photoUrls: remainingUrls,
      photoSizeLabels: widget.existing?.photoSizeLabels ?? const [],
      frames: frames,
      voiceNotes: _voiceNotes,
      quotationDocuments: _quotationDocuments,
      isTotalManuallyAdjusted: _isTotalManuallyAdjusted,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (!mounted) return;

    // Return the customer only after Save is confirmed.
    Navigator.of(context).pop(customer);
  }

  @override
  Widget build(BuildContext context) {
    final c = FormColors.of(context);
    final p = c.p;
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isNarrow = size.width < 600;
    final verticalPadding = isNarrow ? 12.0 : 24.0;
    final availableHeight =
        size.height - keyboardHeight - (verticalPadding * 2);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.42)),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: keyboardHeight,
                left: isNarrow ? 8 : 24,
                right: isNarrow ? 8 : 24,
                top: isNarrow ? 8 : 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 840,
                    maxHeight: availableHeight.clamp(240.0, size.height),
                  ),
                  child: Material(
                    color: c.modalBg,
                    elevation: 24,
                    shadowColor: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(isNarrow ? 16 : 24),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _header(p),
                        Divider(height: 1, color: p.border),
                        Flexible(child: _body(c)),
                        Divider(height: 1, color: p.border),
                        _footer(c),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(AppPalette p) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            isNarrow ? 16 : 24,
            isNarrow ? 16 : 20,
            isNarrow ? 16 : 24,
            isNarrow ? 14 : 18,
          ),
          child: Row(
            children: [
              Container(
                width: isNarrow ? 42 : 52,
                height: isNarrow ? 42 : 52,
                decoration: BoxDecoration(
                  gradient: AppColors.iconDarkGradient,
                  borderRadius: BorderRadius.circular(isNarrow ? 10 : 14),
                ),
                child: Icon(
                  RemixIcons.user_add_line,
                  color: Colors.white,
                  size: isNarrow ? 22 : 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.existing == null
                          ? 'Add Customer & Order'
                          : 'Edit Order (${widget.existing!.id})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isNarrow ? 18 : 22,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isNarrow ? 'Workshop framing details & photos' : 'Fill in customer profile, workshop framing details, and photos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isNarrow ? 12 : 13.5,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                customBorder: const CircleBorder(),
                child: Container(
                  width: isNarrow ? 36 : 40,
                  height: isNarrow ? 36 : 40,
                  decoration: BoxDecoration(
                    color: p.chipFill,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.border),
                  ),
                  child: Icon(
                    RemixIcons.close_line,
                    size: isNarrow ? 18 : 20,
                    color: p.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _body(FormColors c) {
    const gap = SizedBox(height: 18);
    final digits = <TextInputFormatter>[
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(10),
    ];
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.gold),
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(3),
      ),
      child: Scrollbar(
        controller: _scroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                icon: RemixIcons.user_3_line,
                label: 'CUSTOMER INFORMATION',
              ),
              gap,
              FormRow(
                children: [
                  LabeledField(
                    label: 'Customer Name',
                    required: true,
                    child: AppTextBox(
                      controller: _name,
                      hint: 'e.g. Arun Kumar',
                    ),
                  ),
                  LabeledField(
                    label: 'Phone Number',
                    required: true,
                    child: AppTextBox(
                      controller: _phone,
                      hint: 'e.g. 7902261255',
                      keyboardType: TextInputType.phone,
                      inputFormatters: digits,
                    ),
                  ),
                ],
              ),
              gap,
              FormRow(
                children: [
                  LabeledField(
                    label: 'Alternative Phone Number',
                    child: AppTextBox(
                      controller: _alt,
                      hint: 'e.g. 9447000000',
                      keyboardType: TextInputType.phone,
                      inputFormatters: digits,
                    ),
                  ),
                  LabeledField(
                    label: 'City / Town',
                    child: AppTextBox(
                      controller: _city,
                      hint: 'e.g. Trivandrum, Kochi, Kollam',
                    ),
                  ),
                ],
              ),
              gap,
              FormRow(
                flex: const [2, 1],
                children: [
                  LabeledField(
                    label: 'Full Address',
                    child: AppTextBox(
                      controller: _address,
                      hint: 'Street, Building No, Landmark',
                    ),
                  ),
                  LabeledField(
                    label: 'Pincode',
                    child: AppTextBox(
                      controller: _pin,
                      hint: '695001',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const SectionHeader(
                icon: RemixIcons.gallery_line,
                label: 'PHOTO DETAILS & FRAMING OPTIONS',
              ),
              gap,
              FormRow(
                children: [
                  _modeCard(
                    c,
                    FrameMode.same,
                    RemixIcons.file_copy_line,
                    'Same Frame for All Photos',
                    'Upload multiple photos that share identical frame dimensions, material, and moulding style.',
                  ),
                  _modeCard(
                    c,
                    FrameMode.individual,
                    RemixIcons.stack_line,
                    'Individual Frame for Each Photo',
                    'Configure separate frame size, type, material, color, and specs for every photo uploaded.',
                  ),
                ],
              ),
              gap,
              if (_mode == FrameMode.same)
                _sameContent(c)
              else
                _individualContent(c),
              const SizedBox(height: 24),
              OrderVoiceNotesSection(
                voiceNotes: _voiceNotes,
                onChanged: (notes) => setState(() => _voiceNotes = notes),
                isEditable: true,
              ),
              const SizedBox(height: 24),
              _quotationSection(c),
              const SizedBox(height: 26),
              const SectionHeader(
                icon: RemixIcons.bill_line,
                label: 'ORDER & PAYMENT DETAILS',
              ),
              gap,
              FormRow(
                children: [
                  LabeledField(
                    label: 'Order Date',
                    child: DateField(
                      value: _orderDate,
                      showIcon: false,
                      onChanged: (d) => setState(() => _orderDate = d),
                    ),
                  ),
                  LabeledField(
                    label: 'Expected Date',
                    child: DateField(
                      value: _delivery,
                      onChanged: (d) => setState(() => _delivery = d),
                    ),
                  ),
                ],
              ),
              gap,
              FormRow(
                children: [
                  LabeledField(
                    label: 'Total Amount (₹)',
                    trailing: _isTotalManuallyAdjusted
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B).withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'Adjusted',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: _resetToCalculated,
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    'Reset (₹${_calculatedTotal > 0 ? (_calculatedTotal.truncateToDouble() == _calculatedTotal ? _calculatedTotal.toInt() : _calculatedTotal.toStringAsFixed(2)) : 0})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.green.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Text(
                              'Auto Calculated',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.green,
                              ),
                            ),
                          ),
                    child: NumberBox(
                      controller: _total,
                      focusNode: _totalFocus,
                      allowDecimal: true,
                      onChanged: (_) {
                        _isTotalManuallyAdjusted = true;
                        _recalc();
                      },
                    ),
                  ),
                  LabeledField(
                    label: 'Advance Paid (₹)',
                    child: NumberBox(
                      controller: _advance,
                      allowDecimal: true,
                      onChanged: (_) => _recalc(),
                    ),
                  ),
                  LabeledField(
                    label: 'Balance Amount (₹)',
                    child: NumberBox(
                      controller: _balance,
                      hint: '0',
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              gap,
              FormRow(
                children: [
                  LabeledField(
                    label: 'Payment Status',
                    child: FormDropdown<String>(
                      value: _payment,
                      items: _paymentOptions,
                      labelOf: (s) => s,
                      onChanged: (v) {
                        setState(() {
                          _payment = v;
                          _paymentTouched = true;

                          if (v == 'Paid') {
                            _advance.text = _total.text;
                            _balance.text = '0';
                          } else if (v == 'Unpaid') {
                            _advance.text = '0';
                            final total = double.tryParse(_total.text) ?? 0;
                            _balance.text = total.round().toString();
                          } else {
                            _recalculatePaymentAmounts();
                          }
                        });
                      },
                    ),
                  ),
                  LabeledField(
                    label: 'Order Status',
                    child: FormDropdown<Status>(
                      value: _status,
                      items: Status.standardStatuses,
                      labelOf: (status) => status.label,
                      onChanged: (value) {
                        setState(() => _status = value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeCard(
    FormColors c,
    FrameMode mode,
    IconData icon,
    String title,
    String body,
  ) {
    final p = c.p;
    final selected = _mode == mode;
    return InkWell(
      onTap: () => _setMode(mode),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? c.selectedCardFill : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.gold : p.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? p.textPrimary : p.border,
                  width: selected ? 2 : 1.5,
                ),
              ),
              child: selected
                  ? Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: p.textPrimary,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: p.textMuted,
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

  Widget _sameContent(FormColors c) {
    final p = c.p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropTarget(
          onDragEntered: (_) => setState(() => _dragging = true),
          onDragExited: (_) => setState(() => _dragging = false),
          onDragDone: _onDrop,
          child: CustomPaint(
            painter: DashedRRectPainter(
              color: AppColors.gold.withValues(alpha: 0.75),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 16),
              decoration: BoxDecoration(
                color: _dragging
                    ? AppColors.gold.withValues(alpha: 0.14)
                    : c.dropzoneFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(
                    RemixIcons.upload_cloud_2_line,
                    size: 58,
                    color: p.textPrimary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Drag & Drop Customer Photos Here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Supports JPG, PNG, WEBP high-resolution photo prints',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: p.textMuted),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _browseSame,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: p.chipFill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: p.isDark ? p.border : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            RemixIcons.folder_open_line,
                            size: 19,
                            color: p.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Browse Files',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: p.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_existingPhotos.isNotEmpty || _photos.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                RemixIcons.gallery_line,
                size: 16,
                color: AppColors.gold,
              ),
              const SizedBox(width: 8),
              Text(
                '${_existingPhotos.length + _photos.length} photos attached'
                '${_existingPhotos.isNotEmpty && _photos.isNotEmpty ? ' (${_existingPhotos.length} existing, ${_photos.length} new)' : ''}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (var i = 0; i < _existingPhotos.length; i++)
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Tooltip(
                          message: 'Tap to view full image',
                          child: InkWell(
                            onTap: () {
                              final allItems = <AppViewerItem>[
                                for (final p in _existingPhotos)
                                  AppViewerItem(
                                    url: p.url,
                                    title: p.name,
                                    subtitle: 'Existing Customer Photo',
                                  ),
                                for (final p in _photos)
                                  AppViewerItem(
                                    bytes: p.bytes,
                                    title: p.name,
                                    subtitle: 'New Photo · ${p.sizeLabel}',
                                  ),
                              ];
                              showAppImageViewer(
                                context: context,
                                items: allItems,
                                initialIndex: i,
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                ImageUrlHelper.resolve(_existingPhotos[i].url),
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    color: Colors.black12,
                                    alignment: Alignment.center,
                                    child: const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, _, _) => Container(
                                  color: Colors.black26,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    RemixIcons.image_line,
                                    size: 26,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        left: 5,
                        child: InkWell(
                          onTap: () async {
                            final cropped = await showAppImageCropper(
                              context: context,
                              url: _existingPhotos[i].url,
                              title: 'Crop ${_existingPhotos[i].name}',
                            );
                            if (cropped != null && mounted) {
                              setState(() {
                                final ex = _existingPhotos.removeAt(i);
                                _photos.add(
                                  PickedPhoto(
                                    name: ex.name,
                                    bytes: cropped,
                                    size: cropped.length,
                                  ),
                                );
                              });
                            }
                          },
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              RemixIcons.crop_line,
                              size: 13,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _existingPhotos.removeAt(i)),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE05252),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              RemixIcons.close_line,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              for (var i = 0; i < _photos.length; i++)
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Tooltip(
                          message: 'Tap to view full image',
                          child: InkWell(
                            onTap: () {
                              final allItems = <AppViewerItem>[
                                for (final p in _existingPhotos)
                                  AppViewerItem(
                                    url: p.url,
                                    title: p.name,
                                    subtitle: 'Existing Customer Photo',
                                  ),
                                for (final p in _photos)
                                  AppViewerItem(
                                    bytes: p.bytes,
                                    title: p.name,
                                    subtitle: 'New Photo · ${p.sizeLabel}',
                                  ),
                              ];
                              showAppImageViewer(
                                context: context,
                                items: allItems,
                                initialIndex: _existingPhotos.length + i,
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _photos[i].bytes != null
                                  ? Image.memory(
                                      _photos[i].bytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: p.chipFill,
                                      child: const Icon(Icons.image),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        left: 5,
                        child: InkWell(
                          onTap: () async {
                            final cropped = await showAppImageCropper(
                              context: context,
                              bytes: _photos[i].bytes,
                              title: 'Crop ${_photos[i].name}',
                            );
                            if (cropped != null && mounted) {
                              setState(() {
                                _photos[i] = PickedPhoto(
                                  name: _photos[i].name,
                                  bytes: cropped,
                                  size: cropped.length,
                                );
                              });
                            }
                          },
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              RemixIcons.crop_line,
                              size: 13,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: InkWell(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE05252),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              RemixIcons.close_line,
                              size: 14,
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
        ],
        const SizedBox(height: 26),
        const SectionHeader(
          icon: RemixIcons.ruler_line,
          label: 'FRAME SPECIFICATIONS',
        ),
        const SizedBox(height: 18),
        FrameSpecFields(
          data: _shared,
          onChanged: () => setState(() => _syncCalculatedTotal()),
          onNextFromCustomerNote: () => _totalFocus.requestFocus(),
        ),
      ],
    );
  }

  Widget _individualContent(FormColors c) {
    final p = c.p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _entries.length; i++) ...[
          FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: _entryCard(c, i, _entries[i]),
          ),
          const SizedBox(height: 16),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 540;
            final addFrameBtn = InkWell(
              onTap: _addIndividual,
              borderRadius: BorderRadius.circular(14),
              child: CustomPaint(
                painter: DashedRRectPainter(
                  color: AppColors.gold.withValues(alpha: 0.85),
                ),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: c.dropzoneFill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        RemixIcons.add_circle_line,
                        size: 22,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Add Another Photo & Frame',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            final uploadPhotosBtn = InkWell(
              onTap: _addWithPhotos,
              borderRadius: BorderRadius.circular(14),
              child: CustomPaint(
                painter: DashedRRectPainter(color: p.border),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: p.chipFill.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        RemixIcons.upload_cloud_2_line,
                        size: 22,
                        color: p.textPrimary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Upload Images Directly',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            if (isNarrow) {
              return Column(
                children: [
                  addFrameBtn,
                  const SizedBox(height: 10),
                  uploadPhotosBtn,
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 3, child: addFrameBtn),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: uploadPhotosBtn),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _entryCard(FormColors c, int index, _FrameEntry e) {
    final p = c.p;
    final photo = e.photo;
    final hasExisting = e.existingUrl != null && e.existingUrl!.isNotEmpty;
    final hasPhoto = photo != null || hasExisting;

    final thumb = InkWell(
      onTap: () {
        if (photo != null) {
          showSingleImageViewer(
            context: context,
            bytes: photo.bytes,
            title: photo.name,
            subtitle: photo.sizeLabel,
          );
        } else if (hasExisting) {
          showSingleImageViewer(
            context: context,
            url: e.existingUrl!,
            title: e.existingName ?? 'Attached Photo',
            subtitle: 'Frame Artwork Spec',
          );
        } else {
          _replace(e);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Tooltip(
        message: hasPhoto ? 'Tap to view full image' : 'Tap to attach photo',
        child: Container(
          width: 68,
          height: 68,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: p.avatarBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasPhoto
                  ? Colors.transparent
                  : AppColors.gold.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: (photo != null && photo.bytes != null)
              ? Image.memory(photo.bytes!, fit: BoxFit.cover)
              : (photo != null && photo.url != null)
              ? Image.network(
                  ImageUrlHelper.resolve(photo.url!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Icon(RemixIcons.image_line, color: p.textMuted, size: 28),
                )
              : hasExisting
              ? Image.network(
                  ImageUrlHelper.resolve(e.existingUrl!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Icon(RemixIcons.image_line, color: p.textMuted, size: 28),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      RemixIcons.image_add_line,
                      color: AppColors.gold,
                      size: 24,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Attach',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              hasPhoto ? RemixIcons.image_fill : RemixIcons.image_line,
              size: 17,
              color: hasPhoto ? AppColors.gold : p.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                photo?.name ??
                    e.existingName ??
                    (hasExisting ? 'Attached Photo' : 'No photo attached yet'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Frame #${index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.statusGold,
                ),
              ),
            ),
            if (!hasPhoto)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: p.chipFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: p.isDark ? p.border : Colors.black12,
                  ),
                ),
                child: Text(
                  'Photo Pending (Can update later)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: p.textMuted,
                  ),
                ),
              ),
            if (photo != null)
              Text(
                photo.sizeLabel,
                style: TextStyle(fontSize: 12, color: p.textMuted),
              ),
          ],
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!hasPhoto) ...[
          InkWell(
            onTap: () => _replace(e),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.35),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(RemixIcons.upload_2_line, size: 16, color: AppColors.gold),
                  SizedBox(width: 6),
                  Text(
                    'Attach Photo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          InkWell(
            onTap: () async {
              final cropped = await showAppImageCropper(
                context: context,
                bytes: photo?.bytes,
                url: e.existingUrl,
                title: 'Crop Frame Artwork #${index + 1}',
              );
              if (cropped != null && mounted) {
                setState(() {
                  e.photo = PickedPhoto(
                    name: photo?.name ?? e.existingName ?? 'Cropped_Artwork.jpg',
                    bytes: cropped,
                    size: cropped.length,
                  );
                  e.existingUrl = null;
                  e.existingName = null;
                });
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.35),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(RemixIcons.crop_line, size: 15, color: AppColors.gold),
                  SizedBox(width: 4),
                  Text(
                    'Crop',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => _replace(e),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: p.chipFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: p.isDark ? p.border : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(RemixIcons.refresh_line, size: 15, color: p.textPrimary),
                  const SizedBox(width: 5),
                  Text(
                    'Replace',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => _clearPhoto(e),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: p.chipFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: p.isDark ? p.border : Colors.transparent,
                ),
              ),
              child: Tooltip(
                message: 'Remove photo only (keep frame specs)',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(RemixIcons.close_circle_line, size: 15, color: p.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _removeEntry(e),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFE5484D).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE5484D).withValues(alpha: 0.25),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  RemixIcons.delete_bin_line,
                  size: 14,
                  color: Color(0xFFE5484D),
                ),
                SizedBox(width: 5),
                Text(
                  'Remove',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE5484D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Container(
      key: ObjectKey(e),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, cons) {
              if (cons.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        thumb,
                        const SizedBox(width: 14),
                        Expanded(child: info),
                      ],
                    ),
                    const SizedBox(height: 12),
                    actions,
                  ],
                );
              }
              return Row(
                children: [
                  thumb,
                  const SizedBox(width: 14),
                  Expanded(child: info),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 1,
            child: CustomPaint(painter: DashedLinePainter(p.rowDivider)),
          ),
          const SizedBox(height: 18),
          FrameSpecFields(
            data: e.spec,
            onChanged: () => setState(() => _syncCalculatedTotal()),
            onNextFromCustomerNote: () {
              if (index + 1 < _entries.length) {
                _entries[index + 1].spec.priceFocus.requestFocus();
              } else {
                _totalFocus.requestFocus();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _quotationSection(FormColors c) {
    final p = c.p;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          icon: RemixIcons.file_text_line,
          label: 'COMMON QUOTATION & ORDER DOCUMENTS',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.isDark ? const Color(0xFF2C2E46) : const Color(0xFFFCFAF5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: p.isDark ? 0.35 : 0.45),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      RemixIcons.attachment_2,
                      size: 20,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order-Level Quotation & Reference Files',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Attach customer quotations, PDF estimates, Word documents (.doc/.docx), or common reference notes for the entire order.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: p.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _pickQuotationDocuments,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.chipFill,
                      foregroundColor: p.textPrimary,
                      elevation: 0,
                      side: BorderSide(color: p.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(RemixIcons.upload_2_line, size: 16),
                    label: const Text(
                      'Attach File',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (_quotationDocuments.isNotEmpty) ...[
                const SizedBox(height: 14),
                Divider(height: 1, color: p.border),
                const SizedBox(height: 12),
                for (var i = 0; i < _quotationDocuments.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _quotationDocItem(p, i, _quotationDocuments[i]),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _quotationDocItem(AppPalette p, int index, QuotationDocument doc) {
    final isPdf = doc.isPdf;
    final isWord = doc.name.toLowerCase().endsWith('.doc') ||
        doc.name.toLowerCase().endsWith('.docx');
    final iconColor = isPdf
        ? const Color(0xFFE5484D)
        : (isWord ? const Color(0xFF3E63DD) : AppColors.gold);
    final iconBg = isPdf
        ? const Color(0xFFE5484D).withValues(alpha: 0.12)
        : (isWord
            ? const Color(0xFF3E63DD).withValues(alpha: 0.12)
            : AppColors.gold.withValues(alpha: 0.12));
    final iconData = isPdf
        ? RemixIcons.file_pdf_2_line
        : (isWord ? RemixIcons.file_word_2_line : RemixIcons.file_text_line);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(iconData, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  '${doc.sizeLabel} ${doc.url.isNotEmpty ? '· Uploaded' : '· Pending upload'}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: p.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _viewOrOpenQuotation(doc),
            tooltip: 'View / Open Document',
            icon: const Icon(RemixIcons.external_link_line, size: 17),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _quotationDocuments.removeAt(index);
              });
            },
            tooltip: 'Remove Attachment',
            icon: const Icon(
              RemixIcons.delete_bin_line,
              size: 17,
              color: Color(0xFFE5484D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(FormColors c) {
    final p = c.p;

    return LayoutBuilder(
      builder: (_, constraints) {
        final isNarrow = constraints.maxWidth < 540;

        final cancelBtn = InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 16 : 20,
              vertical: 13,
            ),
            alignment: isNarrow ? Alignment.center : null,
            decoration: p.isDark
                ? BoxDecoration(
                    color: p.chipFill,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: p.border),
                  )
                : BoxDecoration(
                    color: p.chipFill.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ),
        );

        final saveBtn = AppPrimaryButton(
          label: isNarrow ? 'Save Order' : 'Save Customer & Order',
          icon: RemixIcons.check_line,
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 12 : 22,
            vertical: 14,
          ),
          onPressed: _save,
        );

        return Container(
          color: c.footerBg,
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 16 : 24,
            vertical: 14,
          ),
          child: isNarrow
              ? Row(
                  children: [
                    Expanded(child: cancelBtn),
                    const SizedBox(width: 10),
                    Expanded(child: saveBtn),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [cancelBtn, const SizedBox(width: 14), saveBtn],
                ),
        );
      },
    );
  }
}
