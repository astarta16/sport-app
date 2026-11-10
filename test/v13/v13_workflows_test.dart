import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/core/errors/app_exception.dart';
import 'package:sport_parent_app/features/admin/data/demo_admin_repository.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/groups/data/demo_groups_repository.dart';
import 'package:sport_parent_app/features/medical_certificates/data/demo_certificates_repository.dart';
import 'package:sport_parent_app/features/medical_certificates/domain/medical_certificate.dart';
import 'package:sport_parent_app/features/notifications/domain/notification_models.dart';
import 'package:sport_parent_app/features/payments/data/demo_payment_proofs_repository.dart';
import 'package:sport_parent_app/features/payments/data/demo_payments_repository.dart';
import 'package:sport_parent_app/features/payments/domain/payment.dart';
import 'package:sport_parent_app/features/payments/domain/payment_proof.dart';
import 'package:sport_parent_app/features/training_plans/data/demo_training_plans_repository.dart';
import 'package:sport_parent_app/features/training_plans/domain/training_plan.dart';
import 'package:sport_parent_app/features/trainings/domain/series.dart';
import 'package:sport_parent_app/features/trainings/domain/training.dart';

import '../helpers.dart';

final denied = throwsA(isA<PermissionDeniedException>());
Matcher invalid(String code) => throwsA(isA<ValidationException>().having((e) => e.code, 'code', code));

PhotoUpload pdf([int size = 64]) =>
    PhotoUpload(bytes: utf8.encode('%PDF-1.4 ${'x' * size}'), fileName: 'r.pdf', mimeType: 'application/pdf');

