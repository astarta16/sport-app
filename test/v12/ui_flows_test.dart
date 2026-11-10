import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_parent_app/features/attendance/domain/attendance.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/groups/domain/group.dart';
import 'package:sport_parent_app/features/trainings/domain/training.dart';

import '../responsive/responsive_screens_test.dart'
    show boot, signInAs, visit, pumpFrames, expectNoLayoutErrors, routerOf;

Future<void> tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f.first);
  await tester.pump();
  await tester.tap(f.first);
  await pumpFrames(tester);
}

void main() {
  setUpAll(() => initializeDateFormatting());
  const phone = Size(390, 844);

  testWidgets('parent accepts an invitation by linking an existing child — no duplicate', (tester) async {
    final db = await boot(tester, phone);
    await signInAs(tester, db, DemoIds.parent);
    expect(find.byKey(const Key('invites-banner')), findsOneWidget);
    await tapKey(tester, 'invites-banner');
    await tapKey(tester, 'invite-accept-inv-1');
    expect(find.byKey(const Key('invite-accept-dialog')), findsOneWidget);
    // Existing Mariam is pre-selected (same first name); the parent confirms.
    await tapKey(tester, 'link-child-2');
    await tapKey(tester, 'invite-media-consent');
    await tapKey(tester, 'invite-confirm');
    expect(db.invites['inv-1']!.status, InviteStatus.accepted);
    expect(db.invites['inv-1']!.linkedChildId, 'child-2');
    expect(db.children['child-pending-1'], isNull, reason: 'duplicate discarded');
    expect(db.groups['g-football-u12']!.hasChild('child-2'), isTrue);
    expectNoLayoutErrors();
  });

  testWidgets('parent RSVP from the training screen; coach sees it and records attendance', (tester) async {
    final db = await boot(tester, phone);
    final t =
        (db.trainings.values
                .where(
                  (t) =>
                      t.groupId == 'g-football-u10' &&
                      t.status == TrainingStatus.scheduled &&
                      t.startAt.isAfter(DateTime(2026, 11, 10, 10)),
                )
                .toList()
              ..sort((a, b) => a.startAt.compareTo(b.startAt)))
            .first;
    await signInAs(tester, db, DemoIds.parent);
    await visit(tester, 'rsvp', ['/training/${t.id}']);
    await tapKey(tester, 'rsvp-child-1-no');
    await tester.enterText(find.byKey(const Key('rsvp-reason-child-1')), 'ავადაა');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpFrames(tester);
    final r = db.rsvps[Rsvp.docId(t.id, 'child-1')]!;
    expect(r.response, RsvpResponse.no);
    expect(r.reason, 'ავადაა');

    // Coach records actual attendance (training moved to "now" so it's markable).
    db.trainings[t.id] = t.copyWith(startAt: DateTime(2026, 11, 10, 9, 30));
    await signInAs(tester, db, DemoIds.coach);
    await visit(tester, 'attendance', ['/training/${t.id}/attendance']);
    await tester.scrollUntilVisible(find.textContaining('ავადაა'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('ავადაა'), findsOneWidget, reason: 'RSVP reason shown to the coach');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await pumpFrames(tester);
    await tapKey(tester, 'attendance-mark-all');
    await tester.scrollUntilVisible(
      find.byKey(const Key('att-child-1-excused')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tapKey(tester, 'att-child-1-excused');
    // v1.3: marks are a local draft until Save.
    expect(db.attendance[AttendanceRecord.docId(t.id, 'child-1')], isNull);
    await tapKey(tester, 'attendance-save');
    expect(db.attendance[AttendanceRecord.docId(t.id, 'child-1')]!.status, AttendanceStatus.excused);
    expect(db.attendance[AttendanceRecord.docId(t.id, 'child-4')]!.status, AttendanceStatus.present);
    expectNoLayoutErrors();

    // Parent sees the recorded status, separate from their RSVP.
    await signInAs(tester, db, DemoIds.parent);
    await visit(tester, 'recorded', ['/training/${t.id}']);
    expect(find.byKey(const Key('recorded-child-1')), findsOneWidget);
  });

  testWidgets('coach creates a recurring schedule from the form', (tester) async {
    final db = await boot(tester, phone);
    await signInAs(tester, db, DemoIds.coach);
    await visit(tester, 'series', ['/series/new?groupId=g-football-u10']);
    await tapKey(tester, 'series-day-1');
    await tapKey(tester, 'series-focus-ball');
    // Pick a venue from the dropdown.
    await tapKey(tester, 'series-venue');
    await tester.tap(find.text('საბურთალოს სტადიონი').last);
    await pumpFrames(tester);
    await tapKey(tester, 'series-save');
    final s = db.series.values.where((s) => s.groupId == 'g-football-u10').toList();
    expect(s, hasLength(1));
    expect(db.trainings.values.where((t) => t.seriesId == s.single.id), hasLength(8));
    expectNoLayoutErrors();
  });

  testWidgets('chat: unread badge clears after opening; coach pins an announcement', (tester) async {
    final db = await boot(tester, phone);
    await signInAs(tester, db, DemoIds.parent);
    await visit(tester, 'chats', ['/chats']);
    expect(find.byKey(const Key('chat-unread-g-football-u10')), findsOneWidget);
    await tapKey(tester, 'chat-tile-g-football-u10');
    expect(find.byKey(const Key('chat-pinned-banner')), findsOneWidget);
    expect(db.unreadFor(DemoIds.parent, 'g-football-u10'), 0);

    await signInAs(tester, db, DemoIds.coach);
    await visit(tester, 'coach chat', ['/chat/g-football-u10']);
    await tapKey(tester, 'chat-announcement-toggle');
    await tester.enterText(find.byKey(const Key('chat-input')), 'ხვალ ვარჯიში 30 წუთით ადრე იწყება');
    await tapKey(tester, 'chat-send');
    final last = db.messages['g-football-u10']!.last;
    expect(last.isAnnouncement && last.pinned, isTrue);
    expectNoLayoutErrors();
  });

  testWidgets('offline: banner shows and a failed send keeps a retry, not a fake message', (tester) async {
    final db = await boot(tester, phone);
    await signInAs(tester, db, DemoIds.parent);
    await visit(tester, 'chat', ['/chat/g-football-u10']);
    db.setOffline(true);
    await pumpFrames(tester);
    expect(find.byKey(const Key('offline-banner')), findsOneWidget);
    final before = db.messages['g-football-u10']!.length;
    await tester.enterText(find.byKey(const Key('chat-input')), 'offline test');
    await tapKey(tester, 'chat-send');
    expect(db.messages['g-football-u10']!.length, before);
    expect(find.byKey(const Key('chat-failed')), findsOneWidget);
    db.setOffline(false);
    await pumpFrames(tester);
    await tapKey(tester, 'chat-retry');
    expect(db.messages['g-football-u10']!.last.text, 'offline test');
    expect(routerOf(tester).routerDelegate.currentConfiguration.uri.path, '/chat/g-football-u10');
  });
}
