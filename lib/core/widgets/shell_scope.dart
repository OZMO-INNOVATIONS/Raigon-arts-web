import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

enum NavDestination {
  dashboard,
  customers,
  orders,
  reminders,
  photoCollection,
  frameSizes,
  messagingAutomation,
  reports,
  profile,
}

extension NavDestinationX on NavDestination {
  String get label => switch (this) {
    NavDestination.dashboard => 'Dashboard',
    NavDestination.customers => 'Customers',
    NavDestination.orders => 'Orders',
    NavDestination.reminders => 'Reminders',
    NavDestination.photoCollection => 'Catalogue',
    NavDestination.frameSizes => 'Material',
    NavDestination.messagingAutomation => 'Messaging Automation',
    NavDestination.reports => 'Reports',
    NavDestination.profile => 'Profile',
  };

  IconData get icon => switch (this) {
    NavDestination.dashboard => RemixIcons.dashboard_line,
    NavDestination.customers => RemixIcons.team_line,
    NavDestination.orders => RemixIcons.inbox_line,
    NavDestination.reminders => RemixIcons.alarm_line,
    NavDestination.photoCollection => RemixIcons.gallery_line,
    NavDestination.frameSizes => RemixIcons.ruler_line,
    NavDestination.messagingAutomation => RemixIcons.message_3_line,
    NavDestination.reports => RemixIcons.bar_chart_line,
    NavDestination.profile => RemixIcons.store_2_line,
  };

  /// Screens Staff members are allowed to access.
  bool get isStaffAllowed => switch (this) {
    NavDestination.customers ||
    NavDestination.orders ||
    NavDestination.reminders ||
    NavDestination.photoCollection ||
    NavDestination.frameSizes ||
    NavDestination.messagingAutomation ||
    NavDestination.profile => true,
    _ => false,
  };

  /// Checks access for the current role.
  bool canAccess({required bool isAdmin}) {
    return isAdmin || isStaffAllowed;
  }
}

class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.goTo,
    required this.openAddCustomer,
    required super.child,
  });

  final ValueChanged<NavDestination> goTo;
  final VoidCallback openAddCustomer;

  static ShellScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ShellScope>();

    assert(scope != null, 'ShellScope not found in widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(ShellScope oldWidget) {
    return goTo != oldWidget.goTo ||
        openAddCustomer != oldWidget.openAddCustomer;
  }
}
