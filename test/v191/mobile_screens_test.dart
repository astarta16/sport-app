import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_parent_app/core/theme/app_theme.dart';
import 'package:sport_parent_app/features/attendance/domain/attendance.dart';
import 'package:sport_parent_app/features/children/presentation/child_profile_screen.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/organizations/domain/organization.dart';
import 'package:sport_parent_app/features/parent/presentation/parent_context.dart';
import 'package:sport_parent_app/features/trainings/domain/training.dart';
import 'package:sport_parent_app/features/trainings/presentation/training_widgets.dart';
import 'package:sport_parent_app/l10n/app_localizations.dart';

import '../helpers.dart';
import '../responsive/responsive_screens_test.dart' show boot, signInAs, visit, pumpFrames, expectNoLayoutErrors;
import '../v17/v17_ui_test.dart' show tapKey, scrollTo, phone, narrow;

const _u10 = 'g-football-u10';

String _path(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first)).routerDelegate.currentConfiguration.uri.toString();

/// Puts child-2 (Mariam, 12) into the U-10 group next to her brother Luka so
/// parent-1 has two children in one group.
void _addSibling(DemoBackend db) {
  final g = db.groups[_u10]!;
  db.groups[_u10] = g.copyWith(memberChildIds: [...g.memberChildIds, 'child-2']);
  final c = db.children['child-2']!;
  db.children['child-2'] = c.copyWith(groupIds: [...c.groupIds, _u10]);
  db.commit();
}

Future<void> _realFonts() async {
  final dir =
      '${Platform.environment['FLUTTER_ROOT'] ?? '/Users/ninigedeshuri/development/flutter'}'
      '/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    roboto.addFont(Future.value(ByteData.sublistView(File('$dir/Roboto-$w.ttf').readAsBytesSync())));
  }
  await roboto.load();
  final ka = FontLoader('NotoSansGeorgian')..addFont(rootBundle.load('assets/fonts/NotoSansGeorgian.ttf'));
  await ka.load();
  AppTheme.debugFontFallback = const ['NotoSansGeorgian'];
}

