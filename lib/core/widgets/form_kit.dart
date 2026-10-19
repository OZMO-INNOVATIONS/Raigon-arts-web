import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';

class FormColors {
  FormColors._(this.p);
  final AppPalette p;

  static FormColors of(BuildContext context) =>
      FormColors._(AppPalette.of(context));

  bool get dark => p.isDark;
  Color get modalBg => p.surface;
  Color get footerBg => dark ? p.surface : const Color(0xFFF7F5F0);
  Color get textFill =>
      dark ? const Color(0xFF2E3047) : const Color(0xFFF9F7F2);
  Color get focusFill => dark ? const Color(0xFF35374F) : Colors.white;
  Color get textBorder =>
      dark ? const Color(0xFFE9E9F0) : const Color(0xFFE7E2D6);
  Color get dropFill => dark ? const Color(0xFF30324A) : Colors.white;
  Color get dropBorder =>
      dark ? const Color(0xFF4A4C68) : const Color(0xFFE7E2D6);
  Color get disabledFill =>
      dark ? const Color(0xFF2E3047) : const Color(0xFFF4F1EA);
  Color get sectionBg => dark ? const Color(0xFF4A4A52) : p.tableHeaderBg;
  Color get sectionText => dark ? AppColors.gold : p.textPrimary;
  Color get hint => dark ? const Color(0xFF9C9DB3) : const Color(0xFFA9A7B3);
  Color get dropzoneFill =>
      dark ? const Color(0xFF35374D) : const Color(0xFFFCFBF8);
  Color get selectedCardFill =>
      dark ? const Color(0xFF40425A) : const Color(0xFFFCFAF4);
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _monthsFull = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String fmtDate(DateTime d) =>
    '${_months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = FormColors.of(context);
    return Container(
      height: 54,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.sectionBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(width: 4, color: AppColors.gold),
          const SizedBox(width: 14),
          Icon(icon, size: 20, color: c.sectionText),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: c.sectionText,
            ),
          ),
        ],
      ),
    );
  }
}

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (required)
                const TextSpan(
                  text: '  *',
                  style: TextStyle(color: Color(0xFFE5484D)),
                ),
            ],
          ),
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class FormRow extends StatelessWidget {
  const FormRow({super.key, required this.children, this.flex, this.gap = 16});
  final List<Widget> children;
  final List<int>? flex;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                children[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(flex: flex?[i] ?? 1, child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

class AppTextBox extends StatefulWidget {
  const AppTextBox({
    super.key,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.readOnly = false,
    this.suffix,
    this.onChanged,
    this.dim = false,
  });

  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool readOnly;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final bool dim;

  @override
  State<AppTextBox> createState() => _AppTextBoxState();
}

class _AppTextBoxState extends State<AppTextBox> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = FormColors.of(context);
    final p = c.p;
    final focused = _focus.hasFocus && !widget.readOnly;
    final multiline = widget.maxLines != 1;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: multiline ? null : 46,
      constraints: multiline ? const BoxConstraints(minHeight: 84) : null,
      decoration: BoxDecoration(
        color: (widget.dim || widget.readOnly)
            ? c.disabledFill
            : (focused ? c.focusFill : c.textFill),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: focused ? AppColors.gold : c.textBorder,
          width: focused ? 1.4 : 1.2,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.28),
                  spreadRadius: 3,
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              readOnly: widget.readOnly,
              maxLines: widget.maxLines,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              onChanged: widget.onChanged,
              cursorColor: p.textPrimary,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: widget.readOnly ? p.textMuted : p.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: widget.hint,
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: c.hint,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: multiline ? 14 : 13,
                ),
              ),
            ),
          ),
          if (widget.suffix != null) widget.suffix!,
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.onUp,
    required this.onDown,
    this.enabled = true,
  });
  final VoidCallback onUp;
  final VoidCallback onDown;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = FormColors.of(context).p.textMuted;
    return SizedBox(
      width: 32,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: enabled ? onUp : null,
            child: Icon(Icons.keyboard_arrow_up, size: 17, color: color),
          ),
          InkWell(
            onTap: enabled ? onDown : null,
            child: Icon(Icons.keyboard_arrow_down, size: 17, color: color),
          ),
        ],
      ),
    );
  }
}

