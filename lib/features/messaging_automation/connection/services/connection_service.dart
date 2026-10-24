import 'package:supabase_flutter/supabase_flutter.dart';

/// Talks to the `instagram-oauth` edge function.
class ConnectionService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Returns the connected Instagram username, or null when not connected.
  Future<String?> instagramStatus() async {
    if (_client.auth.currentSession == null) return null;

    final response = await _client.functions.invoke(
      'instagram-oauth',
      method: HttpMethod.get,
      queryParameters: {'action': 'status'},
    );

    final data = response.data;
    if (response.status < 200 || response.status >= 300 || data is! Map) {
      throw Exception('Could not check your Instagram connection.');
    }

    final accounts = data['accounts'];
    if (data['connected'] == true &&
        accounts is List &&
        accounts.isNotEmpty &&
        accounts.first is Map) {
      return (accounts.first as Map)['username']?.toString() ?? 'Instagram';
    }
    return null;
  }

  /// Starts the OAuth flow and returns the validated Instagram URL.
  Future<Uri> instagramAuthUri() async {
    if (_client.auth.currentSession == null) {
      throw Exception('Please sign in before connecting Instagram.');
    }

    final response = await _client.functions.invoke(
      'instagram-oauth',
      body: {'action': 'start'},
    );

    final data = response.data;
    if (response.status < 200 ||
        response.status >= 300 ||
        data is! Map ||
        data['authorization_url'] is! String) {
      throw Exception(
        data is Map
            ? '${data['error'] ?? 'Could not start Instagram authorization.'}'
            : 'Invalid response from Instagram OAuth.',
      );
    }

    final uri = Uri.tryParse(data['authorization_url'] as String);
    if (uri == null || uri.scheme != 'https' || uri.host != 'www.instagram.com') {
      throw Exception('The Instagram authorization URL is invalid.');
    }
    return uri;
  }
}
