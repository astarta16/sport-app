import 'dart:convert';
import 'dart:typed_data';

import '../../medical_certificates/domain/medical_certificate.dart';
import '../../notifications/domain/notification_models.dart';
import '../../payments/domain/payment.dart';
import '../../payments/domain/payment_proof.dart';
import '../../training_plans/domain/training_plan.dart';
import '../../trainings/domain/series.dart';
import 'demo_backend.dart';
import 'demo_seed.dart';

/// v1.3 demo data: payment reviewers, a submitted and a rejected payment
/// proof, training plans (seasonal + homework + draft) with exercises and
/// mock media, parent progress, sport-specific certificates. All fictional.
class DemoSeedV13 {
  DemoSeedV13._();

  static void seed(DemoBackend db) {
    final now = db.clock();
    final today = LocalDate.tbilisi(now);

    // ── Financial permissions: explicit, per group ──────────────────────
    // coach-1 verifies U-10 payments but NOT U-12 (shows the restriction).
    void managers(String groupId, List<String> ids) {
      final g = db.groups[groupId];
      if (g != null) db.groups[groupId] = g.copyWith(paymentManagerIds: ids);
    }

    managers('g-football-u10', [DemoIds.coach]);
    managers('g-basket-u13', ['coach-2']);

    // ── Sport-specific certificate: Luka's swimming certificate (pool
    // requires its own) expires soon; his general one stays valid.
    final today0 = DateTime(now.year, now.month, now.day);
    const certPath = 'medical/child-1/cert-1-swim';
    db.certificates['cert-1-swim'] = MedicalCertificate(
      id: 'cert-1-swim',
      childId: 'child-1',
      uploadedBy: DemoIds.parent,
      storagePath: certPath,
      issuedAt: today0.subtract(const Duration(days: 355)),
      validUntil: today0.add(const Duration(days: 10)),
      consentAt: today0.subtract(const Duration(days: 355)),
      fileName: 'cnoba_curva.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 96 * 1024,
      createdAt: today0.subtract(const Duration(days: 355)),
      sportId: 'swimming',
    );
    db.certificateFiles[certPath] = Uint8List.fromList(utf8.encode('DEMO CERTIFICATE PLACEHOLDER (swimming)'));

    // ── Payment proofs ──────────────────────────────────────────────────
    final pdf = Uint8List.fromList(utf8.encode('%PDF-1.4 DEMO RECEIPT (fictional)'));
    // parent-2 submitted proof for Dato's overdue fee → awaiting coach.
    final dato = db.payments['pay-d-f-0'];
    if (dato != null) {
      const id = 'proof-1';
      const path = 'receipts/parent-2/proof-1/qvitari.pdf';
      db.receiptFiles[path] = pdf;
      db.paymentProofs[id] = PaymentProof(
        id: id,
        paymentId: dato.id,
        groupId: dato.groupId,
        clubId: 'club-1',
        childId: dato.childId,
        parentId: 'parent-2',
        paidOn: now.subtract(const Duration(days: 1)),
        reference: 'TBC-48213',
        receiptPath: path,
        receiptMime: 'application/pdf',
        receiptSize: pdf.length,
        submittedAt: now.subtract(const Duration(hours: 5)),
      );
      db.payments[dato.id] = dato.copyWith(
        verification: PaymentVerification(state: VerificationState.proofSubmitted, proofId: id, updatedAt: now),
      );
      db.paymentEvents.add(
        PaymentVerificationEvent(
          id: 'pev-1',
          paymentId: dato.id,
          proofId: id,
          action: VerificationAction.submitted,
          actorId: 'parent-2',
          actorName: 'ეკა ჯავახიშვილი',
          at: now.subtract(const Duration(hours: 5)),
        ),
      );
      db.notifications.add(
        AppNotification(
          id: db.newId('ntf'),
          userId: DemoIds.coach,
          type: NotificationType.paymentProofSubmitted,
          title: '',
          body: '',
          createdAt: now.subtract(const Duration(hours: 5)),
          route: '/payments/review',
          args: {'child': 'დათო', 'amount': '80 ₾', 'group': 'U-10 · ახალგაზრდები'},
          groupId: 'g-football-u10',
        ),
      );
    }
    // parent-1: swimming fee proof was rejected → can resubmit.
    final swim = db.payments['pay-l-s-0'];
    if (swim != null) {
      const id = 'proof-2';
      const path = 'receipts/parent-1/proof-2/receipt.pdf';
      db.receiptFiles[path] = pdf;
      final p = PaymentProof(
        id: id,
        paymentId: swim.id,
        groupId: swim.groupId,
        clubId: 'club-3',
        childId: swim.childId,
        parentId: DemoIds.parent,
        paidOn: now.subtract(const Duration(days: 2)),
        receiptPath: path,
        receiptMime: 'application/pdf',
        receiptSize: pdf.length,
        submittedAt: now.subtract(const Duration(days: 2)),
      );
      db.paymentProofs[id] = p.decide(
        ProofStatus.rejected,
        by: 'coach-3',
        byName: 'დავით მაისურაძე',
        at: now.subtract(const Duration(days: 1)),
        reason: 'თანხა არ ემთხვევა — გადახდილია 100 ₾ 120-ის ნაცვლად.',
      );
      db.payments[swim.id] = swim.copyWith(
        verification: PaymentVerification(
          state: VerificationState.rejected,
          proofId: id,
          rejectionReason: 'თანხა არ ემთხვევა — გადახდილია 100 ₾ 120-ის ნაცვლად.',
          updatedAt: now,
        ),
      );
    }

    // ── Training plans ──────────────────────────────────────────────────
    final summer = TrainingPlan(
      id: 'plan-summer',
      title: 'საზაფხულო სავარჯიშო გეგმა',
      description: 'სამი სავარჯიშო კვირაში 3-ჯერ — ფორმის შენარჩუნება არდადეგებზე.',
      type: PlanType.seasonal,
      groupIds: const ['g-football-u10'],
      clubId: 'club-1',
      startDate: today.addDays(-10),
      endDate: today.addDays(60),
      status: PlanStatus.published,
      createdBy: DemoIds.coach,
      coachName: 'გიორგი კაპანაძე',
      createdAt: now.subtract(const Duration(days: 12)),
      publishedAt: now.subtract(const Duration(days: 10)),
      exercises: const [
        Exercise(
          id: 'ex-1',
          name: 'ბურთის ჟონგლიორობა',
          description: 'ბურთის კონტროლი ორივე ფეხით.',
          instructions: 'ბურთი არ უნდა დავარდეს. დაითვალეთ ზედიზედ შეხებები, ყოველ კვირა გააუმჯობესეთ რეკორდი.',
          durationMin: 10,
          sets: 3,
          reps: 20,
          restSec: 60,
          media: [
            ExerciseMedia(
              id: 'm-1',
              kind: MediaKind.video,
              path: 'demo://video/football/ex-1',
              name: 'ჟონგლიორობა.mp4',
            ),
            ExerciseMedia(
              id: 'm-2',
              kind: MediaKind.link,
              url: 'https://www.uefa.com/insideuefa/football-development/grassroots/',
              name: 'UEFA Grassroots',
            ),
          ],
        ),
        Exercise(
          id: 'ex-2',
          name: 'სირბილი კონუსებს შორის',
          instructions: '5 კონუსი 1 მეტრის დაშორებით. გაირბინეთ ზიგზაგით, უკან — ზურგით.',
          durationMin: 8,
          sets: 4,
          reps: 2,
          restSec: 45,
          media: [
            ExerciseMedia(id: 'm-3', kind: MediaKind.photo, path: 'demo://photo/football/ex-2', name: 'კონუსები.jpg'),
          ],
        ),
        Exercise(
          id: 'ex-3',
          name: 'გაჭიმვა',
          instructions: 'ვარჯიშის შემდეგ 5 წუთი: კუნთების გაჭიმვა, ყოველი პოზა 20 წამი.',
          durationMin: 5,
          media: [ExerciseMedia(id: 'm-4', kind: MediaKind.pdf, path: 'demo://pdf/stretching', name: 'გაჭიმვა.pdf')],
        ),
      ],
    );
    final homework = TrainingPlan(
      id: 'plan-homework',
      title: 'დავალება ხუთშაბათამდე',
      description: 'მარცხენა ფეხით პასი კედელთან.',
      type: PlanType.homework,
      groupIds: const ['g-football-u10'],
      clubId: 'club-1',
      startDate: today,
      endDate: today.addDays(2),
      status: PlanStatus.published,
      createdBy: DemoIds.coach,
      coachName: 'გიორგი კაპანაძე',
      createdAt: now.subtract(const Duration(hours: 20)),
      publishedAt: now.subtract(const Duration(hours: 20)),
      exercises: const [
        Exercise(
          id: 'ex-h1',
          name: 'პასი კედელთან',
          instructions: '50 პასი მარცხენა ფეხით, 50 — მარჯვენით.',
          durationMin: 10,
          reps: 50,
          sets: 2,
        ),
      ],
    );
    final draft = TrainingPlan(
      id: 'plan-draft',
      title: 'დეკემბრის გეგმა (მონახაზი)',
      type: PlanType.monthly,
      groupIds: const ['g-football-u12'],
      clubId: 'club-1',
      startDate: today.addDays(20),
      createdBy: DemoIds.coach,
      coachName: 'გიორგი კაპანაძე',
      createdAt: now.subtract(const Duration(hours: 2)),
      exercises: const [Exercise(id: 'ex-d1', name: 'კოორდინაციის კიბე', durationMin: 10)],
    );
    for (final p in [summer, homework, draft]) {
      db.trainingPlans[p.id] = p;
    }
    // Some parent activity (self-reported).
    void progress(String exId, String childId, String parentId, ProgressStatus s) {
      final p = ExerciseProgress(
        planId: 'plan-summer',
        exerciseId: exId,
        childId: childId,
        groupId: 'g-football-u10',
        parentId: parentId,
        status: s,
        updatedAt: now.subtract(const Duration(days: 1)),
        viewedAt: now.subtract(const Duration(days: 2)),
      );
      db.exerciseProgress[p.id] = p;
    }

    progress('ex-1', 'child-1', DemoIds.parent, ProgressStatus.completed);
    progress('ex-2', 'child-1', DemoIds.parent, ProgressStatus.inProgress);
    progress('ex-1', 'child-4', 'parent-2', ProgressStatus.completed);
    for (final pid in [DemoIds.parent, 'parent-2']) {
      db.planViews['plan-summer_$pid'] = PlanView(
        planId: 'plan-summer',
        parentId: pid,
        firstViewedAt: now.subtract(const Duration(days: 3)),
        lastViewedAt: now.subtract(const Duration(days: 1)),
      );
    }
    db.notifications.add(
      AppNotification(
        id: db.newId('ntf'),
        userId: DemoIds.parent,
        type: NotificationType.trainingPlanPublished,
        title: '',
        body: '',
        createdAt: now.subtract(const Duration(hours: 20)),
        route: '/plans/plan-homework',
        args: {'title': homework.title, 'group': 'U-10 · ახალგაზრდები'},
        groupId: 'g-football-u10',
        childId: 'child-1',
      ),
    );
    db.notifications.add(
      AppNotification(
        id: db.newId('ntf'),
        userId: DemoIds.parent,
        type: NotificationType.paymentProofRejected,
        title: '',
        body: '',
        createdAt: now.subtract(const Duration(days: 1)),
        route: '/payments',
        args: {'child': 'ლუკა', 'reason': 'თანხა არ ემთხვევა'},
        childId: 'child-1',
      ),
    );
    // Payment status untouched by any proof (authoritative = pending).
    assert(
      db.payments.values
          .where((p) => p.verification.state != VerificationState.none)
          .every((p) => p.status == PaymentStatus.pending),
    );
  }
}
