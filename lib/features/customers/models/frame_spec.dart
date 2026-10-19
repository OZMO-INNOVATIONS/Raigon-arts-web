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

  factory FrameSpec.fromJson(Map<String, dynamic> j) => FrameSpec(
    size: j['size'] as String? ?? '',
    unit: j['unit'] as String? ?? 'Inch',
    customWidth: j['customWidth'] as String? ?? '',
    customHeight: j['customHeight'] as String? ?? '',
    frameType: j['frameType'] as String? ?? '',
    material: j['material'] as String? ?? '',
    finish: j['finish'] as String? ?? '',
    orientation: j['orientation'] as String? ?? '',
    qty: (j['qty'] as num?)?.toInt() ?? 1,
    notes: j['notes'] as String? ?? '',
    photoName: j['photoName'] as String?,
    photoUrl: j['photoUrl'] as String?,
    // Supports older documents that contain Base64 image bytes.
    photoBytes: j['photoBytes'] == null
        ? null
        : base64Decode(j['photoBytes'] as String),
  );
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
