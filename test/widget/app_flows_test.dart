import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_parent_app/app/app.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/trainings/domain/training.dart';

import '../helpers.dart';

Future<DemoBackend> launch(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final (db, overrides) = await demoSetup(prefs: {'settings.onboardingSeen': true});
  await tester.pumpWidget(ProviderScope(overrides: overrides, retry: (_, _) => null, child: const SportParentApp()));
  await pumpFor(tester);
  return db;
}

/// Skeletons animate forever, so pump fixed frames instead of pumpAndSettle.
Future<void> pumpFor(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapAndPump(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) {
    await tester.scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await pumpFor(tester);
}

void main() {
  setUpAll(() => initializeDateFormatting());

  testWidgets('sign-in screen validates the phone number', (tester) async {
    await launch(tester);
    expect(find.text('შესვლა ტელეფონით'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '123');
    await tapAndPump(tester, find.text('კოდის მიღება'));
    expect(find.textContaining('შეიყვანეთ სწორი მობილურის ნომერი'), findsOneWidget);
  });

  testWidgets('parent demo: dashboard restores context, switching sport updates the training card', (tester) async {
    await launch(tester);
    await tapAndPump(tester, find.byKey(const Key('demo-login-${DemoIds.parent}')));

    expect(find.textContaining('დილა მშვიდობისა, ნინო'), findsOneWidget);
    expect(find.byKey(const Key('child-chip-child-1')), findsOneWidget);
    expect(find.byKey(const Key('next-training-card')), findsOneWidget);
    expect(find.byKey(const Key('certificate-tile')), findsOneWidget);
    expect(find.byKey(const Key('payment-tile')), findsOneWidget);

    // Select Luka → swimming: the card must show the swimming group.
    await tapAndPump(tester, find.byKey(const Key('child-chip-child-1')));
    await tapAndPump(tester, find.byKey(const Key('sport-tab-swimming')));
    expect(
      find.descendant(
        of: find.byKey(const Key('next-training-card')),
        matching: find.textContaining('ცისფერი ტალღის აუზი'),
      ),
      findsOneWidget,
    );

    // Child without a group → empty state with "find a club".
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 2000));
    await pumpFor(tester);
    await tapAndPump(tester, find.byKey(const Key('child-chip-child-3')));
    expect(find.textContaining('ჯერ არ არის ჯგუფში'), findsOneWidget);
  });

  testWidgets('parent demo: send a chat message', (tester) async {
    final db = await launch(tester);
    await tapAndPump(tester, find.byKey(const Key('demo-login-${DemoIds.parent}')));
    await tapAndPump(tester, find.text('ჩატი').last);
    await tapAndPump(tester, find.byKey(const Key('chat-tile-g-football-u10')));
    await tester.enterText(find.byKey(const Key('chat-input')), 'ტესტური შეტყობინება');
    await tapAndPump(tester, find.byKey(const Key('chat-send')));
    expect(find.text('ტესტური შეტყობინება'), findsOneWidget);
    expect(db.messages['g-football-u10']!.last.senderId, DemoIds.parent);
  });

  testWidgets('coach demo: home shows groups and roster; cancelling a training updates status', (tester) async {
    final db = await launch(tester);
    await tapAndPump(tester, find.byKey(const Key('demo-login-${DemoIds.coach}')));
    expect(find.byKey(const Key('group-chip-g-football-u10')), findsOneWidget);
    expect(find.byKey(const Key('new-training-fab')), findsOneWidget);

    // Membership request from the seed is visible and can be approved.
    expect(find.textContaining('ელენე'), findsWidgets);

    final upcoming =
        db.trainings.values
            .where(
              (t) =>
                  t.groupId == 'g-football-u10' && t.status == TrainingStatus.scheduled && t.startAt.isAfter(testNow),
            )
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final target = upcoming.first;
    final router = tester.element(find.byType(Scaffold).first);
    GoRouterHelper(router).push('/training/${target.id}');
    await pumpFor(tester);

    await tapAndPump(tester, find.byKey(const Key('cancel-training')));
    await tapAndPump(tester, find.widgetWithText(FilledButton, 'გაუქმება'));
    expect(db.trainings[target.id]!.status, TrainingStatus.cancelled);
    await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
    await pumpFor(tester);
    expect(find.text('ეს ვარჯიში გაუქმდა'), findsOneWidget);
  });

  testWidgets('coach demo: training form shows validation errors', (tester) async {
    await launch(tester);
    await tapAndPump(tester, find.byKey(const Key('demo-login-${DemoIds.coach}')));
    await tapAndPump(tester, find.byKey(const Key('new-training-fab')));
    expect(find.text('ახალი ვარჯიში'), findsWidgets);
    await tapAndPump(tester, find.byKey(const Key('save-training')));
    expect(find.text('აირჩიეთ ადგილი'), findsWidgets);
    expect(find.text('აირჩიეთ მინიმუმ ერთი თემა'), findsOneWidget);
  });

  testWidgets('pending coach is held on the review screen until approved', (tester) async {
    await launch(tester);
    await tapAndPump(tester, find.byKey(const Key('demo-login-${DemoIds.pendingCoach}')));
    expect(find.text('ანგარიში მოწმდება'), findsOneWidget);
    await tapAndPump(tester, find.text('დემო: დადასტურება ადმინისტრატორის სახელით'));
    expect(find.byKey(const Key('group-chip-g-tennis-teens')), findsOneWidget);
  });
}
