import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_button.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_card.dart';

class QuickStartCard extends StatelessWidget {
  const QuickStartCard({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.example,
    required this.onStart,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String example;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AutoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.tileNeutral,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.gold, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(eyebrow,
                    style: TextStyle(color: p.textMuted, fontSize: 12.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.tileNeutral,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              example,
              style: TextStyle(
                color: p.textMuted,
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 14),
          AutoButton(label: 'Use this template', expand: true, onPressed: onStart),
        ],
      ),
    );
  }
}