void main() {
  late DemoBackend db;
  setUp(() => db = DemoSeed.create(clock: () => testNow));
  void as(String uid) => db.session = (uid: uid, phone: db.users[uid]!.phone);

  group('payment proofs', () {
    test('parent submits → awaiting verification, never paid; duplicate blocked', () async {
      final proofs = DemoPaymentProofsRepository(db);
      as(DemoIds.parent);
      final progress = <double>[];
      final p = await proofs.submit(
        PaymentProofDraft(paymentId: 'pay-l-f-0', paidOn: testNow, receipt: pdf(), reference: 'TBC-1'),
        onProgress: progress.add,
      );
      expect(progress.last, 1.0);
      final pay = db.payments['pay-l-f-0']!;
      expect(pay.status, PaymentStatus.pending, reason: 'a parent claim never marks the payment paid');
      expect(displayStateOf(pay), PaymentDisplayState.proofSubmitted);
      expect(p.status, ProofStatus.submitted);
      expect(
        () => proofs.submit(PaymentProofDraft(paymentId: 'pay-l-f-0', paidOn: testNow, receipt: pdf())),
        throwsA(isA<AppException>()),
        reason: 'only one open proof per payment',
      );
      expect(db.audit.any((a) => a.action == 'payment.proofSubmitted'), isTrue);
      expect(
        db.notifications.any((n) => n.userId == DemoIds.coach && n.type == NotificationType.paymentProofSubmitted),
        isTrue,
        reason: 'the explicit U-10 reviewer is notified',
      );
    });

    test('validation: file type, size, future date, missing receipt', () async {
      final proofs = DemoPaymentProofsRepository(db);
      as(DemoIds.parent);
      expect(
        () => proofs.submit(
          PaymentProofDraft(
            paymentId: 'pay-l-f-0',
            paidOn: testNow,
            receipt: const PhotoUpload(bytes: [1, 2], fileName: 'a.gif', mimeType: 'image/gif'),
          ),
        ),
        invalid('fileType'),
      );
      expect(
        () => proofs.submit(PaymentProofDraft(paymentId: 'pay-l-f-0', paidOn: testNow, receipt: pdf(11 * 1024 * 1024))),
        invalid('fileTooLarge'),
      );
      expect(
        () => proofs.submit(
          PaymentProofDraft(paymentId: 'pay-l-f-0', paidOn: testNow.add(const Duration(days: 5)), receipt: pdf()),
        ),
        invalid('dateFuture'),
      );
      expect(
        PaymentProofDraft.validate(
          PaymentProofDraft(
            paymentId: 'x',
            paidOn: testNow,
            receipt: const PhotoUpload(bytes: [], fileName: '', mimeType: ''),
          ),
          now: testNow,
        ),
        contains('receiptRequired'),
      );
    });

    test('a parent cannot submit for someone else\'s payment', () async {
      as(DemoIds.parent);
      expect(
        () =>
            DemoPaymentProofsRepository(db)
                .submit(PaymentProofDraft(paymentId: 'pay-g-f-0', paidOn: testNow, receipt: pdf())),
        denied,
      );
    });

    test('reviewer authorization: explicit manager yes, other coaches no, club admin yes', () async {
      final proofs = DemoPaymentProofsRepository(db);
      // proof-1 is on U-10 (manager: coach-1). coach-2 coaches basketball only.
      as('coach-2');
      expect(() => proofs.review('proof-1', approve: true), denied);
      // Removing coach-1 as manager revokes the right even though they coach the group.
      as(DemoIds.platformAdmin);
      await DemoAdminRepository(db).setPaymentManagers('g-football-u10', []);
      as(DemoIds.coach);
      expect(() => proofs.review('proof-1', approve: true), denied);
      expect(() => DemoPaymentsRepository(db).setStatus('pay-d-f-0', PaymentStatus.paid), throwsA(anything));
      // A parent can never approve.
      as('parent-2');
      expect(() => proofs.review('proof-1', approve: true), denied);
    });

    test('approve marks paid with verifier; a second decision fails', () async {
      final proofs = DemoPaymentProofsRepository(db);
      as(DemoIds.coach);
      await proofs.startReview('proof-1');
      expect(displayStateOf(db.payments['pay-d-f-0']!), PaymentDisplayState.underReview);
      final receipt = await proofs.openReceipt('proof-1');
      expect(receipt, isNotNull);
      expect(db.audit.any((a) => a.action == 'receipt.view'), isTrue);
      await proofs.review('proof-1', approve: true);
      final pay = db.payments['pay-d-f-0']!;
      expect(pay.status, PaymentStatus.paid);
      expect(pay.verifiedBy, DemoIds.coach);
      expect(displayStateOf(pay), PaymentDisplayState.paid);
      expect(() => proofs.review('proof-1', approve: false, reason: 'ორჯერ'), throwsA(isA<AppException>()));
      expect(
        db.notifications.any((n) => n.userId == 'parent-2' && n.type == NotificationType.paymentProofApproved),
        isTrue,
      );
      final events = await proofs.watchEvents('pay-d-f-0').first;
      expect(events.map((e) => e.action), containsAll([VerificationAction.reviewStarted, VerificationAction.approved]));
    });

    test('reject needs a reason; parent resubmits; old proof superseded', () async {
      final proofs = DemoPaymentProofsRepository(db);
      as(DemoIds.coach);
      expect(() => proofs.review('proof-1', approve: false, reason: 'no'), throwsA(isA<ValidationException>()));
      await proofs.review('proof-1', approve: false, reason: 'ქვითარი არ იკითხება');
      final pay = db.payments['pay-d-f-0']!;
      expect(pay.status, PaymentStatus.pending);
      expect(displayStateOf(pay), PaymentDisplayState.rejected);
      expect(pay.verification.rejectionReason, 'ქვითარი არ იკითხება');

      as('parent-2');
      final again = await proofs.submit(PaymentProofDraft(paymentId: 'pay-d-f-0', paidOn: testNow, receipt: pdf()));
      expect(db.paymentProofs['proof-1']!.status, ProofStatus.superseded);
      expect(again.status, ProofStatus.submitted);
      expect(displayStateOf(db.payments['pay-d-f-0']!), PaymentDisplayState.proofSubmitted);
      expect(db.audit.any((a) => a.action == 'payment.proofResubmitted'), isTrue);
    });

    test('review queue is scoped to the reviewer', () async {
      final proofs = DemoPaymentProofsRepository(db);
      as(DemoIds.coach);
      expect((await proofs.watchReviewQueue().first).map((p) => p.id), contains('proof-1'));
      as('coach-2');
      expect((await proofs.watchReviewQueue().first).map((p) => p.id), isNot(contains('proof-1')));
    });
  });

  group('medical certificates', () {
    test('current certificate: sport-specific vs general, replaced excluded', () {
      MedicalCertificate c(String id, int days, {String? sport, String? replacedBy}) => MedicalCertificate(
        id: id,
        childId: 'k',
        uploadedBy: 'p',
        storagePath: 'x',
        issuedAt: testNow,
        validUntil: testNow.add(Duration(days: days)),
        consentAt: testNow,
        fileName: 'a.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 1,
        createdAt: testNow,
        sportId: sport,
        replacedBy: replacedBy,
      );
      final certs = [c('gen', 100), c('swim', 10, sport: 'swimming'), c('old', 400, replacedBy: 'gen')];
      expect(CertificatePolicy.current(certs)!.id, 'gen');
      expect(CertificatePolicy.current(certs, sportId: 'football')!.id, 'gen');
      expect(
        CertificatePolicy.current([c('gen', 10), c('swim', 10, sport: 'swimming')], sportId: 'swimming')!.id,
        'swim',
      );
      expect(CertificatePolicy.current([c('old', 400, replacedBy: 'gen')]), isNull);
    });

    test('replace marks the old one; download is audited; admins and former coaches denied', () async {
      final repo = DemoCertificatesRepository(db);
      final old = db.certificates.values.firstWhere((c) => c.childId == 'child-1' && c.sportId == null);
      as(DemoIds.parent);
      final fresh = await repo.upload(
        CertificateUpload(
          childId: 'child-1',
          bytes: pdf().bytes,
          fileName: 'new.pdf',
          mimeType: 'application/pdf',
          issuedAt: testNow,
          validUntil: testNow.add(const Duration(days: 365)),
          consentGiven: true,
          replacesCertId: old.id,
        ),
      );
      expect(db.certificates[old.id]!.replacedBy, fresh.id);
      expect(CertificatePolicy.current(db.certificates.values.where((c) => c.childId == 'child-1'))!.id, fresh.id);

      as(DemoIds.coach);
      await repo.requestAccess(fresh.id, purpose: CertificateAccessPurpose.download);
      expect(db.audit.any((a) => a.action == 'certificate.download'), isTrue);
      final log = await (() {
        as(DemoIds.parent);
        return repo.watchAccessLog('child-1').first;
      })();
      expect(log.any((e) => e.userId == DemoIds.coach), isTrue);

      for (final admin in [DemoIds.platformAdmin, DemoIds.clubAdmin]) {
        as(admin);
        expect(() => repo.requestAccess(fresh.id), denied, reason: '$admin must never open medical files');
      }
      as('coach-2');
      expect(() => repo.requestAccess(fresh.id), denied, reason: 'coach-2 does not coach Luka');

      // Luka leaves U-10 and U-12 → coach-1 loses access.
      as(DemoIds.parent);
      final groups = DemoGroupsRepository(db);
      for (final g in db.groups.values.where((g) => g.hasChild('child-1') && g.coachIds.contains(DemoIds.coach))) {
        await groups.leaveGroup(groupId: g.id, childId: 'child-1');
      }
      as(DemoIds.coach);
      expect(() => repo.requestAccess(fresh.id), denied);
    });

    test('admin compliance shows counts only and is scoped to the club admin', () async {
      final admin = DemoAdminRepository(db);
      as(DemoIds.clubAdmin);
      final rows = await admin.compliance();
      final clubs = db.users[DemoIds.clubAdmin]!.adminClubIds;
      expect(rows, isNotEmpty);
      expect(rows.every((r) => clubs.contains(r.clubId)), isTrue);
      as(DemoIds.platformAdmin);
      expect((await admin.compliance()).length, greaterThanOrEqualTo(rows.length));
      as(DemoIds.parent);
      expect(admin.compliance, denied);
    });
  });

  group('training plans', () {
    test('safe links only', () {
      expect(PlanDraft.isSafeLink('https://www.uefa.com/x'), isTrue);
      for (final bad in [
        'http://a.ge',
        'javascript:alert(1)',
        'data:text/html,x',
        'https://',
        'ftp://a',
        'https://a b',
      ]) {
        expect(PlanDraft.isSafeLink(bad), isFalse, reason: bad);
      }
    });

    test('draft invisible to parents; publish notifies once; leaving the group revokes access', () async {
      final plans = DemoTrainingPlansRepository(db);
      as(DemoIds.coach);
      final p = await plans.save(
        PlanDraft(
          title: 'სახლის დავალება',
          type: PlanType.homework,
          groupIds: const ['g-football-u10'],
          startDate: LocalDate.tbilisi(testNow),
          exercises: const [Exercise(id: 'e1', name: 'ჟონგლიორობა', reps: 20)],
        ),
      );
      expect(p.status, PlanStatus.draft);
      as(DemoIds.parent);
      expect((await plans.watchPlans().first).map((x) => x.id), isNot(contains(p.id)));
      expect(
        () => plans.setProgress(planId: p.id, exerciseId: 'e1', childId: 'child-1', status: ProgressStatus.completed),
        throwsA(isA<AppException>()),
      );
      expect(
        () => plans.save(
          PlanDraft(
            title: 'x',
            type: PlanType.weekly,
            groupIds: const ['g-football-u10'],
            startDate: LocalDate.tbilisi(testNow),
            exercises: const [Exercise(id: 'a', name: 'a')],
          ),
        ),
        denied,
      );

      as(DemoIds.coach);
      await plans.setStatus(p.id, PlanStatus.published);
      await plans.setStatus(p.id, PlanStatus.draft);
      await plans.setStatus(p.id, PlanStatus.published);
      final sent = db.notifications.where(
        (n) =>
            n.userId == DemoIds.parent &&
            n.type == NotificationType.trainingPlanPublished &&
            n.route == '/plans/${p.id}',
      );
      expect(sent.length, 1, reason: 'dedupe plan:{id}:published');

      as(DemoIds.parent);
      expect((await plans.watchPlans().first).map((x) => x.id), contains(p.id));
      await plans.recordView(p.id);
      await plans.setProgress(planId: p.id, exerciseId: 'e1', childId: 'child-1', status: ProgressStatus.completed);
      as(DemoIds.coach);
      final stats = await plans.watchStats(p.id).first;
      expect(stats.viewers, greaterThanOrEqualTo(1));
      expect(stats.completed, greaterThanOrEqualTo(1));

      as(DemoIds.parent);
      await DemoGroupsRepository(db).leaveGroup(groupId: 'g-football-u10', childId: 'child-1');
      expect((await plans.watchPlans().first).map((x) => x.id), isNot(contains(p.id)));
    });

    test('validation codes', () {
      final today = LocalDate.tbilisi(testNow);
      expect(
        PlanDraft.validate(
          PlanDraft(title: '', type: PlanType.weekly, groupIds: const [], startDate: today),
          publishing: true,
        ),
        containsAll(['planTitle', 'planGroups', 'planExercises']),
      );
      expect(
        PlanDraft.validate(
          PlanDraft(
            title: 'a',
            type: PlanType.weekly,
            groupIds: const ['g'],
            startDate: today,
            endDate: LocalDate(today.year - 1, 1, 1),
            exercises: const [
              Exercise(
                id: 'e',
                name: 'x',
                media: [ExerciseMedia(id: 'm', kind: MediaKind.link, url: 'javascript:alert(1)')],
              ),
            ],
          ),
        ),
        containsAll(['planDates', 'link']),
      );
    });
  });
}
