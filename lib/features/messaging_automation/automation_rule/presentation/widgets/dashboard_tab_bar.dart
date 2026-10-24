import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/automation_rule_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';

class DashboardTabBar extends StatelessWidget {
  const DashboardTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<AutomationRuleProvider>();
    final p = AppPalette.of(context);

    final items = [
      (DashboardTab.automations, 'Automations', Icons.bolt_rounded, r.visibleRules.length),
      (DashboardTab.inbox, 'Inbox', Icons.inbox_outlined, r.threads.length),
      (DashboardTab.activity, 'Activity', Icons.history_rounded, r.logs.length),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: p.chipFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            for (final (tab, label, icon, count) in items)
              GestureDetector(
                onTap: () => r.setTab(tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: r.tab == tab
                        ? AppColors.gold.withValues(alpha: 0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: r.tab == tab ? AppColors.gold : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon,
                          size: 18,
                          color: r.tab == tab ? p.textPrimary : p.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: r.tab == tab ? p.textPrimary : p.textMuted,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$count',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: p.textMuted,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
