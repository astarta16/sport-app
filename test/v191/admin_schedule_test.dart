import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_parent_app/admin/pages/v17_pages.dart' show bookingLanes;
import 'package:sport_parent_app/features/demo/data/demo_seed_v17.dart';
import 'package:sport_parent_app/features/organizations/domain/organization.dart';
import 'package:sport_parent_app/features/organizations/domain/scheduling.dart';

import '../responsive/responsive_screens_test.dart' show pumpFrames, expectNoLayoutErrors;
import '../v17/v17_ui_test.dart' show tapKey, bootAdmin, adminSignIn;

Booking b(String id, DateTime s, int minutes, {String room = 'r1'}) => Booking(
  id: id,
  orgId: 'o',
  roomId: room,
  kind: BookingKind.event,
  startAt: s,
  endAt: s.add(Duration(minutes: minutes)),
  title: id,
);

void main() {
  setUpAll(() => initializeDateFormatting());
  final t = DateTime.utc(2026, 11, 17, 10);

  group('overlapping bookings share the column', () {
    test('two overlapping → two lanes; a later one starts a new cluster', () {
      final lanes = bookingLanes([
        b('a', t, 60),
        b('b', t.add(const Duration(minutes: 30)), 60),
        b('c', t.add(const Duration(hours: 3)), 30),
      ]);
      expect(lanes['a'], (0, 2));
      expect(lanes['b'], (1, 2));
      expect(lanes['c'], (0, 1));
    });
    test('back-to-back bookings do not overlap; a free lane is reused', () {
      final lanes = bookingLanes([
        b('a', t, 60),
        b('b', t, 120),
        b('c', t.add(const Duration(hours: 1)), 60), // starts when a ends → lane 0
      ]);
      expect(lanes['c']!.$1, 0);
      expect(lanes.values.map((v) => v.$2).toSet(), {2});
    });
  });

  testWidgets('week view with all rooms draws parallel bookings side by side', (tester) async {
    final db = await bootAdmin(tester);
    final c = db.orgConfig(DemoSeedV17.tianeti);
    // Two bookings at the same time in the two halls, tomorrow 11:00 local.
    final tz = c.timezone;
    final w = OrgTimeZones.wall(db.clock(), tz);
    final s = OrgTimeZones.instant(tz, w.year, w.month, w.day + 1, 11, 0);
    for (final (id, room) in [('par-a', DemoSeedV17.hallA), ('par-b', DemoSeedV17.hallB)]) {
      db.bookings[id] = Booking(
        id: id,
        orgId: DemoSeedV17.tianeti,
        roomId: room,
        kind: BookingKind.event,
        startAt: s,
        endAt: s.add(const Duration(hours: 1)),
        title: id,
      );
    }
    db.commit();
    await adminSignIn(tester, DemoSeedV17.tianetiAdmin);
    await tapKey(tester, 'admin-nav-/schedule');
    await tapKey(tester, 'schedule-view');
    await tester.tap(find.text('კვირა')); // "Week" (Georgian UI)
    await pumpFrames(tester);
    // Make sure the week containing tomorrow is shown.
    if (find.byKey(const Key('booking-par-a')).evaluate().isEmpty) {
      await tapKey(tester, 'schedule-next');
    }
    final ra = tester.getRect(find.byKey(const Key('booking-par-a')));
    final rb = tester.getRect(find.byKey(const Key('booking-par-b')));
    expect(ra.overlaps(rb), isFalse, reason: 'both bookings visible, none hidden under the other');
    expectNoLayoutErrors();
  });

  testWidgets('room schedule has a date picker', (tester) async {
    await bootAdmin(tester);
    await adminSignIn(tester, DemoSeedV17.tianetiAdmin);
    await tapKey(tester, 'admin-nav-/schedule');
    await tapKey(tester, 'schedule-pick-date');
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
