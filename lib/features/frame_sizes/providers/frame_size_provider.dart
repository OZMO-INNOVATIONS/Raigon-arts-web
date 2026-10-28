import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/core/provider/customer_and_order_provider.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:raigon_art/core/network/api_client.dart';
import 'package:raigon_art/core/network/api_constants.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/frame_sizes/models/frame_size_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FrameSizeProvider extends ChangeNotifier {
  FrameSizeProvider({ApiClient? apiClient}) : _api = apiClient ?? ApiClient() {
    CustomerAndOrderProvider.onOrdersUpdated = (customers) {
      syncCountsWithCustomers(customers);
      refresh().catchError((e) {
        debugPrint('[FrameSizeProvider] Auto-refresh on order change: $e');
      });
    };
    CustomerAndOrderProvider.onAnyOrderChange = () {
      refresh().catchError((e) {
        debugPrint('[FrameSizeProvider] Auto-refresh on order change: $e');
      });
    };
  }

  final ApiClient _api;
  static const String _storageKey = 'raigon_frame_sizes_cached';

  List<FrameSize> _sizes = [];
  bool _isLoading = false;
  bool _initialized = false;
  Object? _error;
  String _query = '';

  List<FrameSize> get sizes => List.unmodifiable(_sizes);
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;
  Object? get error => _error;
  String get query => _query;

  List<FrameSize> get filteredSizes {
    final q = _query.trim().toLowerCase();

    if (q.isEmpty) {
      return List.unmodifiable(_sizes);
    }

    return _sizes
        .where(
          (size) =>
              size.name.toLowerCase().contains(q) ||
              size.category.toLowerCase().contains(q) ||
              size.code.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> init() async {
    if (_initialized || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _fetchFromApi();
      _initialized = true;
    } catch (error) {
      debugPrint('[FrameSizeProvider] API fetch failed: $error, loading cache');
      await _loadFromCache();
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _fetchFromApi();
      _initialized = true;
    } catch (error) {
      _error = error;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchFromApi() async {
    final response = await _api.get(ApiConstants.frameSizes);
    final List<dynamic> items = response is List
        ? response
        : (response is Map && response['data'] is List
            ? response['data'] as List
            : const []);

    _sizes = items
        .map((item) => FrameSize.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    await _saveToCache();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved != null) {
        final decoded = jsonDecode(saved) as List<dynamic>;
        _sizes = decoded
            .map(
              (item) => FrameSize.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      } else {
        _sizes = List<FrameSize>.from(_defaultSizes);
      }
    } catch (_) {
      _sizes = List<FrameSize>.from(_defaultSizes);
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_sizes.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('[FrameSizeProvider] Failed to cache frame sizes: $e');
    }
  }

  void syncCountsWithCustomers(List<Customer> customers) {
    if (_sizes.isEmpty) return;
    final active = customers.where((c) => c.status != Status.cancelled).toList();
    var changed = false;
    final updated = <FrameSize>[];

    for (final size in _sizes) {
      final matching = active.where((c) => _matchesCustomer(size, c)).length;
      if (size.orders != matching) {
        changed = true;
        updated.add(size.copyWith(orders: matching));
      } else {
        updated.add(size);
      }
    }

    if (changed) {
      _sizes = updated;
      _saveToCache();
      notifyListeners();
    }
  }

  static bool _matchesCustomer(FrameSize size, Customer customer) {
    if (customer.status == Status.cancelled) return false;
    final w = size.width;
    final h = size.height;
    final sCode = size.code.trim().toLowerCase();
    final sName = size.name.trim().toLowerCase();

    for (final f in customer.effectiveFrames) {
      final cw = double.tryParse(f.customWidth.trim());
      final ch = double.tryParse(f.customHeight.trim());
      if (cw != null && ch != null && ((cw == w && ch == h) || (cw == h && ch == w))) {
        return true;
      }

      final fSize = f.size.trim().toLowerCase();
      if (fSize.isNotEmpty && fSize != 'standard') {
        if (fSize == sCode || fSize == sName) return true;
        final dims = _extractDimensions(fSize);
        for (final d in dims) {
          if ((d.$1 == w && d.$2 == h) || (d.$1 == h && d.$2 == w)) return true;
        }
      }
    }

    final summary = customer.frameSize.trim().toLowerCase();
    if (summary.isNotEmpty && summary != 'standard') {
      if (summary == sCode || summary == sName) return true;
      final dims = _extractDimensions(summary);
      for (final d in dims) {
        if ((d.$1 == w && d.$2 == h) || (d.$1 == h && d.$2 == w)) return true;
      }
    }

    return false;
  }

  static List<(double, double)> _extractDimensions(String str) {
    final results = <(double, double)>[];
    final matches = RegExp(r'(\d+(?:\.\d+)?)\s*(?:[×*x]|\s+by\s+)\s*(\d+(?:\.\d+)?)', caseSensitive: false)
        .allMatches(str);
    for (final m in matches) {
      final w = double.tryParse(m.group(1)!);
      final h = double.tryParse(m.group(2)!);
      if (w != null && h != null) {
        results.add((w, h));
      }
    }
    return results;
  }

  void setQuery(String query) {
    _query = query;
    notifyListeners();
  }

  String nextCode() {
    var maxNumber = 0;

    for (final size in _sizes) {
      final match = RegExp(r'(\d+)$').firstMatch(size.code);

      if (match != null) {
        final number = int.parse(match.group(1)!);

        if (number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    return 'FS-${(maxNumber + 1).toString().padLeft(2, '0')}';
  }

  Future<void> add(FrameSize size) async {
    final previous = List<FrameSize>.of(_sizes);
    _sizes = [..._sizes, size];
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post(
        ApiConstants.frameSizes,
        body: size.toJson(),
      );
      if (response is Map) {
        final created = FrameSize.fromJson(Map<String, dynamic>.from(response));
        _sizes = [
          for (final s in _sizes) s.code == size.code ? created : s,
        ];
        notifyListeners();
      }
      await _saveToCache();
    } catch (error) {
      _sizes = previous;
      _error = error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(FrameSize size) async {
    final previous = List<FrameSize>.of(_sizes);
    _sizes = _sizes.map((item) => item.code == size.code ? size : item).toList();
    _error = null;
    notifyListeners();

    try {
      final response = await _api.put(
        ApiConstants.frameSize(size.code),
        body: size.toJson(),
      );
      if (response is Map) {
        final updated = FrameSize.fromJson(Map<String, dynamic>.from(response));
        _sizes = _sizes.map((s) => s.code == size.code ? updated : s).toList();
        notifyListeners();
      }
      await _saveToCache();
    } catch (error) {
      _sizes = previous;
      _error = error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> remove(String code) async {
    final previous = List<FrameSize>.of(_sizes);
    _sizes = _sizes.where((item) => item.code != code).toList();
    _error = null;
    notifyListeners();

    try {
      await _api.delete(ApiConstants.frameSize(code));
      await _saveToCache();
    } catch (error) {
      _sizes = previous;
      _error = error;
      notifyListeners();
      rethrow;
    }
  }

  static const List<FrameSize> _defaultSizes = [
    FrameSize(
      code: 'FS-01',
      name: '4 × 6 inch',
      width: 4,
      height: 6,
      unit: 'Inch',
      category: 'Standard',
    ),
    FrameSize(
      code: 'FS-02',
      name: '5 × 7 inch',
      width: 5,
      height: 7,
      unit: 'Inch',
      category: 'Standard',
    ),
    FrameSize(
      code: 'FS-03',
      name: '8 × 10 inch',
      width: 8,
      height: 10,
      unit: 'Inch',
      category: 'Standard',
    ),
    FrameSize(
      code: 'FS-04',
      name: '12 × 18 inch',
      width: 12,
      height: 18,
      unit: 'Inch',
      category: 'Standard',
    ),
  ];
}
