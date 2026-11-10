import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../app/config.dart';
import '../errors/app_exception.dart';

/// Error categories used in logs and crash reports.
enum ErrorCategory { permission, validation, network, notFound, auth, unexpected }

ErrorCategory categorize(Object error) => switch (error) {
  PermissionDeniedException() => ErrorCategory.permission,
  ValidationException() => ErrorCategory.validation,
  BackendUnavailableException() => ErrorCategory.network,
  NotFoundException() => ErrorCategory.notFound,
  AuthException() => ErrorCategory.auth,
  TimeoutException() => ErrorCategory.network,
  _ => ErrorCategory.unexpected,
};

/// Removes data that must never reach logs or crash reports: phone numbers,
/// 6-digit SMS codes, bearer/ID tokens, emails, storage paths of medical
/// files and long free text (possible chat content).
String redact(String input) {
  var s = input;
  s = s.replaceAll(RegExp(r'(Bearer\s+)?eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+'), '<token>');
  s = s.replaceAll(RegExp(r'\+?995[\s-]?\d{3}[\s-]?\d{2}[\s-]?\d{2}[\s-]?\d{2}'), '<phone>');
  s = s.replaceAll(RegExp(r'\b5\d{2}[\s-]?\d{2}[\s-]?\d{2}[\s-]?\d{2}\b'), '<phone>');
  s = s.replaceAll(RegExp(r'\b\d{6}\b'), '<code>');
  s = s.replaceAll(RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+'), '<email>');
  s = s.replaceAll(RegExp(r'medical/[^\s"]+'), 'medical/<redacted>');
  s = s.replaceAll(RegExp(r'"text"\s*:\s*"[^"]*"'), '"text":"<redacted>"');
  return s.length > 500 ? '${s.substring(0, 500)}…' : s;
}

/// Pluggable sink (Crashlytics in Firebase mode, debug console otherwise).
abstract interface class CrashSink {
  Future<void> record(Object error, StackTrace? stack, {required String reason, required bool fatal});
  Future<void> log(String message);
  Future<void> setEnabled(bool enabled);
}

class _DebugSink implements CrashSink {
  @override
  Future<void> record(Object error, StackTrace? stack, {required String reason, required bool fatal}) async =>
      debugPrint('[error] $reason');

  @override
  Future<void> log(String message) async => debugPrint('[log] $message');

  @override
  Future<void> setEnabled(bool enabled) async {}
}

/// Structured, privacy-safe error reporting. Only `unexpected` errors are
/// sent as non-fatal reports; expected outcomes (validation, permission,
/// offline) are logged locally with their category only.
class ErrorReporter {
  ErrorReporter._();

  static CrashSink _sink = _DebugSink();
  static CrashSink get sink => _sink;

  static void install(CrashSink sink) => _sink = sink;

  /// Diagnostics are opt-in (privacy setting "anonymous diagnostics").
  static Future<void> setConsent(bool consent) => _sink.setEnabled(consent && !AppConfig.isDemo);

  static Future<void> report(Object error, StackTrace? stack, {String context = '', bool fatal = false}) async {
    final category = categorize(error);
    final reason = redact(
      '${category.name} · ${AppConfig.environment.name} · ${AppConfig.version}+${AppConfig.buildNumber} · $context · ${error.runtimeType}${error is AppException ? '(${error.code})' : ''}',
    );
    if (category == ErrorCategory.unexpected || fatal) {
      await _sink.record(error, stack, reason: reason, fatal: fatal);
    } else {
      await _sink.log(reason);
    }
  }

  /// Hooks Flutter and zone errors.
  static void hookFlutterErrors() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      previous?.call(details);
      report(details.exception, details.stack, context: 'flutter', fatal: false);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack, context: 'platform', fatal: true);
      return true;
    };
  }
}
