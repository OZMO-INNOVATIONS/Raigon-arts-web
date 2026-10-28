import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/network/api_exception.dart';
import 'package:raigon_art/core/provider/customer_and_order_provider.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/utils/image_url_helper.dart';
import 'package:raigon_art/core/widgets/app_image_viewer.dart';
import 'package:raigon_art/core/widgets/app_primary_button.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/core/widgets/customer_dialog_kit.dart';
import 'package:raigon_art/core/widgets/form_kit.dart';
import 'package:raigon_art/core/widgets/status_pill.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/customers/models/frame_spec.dart';
import 'package:raigon_art/features/customers/presentation/widgets/add_customer_dialog.dart';
import 'package:raigon_art/features/customers/service/customer_whatsapp_service.dart';

enum _ViewAction { edit }

Future<void> showViewCustomerDialog(
  BuildContext context,
  Customer customer,
) async {
  final action = await showCustomerDialog<_ViewAction>(
    context,
    label: 'View customer',
    builder: (_) => ViewCustomerDialog(customer: customer),
  );
  if (action == _ViewAction.edit && context.mounted) {
    final latest =
        context.read<CustomerAndOrderProvider>().findById(customer.id) ?? customer;
    await showEditCustomerDialog(context, latest);
  }
}

class _VaultPhoto {
  const _VaultPhoto({
    required this.name,
    required this.sizeLabel,
    required this.image,
    this.url,
  });

  final String name;
  final String sizeLabel;
  final ImageProvider image;
  final String? url;
}

void _showPhotoViewerDialog(
  BuildContext context,
  _VaultPhoto photo, {
  Customer? customer,
  int initialIndex = 0,
}) {
  if (customer != null) {
    showAppImageViewer(
      context: context,
      items: viewerItemsFromCustomer(customer),
      initialIndex: initialIndex,
    );
    return;
  }

  showSingleImageViewer(
    context: context,
    url: photo.url,
    title: photo.name,
    subtitle: photo.sizeLabel,
  );
}

List<_VaultPhoto> _photosOf(Customer c) {
  final photos = <_VaultPhoto>[];

  // 1. Show images stored in memory, if available.
  for (var i = 0; i < c.photoBytes.length; i++) {
    final bytes = c.photoBytes[i];
    final name =
        i < c.photoNames.length ? c.photoNames[i] : 'Photo_${i + 1}.jpg';
    final size = i < c.photoSizeLabels.length && c.photoSizeLabels[i].isNotEmpty
        ? c.photoSizeLabels[i]
        : PickedPhoto(name: name, bytes: bytes, size: bytes.length).sizeLabel;

    photos.add(
      _VaultPhoto(
        name: name,
        sizeLabel: size,
        image: MemoryImage(bytes),
      ),
    );
  }

  // 2. Show images loaded from REST API / Supabase Storage.
  for (var i = 0; i < c.photoUrls.length; i++) {
    final url = ImageUrlHelper.resolve(c.photoUrls[i]);
    if (url.trim().isEmpty) continue;
    final name =
        i < c.photoNames.length ? c.photoNames[i] : 'Photo_${i + 1}.webp';
    final size = i < c.photoSizeLabels.length && c.photoSizeLabels[i].isNotEmpty
        ? c.photoSizeLabels[i]
        : 'High-Res Vault Photo';

    if (!photos.any((p) => p.url == url || p.name == name)) {
      photos.add(
        _VaultPhoto(
          name: name,
          sizeLabel: size,
          image: NetworkImage(url),
          url: url,
        ),
      );
    }
  }

  // 3. Also include frame-specific photos if not already included
  for (var i = 0; i < c.frames.length; i++) {
    final frame = c.frames[i];
    if (frame.photoBytes != null) {
      final name = frame.photoName ?? 'Frame_${i + 1}.jpg';
      if (!photos.any((p) => p.name == name)) {
        photos.add(
          _VaultPhoto(
            name: name,
            sizeLabel: PickedPhoto(
              name: name,
              bytes: frame.photoBytes!,
              size: frame.photoBytes!.length,
            ).sizeLabel,
            image: MemoryImage(frame.photoBytes!),
          ),
        );
      }
    } else if (frame.photoUrl != null && frame.photoUrl!.isNotEmpty) {
      final url = ImageUrlHelper.resolve(frame.photoUrl!);
      if (url.trim().isNotEmpty) {
        final name = frame.photoName ?? 'Frame_${i + 1}.webp';
        if (!photos.any((p) => p.url == url || p.name == name)) {
          photos.add(
            _VaultPhoto(
              name: name,
              sizeLabel: 'Frame Photo',
              image: NetworkImage(url),
              url: url,
            ),
          );
        }
      }
    }
  }

  return photos;
}

