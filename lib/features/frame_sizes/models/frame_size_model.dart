class FrameSize {
  const FrameSize({
    required this.code,
    required this.name,
    required this.width,
    required this.height,
    required this.unit,
    required this.category,
    this.orders = 0,
    this.active = true,
  });

  final String code;
  final String name;
  final double width;
  final double height;
  final String unit;
  final String category;
  final int orders;
  final bool active;

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'width': width,
    'height': height,
    'unit': unit,
    'category': category,
    'orders': orders,
    'active': active,
  };

  factory FrameSize.fromJson(Map<String, dynamic> json) {
    return FrameSize(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      width: (json['width'] as num?)?.toDouble() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'Inch',
      category: json['category'] as String? ?? '',
      orders: (json['orders'] as num?)?.toInt() ??
          (json['ordersCount'] as num?)?.toInt() ??
          (json['orders_count'] as num?)?.toInt() ??
          0,
      active: json['active'] as bool? ??
          json['isActive'] as bool? ??
          json['is_active'] as bool? ??
          true,
    );
  }

  FrameSize copyWith({
    String? code,
    String? name,
    double? width,
    double? height,
    String? unit,
    String? category,
    int? orders,
    bool? active,
  }) {
    return FrameSize(
      code: code ?? this.code,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      orders: orders ?? this.orders,
      active: active ?? this.active,
    );
  }
}