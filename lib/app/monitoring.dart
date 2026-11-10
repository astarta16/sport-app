import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../core/services/error_reporter.dart';

/// Crashlytics sink (mobile, Firebase mode). Collection starts disabled and
/// is enabled only with the user's diagnostics consent; reports carry only
/// redacted, categorized reasons — never chat text, codes, tokens or
/// medical data. Not used on web (unsupported) or in demo mode.
class CrashlyticsSink implements CrashSink {
  CrashlyticsSink(this.c);

  final FirebaseCrashlytics c;

  @override
  Future<void> record(Object error, StackTrace? stack, {required String reason, required bool fatal}) =>
      c.recordError(error.runtimeType, stack, reason: reason, fatal: fatal);

  @override
  Future<void> log(String message) => c.log(message);

  @override
  Future<void> setEnabled(bool enabled) => c.setCrashlyticsCollectionEnabled(enabled);
}

Future<void> initMonitoring() async {
  if (kIsWeb) return;
  final c = FirebaseCrashlytics.instance;
  await c.setCrashlyticsCollectionEnabled(false);
  ErrorReporter.install(CrashlyticsSink(c));
  ErrorReporter.hookFlutterErrors();
}
