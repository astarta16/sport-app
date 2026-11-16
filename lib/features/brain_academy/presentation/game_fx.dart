import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';

enum GameSound {
  tap('tap'),
  correct('correct'),
  wrong('wrong'),
  levelComplete('level_complete'),
  fail('fail'),
  reward('reward'),
  tick('tick');

  const GameSound(this.file);
  final String file;
}

/// Brain Academy feedback settings (persisted on the device). There is no
/// background music, so only sound effects and haptics are configurable.
class BrainSettings {
  const BrainSettings({this.sound = true, this.haptics = true});

  final bool sound;
  final bool haptics;

  BrainSettings copyWith({bool? sound, bool? haptics}) =>
      BrainSettings(sound: sound ?? this.sound, haptics: haptics ?? this.haptics);
}

class BrainSettingsNotifier extends Notifier<BrainSettings> {
  static const soundKey = 'brain.sound';
  static const hapticsKey = 'brain.haptics';

  @override
  BrainSettings build() {
    try {
      final p = ref.watch(sharedPreferencesProvider);
      return BrainSettings(sound: p.getBool(soundKey) ?? true, haptics: p.getBool(hapticsKey) ?? true);
    } catch (_) {
      return const BrainSettings();
    }
  }

  Future<void> setSound(bool v) async {
    state = state.copyWith(sound: v);
    try {
      await ref.read(sharedPreferencesProvider).setBool(soundKey, v);
    } catch (_) {}
  }

  Future<void> setHaptics(bool v) async {
    state = state.copyWith(haptics: v);
    try {
      await ref.read(sharedPreferencesProvider).setBool(hapticsKey, v);
    } catch (_) {}
  }
}

final brainSettingsProvider = NotifierProvider<BrainSettingsNotifier, BrainSettings>(BrainSettingsNotifier.new);

/// Plays one bundled sound (assets/sounds). Tests replace it.
abstract interface class SoundPlayer {
  Future<void> play(GameSound s);
}

class AudioSoundPlayer implements SoundPlayer {
  final _players = <GameSound, AudioPlayer>{};

  @override
  Future<void> play(GameSound s) async {
    try {
      final p = _players[s] ??= AudioPlayer()
        ..setPlayerMode(PlayerMode.lowLatency)
        ..setReleaseMode(ReleaseMode.stop);
      await p.stop();
      await p.play(AssetSource('sounds/${s.file}.wav'), volume: s == GameSound.tick ? 0.5 : 0.8);
    } catch (_) {
      // Sound is optional — never break a game because audio is unavailable.
    }
  }
}

final soundPlayerProvider = Provider<SoundPlayer>((_) => AudioSoundPlayer());

/// One call per game event: sound (if on) + haptic (if on).
class GameFx {
  GameFx(this._settings, this._player);

  final BrainSettings Function() _settings;
  final SoundPlayer _player;

  Future<void> _go(GameSound s, Future<void> Function() haptic) async {
    final st = _settings();
    if (st.sound) unawaited(_player.play(s));
    if (st.haptics) {
      try {
        await haptic();
      } catch (_) {}
    }
  }

  Future<void> tap() => _go(GameSound.tap, HapticFeedback.selectionClick);
  Future<void> correct() => _go(GameSound.correct, HapticFeedback.lightImpact);
  Future<void> wrong() => _go(GameSound.wrong, HapticFeedback.heavyImpact);
  Future<void> tick() => _go(GameSound.tick, HapticFeedback.selectionClick);
  Future<void> fail() => _go(GameSound.fail, HapticFeedback.mediumImpact);
  Future<void> reward() => _go(GameSound.reward, HapticFeedback.lightImpact);
  Future<void> levelComplete() => _go(GameSound.levelComplete, () async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.heavyImpact();
  });
}

final gameFxProvider = Provider<GameFx>(
  (ref) => GameFx(() => ref.read(brainSettingsProvider), ref.watch(soundPlayerProvider)),
);
