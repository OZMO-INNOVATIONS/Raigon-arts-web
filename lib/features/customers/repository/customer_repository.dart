import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/core/network/api_client.dart';
import 'package:raigon_art/core/network/api_constants.dart';
import 'package:raigon_art/core/network/api_exception.dart';
import 'package:raigon_art/core/network/media_type_helper.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/reminders/models/reminder_model.dart';

class TrashResult {
  const TrashResult({
    required this.orders,
    required this.reminders,
    required this.totalCount,
    required this.retentionDays,
    required this.orderCount,
    required this.reminderCount,
  });

  final List<Customer> orders;
  final List<CustomerReminder> reminders;
  final int totalCount;
  final int retentionDays;
  final int orderCount;
  final int reminderCount;

  factory TrashResult.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['orders'] as List<dynamic>? ?? [];
    final rawReminders = json['reminders'] as List<dynamic>? ?? [];
    final counts = json['counts'] as Map<String, dynamic>? ?? {};

    final orders = <Customer>[];
    for (final item in rawOrders) {
      if (item is Map<String, dynamic>) {
        try {
          orders.add(Customer.fromJson(item));
        } catch (e) {
          debugPrint('[TrashResult] Error parsing trashed customer: $e');
        }
      }
    }

    final reminders = <CustomerReminder>[];
    for (final item in rawReminders) {
      if (item is Map<String, dynamic>) {
        try {
          reminders.add(CustomerReminder.fromJson(item));
        } catch (e) {
          debugPrint('[TrashResult] Error parsing trashed reminder: $e');
        }
      }
    }

    return TrashResult(
      orders: orders,
      reminders: reminders,
      totalCount:
          (json['totalCount'] as num?)?.toInt() ??
          (json['total_count'] as num?)?.toInt() ??
          (orders.length + reminders.length),
      retentionDays:
          (json['retentionDays'] as num?)?.toInt() ??
          (json['retention_days'] as num?)?.toInt() ??
          14,
      orderCount: (counts['orders'] as num?)?.toInt() ?? orders.length,
      reminderCount: (counts['reminders'] as num?)?.toInt() ?? reminders.length,
    );
  }

  factory TrashResult.empty() => const TrashResult(
    orders: [],
    reminders: [],
    totalCount: 0,
    retentionDays: 14,
    orderCount: 0,
    reminderCount: 0,
  );
}

abstract class CustomerRepository {
  Future<List<Customer>> getAll({
    String? search,
    String? status,
    String? paymentStatus,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
    String? sortBy,
    String? sortOrder,
  });

  Future<String> getNextId();
  Future<Customer> getById(String id);
  Future<Customer> create(Customer customer);
  Future<Customer> update(Customer customer);
  Future<void> upsert(Customer customer);
  Future<void> updateStatus(String id, Status status);
  Future<void> updatePayment(String id, int advance, String paymentStatus);
  Future<void> delete(String id);
  Future<void> deletePhoto(String id, String photoId);
  String getInvoiceUrl(String id);
  String getPhotosZipUrl(String id);
  String getExportCsvUrl();
  Future<TrashResult> getTrash();
  Future<bool> restoreTrashItem(String type, String id);
  Future<bool> permanentlyDeleteTrashItem(String type, String id);
  Future<bool> emptyTrash();
}

class RestCustomerRepository implements CustomerRepository {
  RestCustomerRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Map<String, dynamic> _extractDataMap(dynamic response) {
    if (response is Map) {
      if (response['data'] is Map) {
        return Map<String, dynamic>.from(response['data'] as Map);
      }
      if (response['customer'] is Map) {
        return Map<String, dynamic>.from(response['customer'] as Map);
      }
      return Map<String, dynamic>.from(response);
    }
    throw StateError(
      'Expected customer Map object but received: ${response.runtimeType}',
    );
  }

