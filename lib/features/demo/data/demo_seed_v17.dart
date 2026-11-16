import '../../../core/utils/geo.dart';
import '../../attendance/domain/attendance.dart';
import '../../authentication/domain/app_user.dart';
import '../../brain_academy/domain/brain_models.dart';
import '../../brain_academy/domain/scoring.dart';
import '../../children/domain/child.dart';
import '../../clubs/domain/club.dart';
import '../../groups/domain/group.dart';
import '../../organizations/domain/organization.dart';
import '../../organizations/domain/scheduling.dart';
import '../../sports/domain/sport.dart';
import '../../trainings/domain/training.dart';
import 'demo_backend.dart';
import 'demo_seed.dart';

/// v1.7 demo tenants (fictional, synthetic data only).
///
/// * **Tianeti Sports School / თიანეთის სპორტსკოლა** — premium plan, two
///   halls, volleyball / badminton / football programs, recurring room
///   bookings, RSVPs (one needing reconfirmation), attendance, Brain Academy
///   plays and an opted-in leaderboard. Luka (the demo student) also trains
///   here, so he belongs to two organizations.
/// * **Mtskheta Youth Academy** — a second tenant used to show isolation: its
///   room is booked at the same time as Tianeti's Hall A without conflict.
class DemoSeedV17 {
  DemoSeedV17._();

  static const tianeti = 'org-tianeti';
  static const mtskheta = 'org-mtskheta';
  static const tianetiAdmin = 'admin-tianeti';
  static const mtskhetaAdmin = 'admin-mtskheta';
  static const volleyCoach = 'coach-t1';
  static const badmintonCoach = 'coach-t2';
  static const mtskhetaCoach = 'coach-m1';
  static const tianetiParent = 'parent-t1';
  static const tianetiParent2 = 'parent-t2';
  static const mtskhetaParent = 'parent-m1';
  static const hallA = 'room-tianeti-a';
  static const hallB = 'room-tianeti-b';
  static const mtskhetaHall = 'room-mtskheta-main';
  static const volleyGroup = 'g-tianeti-volley';
  static const badmintonGroup = 'g-tianeti-badminton';
  static const footballGroup = 'g-tianeti-football';
  static const mtskhetaGroup = 'g-mtskheta-basket';
  static const venue = 'venue-tianeti';

  /// The upcoming volleyball training whose RSVP needs reconfirmation.
  static const rescheduledTraining = 'tr-tianeti-resched';

  /// Localized catalog names for every sport (new and existing).
  static const sportNames = <String, Map<String, String>>{
    'football': {'ka': 'ფეხბურთი', 'en': 'Football', 'ru': 'Футбол'},
    'basketball': {'ka': 'კალათბურთი', 'en': 'Basketball', 'ru': 'Баскетбол'},
    'swimming': {'ka': 'ცურვა', 'en': 'Swimming', 'ru': 'Плавание'},
    'tennis': {'ka': 'ჩოგბურთი', 'en': 'Tennis', 'ru': 'Теннис'},
    'wrestling': {'ka': 'ჭიდაობა', 'en': 'Wrestling', 'ru': 'Борьба'},
    'judo': {'ka': 'ძიუდო', 'en': 'Judo', 'ru': 'Дзюдо'},
    'rugby': {'ka': 'რაგბი', 'en': 'Rugby', 'ru': 'Регби'},
    'gymnastics': {'ka': 'ტანვარჯიში', 'en': 'Gymnastics', 'ru': 'Гимнастика'},
    'volleyball': {'ka': 'ფრენბურთი', 'en': 'Volleyball', 'ru': 'Волейбол'},
    'badminton': {'ka': 'ბადმინტონი', 'en': 'Badminton', 'ru': 'Бадминтон'},
    'taekwondo': {'ka': 'ტაეკვონდო', 'en': 'Taekwondo', 'ru': 'Тхэквондо'},
    'mma': {'ka': 'MMA', 'en': 'MMA', 'ru': 'ММА'},
    'fitness': {'ka': 'ზოგადი ფიზიკური მომზადება', 'en': 'General physical training', 'ru': 'ОФП'},
  };

