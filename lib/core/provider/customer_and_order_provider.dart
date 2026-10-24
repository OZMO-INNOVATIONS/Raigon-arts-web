import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/customers/repository/customer_repository.dart';

class CustomerAndOrderProvider extends ChangeNotifier {
  static VoidCallback? onAnyOrderChange;
  static void Function(List<Customer>)? onOrdersUpdated;

  void _notifyOrderChange() {
    onAnyOrderChange?.call();
    onOrdersUpdated?.call(_customers);
  }

  CustomerAndOrderProvider({CustomerRepository? repository})
    : _repository = repository ?? RestCustomerRepository();

  final CustomerRepository _repository;
  CustomerRepository get repository => _repository;

  List<Customer> _customers = [];
  bool _isLoading = false;
  bool _initialized = false;
  Object? _error;

  List<Customer> get customers => List.unmodifiable(_customers);
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;
  Object? get error => _error;

  Future<void> init() async {
    if (_initialized || _isLoading) {
      debugPrint(
        '[CustomerProvider] Init skipped. '
        'Initialized: $_initialized, Loading: $_isLoading',
      );
      return;
    }

    debugPrint(
      '[CustomerProvider] Initializing customer data from REST API...',
    );

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _customers = await _repository.getAll();
      _initialized = true;

      debugPrint('[CustomerProvider] Loaded ${_customers.length} customers.');
    } catch (error, stackTrace) {
      _error = error;

      debugPrint('[CustomerProvider] Initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _error = null;

    try {
      _customers = await _repository.getAll();
      _initialized = true;
      notifyListeners();
      _notifyOrderChange();
    } catch (error) {
      _error = error;
      notifyListeners();
      rethrow;
    }
  }

  String nextId() {
    var maxNumber = 1000;

    for (final customer in _customers) {
      final match = RegExp(r'(\d+)$').firstMatch(customer.id);

      if (match != null) {
        maxNumber = math.max(maxNumber, int.parse(match.group(1)!));
      }
    }

    return 'RA-${maxNumber + 1}';
  }

  Future<String> fetchNextId() async {
    try {
      return await _repository.getNextId();
    } catch (_) {
      return nextId();
    }
  }

  Future<void> add(Customer customer) async {
    final index = _customers.indexWhere((c) => c.id == customer.id);

    if (index != -1) {
      throw StateError('Customer ID already exists: ${customer.id}');
    }

    _customers = [customer, ..._customers];
    _error = null;
    notifyListeners();

    try {
      final created = await _repository.create(customer);
      _customers = [
        for (final c in _customers) c.id == customer.id ? created : c,
      ];
      notifyListeners();
      _notifyOrderChange();
    } catch (error) {
      _customers = _customers.where((c) => c.id != customer.id).toList();
      _error = error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(Customer customer) async {
    final previous = List<Customer>.of(_customers);
    final index = _customers.indexWhere((c) => c.id == customer.id);

    if (index == -1) {
      throw StateError('Customer not found: ${customer.id}');
    }

    _customers = [
      for (final existing in _customers)
        existing.id == customer.id ? customer : existing,
    ];

    _error = null;
    notifyListeners();

    try {
      final updated = await _repository.update(customer);
      _customers = [
        for (final c in _customers) c.id == customer.id ? updated : c,
      ];
      notifyListeners();
      _notifyOrderChange();
    } catch (error) {
      _customers = previous;
      _error = error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    final previous = List<Customer>.of(_customers);

    _customers = _customers.where((c) => c.id != id).toList();
    _error = null;
    notifyListeners();
    _notifyOrderChange();

    try {
      await _repository.delete(id);
    } catch (error) {
      _customers = previous;
      _error = error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePayment(
    String id,
    int advance,
    String paymentStatus,
  ) async {
    final previous = List<Customer>.of(_customers);
    final index = _customers.indexWhere((c) => c.id == id);
    if (index != -1) {
      final cur = _customers[index];
      _customers[index] = Customer(
        id: cur.id,
        name: cur.name,
        city: cur.city,
        phone: cur.phone,
        address: cur.address,
        photoCount: cur.photoCount,
        frameSize: cur.frameSize,
        frameType: cur.frameType,
        qty: cur.qty,
        total: cur.total,
        advance: advance,
        status: cur.status,
        orderDate: cur.orderDate,
        altPhone: cur.altPhone,
        pincode: cur.pincode,
        expectedDelivery: cur.expectedDelivery,
        paymentStatus: paymentStatus,
        photoUrls: cur.photoUrls,
        frames: cur.frames,
        photoBytes: cur.photoBytes,
        photoNames: cur.photoNames,
        photoSizeLabels: cur.photoSizeLabels,
      );
      notifyListeners();
      _notifyOrderChange();
    }
    try {
      await _repository.updatePayment(id, advance, paymentStatus);
    } catch (error) {
      _customers = previous;
      notifyListeners();
      rethrow;
    }
  }

  Status? _orderFilter;

  String _orderQuery = '';

  int _orderPage = 1;

  static const int orderPageSize = 10;

  final Map<String, Status> _statusOverride = {};

  Status? get orderFilter => _orderFilter;

  String get orderQuery => _orderQuery;

  int get orderPage => _orderPage;

  Status statusOf(Customer customer) {
    return _statusOverride[customer.id] ?? customer.status;
  }

  Future<void> setOrderStatus(Customer customer, Status status) async {
    final oldStatus = statusOf(customer);
    _statusOverride[customer.id] = status;
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = _customers[index].copyWith(status: status);
    }
    notifyListeners();
    _notifyOrderChange();

    try {
      await _repository.updateStatus(customer.id, status);
    } catch (e) {
      debugPrint('[CustomerAndOrderProvider] Status persist error: $e');
      _statusOverride[customer.id] = oldStatus;
      if (index != -1) {
        _customers[index] = _customers[index].copyWith(status: oldStatus);
      }
      notifyListeners();
      _notifyOrderChange();
      rethrow;
    }
  }

  void setOrderFilter(Status? status) {
    _orderFilter = status;
    _orderPage = 1;
    notifyListeners();
  }

  void setOrderQuery(String query) {
    _orderQuery = query;
    _orderPage = 1;
    notifyListeners();
  }

  int orderCount(Status? status) {
    if (status == null) {
      return _customers.length;
    }

    return _customers.where((customer) {
      return statusOf(customer) == status;
    }).length;
  }

  List<Customer> get filteredOrders {
    final query = _orderQuery.trim().toLowerCase();

    final result = _customers.where((customer) {
      if (_orderFilter != null && statusOf(customer) != _orderFilter) {
        return false;
      }

      if (query.isEmpty) return true;

      return customer.id.toLowerCase().contains(query) ||
          customer.name.toLowerCase().contains(query);
    }).toList();

    result.sort((a, b) => b.orderDate.compareTo(a.orderDate));

    return result;
  }

  int get orderTotalPages {
    return math.max(1, (filteredOrders.length / orderPageSize).ceil());
  }

  int get currentOrderPage {
    return _orderPage.clamp(1, orderTotalPages);
  }

  List<Customer> get paginatedOrders {
    final currentPage = currentOrderPage;

    return filteredOrders
        .skip((currentPage - 1) * orderPageSize)
        .take(orderPageSize)
        .toList();
  }

  void setOrderPage(int page) {
    _orderPage = page;
    notifyListeners();
  }

  Color statusColor(Status status) {
    return switch (status) {
      Status.inProgress => AppPalette.statusGold,
      Status.pending => AppPalette.orange,
      Status.completed => AppPalette.statusGreen,
      Status.cancelled => AppPalette.statusRed,
    };
  }

  String statusLabel(Status status) {
    return switch (status) {
      Status.inProgress => 'In Progress',
      Status.pending => 'Pending',
      Status.completed => 'Completed',
      Status.cancelled => 'Cancelled',
    };
  }

  String paymentOf(Customer customer) {
    if (customer.advance <= 0) {
      return 'Unpaid';
    }

    if (customer.advance >= customer.total) {
      return 'Paid';
    }

    return 'Partial';
  }

  Color paymentColor(String status) {
    return switch (status) {
      'Paid' => AppPalette.statusGreen,
      'Partial' => AppPalette.statusGold,
      _ => AppPalette.statusRed,
    };
  }

  static const List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String formatOrderDate(DateTime? date) {
    if (date == null) {
      return 'N/A';
    }

    return '${months[date.month - 1]} '
        '${date.day.toString().padLeft(2, '0')}, '
        '${date.year}';
  }

  String deliveryLabel(Customer customer) {
    return statusOf(customer) == Status.cancelled
        ? 'N/A'
        : formatOrderDate(customer.expectedDelivery);
  }

  String money(int value) {
    final s = value.toString();

    if (s.length <= 3) {
      return '₹$s';
    }

    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);

    final parts = <String>[];

    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }

    if (rest.isNotEmpty) {
      parts.insert(0, rest);
    }

    return '₹${parts.join(',')},$last3';
  }

  static const List<String> csvHeader = [
    'Customer ID',
    'Name',
    'Phone',
    'City',
    'Frame Size',
    'Frame Type',
    'Qty',
    'Total Amount',
    'Advance Paid',
    'Balance',
    'Order Status',
    'Order Date',
  ];

  static String _escapeCsv(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }

    return value;
  }

  static String _csvDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');

    return '\u200B${two(date.day)}-${two(date.month)}-${date.year}';
  }

  String buildCustomersCsv([List<Customer>? source]) {
    final list = source ?? _customers;
    final rows = <String>[csvHeader.map(_escapeCsv).join(',')];

    for (final customer in list) {
      rows.add(
        [
          _escapeCsv(customer.id),
          _escapeCsv(customer.name),
          '="${customer.phone.replaceAll('"', '""')}"',
          _escapeCsv(customer.city),
          _escapeCsv(customer.frameSize),
          _escapeCsv(customer.frameType),
          customer.qty.toString(),
          customer.total.toString(),
          customer.advance.toString(),
          customer.balance.toString(),
          _escapeCsv(customer.status.label),
          _csvDate(customer.orderDate),
        ].join(','),
      );
    }

    return rows.join('\r\n');
  }

  String csvFileName([DateTime? now]) {
    final date = now ?? DateTime.now();

    String two(int value) => value.toString().padLeft(2, '0');

    return 'Raigon_Customers_'
        '${date.year}-${two(date.month)}-${two(date.day)}.csv';
  }
}
