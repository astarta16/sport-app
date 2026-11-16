import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/features/attendance/domain/attendance.dart';
import 'package:sport_parent_app/features/brain_academy/domain/brain_models.dart';
import 'package:sport_parent_app/features/brain_academy/domain/scoring.dart';
import 'package:sport_parent_app/features/organizations/domain/organization.dart';
import 'package:sport_parent_app/features/organizations/domain/scheduling.dart';

/// Pure v1.7 logic. functions/test/v17.test.ts pins the same cases for the
/// TypeScript mirror (server authority), so both sides stay identical.
void main() {
  const tz = OrgTimeZones.tbilisi;
  DateTime at(int h, [int m = 0, int day = 16]) => OrgTimeZones.instant(tz, 2026, 11, day, h, m);
  const room = Room(id: 'hall-a', orgId: 'org-1', name: 'Hall A', capacity: 20);
  Booking b(
    String id,
    DateTime s,
    DateTime e, {
    String roomId = 'hall-a',
    String? coach,
    String? group,
    BookingKind kind = BookingKind.training,
    String org = 'org-1',
  }) => Booking(id: id, orgId: org, roomId: roomId, kind: kind, startAt: s, endAt: e, coachId: coach, groupId: group);

  group('time zones', () {
    test('Asia/Tbilisi is UTC+4 all year; instants are stored in UTC', () {
      expect(at(16), DateTime.utc(2026, 11, 16, 12));
      expect(OrgTimeZones.wall(DateTime.utc(2026, 7, 1, 20), tz).hour, 0);
      expect(OrgTimeZones.normalize('Mars/Base'), tz);
    });
  });

  group('interval overlap', () {
    test('09:00–10:00 and 10:00–11:00 touch but do not overlap', () {
      expect(ConflictChecker.overlaps(at(9), at(10), at(10), at(11)), isFalse);
    });

    test('09:00–10:30 and 10:00–11:00 overlap', () {
      expect(ConflictChecker.overlaps(at(9), at(10, 30), at(10), at(11)), isTrue);
    });

    test('a buffer turns touching bookings into a conflict', () {
      expect(ConflictChecker.overlaps(at(10), at(11), at(9), at(10), buffer: const Duration(minutes: 10)), isTrue);
    });
  });

  group('conflict checker', () {
    final existing = [
      b('x', at(10), at(11), coach: 'c1', group: 'g1'),
      b('m', at(14), at(16), kind: BookingKind.maintenance),
      b('other-room', at(18), at(19), roomId: 'hall-b', coach: 'c2', group: 'g2'),
    ];
    List<ConflictCode> codes(Booking c, {int buffer = 0, Room r = room}) => ConflictChecker.check(
      c,
      room: r,
      existing: existing,
      timezone: tz,
      bufferMin: buffer,
    ).map((x) => x.code).toList();

    test('adjacent slot is free; overlapping slot is rejected', () {
      expect(codes(b('n', at(11), at(12))), isEmpty);
      expect(codes(b('n', at(10, 30), at(11, 30))), [ConflictCode.roomOverlap]);
      expect(codes(b('n', at(11), at(12)), buffer: 15), [ConflictCode.roomOverlap]);
    });

    test('maintenance blocks, opening hours, capacity, range and length are checked', () {
      expect(codes(b('n', at(15), at(15, 30))), [ConflictCode.maintenance]);
      expect(codes(b('n', at(7), at(8))), [ConflictCode.outsideHours]);
      expect(codes(b('n', at(21, 30), at(22, 30))), [ConflictCode.outsideHours]);
      expect(
        ConflictChecker.check(
          Booking(
            id: 'n',
            orgId: 'org-1',
            roomId: 'hall-a',
            kind: BookingKind.training,
            startAt: at(12),
            endAt: at(13),
            expectedAttendees: 25,
          ),
          room: room,
          existing: const [],
          timezone: tz,
        ).single.code,
        ConflictCode.overCapacity,
      );
      expect(codes(b('n', at(12), at(12))), [ConflictCode.invalidRange]);
      expect(codes(b('n', at(8), at(21))), contains(ConflictCode.tooLong));
    });

    test('coach double-booking in another room blocks; group double-booking only warns', () {
      final c = codes(b('n', at(18, 30), at(19, 30), coach: 'c2'));
      expect(c, [ConflictCode.coachOverlap]);
      final g = ConflictChecker.check(
        b('n', at(18, 30), at(19, 30), group: 'g2'),
        room: room,
        existing: existing,
        timezone: tz,
      );
      expect(g.single.code, ConflictCode.groupOverlap);
      expect(ConflictChecker.isBlocked(g), isFalse);
    });

    test('unavailable room and another tenant\'s room are rejected; other tenants never conflict', () {
      expect(codes(b('n', at(12), at(13)), r: room.copyWith(status: RoomStatus.unavailable)), [
        ConflictCode.roomNotBookable,
      ]);
      expect(codes(b('n', at(12), at(13), org: 'org-2')), contains(ConflictCode.wrongTenant));
      // A booking of another organization at the same time is invisible.
      expect(
        ConflictChecker.check(
          b('n', at(10), at(11)),
          room: room,
          existing: [b('foreign', at(10), at(11), org: 'org-2')],
          timezone: tz,
        ),
        isEmpty,
      );
    });

    test('cross-midnight booking: allowed only when the room is open past midnight', () {
      final late = b('n', at(23), at(0, 30, 17));
      expect(codes(late), [ConflictCode.outsideHours]);
      final night = room.copyWith(hours: const OperatingHours({1: (480, 1560), 2: (480, 1560)}));
      expect(codes(late, r: night), isEmpty);
      // It still conflicts with a booking early the next day.
      expect(
        ConflictChecker.check(
          late,
          room: night,
          existing: [b('early', at(0, 0, 17), at(1, 0, 17))],
          timezone: tz,
        ).single.code,
        ConflictCode.roomOverlap,
      );
    });

    test('suggests the nearest free times and free rooms', () {
      final alt = ConflictChecker.alternatives(b('n', at(10), at(11)), room: room, existing: existing, timezone: tz);
      // 09:00 and 11:00 are equally near; ties keep the earlier slot first.
      expect(alt.take(2), [at(9), at(11)]);
      expect(alt, isNot(contains(at(10, 30))));
      final hallB = const Room(id: 'hall-b', orgId: 'org-1', name: 'Hall B');
      expect(
        ConflictChecker.freeRooms(
          b('n', at(10), at(11)),
          rooms: [room, hallB],
          existing: existing,
          timezone: tz,
        ).single.id,
        'hall-b',
      );
    });
  });

  group('weekly recurrence', () {
    test('occurrences use local wall-clock time and the bounded window', () {
      final rule = WeeklyRule(
        weekdays: {1, 3},
        startMinute: 16 * 60,
        durationMin: 90,
        from: DateTime.utc(2026, 11, 16),
        until: DateTime.utc(2026, 11, 29),
      );
      final occ = rule.occurrences(tz);
      expect(occ.length, 4);
      expect(occ.first.$1, at(16));
      expect(occ.first.$2, at(17, 30));
      final long = WeeklyRule(
        weekdays: {1},
        startMinute: 600,
        durationMin: 60,
        from: DateTime.utc(2026, 1, 5),
        until: DateTime.utc(2028, 1, 1),
      );
      expect(long.occurrences(tz).length, lessThanOrEqualTo(WeeklyRule.maxWeeks + 1));
    });

    test('every occurrence is checked; one conflict is reported for its date', () {
      final rule = WeeklyRule(
        weekdays: {1},
        startMinute: 10 * 60,
        durationMin: 60,
        from: DateTime.utc(2026, 11, 16),
        until: DateTime.utc(2026, 12, 14),
      );
      final clash = b('x', at(10, 30, 30), at(11, 30, 30));
      final res = ConflictChecker.checkSeries(
        b('t', at(10), at(11)),
        rule,
        room: room,
        existing: [clash],
        timezone: tz,
      );
      expect(res.keys.single, at(10, 0, 30));
    });
  });

  group('feature flags', () {
    test('enabled = active AND allowed AND enabled', () {
      final c = const OrgConfig(
        orgId: 'o',
        allowedModules: {OrgModule.trainings, OrgModule.leaderboards},
        enabledModules: {OrgModule.trainings, OrgModule.roomScheduling},
      );
      expect(c.isEnabled(OrgModule.trainings), isTrue);
      expect(c.isEnabled(OrgModule.roomScheduling), isFalse, reason: 'not allowed by the platform');
      expect(c.isEnabled(OrgModule.leaderboards), isFalse, reason: 'allowed but not enabled');
      expect(c.copyWith(status: OrgStatus.suspended).isEnabled(OrgModule.trainings), isFalse);
      final legacy = OrgConfig.legacy('club-1');
      expect(legacy.isEnabled(OrgModule.brainAcademy), isTrue);
      expect(legacy.isEnabled(OrgModule.roomScheduling), isFalse);
      expect(legacy.isEnabled(OrgModule.leaderboards), isFalse);
    });

    test('config round-trips through the database map', () {
      final c = OrgConfig(
        orgId: 'o',
        plan: OrgPlan.premium,
        allowedModules: OrgPlan.premium.defaultModules,
        enabledModules: {OrgModule.trainings},
        branding: const OrgBranding(names: {'ka': 'სკოლა', 'en': 'School'}, primaryColor: 0xFF0F766E),
        leaderboard: const LeaderboardSettings(enabled: true, games: {BrainGame.logicQuest}),
        timezone: 'Asia/Yerevan',
      );
      final back = OrgConfig.fromMap('o', c.toMap());
      expect(back.plan, OrgPlan.premium);
      expect(back.enabledModules, {OrgModule.trainings});
      expect(back.branding.nameFor('en'), 'School');
      expect(back.branding.nameFor('ru'), 'სკოლა');
      expect(back.leaderboard.games, {BrainGame.logicQuest});
      expect(back.timezone, 'Asia/Yerevan');
    });
  });

  group('scoring service', () {
    final day = DateTime.utc(2026, 11, 16, 8);
    GameResult r(
      String id, {
      int level = 1,
      GameDifficulty d = GameDifficulty.easy,
      double acc = 1,
      int minutes = 0,
      bool done = true,
      int ms = 60000,
      BrainGame g = BrainGame.memoryMatch,
      String child = 'c1',
    }) => GameResult(
      id: id,
      childId: child,
      game: g,
      difficulty: d,
      level: level,
      score: 100,
      accuracy: acc,
      attempts: 5,
      durationMs: ms,
      completed: done,
      playedAt: day.add(Duration(minutes: minutes)),
    );

    test('first clear bonus, then 1 / 0.5 / 0.25 / 0 for repeats of the same level on one day', () {
      final s = ScoringService.score([
        r('a'),
        r('b', minutes: 1),
        r('c', minutes: 2),
        r('d', minutes: 3),
        r('e', minutes: 4),
      ]);
      // easy L1 with 100 % accuracy = 10 + 0 + 10 = 20; first clear +15.
      expect(s.map((x) => x.points), [35, 10, 5, 0, 0]);
    });

    test('harder levels pay more; incomplete or implausibly short plays pay nothing', () {
      expect(ScoringService.total([r('h', d: GameDifficulty.hard, level: 5, acc: .5)]), 30 + 8 + 5 + 15);
      expect(ScoringService.total([r('x', done: false)]), 0);
      expect(ScoringService.total([r('x', ms: 1000)]), 0);
    });

    test('daily cap and duplicate submissions', () {
      final many = [
        for (var i = 0; i < 30; i++)
          r('p$i', level: (i % 10) + 1, d: GameDifficulty.hard, minutes: i, g: BrainGame.values[i % 6]),
      ];
      expect(ScoringService.total(many), ScoringRules.standard.dailyCap);
      expect(ScoringService.total([r('same'), r('same')]), 35, reason: 'one result id counts once');
    });

    test('summary: totals, per game, highest level, weekly points', () {
      final s = ScoringService.summarize([
        r('a'),
        r('b', level: 3, d: GameDifficulty.medium, g: BrainGame.logicQuest, acc: .5),
      ], now: day.add(const Duration(hours: 2)));
      expect(s.gamesCompleted, 2);
      expect(s.pointsByGame[BrainGame.logicQuest], 20 + 4 + 5 + 15);
      expect(s.highestLevel[BrainGame.logicQuest], (GameDifficulty.medium, 3));
      expect(s.weeklyPoints.last, s.totalPoints);
      expect(s.accuracyByGame[BrainGame.logicQuest], .5);
    });

    group('leaderboard', () {
      const settings = LeaderboardSettings(enabled: true, minParticipants: 3);
      final ps = [
        const LeaderboardParticipant(childId: 'c1', displayName: 'Swift Fox 11', ageBand: '9-11'),
        const LeaderboardParticipant(childId: 'c2', displayName: 'Ana K.', ageBand: '9-11'),
        const LeaderboardParticipant(childId: 'c3', displayName: 'Bold Owl 20', ageBand: '9-11'),
        const LeaderboardParticipant(childId: 'c4', displayName: 'Calm Bear 30', ageBand: '12-14'),
      ];
      final results = [
        r('1', child: 'c1'),
        r('2', child: 'c2', minutes: 5),
        r('3', child: 'c3', level: 2),
        r('4', child: 'c4', d: GameDifficulty.hard),
      ];

      test('points desc, then who reached it first, then id', () {
        final e = LeaderboardService.rank(
          participants: ps.take(3),
          results: results,
          settings: settings,
          period: LeaderboardPeriod.week,
          now: day.add(const Duration(hours: 1)),
        );
        expect(e.map((x) => x.childId), ['c3', 'c1', 'c2']);
        expect(e[1].points, e[2].points, reason: 'c1 and c2 tie on points; c1 got there first');
        expect(e.map((x) => x.rank), [1, 2, 3]);
      });

      test('disabled, no consent, too few, age band', () {
        LeaderboardBoard board({bool on = true, bool consent = true, String band = '9-11', int min = 3}) =>
            LeaderboardService.boardFor(
              viewerChildId: 'c1',
              orgEnabled: on,
              viewerConsented: consent,
              viewerAgeBand: band,
              participants: ps,
              results: results,
              settings: settings.copyWith(minParticipants: min),
              period: LeaderboardPeriod.week,
              now: day.add(const Duration(hours: 1)),
            );
        expect(board(on: false).unavailable, LeaderboardUnavailable.disabled);
        expect(board(consent: false).unavailable, LeaderboardUnavailable.notConsented);
        expect(board(band: '12-14').unavailable, LeaderboardUnavailable.tooFewParticipants);
        final ok = board();
        expect(ok.entries.map((e) => e.childId), isNot(contains('c4')), reason: 'other age band');
        expect(ok.ageBand, '9-11');
      });

      test('names are pseudonyms or first name + initial, never full names', () {
        expect(LeaderboardConsent.firstNameInitial('ანა', 'ხუციშვილი'), 'ანა ხ.');
        final p = LeaderboardConsent.pseudonymFor('child-1');
        expect(p, LeaderboardConsent.pseudonymFor('child-1'), reason: 'stable');
        expect(p, matches(RegExp(r'^[A-Z][a-z]+ [A-Z][a-z]+ \d{2}$')));
        expect(LeaderboardSettings.ageBandOf(8), '6-8');
        expect(LeaderboardSettings.ageBandOf(11), '9-11');
        expect(LeaderboardSettings.ageBandOf(14), '12-14');
      });
    });
  });

  group('RSVP summary', () {
    Rsvp rsvp(String child, RsvpResponse r, {int v = 1, Map<String, GuardianResponse> g = const {}}) => Rsvp(
      trainingId: 'e',
      groupId: 'g',
      childId: child,
      parentId: 'p',
      response: r,
      updatedAt: DateTime(2026),
      scheduleVersion: v,
      guardianResponses: g,
    );

    test('each child counts once; an answer for an old version needs reconfirmation', () {
      final s = RsvpSummary.compute(
        ['a', 'b', 'c', 'd', 'e', 'a'],
        [
          rsvp('a', RsvpResponse.yes, v: 2),
          rsvp('b', RsvpResponse.no, v: 2),
          rsvp('c', RsvpResponse.maybe, v: 2),
          rsvp('d', RsvpResponse.yes, v: 1),
        ],
        2,
      );
      expect(s.byChild.length, 5);
      expect(s.count(RsvpState.confirmed), 1);
      expect(s.count(RsvpState.declined), 1);
      expect(s.count(RsvpState.uncertain), 1);
      expect(s.count(RsvpState.needsReconfirmation), 1);
      expect(s.count(RsvpState.notResponded), 1);
    });

    test('guardian answers are kept per guardian; the latest answer is the child-level one', () {
      final at = DateTime(2026, 11, 1);
      var r = rsvp('a', RsvpResponse.yes);
      r = r.withGuardianAnswer(guardianId: 'mom', answer: RsvpResponse.yes, version: 2, at: at);
      r = r.withGuardianAnswer(
        guardianId: 'dad',
        answer: RsvpResponse.no,
        version: 2,
        at: at.add(const Duration(minutes: 5)),
        reason: 'sick',
      );
      expect(r.guardianResponses.keys, {'mom', 'dad'});
      expect(r.response, RsvpResponse.no);
      expect(r.parentId, 'dad');
      expect(r.conflictingFor(2), isTrue);
      final back = Rsvp.fromMap(r.toMap());
      expect(back.guardianResponses['dad']!.reason, 'sick');
      expect(back.scheduleVersion, 2);
    });
  });
}
