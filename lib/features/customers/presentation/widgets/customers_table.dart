import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
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
    'SELECTED PHOTOS',
    'FRAME SIZE',
    'FRAME TYPE',
    'QTY',
    'ORDER STATUS',
    'ORDER DATE',
    'ACTIONS',
  ];
  static const _w = <double>[120, 230, 150, 220, 150, 160, 70, 170, 150];

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
                                      Icons.folder_open,
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
            Text(c.id, style: bold),

            Row(
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),

                      if (c.city.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          c.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: p.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            Text(c.phone, style: cell),

            PhotoStrip(
              count: c.photoCount,
              urls: c.photoUrls,
              bytes: c.photoBytes,
              seed: index,
            ),
            Text(
              c.frameSize,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cell,
            ),
            Text(
              c.frameType,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cell,
            ),
            Text('${c.qty}', style: bold),
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
                child: Icon(Icons.visibility, size: 21, color: p.textPrimary),
              ),
              const SizedBox(width: 10),
              _action(
                onTap: () => widget.onWhatsApp?.call(c),
                fill: AppColors.green.withValues(alpha: p.isDark ? 0.25 : 0.18),
                child: const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  size: 19,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 10),
              _action(
                onTap: () => widget.onEdit?.call(c),
                child: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              _action(
                onTap: () => widget.onDelete?.call(c),
                child: FaIcon(
                  FontAwesomeIcons.trash,
                  size: 17,
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
  });

  final int count;
  final List<String> urls;
  final List<Uint8List> bytes;
  final int seed;

  static const _tones = [
    Color(0xFFB9B3A8),
    Color(0xFFD9C7AE),
    Color(0xFFC6CEC6),
    Color(0xFFCF8F6E),
    Color(0xFF7A86A3),
    Color(0xFFE2D8D0),
  ];

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    if (count <= 0) {
      return Text(
        'No photos',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: p.textMuted),
      );
    }

    const thumbSize = 30.0;
    const gap = 3.0;
    const maxThumbs = 2;

    final shown = math.min(count, maxThumbs);
    final extra = count - shown;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown; i++) ...[
          if (i > 0) const SizedBox(width: gap),
          _thumb(i, thumbSize),
        ],
        if (extra > 0) ...[
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              '+$extra',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: p.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _thumb(int i, double size) {
    final url = i < urls.length ? urls[i] : '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: i < bytes.length
          ? Image.memory(bytes[i], fit: BoxFit.cover)
          : url.isEmpty
          ? ColoredBox(color: _tones[(seed + i) % _tones.length])
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  ColoredBox(color: _tones[(seed + i) % _tones.length]),
            ),
    );
  }
}
