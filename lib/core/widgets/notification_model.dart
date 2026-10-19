import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';

enum NotificationType { completed, due }

class NotificationItem {
  const NotificationItem({
    required this.type,
    required this.title,
    required this.message,
    required this.meta,
    required this.tag,
    this.phone = '',
  });

  final NotificationType type;
  final String title;
  final String message;
  final String meta;
  final String tag;
  final String phone;
}

List<NotificationItem> buildNotificationsFromCustomers(
  List<Customer> customers,
) {
  final list = <NotificationItem>[];
  for (final c in customers) {
    if (c.status == Status.completed) {
      final frameText = c.frameSize.isNotEmpty ? c.frameSize : 'Framing job';
      list.add(
        NotificationItem(
          type: NotificationType.completed,
          title: 'Work Completed: ${c.id} 🖼️',
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
          title: 'Payment Due: ${c.id} ⚠️',
          message:
              '${c.name} has a pending balance of ₹${c.balance} for the order.',
          meta: 'Status: ${c.status.label} • Phone: ${c.phone}',
          tag: 'Due',
          phone: c.phone,
        ),
      );
    }
  }
  return list;
}
