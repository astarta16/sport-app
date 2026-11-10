import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/core/errors/app_exception.dart';
import 'package:sport_parent_app/core/services/error_reporter.dart';

class _Sink implements CrashSink {
  final records = <String>[];
  final logs = <String>[];
  @override
  Future<void> record(Object error, StackTrace? stack, {required String reason, required bool fatal}) async =>
      records.add(reason);
  @override
  Future<void> log(String message) async => logs.add(message);
  @override
  Future<void> setEnabled(bool enabled) async {}
}

void main() {
  test('redaction removes phones, SMS codes, tokens, emails, medical paths and chat text', () {
    final out = redact(
      'user +995 555 00 01 01 code 123456 token eyJabc.def.ghi mail a@b.ge medical/child-1/cert-9 {"text":"secret chat"} 555123456',
    );
    expect(out, isNot(contains('555 00 01 01')));
    expect(out, isNot(contains('123456')));
    expect(out, isNot(contains('eyJabc')));
    expect(out, isNot(contains('a@b.ge')));
    expect(out, isNot(contains('child-1/cert-9')));
    expect(out, isNot(contains('secret chat')));
    expect(out, isNot(contains('555123456')));
  });

  test('expected errors are only logged; unexpected ones are reported, categorized', () async {
    final sink = _Sink();
    ErrorReporter.install(sink);
    await ErrorReporter.report(const ValidationException('startInPast'), null);
    await ErrorReporter.report(const PermissionDeniedException(), null);
    await ErrorReporter.report(StateError('boom'), StackTrace.current, context: 'x');
    expect(sink.logs, hasLength(2));
    expect(sink.logs.first, contains('validation'));
    expect(sink.records.single, contains('unexpected'));
    expect(categorize(const BackendUnavailableException()), ErrorCategory.network);
  });
}
