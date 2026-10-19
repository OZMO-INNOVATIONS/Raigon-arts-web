import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:raigon_art/core/network/api_client.dart';
import 'package:raigon_art/core/network/api_constants.dart';
import 'package:raigon_art/features/frame_sizes/models/frame_size_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FrameSizeProvider extends ChangeNotifier {
  FrameSizeProvider({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

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
    _error = null;
    try {
      await _fetchFromApi();
      _initialized = true;
      notifyListeners();
    } catch (error) {
      _error = error;
      notifyListeners();
      rethrow;
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