class NumberBox extends StatelessWidget {
  const NumberBox({
    super.key,
    required this.controller,
    this.hint,
    this.onChanged,
    this.min = 0,
    this.allowDecimal = false,
    this.readOnly = false,
    this.dim = false,
  });

  final TextEditingController controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final double min;
  final bool allowDecimal;
  final bool readOnly;
  final bool dim;

  void _bump(int delta) {
    final cur = double.tryParse(controller.text) ?? 0;
    var next = cur + delta;
    if (next < min) next = min;
    controller.text = next % 1 == 0 ? next.toInt().toString() : next.toString();
    onChanged?.call(controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AppTextBox(
      controller: controller,
      hint: hint,
      readOnly: readOnly,
      dim: dim,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(allowDecimal ? r'[0-9.]' : r'[0-9]'),
        ),
      ],
      suffix: _Stepper(
        enabled: !readOnly,
        onUp: () => _bump(1),
        onDown: () => _bump(-1),
      ),
    );
  }
}

class FormDropdown<T> extends StatefulWidget {
  const FormDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.hint,
    this.maxMenuHeight = 300,
  });

  final T? value;
  final List<T> items;
  final String Function(T item) labelOf;
  final ValueChanged<T> onChanged;
  final String? hint;
  final double maxMenuHeight;

  @override
  State<FormDropdown<T>> createState() => _FormDropdownState<T>();
}

