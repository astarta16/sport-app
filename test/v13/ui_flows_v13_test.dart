import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/notifications/domain/notification_models.dart';
import 'package:sport_parent_app/features/payments/domain/payment.dart';
import 'package:sport_parent_app/features/payments/domain/payment_proof.dart';
import 'package:sport_parent_app/features/training_plans/domain/training_plan.dart';

import '../responsive/responsive_screens_test.dart' show boot, signInAs, visit, pumpFrames, expectNoLayoutErrors;

Future<void> tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.scrollUntilVisible(f, 150, scrollable: vertical);
  await tester.pump();
  await tester.tap(f.first);
  await pumpFrames(tester);
}

final vertical = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;

void main() {
  setUpAll(() => initializeDateFormatting());
  const phone = Size(390, 844);

  // Share sheet is a platform plugin; answer it in tests.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (_) async => 'dev.fluttercommunity.plus/share/unavailable',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => Directory.systemTemp.path,
    );
  });

  testWidgets('example 1 — parent submits a payment proof; the U-10 reviewer approves it', (tester) async {
    final db = await boot(tester, phone);
    await signInAs(tester, db, DemoIds.parent);
    await visit(tester, 'proof', ['/payments/pay-l-f-0/proof']);
    await tapKey(tester, 'proof-demo-receipt');
    await tester.enterText(find.byKey(const Key('proof-reference')), 'TBC-777');
    await tapKey(tester, 'proof-submit');
    await pumpFrames(tester, 20);
    final proof = db.paymentProofs.values.firstWhere((p) => p.paymentId == 'pay-l-f-0');
    expect(db.payments['pay-l-f-0']!.status, PaymentStatus.pending);
    expect(displayStateOf(db.payments['pay-l-f-0']!), PaymentDisplayState.proofSubmitted);
    expectNoLayoutErrors();

    await signInAs(tester, db, DemoIds.coach);
    await visit(tester, 'review', ['/payments/review']);
    expect(find.byKey(Key('review-${proof.id}')), findsOneWidget);
    await tapKey(tester, 'approve-${proof.id}');
    if (find.byKey(const Key('confirm-ok')).evaluate().isNotEmpty) await tapKey(tester, 'confirm-ok');
    expect(db.payments['pay-l-f-0']!.status, PaymentStatus.paid);
    expect(db.payments['pay-l-f-0']!.verifiedBy, DemoIds.coach);
    expectNoLayoutErrors();
  });

  testWidgets('example 2 — coach rejects with a reason; parent sees it and can resubmit', (tester) async {
    final db = await boot(tester, phone);
    await signInAs(tester, db, DemoIds.coach);
    await visit(tester, 'review', ['/payments/review']);
    await tapKey(tester, 'reject-proof-1');
    await tester.enterText(find.byKey(const Key('reject-reason')), 'ქვითარი ბუნდოვანია');
    await tapKey(tester, 'reject-ok');
    expect(db.paymentProofs['proof-1']!.status, ProofStatus.rejected);
    expect(
      db.notifications.any((n) => n.userId == 'parent-2' && n.type == NotificationType.paymentProofRejected),
      isTrue,
    );
    await signInAs(tester, db, 'parent-2');
    await visit(tester, 'payments', ['/payments']);
    expect(find.byKey(const Key('rejected-reason-pay-d-f-0')), findsOneWidget);
    expect(find.byKey(const Key('submit-proof-pay-d-f-0')), findsOneWidget);
    expectNoLayoutErrors();
  });

  testWidgets('example 3 — coach publishes a plan; parent marks homework progress; coach sees it', (tester) async {
    final db = await boot(tester, phone);
    await signInAs(tester, db, DemoIds.coach);
    await visit(tester, 'draft', ['/plans/plan-draft']);
    await tapKey(tester, 'plan-publish-now');
    if (find.byKey(const Key('confirm-ok')).evaluate().isNotEmpty) await tapKey(tester, 'confirm-ok');
    expect(db.trainingPlans['plan-draft']!.status, PlanStatus.published);

    await signInAs(tester, db, DemoIds.parent);
    await visit(tester, 'home', ['/parent/home']);
    await tester.tap(find.byKey(const Key('child-chip-child-1')));
    await pumpFrames(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('dashboard-plans')), 200, scrollable: vertical);
    expect(find.byKey(const Key('dashboard-plans')), findsOneWidget, reason: 'homework on the dashboard');
    await visit(tester, 'homework', ['/plans/plan-homework']);
    final plan = db.trainingPlans['plan-homework']!;
    final ex = plan.exercises.first;
    await tapKey(tester, 'progress-${ex.id}-child-1-completed');
    expect(db.exerciseProgress[ExerciseProgress.docId(plan.id, ex.id, 'child-1')]?.status, ProgressStatus.completed);
    expect(db.planViews.containsKey('${plan.id}_${DemoIds.parent}'), isTrue);
    expectNoLayoutErrors();

    await signInAs(tester, db, DemoIds.coach);
    await visit(tester, 'coach plan', ['/plans/plan-homework']);
    expect(find.byKey(const Key('plan-coach-panel')), findsOneWidget);
    expectNoLayoutErrors();
  });

  testWidgets('example 4 — coach roster: search, filter, export CSV with a warning', (tester) async {
    final db = await boot(tester, phone);
    await signInAs(tester, db, DemoIds.coach);
    await visit(tester, 'roster', ['/students?groupId=g-football-u10']);
    expect(find.byKey(const Key('student-child-1')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('roster-search')), 'zzz-nobody');
    await pumpFrames(tester);
    expect(find.byKey(const Key('student-child-1')), findsNothing);
    await tester.enterText(find.byKey(const Key('roster-search')), '');
    await pumpFrames(tester);
    await tester.tap(find.byKey(const Key('roster-export')));
    await pumpFrames(tester);
    await tapKey(tester, 'export-roster');
    await tester.tap(find.text('CSV').last);
    await pumpFrames(tester);
    await tapKey(tester, 'export-go');
    // Privacy warning first.
    expect(find.byKey(const Key('confirm-ok')), findsOneWidget);
    // The share sheet writes a temp file (real I/O) — run outside fake time.
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('confirm-ok')));
      for (var i = 0; i < 20; i++) {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await pumpFrames(tester);
    expectNoLayoutErrors();
    expect(find.textContaining('roster_g-football-u10_'), findsWidgets, reason: 'export-ready snack with filename');
  });

  testWidgets('language switches immediately and persists independent of device locale', (tester) async {
    final db = await boot(tester, phone);
    await signInAs(tester, db, DemoIds.parent);
    await visit(tester, 'settings', ['/settings']);
    await tapKey(tester, 'lang-ru');
    expect(Localizations.localeOf(tester.element(find.byType(Scaffold).first)).languageCode, 'ru');
    expect(db.users[DemoIds.parent]!.locale, 'ru');
    await visit(tester, 'ru screens', ['/payments', '/plans', '/plans/plan-summer', '/certificates/child-1']);
    expectNoLayoutErrors();
    await visit(tester, 'settings', ['/settings']);
    await tapKey(tester, 'lang-en');
    expect(Localizations.localeOf(tester.element(find.byType(Scaffold).first)).languageCode, 'en');
    await tapKey(tester, 'lang-ka');
    expect(db.users[DemoIds.parent]!.locale, 'ka');
  });
}
