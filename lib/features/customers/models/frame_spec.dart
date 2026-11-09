import 'dart:convert';
import 'dart:typed_data';

import 'package:raigon_art/core/utils/image_url_helper.dart';

enum FrameUnit {
  inches('Inches', 'in'),
  centimetres('Centimetres', 'cm'),
  feet('Feet', 'ft');

  final String label;
  final String symbol;

  const FrameUnit(this.label, this.symbol);

  static FrameUnit fromString(String? raw) {
    final s = raw?.trim().toLowerCase() ?? '';

    if (s == 'ft' || s == 'feet' || s == 'foot' || s.contains('ft')) {
      return FrameUnit.feet;
    }

    if (s == 'cm' ||
        s.contains('centi') ||
        s == 'centimetres' ||
        s == 'centimeters') {
      return FrameUnit.centimetres;
    }

    return FrameUnit.inches;
  }
}

class FrameMeasurementHelper {
  static const double cmPerInch = 2.54;
  static const double inchesPerFoot = 12.0;

  static double? parseDimension(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return null;
    return double.tryParse(clean);
  }

  static String formatDimension(double value) {
    if (value <= 0) return '0';

    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    final str = value.toStringAsFixed(2);
    return str.replaceAll(RegExp(r'\.?0+$'), '');
  }

  static double convert({
    required double value,
    required FrameUnit from,
    required FrameUnit to,
  }) {
    if (from == to) return value;

    // Step 1: Convert source unit to inches.
    double inches;

    switch (from) {
      case FrameUnit.inches:
        inches = value;
        break;
      case FrameUnit.centimetres:
        inches = value / cmPerInch;
        break;
      case FrameUnit.feet:
        inches = value * inchesPerFoot;
        break;
    }

    // Step 2: Convert inches to target unit.
    switch (to) {
      case FrameUnit.inches:
        return inches;
      case FrameUnit.centimetres:
        return inches * cmPerInch;
      case FrameUnit.feet:
        return inches / inchesPerFoot;
    }
  }

  static String convertString({
    required String valueStr,
    required FrameUnit from,
    required FrameUnit to,
  }) {
    final val = parseDimension(valueStr);
    if (val == null) return valueStr;

    final converted = convert(value: val, from: from, to: to);

    return formatDimension(converted);
  }
}

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
    this.customerNote = '',
    this.photoName,
    this.photoBytes,
    this.photoUrl,
  });

  final String size;
  final String unit;
  final String customWidth;
  final String customHeight;

  // Retained for existing saved orders.
  final String frameType;
  final String material;
  final String finish;

  final String orientation;
  final int qty;

  // Independent note fields.
  final String notes;
  final String customerNote;

  final String? photoName;
  final Uint8List? photoBytes;
  final String? photoUrl;

  FrameUnit get frameUnit => FrameUnit.fromString(unit);

  String get sizeLabel => (customWidth.isNotEmpty && customHeight.isNotEmpty)
      ? '$customWidth × $customHeight ${frameUnit.symbol}'
      : size;

  String get formattedDimensions =>
      (customWidth.isNotEmpty && customHeight.isNotEmpty)
      ? 'Width: $customWidth ${frameUnit.symbol}, '
            'Height: $customHeight ${frameUnit.symbol} '
            '(Unit: ${frameUnit.label})'
      : size;

  FrameSpec copyWith({
    String? size,
    String? unit,
    String? customWidth,
    String? customHeight,
    String? frameType,
    String? material,
    String? finish,
    String? orientation,
    int? qty,
    String? notes,
    String? customerNote,
    String? photoName,
    Uint8List? photoBytes,
    String? photoUrl,
  }) => FrameSpec(
    size: size ?? this.size,
    unit: unit ?? this.unit,
    customWidth: customWidth ?? this.customWidth,
    customHeight: customHeight ?? this.customHeight,
    frameType: frameType ?? this.frameType,
    material: material ?? this.material,
    finish: finish ?? this.finish,
    orientation: orientation ?? this.orientation,
    qty: qty ?? this.qty,
    notes: notes ?? this.notes,
    customerNote: customerNote ?? this.customerNote,
    photoName: photoName ?? this.photoName,
    photoBytes: photoBytes ?? this.photoBytes,
    photoUrl: photoUrl ?? this.photoUrl,
  );

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
    'customerNote': customerNote,
    'photoName': photoName,
    'photoUrl': photoUrl,
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

    if (pBytes != null) {
      if (pBytes is Uint8List) {
        decodedBytes = pBytes;
      } else if (pBytes is String && pBytes.isNotEmpty) {
        try {
          decodedBytes = base64Decode(pBytes);
        } catch (_) {}
      }
    }

    return FrameSpec(
      size: (j['size'] ?? '').toString(),
      unit: (j['unit'] ?? 'Inches').toString(),
      customWidth: (j['customWidth'] ?? j['custom_width'] ?? '').toString(),
      customHeight: (j['customHeight'] ?? j['custom_height'] ?? '').toString(),
      frameType: (j['frameType'] ?? j['frame_type'] ?? '').toString(),
      material: (j['material'] ?? '').toString(),
      finish: (j['finish'] ?? '').toString(),
      orientation: (j['orientation'] ?? '').toString(),
      qty: parseQty(j['qty']),
      notes: (j['notes'] ?? '').toString(),
      customerNote: (j['customerNote'] ?? j['customer_note'] ?? '').toString(),
      photoName: pName?.toString(),
      photoUrl: (pUrl != null && pUrl.toString().trim().isNotEmpty)
          ? ImageUrlHelper.resolve(pUrl.toString().trim())
          : null,
      photoBytes: decodedBytes,
    );
  }
}

class PickedPhoto {
  const PickedPhoto({required this.name, this.bytes, this.url, this.size = 0});

  final String name;
  final Uint8List? bytes;
  final String? url;
  final int size;

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;

  bool get hasUrl => url != null && url!.isNotEmpty;

  bool get isNetwork => hasUrl && !hasBytes;

  String get sizeLabel {
    if (size <= 0) {
      return hasUrl ? 'Saved photo' : '';
    }

    return size >= 1048576
        ? '${(size / 1048576).toStringAsFixed(1)} MB'
        : '${(size / 1024).toStringAsFixed(0)} KB';
  }
}
