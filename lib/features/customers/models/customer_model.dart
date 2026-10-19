import 'dart:convert';
import 'dart:typed_data';

import 'package:raigon_art/core/utils/helper.dart';
import 'package:raigon_art/features/customers/models/frame_spec.dart';
import 'package:raigon_art/core/models/status.dart';

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
    this.photoUrls = const [],
    this.altPhone = '',
    this.pincode = '',
    this.expectedDelivery,
    this.paymentStatus = 'Unpaid',
    this.frames = const [],
    this.photoBytes = const [],
    this.photoNames = const [],
    this.photoSizeLabels = const [],
  });

  final String id;
  final String name;
  final String city;
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

  int get balance => total - advance;
  String get orderDateLabel => Helper.formatDate(orderDate);

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
    'frames': [for (final f in frames) f.toJson()],
  };

  Map<String, dynamic> toApiJson() => {
    'id': id,
    'name': name,
    'city': city,
    'phone': phone,
    'altPhone': altPhone,
    'address': address,
    'pincode': pincode,
    'total': total,
    'advance': advance,
    'paymentStatus': paymentStatus,
    'status': status.name,
    'orderDate': orderDate.toIso8601String(),
    if (expectedDelivery != null)
      'expectedDelivery': expectedDelivery!.toIso8601String(),
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

  factory Customer.fromJson(Map<String, dynamic> j) {
    List<String> strings(String key) => [
      for (final v in (j[key] as List? ?? const [])) v.toString(),
    ];

    Status parseStatus(dynamic value) {
      final s = value?.toString().toLowerCase() ?? '';
      if (s == 'inprogress' || s == 'in_progress') return Status.inProgress;
      if (s == 'completed') return Status.completed;
      if (s == 'cancelled') return Status.cancelled;
      return Status.pending;
    }

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    final pNames = strings('photoNames');
    final pUrls = strings('photoUrls');
    final pSizeLabels = strings('photoSizeLabels');

    return Customer(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? '',
      city: j['city'] as String? ?? '',
      phone: j['phone'] as String? ?? '',
      altPhone: j['altPhone'] as String? ?? '',
      address: j['address'] as String? ?? '',
      pincode: j['pincode'] as String? ?? '',
      photoCount: (j['photoCount'] as num?)?.toInt() ??
          (pUrls.isNotEmpty ? pUrls.length : pNames.length),
      photoNames: pNames,
      photoUrls: pUrls,
      photoSizeLabels: pSizeLabels,
      photoBytes: [
        for (final s in (j['photoBytes'] as List? ?? const []))
          if (s is String) base64Decode(s),
      ],
      frameSize: j['frameSize'] as String? ?? '',
      frameType: j['frameType'] as String? ?? '',
      qty: (j['qty'] as num?)?.toInt() ?? 1,
      total: (j['total'] as num?)?.toInt() ?? 0,
      advance: (j['advance'] as num?)?.toInt() ?? 0,
      paymentStatus: j['paymentStatus'] as String? ?? 'Unpaid',
      status: parseStatus(j['status']),
      orderDate: parseDate(j['orderDate']),
      expectedDelivery: j['expectedDelivery'] == null
          ? null
          : DateTime.tryParse(j['expectedDelivery'].toString()),
      frames: [
        for (final f in (j['frames'] as List? ?? const []))
          if (f is Map)
            FrameSpec.fromJson(Map<String, dynamic>.from(f)),
      ],
    );
  }

  Customer copyWith({Status? status, String? paymentStatus}) => Customer(
    id: id,
    name: name,
    city: city,
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
  );

  Customer copyWithImages({
    List<Uint8List>? photoBytes,
    List<String>? photoNames,
    List<String>? photoUrls,
    List<FrameSpec>? frames,
    int? photoCount,
  }) => Customer(
    id: id,
    name: name,
    city: city,
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
  );
}
