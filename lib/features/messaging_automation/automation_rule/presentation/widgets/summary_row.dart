import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(color: p.textMuted, fontSize: 13)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
