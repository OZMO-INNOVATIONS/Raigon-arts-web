import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/utils/image_url_helper.dart';
import 'package:raigon_art/core/widgets/app_image_viewer.dart';
import 'package:raigon_art/core/widgets/status_pill.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';

class CustomersTable extends StatefulWidget {
  const CustomersTable({
    super.key,
    required this.customers,
    this.onView,
    this.onWhatsApp,
    this.onEdit,
    this.onDelete,
  });

  final List<Customer> customers;
  final ValueChanged<Customer>? onView;
  final ValueChanged<Customer>? onWhatsApp;
  final ValueChanged<Customer>? onEdit;
  final ValueChanged<Customer>? onDelete;

  @override
  State<CustomersTable> createState() => _CustomersTableState();
}

class _CustomersTableState extends State<CustomersTable> {
  final ScrollController _scroll = ScrollController();
  final ScrollController _vScroll = ScrollController();

  static const _labels = [
    'CUSTOMER ID',
    'CUSTOMER NAME',
    'PHONE NO',
    'CITY',
    'ORDER STATUS',
    'ORDER DATE',
    'ACTIONS',
  ];
  static const _w = <double>[140, 260, 170, 170, 180, 160];

  static const double _actionsMin = 200;
  static const double _hPad = 28;
  int _hoveredIndex = -1;

