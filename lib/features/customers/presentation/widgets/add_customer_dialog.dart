import 'package:raigon_art/core/utils/image_url_helper.dart';
import 'package:raigon_art/core/widgets/app_image_viewer.dart';
import 'dart:math' as math;
import 'dart:ui';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
import 'package:raigon_art/features/frame_sizes/providers/frame_size_provider.dart';

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
    // Save the customer first.
    await context.read<CustomerAndOrderProvider>().add(result);

    if (!context.mounted) return;

    AppSnackBar.success(context, 'Customer & frame order saved successfully.');

    // Open the same WhatsApp order confirmation template.
    try {
      final opened = await CustomerWhatsAppService.openOrderConfirmation(
        result,
      );

      if (!opened && context.mounted) {
        AppSnackBar.error(
          context,
          'Customer saved, but WhatsApp could not be opened.',
        );
      }
    } catch (error) {
      debugPrint('WhatsApp confirmation failed: $error');

      if (context.mounted) {
        AppSnackBar.error(
          context,
          'Customer saved, but WhatsApp could not be opened.',
        );
      }
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
    await context.read<CustomerAndOrderProvider>().update(result);

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
  final FrameSpecData _shared = FrameSpecData();
  final List<_FrameEntry> _entries = [];
  FrameMode _mode = FrameMode.same;
  bool _dragging = false;

  DateTime _orderDate = DateUtils.dateOnly(DateTime.now());
  DateTime? _delivery;
  String _payment = 'Unpaid';
  bool _paymentTouched = false;
  Status _status = Status.inProgress;

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
          final n = i < c.photoNames.length ? c.photoNames[i] : 'Photo_${i + 1}.webp';
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
          _existingPhotos.add(_ExistingPhotoItem(
            url: frames.first.photoUrl!,
            name: frames.first.photoName ?? 'Frame_Photo.webp',
          ));
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
    setState(() => _photos.addAll(picked));
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
    if (list.isNotEmpty) setState(() => _photos.addAll(list));
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
    });
  }

  Future<void> _addIndividual() async {
    final picked = await _pick();
    if (!mounted || picked.isEmpty) return;
    setState(() {
      if (_entries.length == 1 && _entries.first.photo == null) {
        _entries.first.spec.dispose();
        _entries.clear();
      }
      for (final p in picked) {
        _entries.add(_FrameEntry(photo: p));
      }
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

  void _removeEntry(_FrameEntry e) {
    setState(() {
      e.spec.dispose();
      _entries.remove(e);
      if (_entries.isEmpty) _entries.add(_FrameEntry());
    });
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

  void _save() {
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
    final advance = (double.tryParse(_advance.text) ?? 0).round();
    if (total > 0 && advance > total) {
      AppSnackBar.error(
        context,
        'Advance paid cannot exceed the total amount.',
      );
      return;
    }

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
      photoBytes: [for (final p in photos) p.bytes],
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
    );
    Navigator.of(context).pop(customer);
  }

  @override
  Widget build(BuildContext context) {
    final c = FormColors.of(context);
    final p = c.p;
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.42)),
          ),
        ),
        Center(
          child: Padding(
            padding: EdgeInsets.all(size.width < 600 ? 12 : 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 840,
                maxHeight: size.height - 48,
              ),
              child: Material(
                color: c.modalBg,
                elevation: 24,
                shadowColor: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
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
      ],
    );
  }

  Widget _header(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.iconDarkGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_add, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existing == null
                      ? 'Add New Customer & Frame Order'
                      : 'Edit Customer & Order (${widget.existing!.id})',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fill in customer profile, workshop framing details, and photos',
                  style: TextStyle(fontSize: 13.5, color: p.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: p.chipFill,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 21, color: p.textPrimary),
            ),
          ),
        ],
      ),
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
                icon: Icons.person,
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
                icon: Icons.photo_library,
                label: 'PHOTO DETAILS & FRAMING OPTIONS',
              ),
              gap,
              FormRow(
                children: [
                  _modeCard(
                    c,
                    FrameMode.same,
                    Icons.filter_none,
                    'Same Frame for All Photos',
                    'Upload multiple photos that share identical frame dimensions, material, and moulding style.',
                  ),
                  _modeCard(
                    c,
                    FrameMode.individual,
                    Icons.layers,
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
              const SizedBox(height: 26),
              const SectionHeader(
                icon: Icons.receipt_long,
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
                    label: 'Expected Delivery Date',
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
                    child: NumberBox(
                      controller: _total,
                      allowDecimal: true,
                      onChanged: (_) => _recalc(),
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
                      onChanged: (v) => setState(() {
                        _payment = v;
                        _paymentTouched = true;
                      }),
                    ),
                  ),
                  LabeledField(
                    label: 'Order Status',
                    child: FormDropdown<Status>(
                      value: _status,
                      items: Status.values,
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
                  Icon(Icons.cloud_upload, size: 58, color: p.textPrimary),
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
                            Icons.folder_open,
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
              const Icon(Icons.photo_library, size: 16, color: AppColors.gold),
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
                                    Icons.broken_image,
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
                        right: 5,
                        child: InkWell(
                          onTap: () => setState(() => _existingPhotos.removeAt(i)),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE05252),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
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
                              child: Image.memory(
                                _photos[i].bytes,
                                fit: BoxFit.cover,
                              ),
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
                              Icons.close,
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
          icon: Icons.straighten,
          label: 'FRAME SPECIFICATIONS',
        ),
        const SizedBox(height: 18),
        FrameSpecFields(data: _shared, onChanged: () => setState(() {})),
      ],
    );
  }

  Widget _individualContent(FormColors c) {
    final p = c.p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _entries.length; i++) ...[
          _entryCard(c, i, _entries[i]),
          const SizedBox(height: 16),
        ],
        InkWell(
          onTap: _addIndividual,
          borderRadius: BorderRadius.circular(14),
          child: CustomPaint(
            painter: DashedRRectPainter(
              color: AppColors.gold.withValues(alpha: 0.75),
            ),
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: c.dropzoneFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle, size: 22, color: p.textPrimary),
                  const SizedBox(width: 10),
                  Text(
                    'Add Another Photo & Frame',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _entryCard(FormColors c, int index, _FrameEntry e) {
    final p = c.p;
    final photo = e.photo;
    final hasExisting = e.existingUrl != null && e.existingUrl!.isNotEmpty;

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
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Tooltip(
        message: (photo != null || hasExisting) ? 'Tap to view full image' : '',
        child: Container(
          width: 68,
          height: 68,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: p.avatarBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: photo != null
              ? Image.memory(photo.bytes, fit: BoxFit.cover)
              : hasExisting
                  ? Image.network(
                      ImageUrlHelper.resolve(e.existingUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Icon(Icons.image_outlined, color: p.textMuted, size: 28),
                    )
                  : Icon(Icons.image_outlined, color: p.textMuted, size: 28),
        ),
      ),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.image, size: 17, color: AppColors.gold),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                photo?.name ?? e.existingName ?? (hasExisting ? 'Attached Photo' : 'No photo selected'),
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Photo #${index + 1}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.statusGold,
                ),
              ),
            ),
            if (photo != null) ...[
              const SizedBox(width: 10),
              Text(
                photo.sizeLabel,
                style: TextStyle(fontSize: 12.5, color: p.textMuted),
              ),
            ],
          ],
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _replace(e),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
                Icon(Icons.refresh, size: 17, color: p.textPrimary),
                const SizedBox(width: 6),
                Text(
                  photo == null ? 'Browse' : 'Replace',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _removeEntry(e),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
                FaIcon(
                  FontAwesomeIcons.trash,
                  size: 14,
                  color: Color(0xFFE5484D),
                ),
                SizedBox(width: 6),
                Text(
                  'Remove',
                  style: TextStyle(
                    fontSize: 13.5,
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
          FrameSpecFields(data: e.spec, onChanged: () => setState(() {})),
        ],
      ),
    );
  }

  Widget _footer(FormColors c) {
    final p = c.p;
    return Container(
      color: c.footerBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
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
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          AppPrimaryButton(
            label: 'Save Customer & Order',
            icon: Icons.check,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
