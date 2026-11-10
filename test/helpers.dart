import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_parent_app/app/demo_overrides.dart';
import 'package:sport_parent_app/app/di.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';

final testNow = DateTime(2026, 11, 10, 10); // Tuesday morning

Future<(DemoBackend, List<Override>)> demoSetup({Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final db = DemoSeed.create(clock: () => testNow);
  return (db, [sharedPreferencesProvider.overrideWithValue(sp), ...demoOverrides(db)]);
}

ProviderContainer container(List<Override> overrides) => ProviderContainer(overrides: overrides, retry: (_, _) => null);
