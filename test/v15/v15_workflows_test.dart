import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/core/errors/app_exception.dart';
import 'package:sport_parent_app/features/child_threads/data/demo_child_threads_repository.dart';
import 'package:sport_parent_app/features/child_threads/domain/child_thread.dart';
import 'package:sport_parent_app/features/children/presentation/student_profile_screen.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed_v14.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed_v15.dart';
import 'package:sport_parent_app/features/groups/domain/group.dart';
import 'package:sport_parent_app/features/matches/data/demo_matches_repository.dart';
import 'package:sport_parent_app/features/matches/domain/match.dart';
import 'package:sport_parent_app/features/notifications/domain/notification_models.dart';
import 'package:sport_parent_app/features/payments/data/demo_payment_proofs_repository.dart';
import 'package:sport_parent_app/features/payments/domain/payment.dart';
import 'package:sport_parent_app/features/payments/domain/payment_proof.dart';
import 'package:sport_parent_app/features/trainings/domain/training.dart';

final denied = throwsA(isA<PermissionDeniedException>());
Matcher invalid(String code) => throwsA(isA<ValidationException>().having((e) => e.code, 'code', code));

void main() {
  var now = DateTime(2026, 11, 16, 12);
  late DemoBackend db;
  const u10 = 'g-football-u10';
  const g2 = DemoSeedV14.secondGuardian;
  setUp(() {
    now = DateTime(2026, 11, 16, 12);
    db = DemoSeed.create(clock: () => now);
  });
  void as(String uid) => db.session = (uid: uid, phone: db.users[uid]!.phone);

  group('student profile scope', () {
    test('parents see their own children with all their groups', () {
      final s = profileScope(db.users[DemoIds.parent]!, db.children['child-1']!, db.groups.values);
      expect(s.isParent, isTrue);
      expect(s.groups.map((g) => g.id), containsAll([u10]));
      final other = profileScope(db.users['parent-2']!, db.children['child-1']!, db.groups.values);
      expect(other.isParent || other.isCoach, isFalse, reason: 'another parent');
    });
    test('coaches see only their own active groups containing the child', () {
      final s = profileScope(db.users[DemoIds.coach]!, db.children['child-1']!, db.groups.values);
      expect(s.isCoach, isTrue);
      expect(s.groups.every((g) => g.hasCoach(DemoIds.coach)), isTrue);
      final unrelated = profileScope(db.users['coach-2']!, db.children['child-1']!, db.groups.values);
      expect(unrelated.isCoach, isFalse, reason: 'coach-2 does not coach Luka');
      final pending = profileScope(db.users[DemoIds.pendingCoach]!, db.children['child-1']!, db.groups.values);
      expect(pending.isCoach, isFalse);
      db.groups[u10] = db.groups[u10]!.copyWith(status: GroupStatus.archived);
      final archived = profileScope(db.users[DemoIds.coach]!, db.children['child-1']!, db.groups.values);
      expect(archived.groups.map((g) => g.id), isNot(contains(u10)));
    });
  });

  group('child-context conversation', () {
    late DemoChildThreadsRepository threads;
    setUp(() => threads = DemoChildThreadsRepository(db));

    test('guardians and the child coach exchange messages; the other side is notified once', () async {
      as(DemoIds.parent);
      await threads.send('child-1', DemoIds.coach, 'Will Luka play on Saturday?');
      final id = ChildThread.idOf('child-1', DemoIds.coach);
      final msg = db.childThreadMessages[id]!.last;
      bool notified(String uid) => db.notifications.any(
        (n) => n.userId == uid && n.type == NotificationType.childMessage && n.dedupeKey == 'thread:$id:${msg.id}',
      );
      expect(notified(DemoIds.coach), isTrue);
      expect(notified(g2), isTrue, reason: 'the other guardian of the SAME child');
      expect(notified(DemoIds.parent), isFalse, reason: 'not the sender');
      expect(notified('parent-2'), isFalse, reason: 'never other parents');
      expect(NotificationType.childMessage.category, NotificationCategory.chat);
      as(g2);
      expect((await threads.watchMessages('child-1', DemoIds.coach).first).last.text, contains('Saturday'));
      as(DemoIds.coach);
      await threads.send('child-1', DemoIds.coach, 'Yes, if his knee is fine.');
      expect((await threads.watchMyThreads().first).map((t) => t.childId), contains('child-1'));
    });

    test('other parents, unrelated coaches and non-coaches of the child are refused', () async {
      as('parent-2');
      await expectLater(threads.watchMessages('child-1', DemoIds.coach).first, denied);
      await expectLater(threads.send('child-1', DemoIds.coach, 'hi'), denied);
      expect(await threads.watchMyThreads().first, isEmpty);
      as('coach-2');
      await expectLater(threads.watchMessages('child-1', DemoIds.coach).first, denied);
      await expectLater(threads.send('child-1', 'coach-2', 'hi'), denied, reason: 'coach-2 does not coach Luka');
      as(DemoIds.parent);
      await expectLater(threads.send('child-1', 'coach-2', 'hi'), denied, reason: 'parents cannot pick any coach');
      await expectLater(threads.send('child-1', DemoIds.coach, '   '), invalid('emptyMessage'));
    });

    test('a coach removed from the child loses the conversation', () async {
      for (final g in db.groups.values.toList()) {
        if (g.hasChild('child-1') && g.hasCoach(DemoIds.coach)) {
          db.groups[g.id] = g.copyWith(memberChildIds: g.memberChildIds.where((c) => c != 'child-1').toList());
        }
      }
      as(DemoIds.coach);
      await expectLater(threads.watchMessages('child-1', DemoIds.coach).first, denied);
      as(DemoIds.parent);
      await expectLater(threads.send('child-1', DemoIds.coach, 'hi'), denied);
    });
  });

  group('payment receipt delivery', () {
    late DemoPaymentProofsRepository proofs;
    setUp(() => proofs = DemoPaymentProofsRepository(db));
    PhotoUpload pdf() =>
        PhotoUpload(bytes: utf8.encode('%PDF-1.4 demo receipt'), fileName: 'qvitari.pdf', mimeType: 'application/pdf');

    test('submit → the explicit reviewer gets one inbox entry that opens the proof; never paid by itself', () async {
      as(DemoIds.parent);
      final p = await proofs.submit(PaymentProofDraft(paymentId: 'pay-l-f-0', paidOn: now, receipt: pdf()));
      expect(db.payments['pay-l-f-0']!.status, PaymentStatus.pending);
      final inbox = db.notifications.where(
        (n) => n.type == NotificationType.paymentProofSubmitted && n.route == '/payments/proofs/${p.id}',
      );
      final to = inbox.map((n) => n.userId).toList();
      expect(to.toSet(), {DemoIds.coach, DemoIds.clubAdmin}, reason: 'explicit U-10 reviewer + the club admin');
      expect(to.length, to.toSet().length, reason: 'once each');
      expect(to, isNot(contains('coach-2')));
      expect(inbox.every((n) => n.args['proofId'] == p.id), isTrue);
      await expectLater(
        proofs.submit(PaymentProofDraft(paymentId: 'pay-l-f-0', paidOn: now, receipt: pdf())),
        throwsA(isA<AppException>()),
      );
      expect(
        db.notifications
            .where((n) => n.type == NotificationType.paymentProofSubmitted && n.route == '/payments/proofs/${p.id}')
            .length,
        2,
        reason: 'a refused second submission notifies nobody',
      );

      as(DemoIds.coach);
      expect(await proofs.watchProof(p.id).first, isNotNull);
      final ticket = await proofs.receiptDownload(p.id);
      expect(ticket.fileName, 'receipt_${p.id}.pdf');
      expect(ticket.bytes, isNotEmpty);
      expect(db.audit.where((a) => a.action == 'receipt.download' && a.targetId == p.id).length, 1);
      expect(db.paymentEvents.any((e) => e.proofId == p.id && e.action == VerificationAction.downloaded), isTrue);
      await proofs.review(p.id, approve: true);
      expect(db.payments['pay-l-f-0']!.status, PaymentStatus.paid);
      await expectLater(proofs.review(p.id, approve: true), throwsA(isA<AppException>()), reason: 'no double approval');
      final decision = db.notifications
          .where((n) => n.userId == DemoIds.parent && n.type == NotificationType.paymentProofApproved)
          .single;
      expect(decision.route, '/payments/pay-l-f-0/proof');
    });

    test('other parents and non-reviewer coaches cannot see or download the receipt', () async {
      as('parent-2');
      final p = db.paymentProofs['proof-1']!;
      expect(p.parentId, 'parent-2');
      as(DemoIds.parent);
      await expectLater(proofs.receiptDownload(p.id), denied);
      await expectLater(proofs.watchProof(p.id).first, denied);
      as('coach-2');
      await expectLater(proofs.receiptDownload(p.id), denied);
    });
  });

  group('match results', () {
    late DemoMatchesRepository matches;
    setUp(() => matches = DemoMatchesRepository(db));
    const m = DemoSeedV15.pendingResultMatch;

    test('coach enters the score: outcome derived, parents notified once, played', () async {
      as(DemoIds.coach);
      await matches.recordResult(m, our: 2, their: 2, summary: '  Good fight ');
      final r = db.matches[m]!.result!;
      expect(r.outcome, MatchOutcome.draw);
      expect(r.summary, 'Good fight');
      expect(db.matches[m]!.status, MatchStatus.played);
      final notified = db.notifications.where(
        (n) => n.type == NotificationType.matchResult && n.dedupeKey == 'match:$m:result',
      );
      expect(notified.map((n) => n.userId), containsAll([DemoIds.parent, g2, 'parent-2']));
      expect(notified.map((n) => n.userId), isNot(contains(DemoIds.coach)));
      expect(MatchOutcome.of(3, 1), MatchOutcome.win);
      expect(MatchOutcome.of(0, 4), MatchOutcome.loss);
    });

    test('correction: new version, history and audit; no second notification; no-op when unchanged', () async {
      as(DemoIds.coach);
      await matches.recordResult(m, our: 1, their: 0);
      final count = db.notifications.where((n) => n.type == NotificationType.matchResult).length;
      now = now.add(const Duration(minutes: 10));
      await matches.recordResult(m, our: 2, their: 0);
      expect(db.matches[m]!.result!.version, 2);
      expect(db.matches[m]!.result!.corrected, isTrue);
      final history = await matches.resultHistory(m);
      expect(history.first.from, (1, 0));
      expect(history.first.to, (2, 0));
      expect(db.audit.where((a) => a.action == 'match.resultCorrected' && a.targetId == m).length, 1);
      expect(db.notifications.where((n) => n.type == NotificationType.matchResult).length, count);
      await matches.recordResult(m, our: 2, their: 0);
      expect(db.matches[m]!.result!.version, 2);
    });

    test('unauthorized and invalid entries are refused', () async {
      as(DemoIds.parent);
      await expectLater(matches.recordResult(m, our: 1, their: 0), denied);
      as('coach-2');
      await expectLater(matches.recordResult(m, our: 1, their: 0), denied);
      as(DemoIds.coach);
      await expectLater(matches.recordResult(m, our: -1, their: 0), invalid('resultScore'));
      await expectLater(matches.recordResult(m, our: 1000, their: 0), invalid('resultScore'));
      await expectLater(matches.recordResult('match-1', our: 1, their: 0), invalid('resultNotStarted'));
      await expectLater(
        matches.recordResult(
          m,
          our: 1,
          their: 0,
          completedAt: db.matches[m]!.startAt.subtract(const Duration(hours: 1)),
        ),
        invalid('resultCompletedAt'),
      );
      await matches.cancel('match-1', const CancelReason(CancelReasonCode.weather, 'Heavy rain'));
      now = db.matches['match-1']!.startAt.add(const Duration(hours: 1));
      await expectLater(matches.recordResult('match-1', our: 1, their: 0), invalid('resultCancelled'));
      expect(db.matches[m]!.result, isNull);
    });

    test('parents read the result through the regular match stream', () async {
      as(DemoIds.parent);
      final r = (await matches.watchMatch(DemoSeedV15.resultMatch).first)!.result!;
      expect((r.ourScore, r.opponentScore, r.outcome), (3, 1, MatchOutcome.win));
    });
  });
}
