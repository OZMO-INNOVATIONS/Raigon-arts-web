import 'package:flutter/material.dart';
import 'package:raigon_art/core/network/auth_token_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initializ Supabase
  await Supabase.initialize(
    url: 'https://nhqewkbztfmlophtzqmk.supabase.co',
    publishableKey: 'sb_publishable_K1zyH5jkmCBZ-wHVCXd32g_7JTzuYvl',
  );

  // Initialize stored authentication session
  await AuthTokenManager.instance.init();

  runApp(const RaigonartApp());
}
