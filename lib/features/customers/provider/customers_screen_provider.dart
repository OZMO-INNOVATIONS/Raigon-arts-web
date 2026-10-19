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

    switch (_sort) {
      case SortOption.newest:
        result.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      case SortOption.oldest:
        result.sort((a, b) => a.orderDate.compareTo(b.orderDate));
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
