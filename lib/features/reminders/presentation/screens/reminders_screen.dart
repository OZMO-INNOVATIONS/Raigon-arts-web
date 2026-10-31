import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/app_confirmation_dialog.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/features/authentication/services/auth_service.dart';
import 'package:raigon_art/features/customers/service/customer_whatsapp_service.dart';
import 'package:raigon_art/features/reminders/models/reminder_model.dart';
import 'package:raigon_art/features/reminders/presentation/widgets/add_reminder_dialog.dart';
import 'package:raigon_art/features/reminders/providers/reminder_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReminderProvider>().init();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _callCustomer(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Future<void> _whatsappCustomer(CustomerReminder r) async {
    if (r.phone.isEmpty) {
      AppSnackBar.error(
        context,
        'No phone number available for this reminder.',
      );
      return;
    }
    final message =
        '*RAIGON ART WORKSHOP - Reminder*\n\n'
        'Dear ${r.customerName},\n'
        'This is a gentle reminder from RAIGON ART regarding: *${r.title}*.\n'
        '${r.description.isNotEmpty ? '\nDetails: ${r.description}\n' : ''}'
        'Scheduled date: ${r.dateFormatted} at ${r.reminderTime}.\n\n'
        'Thank you,\nRAIGON ART Atelier';
    final opened = await CustomerWhatsAppService.openWhatsApp(
      phone: r.phone,
      message: message,
    );
    if (!opened && mounted) {
      AppSnackBar.error(context, 'Could not open WhatsApp.');
    }
  }

  Future<void> _completeReminder(CustomerReminder r) async {
    final provider = context.read<ReminderProvider>();
    final completedBy = AuthService.isAdmin ? 'Admin' : 'Workshop Staff';
    await provider.completeReminder(r.id, completedBy: completedBy);
    if (mounted) {
      AppSnackBar.success(
        context,
        'Reminder for ${r.customerName} marked as completed by $completedBy.',
      );
    }
  }

  Future<void> _reopenReminder(CustomerReminder r) async {
    final provider = context.read<ReminderProvider>();
    await provider.reopenReminder(r.id);
    if (mounted) {
      AppSnackBar.success(context, 'Reminder reopened as pending.');
    }
  }

  Future<void> _deleteReminder(CustomerReminder r) async {
    final confirmed = await showDeleteReminderConfirmationDialog(context, r);
    if (!confirmed || !mounted) return;

    final provider = context.read<ReminderProvider>();
    await provider.deleteReminder(r.id);
    if (mounted) {
      AppSnackBar.success(context, 'Reminder deleted.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final provider = context.watch<ReminderProvider>();
    final reminders = provider.filteredReminders;
    final mediaQuery = MediaQuery.of(context);
    final isWide = mediaQuery.size.width >= 768;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isWide ? 24 : 16,
            8,
            isWide ? 24 : 16,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action Row
              _buildTopHeader(p, provider, isWide),
              const SizedBox(height: 14),

              // Filter Tabs (All, Today, Upcoming, Overdue, Completed)
              _buildFilterTabs(p, provider),
              const SizedBox(height: 12),

              // Search Field
              _buildSearchBar(p, provider),
              const SizedBox(height: 14),

              // Main List Feed
              Expanded(
                child: provider.isLoading && !provider.initialized
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.gold,
                          ),
                        ),
                      )
                    : reminders.isEmpty
                    ? _buildEmptyState(p, provider)
                    : RefreshIndicator(
                        color: AppColors.gold,
                        onRefresh: () => provider.refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: reminders.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            return _buildReminderCard(p, reminders[i], isWide);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(AppPalette p, ReminderProvider provider, bool isWide) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Reminders',
                    style: TextStyle(
                      fontSize: isWide ? 26 : 22,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (provider.dueCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.statusRed.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppPalette.statusRed.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '${provider.dueCount} Due',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.statusRed,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Schedule, track and follow up on customer orders and dates',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: p.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Add Reminder Button
        ElevatedButton.icon(
          onPressed: () => showAddOrEditReminderDialog(context: context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.black,
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 18 : 14,
              vertical: isWide ? 12 : 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.alarm_add_rounded, size: 19),
          label: Text(
            isWide ? 'Add Reminder' : 'New',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(AppPalette p, ReminderProvider provider) {
    final filters = [
      (ReminderFilter.all, 'All', provider.allTabCount),
      (ReminderFilter.today, 'Today', provider.todayCount),
      (ReminderFilter.upcoming, 'Upcoming', provider.upcomingCount),
      (ReminderFilter.overdue, 'Overdue', provider.overdueCount),
      (ReminderFilter.completed, 'Completed', provider.completedCount),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (filter, label, count) = filters[i];
          final isSelected = provider.currentFilter == filter;
          final isOverdueTab = filter == ReminderFilter.overdue && count > 0;

          return InkWell(
            onTap: () => provider.setFilter(filter),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [
                          AppColors.black,
                          Color(0xFF262319),
                          Color(0xFF7A6A3A),
                        ],
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isOverdueTab
                          ? AppPalette.statusRed.withValues(alpha: 0.08)
                          : p.surface),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.gold
                      : (isOverdueTab
                            ? AppPalette.statusRed.withValues(alpha: 0.4)
                            : p.border),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? AppColors.white
                          : (isOverdueTab
                                ? AppPalette.statusRed
                                : p.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gold.withValues(alpha: 0.35)
                          : (isOverdueTab
                                ? AppPalette.statusRed.withValues(alpha: 0.2)
                                : (p.isDark
                                      ? const Color(0xFF374151)
                                      : const Color(0xFFE5E7EB))),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.white
                            : (isOverdueTab
                                  ? AppPalette.statusRed
                                  : (p.isDark
                                        ? const Color(0xFFD1D5DB)
                                        : const Color(0xFF374151))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(AppPalette p, ReminderProvider provider) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => provider.setSearchQuery(v),
        cursorColor: AppColors.gold,
        style: TextStyle(fontSize: 13.5, color: p.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search customer name, ID, phone, title or staff...',
          hintStyle: TextStyle(fontSize: 13, color: p.textMuted),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: p.textMuted),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    provider.setSearchQuery('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildReminderCard(AppPalette p, CustomerReminder r, bool isWide) {
    final isDone = r.isCompleted;
    final isOverdue = r.isOverdue;
    final isToday = r.isDueToday;

    Color badgeColor = AppColors.gold;
    String badgeLabel = 'Pending';
    if (isDone) {
      badgeColor = AppPalette.statusGreen;
      badgeLabel = 'Completed';
    } else if (isOverdue) {
      badgeColor = AppPalette.statusRed;
      badgeLabel = 'Overdue';
    } else if (isToday) {
      badgeColor = const Color(0xFFEAB308);
      badgeLabel = 'Due Today';
    }

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? AppPalette.statusRed.withValues(alpha: 0.4)
              : (isToday ? AppColors.gold.withValues(alpha: 0.5) : p.border),
          width: isOverdue || isToday ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: p.isDark ? 0.35 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Status badge, Priority pill, Customer ID
          Row(
            children: [
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : (isOverdue
                                ? Icons.error_outline_rounded
                                : Icons.access_time_filled_rounded),
                      size: 13,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Priority Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: r.priority.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: r.priority.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${r.priority.label} Priority',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: r.priority.color,
                  ),
                ),
              ),
              const Spacer(),

              // Customer ID & Order tag
              if (r.customerId.isNotEmpty)
                Text(
                  '#${r.customerId}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Title & Description
          Text(
            r.title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: isDone ? p.textMuted : p.textPrimary,
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          if (r.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              r.description,
              style: TextStyle(
                fontSize: 13,
                color: isDone
                    ? p.textMuted.withValues(alpha: 0.7)
                    : p.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Metadata row: Customer Name, Phone, Date, Staff
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Customer Name
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: p.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    r.customerName,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ],
              ),

              // Scheduled Date & Time
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 14,
                    color: isOverdue ? AppPalette.statusRed : AppColors.gold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${r.dateFormatted} • ${r.reminderTime}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOverdue ? AppPalette.statusRed : p.textPrimary,
                    ),
                  ),
                ],
              ),

              // Staff
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.badge_outlined, size: 14, color: p.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned: ${r.assignedStaff}',
                    style: TextStyle(fontSize: 12, color: p.textMuted),
                  ),
                ],
              ),

              // Region
              if (r.region.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: p.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      r.region,
                      style: TextStyle(fontSize: 12, color: p.textMuted),
                    ),
                  ],
                ),
            ],
          ),

          // Completion footprint
          if (isDone && r.completedBy != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppPalette.statusGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '✓ Completed by ${r.completedBy} on ${r.completedAt != null ? "${r.completedAt!.day}/${r.completedAt!.month}/${r.completedAt!.year}" : "recent"}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.statusGreen,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: p.border.withValues(alpha: 0.6)),
          const SizedBox(height: 10),

          // Action Buttons: Complete/Reopen, WhatsApp, Call, Edit, Delete
          Row(
            children: [
              // Complete / Reopen Button
              if (!isDone)
                ElevatedButton.icon(
                  onPressed: () => _completeReminder(r),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.statusGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text(
                    'Mark Complete',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => _reopenReminder(r),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    side: BorderSide(color: p.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.restart_alt_rounded, size: 15),
                  label: Text(
                    'Reopen',
                    style: TextStyle(fontSize: 12, color: p.textMuted),
                  ),
                ),
              const SizedBox(width: 8),

              // WhatsApp button
              if (r.phone.isNotEmpty) ...[
                InkWell(
                  onTap: () => _whatsappCustomer(r),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: Color(0xFF25D366),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _callCustomer(r.phone),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: p.chipFill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              ],
              const Spacer(),

              // Edit
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 17),
                color: p.textMuted,
                tooltip: 'Edit Reminder',
                onPressed: () => showAddOrEditReminderDialog(
                  context: context,
                  existingReminder: r,
                ),
              ),

              // Delete
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                color: AppPalette.statusRed,
                tooltip: 'Delete Reminder',
                onPressed: () => _deleteReminder(r),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppPalette p, ReminderProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: p.chipFill,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 30,
              color: p.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No Reminders Found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            provider.searchQuery.isNotEmpty
                ? 'No reminders match "${provider.searchQuery}"'
                : 'No reminders in ${provider.currentFilter.label}.',
            style: TextStyle(fontSize: 13, color: p.textMuted),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => showAddOrEditReminderDialog(context: context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.alarm_add_rounded, size: 18),
            label: const Text(
              'Create Reminder',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
