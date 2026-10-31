import 'package:flutter_test/flutter_test.dart';
import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/core/widgets/notification_model.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/reminders/models/reminder_model.dart';

void main() {
  group('CustomerReminder Model & Due Calculation Tests', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    test('Identifies today, overdue, and upcoming reminders correctly', () {
      final todayReminder = CustomerReminder(
        id: 'REM-1',
        title: 'Today Reminder',
        customerName: 'Ananthu',
        customerId: 'RA-1001',
        reminderDate: today,
        reminderTime: '10:00',
        priority: ReminderPriority.high,
        createdAt: now,
      );

      final overdueReminder = CustomerReminder(
        id: 'REM-2',
        title: 'Overdue Reminder',
        customerName: 'Deepa',
        customerId: 'RA-1002',
        reminderDate: yesterday,
        reminderTime: '10:00',
        priority: ReminderPriority.high,
        createdAt: now,
      );

      final upcomingReminder = CustomerReminder(
        id: 'REM-3',
        title: 'Upcoming Reminder',
        customerName: 'Shayam',
        customerId: 'RA-1003',
        reminderDate: tomorrow,
        reminderTime: '10:00',
        priority: ReminderPriority.low,
        createdAt: now,
      );

      expect(todayReminder.isDueToday, isTrue);
      expect(todayReminder.isOverdue, isFalse);
      expect(todayReminder.isUpcoming, isFalse);
      expect(todayReminder.isDueOrOverdue, isTrue);

      expect(overdueReminder.isDueToday, isFalse);
      expect(overdueReminder.isOverdue, isTrue);
      expect(overdueReminder.isUpcoming, isFalse);
      expect(overdueReminder.isDueOrOverdue, isTrue);

      expect(upcomingReminder.isDueToday, isFalse);
      expect(upcomingReminder.isOverdue, isFalse);
      expect(upcomingReminder.isUpcoming, isTrue);
      expect(upcomingReminder.isDueOrOverdue, isFalse);
    });

    test('Completed reminder is never due or overdue', () {
      final completedReminder = CustomerReminder(
        id: 'REM-4',
        title: 'Done Reminder',
        customerName: 'Alfiya',
        customerId: 'RA-1004',
        reminderDate: yesterday,
        reminderTime: '10:00',
        isCompleted: true,
        completedBy: 'Workshop Staff',
        completedAt: now,
        createdAt: now,
      );

      expect(completedReminder.isDueToday, isFalse);
      expect(completedReminder.isOverdue, isFalse);
      expect(completedReminder.isDueOrOverdue, isFalse);
    });

    test('JSON serialization & deserialization roundtrip preserves all fields', () {
      final rem = CustomerReminder(
        id: 'REM-99',
        title: 'Test Follow-up',
        customerName: 'Kiran',
        customerId: 'RA-1005',
        orderId: 'ORD-55',
        description: 'Verify dimensions and acrylic finish',
        reminderDate: DateTime(2026, 11, 5),
        reminderTime: '14:30',
        assignedStaff: 'Vinod',
        priority: ReminderPriority.high,
        isCompleted: true,
        completedBy: 'Admin',
        completedAt: DateTime(2026, 10, 30, 18, 0),
        phone: '9876543210',
        region: 'South Region',
        createdAt: DateTime(2026, 10, 30, 10, 0),
      );

      final json = rem.toJson();
      final restored = CustomerReminder.fromJson(json);

      expect(restored.id, equals('REM-99'));
      expect(restored.title, equals('Test Follow-up'));
      expect(restored.customerName, equals('Kiran'));
      expect(restored.customerId, equals('RA-1005'));
      expect(restored.orderId, equals('ORD-55'));
      expect(restored.description, equals('Verify dimensions and acrylic finish'));
      expect(restored.reminderDate, equals(DateTime(2026, 11, 5)));
      expect(restored.reminderTime, equals('14:30'));
      expect(restored.assignedStaff, equals('Vinod'));
      expect(restored.priority, equals(ReminderPriority.high));
      expect(restored.isCompleted, isTrue);
      expect(restored.completedBy, equals('Admin'));
      expect(restored.phone, equals('9876543210'));
      expect(restored.region, equals('South Region'));
    });
  });

  group('Customer Priority & Region Model Enhancements', () {
    test('Calculates orderPriority and effectiveRegion accurately', () {
      final urgentCustomer = Customer(
        id: 'RA-1001',
        name: 'Urgent Client',
        phone: '9999999999',
        city: 'Trivandrum',
        address: 'MG Road',
        orderDate: DateTime(2026, 10, 29),
        expectedDelivery: DateTime.now(),
        total: 5000,
        advance: 1000,
        photoCount: 1,
        qty: 1,
        status: Status.pending,
        frameSize: '12 × 18 inch',
        frameType: 'Teak Wood Moulding',
        region: 'Central Hub',
        createdAt: DateTime(2026, 10, 29),
      );

      expect(urgentCustomer.effectiveRegion, equals('Central Hub'));
      expect(urgentCustomer.orderPriority, equals(OrderPriority.urgent));

      final normalCustomer = Customer(
        id: 'RA-1002',
        name: 'Normal Client',
        phone: '8888888888',
        city: 'Kollam',
        address: 'Beach Road',
        orderDate: DateTime(2026, 10, 20),
        total: 2000,
        advance: 2000,
        photoCount: 0,
        qty: 1,
        status: Status.pending,
        frameSize: '8 × 10 inch',
        frameType: 'Box',
        createdAt: DateTime(2026, 10, 20),
      );

      // Falls back to city when region is empty
      expect(normalCustomer.effectiveRegion, equals('Kollam'));
      expect(normalCustomer.orderPriority, equals(OrderPriority.normal));
    });
  });

  group('Notification System Integration with Reminders', () {
    test('buildNotificationsFromCustomers includes due/overdue reminders in notification list', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final rem1 = CustomerReminder(
        id: 'REM-T1',
        title: 'Confirm Frame Material',
        customerName: 'Ananthu',
        customerId: 'RA-1001',
        reminderDate: today,
        reminderTime: '11:00',
        createdAt: now,
      );

      final remDone = CustomerReminder(
        id: 'REM-T2',
        title: 'Already Completed',
        customerName: 'Deepa',
        customerId: 'RA-1002',
        reminderDate: today,
        reminderTime: '09:00',
        isCompleted: true,
        createdAt: now,
      );

      final notifications = buildNotificationsFromCustomers([], [rem1, remDone]);

      expect(notifications.length, equals(1));
      expect(notifications.first.type, equals(NotificationType.reminder));
      expect(notifications.first.title, contains('Confirm Frame Material'));
      expect(notifications.first.reminder?.id, equals('REM-T1'));
    });
  });

  group('Completed Reminder 1-Week Lifecycle & All Tab Tests', () {
    test('isCompletedWithinOneWeek returns true within 7 days, false after 7 days', () {
      final now = DateTime.now();
      final recentDone = CustomerReminder(
        id: 'REM-R1',
        title: 'Recent completed',
        customerName: 'Customer R',
        reminderDate: now.subtract(const Duration(days: 2)),
        isCompleted: true,
        completedAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 3)),
      );

      final oldDone = CustomerReminder(
        id: 'REM-O1',
        title: 'Old completed',
        customerName: 'Customer O',
        reminderDate: now.subtract(const Duration(days: 10)),
        isCompleted: true,
        completedAt: now.subtract(const Duration(days: 8)),
        createdAt: now.subtract(const Duration(days: 12)),
      );

      final active = CustomerReminder(
        id: 'REM-A1',
        title: 'Active reminder',
        customerName: 'Customer A',
        reminderDate: now,
        isCompleted: false,
        createdAt: now,
      );

      expect(recentDone.isCompletedWithinOneWeek, isTrue);
      expect(recentDone.isCompletedOlderThanOneWeek, isFalse);

      expect(oldDone.isCompletedWithinOneWeek, isFalse);
      expect(oldDone.isCompletedOlderThanOneWeek, isTrue);

      expect(active.isCompletedWithinOneWeek, isFalse);
    });

    test('All tab shows completed reminders within 1 week and does not show 0 when items completed recently', () {
      final now = DateTime.now();
      final doneToday = CustomerReminder(
        id: 'REM-D1',
        title: 'Done earlier today',
        customerName: 'Customer D1',
        reminderDate: now,
        isCompleted: true,
        completedAt: now,
        createdAt: now,
      );
      final done3DaysAgo = CustomerReminder(
        id: 'REM-D2',
        title: 'Done 3 days ago',
        customerName: 'Customer D2',
        reminderDate: now.subtract(const Duration(days: 3)),
        isCompleted: true,
        completedAt: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 4)),
      );
      final done10DaysAgo = CustomerReminder(
        id: 'REM-D3',
        title: 'Done 10 days ago',
        customerName: 'Customer D3',
        reminderDate: now.subtract(const Duration(days: 10)),
        isCompleted: true,
        completedAt: now.subtract(const Duration(days: 10)),
        createdAt: now.subtract(const Duration(days: 12)),
      );

      final list = [doneToday, done3DaysAgo, done10DaysAgo];

      // allTabCount should include items completed within 1 week (2 items), not 0!
      final allTabList = list.where((r) => !r.isCompleted || r.isCompletedWithinOneWeek).toList();
      final completedList = list.where((r) => r.isCompleted).toList();
      final activeList = list.where((r) => !r.isCompleted).toList();

      expect(activeList.length, equals(0)); // 0 active
      expect(completedList.length, equals(3)); // 3 total completed
      expect(allTabList.length, equals(2)); // All shows 2 (within 1 week), NOT 0!
      expect(allTabList.any((r) => r.id == 'REM-D3'), isFalse); // > 1 week excluded from All
      expect(allTabList.any((r) => r.id == 'REM-D1'), isTrue);
      expect(allTabList.any((r) => r.id == 'REM-D2'), isTrue);
    });

    test('All tab orders active reminders first, then recently completed reminders', () {
      final now = DateTime.now();
      final active = CustomerReminder(
        id: 'REM-ACT',
        title: 'Active task',
        customerName: 'Active Cust',
        reminderDate: now,
        isCompleted: false,
        createdAt: now,
      );
      final completed = CustomerReminder(
        id: 'REM-COMP',
        title: 'Completed task',
        customerName: 'Done Cust',
        reminderDate: now,
        isCompleted: true,
        completedAt: now,
        createdAt: now,
      );

      final items = [completed, active];
      final allFiltered = items.where((r) => !r.isCompleted || r.isCompletedWithinOneWeek).toList()
        ..sort((a, b) {
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          return a.reminderDate.compareTo(b.reminderDate);
        });

      expect(allFiltered.length, equals(2));
      expect(allFiltered.first.id, equals('REM-ACT')); // Active first!
      expect(allFiltered.last.id, equals('REM-COMP')); // Completed second!
    });
  });
}

