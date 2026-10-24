import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/models/inbox_thread.dart';

class ConversationView extends StatelessWidget {
  const ConversationView({super.key, required this.thread, required this.onClose});

  final InboxThread thread;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(thread.name,
                  style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
            ],
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(label: Text(thread.incoming)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Chip(
              backgroundColor: AppColors.gold.withValues(alpha: 0.2),
              label: Text('🤖 ${thread.reply}'),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
