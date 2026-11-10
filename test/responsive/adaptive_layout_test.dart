import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_parent_app/core/layout/responsive.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/trainings/domain/training.dart';

import '../helpers.dart';
import 'responsive_screens_test.dart' show boot, collected, pumpFrames, routerOf, signInAs, expectNoLayoutErrors, visit;

void main() {
  setUpAll(() => initializeDateFormatting());
  setUp(collected.clear);

  group('WindowSize breakpoints (width-based)', () {
    test('classes', () {
      expect(WindowSize.forWidth(320), WindowSize.compact); // Slide Over
      expect(WindowSize.forWidth(390), WindowSize.compact); // iPhone
      expect(WindowSize.forWidth(599), WindowSize.compact);
      expect(WindowSize.forWidth(600), WindowSize.medium);
      expect(WindowSize.forWidth(744), WindowSize.medium); // iPad mini portrait
      expect(WindowSize.forWidth(1032), WindowSize.expanded); // iPad Pro 13 portrait
      expect(WindowSize.forWidth(1133), WindowSize.expanded); // iPad mini landscape
      expect(WindowSize.forWidth(1376), WindowSize.large); // iPad Pro 13 landscape
    });

    test('grid columns adapt to width', () {
      expect(ResponsiveGrid.columnsFor(390, minItemWidth: 300), 1);
      expect(ResponsiveGrid.columnsFor(744, minItemWidth: 340), 2);
      expect(ResponsiveGrid.columnsFor(1200, minItemWidth: 340, maxColumns: 3), 3);
    });
  });

  testWidgets('navigation: bottom bar on phone, rail on iPad, sidebar on wide iPad', (tester) async {
    final db = await boot(tester, const Size(390, 844));
    await signInAs(tester, db, DemoIds.parent);
    expect(find.byKey(const Key('bottom-nav')), findsOneWidget);
    expect(find.byKey(const Key('nav-rail')), findsNothing);

    tester.view.physicalSize = const Size(744, 1133) * 2;
    await pumpFrames(tester);
    expect(find.byKey(const Key('bottom-nav')), findsNothing);
    final rail = tester.widget<NavigationRail>(find.byKey(const Key('nav-rail')));
    expect(rail.extended, isFalse);

    tester.view.physicalSize = const Size(1376, 1032) * 2;
    await pumpFrames(tester);
    expect(tester.widget<NavigationRail>(find.byKey(const Key('nav-rail'))).extended, isTrue);

    // Tapping a rail destination switches tabs (GoRouter branches preserved).
    await tester.tap(find.text('კალენდარი').first);
    await pumpFrames(tester);
    expect(routerOf(tester).routerDelegate.currentConfiguration.uri.path, '/parent/calendar');
    expectNoLayoutErrors();
  });

  testWidgets('dynamic window resizing (Split View / Stage Manager) keeps state and never overflows', (tester) async {
    final db = await boot(tester, const Size(1376, 1032));
    await signInAs(tester, db, DemoIds.coach);
    for (final size in const [
      Size(678, 1032),
      Size(320, 1032),
      Size(507, 1032),
      Size(1032, 1376),
      Size(844, 390),
      Size(1376, 1032),
    ]) {
      tester.view.physicalSize = size * 2;
      await pumpFrames(tester, 4);
      expect(find.byKey(const Key('new-training-fab')), findsOneWidget, reason: 'coach home at $size');
    }
    expectNoLayoutErrors();
  });

  testWidgets('parent dashboard: side column with schedule + notifications only on tablet', (tester) async {
    final db = await boot(tester, const Size(390, 844));
    await signInAs(tester, db, DemoIds.parent);
    expect(find.byKey(const Key('parent-dashboard-side')), findsNothing);
    tester.view.physicalSize = const Size(1032, 1376) * 2;
    await pumpFrames(tester);
    expect(find.byKey(const Key('parent-dashboard-side')), findsOneWidget);
    expect(find.byKey(const Key('next-training-card')), findsOneWidget);
    expectNoLayoutErrors();
  });

  testWidgets('coach: group master list + quick actions on wide iPad', (tester) async {
    final db = await boot(tester, const Size(1376, 1032));
    await signInAs(tester, db, DemoIds.coach);
    expect(find.byKey(const Key('coach-group-panel')), findsOneWidget);
    expect(find.byKey(const Key('coach-quick-actions')), findsOneWidget);
    await tester.tap(find.byKey(const Key('group-tile-g-football-u12')));
    await pumpFrames(tester);
    expect(db.users[DemoIds.coach]!.lastContext.groupId, 'g-football-u12');
    // Phone keeps the chip selector instead of the panel.
    tester.view.physicalSize = const Size(390, 844) * 2;
    await pumpFrames(tester);
    expect(find.byKey(const Key('coach-group-panel')), findsNothing);
    expect(find.byKey(const Key('group-chip-g-football-u10')), findsOneWidget);
    expectNoLayoutErrors();
  });

  testWidgets('chat master-detail on iPad: conversation opens beside the list', (tester) async {
    final db = await boot(tester, const Size(1032, 1376));
    await signInAs(tester, db, DemoIds.parent);
    // Legacy tab path redirects to the top-bar chat list (v1.1 §4).
    await visit(tester, 'chat', ['/parent/chat']);
    expect(routerOf(tester).routerDelegate.currentConfiguration.uri.path, '/chats');
    expect(find.byKey(const Key('chat-input')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-tile-g-basket-u13')));
    await pumpFrames(tester);
    await tester.enterText(find.byKey(const Key('chat-input')), 'iPad message');
    await tester.tap(find.byKey(const Key('chat-send')));
    await pumpFrames(tester);
    expect(db.messages['g-basket-u13']!.last.text, 'iPad message');
    // Still on the chat list — the room opened in the detail pane.
    expect(routerOf(tester).routerDelegate.currentConfiguration.uri.path, '/chats');
    expectNoLayoutErrors();
  });

  testWidgets('calendar master-detail on wide iPad shows training detail pane', (tester) async {
    final db = await boot(tester, const Size(1376, 1032));
    await signInAs(tester, db, DemoIds.coach);
    await visit(tester, 'calendar', ['/coach/calendar']);
    expect(find.byKey(const Key('training-detail-pane')), findsOneWidget);
    expectNoLayoutErrors();
  });

  testWidgets('phone back navigation from a pushed detail returns to the tab', (tester) async {
    final db = await boot(tester, const Size(390, 844));
    await signInAs(tester, db, DemoIds.coach);
    final t = db.trainings.values.firstWhere(
      (t) => t.groupId == 'g-football-u10' && t.status == TrainingStatus.scheduled,
    );
    routerOf(tester).push('/training/${t.id}');
    await pumpFrames(tester);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await pumpFrames(tester);
    expect(find.byKey(const Key('new-training-fab')), findsOneWidget);
    expect(testNow, isNotNull);
    expectNoLayoutErrors();
  });

  testWidgets('roster becomes a grid on tablet', (tester) async {
    final db = await boot(tester, const Size(1032, 1376));
    await signInAs(tester, db, DemoIds.coach);
    await visit(tester, 'roster', ['/group/g-football-u10']);
    expect(find.byKey(const Key('roster-grid')), findsOneWidget);
    expectNoLayoutErrors();
  });
}
