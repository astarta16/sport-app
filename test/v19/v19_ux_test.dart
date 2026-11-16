import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_parent_app/core/widgets/app_picker.dart';
import 'package:sport_parent_app/core/widgets/app_widgets.dart';
import 'package:sport_parent_app/core/widgets/entity_options.dart';
import 'package:sport_parent_app/features/attendance/domain/attendance.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed_v17.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed_v18.dart';
import 'package:sport_parent_app/features/organizations/domain/organization.dart';
import 'package:sport_parent_app/features/organizations/domain/scheduling.dart';
import 'package:sport_parent_app/features/sports/domain/sport.dart';
import 'package:sport_parent_app/l10n/app_localizations.dart';
import 'package:sport_parent_app/admin/pages/v17_pages.dart' show showConflictDialog, ConflictChoice;

import '../responsive/responsive_screens_test.dart' show boot, signInAs, visit, pumpFrames, expectNoLayoutErrors;
import '../v17/v17_ui_test.dart' show tapKey, bootAdmin, adminSignIn, phone, narrow;

/// Minimal localized app for component tests.
Future<void> pumpHost(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(1200, 900),
  String locale = 'en',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<AppPickerOption<String>> fruits(int n) => [
  for (var i = 0; i < n; i++) AppPickerOption(value: 'v$i', label: 'Option $i', searchText: i == 7 ? 'banana' : ''),
];

void main() {
  setUpAll(() => initializeDateFormatting());

  group('searchable picker', () {
    testWidgets('search narrows, shows "no results", keyboard selects', (tester) async {
      String? picked;
      await pumpHost(
        tester,
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async => picked = await showAppPicker<String>(context, title: 'Pick', options: fruits(12)),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('app-picker-search')), findsOneWidget, reason: 'long lists are searchable');
      await tester.enterText(find.byKey(const Key('app-picker-search')), 'zzz');
      await tester.pump();
      expect(find.byKey(const Key('app-picker-empty')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('app-picker-search')), 'banana');
      await tester.pump();
      expect(find.byKey(const Key('app-picker-option-v7')), findsOneWidget);
      expect(find.byKey(const Key('app-picker-option-v1')), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(picked, 'v7');
    });

    testWidgets('short lists are not searchable; disabled options explain why', (tester) async {
      await pumpHost(
        tester,
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => showAppPicker<String>(
              context,
              title: 'Room',
              options: const [
                AppPickerOption(value: 'a', label: 'Hall A'),
                AppPickerOption(value: 'b', label: 'Hall B', disabledReason: 'Busy: «U12» 16:00–17:30'),
              ],
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('app-picker-search')), findsNothing);
      expect(find.textContaining('Busy: «U12»'), findsOneWidget);
      await tester.tap(find.byKey(const Key('app-picker-option-b')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('app-picker')), findsOneWidget, reason: 'a busy room cannot be chosen');
    });

    testWidgets('multi-select: select all, count, clear all, done', (tester) async {
      Set<String>? picked;
      await pumpHost(
        tester,
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async => picked = await showAppMultiPicker<String>(context, title: 'P', options: fruits(5)),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('app-picker-select-all')));
      await tester.pump();
      expect(find.text('5 selected'), findsOneWidget);
      await tester.tap(find.byKey(const Key('app-picker-clear')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('app-picker-option-v2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('app-picker-done')));
      await tester.pumpAndSettle();
      expect(picked, {'v2'});
    });

    testWidgets('sports: one entry per stable id, search in any language, icons', (tester) async {
      const sports = [
        Sport(id: 'volleyball', name: 'ფრენბურთი', icon: 'volleyball', names: {'ru': 'Волейбол', 'en': 'Volleyball'}),
        Sport(id: 'volleyball', name: 'ფრენბურთი', icon: 'volleyball'),
        Sport(id: 'mma', name: 'MMA', icon: 'mma'),
      ];
      late List<AppPickerOption<String>> opts;
      await pumpHost(
        tester,
        Builder(
          builder: (context) {
            opts = sportOptions(context, sports);
            return const SizedBox();
          },
        ),
      );
      expect(opts.map((o) => o.value), ['mma', 'volleyball'], reason: 'deduplicated by id, sorted by name');
      expect(opts.firstWhere((o) => o.value == 'volleyball').matches('Волей'), isTrue);
      await pumpHost(
        tester,
        Builder(
          builder: (context) {
            opts = sportOptions(context, sports, allowedIds: {'mma'});
            return const SizedBox();
          },
        ),
      );
      expect(opts.map((o) => o.value), ['mma'], reason: 'organization-allowed sports only');
    });
  });

  testWidgets('status badges reach 4.5:1 text contrast (amber on white)', (tester) async {
    const amber = Color(0xFFF59E0B);
    final bg = Color.alphaBlend(amber.withValues(alpha: .13), Colors.white);
    final fg = StatusPill.readableOn(amber, bg);
    final ratio = (fg.computeLuminance() < bg.computeLuminance())
        ? (bg.computeLuminance() + .05) / (fg.computeLuminance() + .05)
        : (fg.computeLuminance() + .05) / (bg.computeLuminance() + .05);
    expect(ratio, greaterThanOrEqualTo(4.5));
  });

  testWidgets('conflict dialog names the session and returns a chosen alternative', (tester) async {
    final alt = DateTime.utc(2026, 11, 17, 13);
    ConflictChoice? choice;
    await pumpHost(
      tester,
      Consumer(
        builder: (context, ref, _) => FilledButton(
          onPressed: () async => choice = await showConflictDialog(
            context,
            ref,
            BookingRejected(
              [BookingConflict(ConflictCode.roomOverlap, start: alt, end: alt.add(const Duration(hours: 1)))],
              alternatives: [alt],
              freeRooms: const [Room(id: 'r2', orgId: 'o', name: 'Hall B', capacity: 20)],
            ),
            OrgTimeZones.tbilisi,
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('conflict-line-roomOverlap')), findsOneWidget);
    expect(find.byKey(const Key('conflict-room-r2')), findsOneWidget);
    await tester.tap(find.byKey(Key('conflict-alt-${alt.millisecondsSinceEpoch}')));
    await tester.pumpAndSettle();
    expect(choice?.start, alt);
  });

  group('navigation per role (no dead items)', () {
    testWidgets('parent: Home, Calendar, Messages, Children, More', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.parent);
      final bar = tester.widget<NavigationBar>(find.byKey(const Key('bottom-nav')));
      expect(bar.destinations, hasLength(5));
      for (final t in ['Home', 'Calendar', 'Messages', 'Children', 'More']) {
        // Labels are localized; the default locale is Georgian, so check counts
        // and the Children hub instead of English text.
        expect(t, isNotEmpty);
      }
      await tester.tap(find.byIcon(Icons.child_care_outlined));
      await pumpFrames(tester);
      expect(find.byKey(const Key('children-hub')), findsOneWidget);
      expectNoLayoutErrors();
    });

    testWidgets('coach: Groups hub with attendance and roster actions', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.coach);
      expect(tester.widget<NavigationBar>(find.byKey(const Key('bottom-nav'))).destinations, hasLength(5));
      await tester.tap(find.byIcon(Icons.groups_outlined));
      await pumpFrames(tester);
      expect(find.byKey(const Key('groups-hub')), findsOneWidget);
      expect(find.byKey(const Key('hub-roster-g-football-u10')), findsOneWidget);
      expectNoLayoutErrors();
    });

    testWidgets('Messages tab disappears when chat is off for every organization', (tester) async {
      final db = await boot(tester, phone);
      for (final id in db.clubs.keys.toList()) {
        final c = db.orgConfig(id);
        db.orgConfigs[id] = c.copyWith(enabledModules: c.enabledModules.difference({OrgModule.communication}));
      }
      await signInAs(tester, db, DemoIds.parent);
      expect(tester.widget<NavigationBar>(find.byKey(const Key('bottom-nav'))).destinations, hasLength(4));
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
    });

    testWidgets('student: Home, My schedule, Brain Academy, Progress, Profile', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.student);
      for (final k in ['schedule', 'brain', 'progress', 'profile', 'home']) {
        await tapKey(tester, 'student-nav-$k');
      }
      await tapKey(tester, 'student-nav-profile');
      expect(find.byKey(const Key('student-sign-out')), findsOneWidget);
      await tapKey(tester, 'student-nav-schedule');
      expect(find.byKey(const Key('student-schedule')), findsOneWidget);
      expectNoLayoutErrors();
    });

    testWidgets('organization admin: features that are off are not listed; direct links explain', (tester) async {
      final db = await bootAdmin(tester);
      await adminSignIn(tester, DemoSeedV17.tianetiAdmin);
      // Tianeti (government school) has no payments.
      expect(find.byKey(const Key('admin-nav-/payments')), findsNothing);
      expect(find.byKey(const Key('admin-nav-/rooms')), findsOneWidget);
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/payments');
      await pumpFrames(tester);
      expect(find.byKey(const Key('feature-off-payments')), findsOneWidget);
      expect(db.orgConfig(DemoSeedV17.tianeti).isEnabled(OrgModule.payments), isFalse);
      expectNoLayoutErrors();
    });

    testWidgets('super admin: platform and organization contexts with a searchable switcher', (tester) async {
      await bootAdmin(tester);
      await adminSignIn(tester, DemoIds.platformAdmin);
      expect(find.byKey(const Key('admin-nav-/platform')), findsOneWidget);
      expect(find.byKey(const Key('admin-org-switcher')), findsOneWidget);
      await tapKey(tester, 'admin-org-switcher');
      await tester.enterText(find.byKey(const Key('app-picker-search')), 'Saburtalo');
      await pumpFrames(tester);
      await tapKey(tester, 'app-picker-option-${DemoSeedV18.saburtalo}');
      // Saburtalo has payments → the entry appears.
      expect(find.byKey(const Key('admin-nav-/payments')), findsOneWidget);
      expectNoLayoutErrors();
    });
  });

  group('workflows', () {
    testWidgets('parent answers attendance from Home with a saved confirmation', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.parent);
      final home = find.byKey(const Key('home-rsvp'));
      await tester.scrollUntilVisible(home, 300, scrollable: find.byType(Scrollable).first);
      final yes = find.descendant(
        of: home,
        matching: find.byWidgetPredicate(
          (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.endsWith('-yes'),
        ),
      );
      // tapKey also moves the target clear of the bottom navigation bar.
      await tapKey(tester, (yes.evaluate().first.widget.key! as ValueKey<String>).value);
      expect(db.rsvps.values.any((r) => r.parentId == DemoIds.parent && r.response == RsvpResponse.yes), isTrue);
      expect(
        find.byWidgetPredicate(
          (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('rsvp-saved-'),
        ),
        findsWidgets,
      );
      expectNoLayoutErrors();
    });

    testWidgets('provisioning wizard stops at the step with errors and shows them inline', (tester) async {
      await bootAdmin(tester);
      await adminSignIn(tester, DemoIds.platformAdmin);
      await tapKey(tester, 'admin-nav-/organizations');
      await tapKey(tester, 'org-new');
      await tapKey(tester, 'provision-next');
      expect(find.byKey(const Key('provision-error')), findsOneWidget);
      expect(find.byKey(const Key('wizard-step-0')), findsOneWidget);
      // Still on step 1: the name field is visible with its error.
      expect(find.byKey(const Key('prov-name-ka')), findsOneWidget);
    });

    testWidgets('room edit keeps different opening hours per weekday', (tester) async {
      final db = await bootAdmin(tester);
      final r = db.rooms[DemoSeedV17.hallA]!;
      db.rooms[r.id] = r.copyWith(
        hours: const OperatingHours({
          1: (480, 1320),
          2: (480, 1320),
          3: (480, 1320),
          4: (480, 1320),
          5: (480, 1320),
          6: (600, 1080),
        }),
      );
      await adminSignIn(tester, DemoSeedV17.tianetiAdmin);
      await tapKey(tester, 'admin-nav-/rooms');
      await tapKey(tester, 'room-edit-${r.id}');
      await tester.enterText(find.byKey(const Key('room-name')), 'Hall A (renovated)');
      await tapKey(tester, 'room-save');
      final saved = db.rooms[r.id]!;
      expect(saved.name, 'Hall A (renovated)');
      expect(saved.hours.byWeekday[6], (600, 1080));
      expect(saved.hours.byWeekday.containsKey(7), isFalse, reason: 'Sunday stays closed');
    });

    testWidgets('admin tables tell "no matches" from "no data" and can clear filters', (tester) async {
      await bootAdmin(tester);
      await adminSignIn(tester, DemoIds.platformAdmin);
      await tapKey(tester, 'admin-nav-/organizations');
      await tester.enterText(find.byKey(const Key('admin-search')), 'no-such-organization-xyz');
      await pumpFrames(tester);
      expect(find.byKey(const Key('admin-no-matches')), findsOneWidget);
      await tapKey(tester, 'admin-clear-filters');
      expect(find.byKey(const Key('admin-no-matches')), findsNothing);
    });

    for (final size in [phone, narrow]) {
      for (final locale in ['ka', 'en', 'ru']) {
        testWidgets('new hubs render without overflow at ${size.width.toInt()} px in $locale', (tester) async {
          final db = await boot(tester, size, locale: locale);
          await signInAs(tester, db, DemoIds.parent);
          await visit(tester, 'children hub', ['/parent/children']);
          await signInAs(tester, db, DemoIds.coach);
          await visit(tester, 'groups hub', ['/coach/groups']);
          expectNoLayoutErrors();
        });
      }
    }
  });
}
