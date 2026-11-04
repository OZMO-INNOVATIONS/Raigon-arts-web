import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/models/status.dart';
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
import 'package:raigon_art/features/orders/presentation/widgets/order_progress_timeline.dart';
import 'package:raigon_art/features/reminders/presentation/widgets/add_reminder_dialog.dart';
import 'package:raigon_art/core/services/storage_service.dart';
import 'package:raigon_art/features/customers/presentation/widgets/order_voice_notes_section.dart';

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
    final latest = context
        .read<CustomerAndOrderProvider>()
        .customers
        .firstWhere((c) => c.id == customer.id, orElse: () => customer);
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
    final items = viewerItemsFromCustomer(customer);
    if (items.isNotEmpty) {
      showAppImageViewer(
        context: context,
        items: items,
        initialIndex: initialIndex.clamp(0, items.length - 1),
      );
      return;
    }
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
  final seenKeys = <String>{};

  void addVaultPhoto(_VaultPhoto p, [String? dedupeKey]) {
    final key = (dedupeKey != null && dedupeKey.isNotEmpty)
        ? dedupeKey.toLowerCase()
        : p.name.toLowerCase();
    if (seenKeys.contains(key)) return;
    seenKeys.add(key);
    photos.add(p);
  }

  // 1. If frames exist, resolve photo per frame without duplicate entries
  if (c.frames.isNotEmpty) {
    for (var i = 0; i < c.frames.length; i++) {
      final f = c.frames[i];
      final bytes =
          f.photoBytes ?? (i < c.photoBytes.length ? c.photoBytes[i] : null);
      final rawUrl = (f.photoUrl != null && f.photoUrl!.isNotEmpty)
          ? f.photoUrl
          : (i < c.photoUrls.length ? c.photoUrls[i] : null);
      final url = rawUrl != null && rawUrl.isNotEmpty
          ? ImageUrlHelper.resolve(rawUrl)
          : null;

      final name = (f.photoName != null && f.photoName!.isNotEmpty)
          ? f.photoName!
          : (i < c.photoNames.length && c.photoNames[i].isNotEmpty
                ? c.photoNames[i]
                : (url != null
                      ? url.split('?').first.split('/').last
                      : 'Artwork #${i + 1}'));

      final size =
          i < c.photoSizeLabels.length && c.photoSizeLabels[i].isNotEmpty
          ? c.photoSizeLabels[i]
          : (bytes != null
                ? PickedPhoto(
                    name: name,
                    bytes: bytes,
                    size: bytes.length,
                  ).sizeLabel
                : 'Artwork Photo');

      final key = url != null ? url.split('?').first.split('/').last : name;

      if (bytes != null) {
        addVaultPhoto(
          _VaultPhoto(
            name: name,
            sizeLabel: size,
            image: MemoryImage(bytes),
            url: url,
          ),
          key,
        );
      } else if (url != null && url.isNotEmpty) {
        addVaultPhoto(
          _VaultPhoto(
            name: name,
            sizeLabel: size,
            image: NetworkImage(url),
            url: url,
          ),
          key,
        );
      }
    }
  }

  // 2. Extra customer-level photos beyond frames (e.g. Same-frame mode with 1 spec & multiple photos)
  final maxExtra = math.max(c.photoBytes.length, c.photoUrls.length);
  for (var i = 0; i < maxExtra; i++) {
    final bytes = i < c.photoBytes.length ? c.photoBytes[i] : null;
    final rawUrl = i < c.photoUrls.length ? c.photoUrls[i] : null;
    final url = rawUrl != null && rawUrl.isNotEmpty
        ? ImageUrlHelper.resolve(rawUrl)
        : null;

    final name = i < c.photoNames.length && c.photoNames[i].isNotEmpty
        ? c.photoNames[i]
        : (url != null
              ? url.split('?').first.split('/').last
              : 'Photo_${i + 1}.jpg');

    final size = i < c.photoSizeLabels.length && c.photoSizeLabels[i].isNotEmpty
        ? c.photoSizeLabels[i]
        : (bytes != null
              ? PickedPhoto(
                  name: name,
                  bytes: bytes,
                  size: bytes.length,
                ).sizeLabel
              : 'Artwork Photo');

    final key = url != null ? url.split('?').first.split('/').last : name;

    if (bytes != null) {
      addVaultPhoto(
        _VaultPhoto(
          name: name,
          sizeLabel: size,
          image: MemoryImage(bytes),
          url: url,
        ),
        key,
      );
    } else if (url != null && url.isNotEmpty) {
      addVaultPhoto(
        _VaultPhoto(
          name: name,
          sizeLabel: size,
          image: NetworkImage(url),
          url: url,
        ),
        key,
      );
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

// String _shortOrientation(String o) {
//   final i = o.indexOf(' (');
//   return i == -1 ? o : o.substring(0, i);
// }

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
      final provider = context.read<CustomerAndOrderProvider>();
      final matches = provider.customers.where((c) => c.id == _c.id).toList();
      if (matches.isNotEmpty && mounted) {
        setState(() {
          _c = matches.first;
          _isLoadingFresh = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingFresh = false);
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

  Future<void> _updateVoiceNotes(List<OrderVoiceNote> newNotes) async {
    final updatedNotes = <OrderVoiceNote>[];
    for (var i = 0; i < newNotes.length; i++) {
      final vn = newNotes[i];
      if (vn.url.isEmpty &&
          vn.localBytes != null &&
          vn.localBytes!.isNotEmpty) {
        try {
          final fileName =
              'voice_order_${_c.id}_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.m4a';
          final uploaded = await StorageService().uploadFile(
            vn.localBytes!,
            fileName,
          );
          if (uploaded.fileUrl.isNotEmpty) {
            updatedNotes.add(vn.copyWith(url: uploaded.fileUrl));
            continue;
          }
        } catch (e) {
          debugPrint('[VoiceNoteUpload] $e');
        }
      }
      updatedNotes.add(vn);
    }
    final updatedCust = _c.copyWith(voiceNotes: updatedNotes);
    setState(() => _c = updatedCust);
    if (!mounted) return;
    try {
      await context.read<CustomerAndOrderProvider>().update(updatedCust);
      if (mounted) {
        AppSnackBar.success(context, 'Voice instructions updated.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to save voice instruction: $e');
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 560;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            isNarrow ? 16 : 28,
            isNarrow ? 16 : 22,
            isNarrow ? 14 : 24,
            isNarrow ? 14 : 20,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isNarrow ? 36 : 40,
                height: isNarrow ? 36 : 40,
                decoration: BoxDecoration(
                  gradient: AppColors.iconDarkGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  RemixIcons.id_card_line,
                  color: Colors.white,
                  size: isNarrow ? 19 : 22,
                ),
              ),
              SizedBox(width: isNarrow ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isNarrow
                                ? 'Customer Profile'
                                : 'Customer Order Profile & Summary',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isNarrow ? 17.5 : 21,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                          ),
                        ),
                        if (_isLoadingFresh) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.gold,
                            ),
                          ),
                          if (!isNarrow) ...[
                            const SizedBox(width: 6),
                            const Text(
                              'Syncing...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isNarrow ? 'Framing & order specifications' : 'Complete details and workshop framing specifications',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isNarrow ? 12 : 13.5,
                              color: p.textMuted,
                            ),
                          ),
                        ),
                        if (_freshError != null) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: _loadFreshCustomerDetails,
                            child: const Text(
                              '· Retry',
                              style: TextStyle(
                                fontSize: 12,
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
              const SizedBox(width: 10),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                customBorder: const CircleBorder(),
                child: Container(
                  width: isNarrow ? 38 : 44,
                  height: isNarrow ? 38 : 44,
                  decoration: BoxDecoration(
                    color: p.chipFill,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.border),
                  ),
                  child: Icon(
                    RemixIcons.close_line,
                    size: isNarrow ? 18 : 21,
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
    final frames = _c.effectiveFrames;
    final photos = _photosOf(_c);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 560;
        return ScrollbarTheme(
          data: const ScrollbarThemeData(
            thumbColor: WidgetStatePropertyAll(AppColors.gold),
            thickness: WidgetStatePropertyAll(6),
            radius: Radius.circular(3),
          ),
          child: Scrollbar(
            controller: _scroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(
                isNarrow ? 16 : 30,
                isNarrow ? 16 : 26,
                isNarrow ? 16 : 30,
                isNarrow ? 20 : 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _profileCard(c),
                  SizedBox(height: isNarrow ? 16 : 21),
                  _progressTimelineCard(c),
                  SizedBox(height: isNarrow ? 16 : 21),
                  LayoutBuilder(
                    builder: (context, cons) {
                      final contact = _contactCard(c);
                      final summary = _summaryCard(c);
                      if (cons.maxWidth < 640) {
                        return Column(
                          children: [
                            contact,
                            SizedBox(height: isNarrow ? 16 : 21),
                            summary,
                          ],
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
                  SizedBox(height: isNarrow ? 20 : 28),
                  _framesSection(c, frames, photos),
                  SizedBox(height: isNarrow ? 16 : 21),
                  OrderVoiceNotesSection(
                    voiceNotes: _c.voiceNotes,
                    onChanged: _updateVoiceNotes,
                    isEditable: true,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _highlightBg(AppPalette p) =>
      p.isDark ? const Color(0xFF383A66) : const Color(0xFFFBF8F1);

  Widget _progressTimelineCard(FormColors c) {
    final p = c.p;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.isDark ? const Color(0xFF2E3050) : const Color(0xFFFCFAF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: p.isDark ? 0.35 : 0.45),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderProgressTimeline(
            status: _c.status,
            customer: _c,
            statusHistory: _c.statusHistory,
            onStatusSelected: (newStatus) {
              context.read<CustomerAndOrderProvider>().setOrderStatus(
                _c,
                newStatus,
              );
              setState(() {
                _c = _c.copyWith(status: newStatus);
              });
            },
            onResumeOrder: () {
              context.read<CustomerAndOrderProvider>().setOrderStatus(
                _c,
                Status.confirmed,
              );
              setState(() {
                _c = _c.copyWith(status: Status.confirmed);
              });
            },
          ),
          if (_c.statusHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: p.border),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 8),
                Text(
                  'STATUS WORKFLOW HISTORY (${_c.statusHistory.length})',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: p.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final h in _c.statusHistory.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${h.previousStatus.label} → ${h.newStatus.label}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${h.updatedBy} • ${h.updatedAt.day}/${h.updatedAt.month}/${h.updatedAt.year}',
                      style: TextStyle(fontSize: 11, color: p.textMuted),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _profileCard(FormColors c) {
    final p = c.p;
    return LayoutBuilder(
      builder: (context, cons) {
        final isNarrow = cons.maxWidth < 540;
        final avatar = Container(
          width: isNarrow ? 48 : 56,
          height: isNarrow ? 48 : 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.iconDarkGradient,
            borderRadius: BorderRadius.circular(isNarrow ? 12 : 14),
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
            style: TextStyle(
              fontSize: isNarrow ? 22 : 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        );

        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _highlightBg(p),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: p.isDark ? const Color(0xFF4B4D7E) : p.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    avatar,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: p.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _idChip(p),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(status: _c.status),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _infoChip(p, RemixIcons.phone_line, _c.phone),
                    _infoChip(
                      p,
                      RemixIcons.calendar_line,
                      'Order Date: ${_c.orderDateLabel}',
                    ),
                    // _infoChip(
                    //   p,
                    //   RemixIcons.calendar_check_line,
                    //   'Expected Date: ${_c.expectedDateLabel}',
                    // ),

                    if (_c.effectiveRegion.isNotEmpty)
                      _infoChip(
                        p,
                        RemixIcons.map_pin_2_line,
                        'Region: ${_c.effectiveRegion}',
                      ),
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
          // decoration: BoxDecoration(
          //   color: _highlightBg(p),
          //   borderRadius: BorderRadius.circular(16),
          //   border: Border.all(
          //     color: p.isDark ? const Color(0xFF4B4D7E) : p.border,
          //   ),
          // ),
          decoration: BoxDecoration(
            color: p.isDark ? const Color(0xFF2E3050) : const Color(0xFFFCFAF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: p.isDark ? 0.35 : 0.45),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatar,
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
                        _infoChip(
                          p,
                          RemixIcons.calendar_line,
                          'Order Date: ${_c.orderDateLabel}',
                        ),
                        _expectedDateChip(p),
                        if (_c.effectiveRegion.isNotEmpty)
                          _infoChip(
                            p,
                            RemixIcons.map_pin_2_line,
                            'Region: ${_c.effectiveRegion}',
                          ),
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
      },
    );
  }

  Widget _idChip(AppPalette p) {
    final fg = p.isDark ? const Color(0xFF9C9BF5) : AppPalette.statusGold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
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
          Icon(RemixIcons.id_card_line, size: 13, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'ID: ${_c.id}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(AppPalette p, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          Icon(icon, size: 13.5, color: p.textPrimary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expectedDateChip(AppPalette p) {
    const green = Color(0xFF16A34A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: green.withValues(alpha: p.isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: green.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(RemixIcons.calendar_check_line, size: 13.5, color: green),
          const SizedBox(width: 6),
          Text(
            'Expected Date: ${_c.expectedDateLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: green,
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
        color: p.isDark ? const Color(0xFF2E3050) : const Color(0xFFFCFAF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: p.isDark ? 0.35 : 0.45),
          width: 1.2,
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 125,
                    child: Text(
                      rows[i].$1,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: p.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14.5,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: labelColor ?? p.textMuted,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? p.textPrimary,
                ),
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

  Widget _sameFrameSection(
    FormColors c,
    FrameSpec f,
    List<_VaultPhoto> photos,
  ) {
    final p = c.p;
    final qty = _c.qty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: p.isDark ? const Color(0xFF2E3050) : const Color(0xFFFCFAF5),
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
              _cardTitle(p, RemixIcons.stack_line, 'ORDER NOTES'),
              const SizedBox(height: 18),

              _specRow(
                icon: RemixIcons.ruler_line,
                label: 'Frame Size & Dimensions:',
                value: f.formattedDimensions,
                p: p,
              ),
              _dashedDivider(p),
              _specRow(
                icon: RemixIcons.compass_3_line,
                label: 'Total Qty:',
                value: '$qty Frame${qty == 1 ? '' : 's'}',
                p: p,
              ),
              if (f.notes.isNotEmpty) ...[
                _dashedDivider(p),
                _specRow(
                  icon: RemixIcons.file_text_line,
                  label: 'Frame Notes:',
                  value: f.notes,
                  p: p,
                ),
              ],
              if (photos.isNotEmpty) ...[
                const SizedBox(height: 20),
                _dashedDivider(p),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      RemixIcons.image_line,
                      size: 16,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ATTACHED ARTWORKS (${photos.length})',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: p.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < photos.length; i++)
                      InkWell(
                        onTap: () => _showPhotoViewerDialog(
                          context,
                          photos[i],
                          customer: _c,
                          initialIndex: i,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: p.chipFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: p.border.withValues(alpha: 0.8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                child: Image(
                                  image: photos[i].image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: p.chipFill,
                                    child: Icon(
                                      RemixIcons.image_line,
                                      color: p.textMuted,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 150,
                                    ),
                                    child: Text(
                                      photos[i].name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: p.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    photos[i].sizeLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: p.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _framesSection(
    FormColors c,
    List<FrameSpec> frames,
    List<_VaultPhoto> photos,
  ) {
    final p = c.p;
    if (frames.isEmpty && photos.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isSameFrame = frames.length <= 1;

    if (isSameFrame && frames.isNotEmpty) {
      return _sameFrameSection(c, frames.first, photos);
    }

    final int cardCount = frames.isNotEmpty ? frames.length : photos.length;
    if (cardCount == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // _individualFrameHeaderBanner(p, cardCount),
        // const SizedBox(height: 22),
        _cardTitle(p, RemixIcons.stack_line, 'INDIVIDUAL ORDER NOTES'),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, cons) {
            final isMulti = cardCount > 1;
            final isWide = cons.maxWidth >= 640 && isMulti;
            const gap = 20.0;
            final cardWidth = isWide
                ? (cons.maxWidth - gap) / 2
                : cons.maxWidth;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < cardCount; i++)
                  SizedBox(
                    width: cardWidth,
                    child: _individualFrameCard(c, frames, i, photos),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Widget _individualFrameHeaderBanner(AppPalette p, int count) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  //     decoration: BoxDecoration(
  //       color: p.isDark ? const Color(0xFF2E3050) : const Color(0xFFFCFAF5),
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(
  //         color: AppColors.gold.withValues(alpha: p.isDark ? 0.4 : 0.45),
  //         width: 1.2,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha: p.isDark ? 0.2 : 0.04),
  //           blurRadius: 10,
  //           offset: const Offset(0, 3),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         LayoutBuilder(
  //           builder: (_, bannerConstraints) {
  //             final isBannerNarrow = bannerConstraints.maxWidth < 460;
  //             final badge = Container(
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 12,
  //                 vertical: 6,
  //               ),
  //               decoration: BoxDecoration(
  //                 gradient: const LinearGradient(
  //                   colors: [
  //                     Color(0xFF1E1D1B),
  //                     Color(0xFF332D24),
  //                     Color(0xFF6B5838),
  //                   ],
  //                 ),
  //                 borderRadius: BorderRadius.circular(10),
  //                 border: Border.all(
  //                   color: AppColors.gold.withValues(alpha: 0.55),
  //                   width: 1.2,
  //                 ),
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color: Colors.black.withValues(alpha: 0.3),
  //                     blurRadius: 6,
  //                     offset: const Offset(0, 2),
  //                   ),
  //                 ],
  //               ),
  //               child: Row(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   const Icon(
  //                     RemixIcons.equalizer_line,
  //                     size: 14,
  //                     color: Colors.white,
  //                   ),
  //                   const SizedBox(width: 6),
  //                   Text(
  //                     '$count Custom Frame${count == 1 ? '' : 's'}',
  //                     style: const TextStyle(
  //                       fontSize: 12.5,
  //                       fontWeight: FontWeight.w700,
  //                       color: Colors.white,
  //                       letterSpacing: 0.3,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             );

  //             // final headerTitle = Row(
  //             //   children: [
  //             //     const Icon(
  //             //       RemixIcons.stack_line,
  //             //       size: 19,
  //             //       color: AppColors.gold,
  //             //     ),
  //             //     // const SizedBox(width: 8),
  //             //     // Expanded(
  //             //     //   child: Text(
  //             //     //     'INDIVIDUAL FRAME SPECIFICATIONS CONFIGURED',
  //             //     //     style: TextStyle(
  //             //     //       fontSize: 13.5,
  //             //     //       fontWeight: FontWeight.w800,
  //             //     //       letterSpacing: 0.5,
  //             //     //       color: p.textPrimary,
  //             //     //     ),
  //             //     //   ),
  //             //     // ),
  //             //   ],
  //             // );

  //             // if (isBannerNarrow) {
  //             //   return Column(
  //             //     crossAxisAlignment: CrossAxisAlignment.start,
  //             //     children: [headerTitle, const SizedBox(height: 10), badge],
  //             //   );
  //             // }

  //             // return Row(
  //             //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             //   crossAxisAlignment: CrossAxisAlignment.center,
  //             //   children: [
  //             //     Expanded(child: headerTitle),
  //             //     const SizedBox(width: 12),
  //             //     badge,
  //             //   ],
  //             // );
  //           },
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           'Each photo below has its own distinct frame size, material, color, and mounting specifications configured.',
  //           style: TextStyle(
  //             fontSize: 12.5,
  //             fontWeight: FontWeight.w400,
  //             color: p.textMuted,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _individualFrameCard(
    FormColors c,
    List<FrameSpec> frames,
    int index,
    List<_VaultPhoto> photos,
  ) {
    final p = c.p;
    final f = index < frames.length ? frames[index] : frames.first;
    final single = frames.length == 1;
    final qty = single ? _c.qty : f.qty;

    // Resolve associated artwork photo for this frame
    _VaultPhoto? photo;
    int photoIndex = index;

    if (f.photoBytes != null) {
      photo = _VaultPhoto(
        name:
            f.photoName ??
            (index < photos.length
                ? photos[index].name
                : 'Artwork #${index + 1}'),
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
          name:
              f.photoName ??
              (index < photos.length
                  ? photos[index].name
                  : 'Artwork #${index + 1}'),
          sizeLabel: index < photos.length
              ? photos[index].sizeLabel
              : 'Artwork',
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
        color: p.isDark ? const Color(0xFF2E3050) : const Color(0xFFFCFAF5),
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
          LayoutBuilder(
            builder: (_, cardConstraints) {
              final isCardNarrow = cardConstraints.maxWidth < 420;

              final thumbWidget = InkWell(
                onTap: photo == null
                    ? null
                    : () => _showPhotoViewerDialog(
                        context,
                        photo!,
                        customer: _c,
                        initialIndex: photoIndex,
                      ),
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      child: photo != null
                          ? Image(
                              image: photo.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: p.chipFill,
                                child: Icon(
                                  RemixIcons.image_line,
                                  color: p.textMuted,
                                  size: 24,
                                ),
                              ),
                            )
                          : Container(
                              color: p.chipFill,
                              child: Icon(
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
                          color: Colors.black.withValues(alpha: 0.7),
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
              );

              final infoWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photo?.name ?? 'Artwork #${index + 1}',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
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
                      Text(
                        photo?.sizeLabel ?? '0.0 MB',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: p.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              );

              final viewButton = InkWell(
                onTap: photo == null
                    ? null
                    : () => _showPhotoViewerDialog(
                        context,
                        photo!,
                        customer: _c,
                        initialIndex: photoIndex,
                      ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E1D1B),
                        Color(0xFF383126),
                        Color(0xFF7A6237),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        RemixIcons.search_line,
                        size: 13,
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'View Photo',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              if (isCardNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        thumbWidget,
                        const SizedBox(width: 12),
                        Expanded(child: infoWidget),
                      ],
                    ),
                    const SizedBox(height: 10),
                    viewButton,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  thumbWidget,
                  const SizedBox(width: 14),
                  Expanded(child: infoWidget),
                  const SizedBox(width: 10),
                  viewButton,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _dashedDivider(p),
          _specRow(
            icon: RemixIcons.ruler_line,
            label: 'Frame Size & Dimensions:',
            value: f.formattedDimensions,
            p: p,
          ),
          // _dashedDivider(p),
          // _specRow(
          //   icon: RemixIcons.shopping_bag_3_line,
          //   label: 'Frame Type & Material:',
          //   value: '${f.frameType} • ${f.material}',
          //   p: p,
          // ),
          // _dashedDivider(p),
          // _specRow(
          //   icon: RemixIcons.palette_line,
          //   label: 'Color & Finish:',
          //   value: f.finish,
          //   p: p,
          // ),
          _dashedDivider(p),
          _specRow(
            icon: RemixIcons.compass_3_line,
            label: 'Quantity:',
            value:
                // '${_shortOrientation(f.orientation)} • $qty Frame(s)',
                "$qty Frame(s)",
            p: p,
          ),
          if (f.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: p.isDark
                    ? const Color(0xFF383A66)
                    : const Color(0xFFFCF6ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: p.isDark
                      ? Colors.transparent
                      : const Color(0xFFF2DFC6),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    RemixIcons.file_text_fill,
                    size: 15,
                    color: p.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notes: ${f.notes.trim()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: p.textPrimary,
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

  Widget _dashedDivider(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 1,
        child: CustomPaint(painter: DashedLinePainter(p.rowDivider)),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 15, color: p.textPrimary),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: p.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _footer(FormColors c) {
    final p = c.p;

    return LayoutBuilder(
      builder: (_, constraints) {
        final isNarrow = constraints.maxWidth < 560;

        final editButton = AppPrimaryButton(
          label: isNarrow ? 'Edit Order' : 'Edit Customer & Order',
          icon: RemixIcons.edit_line,
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 12 : 22,
            vertical: 14,
          ),
          onPressed: () {
            Navigator.of(context).pop(_ViewAction.edit);
          },
        );

        final whatsAppButton = InkWell(
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
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 12 : 22,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  RemixIcons.whatsapp_fill,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isNarrow ? 'WhatsApp' : 'Send WhatsApp Receipt',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        final remindButton = InkWell(
          onTap: () => showAddOrEditReminderDialog(
            context: context,
            initialCustomer: _c,
          ),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 12 : 18,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: p.isDark ? 0.18 : 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: p.isDark ? 0.45 : 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  RemixIcons.alarm_line,
                  size: 16,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 6),
                Text(
                  isNarrow ? 'Remind' : 'Set Reminder',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        );

        final closeButton = InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: p.isDark
                ? BoxDecoration(
                    color: p.chipFill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.border),
                  )
                : BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.border),
                  ),
            child: Text(
              'Close',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ),
        );

        if (isNarrow) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: c.footerBg,
              border: Border(
                top: BorderSide(
                  color: p.isDark
                      ? const Color(0xFF383A66)
                      : p.border.withValues(alpha: 0.6),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: p.isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(child: editButton),
                const SizedBox(width: 8),
                Expanded(child: whatsAppButton),
                const SizedBox(width: 8),
                remindButton,
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: c.footerBg,
            border: Border(
              top: BorderSide(
                color: p.isDark
                    ? const Color(0xFF383A66)
                    : p.border.withValues(alpha: 0.6),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: p.isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [editButton, whatsAppButton, remindButton, closeButton],
          ),
        );
      },
    );
  }
}
