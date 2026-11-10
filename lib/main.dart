import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/config.dart';
import 'app/demo_overrides.dart';
import 'app/di.dart';
import 'app/firebase_bootstrap.dart';
import 'app/monitoring.dart';
import 'core/theme/app_theme.dart';
import 'features/demo/data/demo_seed.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();

  final List<Override> overrides;
  if (AppConfig.mode == AppMode.demo) {
    // Fictional in-memory data only; never constructed in Firebase mode.
    overrides = demoOverrides(DemoSeed.create());
  } else {
    try {
      overrides = await firebaseOverrides();
      await initMonitoring();
    } catch (e) {
      runApp(_ConfigErrorApp(error: e));
      return;
    }
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs), ...overrides],
      // Repository errors (e.g. permission denied) are final; don't auto-retry.
      retry: (_, _) => null,
      child: const SportParentApp(),
    ),
  );
}

/// Shown when Firebase mode is selected but the project isn't configured.
class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Firebase არ არის კონფიგურირებული / Firebase is not configured',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text('flutterfire configure  ·  --dart-define=APP_MODE=demo', textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('$error', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
