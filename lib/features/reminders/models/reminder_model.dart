import 'package:flutter/material.dart' show Color, DateUtils;

enum ReminderPriority {
  low('Low', Color(0xFF10B981)),
  medium('Medium', Color(0xFFF59E0B)),
  high('High', Color(0xFFEF4444));

  const ReminderPriority(this.label, this.color);
  final String label;
  final Color color;

  static ReminderPriority fromString(String? val) {
    final v = val?.trim().toLowerCase() ?? '';
    if (v == 'high' || v == 'urgent') return ReminderPriority.high;
    if (v == 'low') return ReminderPriority.low;
    return ReminderPriority.medium;
  }
}

enum ReminderStatus {
  pending('Pending'),
  overdue('Overdue'),
  completed('Completed');

  const ReminderStatus(this.label);
  final String label;
}

enum ReminderFilter {
  all('All Reminders'),
  today('Today'),
  upcoming('Upcoming'),
  overdue('Overdue'),
  completed('Completed');

  const ReminderFilter(this.label);
  final String label;
}

class CustomerReminder {
  const CustomerReminder({
    required this.id,
    required this.title,
    required this.customerName,
    this.customerId = '',
    this.orderId = '',
    this.description = '',
    required this.reminderDate,
    this.reminderTime = '10:00 AM',
    this.assignedStaff = 'Admin',
    this.priority = ReminderPriority.medium,
    this.isCompleted = false,
    this.completedAt,
    this.completedBy,
    this.createdBy = 'Admin',
    required this.createdAt,
    this.phone = '',
    this.region = '',
  });

  final String id;
  final String title;
  final String customerName;
  final String customerId;
  final String orderId;
  final String description;
  final DateTime reminderDate;
  final String reminderTime;
  final String assignedStaff;
  final ReminderPriority priority;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completedBy;
  final String createdBy;
  final DateTime createdAt;
  final String phone;
  final String region;

  DateTime get dateOnly =>
      DateTime(reminderDate.year, reminderDate.month, reminderDate.day);

  bool get isDueToday {
    if (isCompleted) return false;
    final now = DateTime.now();
    return DateUtils.isSameDay(reminderDate, now);
  }

  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dateOnly.isBefore(today);
  }

  bool get isUpcoming {
    if (isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dateOnly.isAfter(today);
  }

  bool get isDueOrOverdue => isDueToday || isOverdue;

  bool get isAvailable => !isCompleted;

  /// Whether this completed reminder was completed within the last 1 week (7 days).
  /// Completed reminders remain visible in the "All" tab for 1 week.
  /// After 1 week from completion, they are only visible in the "Completed" tab.
  bool get isCompletedWithinOneWeek {
    if (!isCompleted) return false;
    if (completedAt == null) return true;
    final now = DateTime.now();
    return completedAt!.isAfter(now.subtract(const Duration(days: 7)));
  }

  /// Whether this reminder was completed more than 1 week ago.
  bool get isCompletedOlderThanOneWeek {
    if (!isCompleted) return false;
    if (completedAt == null) return false;
    final now = DateTime.now();
    return completedAt!.isBefore(now.subtract(const Duration(days: 7)));
  }

  ReminderStatus get status {
    if (isCompleted) return ReminderStatus.completed;
    if (isOverdue) return ReminderStatus.overdue;
    return ReminderStatus.pending;
  }

  String get dateFormatted {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = months[reminderDate.month - 1];
    return '$m ${reminderDate.day}, ${reminderDate.year}';
  }

  CustomerReminder copyWith({
    String? title,
    String? customerName,
    String? customerId,
    String? orderId,
    String? description,
    DateTime? reminderDate,
    String? reminderTime,
    String? assignedStaff,
    ReminderPriority? priority,
    bool? isCompleted,
    DateTime? completedAt,
    String? completedBy,
    String? createdBy,
    DateTime? createdAt,
    String? phone,
    String? region,
  }) {
    return CustomerReminder(
      id: id,
      title: title ?? this.title,
      customerName: customerName ?? this.customerName,
      customerId: customerId ?? this.customerId,
      orderId: orderId ?? this.orderId,
      description: description ?? this.description,
      reminderDate: reminderDate ?? this.reminderDate,
      reminderTime: reminderTime ?? this.reminderTime,
      assignedStaff: assignedStaff ?? this.assignedStaff,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      phone: phone ?? this.phone,
      region: region ?? this.region,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'customerName': customerName,
    'customerId': customerId,
    'orderId': orderId,
    'description': description,
    'reminderDate': reminderDate.toIso8601String(),
    'reminderTime': reminderTime,
    'assignedStaff': assignedStaff,
    'priority': priority.name,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'completedBy': completedBy,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'phone': phone,
    'region': region,
  };

  Map<String, dynamic> toSupabaseMap() => {
    'id': id,
    'title': title,
    'customer_name': customerName,
    'customer_id': customerId,
    'order_id': orderId,
    'description': description,
    'reminder_date': reminderDate.toIso8601String(),
    'reminder_time': reminderTime,
    'assigned_staff': assignedStaff,
    'priority': priority.name,
    'is_completed': isCompleted,
    'completed_at': completedAt?.toIso8601String(),
    'completed_by': completedBy,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'phone': phone,
    'region': region,
  };

  factory CustomerReminder.fromJson(Map<String, dynamic> j) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return CustomerReminder(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? 'Customer Follow-up').toString(),
      customerName: (j['customerName'] ?? j['customer_name'] ?? '').toString(),
      customerId: (j['customerId'] ?? j['customer_id'] ?? '').toString(),
      orderId: (j['orderId'] ?? j['order_id'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      reminderDate: parseDate(j['reminderDate'] ?? j['reminder_date']),
      reminderTime: (j['reminderTime'] ?? j['reminder_time'] ?? '10:00 AM').toString(),
      assignedStaff: (j['assignedStaff'] ?? j['assigned_staff'] ?? 'Admin').toString(),
      priority: ReminderPriority.fromString((j['priority'] ?? 'Medium').toString()),
      isCompleted: j['isCompleted'] == true || j['is_completed'] == true,
      completedAt: j['completedAt'] != null || j['completed_at'] != null
          ? DateTime.tryParse((j['completedAt'] ?? j['completed_at']).toString())
          : null,
      completedBy: (j['completedBy'] ?? j['completed_by'])?.toString(),
      createdBy: (j['createdBy'] ?? j['created_by'] ?? 'Admin').toString(),
      createdAt: parseDate(j['createdAt'] ?? j['created_at']),
      phone: (j['phone'] ?? '').toString(),
      region: (j['region'] ?? '').toString(),
    );
  }
}
