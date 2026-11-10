import '../../admin/domain/admin_models.dart';
import '../../attendance/domain/attendance.dart';
import '../../authentication/domain/app_user.dart';
import '../../chat/domain/chat_message.dart';
import '../../children/domain/child.dart';
import '../../groups/domain/group.dart';
import '../../matches/domain/match.dart';
import '../../media/domain/media_post.dart';
import '../../moderation/domain/report.dart';
import '../../notifications/domain/notification_models.dart';
import '../../sports/domain/sport.dart';
import '../../trainings/domain/series.dart';
import '../../trainings/domain/training.dart';
import 'demo_backend.dart';
import 'demo_seed.dart';

/// v1.1 / v1.2 demo data: sports catalog fields, admins, invite codes,
/// invitations, recurring schedules, matches, attendance history, RSVPs,
/// coach feedback, media posts, moderation queue and audit trail.
/// All people, places and numbers are fictional.
class DemoSeedV12 {
  DemoSeedV12._();

  static void seed(DemoBackend db) {
    final now = db.clock();
    final today = DateTime(now.year, now.month, now.day);

    // ── Sports catalog (DB-managed, v1.1 §6) ────────────────────────────
    const cat = {
      'football': (SportCategory.team, 5, 1),
      'basketball': (SportCategory.team, 6, 2),
      'swimming': (SportCategory.other, 4, 3),
      'tennis': (SportCategory.other, 5, 4),
      'wrestling': (SportCategory.combat, 6, 5),
      'judo': (SportCategory.combat, 5, 6),
      'rugby': (SportCategory.team, 7, 7),
      'gymnastics': (SportCategory.other, 4, 8),
    };
    for (final e in cat.entries) {
      final s = db.sports[e.key];
      if (s == null) continue;
      db.sports[e.key] = Sport(
        id: s.id,
        name: s.name,
        icon: s.icon,
        category: e.value.$1,
        ageMin: e.value.$2,
        order: e.value.$3,
      );
    }
    for (final s in const [
      Sport(id: 'mma', name: 'MMA', icon: 'mma', category: SportCategory.combat, ageMin: 12, order: 9),
      Sport(
        id: 'taekwondo',
        name: 'ტაეკვონდო',
        icon: 'taekwondo',
        category: SportCategory.combat,
        ageMin: 5,
        order: 10,
      ),
      Sport(
        id: 'freestyle',
        name: 'თავისუფალი ჭიდაობა',
        icon: 'wrestling',
        category: SportCategory.combat,
        ageMin: 6,
        order: 11,
      ),
    ]) {
      db.sports[s.id] = s;
    }
    final club4 = db.clubs['club-4'];
    if (club4 != null) db.clubs['club-4'] = club4.copyWith(sportIds: [...club4.sportIds, 'freestyle', 'mma']);

    // ── Admins and more coach applications ──────────────────────────────
    AppUser person(
      String id,
      UserRole role,
      String first,
      String last,
      String phone, {
      CoachStatus? status,
      List<String> clubs = const [],
      List<String> sports = const [],
      AdminRole? admin,
      List<String> adminClubs = const [],
      String? reason,
      int daysAgo = 200,
    }) => AppUser(
      id: id,
      role: role,
      firstName: first,
      lastName: last,
      phone: phone,
      createdAt: now.subtract(Duration(days: daysAgo)),
      coachStatus: status,
      clubIds: clubs,
      sportIds: sports,
      dataConsentAt: now.subtract(Duration(days: daysAgo)),
      adminRole: admin,
      adminClubIds: adminClubs,
      coachStatusReason: reason,
    );
    for (final u in [
      person(DemoIds.platformAdmin, UserRole.admin, 'მარიამ', 'წერეთელი', '+995555000301', admin: AdminRole.platform),
      person(
        DemoIds.clubAdmin,
        UserRole.admin,
        'ირაკლი',
        'ჩხეიძე',
        '+995555000302',
        admin: AdminRole.club,
        adminClubs: ['club-1'],
      ),
      person(
        'coach-5',
        UserRole.coach,
        'ბექა',
        'ხარაიშვილი',
        '+995555000205',
        status: CoachStatus.pending,
        clubs: ['club-1'],
        sports: ['football'],
        daysAgo: 2,
      ),
      person(
        'coach-6',
        UserRole.coach,
        'ნათია',
        'გოგოლაძე',
        '+995555000206',
        status: CoachStatus.pending,
        clubs: ['club-4'],
        sports: ['freestyle'],
        daysAgo: 1,
      ),
      person(
        'coach-7',
        UserRole.coach,
        'შოთა',
        'ბაქრაძე',
        '+995555000207',
        status: CoachStatus.rejected,
        clubs: ['club-2'],
        sports: ['basketball'],
        reason: 'კვალიფიკაციის დოკუმენტი ვერ დადასტურდა',
        daysAgo: 20,
      ),
    ]) {
      db.users[u.id] = u;
    }

    // ── Invite codes and group metadata (v1.1 §2) ───────────────────────
    const codes = {
      'g-football-u10': 'KXT7PM',
      'g-football-u12': 'FQ8B2R',
      'g-basket-u13': 'BSK3TW',
      'g-swim-juniors': 'SWM4JR',
      'g-tennis-teens': 'TNS5QH',
      'g-wrestling-kids': 'WRS6KD',
      'g-batumi-u10': 'BTM7UZ',
    };
    for (final e in codes.entries) {
      final g = db.groups[e.key];
      if (g == null) continue;
      db.groups[e.key] = Group(
        id: g.id,
        clubId: g.clubId,
        sportId: g.sportId,
        coachIds: g.coachIds,
        name: g.name,
        ageMin: g.ageMin,
        ageMax: g.ageMax,
        memberChildIds: g.memberChildIds,
        parentIds: g.parentIds,
        scheduleNote: g.scheduleNote,
        inviteCode: e.value,
        createdBy: g.coachIds.firstOrNull,
      );
    }

    // ── Attendance history: 3 extra months of U-10 trainings ───────────
    final u10 = db.groups['g-football-u10']!;
    for (var d = -95; d <= -22; d++) {
      final day = today.add(Duration(days: d));
      if (day.weekday != DateTime.tuesday && day.weekday != DateTime.thursday) continue;
      final id = 'tr-hist-$d';
      db.trainings[id] = Training(
        id: id,
        groupId: u10.id,
        venueId: 'venue-1',
        startAt: DateTime(day.year, day.month, day.day, 17),
        durationMin: 90,
        focus: d.isEven ? const [TrainingFocus.technique] : const [TrainingFocus.ball, TrainingFocus.speed],
        description: 'გუნდური ვარჯიში: ტექნიკა და თამაში.',
        createdBy: DemoIds.coach,
        status: TrainingStatus.done,
        updatedAt: day,
      );
    }
    // Deterministic pattern per child: child-1 very regular, others vary.
    const pattern = {
      'child-1': [0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 1],
      'child-4': [0, 1, 0, 0, 2, 0, 1, 0, 0, 0, 1, 0],
      'child-5': [0, 0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0],
      'child-7': [0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0],
    };
    const statuses = [AttendanceStatus.present, AttendanceStatus.absent, AttendanceStatus.excused];
    void record(String groupId, String coachId, Map<String, List<int>> p) {
      final past =
          db.trainings.values
              .where((t) => t.groupId == groupId && t.status == TrainingStatus.done && t.startAt.isBefore(now))
              .toList()
            ..sort((a, b) => a.startAt.compareTo(b.startAt));
      for (var i = 0; i < past.length; i++) {
        final t = past[i];
        for (final e in p.entries) {
          final a = AttendanceRecord(
            trainingId: t.id,
            groupId: groupId,
            childId: e.key,
            status: statuses[e.value[i % e.value.length]],
            markedBy: coachId,
            markedAt: t.endAt,
          );
          db.attendance[a.id] = a;
        }
      }
    }

    record(u10.id, DemoIds.coach, pattern);
    record('g-basket-u13', 'coach-2', const {
      'child-2': [0, 0, 0, 1, 0, 0],
      'child-5': [0, 2, 0, 0],
      'child-6': [0, 0, 0],
    });
    record('g-swim-juniors', 'coach-3', const {
      'child-1': [0, 0, 1],
      'child-6': [0, 0, 0, 2],
    });

    // ── Coach feedback (constructive, age-appropriate) ──────────────────
    void fb(
      String id,
      String child,
      String group,
      String coach,
      String coachName,
      int daysAgo,
      Map<FeedbackCategory, int> r,
      String comment,
    ) {
      db.feedback[id] = CoachFeedback(
        id: id,
        childId: child,
        groupId: group,
        coachId: coach,
        coachName: coachName,
        createdAt: now.subtract(Duration(days: daysAgo)),
        ratings: r,
        comment: comment,
      );
    }

    fb('fb-1', 'child-1', u10.id, DemoIds.coach, 'გიორგი კაპანაძე', 30, const {
      FeedbackCategory.technique: 3,
      FeedbackCategory.discipline: 4,
      FeedbackCategory.teamwork: 4,
      FeedbackCategory.effort: 5,
    }, 'ლუკა ძალიან ცდილობს. შემდეგი ნაბიჯი — მარცხენა ფეხით პასი.');
    fb('fb-2', 'child-1', u10.id, DemoIds.coach, 'გიორგი კაპანაძე', 4, const {
      FeedbackCategory.technique: 4,
      FeedbackCategory.discipline: 4,
      FeedbackCategory.teamwork: 5,
      FeedbackCategory.effort: 5,
      FeedbackCategory.improvement: 5,
    }, 'შესამჩნევი პროგრესი პირველ შეხებაში. გუნდელებს ყოველთვის ეხმარება 👏');
    fb('fb-3', 'child-2', 'g-basket-u13', 'coach-2', 'თამარ ლომიძე', 6, const {
      FeedbackCategory.technique: 4,
      FeedbackCategory.teamwork: 5,
      FeedbackCategory.effort: 4,
    }, 'დაცვაში ძალიან კარგად კითხულობს თამაშს. ვმუშაობთ სროლის სტაბილურობაზე.');

    // ── Recurring schedule for U-12 (Mon/Wed 18:00), v1.2 ──────────────
    db.trainings.removeWhere((_, t) => t.groupId == 'g-football-u12' && t.startAt.isAfter(now));
    final series = TrainingSeries(
      id: 'ser-u12',
      groupId: 'g-football-u12',
      clubId: 'club-1',
      venueId: 'venue-2',
      weekdays: const [1, 3],
      startTime: const LocalTime(18, 0),
      durationMin: 90,
      focus: const [TrainingFocus.ball, TrainingFocus.technique],
      description: 'U-12 რეგულარული ვარჯიში: ტაქტიკა და ტექნიკა.',
      startDate: LocalDate.tbilisi(now),
      createdBy: DemoIds.coach,
    );
    db.series[series.id] = series;
    final plan = RecurrenceEngine.reconcile(series, existing: const [], now: now);
    for (final t in plan.create) {
      db.trainings[t.id] = t;
    }

    // ── Matches (v1.1 §8) ───────────────────────────────────────────────
    DateTime at(int days, int h, [int m = 0]) {
      final d = today.add(Duration(days: days));
      return DateTime(d.year, d.month, d.day, h, m);
    }

    for (final m in [
      SportMatch(
        id: 'match-1',
        groupId: u10.id,
        clubId: 'club-1',
        venueId: 'venue-7',
        startAt: at(5, 12),
        opponentName: 'დინამოს აკადემია U-10',
        matchType: MatchType.league,
        homeAway: HomeAway.away,
        description: 'შეკრება 11:15-ზე სტადიონის მთავარ შესასვლელთან.',
        createdBy: DemoIds.coach,
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      SportMatch(
        id: 'match-2',
        groupId: u10.id,
        clubId: 'club-1',
        venueId: 'venue-1',
        startAt: at(12, 11),
        opponentName: 'საბურთალო U-10 (B)',
        createdBy: DemoIds.coach,
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      SportMatch(
        id: 'match-3',
        groupId: 'g-basket-u13',
        clubId: 'club-2',
        venueId: 'venue-3',
        startAt: at(8, 15),
        opponentName: 'ოლიმპი U-13',
        matchType: MatchType.tournament,
        homeAway: HomeAway.home,
        createdBy: 'coach-2',
      ),
      SportMatch(
        id: 'match-4',
        groupId: u10.id,
        clubId: 'club-1',
        venueId: 'venue-2',
        startAt: at(2, 16),
        opponentName: 'ვაკის ჭაბუკები',
        status: MatchStatus.cancelled,
        cancelReasonCode: CancelReasonCode.weather,
        cancelReason: 'ძლიერი წვიმის პროგნოზი — მოედანი სველი იქნება.',
        cancelledAt: now.subtract(const Duration(hours: 10)),
        cancelledBy: DemoIds.coach,
        createdBy: DemoIds.coach,
      ),
    ]) {
      db.matches[m.id] = m;
    }

    // Cancellation reason for the seeded cancelled U-10 training.
    for (final t
        in db.trainings.values.where((t) => t.groupId == u10.id && t.status == TrainingStatus.cancelled).toList()) {
      db.trainings[t.id] = t.copyWith(
        cancelReasonCode: CancelReasonCode.venueBusy,
        cancelReason: 'სტადიონი დაკავებულია ტურნირის გამო.',
        cancelledAt: now.subtract(const Duration(days: 1)),
        cancelledBy: DemoIds.coach,
      );
    }

    // ── RSVPs for the next U-10 training ────────────────────────────────
    final nextU10 =
        db.trainings.values.where((t) => t.groupId == u10.id && t.status.isActive && t.startAt.isAfter(now)).toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    if (nextU10.isNotEmpty) {
      final t = nextU10.first;
      for (final r in [
        Rsvp(
          trainingId: t.id,
          groupId: u10.id,
          childId: 'child-4',
          parentId: 'parent-2',
          response: RsvpResponse.yes,
          updatedAt: now.subtract(const Duration(hours: 5)),
        ),
        Rsvp(
          trainingId: t.id,
          groupId: u10.id,
          childId: 'child-5',
          parentId: 'parent-3',
          response: RsvpResponse.no,
          reason: 'სკოლის ექსკურსია',
          updatedAt: now.subtract(const Duration(hours: 3)),
        ),
        Rsvp(
          trainingId: t.id,
          groupId: u10.id,
          childId: 'child-7',
          parentId: 'parent-3',
          response: RsvpResponse.maybe,
          updatedAt: now.subtract(const Duration(hours: 3)),
        ),
      ]) {
        db.rsvps[r.id] = r;
      }
    }

    // ── Coach media posts (v1.1 §5) ─────────────────────────────────────
    for (final p in [
      MediaPost(
        id: 'post-1',
        coachId: DemoIds.coach,
        coachName: 'გიორგი კაპანაძე',
        groupIds: [u10.id],
        clubId: 'club-1',
        type: MediaType.photo,
        storagePath: 'demo://photo/football/post-1',
        caption: 'შაბათის ამხანაგური — ბრავო, ბიჭებო და გოგონებო!',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      MediaPost(
        id: 'post-2',
        coachId: DemoIds.coach,
        coachName: 'გიორგი კაპანაძე',
        groupIds: [u10.id, 'g-football-u12'],
        clubId: 'club-1',
        type: MediaType.video,
        storagePath: 'demo://video/football/post-2',
        caption: 'დრიბლინგის სავარჯიშო — სცადეთ სახლშიც 🙂',
        durationSec: 42,
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      MediaPost(
        id: 'post-3',
        coachId: 'coach-2',
        coachName: 'თამარ ლომიძე',
        groupIds: const ['g-basket-u13'],
        clubId: 'club-2',
        type: MediaType.photo,
        storagePath: 'demo://photo/basketball/post-3',
        caption: 'ტურნირისთვის მზადება',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]) {
      db.mediaPosts[p.id] = p;
    }

    // ── Chat: pinned announcement + system message (v1.1 §4) ────────────
    final u10Msgs = db.messages[u10.id] ??= [];
    u10Msgs.insert(
      0,
      ChatMessage(
        id: 'msg-ann-1',
        groupId: u10.id,
        senderId: DemoIds.coach,
        senderName: 'გიორგი კაპანაძე',
        senderRole: UserRole.coach,
        text: 'შეხსენება: ყოველ ვარჯიშზე — წყალი, ფორმა და ბუცები. სეზონის ტურნირი იწყება მომდევნო თვეს! 🏆',
        createdAt: now.subtract(const Duration(days: 5)),
        type: ChatMessageType.announcement,
        pinned: true,
      ),
    );
    u10Msgs.add(
      ChatMessage(
        id: 'msg-sys-1',
        groupId: u10.id,
        senderId: 'system',
        senderName: '',
        senderRole: UserRole.admin,
        text: 'თამაში (ვაკის ჭაბუკები) გაუქმდა. მიზეზი: ძლიერი წვიმის პროგნოზი — მოედანი სველი იქნება.',
        createdAt: now.subtract(const Duration(hours: 10)),
        type: ChatMessageType.system,
      ),
    );
    u10Msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    // Parent read up to yesterday → recent messages show as unread.
    db.chatReads[u10.id] = {
      DemoIds.parent: now.subtract(const Duration(days: 1, hours: 7)),
      DemoIds.coach: now.subtract(const Duration(hours: 1)),
      'parent-2': now.subtract(const Duration(hours: 4)),
    };
    db.chatReads['g-basket-u13'] = {DemoIds.parent: now.subtract(const Duration(days: 2))};
    db.chatReads['g-swim-juniors'] = {DemoIds.parent: now};

    // ── Pending invitation to parent-1 (duplicate-prevention demo) ──────
    // The coach created "მარიამ ბერიძე" by hand; the parent can link the
    // invite to her existing child Mariam instead of creating a duplicate.
    db.children['child-pending-1'] = Child(
      id: 'child-pending-1',
      firstName: 'მარიამ',
      lastName: 'ბერიძე',
      birthDate: db.children['child-2']!.birthDate,
      parentIds: const [],
      sportIds: const ['football'],
      status: ChildStatus.pendingParent,
      createdByCoachId: DemoIds.coach,
    );
    db.invites['inv-1'] = GroupInvite(
      id: 'inv-1',
      groupId: 'g-football-u12',
      clubId: 'club-1',
      sportId: 'football',
      groupName: db.groups['g-football-u12']!.name,
      childId: 'child-pending-1',
      childFirstName: 'მარიამ',
      childLastName: 'ბერიძე',
      phone: '+995555000101',
      parentId: DemoIds.parent,
      createdBy: DemoIds.coach,
      createdAt: now.subtract(const Duration(hours: 4)),
    );

    // ── Moderation queue ────────────────────────────────────────────────
    final reported = u10Msgs.firstWhere((m) => m.senderId == 'parent-2');
    db.reports['rep-1'] = ContentReport(
      id: 'rep-1',
      targetType: ReportTarget.chatMessage,
      targetPath: 'chats/${u10.id}/messages/${reported.id}',
      groupId: u10.id,
      clubId: 'club-1',
      reason: ReportReason.privacy,
      note: 'შეტყობინებაში ბავშვის სახელი ზედმეტად არის გამოყენებული.',
      reporterId: 'parent-3',
      createdAt: now.subtract(const Duration(hours: 9)),
      preview: reported.text,
    );
    db.reports['rep-2'] = ContentReport(
      id: 'rep-2',
      targetType: ReportTarget.mediaPost,
      targetPath: 'mediaPosts/post-3',
      groupId: 'g-basket-u13',
      clubId: 'club-2',
      reason: ReportReason.privacy,
      note: 'ფოტოზე ჩემი შვილია, რომელსაც თანხმობა არ აქვს.',
      reporterId: 'parent-4',
      createdAt: now.subtract(const Duration(hours: 20)),
      preview: 'ტურნირისთვის მზადება',
    );

    // ── Audit trail ─────────────────────────────────────────────────────
    db.audit.addAll([
      AuditEntry(
        id: 'audit-1',
        action: 'coach.approve',
        actorId: DemoIds.platformAdmin,
        actorName: 'მარიამ წერეთელი',
        targetType: 'user',
        targetId: DemoIds.coach,
        clubId: 'club-1',
        at: now.subtract(const Duration(days: 190)),
      ),
      AuditEntry(
        id: 'audit-2',
        action: 'coach.reject',
        actorId: DemoIds.platformAdmin,
        actorName: 'მარიამ წერეთელი',
        targetType: 'user',
        targetId: 'coach-7',
        clubId: 'club-2',
        details: const {'reason': 'კვალიფიკაციის დოკუმენტი ვერ დადასტურდა'},
        at: now.subtract(const Duration(days: 19)),
      ),
      AuditEntry(
        id: 'audit-3',
        action: 'sport.upsert',
        actorId: DemoIds.platformAdmin,
        actorName: 'მარიამ წერეთელი',
        targetType: 'sport',
        targetId: 'mma',
        details: const {'name': 'MMA'},
        at: now.subtract(const Duration(days: 10)),
      ),
      AuditEntry(
        id: 'audit-4',
        action: 'role.set',
        actorId: DemoIds.platformAdmin,
        actorName: 'მარიამ წერეთელი',
        targetType: 'user',
        targetId: DemoIds.clubAdmin,
        details: const {'role': 'club', 'clubs': 'club-1'},
        at: now.subtract(const Duration(days: 60)),
      ),
    ]);

    // ── Inbox for the v1.2 categories ───────────────────────────────────
    db.notifications.addAll([
      AppNotification(
        id: db.newId('ntf'),
        userId: DemoIds.parent,
        type: NotificationType.groupInvite,
        title: '',
        body: '',
        createdAt: now.subtract(const Duration(hours: 4)),
        route: '/invites',
        args: {'group': db.groups['g-football-u12']!.name, 'child': 'მარიამ'},
        groupId: 'g-football-u12',
      ),
      AppNotification(
        id: db.newId('ntf'),
        userId: DemoIds.parent,
        type: NotificationType.matchChanged,
        title: '',
        body: '',
        createdAt: now.subtract(const Duration(hours: 10)),
        route: '/match/match-4',
        args: {
          'group': u10.name,
          'opponent': 'ვაკის ჭაბუკები',
          'kind': 'cancelled',
          'reason': 'ძლიერი წვიმის პროგნოზი',
        },
        groupId: u10.id,
        childId: 'child-1',
      ),
      AppNotification(
        id: db.newId('ntf'),
        userId: DemoIds.parent,
        type: NotificationType.feedbackAdded,
        title: '',
        body: '',
        createdAt: now.subtract(const Duration(days: 4)),
        route: '/children/child-1/progress',
        args: {'child': 'ლუკა'},
        childId: 'child-1',
        read: true,
      ),
      AppNotification(
        id: db.newId('ntf'),
        userId: DemoIds.parent,
        type: NotificationType.newMatch,
        title: '',
        body: '',
        createdAt: now.subtract(const Duration(days: 2)),
        route: '/match/match-1',
        args: {'group': u10.name, 'opponent': 'დინამოს აკადემია U-10'},
        groupId: u10.id,
        childId: 'child-1',
        read: true,
      ),
      AppNotification(
        id: db.newId('ntf'),
        userId: DemoIds.coach,
        type: NotificationType.chatMessage,
        title: '',
        body: '',
        createdAt: now.subtract(const Duration(hours: 3)),
        route: '/chat/${u10.id}',
        args: {'group': u10.name, 'sender': 'ზურაბ ნოზაძე'},
        groupId: u10.id,
      ),
    ]);
  }
}
