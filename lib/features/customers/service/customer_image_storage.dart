import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:raigon_art/core/utils/customer_image_compressor_web.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/customers/models/frame_spec.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerImageStorage {
  static const String _prefix = 'raigon_customer_images_';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _key(String customerId) => '$_prefix$customerId';

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    debugPrint(
      '[CustomerImageStorage] Original image: ${_formatBytes(bytes.length)}',
    );

    final compressed = await compressImageWeb(bytes);

    debugPrint(
      '[CustomerImageStorage] Compressed image: '
      '${_formatBytes(compressed.length)}',
    );

    return compressed;
  }

  Future<void> save(Customer customer) async {
    debugPrint('[CustomerImageStorage] Saving customer ${customer.id}...');

    try {
      final prefs = await _prefs;
      final storageKey = _key(customer.id);
      final existingValue = prefs.getString(storageKey);

      debugPrint(
        '[CustomerImageStorage] Existing image data: '
        '${_formatBytes(utf8.encode(existingValue ?? '').length)}',
      );

      var photoTotalBytes = 0;
      var frameTotalBytes = 0;

      final photos = <Map<String, dynamic>>[];

      for (var i = 0; i < customer.photoBytes.length; i++) {
        final compressed = await _compressImage(customer.photoBytes[i]);
        photoTotalBytes += compressed.length;

        photos.add({
          'name': i < customer.photoNames.length
              ? customer.photoNames[i]
              : 'Photo_${i + 1}.jpg',
          'bytes': base64Encode(compressed),
        });
      }

      final frames = <Map<String, dynamic>>[];

      for (final frame in customer.frames) {
        final originalBytes = frame.photoBytes;
        Uint8List? compressed;

        if (originalBytes != null) {
          compressed = await _compressImage(originalBytes);
          frameTotalBytes += compressed.length;
        }

        frames.add({
          'photoName': frame.photoName,
          'photoBytes': compressed == null ? null : base64Encode(compressed),
        });
      }

      final data = {'photos': photos, 'frames': frames};

      final jsonData = jsonEncode(data);
      final jsonBytes = utf8.encode(jsonData).length;

      debugPrint(
        '[CustomerImageStorage] Customer ${customer.id} summary: '
        '${customer.photoBytes.length} photos, '
        '${customer.frames.length} frames.',
      );
      debugPrint(
        '[CustomerImageStorage] Compressed photo total: '
        '${_formatBytes(photoTotalBytes)}',
      );
      debugPrint(
        '[CustomerImageStorage] Compressed frame image total: '
        '${_formatBytes(frameTotalBytes)}',
      );
      debugPrint(
        '[CustomerImageStorage] Encoded JSON size: '
        '${_formatBytes(jsonBytes)}',
      );

      var totalPrefsBytes = 0;

      for (final key in prefs.getKeys()) {
        final value = prefs.get(key);

        totalPrefsBytes += utf8.encode(key).length;

        if (value is String) {
          totalPrefsBytes += utf8.encode(value).length;
        } else if (value != null) {
          totalPrefsBytes += utf8.encode(value.toString()).length;
        }
      }

      debugPrint(
        '[CustomerImageStorage] Approximate current preferences size: '
        '${_formatBytes(totalPrefsBytes)}',
      );

      final saved = await prefs.setString(storageKey, jsonData);

      if (!saved) {
        throw StateError('Could not save customer images locally.');
      }

      debugPrint('[CustomerImageStorage] Successfully saved ${customer.id}.');
    } catch (error, stackTrace) {
      debugPrint(
        '[CustomerImageStorage] SAVE FAILED for ${customer.id}: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Customer> attach(Customer customer) async {
    debugPrint('[CustomerImageStorage] Loading images for ${customer.id}...');

    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_key(customer.id));

      if (raw == null || raw.isEmpty) {
        debugPrint(
          '[CustomerImageStorage] No local image data for ${customer.id}.',
        );

        return customer.copyWithImages(
          photoBytes: const [],
          photoNames: const [],
          photoUrls: const [],
          frames: [
            for (final frame in customer.frames)
              FrameSpec(
                size: frame.size,
                unit: frame.unit,
                customWidth: frame.customWidth,
                customHeight: frame.customHeight,
                frameType: frame.frameType,
                material: frame.material,
                finish: frame.finish,
                orientation: frame.orientation,
                qty: frame.qty,
                notes: frame.notes,
                photoName: frame.photoName,
              ),
          ],
          photoCount: 0,
        );
      }

      debugPrint(
        '[CustomerImageStorage] Stored data size for ${customer.id}: '
        '${_formatBytes(utf8.encode(raw).length)}',
      );

      final data = jsonDecode(raw) as Map<String, dynamic>;

      final photos = (data['photos'] as List? ?? const [])
          .cast<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final savedFrames = (data['frames'] as List? ?? const [])
          .cast<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final photoBytes = photos
          .map((item) => base64Decode(item['bytes'] as String))
          .toList();

      final photoNames = photos
          .map((item) => item['name'] as String? ?? 'Photo.jpg')
          .toList();

      final frames = <FrameSpec>[
        for (var i = 0; i < customer.frames.length; i++)
          _attachFrame(
            customer.frames[i],
            i < savedFrames.length ? savedFrames[i] : null,
          ),
      ];

      debugPrint(
        '[CustomerImageStorage] Loaded ${photoBytes.length} photos '
        'for ${customer.id}.',
      );

      return customer.copyWithImages(
        photoBytes: photoBytes,
        photoNames: photoNames,
        photoUrls: const [],
        frames: frames,
        photoCount: photoBytes.length,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[CustomerImageStorage] LOAD FAILED for ${customer.id}: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  FrameSpec _attachFrame(FrameSpec frame, Map<String, dynamic>? saved) {
    if (saved == null) return frame;

    final encoded = saved['photoBytes'] as String?;

    return FrameSpec(
      size: frame.size,
      unit: frame.unit,
      customWidth: frame.customWidth,
      customHeight: frame.customHeight,
      frameType: frame.frameType,
      material: frame.material,
      finish: frame.finish,
      orientation: frame.orientation,
      qty: frame.qty,
      notes: frame.notes,
      photoName: saved['photoName'] as String? ?? frame.photoName,
      photoBytes: encoded == null ? null : base64Decode(encoded),
      photoUrl: null,
    );
  }

  Future<void> delete(String customerId) async {
    final prefs = await _prefs;
    final removed = await prefs.remove(_key(customerId));

    debugPrint(
      '[CustomerImageStorage] Deleted image data for $customerId: $removed',
    );
  }
}
