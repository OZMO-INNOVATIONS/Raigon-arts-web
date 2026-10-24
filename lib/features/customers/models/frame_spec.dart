import 'package:raigon_art/core/utils/image_url_helper.dart';
import 'dart:convert';
import 'dart:typed_data';

class FrameSpec {
  const FrameSpec({
    required this.size,
    required this.unit,
    this.customWidth = '',
    this.customHeight = '',
    required this.frameType,
    required this.material,
    required this.finish,
    required this.orientation,
    required this.qty,
    this.notes = '',
    this.photoName,
    this.photoBytes,
    this.photoUrl,
  });

  final String size;
  final String unit;
  final String customWidth;
  final String customHeight;
  final String frameType;
  final String material;
  final String finish;
  final String orientation;
  final int qty;
  final String notes;
  final String? photoName;
  final Uint8List? photoBytes;
  final String? photoUrl;

  String get sizeLabel => (customWidth.isNotEmpty && customHeight.isNotEmpty)
      ? '$customWidth × $customHeight ${unit.toLowerCase()}'
      : size;

  Map<String, dynamic> toJson() => {
    'size': size,
    'unit': unit,
    'customWidth': customWidth,
    'customHeight': customHeight,
    'frameType': frameType,
    'material': material,
    'finish': finish,
    'orientation': orientation,
    'qty': qty,
    'notes': notes,
    'photoName': photoName,
    'photoUrl': photoUrl,
    // Do not save image bytes directly in Firestore.
  };

  factory FrameSpec.fromJson(Map<String, dynamic> j) {
    int parseQty(dynamic v) {
      if (v == null) return 1;
      if (v is num) return v.toInt();
      if (v is String) return num.tryParse(v)?.toInt() ?? 1;
      return 1;
    }

    final pUrl = j['photoUrl'] ?? j['photo_url'];
    final pName = j['photoName'] ?? j['photo_name'];
    final pBytes = j['photoBytes'] ?? j['photo_bytes'];

    Uint8List? decodedBytes;
    if (pBytes != null && pBytes is String && pBytes.isNotEmpty) {
      try {
        decodedBytes = base64Decode(pBytes);
      } catch (_) {}
    }

    return FrameSpec(
      size: (j['size'] ?? '')?.toString() ?? '',
      unit: (j['unit'] ?? 'Inch')?.toString() ?? 'Inch',
      customWidth: (j['customWidth'] ?? j['custom_width'] ?? '')?.toString() ?? '',
      customHeight: (j['customHeight'] ?? j['custom_height'] ?? '')?.toString() ?? '',
      frameType: (j['frameType'] ?? j['frame_type'] ?? '')?.toString() ?? '',
      material: (j['material'] ?? '')?.toString() ?? '',
      finish: (j['finish'] ?? '')?.toString() ?? '',
      orientation: (j['orientation'] ?? '')?.toString() ?? '',
      qty: parseQty(j['qty']),
      notes: (j['notes'] ?? '')?.toString() ?? '',
      photoName: pName?.toString(),
      photoUrl: (pUrl != null && pUrl.toString().trim().isNotEmpty)
          ? ImageUrlHelper.resolve(pUrl.toString().trim())
          : null,
      photoBytes: decodedBytes,
    );
  }
}

class PickedPhoto {
  const PickedPhoto({
    required this.name,
    required this.bytes,
    required this.size,
  });

  final String name;
  final Uint8List bytes;
  final int size;

  String get sizeLabel => size >= 1048576
      ? '${(size / 1048576).toStringAsFixed(1)} MB'
      : '${(size / 1024).toStringAsFixed(0)} KB';
}
