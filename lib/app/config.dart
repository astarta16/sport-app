import 'package:flutter/foundation.dart';

enum AppMode { demo, firebase }

/// Deployment environment. Demo never touches Firebase; dev/staging/prod
/// each need their own Firebase project (separate `flutterfire configure`
/// outputs, see docs/firebase-setup.md).
enum AppEnvironment { demo, dev, staging, prod }

/// Build-time configuration via `--dart-define`.
///
/// * `APP_MODE=demo|firebase` — debug builds default to demo, release builds
///   default to firebase. Release builds refuse demo unless
///   `ALLOW_DEMO_IN_RELEASE=true` is passed explicitly, so demo data can
///   never ship to production by accident.
/// * `APP_ENV=dev|staging|prod` — which Firebase project the build targets
///   (Firebase mode only; demo mode always reports `demo`).
/// * `USE_FIREBASE_EMULATOR=true` — point Firebase SDKs at local emulators.
class AppConfig {
  AppConfig._();

  static const _modeRaw = String.fromEnvironment('APP_MODE');
  static const _envRaw = String.fromEnvironment('APP_ENV');
  static const _allowDemoInRelease = bool.fromEnvironment('ALLOW_DEMO_IN_RELEASE');
  static const useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
  static const emulatorHost = String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');
  static const version = '1.6.1-beta';
  static const buildNumber = String.fromEnvironment('BUILD_NUMBER', defaultValue: '12');

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

  /// Demo mode is always the `demo` environment, so a demo build can never be
  /// pointed at production services. Firebase builds default to `dev` in
  /// debug and must name `prod` explicitly for release.
  static AppEnvironment get environment {
    if (isDemo) return AppEnvironment.demo;
    return switch (_envRaw) {
      'prod' => AppEnvironment.prod,
      'staging' => AppEnvironment.staging,
      'dev' => AppEnvironment.dev,
      _ => kReleaseMode ? AppEnvironment.staging : AppEnvironment.dev,
    };
  }
}
