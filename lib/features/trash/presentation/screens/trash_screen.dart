import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';
import 'package:raigon_art/core/provider/customer_and_order_provider.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/app_confirmation_dialog.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/reminders/models/reminder_model.dart';
import 'package:raigon_art/features/reminders/providers/reminder_provider.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CustomerAndOrderProvider>().fetchTrash();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await context.read<CustomerAndOrderProvider>().fetchTrash();
  }

  Future<void> _handleEmptyTrash(int totalCount) async {
    if (totalCount == 0) return;
    final confirmed = await showEmptyTrashConfirmationDialog(
      context,
      count: totalCount,
    );
    if (!confirmed || !mounted) return;

    final success = await context.read<CustomerAndOrderProvider>().emptyTrash();
    if (mounted) {
      if (success) {
        AppSnackBar.success(context, 'Trash bin emptied successfully.');
      } else {
        AppSnackBar.error(context, 'Failed to empty trash bin.');
      }
    }
  }

  Future<void> _restoreCustomer(Customer customer) async {
    final confirmed = await showRestoreConfirmationDialog(
      context,
      itemLabel: 'Order #${customer.id} (${customer.name})',
    );
    if (!confirmed || !mounted) return;

    final provider = context.read<CustomerAndOrderProvider>();
    final success = await provider.restoreOrder(customer.id);
    if (mounted) {
      if (success) {
        AppSnackBar.success(
          context,
          'Order #${customer.id} restored to active orders.',
        );
      } else {
        AppSnackBar.error(context, 'Could not restore order #${customer.id}.');
      }
    }
  }

  Future<void> _permanentDeleteCustomer(Customer customer) async {
    final confirmed = await showPermanentDeleteConfirmationDialog(
      context,
      itemLabel: 'Order #${customer.id} (${customer.name})',
    );
    if (!confirmed || !mounted) return;

    final provider = context.read<CustomerAndOrderProvider>();
    final success = await provider.permanentlyDeleteOrder(customer.id);
    if (mounted) {
      if (success) {
        AppSnackBar.success(
          context,
          'Order #${customer.id} permanently deleted.',
        );
      } else {
        AppSnackBar.error(
          context,
          'Could not permanently delete order #${customer.id}.',
        );
      }
    }
  }

  Future<void> _restoreReminder(CustomerReminder reminder) async {
    final title = reminder.title.isNotEmpty ? reminder.title : 'Reminder';
    final confirmed = await showRestoreConfirmationDialog(
      context,
      itemLabel: '$title for ${reminder.customerName}',
    );
    if (!confirmed || !mounted) return;

    final provider = context.read<CustomerAndOrderProvider>();
    final success = await provider.restoreReminder(reminder.id);
    if (mounted) {
      if (success) {
        context.read<ReminderProvider>().refresh().ignore();
        AppSnackBar.success(
          context,
          'Reminder restored to active reminders.',
        );
      } else {
        AppSnackBar.error(context, 'Could not restore reminder.');
      }
    }
  }

  Future<void> _permanentDeleteReminder(CustomerReminder reminder) async {
    final title = reminder.title.isNotEmpty ? reminder.title : 'Reminder';
    final confirmed = await showPermanentDeleteConfirmationDialog(
      context,
      itemLabel: '$title for ${reminder.customerName}',
    );
    if (!confirmed || !mounted) return;

    final provider = context.read<CustomerAndOrderProvider>();
    final success = await provider.permanentlyDeleteReminder(reminder.id);
    if (mounted) {
      if (success) {
        AppSnackBar.success(context, 'Reminder permanently deleted.');
      } else {
        AppSnackBar.error(context, 'Could not permanently delete reminder.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<CustomerAndOrderProvider>();
    final orders = provider.trashOrders;
    final reminders = provider.trashReminders;
    final totalCount = provider.totalTrashCount;
    final isLoading = provider.isLoadingTrash;
    final retentionDays = provider.trashRetentionDays;

    return Scaffold(
      backgroundColor: p.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            _buildHeader(context, p, isDark, totalCount, isLoading),

            // 14-Day Retention Banner
            _buildRetentionBanner(p, isDark, retentionDays),

            // Tab Bar
            _buildTabBar(p, isDark, orders.length, reminders.length),

            // Tab Views
            Expanded(
              child: isLoading && orders.isEmpty && reminders.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: isDark ? AppColors.gold : const Color(0xFF1E1A14),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOrdersList(orders, p, isDark),
                        _buildRemindersList(reminders, p, isDark),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppPalette p,
    bool isDark,
    int totalCount,
    bool isLoading,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border, width: 1)),
      ),
      child: Row(
        children: [
          if (Navigator.of(context).canPop()) ...[
            IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: p.textPrimary),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                  : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              RemixIcons.delete_bin_line,
              color: Color(0xFFEF4444),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Trash & Recovery Vault',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (totalCount > 0) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '$totalCount items',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Recover orders and reminders before they auto-purge, or permanently delete them.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: p.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: Icon(RemixIcons.refresh_line, color: p.textPrimary, size: 20),
              tooltip: 'Refresh Trash',
              onPressed: _handleRefresh,
            ),
          const SizedBox(width: 8),
          if (totalCount > 0)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                    : const Color(0xFFFEE2E2),
                foregroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                  ),
                ),
                elevation: 0,
              ),
              icon: const Icon(RemixIcons.delete_bin_7_line, size: 16),
              label: const Text(
                'Empty Trash Bin',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: () => _handleEmptyTrash(totalCount),
            ),
        ],
      ),
    );
  }

  Widget _buildRetentionBanner(AppPalette p, bool isDark, int retentionDays) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 14, 24, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.gold.withValues(alpha: 0.08)
            : const Color(0xFFFDF8EE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? AppColors.gold.withValues(alpha: 0.25)
              : const Color(0xFFE2C98C),
        ),
      ),
      child: Row(
        children: [
          Icon(
            RemixIcons.time_line,
            color: isDark ? AppColors.gold : const Color(0xFF926A18),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '14-Day Auto-Purge Policy: Items moved to the Trash are retained for $retentionDays days before being automatically and permanently deleted from database and storage. '
              'You can restore items back to active records anytime before that period expires.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFE2D6B5) : const Color(0xFF6B4D08),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppPalette p, bool isDark, int orderCount, int reminderCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222A) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark ? AppColors.gold : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: isDark ? AppColors.black : const Color(0xFF18181B),
        unselectedLabelColor: p.textMuted,
        labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(RemixIcons.inbox_archive_line, size: 17),
                const SizedBox(width: 8),
                Text('Orders ($orderCount)'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(RemixIcons.alarm_line, size: 17),
                const SizedBox(width: 8),
                Text('Reminders ($reminderCount)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Customer> orders, AppPalette p, bool isDark) {
    if (orders.isEmpty) {
      return _buildEmptyState(
        p,
        isDark,
        icon: RemixIcons.inbox_archive_line,
        title: 'No Trashed Orders',
        subtitle: 'Deleted orders will remain here for 14 days before permanent deletion.',
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.gold,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final customer = orders[index];
          return _buildOrderCard(customer, p, isDark);
        },
      ),
    );
  }

  Widget _buildOrderCard(Customer customer, AppPalette p, bool isDark) {
    final daysRemaining = customer.daysRemainingInTrash;
    final isUrgent = daysRemaining <= 3;

    return Container(
      decoration: p.card(radius: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ID badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.gold.withValues(alpha: 0.15)
                    : const Color(0xFFF3E7C4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark
                      ? AppColors.gold.withValues(alpha: 0.3)
                      : const Color(0xFFCDBB88),
                ),
              ),
              child: Text(
                customer.id,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.gold : const Color(0xFF785507),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Main Info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(RemixIcons.phone_line, size: 13, color: p.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        customer.phone.isNotEmpty ? customer.phone : 'No phone',
                        style: TextStyle(fontSize: 12.5, color: p.textMuted),
                      ),
                      if (customer.city.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(RemixIcons.map_pin_line, size: 13, color: p.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          customer.city,
                          style: TextStyle(fontSize: 12.5, color: p.textMuted),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Frames & Total
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${customer.qty} frame(s) • ${customer.frameSize}',
                    style: TextStyle(fontSize: 13, color: p.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ₹${customer.total}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Countdown Badge & Deleted At
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isUrgent
                            ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          RemixIcons.hourglass_line,
                          size: 13,
                          color: isUrgent
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          daysRemaining <= 0
                              ? 'Purges today'
                              : '$daysRemaining days left',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isUrgent
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (customer.deletedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Deleted ${_formatDate(customer.deletedAt!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: p.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.gold : const Color(0xFF1E1A14),
                    foregroundColor:
                        isDark ? AppColors.black : const Color(0xFFF3E7C4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(RemixIcons.restart_line, size: 16),
                  label: const Text(
                    'Restore',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _restoreCustomer(customer),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(
                    RemixIcons.delete_bin_2_line,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                  tooltip: 'Delete Forever',
                  onPressed: () => _permanentDeleteCustomer(customer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersList(
    List<CustomerReminder> reminders,
    AppPalette p,
    bool isDark,
  ) {
    if (reminders.isEmpty) {
      return _buildEmptyState(
        p,
        isDark,
        icon: RemixIcons.alarm_line,
        title: 'No Trashed Reminders',
        subtitle:
            'Deleted reminders will remain here for 14 days before permanent deletion.',
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.gold,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        itemCount: reminders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final reminder = reminders[index];
          return _buildReminderCard(reminder, p, isDark);
        },
      ),
    );
  }

  Widget _buildReminderCard(
    CustomerReminder reminder,
    AppPalette p,
    bool isDark,
  ) {
    final daysRemaining = reminder.daysRemainingInTrash;
    final isUrgent = daysRemaining <= 3;

    return Container(
      decoration: p.card(radius: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Customer: ${reminder.customerName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: p.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (reminder.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      reminder.description,
                      style: TextStyle(fontSize: 12.5, color: p.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(RemixIcons.calendar_event_line, size: 14, color: p.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    '${reminder.dateFormatted} at ${reminder.reminderTime}',
                    style: TextStyle(fontSize: 12.5, color: p.textMuted),
                  ),
                ],
              ),
            ),

            // Countdown Badge & Deleted At
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isUrgent
                            ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          RemixIcons.hourglass_line,
                          size: 13,
                          color: isUrgent
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          daysRemaining <= 0
                              ? 'Purges today'
                              : '$daysRemaining days left',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isUrgent
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (reminder.deletedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Deleted ${_formatDate(reminder.deletedAt!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: p.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.gold : const Color(0xFF1E1A14),
                    foregroundColor:
                        isDark ? AppColors.black : const Color(0xFFF3E7C4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(RemixIcons.restart_line, size: 16),
                  label: const Text(
                    'Restore',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _restoreReminder(reminder),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(
                    RemixIcons.delete_bin_2_line,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                  tooltip: 'Delete Forever',
                  onPressed: () => _permanentDeleteReminder(reminder),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    AppPalette p,
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF232730)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
                border: Border.all(color: p.border),
              ),
              child: Icon(icon, size: 34, color: p.textMuted),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = months[local.month - 1];
    final d = local.day;
    final hr = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '$d $m, $hr:$min $ampm';
  }
}
