import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';

class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.width = 190,
  });

  final T value;
  final List<T> items;
  final String Function(T item) labelOf;
  final ValueChanged<T> onChanged;
  final double width;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
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
      constraints: BoxConstraints.tightFor(width: widget.width),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: item == widget.value ? p.avatarBg : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.labelOf(item),
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: item == widget.value
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: p.textPrimary,
                ),
              ),
            ),
          ),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: _open ? AppColors.gold.withValues(alpha: 0.22) : null,
        ),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _open ? AppColors.gold : p.border,
              width: _open ? 1.4 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.labelOf(widget.value),
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
      ),
    );
  }
}
