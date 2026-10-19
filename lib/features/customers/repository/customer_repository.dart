import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/core/network/api_client.dart';
import 'package:raigon_art/core/network/api_constants.dart';
import 'package:raigon_art/core/network/api_exception.dart';
import 'package:raigon_art/core/network/media_type_helper.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';

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
}

class RestCustomerRepository implements CustomerRepository {
  RestCustomerRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

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
        'page': ?page,
        'limit': ?limit,
        'sortBy': ?sortBy,
        'sortOrder': ?sortOrder,
      };

      final response = await _api.get(
        ApiConstants.customers,
        queryParameters: query,
      );

      final List<dynamic> items = response is List
          ? response
          : (response is Map && response['data'] is List
              ? response['data'] as List
              : const []);

      final customers = items
          .map((item) => Customer.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      debugPrint('[RestCustomerRepository] Loaded ${customers.length} customers.');
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
      final map = response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response as Map);
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

        for (final frame in customer.frames) {
          if (frame.photoBytes != null) {
            final frameName = ensureImageFilename(frame.photoName ?? 'frame.jpg');
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

        final map = response is Map<String, dynamic>
            ? response
            : Map<String, dynamic>.from(response as Map);
        debugPrint('[RestCustomerRepository] Created customer ${customer.id} with photos.');
        return Customer.fromJson(map);
      } else {
        final response = await _api.post(
          ApiConstants.customers,
          body: customer.toApiJson(),
        );
        final map = response is Map<String, dynamic>
            ? response
            : Map<String, dynamic>.from(response as Map);
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

        for (final frame in customer.frames) {
          if (frame.photoBytes != null) {
            final frameName = ensureImageFilename(frame.photoName ?? 'frame.jpg');
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

        final map = response is Map<String, dynamic>
            ? response
            : Map<String, dynamic>.from(response as Map);
        debugPrint('[RestCustomerRepository] Updated customer ${customer.id} with photos.');
        return Customer.fromJson(map);
      } else {
        final response = await _api.put(
          ApiConstants.customer(customer.id),
          body: customer.toApiJson(),
        );
        final map = response is Map<String, dynamic>
            ? response
            : Map<String, dynamic>.from(response as Map);
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
        body: {'status': status.name},
      );
      debugPrint('[RestCustomerRepository] Updated status for $id to ${status.name}.');
    } catch (e) {
      debugPrint('[RestCustomerRepository] updateStatus failed ($id): $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePayment(String id, int advance, String paymentStatus) async {
    try {
      await _api.patch(
        ApiConstants.customerPayment(id),
        body: {
          'advance': advance,
          'paymentStatus': paymentStatus,
        },
      );
      debugPrint('[RestCustomerRepository] Updated payment for $id: advance=$advance, status=$paymentStatus.');
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
}

/// Backward compatibility alias
typedef FirestoreCustomerRepository = RestCustomerRepository;
