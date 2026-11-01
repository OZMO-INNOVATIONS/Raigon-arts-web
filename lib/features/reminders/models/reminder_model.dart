import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart' show Color, DateUtils;
import 'package:raigon_art/features/customers/models/customer_model.dart';

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
    this.voiceUrl = '',
    this.voiceDurationSeconds = 0,
    this.voiceBytes,
    this.voiceNotes = const [],
    this.isDeleted = false,
    this.deletedAt,
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
  final String voiceUrl;
  final int voiceDurationSeconds;
  final Uint8List? voiceBytes;
  final List<OrderVoiceNote> voiceNotes;
  final bool isDeleted;
  final DateTime? deletedAt;

  List<OrderVoiceNote> get effectiveVoiceNotes {
    if (voiceNotes.isNotEmpty) return voiceNotes;
    if (voiceUrl.isNotEmpty || (voiceBytes != null && voiceBytes!.isNotEmpty)) {
      return [
        OrderVoiceNote(
          id: 'voice_${id}_1',
          url: voiceUrl,
          name: 'Voice Note #1',
          durationSeconds: voiceDurationSeconds > 0 ? voiceDurationSeconds : 10,
          createdAt: createdAt,
          localBytes: voiceBytes,
        ),
      ];
    }
    return const [];
  }

  bool get hasVoice => effectiveVoiceNotes.isNotEmpty;

  /// Calculates days remaining before permanent purge (14-day policy)
  int get daysRemainingInTrash {
    if (deletedAt == null) return 14;
    final elapsed = DateTime.now().difference(deletedAt!).inDays;
    return math.max(0, 14 - elapsed);
  }

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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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
    String? voiceUrl,
    int? voiceDurationSeconds,
    Uint8List? voiceBytes,
    List<OrderVoiceNote>? voiceNotes,
    bool? isDeleted,
    DateTime? deletedAt,
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
      voiceUrl: voiceUrl ?? this.voiceUrl,
      voiceDurationSeconds: voiceDurationSeconds ?? this.voiceDurationSeconds,
      voiceBytes: voiceBytes ?? this.voiceBytes,
      voiceNotes: voiceNotes ?? this.voiceNotes,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    final vNotes = effectiveVoiceNotes;
    final primaryUrl = voiceUrl.isNotEmpty
        ? voiceUrl
        : (vNotes.isNotEmpty ? vNotes.first.url : '');
    final primaryDur = voiceDurationSeconds > 0
        ? voiceDurationSeconds
        : (vNotes.isNotEmpty ? vNotes.first.durationSeconds : 0);

    return {
      'id': id,
      'title': title,
      'customerName': customerName,
      'customerId': customerId,
      'orderId': orderId,
      'description': description,
      'reminderDate': reminderDate.toIso8601String().split('T').first,
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
      'voiceUrl': primaryUrl,
      'voiceDurationSeconds': primaryDur,
      'voiceNotes': [for (final v in vNotes) v.toJson()],
      'voice_notes': [for (final v in vNotes) v.toJson()],
      if (voiceBytes != null) 'voiceBytes': base64Encode(voiceBytes!),
      'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    final vNotes = effectiveVoiceNotes;
    final primaryUrl = voiceUrl.isNotEmpty
        ? voiceUrl
        : (vNotes.isNotEmpty ? vNotes.first.url : '');
    final primaryDur = voiceDurationSeconds > 0
        ? voiceDurationSeconds
        : (vNotes.isNotEmpty ? vNotes.first.durationSeconds : 0);

    return {
      'id': id,
      'title': title,
      'customer_name': customerName,
      'customer_id': customerId,
      'order_id': orderId,
      'description': description,
      'reminder_date': reminderDate.toIso8601String().split('T').first,
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
      'voice_url': primaryUrl,
      'voice_duration_seconds': primaryDur,
      'voice_notes': [for (final v in vNotes) v.toJson()],
      'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  factory CustomerReminder.fromJson(Map<String, dynamic> j) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    Uint8List? parseBytes(dynamic v) {
      if (v == null) return null;
      if (v is Uint8List) return v;
      if (v is String && v.isNotEmpty) {
        try {
          return base64Decode(v);
        } catch (_) {}
      }
      return null;
    }

    final rawNotes = j['voiceNotes'] ?? j['voice_notes'];
    final parsedNotes = <OrderVoiceNote>[];
    if (rawNotes is List) {
      for (final n in rawNotes) {
        if (n is Map) {
          parsedNotes.add(
            OrderVoiceNote.fromJson(Map<String, dynamic>.from(n)),
          );
        }
      }
    }

    final parsedVoiceUrl = (j['voiceUrl'] ?? j['voice_url'] ?? '').toString();
    final parsedVoiceDur =
        (j['voiceDurationSeconds'] ?? j['voice_duration_seconds'] as num?)
            ?.toInt() ??
        0;
    final parsedVoiceBytes = parseBytes(j['voiceBytes']);

    if (parsedNotes.isEmpty &&
        (parsedVoiceUrl.isNotEmpty || parsedVoiceBytes != null)) {
      parsedNotes.add(
        OrderVoiceNote(
          id: 'voice_${(j['id'] ?? '')}_1',
          url: parsedVoiceUrl,
          name: 'Voice Note #1',
          durationSeconds: parsedVoiceDur > 0 ? parsedVoiceDur : 10,
          createdAt: parseDate(j['createdAt'] ?? j['created_at']),
          localBytes: parsedVoiceBytes,
        ),
      );
    }

    return CustomerReminder(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? 'Customer Follow-up').toString(),
      customerName: (j['customerName'] ?? j['customer_name'] ?? '').toString(),
      customerId: (j['customerId'] ?? j['customer_id'] ?? '').toString(),
      orderId: (j['orderId'] ?? j['order_id'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      reminderDate: parseDate(j['reminderDate'] ?? j['reminder_date']),
      reminderTime: (j['reminderTime'] ?? j['reminder_time'] ?? '10:00 AM')
          .toString(),
      assignedStaff: (j['assignedStaff'] ?? j['assigned_staff'] ?? 'Admin')
          .toString(),
      priority: ReminderPriority.fromString(
        (j['priority'] ?? 'Medium').toString(),
      ),
      isCompleted: j['isCompleted'] == true || j['is_completed'] == true,
      completedAt: j['completedAt'] != null || j['completed_at'] != null
          ? DateTime.tryParse(
              (j['completedAt'] ?? j['completed_at']).toString(),
            )
          : null,
      completedBy: (j['completedBy'] ?? j['completed_by'])?.toString(),
      createdBy: (j['createdBy'] ?? j['created_by'] ?? 'Admin').toString(),
      createdAt: parseDate(j['createdAt'] ?? j['created_at']),
      phone: (j['phone'] ?? '').toString(),
      region: (j['region'] ?? '').toString(),
      voiceUrl: parsedVoiceUrl,
      voiceDurationSeconds: parsedVoiceDur,
      voiceBytes: parsedVoiceBytes,
      voiceNotes: parsedNotes,
      isDeleted: j['is_deleted'] == true || j['isDeleted'] == true,
      deletedAt: j['deleted_at'] != null || j['deletedAt'] != null
          ? DateTime.tryParse((j['deleted_at'] ?? j['deletedAt']).toString())
          : null,
    );
  }
}