  static void seed(DemoBackend db) {
    final now = db.clock();
    _sports(db);

    // ── organizations ──────────────────────────────────────────────────
    db.clubs[tianeti] = const Club(
      id: tianeti,
      name: 'თიანეთის სპორტსკოლა',
      address: 'რუსთაველის ქ. 12, თიანეთი',
      sportIds: ['volleyball', 'badminton', 'football', 'wrestling'],
      location: GeoCoord(42.1089, 44.9690),
      geohash: 'szrpvd',
      phone: '+995555100700',
      description: 'მუნიციპალური სპორტული სკოლა (სადემონსტრაციო)',
      adminIds: [tianetiAdmin],
    );
    db.clubs[mtskheta] = const Club(
      id: mtskheta,
      name: 'მცხეთის ახალგაზრდული აკადემია',
      address: 'აღმაშენებლის ქ. 5, მცხეთა',
      sportIds: ['basketball', 'badminton'],
      location: GeoCoord(41.8456, 44.7186),
      geohash: 'szrkfb',
      adminIds: [mtskhetaAdmin],
    );
    db.orgConfigs[tianeti] = OrgConfig(
      orgId: tianeti,
      plan: OrgPlan.premium,
      allowedModules: OrgPlan.premium.defaultModules,
      enabledModules: OrgPlan.premium.defaultModules,
      branding: const OrgBranding(
        names: {'ka': 'თიანეთის სპორტსკოლა', 'en': 'Tianeti Sports School', 'ru': 'Спортивная школа Тианети'},
        primaryColor: 0xFF0F766E,
        description: 'Volleyball, badminton, football and wrestling for ages 6–17.',
        contactPhone: '+995555100700',
        contactEmail: 'info@tianeti-sports.example',
        address: 'რუსთაველის ქ. 12, თიანეთი',
      ),
      limits: OrgPlan.premium.defaultLimits,
      leaderboard: const LeaderboardSettings(enabled: true, minParticipants: 3),
      updatedAt: now,
    );
    db.orgConfigs[mtskheta] = OrgConfig(
      orgId: mtskheta,
      plan: OrgPlan.standard,
      allowedModules: {...OrgPlan.standard.defaultModules, OrgModule.roomScheduling},
      enabledModules: {...OrgPlan.standard.defaultModules, OrgModule.roomScheduling},
      branding: const OrgBranding(
        names: {
          'ka': 'მცხეთის ახალგაზრდული აკადემია',
          'en': 'Mtskheta Youth Academy',
          'ru': 'Молодёжная академия Мцхеты',
        },
        primaryColor: 0xFF7C2D12,
      ),
      limits: OrgPlan.standard.defaultLimits,
      updatedAt: now,
    );

    db.venues[venue] = const Venue(
      id: venue,
      clubId: tianeti,
      name: 'თიანეთის სპორტული კომპლექსი',
      address: 'რუსთაველის ქ. 12, თიანეთი',
      location: GeoCoord(42.1089, 44.9690),
      geohash: 'szrpvd',
      sportIds: ['volleyball', 'badminton', 'football', 'wrestling'],
      type: VenueType.hall,
    );
    db.venues['venue-mtskheta'] = const Venue(
      id: 'venue-mtskheta',
      clubId: mtskheta,
      name: 'მცხეთის სპორტული დარბაზი',
      address: 'აღმაშენებლის ქ. 5, მცხეთა',
      location: GeoCoord(41.8456, 44.7186),
      geohash: 'szrkfb',
      sportIds: ['basketball', 'badminton'],
      type: VenueType.hall,
    );

    // ── people (synthetic) ─────────────────────────────────────────────
    AppUser user(String id, UserRole role, String first, String last, String phone, {List<String> clubs = const []}) =>
        AppUser(
          id: id,
          role: role,
          firstName: first,
          lastName: last,
          phone: phone,
          createdAt: now.subtract(const Duration(days: 90)),
          coachStatus: role == UserRole.coach ? CoachStatus.approved : null,
          clubIds: clubs,
          dataConsentAt: now.subtract(const Duration(days: 90)),
          smsConsentAt: role == UserRole.parent ? now.subtract(const Duration(days: 90)) : null,
        );
    db.users[tianetiAdmin] = user(
      tianetiAdmin,
      UserRole.parent,
      'თამარ',
      'ლომიძე',
      '+995555100701',
    ).copyWith(adminRole: AdminRole.club, adminClubIds: [tianeti]);
    db.users[mtskhetaAdmin] = user(
      mtskhetaAdmin,
      UserRole.parent,
      'დავით',
      'კობახიძე',
      '+995555100702',
    ).copyWith(adminRole: AdminRole.club, adminClubIds: [mtskheta]);
    db.users[volleyCoach] = user(
      volleyCoach,
      UserRole.coach,
      'ნინო',
      'გელაშვილი',
      '+995555100711',
      clubs: [tianeti],
    ).copyWith(sportIds: ['volleyball']);
    db.users[badmintonCoach] = user(
      badmintonCoach,
      UserRole.coach,
      'ლევან',
      'ჩიქოვანი',
      '+995555100712',
      clubs: [tianeti],
    ).copyWith(sportIds: ['badminton']);
    db.users[mtskhetaCoach] = user(
      mtskhetaCoach,
      UserRole.coach,
      'ირაკლი',
      'მაისურაძე',
      '+995555100713',
      clubs: [mtskheta],
    ).copyWith(sportIds: ['basketball']);
    db.users[tianetiParent] = user(tianetiParent, UserRole.parent, 'ეკა', 'ხუციშვილი', '+995555100721');
    db.users[tianetiParent2] = user(tianetiParent2, UserRole.parent, 'გიორგი', 'ხუციშვილი', '+995555100722');
    db.users[mtskhetaParent] = user(mtskhetaParent, UserRole.parent, 'სოფო', 'ნოზაძე', '+995555100723');
    // The demo football coach is also a member of Tianeti (multi-organization
    // membership; he does not coach a Tianeti group yet).
    final giorgi = db.users[DemoIds.coach];
    if (giorgi != null) db.users[DemoIds.coach] = giorgi.copyWith(clubIds: {...giorgi.clubIds, tianeti}.toList());

    DateTime born(int years, int days) => DateTime(now.year - years, now.month, now.day).subtract(Duration(days: days));
    // Two guardians for Ana: both answers are kept, the child counts once.
    db.children['child-t1'] = Child(
      id: 'child-t1',
      firstName: 'ანა',
      lastName: 'ხუციშვილი',
      birthDate: born(10, 30),
      parentIds: const [tianetiParent, tianetiParent2],
      sportIds: const ['volleyball'],
      photoConsent: false,
    );
    db.guardianRelations['child-t1'] = {tianetiParent: 'mother', tianetiParent2: 'father'};
    db.children['child-t2'] = Child(
      id: 'child-t2',
      firstName: 'საბა',
      lastName: 'ხუციშვილი',
      birthDate: born(11, 120),
      parentIds: const [tianetiParent],
      sportIds: const ['badminton', 'volleyball'],
      photoConsent: false,
    );
    db.children['child-t3'] = Child(
      id: 'child-t3',
      firstName: 'ელენე',
      lastName: 'ბურდული',
      birthDate: born(9, 200),
      parentIds: const [tianetiParent2],
      sportIds: const ['volleyball'],
      photoConsent: false,
    );
    db.children['child-m1'] = Child(
      id: 'child-m1',
      firstName: 'ნიკა',
      lastName: 'ნოზაძე',
      birthDate: born(12, 10),
      parentIds: const [mtskhetaParent],
      sportIds: const ['basketball'],
      photoConsent: false,
    );

    db.groups[volleyGroup] = const Group(
      id: volleyGroup,
      clubId: tianeti,
      sportId: 'volleyball',
      coachIds: [volleyCoach],
      name: 'ფრენბურთი U-12',
      ageMin: 8,
      ageMax: 12,
      memberChildIds: ['child-t1', 'child-t2', 'child-t3'],
      scheduleNote: 'ორშ, ოთხ 16:00 · დარბაზი A',
    );
    db.groups[badmintonGroup] = const Group(
      id: badmintonGroup,
      clubId: tianeti,
      sportId: 'badminton',
      coachIds: [badmintonCoach],
      name: 'ბადმინტონი · იუნიორები',
      ageMin: 9,
      ageMax: 14,
      memberChildIds: ['child-t2'],
      scheduleNote: 'სამ, ხუთ 17:00 · დარბაზი B',
    );
    db.groups[footballGroup] = const Group(
      id: footballGroup,
      clubId: tianeti,
      sportId: 'football',
      coachIds: [volleyCoach],
      name: 'ფეხბურთი · თიანეთი U-11',
      ageMin: 9,
      ageMax: 11,
      memberChildIds: ['child-1', 'child-t2'],
      scheduleNote: 'შაბ 10:00 · დარბაზი A',
    );
    db.groups[mtskhetaGroup] = const Group(
      id: mtskhetaGroup,
      clubId: mtskheta,
      sportId: 'basketball',
      coachIds: [mtskhetaCoach],
      name: 'კალათბურთი U-13',
      ageMin: 10,
      ageMax: 13,
      memberChildIds: ['child-m1'],
    );
    db.recomputeMemberships();

    void member(String org, String uid, Set<OrgRole> roles) =>
        db.memberships['$org|$uid'] = OrgMembership(orgId: org, userId: uid, roles: roles);
    member(tianeti, tianetiAdmin, {OrgRole.admin});
    member(mtskheta, mtskhetaAdmin, {OrgRole.admin});
    member(tianeti, volleyCoach, {OrgRole.coach});
    member(tianeti, badmintonCoach, {OrgRole.coach});
    member(tianeti, DemoIds.coach, {OrgRole.coach});
    member(mtskheta, mtskhetaCoach, {OrgRole.coach});
    member(tianeti, tianetiParent, {OrgRole.parent});
    member(tianeti, tianetiParent2, {OrgRole.parent});
    member(tianeti, DemoIds.parent, {OrgRole.parent});
    member(tianeti, DemoIds.student, {OrgRole.student});
    member(mtskheta, mtskhetaParent, {OrgRole.parent});

    // ── rooms and programs ─────────────────────────────────────────────
    db.rooms[hallA] = const Room(
      id: hallA,
      orgId: tianeti,
      name: 'დარბაზი A',
      capacity: 40,
      sportIds: ['volleyball', 'football', 'wrestling'],
      venueId: venue,
    );
    db.rooms[hallB] = const Room(
      id: hallB,
      orgId: tianeti,
      name: 'დარბაზი B',
      capacity: 24,
      sportIds: ['badminton', 'wrestling'],
      venueId: venue,
    );
    db.rooms[mtskhetaHall] = const Room(
      id: mtskhetaHall,
      orgId: mtskheta,
      name: 'მთავარი დარბაზი',
      capacity: 30,
      venueId: 'venue-mtskheta',
    );
    db.programs['program-volley'] = const SportsProgram(
      id: 'program-volley',
      orgId: tianeti,
      sportId: 'volleyball',
      name: 'ფრენბურთი 8–12',
      description: 'Beginner and intermediate volleyball.',
      ageMin: 8,
      ageMax: 12,
      coachIds: [volleyCoach],
      groupIds: [volleyGroup],
      roomId: hallA,
      venueId: venue,
      scheduleNote: 'Mon, Wed 16:00–17:30',
      capacity: 18,
    );
    db.programs['program-badminton'] = const SportsProgram(
      id: 'program-badminton',
      orgId: tianeti,
      sportId: 'badminton',
      name: 'ბადმინტონი 9–14',
      ageMin: 9,
      ageMax: 14,
      coachIds: [badmintonCoach],
      groupIds: [badmintonGroup],
      roomId: hallB,
      venueId: venue,
      scheduleNote: 'Tue, Thu 17:00–18:30',
      capacity: 12,
    );
    db.programs['program-football'] = const SportsProgram(
      id: 'program-football',
      orgId: tianeti,
      sportId: 'football',
      name: 'ფეხბურთი 9–11',
      ageMin: 9,
      ageMax: 11,
      coachIds: [volleyCoach],
      groupIds: [footballGroup],
      roomId: hallA,
      venueId: venue,
      capacity: 16,
    );
    db.programs['program-mtskheta-basket'] = const SportsProgram(
      id: 'program-mtskheta-basket',
      orgId: mtskheta,
      sportId: 'basketball',
      name: 'კალათბურთი 10–13',
      coachIds: [mtskhetaCoach],
      groupIds: [mtskhetaGroup],
      roomId: mtskhetaHall,
    );

    // ── recurring bookings (+ linked trainings) for the next 4 weeks ────
    const tz = OrgTimeZones.tbilisi;
    final today = OrgTimeZones.wall(now, tz);
    final from = DateTime.utc(today.year, today.month, today.day).subtract(const Duration(days: 14));
    final until = from.add(const Duration(days: 42));
    var seq = 0;
    void series(
      String org,
      String room,
      String? group,
      String? coach,
      String sport,
      Set<int> days,
      int startMin,
      int dur,
      String title, {
      bool linkTraining = true,
      BookingKind kind = BookingKind.training,
    }) {
      final rule = WeeklyRule(weekdays: days, startMinute: startMin, durationMin: dur, from: from, until: until);
      final sid = 'series-$org-${seq++}';
      for (final (s, e) in rule.occurrences(tz)) {
        final id = 'bk-$org-${seq++}';
        String? eventId;
        if (linkTraining && group != null) {
          eventId = 'tr-$id';
          db.trainings[eventId] = Training(
            id: eventId,
            groupId: group,
            venueId: db.rooms[room]?.venueId ?? '',
            startAt: s,
            durationMin: dur,
            focus: const [TrainingFocus.technique],
            description: title,
            createdBy: tianetiAdmin,
            status: e.isBefore(now) ? TrainingStatus.done : TrainingStatus.scheduled,
            roomId: room,
          );
        }
        db.bookings[id] = Booking(
          id: id,
          orgId: org,
          roomId: room,
          kind: kind,
          startAt: s,
          endAt: e,
          title: title,
          coachId: coach,
          groupId: group,
          sportId: sport,
          seriesId: sid,
          rule: rule,
          eventId: eventId,
          createdBy: org == tianeti ? tianetiAdmin : mtskhetaAdmin,
          updatedAt: now,
        );
      }
    }

    series(tianeti, hallA, volleyGroup, volleyCoach, 'volleyball', {1, 3}, 16 * 60, 90, 'ფრენბურთი U-12');
    series(tianeti, hallB, badmintonGroup, badmintonCoach, 'badminton', {2, 4}, 17 * 60, 90, 'ბადმინტონი');
    series(tianeti, hallA, footballGroup, volleyCoach, 'football', {6}, 10 * 60, 90, 'ფეხბურთი U-11');
    series(
      tianeti,
      hallB,
      null,
      null,
      'wrestling',
      {5},
      12 * 60,
      120,
      'ტექნიკური მომსახურება',
      linkTraining: false,
      kind: BookingKind.maintenance,
    );
    // Same wall-clock time as Tianeti Hall A — different tenant, no conflict.
    series(mtskheta, mtskhetaHall, mtskhetaGroup, mtskhetaCoach, 'basketball', {1, 3}, 16 * 60, 90, 'კალათბურთი U-13');

    // ── an upcoming training that was rescheduled (needs reconfirmation) ─
    final soon = DateTime.utc(today.year, today.month, today.day + 2, 15).subtract(const Duration(hours: 4));
    db.trainings[rescheduledTraining] = Training(
      id: rescheduledTraining,
      groupId: volleyGroup,
      venueId: venue,
      startAt: soon,
      durationMin: 60,
      focus: const [TrainingFocus.ball],
      description: 'დამატებითი ვარჯიში (გადატანილი)',
      createdBy: volleyCoach,
      status: TrainingStatus.moved,
      previousStartAt: soon.subtract(const Duration(hours: 2)),
      scheduleVersion: 2,
      updatedAt: now.subtract(const Duration(hours: 3)),
    );
    final v1 = now.subtract(const Duration(days: 1));
    // Ana: mother said yes for v1, father said yes for v2 → confirmed.
    db.rsvps[Rsvp.docId(rescheduledTraining, 'child-t1')] = Rsvp(
      trainingId: rescheduledTraining,
      groupId: volleyGroup,
      childId: 'child-t1',
      parentId: tianetiParent2,
      response: RsvpResponse.yes,
      updatedAt: now.subtract(const Duration(hours: 1)),
      scheduleVersion: 2,
      guardianResponses: {
        tianetiParent: GuardianResponse(response: RsvpResponse.yes, version: 1, at: v1),
        tianetiParent2: GuardianResponse(
          response: RsvpResponse.yes,
          version: 2,
          at: now.subtract(const Duration(hours: 1)),
        ),
      },
    );
    // Saba: answered for the old time only → needs reconfirmation.
    db.rsvps[Rsvp.docId(rescheduledTraining, 'child-t2')] = Rsvp(
      trainingId: rescheduledTraining,
      groupId: volleyGroup,
      childId: 'child-t2',
      parentId: tianetiParent,
      response: RsvpResponse.no,
      reason: 'ექიმთან ვიზიტი',
      updatedAt: v1,
      scheduleVersion: 1,
      guardianResponses: {
        tianetiParent: GuardianResponse(response: RsvpResponse.no, version: 1, at: v1, reason: 'ექიმთან ვიზიტი'),
      },
    );
    db.rsvpHistory.addAll([
      RsvpHistoryEntry(
        rsvpId: Rsvp.docId(rescheduledTraining, 'child-t1'),
        guardianId: tianetiParent,
        response: RsvpResponse.yes,
        version: 1,
        at: v1,
      ),
      RsvpHistoryEntry(
        rsvpId: Rsvp.docId(rescheduledTraining, 'child-t1'),
        guardianId: tianetiParent2,
        response: RsvpResponse.yes,
        version: 2,
        at: now.subtract(const Duration(hours: 1)),
      ),
      RsvpHistoryEntry(
        rsvpId: Rsvp.docId(rescheduledTraining, 'child-t2'),
        guardianId: tianetiParent,
        response: RsvpResponse.no,
        version: 1,
        at: v1,
        reason: 'ექიმთან ვიზიტი',
      ),
    ]);
    db.announceScheduleChange(
      db.groups[volleyGroup]!,
      eventId: rescheduledTraining,
      eventType: 'training',
      version: 2,
      text: 'ვარჯიშის განრიგი შეიცვალა. გთხოვთ, დაადასტუროთ დასწრება.',
      route: '/training/$rescheduledTraining',
    );

    // ── coach-recorded attendance for past Tianeti trainings ───────────
    final past = db.trainings.values.where((t) => t.groupId == volleyGroup && t.status == TrainingStatus.done).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    const pattern = [
      AttendanceStatus.present,
      AttendanceStatus.present,
      AttendanceStatus.absent,
      AttendanceStatus.excused,
    ];
    for (var i = 0; i < past.length; i++) {
      for (final (j, c) in const ['child-t1', 'child-t2', 'child-t3'].indexed) {
        final t = past[i];
        db.attendance[AttendanceRecord.docId(t.id, c)] = AttendanceRecord(
          trainingId: t.id,
          groupId: volleyGroup,
          childId: c,
          status: pattern[(i + j) % pattern.length],
          markedBy: volleyCoach,
          markedAt: t.endAt,
        );
      }
    }

    // ── Brain Academy plays + leaderboard consents ─────────────────────
    var n = 0;
    GameResult play(String child, BrainGame g, GameDifficulty d, int level, int score, double acc, int daysAgo) =>
        GameResult(
          id: 'v17-$child-${n++}',
          childId: child,
          game: g,
          difficulty: d,
          level: level,
          score: score,
          accuracy: acc,
          attempts: 10,
          durationMs: 60000,
          completed: true,
          playedAt: now.subtract(Duration(days: daysAgo, hours: n)),
        );
    db.brainResults.addAll([
      play('child-t1', BrainGame.memoryMatch, GameDifficulty.medium, 2, 420, .9, 1),
      play('child-t1', BrainGame.logicQuest, GameDifficulty.easy, 3, 300, 1, 2),
      play('child-t1', BrainGame.smartPlay, GameDifficulty.medium, 1, 250, .8, 3),
      play('child-t2', BrainGame.quickMind, GameDifficulty.easy, 2, 280, .75, 0),
      play('child-t2', BrainGame.pathFinder, GameDifficulty.medium, 1, 350, .85, 2),
      play('child-t3', BrainGame.sequenceMaster, GameDifficulty.easy, 1, 180, .7, 1),
      play('child-t3', BrainGame.memoryMatch, GameDifficulty.easy, 1, 200, .8, 4),
    ]);
    LeaderboardConsent consent(String child, String guardian, DisplayNameMode mode) {
      final c = db.children[child]!;
      return LeaderboardConsent(
        orgId: tianeti,
        childId: child,
        guardianId: guardian,
        granted: true,
        mode: mode,
        displayName: mode == DisplayNameMode.pseudonym
            ? LeaderboardConsent.pseudonymFor(child)
            : LeaderboardConsent.firstNameInitial(c.firstName, c.lastName),
        at: now.subtract(const Duration(days: 10)),
      );
    }

    db.leaderboardConsents['$tianeti|child-t1'] = consent('child-t1', tianetiParent, DisplayNameMode.pseudonym);
    db.leaderboardConsents['$tianeti|child-t2'] = consent('child-t2', tianetiParent, DisplayNameMode.firstNameInitial);
    db.leaderboardConsents['$tianeti|child-t3'] = consent('child-t3', tianetiParent2, DisplayNameMode.pseudonym);
    db.leaderboardConsents['$tianeti|child-1'] = consent('child-1', DemoIds.parent, DisplayNameMode.pseudonym);
  }

  static void _sports(DemoBackend db) {
    void add(Sport s) => db.sports[s.id] = s;
    if (!db.sports.containsKey('volleyball')) {
      add(
        const Sport(id: 'volleyball', name: 'ფრენბურთი', icon: 'volleyball', category: SportCategory.team, order: 30),
      );
    }
    if (!db.sports.containsKey('badminton')) {
      add(const Sport(id: 'badminton', name: 'ბადმინტონი', icon: 'badminton', order: 31));
    }
    if (!db.sports.containsKey('taekwondo')) {
      add(
        const Sport(id: 'taekwondo', name: 'ტაეკვონდო', icon: 'taekwondo', category: SportCategory.combat, order: 32),
      );
    }
    if (!db.sports.containsKey('mma')) {
      add(const Sport(id: 'mma', name: 'MMA', icon: 'mma', category: SportCategory.combat, ageMin: 12, order: 33));
    }
    if (!db.sports.containsKey('fitness')) {
      add(const Sport(id: 'fitness', name: 'ზოგადი ფიზიკური მომზადება', icon: 'fitness', order: 34));
    }
    for (final e in sportNames.entries) {
      final s = db.sports[e.key];
      if (s != null) db.sports[e.key] = s.copyWith(names: e.value);
    }
  }
}