  @override
  Future<List<Customer>> getAll({
    String? search,
    String? status,
    String? paymentStatus,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final query = <String, dynamic>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (paymentStatus != null && paymentStatus.isNotEmpty)
          'paymentStatus': paymentStatus,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        'page': page ?? 1,
        'limit': limit ?? 1000,
        'sortBy': sortBy ?? 'createdAt',
        'sortOrder': sortOrder ?? 'desc',
      };

      final response = await _api.get(
        ApiConstants.customers,
        queryParameters: query,
      );

      final List<dynamic> items = response is List
          ? response
          : (response is Map && response['data'] is List
                ? response['data'] as List
                : (response is Map && response['customers'] is List
                      ? response['customers'] as List
                      : const []));

      final customers = <Customer>[];
      for (final item in items) {
        if (item is Map) {
          try {
            customers.add(Customer.fromJson(Map<String, dynamic>.from(item)));
          } catch (e) {
            debugPrint(
              '[RestCustomerRepository] Skipping invalid customer record: $e',
            );
          }
        }
      }

      debugPrint(
        '[RestCustomerRepository] Loaded ${customers.length} customers.',
      );
      return customers;
    } catch (e) {
      debugPrint('[RestCustomerRepository] getAll failed: $e');
      rethrow;
    }
  }

  @override
  Future<String> getNextId() async {
    try {
      final response = await _api.get(ApiConstants.nextCustomerId);
      if (response is Map) {
        if (response['nextId'] != null) {
          return response['nextId'].toString();
        }
        if (response['data'] != null && response['data'] is Map) {
          return response['data']['nextId'].toString();
        }
      }
      return 'RA-1001';
    } catch (e) {
      debugPrint('[RestCustomerRepository] getNextId failed: $e');
      return 'RA-1001';
    }
  }

  @override
  Future<Customer> getById(String id) async {
    try {
      final response = await _api.get(ApiConstants.customer(id));
      final map = _extractDataMap(response);
      return Customer.fromJson(map);
    } catch (e) {
      debugPrint('[RestCustomerRepository] getById failed ($id): $e');
      rethrow;
    }
  }

  @override
  Future<Customer> create(Customer customer) async {
    try {
      final hasPhotos = customer.photoBytes.isNotEmpty;
      final hasFramePhotos = customer.frames.any((f) => f.photoBytes != null);

      if (hasPhotos || hasFramePhotos) {
        final files = <http.MultipartFile>[];

        // When individual frames have their own photos, upload them as frame_photos.
        // Only upload to 'photos' if frame_photos are not present, preventing duplicate uploads.
        if (!hasFramePhotos) {
          for (var i = 0; i < customer.photoBytes.length; i++) {
            final bytes = customer.photoBytes[i];
            final rawName = i < customer.photoNames.length
                ? customer.photoNames[i]
                : 'photo_${i + 1}.jpg';
            final name = ensureImageFilename(rawName);
            files.add(
              http.MultipartFile.fromBytes(
                'photos',
                bytes,
                filename: name,
                contentType: detectMediaType(name),
              ),
            );
          }
        }

        for (final frame in customer.frames) {
          if (frame.photoBytes != null) {
            final frameName = ensureImageFilename(
              frame.photoName ?? 'frame.jpg',
            );
            files.add(
              http.MultipartFile.fromBytes(
                'frame_photos',
                frame.photoBytes!,
                filename: frameName,
                contentType: detectMediaType(frameName),
              ),
            );
          }
        }

        final response = await _api.sendMultipart(
          method: 'POST',
          path: ApiConstants.customers,
          fields: {'customerData': jsonEncode(customer.toApiJson())},
          files: files,
        );

        final map = _extractDataMap(response);
        debugPrint(
          '[RestCustomerRepository] Created customer ${customer.id} with photos.',
        );
        return Customer.fromJson(map);
      } else {
        final response = await _api.post(
          ApiConstants.customers,
          body: customer.toApiJson(),
        );
        final map = _extractDataMap(response);
        debugPrint('[RestCustomerRepository] Created customer ${customer.id}.');
        return Customer.fromJson(map);
      }
    } catch (e) {
      debugPrint('[RestCustomerRepository] create failed (${customer.id}): $e');
      rethrow;
    }
  }

  @override
  Future<Customer> update(Customer customer) async {
    try {
      final hasPhotos = customer.photoBytes.isNotEmpty;
      final hasFramePhotos = customer.frames.any((f) => f.photoBytes != null);

      if (hasPhotos || hasFramePhotos) {
        final files = <http.MultipartFile>[];

        // When individual frames have their own photos, upload them as frame_photos.
        // Only upload to 'photos' if frame_photos are not present, preventing duplicate uploads.
        if (!hasFramePhotos) {
          for (var i = 0; i < customer.photoBytes.length; i++) {
            final bytes = customer.photoBytes[i];
            final rawName = i < customer.photoNames.length
                ? customer.photoNames[i]
                : 'photo_${i + 1}.jpg';
            final name = ensureImageFilename(rawName);
            files.add(
              http.MultipartFile.fromBytes(
                'photos',
                bytes,
                filename: name,
                contentType: detectMediaType(name),
              ),
            );
          }
        }

        for (final frame in customer.frames) {
          if (frame.photoBytes != null) {
            final frameName = ensureImageFilename(
              frame.photoName ?? 'frame.jpg',
            );
            files.add(
              http.MultipartFile.fromBytes(
                'frame_photos',
                frame.photoBytes!,
                filename: frameName,
                contentType: detectMediaType(frameName),
              ),
            );
          }
        }

        final response = await _api.sendMultipart(
          method: 'PUT',
          path: ApiConstants.customer(customer.id),
          fields: {'customerData': jsonEncode(customer.toApiJson())},
          files: files,
        );

        final map = _extractDataMap(response);
        debugPrint(
          '[RestCustomerRepository] Updated customer ${customer.id} with photos.',
        );
        return Customer.fromJson(map);
      } else {
        final response = await _api.put(
          ApiConstants.customer(customer.id),
          body: customer.toApiJson(),
        );
        final map = _extractDataMap(response);
        debugPrint('[RestCustomerRepository] Updated customer ${customer.id}.');
        return Customer.fromJson(map);
      }
    } catch (e) {
      debugPrint('[RestCustomerRepository] update failed (${customer.id}): $e');
      rethrow;
    }
  }

  @override
  Future<void> upsert(Customer customer) async {
    try {
      await update(customer);
    } on ApiException catch (e) {
      if (e.isNotFound) {
        await create(customer);
      } else {
        rethrow;
      }
    } catch (_) {
      // If error might be because record does not exist yet
      try {
        await create(customer);
      } catch (err) {
        rethrow;
      }
    }
  }

  @override
  Future<void> updateStatus(String id, Status status) async {
    try {
      await _api.patch(
        ApiConstants.customerStatus(id),
        body: {
          'status': status.apiValue,
          'stage': status.name,
          'detailedStatus': status.name,
        },
      );
      debugPrint(
        '[RestCustomerRepository] Updated status for $id to ${status.name} (API: ${status.apiValue}).',
      );
    } catch (e) {
      debugPrint('[RestCustomerRepository] updateStatus failed ($id): $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePayment(
    String id,
    int advance,
    String paymentStatus,
  ) async {
    try {
      await _api.patch(
        ApiConstants.customerPayment(id),
        body: {'advance': advance, 'paymentStatus': paymentStatus},
      );
      debugPrint(
        '[RestCustomerRepository] Updated payment for $id: advance=$advance, status=$paymentStatus.',
      );
    } catch (e) {
      debugPrint('[RestCustomerRepository] updatePayment failed ($id): $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _api.delete(ApiConstants.customer(id));
      debugPrint('[RestCustomerRepository] Deleted customer $id.');
    } catch (e) {
      debugPrint('[RestCustomerRepository] delete failed ($id): $e');
      rethrow;
    }
  }

  @override
  Future<void> deletePhoto(String id, String photoId) async {
    try {
      await _api.delete(ApiConstants.customerPhoto(id, photoId));
      debugPrint('[RestCustomerRepository] Deleted photo $photoId from $id.');
    } catch (e) {
      debugPrint('[RestCustomerRepository] deletePhoto failed: $e');
      rethrow;
    }
  }

  @override
  String getInvoiceUrl(String id) =>
      '${ApiConstants.baseUrl}${ApiConstants.customerInvoice(id)}';

  @override
  String getPhotosZipUrl(String id) =>
      '${ApiConstants.baseUrl}${ApiConstants.customerPhotosZip(id)}';

  @override
  String getExportCsvUrl() =>
      '${ApiConstants.baseUrl}${ApiConstants.exportCustomersCsv}';

  @override
  Future<TrashResult> getTrash() async {
    try {
      final res = await _api.get(ApiConstants.trash);
      final Map<String, dynamic> data = (res is Map<String, dynamic>)
          ? (res['data'] is Map<String, dynamic>
                ? res['data'] as Map<String, dynamic>
                : res)
          : {};
      return TrashResult.fromJson(data);
    } catch (e) {
      debugPrint('[RestCustomerRepository] getTrash failed: $e');
      rethrow;
    }
  }

  @override
  Future<bool> restoreTrashItem(String type, String id) async {
    try {
      await _api.post(
        ApiConstants.trashRestore,
        body: {'type': type, 'id': id},
      );
      debugPrint('[RestCustomerRepository] Restored $type $id.');
      return true;
    } catch (e) {
      debugPrint('[RestCustomerRepository] restoreTrashItem failed: $e');
      rethrow;
    }
  }

  @override
  Future<bool> permanentlyDeleteTrashItem(String type, String id) async {
    try {
      await _api.delete(ApiConstants.trashPermanent(type, id));
      debugPrint('[RestCustomerRepository] Permanently deleted $type $id.');
      return true;
    } catch (e) {
      debugPrint(
        '[RestCustomerRepository] permanentlyDeleteTrashItem failed: $e',
      );
      rethrow;
    }
  }

  @override
  Future<bool> emptyTrash() async {
    try {
      await _api.delete(ApiConstants.trashEmpty);
      debugPrint('[RestCustomerRepository] Emptied trash.');
      return true;
    } catch (e) {
      debugPrint('[RestCustomerRepository] emptyTrash failed: $e');
      rethrow;
    }
  }
}

/// Backward compatibility alias
typedef FirestoreCustomerRepository = RestCustomerRepository;
