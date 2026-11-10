import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin/admin_app.dart';
import 'app/config.dart';
import 'app/demo_overrides.dart';
import 'app/di.dart';
import 'app/firebase_bootstrap.dart';
import 'features/demo/data/demo_seed.dart';

/// Admin web dashboard entry point (v1.2). Shares the domain, repositories
/// and demo backend with the mobile app; every admin action is re-checked
/// server-side (custom claims), the UI only hides what the role can't do.
///
///   flutter run -d chrome -t lib/main_admin.dart            # demo
///   flutter build web -t lib/main_admin.dart --dart-define=APP_MODE=demo \
///     --dart-define=ALLOW_DEMO_IN_RELEASE=true -o build/admin_web
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();
  final List<Override> overrides = AppConfig.mode == AppMode.demo
      ? demoOverrides(DemoSeed.create())
      : await firebaseOverrides();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs), ...overrides],
      retry: (_, _) => null,
      child: const AdminApp(),
    ),
  );
}