  @override
  void dispose() {
    _scroll.dispose();
    _vScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final fixed = _w.fold<double>(0, (a, b) => a + b);

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = math.max(
            constraints.maxWidth,
            fixed + _actionsMin + _hPad * 2,
          );

          return ScrollbarTheme(
            data: ScrollbarThemeData(
              thumbColor: const WidgetStatePropertyAll(AppColors.gold),
              trackColor: WidgetStatePropertyAll(
                AppColors.gold.withValues(alpha: 0.12),
              ),
              thickness: const WidgetStatePropertyAll(6),
              radius: const Radius.circular(3),
            ),
            child: Scrollbar(
              controller: _scroll,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _headerRow(p),
                      Expanded(
                        child: widget.customers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      RemixIcons.folder_open_line,
                                      size: 46,
                                      color: p.textMuted,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No customer records match '
                                      'your filter criteria.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: p.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Scrollbar(
                                controller: _vScroll,
                                thumbVisibility: true,
                                trackVisibility: true,
                                notificationPredicate: (notification) =>
                                    notification.metrics.axis == Axis.vertical,
                                child: SingleChildScrollView(
                                  controller: _vScroll,
                                  scrollDirection: Axis.vertical,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      for (
                                        var i = 0;
                                        i < widget.customers.length;
                                        i++
                                      )
                                        _row(p, widget.customers[i], i),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _cells(List<Widget> cells, Widget actions) => Row(
    children: [
      for (var i = 0; i < _w.length; i++)
        SizedBox(width: _w[i], child: cells[i]),
      Expanded(child: actions),
    ],
  );

  Widget _headerRow(AppPalette p) {
    final style = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: p.headerText,
    );
    return Container(
      color: p.tableHeaderBg,
      padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 22),
      child: _cells(
        [for (var i = 0; i < _w.length; i++) Text(_labels[i], style: style)],
        Align(
          alignment: Alignment.center,
          child: Text(_labels.last, style: style),
        ),
      ),
    );
  }

  Widget _row(AppPalette p, Customer c, int index) {
    final cell = TextStyle(fontSize: 15, color: p.textPrimary);
    final bold = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: p.textPrimary,
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: Container(
        decoration: BoxDecoration(
          color: _hoveredIndex == index
              ? (p.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFFCFBF8))
              : Colors.transparent,
          border: Border(top: BorderSide(color: p.rowDivider)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 16),
        child: _cells(
          [
            InkWell(
              onTap: () => widget.onView?.call(c),
              child: Text(c.id, style: bold),
            ),

            InkWell(
              onTap: () => widget.onView?.call(c),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.avatarBg,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Text(c.phone, style: cell),

            Text(
              c.city.trim().isNotEmpty ? c.city : '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cell,
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(status: c.status),
            ),

            Text(c.orderDateLabel, style: cell),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _action(
                onTap: () => widget.onView?.call(c),
                child: Icon(RemixIcons.eye_line, size: 20, color: p.textPrimary),
              ),
              const SizedBox(width: 10),
              _action(
                onTap: () => widget.onWhatsApp?.call(c),
                fill: AppColors.green.withValues(alpha: p.isDark ? 0.25 : 0.18),
                child: const Icon(
                  RemixIcons.whatsapp_fill,
                  size: 20,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 10),
              _action(
                onTap: () => widget.onEdit?.call(c),
                child: Icon(
                  RemixIcons.edit_line,
                  size: 20,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              _action(
                onTap: () => widget.onDelete?.call(c),
                child: Icon(
                  RemixIcons.delete_bin_line,
                  size: 19,
                  color: p.isDark ? p.textMuted : AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action({
    required VoidCallback onTap,
    required Widget child,
    Color? fill,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    ),
  );
}

class PhotoStrip extends StatelessWidget {
  const PhotoStrip({
    super.key,
    required this.count,
    required this.urls,
    required this.seed,
    this.bytes = const [],
    this.customer,
    this.onTap,
  });

  final int count;
  final List<String> urls;
  final List<Uint8List> bytes;
  final int seed;
  final Customer? customer;
  final VoidCallback? onTap;

  static const _tones = [
    Color(0xFFB9B3A8),
    Color(0xFFD9C7AE),
    Color(0xFFC6CEC6),
    Color(0xFFCF8F6E),
    Color(0xFF7A86A3),
    Color(0xFFE2D8D0),
  ];

  void _openViewer(BuildContext context, int initialIndex, List<String> validUrls) {
    if (customer != null) {
      showAppImageViewer(
        context: context,
        items: viewerItemsFromCustomer(customer!),
        initialIndex: initialIndex,
      );
      return;
    }

    final items = <AppViewerItem>[
      for (var i = 0; i < bytes.length; i++)
        AppViewerItem(bytes: bytes[i], title: 'Photo #${i + 1}'),
      for (var i = 0; i < validUrls.length; i++)
        AppViewerItem(url: validUrls[i], title: 'Artwork #${i + 1}'),
    ];

    if (items.isNotEmpty) {
      showAppImageViewer(
        context: context,
        items: items,
        initialIndex: initialIndex.clamp(0, items.length - 1),
      );
    } else {
      onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final validUrls = urls.where((u) => u.trim().isNotEmpty).toList();
    final effectiveCount =
        count > 0 ? count : math.max(validUrls.length, bytes.length);

    if (effectiveCount <= 0) {
      return Text(
        'No photos',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: p.textMuted),
      );
    }

    const thumbSize = 32.0;
    const gap = 4.0;
    const maxThumbs = 2;

    final shown = math.min(effectiveCount, maxThumbs);
    final extra = effectiveCount - shown;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown; i++) ...[
          if (i > 0) const SizedBox(width: gap),
          _thumb(context, i, thumbSize, p, validUrls),
        ],
        if (extra > 0) ...[
          const SizedBox(width: 4),
          Flexible(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _openViewer(context, shown, validUrls),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '+$extra',
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _thumb(
    BuildContext context,
    int i,
    double size,
    AppPalette p,
    List<String> validUrls,
  ) {
    final rawUrl =
        i < validUrls.length ? validUrls[i] : (i < urls.length ? urls[i] : '');
    final url = ImageUrlHelper.resolve(rawUrl);

    Widget imageWidget;
    if (i < bytes.length) {
      imageWidget = Image.memory(
        bytes[i],
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      );
    } else if (url.isNotEmpty) {
      imageWidget = Image.network(
        url,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: p.chipFill,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.gold,
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => Container(
          color: p.chipFill,
          alignment: Alignment.center,
          child: Icon(RemixIcons.image_line, size: 14, color: p.textMuted),
        ),
      );
    } else {
      imageWidget = ColoredBox(color: _tones[(seed + i) % _tones.length]);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: 'Click to view full photo',
        child: GestureDetector(
          onTap: () => _openViewer(context, i, validUrls),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.8),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: imageWidget,
          ),
        ),
      ),
    );
  }
}
