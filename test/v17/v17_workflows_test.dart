import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_parent_app/core/errors/app_exception.dart';
import 'package:sport_parent_app/features/admin/domain/admin_models.dart';
import 'package:sport_parent_app/features/attendance/data/demo_attendance_repository.dart';
import 'package:sport_parent_app/features/attendance/domain/attendance.dart';
import 'package:sport_parent_app/features/brain_academy/data/demo_brain_repositories.dart';
import 'package:sport_parent_app/features/brain_academy/domain/brain_models.dart';
import 'package:sport_parent_app/features/brain_academy/domain/scoring.dart';
import 'package:sport_parent_app/features/chat/data/demo_chat_repository.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed_v17.dart';
import 'package:sport_parent_app/features/matches/domain/match.dart';
import 'package:sport_parent_app/features/notifications/domain/notification_models.dart';
import 'package:sport_parent_app/features/organizations/data/demo_org_repositories.dart';
import 'package:sport_parent_app/features/organizations/domain/coach_contact.dart';
import 'package:sport_parent_app/features/organizations/domain/organization.dart';
import 'package:sport_parent_app/features/organizations/domain/scheduling.dart';
import 'package:sport_parent_app/features/trainings/data/demo_trainings_repository.dart';
import 'package:sport_parent_app/features/trainings/domain/training.dart';

final denied = throwsA(isA<PermissionDeniedException>());
Matcher invalid(String code) => throwsA(isA<ValidationException>().having((e) => e.code, 'code', code));

