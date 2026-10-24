import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/features/authentication/services/auth_service.dart';
import 'package:raigon_art/features/authentication/providers/auth_provider.dart';

import 'package:raigon_art/app/app_router.dart';
import 'package:raigon_art/core/provider/customer_and_order_provider.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/app_sidebar.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/core/widgets/app_top_bar.dart';
import 'package:raigon_art/core/widgets/notification_model.dart';
import 'package:raigon_art/core/widgets/notification_panel.dart';
import 'package:raigon_art/core/widgets/shell_scope.dart';
import 'package:raigon_art/features/customers/presentation/widgets/add_customer_dialog.dart';
import 'package:raigon_art/features/customers/presentation/screens/customers_screen.dart';
import 'package:raigon_art/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:raigon_art/features/frame_sizes/presentation/screens/frame_sizes_screen.dart';
import 'package:raigon_art/features/messaging_automation/presentation/screens/messaging_automation_screen.dart';
import 'package:raigon_art/features/messaging_automation/providers/messaging_automation_provider.dart';
import 'package:raigon_art/features/orders/presentation/screens/orders_screen.dart';
import 'package:raigon_art/features/photo_collection/presentation/screens/photo_collection_screen.dart';
import 'package:raigon_art/features/reports/presentation/screens/reports_screen.dart';
import 'package:raigon_art/features/profile/presentation/screens/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late NavDestination _current;

  bool? _collapsedOverride;
  bool _showNotifications = false;

  bool get _isAdmin => AuthService.isAdmin;

  bool get _collapsed =>
      _collapsedOverride ?? MediaQuery.of(context).size.width < 1000;

  @override
  void initState() {
    super.initState();

    final uri = Uri.base;
    final instagramConnected = uri.queryParameters['instagram'] == 'connected';

    _current = instagramConnected
        ? NavDestination.messagingAutomation
        : (_isAdmin ? NavDestination.dashboard : NavDestination.customers);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<CustomerAndOrderProvider>().init();

      if (instagramConnected) {
        final username = uri.queryParameters['username'] ?? '';

        context.read<MessagingAutomationProvider>().handleInstagramConnected(
          username,
        );
      }
    });
  }

  bool _canAccess(NavDestination destination) {
    return destination.canAccess(isAdmin: _isAdmin);
  }

  void _goTo(NavDestination destination) {
    if (!_canAccess(destination)) return;

    if (destination == NavDestination.messagingAutomation) {
      _openMessagingAutomation();
      return;
    }

    setState(() {
      _current = destination;
      _showNotifications = false;
    });
  }

  Future<void> _openMessagingAutomation() async {
    if (!_canAccess(NavDestination.messagingAutomation)) return;

    setState(() {
      _current = NavDestination.messagingAutomation;
      _showNotifications = false;
    });

    final provider = context.read<MessagingAutomationProvider>();
    final uri = Uri.base;

    if (uri.queryParameters['instagram'] == 'connected') {
      provider.handleInstagramConnected(uri.queryParameters['username'] ?? '');
    } else {
      await provider.restoreInstagramConnection();
    }
  }

  void _openAddCustomer() {
    if (!_canAccess(NavDestination.customers)) return;
    showAddCustomerDialog(context);
  }

  Future<void> _logout() async {
    try {
      await context.read<AuthProvider>().signOut();

      if (!mounted) return;

      AppSnackBar.success(context, 'Logged out successfully.');

      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRouter.auth, (_) => false);
    } catch (error) {
      debugPrint('[AppShell] Logout failed: $error');

      if (!mounted) return;

      AppSnackBar.error(context, 'Could not log out. Please try again.');
    }
  }

  Widget _page() => switch (_current) {
    NavDestination.dashboard => const DashboardScreen(),
    NavDestination.customers => const CustomersScreen(),
    NavDestination.orders => const OrdersScreen(),
    NavDestination.photoCollection => const PhotoCollectionScreen(),
    NavDestination.frameSizes => const FrameSizesScreen(),
    NavDestination.messagingAutomation => const MessagingAutomationScreen(),
    NavDestination.reports => const ReportsScreen(),
    NavDestination.profile => const ProfileScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final customers = context.watch<CustomerAndOrderProvider>().customers;
    final notifications = buildNotificationsFromCustomers(customers);

    return ShellScope(
      goTo: _goTo,
      openAddCustomer: _openAddCustomer,
      child: Scaffold(
        backgroundColor: p.pageBg,
        body: Stack(
          children: [
            Row(
              children: [
                AppSidebar(
                  collapsed: _collapsed,
                  current: _current,
                  isAdmin: _isAdmin,
                  onToggle: () {
                    setState(() {
                      _collapsedOverride = !_collapsed;
                    });
                  },
                  onSelect: _goTo,
                  onLogout: _logout,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                        child: AppTopBar(
                          notificationCount: notifications.length,
                          onBellTap: () {
                            setState(() {
                              _showNotifications = !_showNotifications;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: KeyedSubtree(
                          key: ValueKey(_current),
                          child: _page(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_showNotifications) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _showNotifications = false);
                  },
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                top: 76,
                right: 28,
                child: NotificationPanel(
                  notifications: notifications,
                  onClose: () {
                    setState(() => _showNotifications = false);
                  },
                  onViewDetails: () => _goTo(NavDestination.orders),
                  onViewAll: () => _goTo(NavDestination.orders),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
