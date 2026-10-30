import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raigon_art/core/network/api_client.dart';
import 'package:raigon_art/core/network/api_constants.dart';
import 'package:raigon_art/features/reminders/models/reminder_model.dart';

class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const String _storageKey = 'raigon_workshop_reminders_v1';
  static const String _notifiedKey = 'raigon_notified_reminders_v1';

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Loads all reminders from local storage and attempts syncing with REST API and Supabase.
  Future<List<CustomerReminder>> getReminders() async {
    final localList = await _loadLocalReminders();

    // 1. Attempt remote fetch from REST API
    try {
      final res = await ApiClient().get(ApiConstants.reminders);
      if (res is Map && res['data'] is List) {
        final apiList = (res['data'] as List)
            .map((item) => CustomerReminder.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();

        final mergedMap = <String, CustomerReminder>{};
        for (final r in localList) {
          mergedMap[r.id] = r;
        }
        for (final r in apiList) {
          mergedMap[r.id] = r;
        }
        final merged = mergedMap.values.toList();
        await _saveLocalReminders(merged);
        return merged;
      }
    } catch (e) {
      debugPrint('[ReminderService] REST API fetch notice: $e (trying Supabase/local)');
    }

    // 2. Attempt remote fetch from Supabase
    try {
      final client = _supabase;
      if (client != null) {
        final res = await client
            .from('reminders')
            .select()
            .order('reminder_date', ascending: true);

        final remoteList = res
            .map((row) => CustomerReminder.fromJson(Map<String, dynamic>.from(row as Map)))
            .toList();

        final mergedMap = <String, CustomerReminder>{};
        for (final r in localList) {
          mergedMap[r.id] = r;
        }
        for (final r in remoteList) {
          mergedMap[r.id] = r;
        }
        final merged = mergedMap.values.toList();
        await _saveLocalReminders(merged);
        return merged;
      }
    } catch (e) {
      debugPrint('[ReminderService] Supabase remote fetch notice: $e (using local)');
    }

    return localList;
  }

  /// Saves or updates a reminder.
  Future<void> saveReminder(CustomerReminder reminder) async {
    final list = await _loadLocalReminders();
    final index = list.indexWhere((r) => r.id == reminder.id);
    if (index >= 0) {
      list[index] = reminder;
    } else {
      list.insert(0, reminder);
    }
    await _saveLocalReminders(list);

    // Sync to Supabase
    try {
      final client = _supabase;
      if (client != null) {
        await client.from('reminders').upsert(reminder.toSupabaseMap());
      }
    } catch (e) {
      debugPrint('[ReminderService] Supabase upsert notice: $e (stored locally)');
    }

    // Sync to REST API
    try {
      await ApiClient().post(
        ApiConstants.reminders,
        body: reminder.toJson(),
      );
    } catch (e) {
      debugPrint('[ReminderService] REST API save notice: $e');
    }
  }

  /// Marks a reminder as complete with the staff or admin identity.
  Future<CustomerReminder> completeReminder(
    String id, {
    required String completedBy,
  }) async {
    final list = await _loadLocalReminders();
    final index = list.indexWhere((r) => r.id == id);
    if (index < 0) {
      throw StateError('Reminder not found: $id');
    }

    final updated = list[index].copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
      completedBy: completedBy,
    );
    list[index] = updated;
    await _saveLocalReminders(list);

    try {
      final client = _supabase;
      if (client != null) {
        await client.from('reminders').update({
          'is_completed': true,
          'completed_at': updated.completedAt!.toIso8601String(),
          'completed_by': completedBy,
        }).eq('id', id);
      }
    } catch (e) {
      debugPrint('[ReminderService] Supabase complete update notice: $e');
    }

    // Sync to REST API
    try {
      await ApiClient().patch(
        ApiConstants.reminder(id),
        body: {
          'status': 'completed',
          'completedBy': completedBy,
          'completedAt': updated.completedAt?.toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('[ReminderService] REST API complete notice: $e');
    }

    return updated;
  }

  /// Reopens a completed reminder.
  Future<CustomerReminder> reopenReminder(String id) async {
    final list = await _loadLocalReminders();
    final index = list.indexWhere((r) => r.id == id);
    if (index < 0) {
      throw StateError('Reminder not found: $id');
    }

    final updated = CustomerReminder(
      id: list[index].id,
      title: list[index].title,
      customerName: list[index].customerName,
      customerId: list[index].customerId,
      orderId: list[index].orderId,
      description: list[index].description,
      reminderDate: list[index].reminderDate,
      reminderTime: list[index].reminderTime,
      assignedStaff: list[index].assignedStaff,
      priority: list[index].priority,
      isCompleted: false,
      completedAt: null,
      completedBy: null,
      createdBy: list[index].createdBy,
      createdAt: list[index].createdAt,
      phone: list[index].phone,
      region: list[index].region,
    );

    list[index] = updated;
    await _saveLocalReminders(list);

    try {
      final client = _supabase;
      if (client != null) {
        await client.from('reminders').update({
          'is_completed': false,
          'completed_at': null,
          'completed_by': null,
        }).eq('id', id);
      }
    } catch (e) {
      debugPrint('[ReminderService] Supabase reopen notice: $e');
    }

    return updated;
  }

  /// Deletes a reminder.
  Future<void> deleteReminder(String id) async {
    final list = await _loadLocalReminders();
    list.removeWhere((r) => r.id == id);
    await _saveLocalReminders(list);

    try {
      final client = _supabase;
      if (client != null) {
        await client.from('reminders').delete().eq('id', id);
      }
    } catch (e) {
      debugPrint('[ReminderService] Supabase delete notice: $e');
    }

    // Sync to REST API
    try {
      await ApiClient().delete(ApiConstants.reminder(id));
    } catch (e) {
      debugPrint('[ReminderService] REST API delete notice: $e');
    }
  }

  Future<List<CustomerReminder>> _loadLocalReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        return [];
      }
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => CustomerReminder.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('[ReminderService] Local load error: $e');
    }
    return [];
  }

  Future<void> _saveLocalReminders(List<CustomerReminder> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(list.map((r) => r.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('[ReminderService] Local save error: $e');
    }
  }

  /// Checks if a reminder notification was already registered to prevent duplicates.
  Future<bool> markNotificationTriggered(String reminderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_notifiedKey) ?? [];
      if (list.contains(reminderId)) return false;
      list.add(reminderId);
      await prefs.setStringList(_notifiedKey, list);
      return true;
    } catch (_) {
      return true;
    }
  }
}
