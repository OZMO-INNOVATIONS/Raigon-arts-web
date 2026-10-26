import 'package:flutter/foundation.dart';
import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';

enum SortOption {
  newest('Newest First'),
  oldest('Oldest First'),
  name('Name (A-Z)'),
  amount('Total Amount (High-Low)');

  const SortOption(this.label);

  final String label;
}

class CustomersScreenProvider extends ChangeNotifier {
  String _searchQuery = '';
  Status? _status;
  SortOption _sort = SortOption.newest;

  String get searchQuery => _searchQuery;
  Status? get status => _status;
  SortOption get sort => _sort;

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;

    _searchQuery = value;
    notifyListeners();
  }

  void setStatus(Status? value) {
    if (_status == value) return;

    _status = value;
    notifyListeners();
  }

  void setSort(SortOption value) {
    if (_sort == value) return;

    _sort = value;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _status = null;
    _sort = SortOption.newest;
    notifyListeners();
  }

  List<Customer> filteredCustomers(List<Customer> customers) {
    final query = _searchQuery.trim().toLowerCase();

    final result = customers.where((customer) {
      final statusMatches = _status == null || customer.status == _status;

      final searchMatches =
          query.isEmpty ||
          [
            customer.id,
            customer.name,
            customer.phone,
            customer.city,
            customer.address,
          ].any((value) => value.toLowerCase().contains(query));

      return statusMatches && searchMatches;
    }).toList();

    int parseIdNum(String id) {
      final match = RegExp(r'(\d+)').allMatches(id);
      if (match.isNotEmpty) {
        return int.tryParse(match.last.group(1) ?? '0') ?? 0;
      }
      return 0;
    }

    switch (_sort) {
      case SortOption.newest:
        result.sort((a, b) {
          if (a.createdAt != null && b.createdAt != null) {
            final cmp = b.createdAt!.compareTo(a.createdAt!);
            if (cmp != 0) return cmp;
          } else if (b.createdAt != null) {
            return 1;
          } else if (a.createdAt != null) {
            return -1;
          }
          final orderCmp = b.orderDate.compareTo(a.orderDate);
          if (orderCmp != 0) return orderCmp;
          return parseIdNum(b.id).compareTo(parseIdNum(a.id));
        });
      case SortOption.oldest:
        result.sort((a, b) {
          if (a.createdAt != null && b.createdAt != null) {
            final cmp = a.createdAt!.compareTo(b.createdAt!);
            if (cmp != 0) return cmp;
          } else if (a.createdAt != null) {
            return -1;
          } else if (b.createdAt != null) {
            return 1;
          }
          final orderCmp = a.orderDate.compareTo(b.orderDate);
          if (orderCmp != 0) return orderCmp;
          return parseIdNum(a.id).compareTo(parseIdNum(b.id));
        });
      case SortOption.name:
        result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case SortOption.amount:
        result.sort((a, b) => b.total.compareTo(a.total));
    }

    return result;
  }
}
