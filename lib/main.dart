import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:raigon_art/core/network/auth_token_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

const String _kFallbackSupabaseUrl = 'https://nhqewkbztfmlophtzqmk.supabase.co';
const String _kFallbackSupabaseKey =
    'sb_publishable_K1zyH5jkmCBZ-wHVCXd32g_7JTzuYvl';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[main] Note: .env could not be loaded: $e');
  }

  const envUrl = String.fromEnvironment('SUPABASE_URL');
  const envKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  final supabaseUrl = envUrl.isNotEmpty
      ? envUrl
      : (dotenv.env['SUPABASE_URL']?.trim().isNotEmpty == true
            ? dotenv.env['SUPABASE_URL']!.trim()
            : _kFallbackSupabaseUrl);

  final supabaseKey = envKey.isNotEmpty
      ? envKey
      : (dotenv.env['SUPABASE_PUBLISHABLE_KEY']?.trim().isNotEmpty == true
            ? dotenv.env['SUPABASE_PUBLISHABLE_KEY']!.trim()
            : _kFallbackSupabaseKey);

  try {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  } catch (e) {
    debugPrint('[main] Supabase initialization error: $e');
  }

  try {
    await AuthTokenManager.instance.init();
  } catch (e) {
    debugPrint('[main] AuthTokenManager initialization error: $e');
  }

  runApp(const RaigonartApp());
}
