import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/core/errors/app_exception.dart';
import 'package:sport_parent_app/features/authentication/data/demo_auth_repository.dart';
import 'package:sport_parent_app/features/authentication/domain/app_user.dart';
import 'package:sport_parent_app/features/chat/data/demo_chat_repository.dart';
import 'package:sport_parent_app/features/children/data/demo_children_repository.dart';
import 'package:sport_parent_app/features/children/domain/child.dart';
import 'package:sport_parent_app/features/clubs/data/demo_clubs_repository.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/groups/data/demo_groups_repository.dart';
import 'package:sport_parent_app/features/medical_certificates/data/demo_certificates_repository.dart';
import 'package:sport_parent_app/features/medical_certificates/domain/medical_certificate.dart';
import 'package:sport_parent_app/features/notifications/domain/notification_models.dart';
import 'package:sport_parent_app/features/payments/data/demo_payments_repository.dart';
import 'package:sport_parent_app/features/payments/domain/payment.dart';
import 'package:sport_parent_app/features/payments/domain/payment_reminders.dart';
import 'package:sport_parent_app/features/trainings/data/demo_trainings_repository.dart';
import 'package:sport_parent_app/features/trainings/domain/training.dart';

void main() {
  final fixedNow = DateTime(2026, 11, 10, 10); // Tuesday
  late DemoBackend db;
  late DemoAuthRepository auth;

  setUp(() {
    db = DemoSeed.create(clock: () => fixedNow);
    auth = DemoAuthRepository(db);
  });

  Future<void> signIn(String uid) => auth.signInAsDemo(uid);

  group('auth & registration', () {
    test('OTP flow: wrong code rejected, demo code signs in existing parent', () async {
      final vid = await auth.sendCode('555 000 101');
      await expectLater(auth.verifyCode(vid, '000000'), throwsA(isA<AuthException>()));
      await auth.verifyCode(vid, DemoIds.otpCode);
      expect(auth.currentSession?.user?.id, DemoIds.parent);
    });

    test('new phone needs registration; coaches start pending; child role refused', () async {
      final vid = await auth.sendCode('599123456');
      await auth.verifyCode(vid, DemoIds.otpCode);
      expect(auth.currentSession!.needsRegistration, isTrue);
      await expectLater(
        auth.completeRegistration(
          const RegistrationData(
            role: UserRole.child,
            firstName: 'ნიკა',
            lastName: 'ბ',
            sportIds: ['tennis'],
            dataConsent: true,
          ),
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
      await expectLater(
        auth.completeRegistration(
          const RegistrationData(
            role: UserRole.parent,
            firstName: 'ნიკა',
            lastName: 'ბერიძე',
            sportIds: ['tennis'],
            dataConsent: false,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      final coach = await auth.completeRegistration(
        const RegistrationData(
          role: UserRole.coach,
          firstName: 'ლაშა',
          lastName: 'ხარაძე',
          sportIds: ['football'],
          clubIds: ['club-1'],
          dataConsent: true,
        ),
      );
      expect(coach.coachStatus, CoachStatus.pending);
      expect(coach.isApprovedCoach, isFalse);
    });
  });

  group('children', () {
    test('adding a child updates the parent\'s stream', () async {
      await signIn(DemoIds.parent);
      final repo = DemoChildrenRepository(db);
      final stream = repo.watchMyChildren();
      final first = await stream.first;
      await repo.addChild(
        ChildDraft(
          firstName: 'ელენე',
          lastName: 'ბერიძე',
          birthDate: DateTime(2018, 4, 4),
          sportIds: const ['swimming'],
        ),
      );
      final after = await repo.watchMyChildren().first;
      expect(after.length, first.length + 1);
      expect(after.any((c) => c.firstName == 'ელენე' && c.parentIds.single == DemoIds.parent), isTrue);
    });

    test('a parent cannot read another family\'s child', () async {
      await signIn(DemoIds.parent);
      expect(DemoChildrenRepository(db).watchChild('child-4').first, throwsA(isA<PermissionDeniedException>()));
    });

    test('coach cannot add children', () async {
      await signIn(DemoIds.coach);
      expect(
        DemoChildrenRepository(db)
            .addChild(ChildDraft(firstName: 'ა', lastName: 'ბბ', birthDate: DateTime(2018), sportIds: const ['x'])),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });

  group('trainings', () {
    TrainingDraft draft(String group) => TrainingDraft(
      groupId: group,
      venueId: 'venue-1',
      startAt: fixedNow.add(const Duration(days: 2)),
      durationMin: 90,
      focus: const [TrainingFocus.technique],
      description: 'ტესტი',
    );

    test('coach creates a training; parents of the group are notified', () async {
      await signIn(DemoIds.coach);
      final repo = DemoTrainingsRepository(db);
      final before = (await repo.watchForGroups(['g-football-u10']).first).length;
      final t = await repo.create(draft('g-football-u10'));
      expect((await repo.watchForGroups(['g-football-u10']).first).length, before + 1);
      final notified = db.notifications.where(
        (n) => n.type == NotificationType.newTraining && n.route == '/training/${t.id}',
      );
      expect(notified.map((n) => n.userId).toSet(), containsAll(['parent-1', 'parent-2', 'parent-3']));
      expect(notified.any((n) => n.userId.startsWith('coach')), isFalse);
    });

    test('parents and coaches of other groups cannot create trainings', () async {
      await signIn(DemoIds.parent);
      expect(DemoTrainingsRepository(db).create(draft('g-football-u10')), throwsA(isA<PermissionDeniedException>()));
      await signIn('coach-2');
      expect(DemoTrainingsRepository(db).create(draft('g-football-u10')), throwsA(isA<PermissionDeniedException>()));
    });

    test('pending coach cannot create trainings even in their own group', () async {
      await signIn(DemoIds.pendingCoach);
      expect(DemoTrainingsRepository(db).create(draft('g-tennis-teens')), throwsA(isA<PermissionDeniedException>()));
    });

    test('cancel and reschedule change status', () async {
      await signIn(DemoIds.coach);
      final repo = DemoTrainingsRepository(db);
      final t = await repo.create(draft('g-football-u10'));
      await repo.cancel(t.id);
      expect((await repo.watchTraining(t.id).first)!.status, TrainingStatus.cancelled);
      final t2 = await repo.create(draft('g-football-u10'));
      final newStart = t2.startAt.add(const Duration(days: 1));
      await repo.reschedule(t2.id, newStart);
      final moved = (await repo.watchTraining(t2.id).first)!;
      expect(moved.status, TrainingStatus.moved);
      expect(moved.previousStartAt, t2.startAt);
      expect(moved.startAt, newStart);
    });
  });

  group('chat', () {
    test('parent in group sends; other family and outsiders are denied', () async {
      await signIn(DemoIds.parent);
      final chat = DemoChatRepository(db);
      await chat.send('g-football-u10', 'გამარჯობა!');
      final msgs = await chat.watchMessages('g-football-u10').first;
      expect(msgs.last.text, 'გამარჯობა!');
      expect(msgs.last.senderId, DemoIds.parent);
      // parent-1 has no child in U-12.
      expect(chat.watchMessages('g-football-u12').first, throwsA(isA<PermissionDeniedException>()));
      await signIn('coach-2');
      expect(chat.send('g-football-u10', 'x'), throwsA(isA<PermissionDeniedException>()));
    });

    test('a child account can never access chat', () async {
      db.users['kid'] = AppUser(
        id: 'kid',
        role: UserRole.child,
        firstName: 'ნ',
        lastName: 'ბ',
        phone: '+995555999999',
        createdAt: fixedNow,
      );
      final g = db.groups['g-football-u10']!;
      db.groups[g.id] = g.copyWith(parentIds: [...g.parentIds, 'kid']);
      db.session = (uid: 'kid', phone: '+995555999999');
      final chat = DemoChatRepository(db);
      expect(chat.watchMessages('g-football-u10').first, throwsA(isA<PermissionDeniedException>()));
      expect(chat.send('g-football-u10', 'hi'), throwsA(isA<PermissionDeniedException>()));
    });
  });

  group('medical certificates', () {
    test('coach access is audited and revoked when the child leaves the group', () async {
      await signIn(DemoIds.coach);
      final certs = DemoCertificatesRepository(db);
      final grant = await certs.requestAccess('cert-1'); // Luka, U-10
      expect(grant.expiresAt.difference(fixedNow), const Duration(minutes: 5));
      expect(db.accessLog.last.action, 'open');
      expect(db.accessLog.last.userId, DemoIds.coach);

      await DemoGroupsRepository(db).removeMember('g-football-u10', 'child-1');
      expect(certs.requestAccess('cert-1'), throwsA(isA<PermissionDeniedException>()));
      await Future<void>.delayed(Duration.zero);
      expect(db.accessLog.last.action, 'denied');
    });

    test('other coaches and parents cannot read; parent uploads and deletes', () async {
      await signIn('coach-2');
      expect(DemoCertificatesRepository(db).requestAccess('cert-1'), throwsA(isA<PermissionDeniedException>()));

      await signIn(DemoIds.parent);
      final repo = DemoCertificatesRepository(db);
      final up = await repo.upload(
        CertificateUpload(
          childId: 'child-3',
          bytes: List.filled(64, 1),
          fileName: 'c.pdf',
          mimeType: 'application/pdf',
          issuedAt: DateTime(2026, 11, 1),
          validUntil: DateTime(2027, 11, 1),
          consentGiven: true,
        ),
      );
      expect(db.certificateFiles.containsKey('medical/child-3/${up.id}'), isTrue);
      await repo.delete(up.id);
      expect(db.certificateFiles.containsKey('medical/child-3/${up.id}'), isFalse);
      expect(db.certificates.containsKey(up.id), isFalse);
    });

    test('upload without consent or too large is rejected', () async {
      await signIn(DemoIds.parent);
      final repo = DemoCertificatesRepository(db);
      CertificateUpload u({bool consent = true, int size = 10}) => CertificateUpload(
        childId: 'child-1',
        bytes: List.filled(size, 0),
        fileName: 'a.pdf',
        mimeType: 'application/pdf',
        issuedAt: DateTime(2026, 1, 1),
        validUntil: DateTime(2027, 1, 1),
        consentGiven: consent,
      );
      expect(repo.upload(u(consent: false)), throwsA(isA<ValidationException>()));
      expect(repo.upload(u(size: CertificatePolicy.maxBytes + 1)), throwsA(isA<ValidationException>()));
    });
  });

  group('payments', () {
    test('coach marks paid → parent stream reflects it', () async {
      await signIn(DemoIds.coach);
      await DemoPaymentsRepository(db).setStatus('pay-l-f-0', PaymentStatus.paid);
      await signIn(DemoIds.parent);
      final mine = await DemoPaymentsRepository(db).watchMyPayments().first;
      expect(mine.firstWhere((p) => p.id == 'pay-l-f-0').status, PaymentStatus.paid);
      expect(mine.every((p) => p.parentId == DemoIds.parent), isTrue);
    });

    test('parent cannot change payment status', () async {
      await signIn(DemoIds.parent);
      expect(
        DemoPaymentsRepository(db).setStatus('pay-l-f-0', PaymentStatus.paid),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('reminder job is idempotent and combines same-day payments', () async {
      await signIn(DemoIds.coach);
      final sms = MockSmsProvider();
      final repo = DemoPaymentsRepository(db, smsProvider: sms);
      final first = await repo.runReminderJob(fixedNow);
      final second = await repo.runReminderJob(fixedNow);
      expect(first.sent, greaterThan(0));
      expect(second.sent, 0);
      expect(second.claimed, 0);
      // parent-1: football + basketball due in 5 days → one combined SMS.
      final toParent1 = sms.sent.where((s) => s.phone == '+995555000101').toList();
      expect(toParent1.where((s) => s.text.contains('ლუკა') && s.text.contains('მარიამ')), hasLength(1));
      expect(db.payments['pay-l-f-0']!.reminders.d5SentAt, isNotNull);
    });

    test('recurring generation is idempotent per month', () async {
      await signIn(DemoIds.coach);
      final repo = DemoPaymentsRepository(db);
      final n1 = await repo.generateRecurring('plan-football-u10', year: 2026, month: 12);
      final n2 = await repo.generateRecurring('plan-football-u10', year: 2026, month: 12);
      expect(n1, db.groups['g-football-u10']!.memberChildIds.length);
      expect(n2, 0);
    });
  });

  group('membership requests', () {
    test('parent requests; coach approves; child joins group and parent sees it', () async {
      await signIn(DemoIds.parent);
      final clubs = DemoClubsRepository(db);
      await clubs.requestMembership(childId: 'child-3', clubId: 'club-1', groupId: 'g-football-u12');
      expect(
        clubs.requestMembership(childId: 'child-3', clubId: 'club-1', groupId: 'g-football-u12'),
        throwsA(isA<ValidationException>()),
      );

      await signIn(DemoIds.coach);
      final incoming = await clubs.watchIncomingRequests().first;
      final req = incoming.firstWhere((r) => r.childId == 'child-3');
      expect(req.childName, 'ნიკა');
      await clubs.decideRequest(req.id, approve: true);
      expect(db.groups['g-football-u12']!.memberChildIds, contains('child-3'));
      expect(db.groups['g-football-u12']!.parentIds, contains(DemoIds.parent));
      expect(db.children['child-3']!.groupIds, contains('g-football-u12'));
    });
  });

  group('account deletion', () {
    test('removes solely-owned children and their certificate files', () async {
      await signIn(DemoIds.parent);
      await auth.deleteAccount();
      expect(db.users.containsKey(DemoIds.parent), isFalse);
      expect(db.children.values.any((c) => c.parentIds.contains(DemoIds.parent)), isFalse);
      expect(db.certificateFiles.keys.any((k) => k.contains('child-1') || k.contains('child-2')), isFalse);
      expect(db.session, isNull);
    });
  });
}
