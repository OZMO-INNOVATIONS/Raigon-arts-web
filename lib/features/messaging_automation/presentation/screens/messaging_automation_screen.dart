import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/screens/automation_dashboard_screen.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/screens/rule_builder_screen.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/automation_rule_provider.dart';
import 'package:raigon_art/features/messaging_automation/connection/presentation/screens/connection_screen.dart';
import 'package:raigon_art/features/messaging_automation/connection/providers/connection_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';

/// Entry point used by AppShell. Decides between:
/// connection flow → dashboard → rule builder.
class MessagingAutomationScreen extends StatelessWidget {
  const MessagingAutomationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectionProvider>();
    final building = context.select<AutomationRuleProvider, AutomationTrigger?>(
      (r) => r.builderTrigger,
    );

    final (key, body) = switch ((conn, building)) {
      (final c, _) when c.restoring && !c.connected => (
          'loading',
          const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        ),
      (final c, _) when !c.showAutomation => ('connection', const ConnectionScreen()),
      (_, final t?) => ('builder', RuleBuilderScreen(trigger: t)),
      _ => ('dashboard', const AutomationDashboardScreen()),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(key: ValueKey(key), child: body),
    );
  }
}
