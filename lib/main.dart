import 'package:flutter/material.dart';
import 'package:raigon_art/core/network/auth_token_manager.dart';

import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize stored authentication session
  await AuthTokenManager.instance.init();

  runApp(const RaigonartApp());
}
