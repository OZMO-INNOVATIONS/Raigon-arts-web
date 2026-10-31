import 'package:flutter_test/flutter_test.dart';
import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/core/provider/customer_and_order_provider.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/customers/provider/customers_screen_provider.dart';

void main() {
  group('Customer Sorting & List Logic', () {
    test('Newest first sorts by createdAt descending properly', () {
      final provider = CustomersScreenProvider();

      final now = DateTime.now();
      final cOld = Customer(
        id: 'RA-1001',
        name: 'Old Customer',
        city: 'Trivandrum',
        phone: '9876543210',
        address: 'MG Road',
        photoCount: 1,
        frameSize: '12x18',
        frameType: 'Fiber',
        qty: 1,
        total: 1000,
        advance: 500,
        status: Status.pending,
        orderDate: DateTime(2026, 1, 1),
        createdAt: now.subtract(const Duration(days: 5)),
      );

      final cMiddle = Customer(
        id: 'RA-1002',
        name: 'Middle Customer',
        city: 'Kochi',
        phone: '9876543211',
        address: 'Marine Drive',
        photoCount: 1,
        frameSize: '16x24',
        frameType: 'Wood',
        qty: 1,
        total: 1500,
        advance: 1000,
        status: Status.inProgress,
        orderDate: DateTime(2026, 1, 1),
        createdAt: now.subtract(const Duration(days: 2)),
      );

      final cLatestUploaded = Customer(
        id: 'RA-1003',
        name: 'Latest Uploaded Customer',
        city: 'Calicut',
        phone: '9876543212',
        address: 'Beach Road',
        photoCount: 2,
        frameSize: '20x30',
        frameType: 'Synthetic',
        qty: 1,
        total: 2500,
        advance: 2000,
        status: Status.pending,
        orderDate: DateTime(2026, 1, 1), // Same order date
        createdAt: now, // Latest uploaded
      );

      final list = [cOld, cMiddle, cLatestUploaded];
      final sorted = provider.filteredCustomers(list);

      expect(sorted[0].id, 'RA-1003');
      expect(sorted[1].id, 'RA-1002');
      expect(sorted[2].id, 'RA-1001');
    });

    test('Tie-breaker on orderDate and numeric ID when createdAt is identical or null', () {
      final provider = CustomersScreenProvider();

      final c1 = Customer(
        id: 'RA-1008',
        name: 'Customer 8',
        city: 'Trivandrum',
        phone: '9876543210',
        address: 'MG Road',
        photoCount: 1,
        frameSize: '12x18',
        frameType: 'Fiber',
        qty: 1,
        total: 1000,
        advance: 500,
        status: Status.pending,
        orderDate: DateTime(2026, 10, 26),
      );

      final c2 = Customer(
        id: 'RA-1010',
        name: 'Customer 10',
        city: 'Kochi',
        phone: '9876543211',
        address: 'Marine Drive',
        photoCount: 1,
        frameSize: '16x24',
        frameType: 'Wood',
        qty: 1,
        total: 1500,
        advance: 1000,
        status: Status.inProgress,
        orderDate: DateTime(2026, 10, 26),
      );

      final c3 = Customer(
        id: 'RA-1009',
        name: 'Customer 9',
        city: 'Calicut',
        phone: '9876543212',
        address: 'Beach Road',
        photoCount: 1,
        frameSize: '20x30',
        frameType: 'Synthetic',
        qty: 1,
        total: 2000,
        advance: 1000,
        status: Status.pending,
        orderDate: DateTime(2026, 10, 26),
      );

      final list = [c1, c2, c3];
      final sorted = provider.filteredCustomers(list);

      // RA-1010 was uploaded last (higher numeric ID), so it must be on top
      expect(sorted[0].id, 'RA-1010');
      expect(sorted[1].id, 'RA-1009');
      expect(sorted[2].id, 'RA-1008');
    });

    test('Oldest first sorts by createdAt ascending', () {
      final provider = CustomersScreenProvider();
      provider.setSort(SortOption.oldest);

      final now = DateTime.now();
      final cOld = Customer(
        id: 'RA-1001',
        name: 'Old',
        city: 'A',
        phone: '1',
        address: 'A',
        photoCount: 1,
        frameSize: '1',
        frameType: '1',
        qty: 1,
        total: 100,
        advance: 0,
        status: Status.pending,
        orderDate: DateTime(2026, 1, 1),
        createdAt: now.subtract(const Duration(days: 2)),
      );

      final cNew = Customer(
        id: 'RA-1002',
        name: 'New',
        city: 'B',
        phone: '2',
        address: 'B',
        photoCount: 1,
        frameSize: '2',
        frameType: '2',
        qty: 1,
        total: 200,
        advance: 0,
        status: Status.pending,
        orderDate: DateTime(2026, 1, 1),
        createdAt: now,
      );

      final sorted = provider.filteredCustomers([cNew, cOld]);
      expect(sorted[0].id, 'RA-1001');
      expect(sorted[1].id, 'RA-1002');
    });

    test('compareLatestFirst sorts strictly by Raigon ID descending even if intermediate orders are deleted (e.g. 5, 3, 2, 1)', () {
      final now = DateTime.now();

      Customer makeCustomer(String id, {DateTime? expectedDelivery}) {
        return Customer(
          id: id,
          name: 'Customer $id',
          city: 'Trivandrum',
          phone: '9876543210',
          address: 'MG Road',
          photoCount: 1,
          frameSize: '12x18',
          frameType: 'Fiber',
          qty: 1,
          total: 1000,
          advance: 500,
          status: Status.pending,
          expectedDelivery: expectedDelivery,
          orderDate: DateTime(2026, 10, 31),
          createdAt: now,
        );
      }

      // Simulating user scenario: RA-1004 (Urgent), RA-1006 (High), RA-1005 (Low)
      // Intermediate order 1005 / deleted orders (e.g. 5, 3, 2, 1)
      final o1004 = makeCustomer('RA-1004', expectedDelivery: DateTime(2026, 10, 31)); // urgent
      final o1006 = makeCustomer('RA-1006', expectedDelivery: DateTime(2026, 11, 2));  // high
      final o1005 = makeCustomer('RA-1005', expectedDelivery: DateTime(2026, 11, 10)); // normal

      final list = [o1004, o1006, o1005];
      list.sort(CustomerAndOrderProvider.compareLatestFirst);

      expect(list.map((c) => c.id).toList(), ['RA-1006', 'RA-1005', 'RA-1004']);

      // Gapped / deleted IDs: 5, 3, 2, 1
      final o1 = makeCustomer('1');
      final o2 = makeCustomer('2');
      final o3 = makeCustomer('3');
      final o5 = makeCustomer('5');

      final gappedList = [o2, o5, o1, o3];
      gappedList.sort(CustomerAndOrderProvider.compareLatestFirst);

      expect(gappedList.map((c) => c.id).toList(), ['5', '3', '2', '1']);
    });
  });
}
