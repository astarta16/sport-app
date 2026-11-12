import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_parent_app/features/calendar/domain/ics.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/trainings/domain/training.dart';

import '../responsive/responsive_screens_test.dart' show boot, signInAs, visit, pumpFrames, expectNoLayoutErrors;

void main() {
  group('Ics.build', () {
    final stamp = DateTime.utc(2026, 11, 12, 9);
    final ev = IcsEvent(
      uid: 'training-t1',
      start: DateTime.utc(2026, 11, 14, 14, 30),
      end: DateTime.utc(2026, 11, 14, 16),
      summary: 'ვარჯიში · U-10, ფეხბურთი; ბურთის კონტროლი',
      location: 'Dinamo Arena, Tbilisi',
      description: 'line 1\nline 2',
    );

    test('valid calendar with CRLF lines, UTC times, alarm and escaping', () {
      final s = Ics.build([ev], stamp: stamp);
      expect(s, startsWith('BEGIN:VCALENDAR\r\nVERSION:2.0\r\n'));
      expect(s, endsWith('END:VCALENDAR\r\n'));
      expect(s.replaceAll('\r\n', '').contains('\n'), isFalse, reason: 'only CRLF line breaks');
      final unfolded = s.replaceAll('\r\n ', '');
      expect(unfolded, contains('DTSTART:20261114T143000Z'));
      expect(unfolded, contains('DTEND:20261114T160000Z'));
      expect(unfolded, contains('UID:training-t1@${Ics.domain}'));
      expect(unfolded, contains(r'SUMMARY:ვარჯიში · U-10\, ფეხბურთი\; ბურთის კონტროლი'));
      expect(unfolded, contains(r'LOCATION:Dinamo Arena\, Tbilisi'));
      expect(unfolded, contains(r'DESCRIPTION:line 1\nline 2'));
      expect(unfolded, contains('TRIGGER:-PT60M'));
      expect(unfolded, contains('STATUS:CONFIRMED'));
    });

    test('long Georgian lines fold at ≤ 75 octets without splitting a letter', () {
      final s = Ics.build([IcsEvent(uid: 'x', start: ev.start, end: ev.end, summary: 'ფეხბურთი ' * 20)], stamp: stamp);
      for (final line in s.split('\r\n')) {
        expect(utf8.encode(line).length, lessThanOrEqualTo(75), reason: line);
      }
      expect(utf8.decode(utf8.encode(s)), s, reason: 'still valid UTF-8');
      expect(s.replaceAll('\r\n ', ''), contains('SUMMARY:${'ფეხბურთი ' * 19}ფეხბურთი'));
    });

    test('cancelled events have no alarm; zero-length events get one hour', () {
      final s = Ics.build([
        IcsEvent(uid: 'c', start: ev.start, end: ev.start, summary: 'x', cancelled: true),
      ], stamp: stamp);
      expect(s, contains('STATUS:CANCELLED'));
      expect(s, isNot(contains('VALARM')));
      expect(s, contains('DTEND:20261114T153000Z'));
    });

    test('file name has kind, safe slug and timestamp', () {
      expect(Ics.fileName('training', 'a/b c', DateTime(2026, 11, 12, 9, 5)), 'training_a-b-c_20261112-0905.ics');
    });
  });

  group('add to calendar UI', () {
    setUpAll(() => initializeDateFormatting());
    setUp(() {
      final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      m.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        (_) async => 'dev.fluttercommunity.plus/share/unavailable',
      );
      m.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => Directory.systemTemp.path,
      );
    });

    Future<void> tapShare(WidgetTester tester, String key) async {
      final f = find.byKey(Key(key));
      await tester.ensureVisible(f);
      await pumpFrames(tester);
      await tester.runAsync(() async {
        await tester.tap(f);
        for (var i = 0; i < 20; i++) {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await pumpFrames(tester);
    }

    Future<void> dismissSnacks(WidgetTester tester) async {
      for (final m in tester.stateList<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))) {
        m.removeCurrentSnackBar();
      }
      await pumpFrames(tester);
    }

    testWidgets('parent adds a training and exports the schedule', (tester) async {
      final db = await boot(tester, const Size(390, 844));
      await signInAs(tester, db, DemoIds.parent);
      final now = db.clock();
      final upcoming = db.trainings.values.firstWhere(
        (t) => t.groupId == 'g-football-u10' && t.startAt.isAfter(now) && t.status != TrainingStatus.cancelled,
      );
      await visit(tester, 'training', ['/training/${upcoming.id}']);
      await tapShare(tester, 'training-add-calendar');
      expect(find.textContaining('training_${upcoming.id}_'), findsWidgets);
      await dismissSnacks(tester);
      expectNoLayoutErrors();

      await visit(tester, 'calendar', ['/parent/calendar']);
      await tapShare(tester, 'calendar-export');
      expect(find.textContaining('schedule_'), findsWidgets);
      await dismissSnacks(tester);
      expectNoLayoutErrors();
    });

    testWidgets('match detail offers add to calendar (narrow phone, Russian)', (tester) async {
      final db = await boot(tester, const Size(320, 640), locale: 'ru');
      await signInAs(tester, db, DemoIds.parent);
      await visit(tester, 'match', ['/match/match-1']);
      final m = db.matches['match-1']!;
      if (m.status.name == 'cancelled') {
        expect(find.byKey(const Key('match-add-calendar')), findsNothing);
      } else {
        await tapShare(tester, 'match-add-calendar');
        expect(find.textContaining('match_match-1_'), findsWidgets);
        await dismissSnacks(tester);
      }
      expectNoLayoutErrors();
    });
  });
}
