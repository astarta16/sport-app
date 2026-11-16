import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_parent_app/app/demo_overrides.dart';
import 'package:sport_parent_app/app/di.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/brain_academy/presentation/game_fx.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';

final testNow = DateTime(2026, 11, 10, 10); // Tuesday morning

Future<(DemoBackend, List<Override>)> demoSetup({Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final db = DemoSeed.create(clock: () => testNow);
  return (
    db,
    [
      sharedPreferencesProvider.overrideWithValue(sp),
      soundPlayerProvider.overrideWithValue(testSounds..played.clear()),
      ...demoOverrides(db),
    ],
  );
}

ProviderContainer container(List<Override> overrides) => ProviderContainer(overrides: overrides, retry: (_, _) => null);

/// Records sounds instead of playing them (no audio plugin in tests).
class RecordingSoundPlayer implements SoundPlayer {
  final played = <GameSound>[];

  @override
  Future<void> play(GameSound s) async => played.add(s);
}

final testSounds = RecordingSoundPlayer();
