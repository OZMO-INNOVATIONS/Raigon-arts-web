import 'package:flutter/material.dart';

enum NavDestination {
  dashboard,
  customers,
  orders,
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
    NavDestination.photoCollection => 'Photo Collection',
    NavDestination.frameSizes => 'Frame Sizes',
    NavDestination.messagingAutomation => 'Messaging Automation',
    NavDestination.reports => 'Reports',
    NavDestination.profile => 'Profile',
  };

  IconData get icon => switch (this) {
    NavDestination.dashboard => Icons.pie_chart,
    NavDestination.customers => Icons.groups,
    NavDestination.orders => Icons.move_to_inbox,
    NavDestination.photoCollection => Icons.photo_library,
    NavDestination.frameSizes => Icons.straighten,
    NavDestination.messagingAutomation => Icons.forum_outlined,
    NavDestination.reports => Icons.bar_chart,
    NavDestination.profile => Icons.storefront_outlined,
  };

  /// Screens Staff members are allowed to access.
  bool get isStaffAllowed => switch (this) {
    NavDestination.customers ||
    NavDestination.orders ||
    NavDestination.photoCollection ||
    NavDestination.frameSizes ||
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
