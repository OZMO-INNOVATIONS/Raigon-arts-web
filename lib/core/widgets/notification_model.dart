import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/reminders/models/reminder_model.dart';

enum NotificationType { completed, due, reminder }

class NotificationItem {
  const NotificationItem({
    required this.type,
    required this.title,
    required this.message,
    required this.meta,
    required this.tag,
    this.phone = '',
    this.customer,
    this.reminder,
    this.date,
  });

  final NotificationType type;
  final String title;
  final String message;
  final String meta;
  final String tag;
  final String phone;
  final Customer? customer;
  final CustomerReminder? reminder;
  final DateTime? date;
}

List<NotificationItem> buildNotificationsFromCustomers(
  List<Customer> customers, [
  List<CustomerReminder> reminders = const [],
]) {
  final list = <NotificationItem>[];

  // 1. Reminders (active/uncompleted, ordered by urgency)
  final activeReminders = reminders.where((r) => !r.isCompleted).toList()
    ..sort((a, b) {
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      if (a.isDueToday != b.isDueToday) return a.isDueToday ? -1 : 1;
      return a.reminderDate.compareTo(b.reminderDate);
    });

  for (final r in activeReminders) {
    final isOverdue = r.isOverdue;
    final isDueToday = r.isDueToday;
    final tag = isOverdue
        ? 'Overdue Reminder'
        : (isDueToday ? 'Due Today' : 'Scheduled (${r.dateFormatted})');
    list.add(
      NotificationItem(
        type: NotificationType.reminder,
        title: '⏰ Reminder: ${r.title}',
        message:
            '${r.customerName} • ${r.description.isNotEmpty ? r.description : "Scheduled for ${r.dateFormatted} (${r.reminderTime})"}',
        meta: 'Assigned: ${r.assignedStaff} • Priority: ${r.priority.label} • Phone: ${r.phone}',
        tag: tag,
        phone: r.phone,
        reminder: r,
        date: r.reminderDate,
      ),
    );
  }

  // 2. Customers: Completed and dues
  for (final c in customers) {
    final frameText = c.frameSize.isNotEmpty ? c.frameSize : 'Framing job';
    final eventDate = c.updatedAt ?? c.createdAt ?? c.orderDate;

    if (c.status == Status.completed) {
      list.add(
        NotificationItem(
          type: NotificationType.completed,
          customer: c,
          date: eventDate,
          title: 'Ready for Delivery • ${c.id}',
          message:
              'Framing job for ${c.name} ($frameText) is completed & ready!',
          meta: 'Status: Completed • Phone: ${c.phone}',
          tag: 'Ready',
          phone: c.phone,
        ),
      );
    }
    if (c.balance > 0 && c.status != Status.cancelled) {
      list.add(
        NotificationItem(
          type: NotificationType.due,
          customer: c,
          date: eventDate,
          title: 'Payment Due • ${c.id}',
          message:
              '${c.name} has a pending balance of ₹${c.balance} for the order.',
          meta: 'Balance: ₹${c.balance} • Phone: ${c.phone}',
          tag: '₹${c.balance} Due',
          phone: c.phone,
        ),
      );
    }
  }

  list.sort((a, b) {
    // Keep reminders at the top if urgent
    if (a.type == NotificationType.reminder && b.type != NotificationType.reminder) {
      return -1;
    }
    if (a.type != NotificationType.reminder && b.type == NotificationType.reminder) {
      return 1;
    }
    if (a.date != null && b.date != null) {
      return b.date!.compareTo(a.date!);
    }
    return 0;
  });

  return list;
}