void main() {
  final now = DateTime(2026, 11, 16, 12); // Monday
  late DemoBackend db;
  late DemoOrganizationsRepository orgs;
  late DemoSchedulingRepository sched;
  late DemoLeaderboardRepository boards;
  late DemoAttendanceRepository att;
  setUp(() {
    db = DemoSeed.create(clock: () => now);
    orgs = DemoOrganizationsRepository(db);
    sched = DemoSchedulingRepository(db);
    boards = DemoLeaderboardRepository(db);
    att = DemoAttendanceRepository(db);
  });
  void as(String uid) => db.session = (uid: uid, phone: db.users[uid]!.phone);
  const tianeti = DemoSeedV17.tianeti;
  const mtskheta = DemoSeedV17.mtskheta;
  DateTime local(int dayOffset, int h, [int m = 0]) {
    final w = OrgTimeZones.wall(now, OrgTimeZones.tbilisi);
    return OrgTimeZones.instant(OrgTimeZones.tbilisi, w.year, w.month, w.day + dayOffset, h, m);
  }

  Booking draft(
    DateTime s,
    int minutes, {
    String room = DemoSeedV17.hallA,
    String org = tianeti,
    String? coach,
    String? group,
  }) => Booking(
    id: '',
    orgId: org,
    roomId: room,
    kind: BookingKind.event,
    startAt: s,
    endAt: s.add(Duration(minutes: minutes)),
    title: 'Test',
    coachId: coach,
    groupId: group,
  );

  group('demo tenants', () {
    test('Tianeti Sports School and a second academy, with synthetic data', () {
      expect(db.clubs[tianeti]!.name, 'თიანეთის სპორტსკოლა');
      expect(db.orgConfig(tianeti).branding.nameFor('en'), 'Tianeti Sports School');
      expect(
        db.rooms.values.where((r) => r.orgId == tianeti).map((r) => r.name),
        containsAll(['დარბაზი A', 'დარბაზი B']),
      );
      expect(db.programs.values.where((p) => p.orgId == tianeti).length, 3);
      expect(db.orgConfigs.containsKey(mtskheta), isTrue);
      // Seeded active bookings never overlap in the same room.
      final active = db.bookings.values.where((b) => b.isActive).toList();
      for (final a in active) {
        for (final b in active) {
          if (a.id != b.id && a.roomId == b.roomId) {
            expect(
              ConflictChecker.overlaps(a.startAt, a.endAt, b.startAt, b.endAt),
              isFalse,
              reason: '${a.id}/${b.id}',
            );
          }
        }
      }
    });

    test('volleyball and badminton are in the database catalog with ka/en/ru names', () {
      expect(db.sports['volleyball']!.localizedName('ka'), 'ფრენბურთი');
      expect(db.sports['volleyball']!.localizedName('ru'), 'Волейбол');
      expect(db.sports['badminton']!.localizedName('en'), 'Badminton');
      expect(db.sports['badminton']!.localizedName('ru'), 'Бадминтон');
      expect(db.sports['football']!.localizedName('en'), 'Football', reason: 'existing sports kept');
      expect(db.clubs[tianeti]!.sportIds, containsAll(['volleyball', 'badminton']));
    });

    test('a user can belong to several organizations', () async {
      as(DemoIds.parent);
      final mine = await orgs.watchMyMemberships().first;
      expect(mine.map((m) => m.orgId), containsAll(['club-1', tianeti]));
    });
  });

  group('tenant isolation and admin permissions', () {
    test('organization admin cannot read or write another tenant', () async {
      as(DemoSeedV17.tianetiAdmin);
      expect(orgs.watchMembers(mtskheta).first, denied);
      expect(orgs.health(mtskheta), denied);
      expect(sched.createBooking(draft(local(1, 12), 60, room: DemoSeedV17.mtskhetaHall, org: mtskheta)), denied);
      // Pointing a Tianeti booking at the other tenant's room or group fails too.
      expect(sched.createBooking(draft(local(1, 12), 60, room: DemoSeedV17.mtskhetaHall)), denied);
      expect(sched.createBooking(draft(local(1, 12), 60, group: DemoSeedV17.mtskhetaGroup)), denied);
      expect(orgs.brainSummary(mtskheta), denied);
      expect(
        orgs.upsertProgram(const SportsProgram(id: '', orgId: mtskheta, sportId: 'basketball', name: 'Hack')),
        denied,
      );
      // Mtskheta's admin cannot see Tianeti's room plan either.
      as(DemoSeedV17.mtskhetaAdmin);
      expect(sched.watchBookings(tianeti, from: now, to: now.add(const Duration(days: 7))).first, denied);
    });

    test('organization admin cannot escalate: platform-only fields and restricted modules', () async {
      as(DemoSeedV17.mtskhetaAdmin);
      expect(orgs.updatePlatformSettings(mtskheta, status: OrgStatus.active), denied);
      expect(orgs.setOrgAdmin(mtskheta, DemoSeedV17.mtskhetaParent, admin: true), denied);
      expect(orgs.createOrganization(club: _club, plan: OrgPlan.premium, branding: const OrgBranding()), denied);
      // Leaderboards are not allowed for Mtskheta's plan → cannot self-enable.
      expect(orgs.updateOrgSettings(mtskheta, enabledModules: {...OrgModule.values}), denied);
      expect(orgs.updateOrgSettings(mtskheta, leaderboard: const LeaderboardSettings(enabled: true)), denied);
      // Switching off an allowed module is fine.
      await orgs.updateOrgSettings(
        mtskheta,
        enabledModules: db.orgConfig(mtskheta).enabledModules.difference({OrgModule.media}),
      );
      expect(db.orgConfig(mtskheta).isEnabled(OrgModule.media), isFalse);
    });

    test('parents, coaches and students never get admin data or the room plan', () async {
      as(DemoSeedV17.tianetiParent);
      expect(sched.watchBookings(tianeti, from: now, to: now.add(const Duration(days: 1))).first, completion(isEmpty));
      expect(orgs.rsvpReport(tianeti, from: now, to: now), denied);
      as(DemoIds.student);
      expect(orgs.watchMembers(tianeti).first, denied);
      expect(orgs.watchConfig(mtskheta).first, denied, reason: 'not a member of that tenant');
    });
  });

  group('platform → organization admin → schedule', () {
    test('create a school, assign its admin, add rooms/programs/coaches, recurring schedule', () async {
      as(DemoIds.platformAdmin);
      final club = await orgs.createOrganization(
        club: _club,
        plan: OrgPlan.premium,
        branding: const OrgBranding(names: {'ka': 'ახალი სკოლა', 'en': 'New School'}, primaryColor: 0xFF7C3AED),
      );
      final cfg = db.orgConfig(club.id);
      expect(cfg.isEnabled(OrgModule.trainings), isTrue);
      expect(cfg.isEnabled(OrgModule.leaderboards), isFalse, reason: 'restricted modules start off');
      expect(cfg.leaderboard.enabled, isFalse);
      await orgs.setOrgAdmin(club.id, DemoSeedV17.mtskhetaParent, admin: true);
      expect(db.users[DemoSeedV17.mtskhetaParent]!.administersClub(club.id), isTrue);

      as(DemoSeedV17.mtskhetaParent);
      await orgs.updateOrgSettings(
        club.id,
        enabledModules: {...cfg.enabledModules, OrgModule.facilities, OrgModule.roomScheduling},
      );
      final hall = await sched.upsertRoom(Room(id: '', orgId: club.id, name: 'Main hall', capacity: 25));
      await orgs.setOrgCoach(club.id, DemoSeedV17.badmintonCoach, member: true);
      final program = await orgs.upsertProgram(
        SportsProgram(
          id: '',
          orgId: club.id,
          sportId: 'badminton',
          name: 'Badminton 9–14',
          coachIds: [DemoSeedV17.badmintonCoach],
        ),
      );
      expect(program.id, isNotEmpty);
      final rule = WeeklyRule(
        weekdays: {2, 4},
        startMinute: 17 * 60,
        durationMin: 90,
        from: DateTime.utc(2026, 11, 17),
        until: DateTime.utc(2026, 12, 15),
      );
      final series = await sched.createRecurring(
        Booking(
          id: '',
          orgId: club.id,
          roomId: hall.id,
          kind: BookingKind.training,
          startAt: local(1, 17),
          endAt: local(1, 18, 30),
          coachId: DemoSeedV17.badmintonCoach,
        ),
        rule,
      );
      expect(series.length, 9);
      expect(series.map((b) => b.seriesId).toSet().length, 1);
      // A conflicting booking is rejected with reasons and alternatives.
      await expectLater(
        sched.createBooking(draft(local(1, 17, 30), 60, room: hall.id, org: club.id)),
        throwsA(
          isA<BookingRejected>()
              .having((e) => e.primary, 'primary', ConflictCode.roomOverlap)
              .having((e) => e.alternatives, 'alternatives', isNotEmpty),
        ),
      );
      // The same coach cannot be double-booked at Tianeti at the same time either.
      as(DemoSeedV17.tianetiAdmin);
      await expectLater(
        sched.createBooking(draft(local(1, 17, 30), 60, room: DemoSeedV17.hallA, coach: DemoSeedV17.badmintonCoach)),
        throwsA(isA<BookingRejected>().having((e) => e.primary, 'primary', ConflictCode.coachOverlap)),
      );
    });

    test('recurring series is all-or-nothing when one occurrence conflicts', () async {
      as(DemoSeedV17.tianetiAdmin);
      final before = db.bookings.length;
      final rule = WeeklyRule(
        weekdays: {1},
        startMinute: 16 * 60 + 30,
        durationMin: 60,
        from: DateTime.utc(2026, 11, 23),
        until: DateTime.utc(2026, 12, 21),
      );
      await expectLater(
        sched.createRecurring(draft(local(7, 16, 30), 60), rule),
        throwsA(isA<BookingRejected>()),
        reason: 'Hall A has volleyball Mon 16:00–17:30',
      );
      expect(db.bookings.length, before);
    });

    test('concurrent reservations of the same slot: exactly one succeeds', () async {
      as(DemoSeedV17.tianetiAdmin);
      final slot = local(2, 12);
      final results = await Future.wait([
        sched
            .createBooking(draft(slot, 60))
            .then((_) => 'ok', onError: (Object e) => e is BookingRejected ? 'rejected' : '$e'),
        sched
            .createBooking(draft(slot.add(const Duration(minutes: 30)), 60))
            .then((_) => 'ok', onError: (Object e) => e is BookingRejected ? 'rejected' : '$e'),
      ]);
      expect(results..sort(), ['ok', 'rejected']);
    });

    test('adjacent bookings are allowed; a configured buffer rejects them', () async {
      as(DemoSeedV17.tianetiAdmin);
      await sched.createBooking(draft(local(2, 12), 60));
      await sched.createBooking(draft(local(2, 13), 60));
      await orgs.updateOrgSettings(tianeti, bookingBufferMin: 15);
      await expectLater(sched.createBooking(draft(local(2, 14), 60)), throwsA(isA<BookingRejected>()));
    });

    test('other tenants can book the same time in their own room', () async {
      as(DemoSeedV17.mtskhetaAdmin);
      final b = await sched.createBooking(draft(local(2, 12), 60, room: DemoSeedV17.mtskhetaHall, org: mtskheta));
      as(DemoSeedV17.tianetiAdmin);
      await sched.createBooking(draft(local(2, 12), 60));
      expect(b.id, isNotEmpty);
    });

    test('maintenance and unavailable rooms block bookings', () async {
      as(DemoSeedV17.tianetiAdmin);
      final fri = local((DateTime.friday - now.weekday) % 7, 12, 30);
      await expectLater(
        sched.createBooking(draft(fri, 30, room: DemoSeedV17.hallB)),
        throwsA(isA<BookingRejected>().having((e) => e.primary, 'p', ConflictCode.maintenance)),
      );
      await sched.setRoomStatus(tianeti, DemoSeedV17.hallB, RoomStatus.unavailable);
      await expectLater(
        sched.createBooking(draft(local(2, 9), 30, room: DemoSeedV17.hallB)),
        throwsA(isA<BookingRejected>().having((e) => e.primary, 'p', ConflictCode.roomNotBookable)),
      );
    });

    test('room booking and its training stay one schedule (move, edit future, cancel)', () async {
      as(DemoSeedV17.tianetiAdmin);
      final b = await sched.createBooking(
        Booking(
          id: '',
          orgId: tianeti,
          roomId: DemoSeedV17.hallB,
          kind: BookingKind.training,
          startAt: local(2, 9),
          endAt: local(2, 10),
          groupId: DemoSeedV17.badmintonGroup,
          coachId: DemoSeedV17.badmintonCoach,
          title: 'Extra',
        ),
      );
      final t = db.trainings[b.eventId]!;
      expect(t.roomId, DemoSeedV17.hallB);
      expect(t.startAt.isAtSameMomentAs(b.startAt), isTrue);
      await sched.updateBooking(b.copyWith(startAt: local(2, 10), endAt: local(2, 11)));
      final moved = db.trainings[b.eventId]!;
      expect(moved.startAt.isAtSameMomentAs(local(2, 10)), isTrue);
      expect(moved.scheduleVersion, 2);
      expect(moved.status, TrainingStatus.moved);
      // Editing "this and later" of a seeded series moves every later occurrence.
      final anchor =
          db.bookings.values
              .where((x) => x.groupId == DemoSeedV17.volleyGroup && x.isActive && x.startAt.isAfter(now))
              .toList()
            ..sort((a, c) => a.startAt.compareTo(c.startAt));
      final moved2 = await sched.updateSeriesFrom(anchor.first, startMinute: 18 * 60, durationMin: 60);
      expect(moved2.length, anchor.length);
      expect(OrgTimeZones.wall(db.bookings[anchor.last.id]!.startAt, OrgTimeZones.tbilisi).hour, 18);
      await sched.cancelBooking(db.bookings[anchor.first.id]!, scope: SeriesEditScope.thisAndFuture);
      expect(anchor.every((x) => !db.bookings[x.id]!.isActive), isTrue);
      expect(db.trainings[anchor.first.eventId]!.status, TrainingStatus.cancelled);
    });

    test('a coach cannot move a room-linked training into a booked slot', () async {
      as(DemoSeedV17.volleyCoach);
      final t =
          db.trainings.values
              .where((x) => x.groupId == DemoSeedV17.volleyGroup && x.roomId != null && x.startAt.isAfter(now))
              .toList()
            ..sort((a, b) => a.startAt.compareTo(b.startAt));
      // Saturday 10:00 Hall A is the football slot.
      final sat = local((DateTime.saturday - now.weekday) % 7, 10);
      expect(DemoTrainingsRepository(db).reschedule(t.first.id, sat), invalid('roomConflict'));
    });
  });

  group('feature flags are enforced on the server side', () {
    test('disabled or suspended organizations block the module', () async {
      as(DemoIds.platformAdmin);
      await orgs.updatePlatformSettings(
        mtskheta,
        allowedModules: db.orgConfig(mtskheta).allowedModules.difference({OrgModule.roomScheduling}),
      );
      as(DemoSeedV17.mtskhetaAdmin);
      expect(
        sched.createBooking(draft(local(1, 12), 60, room: DemoSeedV17.mtskhetaHall, org: mtskheta)),
        invalid('moduleDisabled:roomScheduling'),
      );
      as(DemoIds.platformAdmin);
      await orgs.updatePlatformSettings(tianeti, status: OrgStatus.suspended);
      expect(db.orgConfig(tianeti).isEnabled(OrgModule.trainings), isFalse);
      as(DemoSeedV17.volleyCoach);
      final past = db.trainings.values.firstWhere(
        (t) => t.groupId == DemoSeedV17.volleyGroup && t.status == TrainingStatus.done,
      );
      expect(
        att.mark(trainingId: past.id, childId: 'child-t1', status: AttendanceStatus.present),
        invalid('moduleDisabled:attendance'),
      );
      as(DemoSeedV17.tianetiAdmin);
      expect(orgs.updateOrgSettings(tianeti, bookingBufferMin: 5), invalid('orgInactive'));
    });
  });

  group('event RSVP, reconfirmation and acknowledgment', () {
    test('seeded reschedule: one confirmed, one needs reconfirmation, one no answer', () {
      final t = db.trainings[DemoSeedV17.rescheduledTraining]!;
      final s = RsvpSummary.compute(
        db.groups[DemoSeedV17.volleyGroup]!.memberChildIds,
        db.rsvps.values.where((r) => r.trainingId == t.id),
        t.scheduleVersion,
      );
      expect(s.count(RsvpState.confirmed), 1);
      expect(s.count(RsvpState.needsReconfirmation), 1);
      expect(s.count(RsvpState.notResponded), 1);
    });

    test('a material change bumps the version, keeps old answers and asks for acknowledgment', () async {
      as(DemoSeedV17.tianetiParent);
      final t = db.trainings.values.firstWhere(
        (x) => x.groupId == DemoSeedV17.volleyGroup && x.startAt.isAfter(now) && x.roomId == null,
      );
      await att.respond(trainingId: t.id, childId: 'child-t2', response: RsvpResponse.yes);
      expect(db.rsvps[Rsvp.docId(t.id, 'child-t2')]!.scheduleVersion, t.scheduleVersion);

      as(DemoSeedV17.volleyCoach);
      final next = t.startAt.add(const Duration(days: 1));
      await DemoTrainingsRepository(db).reschedule(t.id, next);
      final moved = db.trainings[t.id]!;
      expect(moved.scheduleVersion, t.scheduleVersion + 1);
      final r = db.rsvps[Rsvp.docId(t.id, 'child-t2')]!;
      expect(r.needsReconfirmation(moved.scheduleVersion), isTrue);
      expect(r.response, RsvpResponse.yes, reason: 'previous answer preserved');

      // Parents get an acknowledgment request; acknowledging ≠ "will attend".
      final notice = db.messages[DemoSeedV17.volleyGroup]!.lastWhere(
        (m) => m.systemKey == 'eventRescheduled' && m.systemArgs['eventId'] == t.id,
      );
      expect(notice.requiresAck, isTrue);
      expect(notice.systemArgs['eventId'], t.id);
      expect(
        db.notifications.any((n) => n.userId == DemoSeedV17.tianetiParent && n.type == NotificationType.ackRequested),
        isTrue,
      );
      as(DemoSeedV17.tianetiParent);
      await DemoChatRepository(db).acknowledge(DemoSeedV17.volleyGroup, notice.id);
      expect(db.msgAcks[notice.id]!.containsKey(DemoSeedV17.tianetiParent), isTrue);
      expect(db.rsvps[Rsvp.docId(t.id, 'child-t2')]!.needsReconfirmation(moved.scheduleVersion), isTrue);

      // Reconfirming for the new schedule; history keeps both answers.
      await att.respond(trainingId: t.id, childId: 'child-t2', response: RsvpResponse.no, reason: 'school trip');
      final after = db.rsvps[Rsvp.docId(t.id, 'child-t2')]!;
      expect(after.needsReconfirmation(moved.scheduleVersion), isFalse);
      expect(after.reason, 'school trip');
      final history = await att.watchRsvpHistory(t.id, 'child-t2').first;
      expect(history.map((h) => h.version).toSet(), containsAll([t.scheduleVersion, moved.scheduleVersion]));
    });

    test('two guardians: both answers kept, the child is counted once', () async {
      final t = db.trainings.values.firstWhere(
        (x) => x.groupId == DemoSeedV17.volleyGroup && x.startAt.isAfter(now) && x.status.isActive,
      );
      as(DemoSeedV17.tianetiParent);
      await att.respond(trainingId: t.id, childId: 'child-t1', response: RsvpResponse.yes);
      as(DemoSeedV17.tianetiParent2);
      await att.respond(trainingId: t.id, childId: 'child-t1', response: RsvpResponse.maybe);
      final r = db.rsvps[Rsvp.docId(t.id, 'child-t1')]!;
      expect(r.guardianResponses.keys, {DemoSeedV17.tianetiParent, DemoSeedV17.tianetiParent2});
      expect(r.conflictingFor(t.scheduleVersion), isTrue);
      expect(db.rsvps.values.where((x) => x.trainingId == t.id && x.childId == 'child-t1').length, 1);
      // A parent of another child cannot answer for Ana.
      as(DemoSeedV17.mtskhetaParent);
      expect(att.respond(trainingId: t.id, childId: 'child-t1', response: RsvpResponse.no), denied);
    });

    test('matches: parents RSVP, the coach marks actual attendance separately', () async {
      final upcoming = db.matches.values.firstWhere(
        (m) => m.groupId == 'g-football-u10' && m.status.isActive && m.startAt.isAfter(now),
      );
      as(DemoIds.parent);
      await att.respond(trainingId: upcoming.id, childId: 'child-1', response: RsvpResponse.no, reason: 'sick');
      expect(db.rsvps[Rsvp.docId(upcoming.id, 'child-1')]!.eventType, EventType.match);
      final played = db.matches.values.firstWhere(
        (m) => m.groupId == 'g-football-u10' && m.startAt.isBefore(now) && m.status != MatchStatus.cancelled,
      );
      as(DemoIds.coach);
      await att.mark(trainingId: played.id, childId: 'child-1', status: AttendanceStatus.present);
      final rec = db.attendance[AttendanceRecord.docId(played.id, 'child-1')]!;
      expect(rec.eventType, EventType.match);
      expect(db.rsvps[Rsvp.docId(played.id, 'child-1')], isNull, reason: 'attendance never creates an RSVP');
      // Bulk marking works for matches too.
      await att.markAll(trainingId: played.id, status: AttendanceStatus.absent);
      expect(
        db.attendance.values.where((a) => a.trainingId == played.id).length,
        db.groups['g-football-u10']!.memberChildIds.length,
      );
    });

    test('students see only their own attendance', () async {
      as(DemoIds.student);
      final mine = await att.watchForChild('child-1').first;
      expect(mine.every((a) => a.childId == 'child-1'), isTrue);
      expect(att.watchForChild('child-4').first, denied);
      expect(att.watchForChild('child-t1').first, denied);
    });
  });

  group('student coach contact (parent-mediated)', () {
    test('student asks; only the guardian is notified; no phone numbers', () async {
      final contacts = DemoCoachContactRepository(db);
      as(DemoIds.student);
      final r = await contacts.request(coachId: DemoIds.coach, groupId: 'g-football-u10', topic: 'question');
      // Every guardian of the child (Luka has two), nobody else.
      expect(
        db.notifications.where((n) => n.dedupeKey == 'contact:${r.id}').map((n) => n.userId).toSet(),
        db.children['child-1']!.parentIds.toSet(),
      );
      expect(db.notifications.any((n) => n.userId == DemoIds.coach && n.dedupeKey == 'contact:${r.id}'), isFalse);
      // Not this student's coach / group.
      expect(contacts.request(coachId: 'coach-2', groupId: 'g-basket-u13', topic: 'question'), denied);
      expect(contacts.request(coachId: DemoIds.coach, groupId: 'g-football-u10', topic: 'call me'), invalid('topic'));
      as(DemoIds.parent);
      final open = await contacts.watchForParent().first;
      expect(open.single.status, ContactRequestStatus.open);
      await contacts.markHandled(r.id);
      expect(db.coachContactRequests[r.id]!.status, ContactRequestStatus.handled);
      // Another parent cannot see or close it.
      as(DemoSeedV17.tianetiParent);
      expect(await contacts.watchForParent().first, isEmpty);
      expect(contacts.markHandled(r.id), denied);
    });

    test('a coach cannot use the student request path', () {
      as(DemoIds.coach);
      expect(
        DemoCoachContactRepository(db).request(coachId: DemoIds.coach, groupId: 'g-football-u10', topic: 'question'),
        denied,
      );
    });
  });

  group('Brain Academy progress', () {
    test('results are idempotent, persisted, gated by the module, and points come from the server', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = DemoBrainAcademyRepository(db, prefs);
      as(DemoIds.student);
      final r = GameResult(
        id: 'r-client-1',
        childId: 'child-1',
        game: BrainGame.logicQuest,
        difficulty: GameDifficulty.medium,
        level: 2,
        score: 400,
        accuracy: .9,
        attempts: 6,
        durationMs: 40000,
        completed: true,
        playedAt: now,
      );
      final before = ScoringService.total(db.brainResults.where((x) => x.childId == 'child-1'));
      await repo.recordResult(r);
      await repo.recordResult(r); // retry after reconnect / double tap
      expect(db.brainResults.where((x) => x.id == 'r-client-1').length, 1);
      final after = ScoringService.total(db.brainResults.where((x) => x.childId == 'child-1'));
      expect(after, greaterThan(before));
      // Survives an app restart (new repository instance on the same prefs).
      final db2 = DemoSeed.create(clock: () => now);
      DemoBrainAcademyRepository(db2, prefs);
      expect(db2.brainResults.any((x) => x.id == 'r-client-1'), isTrue);
      // Recording works offline (the games never need a network).
      db.setOffline(true);
      await repo.recordResult(
        GameResult(
          id: 'r-offline',
          childId: 'child-1',
          game: BrainGame.quickMind,
          difficulty: GameDifficulty.easy,
          level: 1,
          score: 100,
          accuracy: 1,
          attempts: 3,
          durationMs: 20000,
          completed: true,
          playedAt: now,
        ),
      );
      expect(db.brainResults.any((x) => x.id == 'r-offline'), isTrue);
    });

    test('rejected when every organization of the child disabled Brain Academy', () async {
      as(DemoIds.platformAdmin);
      for (final o in {
        for (final g in db.groups.values)
          if (g.hasChild('child-1')) g.clubId,
      }) {
        db.orgConfigs[o] = db
            .orgConfig(o)
            .copyWith(enabledModules: db.orgConfig(o).enabledModules.difference({OrgModule.brainAcademy}));
      }
      as(DemoIds.student);
      expect(
        DemoBrainAcademyRepository(db, null).recordResult(
          GameResult(
            id: 'x',
            childId: 'child-1',
            game: BrainGame.memoryMatch,
            difficulty: GameDifficulty.easy,
            level: 1,
            score: 1,
            accuracy: 1,
            attempts: 1,
            durationMs: 5000,
            completed: true,
            playedAt: now,
          ),
        ),
        invalid('moduleDisabled:brainAcademy'),
      );
    });
  });

  group('organization leaderboard and consent', () {
    test('opted-in students of one organization, pseudonyms, own age band', () async {
      as(DemoIds.student);
      final board = await boards.watchBoard(tianeti, 'child-1', period: LeaderboardPeriod.month).first;
      expect(board.unavailable, isNull);
      expect(board.entries.length, greaterThanOrEqualTo(3));
      expect(board.entries.any((e) => e.childId == 'child-1'), isTrue);
      final names = board.entries.map((e) => e.displayName).join(' ');
      expect(names, isNot(contains('ხუციშვილი')), reason: 'never a full last name');
      expect(names, isNot(contains('ბერიძე')));
      // No cross-organization boards.
      expect(boards.watchBoard(mtskheta, 'child-1', period: LeaderboardPeriod.week).first, denied);
      expect(boards.watchBoard(tianeti, 'child-t1', period: LeaderboardPeriod.week).first, denied);
    });

    test('only a guardian sets consent; revoking removes the child immediately', () async {
      as(DemoIds.student);
      expect(boards.setConsent(tianeti, 'child-1', granted: true), denied);
      as(DemoSeedV17.volleyCoach);
      expect(boards.setConsent(tianeti, 'child-t1', granted: false), denied);
      as(DemoIds.parent);
      await boards.setConsent(tianeti, 'child-1', granted: false);
      final mine = await boards.watchBoard(tianeti, 'child-1', period: LeaderboardPeriod.week).first;
      expect(mine.unavailable, LeaderboardUnavailable.notConsented);
      as(DemoSeedV17.tianetiParent);
      final theirs = await boards.watchBoard(tianeti, 'child-t1', period: LeaderboardPeriod.month).first;
      expect(theirs.entries.any((e) => e.childId == 'child-1'), isFalse);
    });

    test('disabled by default; organizations without the module show private progress only', () async {
      as(DemoIds.parent);
      final cfg = db.orgConfig('club-1');
      expect(cfg.leaderboardOn, isFalse);
      as(DemoIds.platformAdmin);
      await orgs.updatePlatformSettings(tianeti, allowedModules: OrgPlan.standard.defaultModules);
      as(DemoIds.student);
      final b = await boards.watchBoard(tianeti, 'child-1', period: LeaderboardPeriod.week).first;
      expect(b.unavailable, LeaderboardUnavailable.disabled);
    });
  });

  group('reports', () {
    test('RSVP, attendance and Brain Academy summaries are tenant-scoped', () async {
      as(DemoSeedV17.tianetiAdmin);
      final rsvp = await orgs.rsvpReport(tianeti, from: now, to: now.add(const Duration(days: 7)));
      expect(
        rsvp.where((r) => r.eventId == DemoSeedV17.rescheduledTraining).single.counts[RsvpState.needsReconfirmation],
        1,
      );
      final attendance = await orgs.attendanceReport(
        tianeti,
        from: now.subtract(const Duration(days: 30)),
        to: now,
        groupId: DemoSeedV17.volleyGroup,
      );
      expect(attendance, isNotEmpty);
      expect(attendance.every((a) => a.groupId == DemoSeedV17.volleyGroup), isTrue);
      expect(orgs.attendanceReport(tianeti, from: now, to: now, groupId: DemoSeedV17.mtskhetaGroup), denied);
      final brain = await orgs.brainSummary(tianeti);
      expect(brain.map((b) => b.childId), containsAll(['child-t1', 'child-1']));
      expect(brain.map((b) => b.childId), isNot(contains('child-m1')));
      expect(brain.firstWhere((b) => b.childId == 'child-t1').displayName, 'ანა ხ.');
    });
  });
}

const _club = ClubDraft(
  name: 'ახალი სკოლა',
  address: 'თიანეთი',
  lat: 42.1,
  lng: 44.9,
  sportIds: ['badminton', 'volleyball'],
);
