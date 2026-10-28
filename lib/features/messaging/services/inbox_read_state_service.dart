import 'package:supabase_flutter/supabase_flutter.dart';

class InboxReadStateService {
  InboxReadStateService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, DateTime>> loadReadStates() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in to load inbox read states.');
    }

    final rows = await _client
        .from('inbox_read_states')
        .select('channel, conversation_key, last_read_at')
        .eq('user_id', user.id);

    final result = <String, DateTime>{};

    for (final row in rows) {
      final channel = row['channel']?.toString();
      final key = row['conversation_key']?.toString();
      final rawTime = row['last_read_at']?.toString();
      final time = DateTime.tryParse(rawTime ?? '');

      if (channel == null || key == null || time == null) continue;

      result['$channel:$key'] = time.toUtc();
    }

    return result;
  }

  Future<void> markRead({
    required String channel,
    required String conversationKey,
    required DateTime lastReadAt,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in to save inbox read states.');
    }

    await _client.from('inbox_read_states').upsert({
      'user_id': user.id,
      'channel': channel,
      'conversation_key': conversationKey,
      'last_read_at': lastReadAt.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,channel,conversation_key');
  }
}