class _FormDropdownState<T> extends State<FormDropdown<T>> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = FormColors.of(context);
    final p = c.p;
    return LayoutBuilder(
      builder: (context, cons) {
        return PopupMenuButton<T>(
          tooltip: '',
          position: PopupMenuPosition.under,
          offset: const Offset(0, 8),
          color: p.surface,
          elevation: 10,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: p.border),
          ),
          constraints: BoxConstraints(
            minWidth: cons.maxWidth,
            maxWidth: cons.maxWidth,
            maxHeight: widget.maxMenuHeight,
          ),
          onOpened: () => setState(() => _open = true),
          onCanceled: () => setState(() => _open = false),
          onSelected: (v) {
            setState(() => _open = false);
            widget.onChanged(v);
          },
          itemBuilder: (_) => [
            for (final item in widget.items)
              PopupMenuItem<T>(
                value: item,
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: item == widget.value ? p.avatarBg : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.labelOf(item),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: item == widget.value
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: c.dropFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _open ? AppColors.gold : c.dropBorder,
                width: _open ? 1.4 : 1.2,
              ),
              boxShadow: _open
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.28),
                        spreadRadius: 3,
                        blurRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.value == null
                        ? (widget.hint ?? 'Select an option')
                        : widget.labelOf(widget.value as T),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  _open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 22,
                  color: p.textPrimary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DateField extends StatefulWidget {
  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.showIcon = true,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool showIcon;

  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  void _toggle() {
    if (_entry != null) {
      _close();
      return;
    }
    final box = context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;
    final below = screenH - (pos.dy + box.size.height) > 420;
    _entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            targetAnchor: below ? Alignment.bottomLeft : Alignment.topLeft,
            followerAnchor: below ? Alignment.topLeft : Alignment.bottomLeft,
            offset: Offset(0, below ? 8 : -8),
            child: _CalendarCard(
              selected: widget.value,
              onPick: (d) {
                widget.onChanged(d);
                _close();
              },
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_entry!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = FormColors.of(context);
    final p = c.p;
    final open = _entry != null;
    return CompositedTransformTarget(
      link: _link,
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: c.textFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: open ? AppColors.gold : c.textBorder,
              width: open ? 1.4 : 1.2,
            ),
            boxShadow: open
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.28),
                      spreadRadius: 3,
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.value == null ? '' : fmtDate(widget.value!),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: p.textPrimary,
                  ),
                ),
              ),
              if (widget.showIcon)
                Icon(Icons.calendar_month, size: 20, color: p.textPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarCard extends StatefulWidget {
  const _CalendarCard({required this.selected, required this.onPick});
  final DateTime? selected;
  final ValueChanged<DateTime> onPick;

  @override
  State<_CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<_CalendarCard> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final base = widget.selected ?? DateTime.now();
    _month = DateTime(base.year, base.month);
  }

  void _shift(int d) =>
      setState(() => _month = DateTime(_month.year, _month.month + d));

  @override
  Widget build(BuildContext context) {
    final c = FormColors.of(context);
    final p = c.p;
    final first = DateTime(_month.year, _month.month, 1);
    final lead = first.weekday % 7;
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final prev = DateTime(_month.year, _month.month - 1);
    final prevDays = DateUtils.getDaysInMonth(prev.year, prev.month);
    final rows = ((lead + days) / 7).ceil();
    final today = DateUtils.dateOnly(DateTime.now());

    Widget cell(int i) {
      final dayIndex = i - lead + 1;
      final inMonth = dayIndex >= 1 && dayIndex <= days;
      final label = dayIndex < 1
          ? prevDays + dayIndex
          : dayIndex > days
          ? dayIndex - days
          : dayIndex;
      final date = DateTime(_month.year, _month.month, dayIndex);
      final isSel =
          inMonth &&
          widget.selected != null &&
          DateUtils.isSameDay(widget.selected, date);
      return SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => widget.onPick(DateUtils.dateOnly(date)),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isSel ? AppColors.darkGradient : null,
                borderRadius: BorderRadius.circular(8),
                border: (!isSel && inMonth && DateUtils.isSameDay(today, date))
                    ? Border.all(color: AppColors.gold)
                    : null,
              ),
              child: Text(
                '$label',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel
                      ? Colors.white
                      : inMonth
                      ? p.textPrimary
                      : p.textMuted.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget chip(String label, int plusDays) => InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => widget.onPick(
        DateUtils.dateOnly(DateTime.now()).add(Duration(days: plusDays)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: p.chipFill,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: p.textPrimary,
          ),
        ),
      ),
    );

    Widget navButton(IconData icon, VoidCallback onTap) => InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: p.chipFill, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: p.textPrimary),
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 322,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: p.isDark ? 0.45 : 0.16),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                navButton(Icons.chevron_left, () => _shift(-1)),
                Expanded(
                  child: Text(
                    '${_monthsFull[_month.month - 1]} ${_month.year}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                navButton(Icons.chevron_right, () => _shift(1)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final d in const [
                  'SU',
                  'MO',
                  'TU',
                  'WE',
                  'TH',
                  'FR',
                  'SA',
                ])
                  SizedBox(
                    width: 40,
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            for (var r = 0; r < rows; r++)
              Row(children: [for (var k = 0; k < 7; k++) cell(r * 7 + k)]),
            const SizedBox(height: 10),
            SizedBox(
              height: 1,
              width: double.infinity,
              child: CustomPaint(painter: DashedLinePainter(p.rowDivider)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                chip('Today', 0),
                chip('Tomorrow', 1),
                chip('+3 Days', 3),
                chip('+7 Days', 7),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  const DashedLinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
      x += 8;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter old) => old.color != color;
}

class DashedRRectPainter extends CustomPainter {
  const DashedRRectPainter({
    required this.color,
    this.radius = 14,
    this.dash = 7,
    this.gap = 5,
    this.strokeWidth = 1.6,
  });

  final Color color;
  final double radius;
  final double dash;
  final double gap;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          paint,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
