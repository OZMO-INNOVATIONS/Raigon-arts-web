import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:raigon_art/core/network/auth_token_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables.
  await dotenv.load(fileName: '.env');

  // Supabase configuration.
  final supabaseUrl = dotenv.env['SUPABASE_URL']!.trim();
  final supabaseKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY']!.trim();

  // Initialize Supabase.
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);

  // Initialize authentication.
  await AuthTokenManager.instance.init();

  runApp(const RaigonartApp());
}
