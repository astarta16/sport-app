import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_parent_app/admin/admin_app.dart';
import 'package:sport_parent_app/features/attendance/domain/attendance.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed_v17.dart';
import 'package:sport_parent_app/features/organizations/domain/coach_contact.dart';
import 'package:sport_parent_app/features/organizations/domain/organization.dart';
import 'package:sport_parent_app/features/organizations/domain/scheduling.dart';
import 'package:sport_parent_app/features/trainings/domain/training.dart';

import '../helpers.dart';
import '../responsive/responsive_screens_test.dart' show boot, signInAs, visit, pumpFrames, expectNoLayoutErrors;

const phone = Size(390, 844);
const narrow = Size(320, 640);

/// Scrolls whichever vertical list holds [f] (up or down) until it is built.
Future<void> _reveal(WidgetTester tester, Finder f) async {
  if (f.evaluate().isNotEmpty) return;
  final lists = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
  for (var i = lists.evaluate().length - 1; i >= 0 && f.evaluate().isEmpty; i--) {
    for (final delta in [250.0, -250.0]) {
      if (f.evaluate().isNotEmpty) break;
      try {
        await tester.scrollUntilVisible(f, delta, scrollable: lists.at(i), maxScrolls: 40);
      } on StateError {
        // not in this list / this direction
      } on TestFailure {
        // not in this list / this direction
      }
    }
  }
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  for (final m in find.byType(ScaffoldMessenger).evaluate()) {
    (m as StatefulElement).state is ScaffoldMessengerState
        ? (m.state as ScaffoldMessengerState).clearSnackBars()
        : null;
  }
  await pumpFrames(tester, 1);
  await _reveal(tester, f);
  await tester.ensureVisible(f.first);
  await pumpFrames(tester, 2);
  await _clearBottomBar(tester, f.first);
  await tester.tap(f.first);
  await pumpFrames(tester);
}

Future<void> scrollTo(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await _reveal(tester, f);
  await tester.ensureVisible(f.first);
  await pumpFrames(tester, 2);
}

/// ensureVisible() may leave a widget under the bottom navigation bar.
Future<void> _clearBottomBar(WidgetTester tester, Finder f) async {
  final h = tester.view.physicalSize.height / tester.view.devicePixelRatio;
  if (tester.getRect(f).bottom <= h - 110) return;
  final scrollables = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
  if (scrollables.evaluate().isEmpty) return;
  await tester.drag(scrollables.first, const Offset(0, -160), warnIfMissed: false);
  await pumpFrames(tester, 2);
}

Finder keyPrefix(String prefix, {String? suffix}) => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith(prefix) &&
      (suffix == null || (w.key! as ValueKey<String>).value.endsWith(suffix)),
);

