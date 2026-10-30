import 'package:flutter/material.dart' show Color;
import 'package:raigon_art/core/utils/image_url_helper.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:raigon_art/core/utils/helper.dart';
import 'package:raigon_art/features/customers/models/frame_spec.dart';
import 'package:raigon_art/core/models/status.dart';


enum OrderPriority {
  urgent('Urgent', Color(0xFFEF4444)),
  high('High', Color(0xFFF59E0B)),
  normal('Normal', Color(0xFF3B82F6)),
  low('Low', Color(0xFF6B7280));

  const OrderPriority(this.label, this.color);
  final String label;
  final Color color;
}

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.city,
    required this.phone,
    required this.address,
    required this.photoCount,
    required this.frameSize,
    required this.frameType,
    required this.qty,
    required this.total,
    required this.advance,
    required this.status,
    required this.orderDate,
    this.region = '',
    this.photoUrls = const [],
    this.altPhone = '',
    this.pincode = '',
    this.expectedDelivery,
    this.paymentStatus = 'Unpaid',
    this.frames = const [],
    this.photoBytes = const [],
    this.photoNames = const [],
    this.photoSizeLabels = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String city;
  final String region;
  final String phone;
  final String address;
  final int photoCount;
  final List<String> photoNames;
  final List<String> photoUrls;
  final String frameSize;
  final String frameType;
  final int qty;
  final int total;
  final int advance;
  final Status status;
  final DateTime orderDate;
  final String altPhone;
  final String pincode;
  final DateTime? expectedDelivery;
  final String paymentStatus;
  final List<FrameSpec> frames;
  final List<Uint8List> photoBytes;
  final List<String> photoSizeLabels;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get balance => total - advance;
  String get orderDateLabel => Helper.formatDate(orderDate);

  String get effectiveRegion =>
      region.isNotEmpty ? region : (city.isNotEmpty ? city : 'Main Region');

  /// Computes order priority based on delivery date urgency, status and pending balance.
  OrderPriority get orderPriority {
    if (status == Status.completed || status == Status.cancelled) {
      return OrderPriority.low;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (expectedDelivery != null) {
      final exp = DateTime(
        expectedDelivery!.year,
        expectedDelivery!.month,
        expectedDelivery!.day,
      );
      if (exp.isBefore(today) || exp.isAtSameMomentAs(today)) {
        return OrderPriority.urgent;
      }
      if (exp.difference(today).inDays <= 3) {
        return OrderPriority.high;
      }
    }
    if (status == Status.inProgress && balance > 5000) {
      return OrderPriority.high;
    }
    if (status == Status.inProgress) {
      return OrderPriority.high;
    }
    return OrderPriority.normal;
  }

  List<FrameSpec> get effectiveFrames => frames.isNotEmpty
      ? frames
      : [
          FrameSpec(
            size: frameSize,
            unit: 'Inch',
            frameType: frameType,
            material: 'Teak Wood Moulding',
            finish: 'Walnut Brown',
            orientation: 'Landscape (Horizontal)',
            qty: qty,
          ),
        ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'region': region,
    'phone': phone,
    'altPhone': altPhone,
    'address': address,
    'pincode': pincode,
    'photoCount': photoCount,
    'photoNames': photoNames,
    'photoUrls': photoUrls,
    'photoSizeLabels': photoSizeLabels,
    'photoBytes': [for (final b in photoBytes) base64Encode(b)],
    'frameSize': frameSize,
    'frameType': frameType,
    'qty': qty,
    'total': total,
    'advance': advance,
    'paymentStatus': paymentStatus,
    'status': status.name,
    'orderDate': orderDate.toIso8601String(),
    'expectedDelivery': expectedDelivery?.toIso8601String(),
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    'frames': [for (final f in frames) f.toJson()],
  };

  Map<String, dynamic> toApiJson() => {
    'id': id,
    'name': name,
    'city': city,
    'region': region,
    'phone': phone,
    'altPhone': altPhone,
    'address': address,
    'pincode': pincode,
    'photoUrls': photoUrls,
    'photoNames': photoNames,
    'photoSizeLabels': photoSizeLabels,
    'total': total,
    'advance': advance,
    'paymentStatus': paymentStatus,
    'status': status.name,
    'orderDate': orderDate.toIso8601String(),
    if (expectedDelivery != null)
      'expectedDelivery': expectedDelivery!.toIso8601String(),
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    'frames': [
      for (final f in effectiveFrames)
        {
          'size': f.size,
          'unit': f.unit,
          'customWidth': f.customWidth,
          'customHeight': f.customHeight,
          'frameType': f.frameType,
          'material': f.material,
          'finish': f.finish,
          'orientation': f.orientation,
          'qty': f.qty,
          'notes': f.notes,
          if (f.photoName != null && f.photoName!.isNotEmpty)
            'photoName': f.photoName,
          if (f.photoUrl != null && f.photoUrl!.isNotEmpty)
            'photoUrl': f.photoUrl,
        },
    ],
  };

  factory Customer.fromJson(Map<String, dynamic> raw) {
    var j = raw;
    if (j.containsKey('data') && j['data'] is Map && !j.containsKey('id')) {
      j = Map<String, dynamic>.from(j['data'] as Map);
    } else if (j.containsKey('customer') && j['customer'] is Map && !j.containsKey('id')) {
      j = Map<String, dynamic>.from(j['customer'] as Map);
    }

    int toInt(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is num) return v.toInt();
      if (v is String) return num.tryParse(v)?.toInt() ?? fallback;
      return fallback;
    }

    List<String> extractStrings(List<String> keys) {
      for (final k in keys) {
        final list = j[k];
        if (list is List) {
          return [for (final v in list) if (v != null) v.toString()];
        }
      }
      return [];
    }

    Status parseStatus(dynamic value) {
      final s = value?.toString().toLowerCase().replaceAll('-', '').replaceAll('_', '') ?? '';
      if (s == 'inprogress') return Status.inProgress;
      if (s == 'completed') return Status.completed;
      if (s == 'cancelled') return Status.cancelled;
      return Status.pending;
    }

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    final rawFrames = j['frames'] ?? j['customer_frames'];
    final frames = [
      for (final f in (rawFrames is List ? rawFrames : const []))
        if (f is Map)
          FrameSpec.fromJson(Map<String, dynamic>.from(f)),
    ];

    final pNames = extractStrings(['photoNames', 'photo_names']);
    final rawUrls = extractStrings(['photoUrls', 'photo_urls']);

    // Fallback: If customer_photos table objects are passed
    final rawCustPhotos = j['customer_photos'];
    if (rawUrls.isEmpty && rawCustPhotos is List) {
      for (final p in rawCustPhotos) {
        if (p is Map) {
          final u = p['file_url'] ?? p['fileUrl'] ?? p['url'];
          if (u != null && u.toString().trim().isNotEmpty) {
            rawUrls.add(u.toString().trim());
          }
          final n = p['file_name'] ?? p['fileName'] ?? p['name'];
          if (n != null && n.toString().trim().isNotEmpty) {
            pNames.add(n.toString().trim());
          }
        }
      }
    }

    var pUrls = [
      for (final u in rawUrls) ImageUrlHelper.resolve(u),
    ].where((u) => u.isNotEmpty).toList();
    final pSizeLabels = extractStrings(['photoSizeLabels', 'photo_size_labels']);

    // Collect any frame photos that might not be in pUrls
    for (var i = 0; i < frames.length; i++) {
      final f = frames[i];
      if (f.photoUrl != null && f.photoUrl!.isNotEmpty) {
        final resolvedFrameUrl = ImageUrlHelper.resolve(f.photoUrl!);
        if (!pUrls.contains(resolvedFrameUrl)) {
          pUrls.add(resolvedFrameUrl);
          final fname = f.photoName ?? 'Frame_${i + 1}.webp';
          if (!pNames.contains(fname)) {
            pNames.add(fname);
          }
        }
      }
    }

    // Link frames to pUrls if frame has no photoUrl but customer vault has photos
    final resolvedFrames = <FrameSpec>[];
    for (var i = 0; i < frames.length; i++) {
      final f = frames[i];
      if ((f.photoUrl == null || f.photoUrl!.isEmpty) && pUrls.isNotEmpty) {
        final assignedUrl = i < pUrls.length ? pUrls[i] : pUrls.first;
        final assignedName = i < pNames.length ? pNames[i] : 'Photo_${i + 1}';
        resolvedFrames.add(FrameSpec(
          size: f.size,
          unit: f.unit,
          customWidth: f.customWidth,
          customHeight: f.customHeight,
          frameType: f.frameType,
          material: f.material,
          finish: f.finish,
          orientation: f.orientation,
          qty: f.qty,
          notes: f.notes,
          photoName: f.photoName ?? assignedName,
          photoUrl: assignedUrl,
          photoBytes: f.photoBytes,
        ));
      } else {
        resolvedFrames.add(f);
      }
    }

    final rawPhotoCount = toInt(j['photoCount'] ?? j['photo_count'], 0);
    final photoCount = rawPhotoCount > 0
        ? rawPhotoCount
        : (pUrls.isNotEmpty ? pUrls.length : pNames.length);

    final rawBytes = j['photoBytes'] ?? j['photo_bytes'];
    final bytesList = <Uint8List>[];
    if (rawBytes is List) {
      for (final s in rawBytes) {
        if (s is String && s.isNotEmpty) {
          try {
            bytesList.add(base64Decode(s));
          } catch (_) {}
        }
      }
    }

    final rawOrderDate = j['orderDate'] ?? j['order_date'];
    final rawExpectedDelivery = j['expectedDelivery'] ?? j['expected_delivery'];
    final rawCreatedAt = j['createdAt'] ?? j['created_at'];
    final rawUpdatedAt = j['updatedAt'] ?? j['updated_at'];

    return Customer(
      id: (j['id'] ?? '')?.toString() ?? '',
      name: (j['name'] ?? '')?.toString() ?? '',
      city: (j['city'] ?? '')?.toString() ?? '',
      region: (j['region'] ?? j['regionId'] ?? j['region_id'] ?? j['city'] ?? '')?.toString() ?? '',
      phone: (j['phone'] ?? '')?.toString() ?? '',
      altPhone: (j['altPhone'] ?? j['alt_phone'] ?? '')?.toString() ?? '',
      address: (j['address'] ?? '')?.toString() ?? '',
      pincode: (j['pincode'] ?? '')?.toString() ?? '',
      photoCount: photoCount,
      photoNames: pNames,
      photoUrls: pUrls,
      photoSizeLabels: pSizeLabels,
      photoBytes: bytesList,
      frameSize: (j['frameSize'] ?? j['frame_size'] ?? j['frame_size_summary'] ?? '')?.toString() ?? '',
      frameType: (j['frameType'] ?? j['frame_type'] ?? j['frame_type_summary'] ?? '')?.toString() ?? '',
      qty: toInt(j['qty'], 1),
      total: toInt(j['total'], 0),
      advance: toInt(j['advance'], 0),
      paymentStatus: (j['paymentStatus'] ?? j['payment_status'] ?? 'Unpaid')?.toString() ?? 'Unpaid',
      status: parseStatus(j['status']),
      orderDate: parseDate(rawOrderDate),
      expectedDelivery: rawExpectedDelivery == null
          ? null
          : DateTime.tryParse(rawExpectedDelivery.toString()),
      frames: resolvedFrames,
      createdAt: rawCreatedAt != null ? DateTime.tryParse(rawCreatedAt.toString()) : null,
      updatedAt: rawUpdatedAt != null ? DateTime.tryParse(rawUpdatedAt.toString()) : null,
    );
  }

  Customer copyWith({
    Status? status,
    String? region,
    String? paymentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Customer(
    id: id,
    name: name,
    city: city,
    region: region ?? this.region,
    phone: phone,
    address: address,
    photoCount: photoCount,
    frameSize: frameSize,
    frameType: frameType,
    qty: qty,
    total: total,
    advance: advance,
    status: status ?? this.status,
    orderDate: orderDate,
    photoUrls: photoUrls,
    altPhone: altPhone,
    pincode: pincode,
    expectedDelivery: expectedDelivery,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    frames: frames,
    photoBytes: photoBytes,
    photoNames: photoNames,
    photoSizeLabels: photoSizeLabels,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Customer copyWithImages({
    String? region,
    List<Uint8List>? photoBytes,
    List<String>? photoNames,
    List<String>? photoUrls,
    List<FrameSpec>? frames,
    int? photoCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Customer(
    id: id,
    name: name,
    city: city,
    region: region ?? this.region,
    phone: phone,
    address: address,
    photoCount: photoCount ?? this.photoCount,
    photoNames: photoNames ?? this.photoNames,
    photoUrls: photoUrls ?? this.photoUrls,
    frameSize: frameSize,
    frameType: frameType,
    qty: qty,
    total: total,
    advance: advance,
    status: status,
    orderDate: orderDate,
    altPhone: altPhone,
    pincode: pincode,
    expectedDelivery: expectedDelivery,
    paymentStatus: paymentStatus,
    frames: frames ?? this.frames,
    photoBytes: photoBytes ?? this.photoBytes,
    photoSizeLabels: photoSizeLabels,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
