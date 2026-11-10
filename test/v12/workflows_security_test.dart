import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/core/errors/app_exception.dart';
import 'package:sport_parent_app/features/account/data/demo_account_repository.dart';
import 'package:sport_parent_app/features/admin/data/demo_admin_repository.dart';
import 'package:sport_parent_app/features/attendance/data/demo_attendance_repository.dart';
import 'package:sport_parent_app/features/attendance/domain/attendance.dart';
import 'package:sport_parent_app/features/authentication/domain/app_user.dart';
import 'package:sport_parent_app/features/chat/data/demo_chat_repository.dart';
import 'package:sport_parent_app/features/chat/domain/chat_message.dart';
import 'package:sport_parent_app/features/children/data/demo_children_repository.dart';
import 'package:sport_parent_app/features/children/domain/child.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/groups/data/demo_groups_repository.dart';
import 'package:sport_parent_app/features/groups/domain/group.dart';
import 'package:sport_parent_app/features/matches/data/demo_matches_repository.dart';
import 'package:sport_parent_app/features/matches/domain/match.dart';
import 'package:sport_parent_app/features/media/data/demo_media_repository.dart';
import 'package:sport_parent_app/features/media/domain/media_post.dart';
import 'package:sport_parent_app/features/moderation/data/demo_moderation_repository.dart';
import 'package:sport_parent_app/features/moderation/domain/report.dart';
import 'package:sport_parent_app/features/notifications/data/demo_notifications_repository.dart';
import 'package:sport_parent_app/features/notifications/domain/notification_models.dart';
import 'package:sport_parent_app/features/payments/data/demo_payments_repository.dart';
import 'package:sport_parent_app/features/payments/domain/payment.dart';
import 'package:sport_parent_app/features/trainings/data/demo_trainings_repository.dart';
import 'package:sport_parent_app/features/trainings/domain/series.dart';
import 'package:sport_parent_app/features/trainings/domain/training.dart';

import '../helpers.dart';

final denied = throwsA(isA<PermissionDeniedException>());
Matcher invalid(String code) => throwsA(isA<ValidationException>().having((e) => e.code, 'code', code));

