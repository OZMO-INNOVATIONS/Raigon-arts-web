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
    this.customer,
    this.date,
  });

  final NotificationType type;
  final String title;
  final String message;
  final String meta;
  final String tag;
  final String phone;
  final Customer? customer;
  final DateTime? date;
}

List<NotificationItem> buildNotificationsFromCustomers(
  List<Customer> customers,
) {
  final list = <NotificationItem>[];
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
    if (a.date != null && b.date != null) {
      return b.date!.compareTo(a.date!);
    }
    return 0;
  });

  return list;
}
