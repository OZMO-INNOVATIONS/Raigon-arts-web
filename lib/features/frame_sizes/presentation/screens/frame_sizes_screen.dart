import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';

import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/app_dropdown.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/core/network/api_exception.dart';
import 'package:raigon_art/core/provider/customer_and_order_provider.dart';
import 'package:raigon_art/features/frame_sizes/models/frame_size_model.dart';
import 'package:raigon_art/features/frame_sizes/providers/frame_size_provider.dart';

const _units = ['Inch', 'CM'];
const _categories = [
  'Standard Photo',
  'Medium Portrait',
  'Large Gallery',
  'Exhibition Wall Art',
  'Custom Size',
];

String _num(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

class FrameSizesScreen extends StatefulWidget {
  const FrameSizesScreen({super.key});

  @override
  State<FrameSizesScreen> createState() => _FrameSizesScreenState();
}

class _FrameSizesScreenState extends State<FrameSizesScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final custProvider = context.read<CustomerAndOrderProvider>();
      if (custProvider.customers.isNotEmpty) {
        context.read<FrameSizeProvider>().syncCountsWithCustomers(custProvider.customers);
      }
      final frameProvider = context.read<FrameSizeProvider>();
      if (!frameProvider.initialized && !frameProvider.isLoading) {
        frameProvider.init();
      } else {
        frameProvider.refresh().catchError((_) {});
      }
    });
  }

  static const _flex = [13, 15, 10, 11, 19, 19, 17, 19, 10];
  static const _heads = [
    'SIZE CODE',
    'SIZE NAME',
    'WIDTH',
    'HEIGHT',
    'UNIT',
    'CATEGORY',
    'ORDERS COUNT',
    'STATUS',
    'ACTIONS',
  ];

  Future<void> _add() async {
    final result = await _showBlurDialog<FrameSize>(
      context,
      (_) => const _FrameSizeDialog(),
    );

    if (result == null || !mounted) return;

    final provider = context.read<FrameSizeProvider>();

    try {
      await provider.add(
        FrameSize(
          code: provider.nextCode(),
          name: result.name,
          width: result.width,
          height: result.height,
          unit: result.unit,
          category: result.category,
        ),
      );

      if (!mounted) return;
      AppSnackBar.success(context, 'Material added successfully.');
    } catch (error) {
      if (!mounted) return;
      final msg = error is ApiException
          ? error.userFriendlyMessage
          : 'Could not add material. Try again.';
      AppSnackBar.error(context, msg);
    }
  }

  Future<void> _edit(FrameSize size) async {
    final result = await _showBlurDialog<FrameSize>(
      context,
      (_) => _FrameSizeDialog(initial: size),
    );

    if (result == null || !mounted) return;

    try {
      await context.read<FrameSizeProvider>().update(
        FrameSize(
          code: size.code,
          name: result.name,
          width: result.width,
          height: result.height,
          unit: result.unit,
          category: result.category,
          orders: size.orders,
          active: size.active,
        ),
      );

      if (!mounted) return;
      AppSnackBar.success(context, 'Material updated successfully.');
    } catch (error) {
      if (!mounted) return;
      final msg = error is ApiException
          ? error.userFriendlyMessage
          : 'Could not update material. Try again.';
      AppSnackBar.error(context, msg);
    }
  }

  Future<void> _delete(FrameSize size) async {
    final confirmed = await _showBlurDialog<bool>(
      context,
      (_) => _DeleteDialog(size: size),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<FrameSizeProvider>().remove(size.code);

      if (!mounted) return;
      AppSnackBar.success(context, 'Material deleted successfully.');
    } catch (error) {
      if (!mounted) return;
      final msg = error is ApiException
          ? error.userFriendlyMessage
          : 'Could not delete material. Try again.';
      AppSnackBar.error(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final provider = context.watch<FrameSizeProvider>();
    final list = provider.filteredSizes;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _titleRow(p),
          const SizedBox(height: 24),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: p.card(radius: 16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 340,
                          height: 44,
                          child: TextField(
                            onChanged: context
                                .read<FrameSizeProvider>()
                                .setQuery,
                            cursorColor: p.textPrimary,
                            style: TextStyle(
                              fontSize: 14.5,
                              color: p.textPrimary,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Search size name, category...',
                              hintStyle: TextStyle(
                                fontSize: 14.5,
                                color: p.textMuted,
                              ),
                              prefixIcon: Icon(
                                RemixIcons.search_line,
                                size: 22,
                                color: p.textMuted,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: p.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text.rich(
                          TextSpan(
                            text: 'Total Sizes: ',
                            style: TextStyle(
                              fontSize: 14.5,
                              color: p.textMuted,
                            ),
                            children: [
                              TextSpan(
                                text: '${provider.sizes.length}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: p.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (provider.isLoading && provider.initialized)
                    const LinearProgressIndicator(
                      color: AppColors.gold,
                      backgroundColor: Colors.transparent,
                      minHeight: 3,
                    ),

                  if (provider.isLoading && !provider.initialized)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      ),
                    )
                  else if (provider.error != null && provider.sizes.isEmpty)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(RemixIcons.cloud_off_line, size: 48, color: AppColors.error),
                              const SizedBox(height: 14),
                              Text(
                                'Failed to load materials catalog',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: p.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                provider.error is ApiException
                                    ? (provider.error as ApiException).userFriendlyMessage
                                    : 'Please check your connection to the server.',
                                style: TextStyle(fontSize: 14, color: p.textMuted),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.read<FrameSizeProvider>().refresh().then((_) {
                                    if (context.mounted) {
                                      AppSnackBar.success(context, 'Materials loaded.');
                                    }
                                  }).catchError((e) {
                                    if (context.mounted) {
                                      final msg = e is ApiException ? e.userFriendlyMessage : 'Retry failed.';
                                      AppSnackBar.error(context, msg);
                                    }
                                  });
                                },
                                icon: const Icon(RemixIcons.refresh_line, size: 16),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(child: _table(p, list, provider)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleRow(AppPalette p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Material & Size Management',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Catalog of wholesale frame materials, dimensions & specs',
                style: TextStyle(fontSize: 14.5, color: p.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _GradientButton(
          icon: RemixIcons.add_line,
          label: 'Add Material',
          onTap: _add,
          fontSize: 15.5,
          vPad: 14,
        ),
      ],
    );
  }

  Widget _table(AppPalette p, List<FrameSize> list, FrameSizeProvider provider) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = math.max(c.maxWidth, 1100.0);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: w,
            child: Column(
              children: [
                Container(
                  height: 48,
                  color: p.tableHeaderBg,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      for (var i = 0; i < _heads.length; i++)
                        Expanded(
                          flex: _flex[i],
                          child: Text(
                            _heads[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                              color: p.headerText,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      'No materials found',
                      style: TextStyle(fontSize: 15, color: p.textMuted),
                    ),
                  )
                else
                  for (final s in list)
                    _SizeRow(
                      p: p,
                      size: s,
                      flex: _flex,
                      onEdit: () => _edit(s),
                      onDelete: () => _delete(s),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SizeRow extends StatefulWidget {
  const _SizeRow({
    required this.p,
    required this.size,
    required this.flex,
    required this.onEdit,
    required this.onDelete,
  });

  final AppPalette p;
  final FrameSize size;
  final List<int> flex;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_SizeRow> createState() => _SizeRowState();
}

class _SizeRowState extends State<_SizeRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final s = widget.size;
    final f = widget.flex;

    Widget cell(int i, Widget child) => Expanded(
      flex: f[i],
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
    TextStyle t(FontWeight w) =>
        TextStyle(fontSize: 15, fontWeight: w, color: p.textPrimary);

    final statusColor = s.active
        ? AppPalette.statusGreen
        : AppPalette.statusRed;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: _hover
              ? (p.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF8F6F1))
              : Colors.transparent,
          border: Border(top: BorderSide(color: p.rowDivider)),
        ),
        child: Row(
          children: [
            cell(0, Text(s.code, style: t(FontWeight.w700))),
            cell(1, Text(s.name, style: t(FontWeight.w700))),
            cell(2, Text(_num(s.width), style: t(FontWeight.w500))),
            cell(3, Text(_num(s.height), style: t(FontWeight.w500))),
            cell(
              4,
              Container(
                width: 120,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.chipFill,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.unit.toLowerCase(),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
              ),
            ),
            cell(5, Text(s.category, style: t(FontWeight.w500))),
            cell(6, Text('${s.orders} orders', style: t(FontWeight.w500))),
            cell(
              7,
              Container(
                width: 120,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s.active ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ),
            cell(
              8,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iconBtn(
                    RemixIcons.edit_line,
                    p.textPrimary,
                    widget.onEdit,
                    'Edit',
                  ),
                  const SizedBox(width: 4),
                  _iconBtn(
                    RemixIcons.delete_bin_line,
                    p.textPrimary,
                    widget.onDelete,
                    'Delete',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData i, Color c, VoidCallback onTap, String tip) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Tooltip(
        message: tip,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(i, size: 20, color: c),
        ),
      ),
    );
  }
}


class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.fontSize = 15,
    this.vPad = 13,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final double fontSize;
  final double vPad;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppColors.darkGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: vPad),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: Colors.white),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> _showBlurDialog<T>(BuildContext context, WidgetBuilder builder) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dialog',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    transitionBuilder: (_, a, _, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(
        scale: Tween(
          begin: 0.97,
          end: 1.0,
        ).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
        child: child,
      ),
    ),
    pageBuilder: (ctx, _, _) {
      final dark = AppPalette.of(ctx).isDark;
      return Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(ctx).pop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                  child: Container(
                    color: Colors.black.withValues(alpha: dark ? 0.45 : 0.48),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: builder(ctx),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _DialogShell extends StatelessWidget {
  const _DialogShell({
    required this.maxWidth,
    required this.title,
    required this.body,
    required this.footer,
    this.subtitle,
    this.leading,
  }) : onClose = null;

  final double maxWidth;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget body;
  final Widget footer;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final footerBg = p.isDark
        ? const Color(0xFF23253A)
        : const Color(0xFFF4F2ED);
    return GestureDetector(
      onTap: () {},
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(20),
          border: p.isDark ? Border.all(color: p.border) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                leading != null ? 28 : 28,
                subtitle != null ? 24 : 20,
                24,
                subtitle != null ? 22 : 18,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 16)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: TextStyle(fontSize: 13, color: p.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onClose ?? () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.avatarBg,
                        border: Border.all(color: p.border),
                      ),
                      child: Icon(RemixIcons.close_line, size: 18, color: p.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: p.border),
            Flexible(child: SingleChildScrollView(child: body)),
            Container(
              color: footerBg,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: footer,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _cancelButton(BuildContext context, AppPalette p) {
  return InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: () => Navigator.of(context).pop(),
    child: Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: p.isDark
          ? BoxDecoration(
              color: const Color(0xFF30324A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: p.border),
            )
          : null,
      child: Text(
        'Cancel',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: p.textPrimary,
        ),
      ),
    ),
  );
}

class _FrameSizeDialog extends StatefulWidget {
  const _FrameSizeDialog({this.initial});
  final FrameSize? initial;

  @override
  State<_FrameSizeDialog> createState() => _FrameSizeDialogState();
}

class _FrameSizeDialogState extends State<_FrameSizeDialog> {
  late final TextEditingController _name;
  late final TextEditingController _w;
  late final TextEditingController _h;
  late String _unit;
  late String _category;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i?.name ?? '');
    _w = TextEditingController(text: i == null ? '' : _num(i.width));
    _h = TextEditingController(text: i == null ? '' : _num(i.height));
    _unit = i?.unit ?? _units.first;
    _category = i?.category ?? _categories.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _w.dispose();
    _h.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    final v = double.tryParse(c.text.trim());
    return (v != null && v > 0) ? v : null;
  }

  void _step(TextEditingController c, int d) {
    final cur = double.tryParse(c.text.trim()) ?? 0;
    final next = math.max(0, cur + d).toDouble();
    setState(() => c.text = _num(next));
  }

  void _save() {
    setState(() => _submitted = true);
    final w = _parse(_w);
    final h = _parse(_h);
    if (_name.text.trim().isEmpty || w == null || h == null) return;
    Navigator.of(context).pop(
      FrameSize(
        code: widget.initial?.code ?? '',
        name: _name.text.trim(),
        width: w,
        height: h,
        unit: _unit,
        category: _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final edit = widget.initial != null;
    return _DialogShell(
      maxWidth: 520,
      title: edit
          ? 'Edit Material (${widget.initial!.code})'
          : 'Add New Material',
      subtitle: 'Configure workshop material dimensions & category',
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: AppColors.darkGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(RemixIcons.ruler_line, size: 22, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(p, 'Size Name / Label', required: true),
            const SizedBox(height: 10),
            _field(
              p,
              controller: _name,
              hint: 'e.g. 12 × 18 inch',
              invalid: _submitted && _name.text.trim().isEmpty,
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(p, 'Width', required: true),
                      const SizedBox(height: 10),
                      _field(
                        p,
                        controller: _w,
                        hint: '12',
                        number: true,
                        invalid: _submitted && _parse(_w) == null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(p, 'Height', required: true),
                      const SizedBox(height: 10),
                      _field(
                        p,
                        controller: _h,
                        hint: '18',
                        number: true,
                        invalid: _submitted && _parse(_h) == null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _label(p, 'Measurement Unit'),
            const SizedBox(height: 8),
            _dropdown<String>(
              value: _unit,
              items: _units,
              onChanged: (v) => setState(() => _unit = v),
            ),
            const SizedBox(height: 14),
            _label(p, 'Category'),
            const SizedBox(height: 8),
            _dropdown<String>(
              value: _category,
              items: _categories,
              onChanged: (v) => setState(() => _category = v),
            ),
          ],
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _cancelButton(context, p),
          const SizedBox(width: 14),
          _GradientButton(
            icon: RemixIcons.check_line,
            label: 'Save Material',
            onTap: _save,
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T> onChanged,
  }) {
    return LayoutBuilder(
      builder: (context, c) => SizedBox(
        height: 52,
        child: OverflowBox(
          minWidth: c.maxWidth + 6,
          maxWidth: c.maxWidth + 6,
          child: AppDropdown<T>(
            value: value,
            items: items,
            labelOf: (x) => '$x',
            onChanged: onChanged,
            width: c.maxWidth + 6,
          ),
        ),
      ),
    );
  }

  Widget _label(AppPalette p, String text, {bool required = false}) {
    return Text.rich(
      TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
        children: [
          if (required)
            const TextSpan(
              text: '  *',
              style: TextStyle(color: Color(0xFFE5484D)),
            ),
        ],
      ),
    );
  }

  Widget _field(
    AppPalette p, {
    required TextEditingController controller,
    required String hint,
    bool number = false,
    bool invalid = false,
  }) {
    final fill = p.isDark ? p.surface : p.pageBg;
    final base = p.isDark ? Colors.white.withValues(alpha: 0.92) : p.border;
    OutlineInputBorder b(Color c, [double w = 1.2]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c, width: w),
    );
    const red = Color(0xFFE5484D);
    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        cursorColor: p.textPrimary,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: number
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : null,
        onChanged: (_) {
          if (_submitted) setState(() {});
        },
        style: TextStyle(fontSize: 15, color: p.textPrimary),
        decoration: InputDecoration(
          filled: true,
          fillColor: fill,
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 15, color: p.textMuted),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          enabledBorder: b(invalid ? red : base),
          focusedBorder: b(invalid ? red : AppColors.gold, 1.4),
          suffixIcon: number
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _spinner(
                    p,
                    () => _step(controller, 1),
                    () => _step(controller, -1),
                  ),
                )
              : null,
          suffixIconConstraints: number
              ? const BoxConstraints(minWidth: 32, minHeight: 32)
              : null,
        ),
      ),
    );
  }

  Widget _spinner(AppPalette p, VoidCallback up, VoidCallback down) {
    Widget arrow(IconData i, VoidCallback f) => InkWell(
      onTap: f,
      child: SizedBox(
        width: 22,
        height: 14,
        child: Icon(i, size: 15, color: p.textPrimary),
      ),
    );
    return Container(
      width: 24,
      height: 30,
      decoration: BoxDecoration(
        color: p.chipFill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          arrow(RemixIcons.arrow_up_s_line, up),
          arrow(RemixIcons.arrow_down_s_line, down),
        ],
      ),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.size});
  final FrameSize size;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return _DialogShell(
      maxWidth: 440,
      title: 'Delete Material',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
        child: Text(
          'Are you sure you want to delete material "${size.name}" (${size.code})?',
          style: TextStyle(fontSize: 15, color: p.textPrimary),
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _cancelButton(context, p),
          const SizedBox(width: 12),
          Material(
            color: AppPalette.statusRed,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Navigator.of(context).pop(true),
              child: const SizedBox(
                height: 44,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: Text(
                      'Delete Size',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
}
