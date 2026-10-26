import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';

import 'section_card.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.soft,
  });

  final IconData icon;
  final String label, value;
  final Color color, soft;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}