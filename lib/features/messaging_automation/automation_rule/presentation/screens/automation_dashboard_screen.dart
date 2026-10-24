import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/activity_tab.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/connect_banner.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/dashboard_header.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/dashboard_tab_bar.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/inbox_tab.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/rules_tab.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/automation_rule_provider.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';

class AutomationDashboardScreen extends StatefulWidget {
  const AutomationDashboardScreen({super.key});

  @override
  State<AutomationDashboardScreen> createState() =>
      _AutomationDashboardScreenState();
}

class _AutomationDashboardScreenState extends State<AutomationDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AutomationRuleProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tab = context.select<AutomationRuleProvider, DashboardTab>((r) => r.tab);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardHeader(),
          const ConnectBanner(),
          const SizedBox(height: 22),
          const DashboardTabBar(),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey(tab),
              child: switch (tab) {
                DashboardTab.automations => const RulesTab(),
                DashboardTab.inbox => const InboxTab(),
                DashboardTab.activity => const ActivityTab(),
              },
            ),
          ),
        ],
      ),
    );
  }
}