Future<DemoBackend> bootAdmin(WidgetTester tester, {Size size = const Size(1440, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final (db, overrides) = await demoSetup();
  await tester.pumpWidget(ProviderScope(overrides: overrides, retry: (_, _) => null, child: const AdminApp()));
  await pumpFrames(tester, 6);
  return db;
}

Future<void> adminSignIn(WidgetTester tester, String uid) async {
  await tapKey(tester, 'admin-demo-$uid');
}

void main() {
  setUpAll(() => initializeDateFormatting());

  group('parent: RSVP, reconfirmation and acknowledgment', () {
    for (final size in [phone, narrow]) {
      testWidgets('rescheduled training at ${size.width.toInt()} px', (tester) async {
        final db = await boot(tester, size);
        await signInAs(tester, db, DemoSeedV17.tianetiParent);
        await visit(tester, 'resched', ['/training/${DemoSeedV17.rescheduledTraining}']);
        await scrollTo(tester, 'schedule-change-ack');
        expect(find.byKey(const Key('schedule-change-ack')), findsOneWidget);
        await scrollTo(tester, 'reconfirm-child-t2');
        expect(find.byKey(const Key('rsvp-previous-child-t2')), findsOneWidget);
        expect(find.byKey(const Key('rsvp-schedule-child-t2')), findsOneWidget, reason: 'current schedule shown first');
        await tapKey(tester, 'rsvp-child-t2-yes');
        final r = db.rsvps[Rsvp.docId(DemoSeedV17.rescheduledTraining, 'child-t2')]!;
        expect(r.response, RsvpResponse.yes);
        expect(r.scheduleVersion, 2);
        expect(find.byKey(const Key('reconfirm-child-t2')), findsNothing);
        // Acknowledging is a separate step and does not change the RSVP.
        await tapKey(tester, 'schedule-ack-button');
        expect(find.byKey(const Key('schedule-change-ack')), findsNothing);
        expect(db.rsvps[Rsvp.docId(DemoSeedV17.rescheduledTraining, 'child-t1')]!.guardianResponses.length, 2);
        expectNoLayoutErrors();
      });
    }

    testWidgets('coach sees confirmed / needs reconfirmation / no answer counters', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoSeedV17.volleyCoach);
      await visit(tester, 'coach', ['/training/${DemoSeedV17.rescheduledTraining}']);
      await scrollTo(tester, 'coach-attendance-summary');
      Text pill(String s) =>
          tester.widget<Text>(find.descendant(of: find.byKey(Key('rsvp-count-$s')), matching: find.byType(Text)).first);
      expect(pill('confirmed').data, endsWith(': 1'));
      expect(pill('needsReconfirmation').data, endsWith(': 1'));
      expect(pill('notResponded').data, endsWith(': 1'));
      expect(find.byKey(const Key('coach-rsvp-child-t1')), findsOneWidget);
      expectNoLayoutErrors();
    });

    testWidgets('matches: parent RSVP; coach opens the match attendance roster', (tester) async {
      final db = await boot(tester, phone);
      final upcoming = db.matches.values.firstWhere(
        (m) => m.groupId == 'g-football-u10' && m.status.isActive && m.startAt.isAfter(testNow),
      );
      await signInAs(tester, db, DemoIds.parent);
      await visit(tester, 'match', ['/match/${upcoming.id}']);
      await scrollTo(tester, 'rsvp-child-1');
      await tapKey(tester, 'rsvp-child-1-maybe');
      expect(db.rsvps[Rsvp.docId(upcoming.id, 'child-1')]!.eventType, EventType.match);
      await signInAs(tester, db, DemoIds.coach);
      await visit(tester, 'match coach', ['/match/match-past-1']);
      await tapKey(tester, 'open-attendance');
      expect(find.byKey(const Key('attendance-summary')), findsOneWidget);
      await tapKey(tester, 'attendance-mark-all');
      await tapKey(tester, 'attendance-save');
      expect(
        db.attendance.values.where((a) => a.trainingId == 'match-past-1' && a.eventType == EventType.match),
        isNotEmpty,
      );
      expectNoLayoutErrors();
    });

    testWidgets('parent: contact request banner, academy switcher, leaderboard consent', (tester) async {
      final db = await boot(tester, phone);
      db.coachContactRequests['contact-x'] = CoachContactRequest(
        id: 'contact-x',
        childId: 'child-1',
        coachId: DemoIds.coach,
        groupId: 'g-football-u10',
        topic: 'absence',
        createdAt: testNow,
      );
      await signInAs(tester, db, DemoIds.parent);
      await visit(tester, 'home', ['/parent/home']);
      expect(find.byKey(const Key('parent-contact-contact-x')), findsOneWidget);
      expect(find.byKey(const Key('org-switcher')), findsOneWidget);
      await tapKey(tester, 'org-switcher');
      expect(find.byKey(const Key('org-option-${DemoSeedV17.tianeti}')), findsOneWidget);
      await tapKey(tester, 'org-option-${DemoSeedV17.tianeti}');
      await tapKey(tester, 'parent-contact-done-contact-x');
      expect(db.coachContactRequests['contact-x']!.status, ContactRequestStatus.handled);

      await visit(tester, 'child', ['/children/child-1']);
      await scrollTo(tester, 'lb-consent-switch-${DemoSeedV17.tianeti}');
      await tapKey(tester, 'lb-consent-switch-${DemoSeedV17.tianeti}');
      expect(db.leaderboardConsents['${DemoSeedV17.tianeti}|child-1']!.granted, isFalse);
      expectNoLayoutErrors();
    });
  });

  group('student dashboard', () {
    for (final size in [phone, narrow]) {
      testWidgets('events with venues and maps, coach contact, points and leaderboard at ${size.width.toInt()} px', (
        tester,
      ) async {
        final db = await boot(tester, size);
        await signInAs(tester, db, DemoIds.student);
        await scrollTo(tester, 'student-events');
        final card = keyPrefix('student-event-map-');
        await scrollTo(tester, (card.evaluate().first.widget.key! as ValueKey<String>).value);
        await tester.tap(card.first);
        await pumpFrames(tester);
        expect(find.byKey(const Key('venue-map-sheet')), findsOneWidget);
        expect(find.byKey(const Key('venue-marker')), findsOneWidget);
        expect(find.byKey(const Key('venue-map-directions')), findsOneWidget);
        await tester.tapAt(const Offset(10, 10));
        await pumpFrames(tester);

        await tapKey(tester, 'contact-coach-${DemoIds.coach}');
        expect(find.byKey(const Key('contact-coach-sheet')), findsOneWidget);
        await tapKey(tester, 'contact-topic-question');
        expect(db.coachContactRequests.values.single.coachId, DemoIds.coach);
        expect(find.byKey(const Key('contact-pending-${DemoIds.coach}')), findsOneWidget);
        // No phone number of the coach or the guardians is shown to the student.
        expect(find.textContaining('+995'), findsNothing);

        await tapKey(tester, 'student-nav-progress');
        expect(find.byKey(const Key('points-total')), findsOneWidget);
        await scrollTo(tester, 'leaderboard-${DemoSeedV17.tianeti}');
        expect(find.byKey(const Key('lb-row-1')), findsOneWidget);
        expect(find.byKey(const Key('leaderboard-club-1')), findsNothing, reason: 'club-1 has no leaderboard');
        expectNoLayoutErrors();
      });
    }

    testWidgets('a cancelled training is flagged on the student schedule', (tester) async {
      final db = await boot(tester, phone);
      final t = db.trainings.values.firstWhere(
        (x) => x.groupId == 'g-football-u10' && x.startAt.isAfter(testNow) && x.status.isActive,
      );
      db.trainings[t.id] = t.copyWith(status: TrainingStatus.cancelled, cancelReason: 'წვიმა');
      await signInAs(tester, db, DemoIds.student);
      await scrollTo(tester, 'student-event-cancelled-${t.id}');
      expect(find.byKey(Key('student-event-cancelled-${t.id}')), findsOneWidget);
      expectNoLayoutErrors();
    });
  });

  group('admin web', () {
    testWidgets('super admin: separate platform navigation, tenants, plan/modules, create a school', (tester) async {
      final db = await bootAdmin(tester);
      await adminSignIn(tester, DemoIds.platformAdmin);
      expect(find.byKey(const Key('admin-nav-header-0')), findsOneWidget);
      await tapKey(tester, 'admin-nav-/organizations');
      expect(find.byKey(const Key('org-row-${DemoSeedV17.tianeti}')), findsOneWidget);
      expect(find.byKey(const Key('org-row-${DemoSeedV17.mtskheta}')), findsOneWidget);
      await tapKey(tester, 'org-manage-${DemoSeedV17.mtskheta}');
      await tapKey(tester, 'org-allow-leaderboards');
      await tapKey(tester, 'org-platform-save');
      expect(db.orgConfig(DemoSeedV17.mtskheta).allowedModules, contains(OrgModule.leaderboards));
      await tapKey(tester, 'org-health-${DemoSeedV17.tianeti}');
      expect(find.byKey(const Key('org-health')), findsOneWidget);
      await tester.tap(find.text('დახურვა').last);
      await pumpFrames(tester);
      await tapKey(tester, 'org-new');
      await tester.enterText(find.byKey(const Key('org-name-ka')), 'გორის სპორტსკოლა');
      await tester.enterText(find.byKey(const Key('org-name-en')), 'Gori Sports School');
      await tester.enterText(find.byKey(const Key('org-address')), 'გორი');
      await tapKey(tester, 'org-sport-volleyball');
      await tapKey(tester, 'org-create');
      expect(db.clubs.values.any((c) => c.name == 'გორის სპორტსკოლა'), isTrue);
      expectNoLayoutErrors();
    });

    testWidgets('organization admin: no platform pages; settings, rooms, schedule, reports', (tester) async {
      final db = await bootAdmin(tester);
      await adminSignIn(tester, DemoSeedV17.tianetiAdmin);
      expect(find.byKey(const Key('admin-nav-/organizations')), findsNothing);
      expect(find.byKey(const Key('admin-nav-/admins')), findsNothing);

      await tapKey(tester, 'admin-nav-/org-settings');
      await tapKey(tester, 'org-module-media');
      await tapKey(tester, 'org-settings-save');
      expect(db.orgConfig(DemoSeedV17.tianeti).enabledModules, isNot(contains(OrgModule.media)));

      await tapKey(tester, 'admin-nav-/rooms');
      expect(find.byKey(const Key('room-row-${DemoSeedV17.hallA}')), findsOneWidget);
      await tapKey(tester, 'room-new');
      await tester.enterText(find.byKey(const Key('room-name')), 'დარბაზი C');
      await tapKey(tester, 'room-save');
      expect(db.rooms.values.any((r) => r.name == 'დარბაზი C' && r.orgId == DemoSeedV17.tianeti), isTrue);

      await tapKey(tester, 'admin-nav-/schedule');
      expect(find.byKey(const Key('schedule-col-${DemoSeedV17.hallA}')), findsOneWidget);
      expect(find.byKey(const Key('schedule-col-${DemoSeedV17.hallB}')), findsOneWidget);
      // Tuesday 16:30 + 90 min in Hall B collides with badminton at 17:00 →
      // the editor warns before saving (the 17:00 cell itself is covered by
      // the booking chip, which opens the booking instead).
      final busy = keyPrefix('slot-${DemoSeedV17.hallB}-', suffix: '-19');
      await tester.ensureVisible(busy.first);
      await tester.tap(busy.first);
      await pumpFrames(tester);
      expect(find.byKey(const Key('booking-dialog')), findsOneWidget);
      expect(find.byKey(const Key('conflict-roomOverlap')), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('booking-save'))).onPressed, isNull);
      await tester.tap(find.text('დახურვა').last);
      await pumpFrames(tester);
      // 08:00 Hall A is free → booked.
      final before = db.bookings.length;
      final free = keyPrefix('slot-${DemoSeedV17.hallA}-', suffix: '-2');
      await tester.ensureVisible(free.first);
      await tester.tap(free.first);
      await pumpFrames(tester);
      await tapKey(tester, 'booking-save');
      expect(db.bookings.length, before + 1);
      await tapKey(tester, 'schedule-view');
      await tester.tap(find.text('კვირა'));
      await pumpFrames(tester);
      expect(find.byKey(const Key('schedule-col-day-6')), findsOneWidget);

      await tapKey(tester, 'admin-nav-/reports');
      expect(find.byKey(const Key('rsvp-row-${DemoSeedV17.rescheduledTraining}')), findsOneWidget);
      expectNoLayoutErrors();
    });

    testWidgets('narrow admin window: calendar scrolls horizontally without overflow', (tester) async {
      await bootAdmin(tester, size: const Size(800, 1000));
      await adminSignIn(tester, DemoSeedV17.tianetiAdmin);
      await tester.tap(find.byIcon(Icons.menu));
      await pumpFrames(tester);
      await tapKey(tester, 'admin-nav-/schedule');
      expect(find.byKey(const Key('schedule-col-${DemoSeedV17.hallA}')), findsOneWidget);
      expectNoLayoutErrors();
    });

    testWidgets('legacy club without room scheduling shows the locked module', (tester) async {
      await bootAdmin(tester);
      await adminSignIn(tester, DemoIds.clubAdmin);
      await tapKey(tester, 'admin-nav-/rooms');
      expect(find.byKey(const Key('room-new')), findsNothing);
      expect(find.byIcon(Icons.lock_rounded), findsWidgets);
      expectNoLayoutErrors();
    });
  });

  test('every v1.7 string exists in ka, en and ru and is translated', () {
    Map<String, dynamic> arb(String l) =>
        jsonDecode(File('lib/l10n/app_$l.arb').readAsStringSync()) as Map<String, dynamic>;
    final ka = arb('ka'), en = arb('en'), ru = arb('ru');
    const keys = [
      'rsvpNeedsReconfirm',
      'scheduleChangedTitle',
      'ackIsNotRsvp',
      'contactCoachExplain',
      'leaderboardConsentExplain',
      'leaderboardPrivacyNote',
      'adminNavOrganizations',
      'adminNavSchedule',
      'conflictRoomOverlap',
      'conflictCoachOverlap',
      'bookingRejected',
      'moduleRoomScheduling',
      'orgStatusHelp',
      'pointsTotal',
      'studentUpcomingEvents',
      'eventShowMap',
    ];
    for (final k in keys) {
      expect(ka[k], isA<String>(), reason: k);
      expect(en[k], isA<String>(), reason: k);
      expect(ru[k], isA<String>(), reason: k);
      expect(ka[k] != en[k] && ru[k] != en[k], isTrue, reason: '$k is untranslated');
    }
  });

  test('seeded conflicts stay out of the demo calendar', () {
    final db = DemoSeed.create(clock: () => testNow);
    final hallA = db.bookings.values.where((b) => b.roomId == DemoSeedV17.hallA && b.isActive).toList();
    for (final a in hallA) {
      expect(
        ConflictChecker.check(
          a,
          room: db.rooms[DemoSeedV17.hallA]!,
          existing: hallA,
          timezone: OrgTimeZones.tbilisi,
        ).where((c) => c.code == ConflictCode.roomOverlap),
        isEmpty,
      );
    }
  });
}
