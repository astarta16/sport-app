import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_parent_app/features/child_threads/domain/child_thread.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed_v15.dart';
import 'package:sport_parent_app/features/matches/domain/match.dart';
import 'package:sport_parent_app/features/notifications/domain/notification_models.dart';
import 'package:sport_parent_app/features/payments/domain/payment.dart';

import '../responsive/responsive_screens_test.dart' show boot, signInAs, visit, pumpFrames, expectNoLayoutErrors;

void main() {
  setUpAll(() => initializeDateFormatting());
  const phone = Size(390, 844);

  setUp(() {
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (_) async => 'dev.fluttercommunity.plus/share/unavailable',
    );
    m.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => Directory.systemTemp.path,
    );
  });

  Future<void> tab(WidgetTester tester, String label) async {
    final f = find.descendant(of: find.byKey(const Key('profile-tabs')), matching: find.text(label));
    await tester.ensureVisible(f);
    await pumpFrames(tester, 2);
    await tester.tap(f);
    await pumpFrames(tester);
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final f = find.byKey(Key(key));
    await tester.ensureVisible(f.first);
    await pumpFrames(tester, 2);
    await tester.tap(f.first);
    await pumpFrames(tester);
  }

  testWidgets('flow 1 — parent opens the child profile, sees trainings and messages the coach', (tester) async {
    final db = await boot(tester, phone);
    await signInAs(tester, db, DemoIds.parent);
    await visit(tester, 'home', ['/parent/home']);
    await tap(tester, 'child-chip-child-1');
    await tap(tester, 'open-student-profile');
    expect(find.byKey(const Key('profile-overview')), findsOneWidget);
    expect(find.byKey(const Key('profile-contact-coach')), findsOneWidget);
    // Every tab renders.
    for (final label in ['ვარჯიშები', 'გეგმები', 'მედია', 'მატჩები', 'მიმოხილვა']) {
      await tab(tester, label);
      expectNoLayoutErrors();
    }
    expect(find.byKey(const Key('profile-overview')), findsOneWidget);
    await tap(tester, 'profile-contact-coach');
    if (find.byKey(const Key('choose-coach-${DemoIds.coach}')).evaluate().isNotEmpty) {
      await tap(tester, 'choose-coach-${DemoIds.coach}');
    }
    expect(find.byKey(const Key('thread-child-banner')), findsOneWidget);
    expect(find.textContaining('ლუკა'), findsWidgets, reason: 'the conversation shows which child it concerns');
    await tester.enterText(find.byKey(const Key('thread-input')), 'შაბათს მოვალთ 10:00-ზე');
    await tap(tester, 'thread-send');
    final msgs = db.childThreadMessages[ChildThread.idOf('child-1', DemoIds.coach)]!;
    expect(msgs.last.text, 'შაბათს მოვალთ 10:00-ზე');
    expect(db.notifications.any((n) => n.userId == DemoIds.coach && n.type == NotificationType.childMessage), isTrue);
    expectNoLayoutErrors();

    // Another parent cannot open Luka's profile or conversation.
    await signInAs(tester, db, 'parent-2');
    await visit(tester, 'other', ['/student/child-1']);
    expect(find.byKey(const Key('profile-overview')), findsNothing);
    await visit(tester, 'other thread', ['/student/child-1/coach/${DemoIds.coach}']);
    expect(find.byKey(const Key('thread-msg-tmsg-seed-1')), findsNothing);
  });

  testWidgets('flow 2 — parent submits a receipt; coach opens the notification, downloads and approves', (
    tester,
  ) async {
    final db = await boot(tester, phone);
    await signInAs(tester, db, DemoIds.parent);
    await visit(tester, 'proof', ['/payments/pay-l-f-0/proof']);
    await tap(tester, 'proof-demo-receipt');
    await tester.enterText(find.byKey(const Key('proof-reference')), 'TBC-905');
    await tap(tester, 'proof-submit');
    await pumpFrames(tester, 20);
    final proof = db.paymentProofs.values.firstWhere((p) => p.paymentId == 'pay-l-f-0');
    expect(db.payments['pay-l-f-0']!.status, PaymentStatus.pending);

    await signInAs(tester, db, DemoIds.coach);
    final n = db.notifications.lastWhere(
      (n) => n.userId == DemoIds.coach && n.type == NotificationType.paymentProofSubmitted,
    );
    await visit(tester, 'inbox', ['/notifications']);
    await tap(tester, 'ntf-${n.id}');
    expect(find.byKey(const Key('proof-detail')), findsOneWidget, reason: 'the notification opens the proof');
    await tester.runAsync(() async {
      await tester.tap(find.byKey(Key('download-receipt-${proof.id}')));
      for (var i = 0; i < 40; i++) {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await pumpFrames(tester, 3);
    expect(find.textContaining('receipt_${proof.id}'), findsWidgets);
    await tap(tester, 'approve-${proof.id}');
    if (find.byKey(const Key('confirm-ok')).evaluate().isNotEmpty) await tap(tester, 'confirm-ok');
    expect(db.payments['pay-l-f-0']!.status, PaymentStatus.paid);
    expect(find.byKey(Key('approve-${proof.id}')), findsNothing, reason: 'decided proofs cannot be approved twice');
    expectNoLayoutErrors();

    await signInAs(tester, db, DemoIds.parent);
    await visit(tester, 'parent proof', ['/payments/pay-l-f-0/proof']);
    expectNoLayoutErrors();
  });

  testWidgets('flow 3 — coach enters a score; parent sees it in the profile and the calendar', (tester) async {
    final db = await boot(tester, phone);
    const m = DemoSeedV15.pendingResultMatch;
    await signInAs(tester, db, DemoIds.coach);
    await visit(tester, 'match', ['/match/$m']);
    await tap(tester, 'match-result-enter');
    await tester.enterText(find.byKey(const Key('result-our')), '4');
    await tester.enterText(find.byKey(const Key('result-their')), '2');
    await tester.enterText(find.byKey(const Key('result-summary')), 'ძლიერი მეორე ტაიმი');
    await tap(tester, 'result-save');
    expect(db.matches[m]!.result!.outcome, MatchOutcome.win);
    expect(find.byKey(const Key('match-result-$m')), findsOneWidget);
    expect(find.text('4 — 2'), findsOneWidget);
    // Correction.
    await tap(tester, 'match-result-enter');
    await tester.enterText(find.byKey(const Key('result-our')), '3');
    await tap(tester, 'result-save');
    expect(db.matches[m]!.result!.version, 2);
    expect(find.byKey(const Key('match-result-history')), findsOneWidget);
    expectNoLayoutErrors();

    await signInAs(tester, db, DemoIds.parent);
    await visit(tester, 'profile', ['/student/child-1']);
    await tab(tester, 'მატჩები');
    expect(find.byKey(const Key('result-tile-$m')), findsOneWidget);
    expect(find.byKey(const Key('result-tile-${DemoSeedV15.resultMatch}')), findsOneWidget);
    await visit(tester, 'home', ['/parent/home']);
    await tap(tester, 'child-chip-child-1'); // the calendar follows the selected child
    await visit(tester, 'calendar', ['/parent/calendar']);
    await tester.scrollUntilVisible(
      find.byKey(const Key('result-tile-$m')),
      200,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first,
    );
    expect(find.byKey(const Key('result-tile-$m')), findsOneWidget);
    await visit(tester, 'match parent', ['/match/$m']);
    expect(find.byKey(const Key('match-result-enter')), findsNothing, reason: 'parents cannot enter results');
    expect(find.byKey(const Key('match-result-history')), findsNothing, reason: 'history is coach-only');
    expectNoLayoutErrors();
  });
}