void main() {
  setUpAll(() => initializeDateFormatting());

  group('calendar (M27, M28)', () {
    testWidgets('match days carry a trophy marker and a legend; the match is listed on its day', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.parent);
      await visit(tester, 'calendar', ['/parent/calendar']);
      await tapKey(tester, 'calendar-child-child-1');
      // match-1 (U-10, Luka's group) is five days after the test clock.
      final day = db.matches['match-1']!.startAt;
      final marker = 'calendar-match-marker-${day.year}-${day.month}-${day.day}';

      expect(find.byKey(Key(marker)), findsOneWidget, reason: 'match day is marked');
      expect(find.byKey(const Key('calendar-legend')), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_rounded), findsWidgets);
      await tester.tap(find.text('${day.day}').first);
      await pumpFrames(tester);
      await scrollTo(tester, 'calendar-match-match-1');
      expect(find.byKey(const Key('calendar-match-match-1')), findsOneWidget);
      expect(find.byKey(const Key('calendar-matches-error')), findsNothing);
      expectNoLayoutErrors();
    });

    testWidgets('the child selector shows whose calendar it is and changes the Home selection', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.parent);
      await visit(tester, 'calendar', ['/parent/calendar']);
      expect(find.byKey(const Key('calendar-child-selector')), findsOneWidget);
      final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
      await tapKey(tester, 'calendar-child-child-2');
      expect(container.read(parentSelectionProvider).value!.child!.id, 'child-2');
      expect(tester.widget<ChoiceChip>(find.byKey(const Key('calendar-child-child-2'))).selected, isTrue);
      await tapKey(tester, 'calendar-child-all');
      expect(tester.widget<ChoiceChip>(find.byKey(const Key('calendar-child-all'))).selected, isTrue);
      // Home follows the calendar.
      await tapKey(tester, 'calendar-child-child-1');
      await visit(tester, 'home', ['/parent/home']);
      expect(container.read(parentSelectionProvider).value!.child!.id, 'child-1');
      expectNoLayoutErrors();
    });
  });

  group('student tabs are linkable (M3)', () {
    testWidgets('/kid/home?tab=brain opens Brain Academy; switching tabs updates the URL', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.student);
      await visit(tester, 'brain link', ['/kid/home?tab=brain']);
      expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 2);
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack).first).index, 2);
      await tapKey(tester, 'student-nav-progress');
      expect(_path(tester), '/kid/home?tab=progress');
      await tapKey(tester, 'student-nav-home');
      expect(_path(tester), '/kid/home');
      await visit(tester, 'profile link', ['/kid/home?tab=profile']);
      expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 4);
      expectNoLayoutErrors();
    });
  });

  group('coach group page (M17, M18, M19)', () {
    testWidgets('Add match / Roster / New plan follow the organization features', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.coach);
      final clubId = db.groups[_u10]!.clubId;
      final c = db.orgConfig(clubId);
      db.orgConfigs[clubId] = c.copyWith(
        enabledModules: c.enabledModules.union({OrgModule.matches, OrgModule.dataExports, OrgModule.trainingPlans}),
      );
      db.commit();
      await visit(tester, 'roster on', ['/group/$_u10']);
      for (final k in ['group-add-match', 'group-students', 'group-new-plan']) {
        await scrollTo(tester, k);
        expect(find.byKey(Key(k)), findsOneWidget, reason: '$k shown while the feature is on');
      }
      final on = db.orgConfig(clubId);
      db.orgConfigs[clubId] = on.copyWith(
        enabledModules: on.enabledModules.difference({
          OrgModule.matches,
          OrgModule.dataExports,
          OrgModule.trainingPlans,
        }),
      );
      db.commit();
      await visit(tester, 'roster off', ['/coach/home', '/group/$_u10']);
      for (final k in ['group-add-match', 'group-students', 'group-new-plan']) {
        expect(find.byKey(Key(k)), findsNothing, reason: '$k hidden while the feature is off');
      }
      expect(find.byKey(const Key('invite-child')), findsOneWidget);
      expectNoLayoutErrors();
    });

    testWidgets('roster search filters by name; Remove sits in a menu and asks first', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.coach);
      await visit(tester, 'roster', ['/group/$_u10']);
      await scrollTo(tester, 'roster-search');
      await tester.enterText(find.byKey(const Key('roster-search')), 'დათო');
      await pumpFrames(tester);
      await scrollTo(tester, 'roster-child-4');
      expect(find.byKey(const Key('roster-child-4')), findsOneWidget);
      expect(find.byKey(const Key('roster-child-1')), findsNothing);
      // No "Remove" button inside the expanded tile any more.
      await tester.tap(find.byKey(const Key('roster-child-4')));
      await pumpFrames(tester);
      expect(find.widgetWithText(TextButton, 'ჯგუფიდან ამოშლა'), findsNothing);
      await tapKey(tester, 'roster-menu-child-4');
      await tapKey(tester, 'roster-remove-child-4');
      expect(find.byType(AlertDialog), findsOneWidget, reason: 'destructive action is confirmed');
      await tester.tap(find.byKey(const Key('confirm-ok')));
      await pumpFrames(tester);
      expect(db.groups[_u10]!.memberChildIds, isNot(contains('child-4')));
      // A search without matches says so.
      await tester.enterText(find.byKey(const Key('roster-search')), 'zzzz');
      await pumpFrames(tester);
      expect(find.byKey(const Key('roster-no-matches')), findsOneWidget);
      expectNoLayoutErrors();
    });

    testWidgets('an empty group says so and offers to add a child', (tester) async {
      final db = await boot(tester, narrow);
      await signInAs(tester, db, DemoIds.coach);
      await visit(tester, 'empty roster', ['/group/g-football-u12']);
      await scrollTo(tester, 'roster-empty');
      expect(find.byKey(const Key('roster-empty')), findsOneWidget);
      final empty = tester.widget<Widget>(find.byKey(const Key('roster-empty')));
      expect((empty as dynamic).onAction, isNotNull);
      expectNoLayoutErrors();
    });

    testWidgets('child search shows "no results" only after a search ran (M35)', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.coach);
      await visit(tester, 'invite', ['/group/$_u10/invite']);
      await tester.enterText(find.byKey(const Key('child-search')), 'qqqq');
      await pumpFrames(tester);
      expect(find.byKey(const Key('child-search-empty')), findsNothing, reason: 'nothing searched yet');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await pumpFrames(tester);
      expect(find.byKey(const Key('child-search-empty')), findsOneWidget);
      expectNoLayoutErrors();
    });
  });

  group('parent (M11, M29, M30, M34)', () {
    testWidgets('"Same answer for all" saves the answer for each child in the group', (tester) async {
      final db = await boot(tester, phone);
      _addSibling(db);
      await signInAs(tester, db, DemoIds.parent);
      final training = db.trainings.values
          .where((t) => t.groupId == _u10 && t.startAt.isAfter(testNow) && t.status == TrainingStatus.scheduled)
          .reduce((a, b) => a.startAt.isBefore(b.startAt) ? a : b);
      await visit(tester, 'training', ['/training/${training.id}']);
      await scrollTo(tester, 'rsvp-all');
      expect(find.byKey(const Key('rsvp-child-1')), findsOneWidget, reason: 'per-child cards stay');
      await tapKey(tester, 'rsvp-all-no');
      Rsvp? answer(String child) =>
          db.rsvps.values.where((r) => r.trainingId == training.id && r.childId == child).firstOrNull;
      expect(answer('child-1')?.response, RsvpResponse.no);
      expect(answer('child-2')?.response, RsvpResponse.no);
      expectNoLayoutErrors();
    });

    testWidgets('one child in the group: no "answer for all" row', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.parent);
      final training = db.trainings.values.firstWhere(
        (t) => t.groupId == _u10 && t.startAt.isAfter(testNow) && t.status == TrainingStatus.scheduled,
      );
      await visit(tester, 'training', ['/training/${training.id}']);
      expect(find.byKey(const Key('rsvp-all')), findsNothing);
    });

    testWidgets('Home: visible child-details link and a real "Add child" button', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.parent);
      await visit(tester, 'home', ['/parent/home']);
      final handle = tester.ensureSemantics();
      final add = tester.getSemantics(find.byKey(const Key('home-add-child')));
      expect(add.flagsCollection.isButton, isTrue);
      handle.dispose();
      await tapKey(tester, 'open-child-details');
      expect(find.byType(ChildProfileScreen), findsOneWidget);
      expectNoLayoutErrors();
    });

    testWidgets('join picker disables members and children outside the age range, with the reason', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.parent);
      await visit(tester, 'club', ['/club/club-1']);
      // U-10 (8–10): Luka is a member, Mariam (12) and Nika (15) are too old.
      await tapKey(tester, 'join-$_u10');
      expect(find.byKey(const Key('app-picker')), findsOneWidget);
      ListTile option(String id) => tester.widget<ListTile>(find.byKey(Key('app-picker-option-$id')));
      expect(option('child-1').enabled, isFalse);
      expect(option('child-2').enabled, isFalse);
      expect(option('child-3').enabled, isFalse);
      expect(find.textContaining('უკვე ამ ჯგუფშია'), findsOneWidget);
      expect(find.textContaining('ჯგუფი 8–10 წლისთვისაა'), findsNWidgets(2));
      expectNoLayoutErrors();
    });
  });

  testWidgets('export sheet: trainings picker grouped by month (M43)', (tester) async {
    final db = await boot(tester, phone);
    await signInAs(tester, db, DemoIds.coach);
    await visit(tester, 'students', ['/students?groupId=$_u10']);
    await tapKey(tester, 'roster-export');
    await tapKey(tester, 'export-sheet-kind');
    await tapKey(tester, 'export-training');
    expect(find.byKey(const Key('app-picker')), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is ListTile && w.key.toString().contains('app-picker-option-')),
      findsWidgets,
    );
    expectNoLayoutErrors();
  });
  // Last in the file: it loads real fonts (Roboto + the app's Georgian
  // font), which stay registered for the rest of the isolate. The default
  // test font draws every glyph as a square and would measure nothing real.
  group('NextTrainingCard label is never cut (Georgian truncation)', () {
    setUpAll(_realFonts);
    tearDownAll(() => AppTheme.debugFontFallback = null);
    for (final locale in ['ka', 'en', 'ru']) {
      for (final width in [320.0, 360.0, 390.0]) {
        testWidgets('$locale at ${width.toInt()} px', (tester) async {
          final (db, overrides) = await demoSetup();
          final training = db.trainings.values.firstWhere(
            (t) => t.groupId == _u10 && t.startAt.isAfter(testNow) && t.status == TrainingStatus.scheduled,
          );
          final group = db.groups[_u10]!;
          tester.view.physicalSize = Size(width, 900) * 2;
          tester.view.devicePixelRatio = 2;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: overrides,
              retry: (_, _) => null,
              child: MaterialApp(
                theme: AppTheme.light(),
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      NextTrainingCard(training: training, group: group, now: testNow, coachName: 'გიორგი'),
                      const SizedBox(height: 12),
                      TrainingTile(training: training, group: group),
                    ],
                  ),
                ),
              ),
            ),
          );
          await pumpFrames(tester);
          final label = tester.renderObject<RenderParagraph>(find.byKey(const Key('next-training-label')));
          final expected = lookupAppLocalizations(Locale(locale)).nextTraining.toUpperCase();
          expect(tester.widget<Text>(find.byKey(const Key('next-training-label'))).data, expected);
          expect(label.didExceedMaxLines, isFalse);
          expect(
            tester.widget<Text>(find.byKey(const Key('next-training-label'))).overflow,
            isNot(TextOverflow.ellipsis),
          );
          // Fully inside the card, and on one line when the phone is wide enough.
          final card = tester.getRect(find.byKey(const Key('next-training-card')));
          final rect = tester.getRect(find.byKey(const Key('next-training-label')));
          expect(card.contains(rect.topLeft) && card.contains(rect.bottomRight), isTrue);
          if (width >= 360) {
            expect(label.getMaxIntrinsicWidth(double.infinity), lessThanOrEqualTo(label.size.width + 0.5));
          }
          // The countdown is never cut either.
          final countdown = tester.renderObject<RenderParagraph>(find.byKey(const Key('next-training-countdown')));
          expect(countdown.didExceedMaxLines, isFalse);
          // TrainingTile: time and group name get two lines before any ellipsis.
          final tile = tester.renderObject<RenderParagraph>(find.byKey(Key('training-tile-title-${training.id}')));
          expect(tile.didExceedMaxLines, isFalse);
          expectNoLayoutErrors();
        });
      }
    }
  });
}