String _inr(int v) {
  final s = v.abs().toString();
  String out;
  if (s.length <= 3) {
    out = s;
  } else {
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    out = '${parts.join(',')},$last3';
  }
  return '₹$out';
}

String _orDash(String s) => s.trim().isEmpty ? '—' : s.trim();

String _shortOrientation(String o) {
  final i = o.indexOf(' (');
  return i == -1 ? o : o.substring(0, i);
}

String _paymentLabel(Customer c) {
  if (c.paymentStatus != 'Unpaid') return c.paymentStatus;
  if (c.advance <= 0) return 'Unpaid';
  if (c.total > 0 && c.advance >= c.total) return 'Paid';
  return 'Partial';
}

class ViewCustomerDialog extends StatefulWidget {
  const ViewCustomerDialog({super.key, required this.customer});
  final Customer customer;

  @override
  State<ViewCustomerDialog> createState() => _ViewCustomerDialogState();
}

class _ViewCustomerDialogState extends State<ViewCustomerDialog> {
  final _scroll = ScrollController();
  late Customer _c;
  bool _isLoadingFresh = false;
  String? _freshError;

  static const _green = AppPalette.statusGreen;
  static const _red = Color(0xFFE0605E);

  @override
  void initState() {
    super.initState();
    _c = widget.customer;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFreshCustomerDetails();
    });
  }

  Future<void> _loadFreshCustomerDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoadingFresh = true;
      _freshError = null;
    });

    try {
      final fresh = await context
          .read<CustomerAndOrderProvider>()
          .fetchCustomerDetails(_c.id);
      if (mounted) {
        setState(() {
          _c = fresh;
          _isLoadingFresh = false;
        });
      }
    } catch (e) {
      debugPrint('[ViewCustomerDialog] Fetch customer details error: $e');
      if (mounted) {
        setState(() {
          _isLoadingFresh = false;
          _freshError = e is ApiException
              ? e.userFriendlyMessage
              : 'Could not load fresh details from server.';
        });
      }
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = FormColors.of(context);
    final p = c.p;
    return DialogBackdrop(
      maxWidth: 872,
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
    );
  }

  Widget _header(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 24, 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.iconDarkGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(RemixIcons.id_card_line, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Customer Order Profile & Summary',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    if (_isLoadingFresh) ...[
                      const SizedBox(width: 10),
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Syncing...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Complete details and workshop framing specifications',
                      style: TextStyle(fontSize: 13.5, color: p.textMuted),
                    ),
                    if (_freshError != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _loadFreshCustomerDetails,
                        child: Text(
                          '· Tap to retry sync',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE0605E),
                          ),
                        ),
                      ),
                    ],
                  ],
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
                border: Border.all(color: p.isDark ? p.border : p.border),
              ),
              child: Icon(RemixIcons.close_line, size: 21, color: p.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(FormColors c) {
    final p = c.p;
    final frames = _c.effectiveFrames;
    final photos = _photosOf(_c);
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
          padding: const EdgeInsets.fromLTRB(30, 26, 30, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _profileCard(c),
              const SizedBox(height: 21),
              LayoutBuilder(
                builder: (context, cons) {
                  final contact = _contactCard(c);
                  final summary = _summaryCard(c);
                  if (cons.maxWidth < 640) {
                    return Column(
                      children: [contact, const SizedBox(height: 21), summary],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: contact),
                      const SizedBox(width: 21),
                      Expanded(child: summary),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              _framesSection(c, frames, photos),
              const SizedBox(height: 36),
              _vault(c, photos),
              SizedBox(height: p.isDark ? 4 : 4),
            ],
          ),
        ),
      ),
    );
  }

  Color _highlightBg(AppPalette p) =>
      p.isDark ? const Color(0xFF383A66) : const Color(0xFFFBF8F1);

  Widget _profileCard(FormColors c) {
    final p = c.p;
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
      decoration: BoxDecoration(
        color: _highlightBg(p),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: p.isDark ? const Color(0xFF4B4D7E) : p.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.iconDarkGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              _c.name.isEmpty ? '?' : _c.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _idChip(p),
                    _infoChip(p, RemixIcons.phone_line, _c.phone),
                    _infoChip(p, RemixIcons.calendar_line, _c.orderDateLabel),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          StatusPill(status: _c.status),
        ],
      ),
    );
  }

  Widget _idChip(AppPalette p) {
    final fg = p.isDark ? const Color(0xFF9C9BF5) : AppPalette.statusGold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: p.isDark
            ? const Color(0xFF4A4C86)
            : AppColors.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: p.isDark
              ? const Color(0xFF5E60A0)
              : AppColors.gold.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(RemixIcons.id_card_line, size: 15, color: fg),
          const SizedBox(width: 7),
          Text(
            'ID: ${_c.id}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(AppPalette p, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: p.isDark ? const Color(0xFF2A2C46) : p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: p.isDark ? const Color(0xFF4A4C70) : p.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: p.textPrimary),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(FormColors c, {required Widget child, EdgeInsets? padding}) {
    final p = c.p;
    return Container(
      padding: padding ?? const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: p.isDark ? const Color(0xFF2E3050) : p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: p.isDark ? const Color(0xFF45477A) : p.border,
        ),
      ),
      child: child,
    );
  }

  Widget _cardTitle(AppPalette p, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.gold),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: p.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _contactCard(FormColors c) {
    final p = c.p;
    final cityPin = [
      _c.city.trim(),
      _c.pincode.trim(),
    ].where((s) => s.isNotEmpty).join(' - ');

    final rows = <(String, String)>[
      ('Primary Phone', _orDash(_c.phone)),
      ('Alt Phone', _orDash(_c.altPhone)),
      ('Delivery Address', _orDash(_c.address)),
      ('City & Pincode', _orDash(cityPin)),
    ];

    return _card(
      c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardTitle(p, RemixIcons.contacts_line, 'CUSTOMER CONTACT INFO'),
          const SizedBox(height: 14),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              SizedBox(
                height: 1,
                child: CustomPaint(painter: DashedLinePainter(p.rowDivider)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rows[i].$1,
                    style: TextStyle(fontSize: 15.5, color: p.textPrimary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryCard(FormColors c) {
    final p = c.p;
    final balance = _c.balance < 0 ? 0 : _c.balance;

    Widget tile({
      required String label,
      required String value,
      Color? labelColor,
      Color? valueColor,
      required Color bg,
      Color? border,
      double valueSize = 24,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border ?? p.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: labelColor ?? p.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.w800,
                color: valueColor ?? p.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    final neutral = p.isDark
        ? const Color(0xFF222439)
        : const Color(0xFFF5F3EE);
    final neutralBorder = p.isDark
        ? const Color(0xFF3A3C5A)
        : const Color(0xFFEDEAE2);
    final greenBg = Color.alphaBlend(
      _green.withValues(alpha: p.isDark ? 0.32 : 0.16),
      p.isDark ? const Color(0xFF2E3050) : p.surface,
    );
    final redBg = Color.alphaBlend(
      _red.withValues(alpha: p.isDark ? 0.34 : 0.16),
      p.isDark ? const Color(0xFF2E3050) : p.surface,
    );

    return _card(
      c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardTitle(p, RemixIcons.file_list_3_line, 'ORDER & PAYMENT SUMMARY'),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: tile(
                  label: 'TOTAL AMOUNT',
                  value: _inr(_c.total),
                  bg: neutral,
                  border: neutralBorder,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: tile(
                  label: 'ADVANCE PAID',
                  value: _inr(_c.advance),
                  labelColor: _green,
                  valueColor: _green,
                  bg: greenBg,
                  border: _green.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: tile(
                    label: 'BALANCE DUE',
                    value: _inr(balance),
                    labelColor: _red,
                    valueColor: _red,
                    bg: redBg,
                    border: _red.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: tile(
                    label: 'PAYMENT STATUS',
                    value: _paymentLabel(_c),
                    valueSize: 20,
                    bg: neutral,
                    border: neutralBorder,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _framesSection(
    FormColors c,
    List<FrameSpec> frames,
    List<_VaultPhoto> photos,
  ) {
    return LayoutBuilder(
      builder: (context, cons) {
        final isMulti = frames.length > 1;
        final isWide = cons.maxWidth >= 640 && isMulti;
        const gap = 20.0;
        final cardWidth = isWide ? (cons.maxWidth - gap) / 2 : cons.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < frames.length; i++)
              SizedBox(
                width: cardWidth,
                child: _individualFrameCard(c, frames, i, photos),
              ),
          ],
        );
      },
    );
  }

  Widget _individualFrameCard(
    FormColors c,
    List<FrameSpec> frames,
    int index,
    List<_VaultPhoto> photos,
  ) {
    final p = c.p;
    final f = frames[index];
    final single = frames.length == 1;
    final qty = single ? _c.qty : f.qty;

    // Resolve associated artwork photo for this frame
    _VaultPhoto? photo;
    int photoIndex = index;

    if (f.photoBytes != null) {
      photo = _VaultPhoto(
        name: f.photoName ?? 'Artwork #${index + 1}',
        sizeLabel:
            '${(f.photoBytes!.length / 1024 / 1024).toStringAsFixed(1)} MB',
        image: MemoryImage(f.photoBytes!),
      );
    } else if (f.photoUrl != null && f.photoUrl!.isNotEmpty) {
      final resolvedUrl = ImageUrlHelper.resolve(f.photoUrl!);
      final matchedIndex = photos.indexWhere((item) => item.url == resolvedUrl);
      if (matchedIndex != -1) {
        photo = photos[matchedIndex];
        photoIndex = matchedIndex;
      } else {
        photo = _VaultPhoto(
          name: f.photoName ??
              (index < photos.length ? photos[index].name : 'Artwork #${index + 1}'),
          sizeLabel: index < photos.length ? photos[index].sizeLabel : 'Artwork',
          image: NetworkImage(resolvedUrl),
          url: resolvedUrl,
        );
      }
    } else if (index < photos.length) {
      photo = photos[index];
      photoIndex = index;
    }

    return Container(
      decoration: BoxDecoration(
        color: p.isDark ? const Color(0xFF2E3050) : const Color(0xFFFCFAF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: p.isDark ? 0.35 : 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: p.isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (photo != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => _showPhotoViewerDialog(
                    context,
                    photo!,
                    customer: _c,
                    initialIndex: photoIndex,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.gold, width: 1.5),
                        ),
                        child: Image(
                          image: photo.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            RemixIcons.image_line,
                            color: p.textMuted,
                            size: 24,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            RemixIcons.zoom_in_line,
                            size: 11,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: p.isDark
                                  ? const Color(0xFF3D4068)
                                  : const Color(0xFFF0ECE1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: p.isDark
                                    ? const Color(0xFF555888)
                                    : const Color(0xFFE2DDD1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  RemixIcons.image_line,
                                  size: 13,
                                  color: p.textPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Photo #${photoIndex + 1}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: p.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            photo.sizeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: p.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => _showPhotoViewerDialog(
                    context,
                    photo!,
                    customer: _c,
                    initialIndex: photoIndex,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.darkGradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(RemixIcons.search_line, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'View',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: p.isDark
                  ? const Color(0xFF45477A)
                  : p.border.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
          ],
          _specRow(
            icon: RemixIcons.ruler_line,
            label: 'Frame Size:',
            value: f.sizeLabel,
            p: p,
          ),
          const SizedBox(height: 14),
          _specRow(
            icon: RemixIcons.shopping_bag_3_line,
            label: 'Frame Type & Material:',
            value: '${f.frameType} • ${f.material}',
            p: p,
          ),
          const SizedBox(height: 14),
          _specRow(
            icon: RemixIcons.palette_line,
            label: 'Color & Finish:',
            value: f.finish,
            p: p,
          ),
          const SizedBox(height: 14),
          _specRow(
            icon: RemixIcons.compass_3_line,
            label: 'Orientation & Qty:',
            value: '${_shortOrientation(f.orientation)} • $qty Frame(s)',
            p: p,
          ),
          if (f.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFDEFE0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: p.isDark ? Colors.transparent : const Color(0xFFF7DFC4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      RemixIcons.file_text_line,
                      size: 15,
                      color: Color(0xFFD27D2D),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f.notes.trim(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFC9722A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _specRow({
    required IconData icon,
    required String label,
    required String value,
    required AppPalette p,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: p.textPrimary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: p.textPrimary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _vault(FormColors c, List<_VaultPhoto> photos) {
    final p = c.p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardTitle(
          p,
          RemixIcons.gallery_line,
          'DIGITAL PHOTO VAULT (${photos.length})',
        ),
        const SizedBox(height: 18),
        if (photos.isEmpty)
          Text(
            'No photos uploaded for this order.',
            style: TextStyle(fontSize: 14.5, color: p.textMuted),
          )
        else
          LayoutBuilder(
            builder: (context, cons) {
              const gap = 21.0;
              final cols = (photos.length == 1 || cons.maxWidth < 560) ? 1 : 2;
              final w = (cons.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: 20,
                children: [
                  for (var i = 0; i < photos.length; i++)
                    SizedBox(
                      width: w,
                      child: _VaultCard(
                        photo: photos[i],
                        index: i,
                        customer: _c,
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _footer(FormColors c) {
    final p = c.p;

    return Container(
      width: double.infinity,
      color: c.footerBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppPrimaryButton(
            label: 'Edit Customer & Order',
            icon: RemixIcons.edit_line,
            onPressed: () {
              Navigator.of(context).pop(_ViewAction.edit);
            },
          ),
          const SizedBox(width: 10),

          InkWell(
            onTap: () async {
              try {
                final opened =
                    await CustomerWhatsAppService.openOrderConfirmation(_c);
                if (!mounted) return;
                if (opened) {
                  AppSnackBar.success(
                    context,
                    'WhatsApp opened with order receipt.',
                  );
                } else {
                  AppSnackBar.error(
                    context,
                    'Could not open WhatsApp. Check customer phone number.',
                  );
                }
              } catch (e) {
                if (!mounted) return;
                AppSnackBar.error(
                  context,
                  'Could not open WhatsApp for ${_c.name}.',
                );
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    RemixIcons.whatsapp_fill,
                    size: 16,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Send WhatsApp Receipt',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: p.isDark
                  ? BoxDecoration(
                      color: p.chipFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: p.border),
                    )
                  : null,
              child: Text(
                'Close',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VaultCard extends StatefulWidget {
  const _VaultCard({
    required this.photo,
    required this.index,
    this.customer,
  });
  final _VaultPhoto photo;
  final int index;
  final Customer? customer;

  @override
  State<_VaultCard> createState() => _VaultCardState();
}

class _VaultCardState extends State<_VaultCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final photo = widget.photo;
    final dark = p.isDark;

    final nameColor = dark ? const Color(0xFF111118) : p.textPrimary;
    final sizeColor = dark ? const Color(0xFF6E6E80) : p.textMuted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: dark ? null : const Color(0xFFFEFDFB),
          gradient: dark
              ? const LinearGradient(
                  colors: [Color(0xFF74748A), Color(0xFFD3D3DE)],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hover
                ? AppColors.gold
                : (dark ? const Color(0xFF8D8776) : p.border),
            width: _hover ? 1.6 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.2 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () => _showPhotoViewerDialog(
                context,
                photo,
                customer: widget.customer,
                initialIndex: widget.index,
              ),
              child: Container(
                width: 76,
                height: 76,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.7),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image(
                        image: photo.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: p.chipFill,
                          alignment: Alignment.center,
                          child: Icon(
                            RemixIcons.image_line,
                            size: 28,
                            color: p.textMuted,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(RemixIcons.zoom_in_line, size: 14, color: AppColors.gold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photo.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: nameColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: dark
                              ? AppColors.gold.withValues(alpha: 0.3)
                              : const Color(0xFFF4F1EA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              RemixIcons.image_fill,
                              size: 14,
                              color: dark ? AppColors.gold : p.textPrimary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Photo #${widget.index + 1}',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: dark ? AppColors.gold : p.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          photo.sizeLabel,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: sizeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showPhotoViewerDialog(
                context,
                photo,
                customer: widget.customer,
                initialIndex: widget.index,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.darkGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(RemixIcons.zoom_in_line, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'View',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