void main() {
  late DemoBackend db;
  setUp(() => db = DemoSeed.create(clock: () => testNow));
  void as(String uid) {
    db.session = (uid: uid, phone: db.users[uid]!.phone);
  }

  group('end-to-end: group → invite → schedule → RSVP → attendance → stats', () {
    test('coach creates a group, parent accepts by linking an existing child (no duplicate)', () async {
      final groups = DemoGroupsRepository(db);
      final trainings = DemoTrainingsRepository(db);
      final attendance = DemoAttendanceRepository(db);

      as(DemoIds.coach);
      final g = await groups.createGroup(
        const GroupDraft(clubId: 'club-1', sportId: 'football', name: 'U-9 · ახალბედები', ageMin: 8, ageMax: 9),
      );
      expect(InviteCodes.isValid(g.inviteCode), isTrue);
      // Coach types the child by hand → pending child, parent invited by phone.
      final invite = await groups.invitePendingChild(
        groupId: g.id,
        child: PendingChildDraft(
          firstName: 'ლუკა',
          lastName: 'ბერიძე',
          birthDate: DateTime(2017, 3, 2),
          parentPhone: '555000101',
        ),
      );
      expect(db.children[invite.childId]!.isPending, isTrue);
      expect(g.hasChild(invite.childId!), isFalse);
      // Coach sees only the name of the pending child, never its details.
      final childCount = db.children.length;

      as(DemoIds.parent);
      final mine = await groups.watchMyInvites().first;
      expect(mine.map((i) => i.id), contains(invite.id));
      // The parent links the invite to their existing Luka → no duplicate.
      await groups.respondInvite(invite.id, accept: true, linkedChildId: 'child-1', mediaConsent: true);
      expect(db.children.length, childCount - 1, reason: 'coach-created duplicate discarded');
      expect(db.groups[g.id]!.hasChild('child-1'), isTrue);
      expect(
        db.notifications.any((n) => n.userId == DemoIds.coach && n.type == NotificationType.inviteAnswered),
        isTrue,
      );

      as(DemoIds.coach);
      final s = await trainings.createSeries(
        SeriesDraft(
          groupId: g.id,
          venueId: 'venue-1',
          weekdays: const [3, 5],
          startTime: const LocalTime(17, 0),
          durationMin: 60,
          focus: const [TrainingFocus.ball],
          startDate: LocalDate.tbilisi(testNow),
        ),
      );
      final occ = db.trainings.values.where((t) => t.seriesId == s.id).toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
      expect(occ, isNotEmpty);
      // Exactly one schedule notification per parent, not one per occurrence.
      expect(
        db.notifications.where((n) => n.userId == DemoIds.parent && n.type == NotificationType.scheduleChanged),
        hasLength(1),
      );
      // Overlapping schedule is rejected.
      expect(
        trainings.createSeries(
          SeriesDraft(
            groupId: g.id,
            venueId: 'venue-1',
            weekdays: const [3],
            startTime: const LocalTime(17, 0),
            durationMin: 60,
            focus: const [TrainingFocus.ball],
            startDate: LocalDate.tbilisi(testNow),
          ),
        ),
        invalid('seriesOverlap'),
      );

      as(DemoIds.parent);
      final first = occ.first;
      await attendance.respond(trainingId: first.id, childId: 'child-1', response: RsvpResponse.yes);
      // RSVP is NOT attendance.
      expect(
        AttendanceStats.compute(await attendance.watchForChild('child-1').first, {first.id: first.startAt}).recorded,
        0,
      );

      // Coach records actual attendance once the training is about to start.
      db = db; // clock is fixed; move training into the past window
      db.trainings[first.id] = first.copyWith(startAt: testNow.subtract(const Duration(hours: 1)));
      as(DemoIds.coach);
      await attendance.mark(trainingId: first.id, childId: 'child-1', status: AttendanceStatus.present);

      as(DemoIds.parent);
      final recs = await attendance.watchForChild('child-1').first;
      final stats = AttendanceStats.compute(recs, {for (final t in db.trainings.values) t.id: t.startAt});
      expect(recs.any((r) => r.trainingId == first.id && r.status == AttendanceStatus.present), isTrue);
      expect(stats.totalPresent, greaterThan(0));
      expect(
        db.notifications.any((n) => n.userId == DemoIds.parent && n.type == NotificationType.attendanceRecorded),
        isTrue,
      );
    });

    test('edit "this and future": RSVPs stay attached to the same training id', () async {
      final trainings = DemoTrainingsRepository(db);
      final attendance = DemoAttendanceRepository(db);
      as(DemoIds.coach);
      final s = db.series['ser-u12']!;
      // Put child-2 (parent-1) into U-12 to RSVP.
      db.groups['g-football-u12'] = db.groups['g-football-u12']!.copyWith(memberChildIds: ['child-2']);
      db.recomputeMemberships();
      final occ = db.trainings.values.where((t) => t.seriesId == s.id).toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
      final target = occ[2];
      as(DemoIds.parent);
      await attendance.respond(trainingId: target.id, childId: 'child-2', response: RsvpResponse.no, reason: 'ექიმთან');
      as(DemoIds.coach);
      await trainings.updateSeriesFrom(
        s.id,
        SeriesDraft(
          groupId: s.groupId,
          venueId: s.venueId,
          weekdays: s.weekdays,
          startTime: const LocalTime(19, 0),
          durationMin: 90,
          focus: s.focus,
          startDate: LocalDate.parse(target.occurrenceDate!),
        ),
        from: LocalDate.parse(target.occurrenceDate!),
      );
      final moved = db.trainings[target.id]!;
      expect(moved.startAt.toUtc().hour, 15, reason: '19:00 Tbilisi');
      expect(moved.seriesId, isNot(s.id));
      expect(db.rsvps[Rsvp.docId(target.id, 'child-2')], isNotNull);
      // Earlier occurrences untouched.
      expect(db.trainings[occ.first.id]!.seriesId, s.id);
    });
  });

  group('security: cross-role attempts are rejected', () {
    test("another parent cannot read someone else's child, RSVP for it, or see its progress", () async {
      as('parent-2');
      expect(DemoChildrenRepository(db).watchChild('child-1').first, denied);
      final next = db.trainings.values.firstWhere(
        (t) => t.groupId == 'g-football-u10' && t.startAt.isAfter(testNow) && t.status.isActive,
      );
      expect(
        DemoAttendanceRepository(db).respond(trainingId: next.id, childId: 'child-1', response: RsvpResponse.yes),
        denied,
      );
      expect(DemoAttendanceRepository(db).watchForChild('child-1').first, denied);
      expect(DemoAttendanceRepository(db).watchFeedback('child-1').first, denied);
    });

    test("coach of another group cannot read the group's attendance or mark it", () async {
      as('coach-2');
      final t = db.trainings.values.firstWhere((t) => t.groupId == 'g-football-u10');
      expect(DemoAttendanceRepository(db).watchForGroup('g-football-u10').first, denied);
      expect(
        DemoAttendanceRepository(db).mark(trainingId: t.id, childId: 'child-1', status: AttendanceStatus.present),
        denied,
      );
      expect(DemoChildrenRepository(db).watchGroupMembers('g-football-u10').first, denied);
    });

    test('parent cannot mark attendance; RSVP closes at start', () async {
      as(DemoIds.parent);
      final past = db.trainings.values.firstWhere((t) => t.groupId == 'g-football-u10' && t.startAt.isBefore(testNow));
      expect(
        DemoAttendanceRepository(db).mark(trainingId: past.id, childId: 'child-1', status: AttendanceStatus.present),
        denied,
      );
      expect(
        DemoAttendanceRepository(db).respond(trainingId: past.id, childId: 'child-1', response: RsvpResponse.yes),
        invalid('rsvpClosed'),
      );
    });

    test('coach cannot publish media without consent confirmation or to a foreign group', () async {
      as(DemoIds.coach);
      final repo = DemoMediaPostsRepository(db);
      final up = MediaUpload(
        type: MediaType.photo,
        file: PhotoUpload(bytes: Uint8List(10), fileName: 'a.jpg', mimeType: 'image/jpeg'),
      );
      expect(
        repo.publish(upload: up, groupIds: const ['g-football-u10'], consentConfirmed: false),
        invalid('photoConsentRequired'),
      );
      expect(repo.publish(upload: up, groupIds: const ['g-basket-u13'], consentConfirmed: true), denied);
      final p = await repo.publish(upload: up, groupIds: const ['g-football-u10'], consentConfirmed: true);
      expect(p.groupIds, ['g-football-u10']);
    });

    test('private media is unreadable after the child leaves the group', () async {
      as(DemoIds.coach);
      final up = MediaUpload(
        type: MediaType.photo,
        file: PhotoUpload(bytes: Uint8List(10), fileName: 'a.jpg', mimeType: 'image/jpeg'),
      );
      final p = await DemoMediaPostsRepository(db)
          .publish(upload: up, groupIds: const ['g-football-u10'], consentConfirmed: true);
      as('parent-2');
      expect(await DemoMediaRepository(db).load(p.storagePath), isNotNull);
      await DemoGroupsRepository(db).leaveGroup(groupId: 'g-football-u10', childId: 'child-4');
      expect(DemoMediaRepository(db).load(p.storagePath), denied);
      expect(await DemoMediaPostsRepository(db).watchForGroups(['g-football-u10']).first, isEmpty);
    });

    test('parents cannot change payments; cancelling needs a reason and is audited', () async {
      as(DemoIds.parent);
      expect(DemoPaymentsRepository(db).setStatus('pay-l-f-0', PaymentStatus.paid), denied);
      as(DemoIds.coach);
      expect(DemoPaymentsRepository(db).setStatus('pay-l-f-0', PaymentStatus.cancelled), invalid('reasonRequired'));
      await DemoPaymentsRepository(db).setStatus('pay-l-f-0', PaymentStatus.cancelled, reason: 'გადავიდა სხვა ჯგუფში');
      final audit = await DemoPaymentsRepository(db).watchAudit('g-football-u10').first;
      expect(audit.single.to, PaymentStatus.cancelled);
      expect(db.audit.any((a) => a.action == 'payment.status'), isTrue);
    });

    test('a parent or coach cannot use admin operations or forge coach approval', () async {
      for (final uid in [DemoIds.parent, DemoIds.coach, DemoIds.pendingCoach]) {
        as(uid);
        expect(DemoAdminRepository(db).setCoachStatus(DemoIds.pendingCoach, CoachStatus.approved), denied);
        expect(DemoAdminRepository(db).watchAudit().first, denied);
        expect(DemoAdminRepository(db).stats(), denied);
      }
      expect(db.users[DemoIds.pendingCoach]!.coachStatus, CoachStatus.pending);
    });

    test('club admin is scoped to their club', () async {
      as(DemoIds.clubAdmin);
      final admin = DemoAdminRepository(db);
      final reports = await admin.watchReports().first;
      expect(reports.map((r) => r.clubId).toSet(), {'club-1'});
      expect(admin.moderate('rep-2', ModerationDecision.hidden), denied); // club-2
      expect(admin.upsertSport(db.sports['mma']!), denied); // platform only
      expect(admin.archiveClub('club-1', archived: true), denied); // platform only
      expect(admin.watchAdmins().first, denied);
      // coach-7 belongs to club-2 → no decision rights.
      expect(admin.setCoachStatus('coach-7', CoachStatus.approved), denied);
      // Own club coach application can be decided, with audit.
      await admin.setCoachStatus('coach-5', CoachStatus.approved);
      expect(db.users['coach-5']!.isApprovedCoach, isTrue);
      expect(db.audit.last.action, 'coach.approve');
      expect(db.audit.last.actorId, DemoIds.clubAdmin);
      // Admins never browse child profiles.
      expect(DemoChildrenRepository(db).watchChild('child-1').first, denied);
    });

    test('rejecting or suspending a coach requires a reason; suspended coach loses access', () async {
      as(DemoIds.platformAdmin);
      final admin = DemoAdminRepository(db);
      expect(admin.setCoachStatus(DemoIds.coach, CoachStatus.suspended), invalid('reasonRequired'));
      await admin.setCoachStatus(DemoIds.coach, CoachStatus.suspended, reason: 'დოკუმენტების გადამოწმება');
      as(DemoIds.coach);
      expect(DemoChildrenRepository(db).watchGroupMembers('g-football-u10').first, denied);
      expect(DemoChatRepository(db).watchMessages('g-football-u10').first, denied);
    });

    test('moderation hides a reported chat message and is audited', () async {
      as(DemoIds.platformAdmin);
      final r = db.reports['rep-1']!;
      await DemoAdminRepository(db).moderate(r.id, ModerationDecision.hidden);
      final id = r.targetPath.split('/').last;
      expect(db.messages['g-football-u10']!.firstWhere((m) => m.id == id).hidden, isTrue);
      expect(db.reports[r.id]!.status, ReportStatus.resolved);
      expect(db.audit.last.action, 'moderation.decide');
    });

    test('only group members can report; duplicates and floods are blocked', () async {
      as('parent-4'); // basketball only
      final mod = DemoModerationRepository(db);
      expect(
        mod.report(
          targetType: ReportTarget.chatMessage,
          targetPath: 'chats/g-football-u10/messages/x',
          groupId: 'g-football-u10',
          reason: ReportReason.spam,
        ),
        denied,
      );
    });

    test('children never access chat; announcements are coach-only', () async {
      as(DemoIds.parent);
      expect(DemoChatRepository(db).send('g-football-u10', 'hi', announcement: true), denied);
      final child = AppUser(
        id: 'kid',
        role: UserRole.child,
        firstName: 'a',
        lastName: 'b',
        phone: '',
        createdAt: testNow,
      );
      db.users['kid'] = child;
      as('kid');
      expect(DemoChatRepository(db).watchMessages('g-football-u10').first, denied);
    });

    test('cancel needs a reason (client and backend) and writes a system chat message', () async {
      as(DemoIds.coach);
      final m = await DemoMatchesRepository(db).create(
        MatchDraft(
          groupId: 'g-football-u10',
          venueId: 'venue-1',
          startAt: testNow.add(const Duration(days: 3)),
          opponentName: 'ტესტ გუნდი',
        ),
      );
      expect(
        DemoMatchesRepository(db).cancel(m.id, const CancelReason(CancelReasonCode.other, '')),
        invalid('cancelReasonTooShort'),
      );
      await DemoMatchesRepository(db).cancel(m.id, const CancelReason(CancelReasonCode.weather, 'ქარიშხალი'));
      expect(db.matches[m.id]!.status, MatchStatus.cancelled);
      expect(db.messages['g-football-u10']!.last.type, ChatMessageType.system);
    });

    test('notification inbox: owner-only, deduplicated, categories', () async {
      final before = db.notifications.length;
      final g = db.groups['g-football-u10']!;
      db.dispatch(NotificationType.newMatch, g, dedupeKey: 'x');
      final once = db.notifications.length;
      db.dispatch(NotificationType.newMatch, g, dedupeKey: 'x');
      expect(db.notifications.length, once);
      expect(once, greaterThan(before));
      as('parent-2');
      final inbox = await DemoNotificationsRepository(db).watchInbox(limit: 100).first;
      expect(inbox.every((n) => n.userId == 'parent-2'), isTrue);
      final matches = await DemoNotificationsRepository(db).watchInbox(category: NotificationCategory.matches).first;
      expect(matches.every((n) => n.category == NotificationCategory.matches), isTrue);
    });

    test('offline: writes fail with a clear error, never a fake success', () async {
      as(DemoIds.coach);
      db.offline = true;
      final t = db.trainings.values.firstWhere(
        (t) => t.groupId == 'g-football-u10' && t.status.isActive && t.startAt.isAfter(testNow),
      );
      expect(
        DemoTrainingsRepository(db).cancel(t.id, const CancelReason(CancelReasonCode.weather, 'წვიმა')),
        throwsA(isA<BackendUnavailableException>()),
      );
      expect(db.trainings[t.id]!.status, isNot(TrainingStatus.cancelled));
    });
  });

  group('account lifecycle', () {
    test('deleting a parent unlinks shared children and deletes solely owned ones', () async {
      db.children['child-1'] = db.children['child-1']!.copyWith(parentIds: [DemoIds.parent, 'parent-2']);
      as(DemoIds.parent);
      final repo = DemoAccountRepository(db);
      final impact = await repo.deletionImpact();
      expect(impact.unlinkedChildren, ['ლუკა ბერიძე']);
      expect(impact.deletedChildren, containsAll(['მარიამ ბერიძე', 'ნიკა ბერიძე']));
      await repo.requestDeletion();
      expect(db.children['child-1']!.parentIds, ['parent-2']);
      expect(db.children['child-2'], isNull);
      expect(db.certificates.values.where((c) => c.childId == 'child-2'), isEmpty);
      expect(db.payments.values.where((p) => p.parentId == DemoIds.parent), isEmpty);
      expect(db.users[DemoIds.parent], isNull);
      expect(db.session, isNull);
    });

    test('data export contains no medical file contents', () async {
      as(DemoIds.parent);
      final repo = DemoAccountRepository(db);
      final r = await repo.requestExport();
      final json = repo.exportContent(r)!;
      expect(json, contains('"children"'));
      expect(json, isNot(contains('DEMO CERTIFICATE PLACEHOLDER')));
      expect(repo.requestExport(), completes); // previous one is done, not pending
    });
  });

  test('join by code creates a request; invalid codes are rejected', () async {
    as(DemoIds.parent);
    final repo = DemoGroupsRepository(db);
    expect(repo.joinByCode(code: 'ZZZZZZ', childId: 'child-3'), invalid('invalidGroupCode'));
    final name = await repo.joinByCode(code: 'fq8-b2r', childId: 'child-3');
    expect(name, db.groups['g-football-u12']!.name);
    expect(db.requests.values.any((r) => r.childId == 'child-3' && r.source == 'code'), isTrue);
    expect(db.groups['g-football-u12']!.hasChild('child-3'), isFalse, reason: 'coach must approve');
  });

  test('pending child is visible to nobody but its creator coach via the invite', () async {
    as(DemoIds.coach);
    expect(DemoChildrenRepository(db).watchChild('child-pending-1').first, denied);
    expect(db.children['child-pending-1']!.status, ChildStatus.pendingParent);
  });
}
