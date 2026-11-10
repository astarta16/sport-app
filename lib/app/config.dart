import 'package:flutter/foundation.dart';

enum AppMode { demo, firebase }

/// Build-time configuration via `--dart-define`.
///
/// * `APP_MODE=demo|firebase` — debug builds default to demo, release builds
///   default to firebase. Release builds refuse demo unless
///   `ALLOW_DEMO_IN_RELEASE=true` is passed explicitly, so demo data can
///   never ship to production by accident.
/// * `USE_FIREBASE_EMULATOR=true` — point Firebase SDKs at local emulators.
class AppConfig {
  AppConfig._();

  static const _modeRaw = String.fromEnvironment('APP_MODE');
  static const _allowDemoInRelease = bool.fromEnvironment('ALLOW_DEMO_IN_RELEASE');
  static const useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
  static const emulatorHost = String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');
  static const version = '1.0.0';

  static AppMode get mode {
    final requested = switch (_modeRaw) {
      'demo' => AppMode.demo,
      'firebase' => AppMode.firebase,
      _ => kReleaseMode ? AppMode.firebase : AppMode.demo,
    };
    if (requested == AppMode.demo && kReleaseMode && !_allowDemoInRelease) return AppMode.firebase;
    return requested;
  }

  static bool get isDemo => mode == AppMode.demo;
}
