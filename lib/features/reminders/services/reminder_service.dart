import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raigon_art/core/network/api_client.dart';
import 'package:raigon_art/core/network/api_constants.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
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

  /// Loads all reminders from local storage and syncs with Supabase (priority) and REST API.
  Future<List<CustomerReminder>> getReminders() async {
    final localList = await _loadLocalReminders();
    final localMap = <String, CustomerReminder>{for (final r in localList) r.id: r};
    final mergedMap = <String, CustomerReminder>{};
    bool remoteSucceeded = false;

    // 1. Remote fetch from Supabase (shared cloud PostgreSQL database for mobile & web)
    try {
      final client = _supabase;
      if (client != null) {
        final res = await client
            .from('reminders')
            .select()
            .neq('is_deleted', true)
            .order('reminder_date', ascending: true);

        final remoteList = (res as List)
            .map(
              (row) => CustomerReminder.fromJson(
                Map<String, dynamic>.from(row as Map),
              ),
            )
            .toList();

        for (final r in remoteList) {
          final existing = localMap[r.id];
          mergedMap[r.id] = existing != null ? _merge(existing, r) : r;
        }
        remoteSucceeded = true;
      }
    } catch (e) {
      debugPrint('[ReminderService] Supabase remote fetch notice: $e');
    }

    // 2. Remote fetch from REST API (with resilient timeout for cold starts)
    try {
      final res = await ApiClient()
          .get(ApiConstants.reminders)
          .timeout(const Duration(seconds: 15));

      List<dynamic>? rawList;
      if (res is List) {
        rawList = res;
      } else if (res is Map && res['data'] is List) {
        rawList = res['data'] as List;
      }

      if (rawList != null) {
        final apiList = rawList
            .map(
              (item) => CustomerReminder.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();

        for (final r in apiList) {
          final existing = localMap[r.id] ?? mergedMap[r.id];
          mergedMap[r.id] = existing != null ? _merge(existing, r) : r;
        }
        remoteSucceeded = true;
      }
    } catch (e) {
      debugPrint('[ReminderService] REST API fetch notice: $e');
    }

    List<CustomerReminder> result;
    if (remoteSucceeded) {
      // Also keep any local-only pending reminders that haven't been synced or deleted
      for (final r in localList) {
        if (!mergedMap.containsKey(r.id)) {
          final age = DateTime.now().difference(r.createdAt);
          if (age.inMinutes < 2) {
            mergedMap[r.id] = r;
          }
        }
      }
      result = mergedMap.values.toList();
    } else {
      result = localList;
    }

    await _saveLocalReminders(result);
    return result;
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
      debugPrint(
        '[ReminderService] Supabase upsert notice: $e (stored locally)',
      );
    }

    // Sync to REST API
    try {
      await ApiClient().post(ApiConstants.reminders, body: reminder.toJson());
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
        await client
            .from('reminders')
            .update({
              'is_completed': true,
              'status': 'completed',
              'completed_at': updated.completedAt!.toIso8601String(),
              'completed_by': completedBy,
            })
            .eq('id', id);
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
          'isCompleted': true,
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

    final updated = list[index].copyWith(
      isCompleted: false,
      completedAt: null,
      completedBy: null,
    );

    list[index] = updated;
    await _saveLocalReminders(list);

    try {
      final client = _supabase;
      if (client != null) {
        await client
            .from('reminders')
            .update({
              'is_completed': false,
              'status': 'pending',
              'completed_at': null,
              'completed_by': null,
            })
            .eq('id', id);
      }
    } catch (e) {
      debugPrint('[ReminderService] Supabase reopen notice: $e');
    }

    // Sync to REST API
    try {
      await ApiClient().patch(
        ApiConstants.reminder(id),
        body: {
          'status': 'pending',
          'isCompleted': false,
          'completedBy': null,
          'completedAt': null,
        },
      );
    } catch (e) {
      debugPrint('[ReminderService] REST API reopen notice: $e');
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
        await client.from('reminders').update({
          'is_deleted': true,
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', id);
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
            .map(
              (e) => CustomerReminder.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
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

  static CustomerReminder _merge(
    CustomerReminder local,
    CustomerReminder remote,
  ) {
    final mergedNotes = <OrderVoiceNote>[];
    if (remote.effectiveVoiceNotes.isNotEmpty) {
      for (final rNote in remote.effectiveVoiceNotes) {
        final match = local.effectiveVoiceNotes.where(
          (l) => l.id == rNote.id || (l.url.isNotEmpty && l.url == rNote.url),
        );
        final localMatch = match.isNotEmpty ? match.first : null;
        mergedNotes.add(
          rNote.copyWith(
            localBytes: rNote.localBytes ?? localMatch?.localBytes,
          ),
        );
      }
    } else {
      mergedNotes.addAll(local.effectiveVoiceNotes);
    }

    final voiceUrl = remote.voiceUrl.isNotEmpty
        ? remote.voiceUrl
        : (mergedNotes.isNotEmpty ? mergedNotes.first.url : local.voiceUrl);
    final voiceDur = remote.voiceDurationSeconds > 0
        ? remote.voiceDurationSeconds
        : (mergedNotes.isNotEmpty
            ? mergedNotes.first.durationSeconds
            : local.voiceDurationSeconds);

    return remote.copyWith(
      voiceUrl: voiceUrl,
      voiceDurationSeconds: voiceDur,
      voiceBytes: remote.voiceBytes ?? local.voiceBytes,
      voiceNotes: mergedNotes,
    );
  }
}
