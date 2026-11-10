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

/// Representative logical window sizes (width x height).
const sizes = <String, Size>{
  'iPhone portrait': Size(390, 844),
  'iPhone landscape': Size(844, 390),
  'iPad mini portrait': Size(744, 1133),
  'iPad mini landscape': Size(1133, 744),
  'iPad Pro 13 portrait': Size(1032, 1376),
  'iPad Pro 13 landscape': Size(1376, 1032),
  'iPad Slide Over': Size(320, 980),
  'iPad 1/3 Split View': Size(507, 1032),
  'iPad 1/2 Split View (landscape)': Size(678, 1032),
};

/// Every framework error seen during a test (boot + visits), with the first
/// `lib/` source location found in the report.
final collected = <String>[];
String currentLabel = '';

void _collect(FlutterErrorDetails details) {
  final msg = details.exceptionAsString().split('\n').first;
  // Map tiles have no network in tests; that's not a layout problem.
  if (msg.contains('HTTP') || msg.contains('NetworkTile') || msg.contains('ClientException')) return;
  final full = '$details\n${details.stack}';
  final loc = RegExp(r'lib/[\w/]+\.dart:\d+(:\d+)?').firstMatch(full)?.group(0) ?? '?';
  collected.add('[$currentLabel] $msg  <$loc>');
}

/// Restores the framework handler first (expect() must not run while it is
/// overridden), then asserts that no layout errors were collected.
void expectNoLayoutErrors() {
  final errors = List.of(collected);
  collected.clear();
  expect(errors, isEmpty, reason: errors.join('\n'));
}

/// Runs [body] with the error collector installed, restoring the framework
/// handler afterwards so expect() never runs while it is overridden.
Future<T> collecting<T>(Future<T> Function() body) async {
  final previous = FlutterError.onError;
  FlutterError.onError = _collect;
  try {
    return await body();
  } finally {
    FlutterError.onError = previous;
  }
}

Future<void> pumpFrames(WidgetTester tester, [int n = 8]) => collecting(() async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
});

Future<DemoBackend> boot(WidgetTester tester, Size size, {double textScale = 1, bool onboarded = true}) async {
  currentLabel = '${size.width.toInt()}x${size.height.toInt()} boot';
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final (db, overrides) = await demoSetup(prefs: {'settings.onboardingSeen': onboarded});
  await collecting(
    () => tester.pumpWidget(ProviderScope(overrides: overrides, retry: (_, _) => null, child: const SportParentApp())),
  );
  await pumpFrames(tester);
  return db;
}

Future<void> signInAs(WidgetTester tester, DemoBackend db, String uid) async {
  db.session = (uid: uid, phone: db.users[uid]!.phone);
  db.commit();
  await pumpFrames(tester);
}

GoRouter routerOf(WidgetTester tester) => GoRouter.of(tester.element(find.byType(Scaffold).first));

Future<void> visit(WidgetTester tester, String label, List<String> routes) async {
  for (final r in routes) {
    currentLabel = '$label @ $r';
    routerOf(tester).go(r);
    await pumpFrames(tester);
  }
}

void main() {
  setUpAll(() => initializeDateFormatting());
  setUp(collected.clear);

  for (final entry in sizes.entries) {
    testWidgets('parent screens render without layout errors — ${entry.key}', (tester) async {
      final db = await boot(tester, entry.value);
      await signInAs(tester, db, DemoIds.parent);
      final training = db.trainings.values.firstWhere((t) => t.groupId == 'g-football-u10' && t.photoUrls.isNotEmpty);
      await visit(tester, entry.key, [
        '/parent/home',
        '/parent/calendar',
        '/parent/chat',
        '/parent/map',
        '/parent/profile',
        '/training/${training.id}',
        '/chat/g-football-u10',
        '/children/child-1',
        '/children/new',
        '/certificates/child-2',
        '/certificates/child-2/upload',
        '/payments',
        '/notifications',
        '/notifications/settings',
        '/settings',
        '/club/club-1',
        // v1.1 / v1.2
        '/chats',
        '/invites',
        '/children/child-1/progress',
        '/match/match-1',
        '/match/match-4',
        '/media/post-1',
        '/account',
        '/account/privacy',
      ]);
      expectNoLayoutErrors();
    });

    testWidgets('coach screens render without layout errors — ${entry.key}', (tester) async {
      final db = await boot(tester, entry.value);
      await signInAs(tester, db, DemoIds.coach);
      final upcoming = db.trainings.values.firstWhere(
        (t) => t.groupId == 'g-football-u10' && t.status == TrainingStatus.scheduled && t.startAt.isAfter(testNow),
      );
      await visit(tester, entry.key, [
        '/coach/home',
        '/coach/calendar',
        '/coach/chat',
        '/coach/map',
        '/coach/profile',
        '/training/${upcoming.id}',
        '/training/${upcoming.id}/edit',
        '/training/new?groupId=g-football-u10',
        '/group/g-football-u10',
        '/group/g-football-u10/payments',
        '/certificates/child-1',
        // v1.1 / v1.2
        '/chats',
        '/training/${upcoming.id}/attendance',
        '/series/new?groupId=g-football-u10',
        '/series/ser-u12/edit?from=${testNow.year}-${testNow.month.toString().padLeft(2, '0')}-${testNow.day.toString().padLeft(2, '0')}',
        '/match/new?groupId=g-football-u10',
        '/match/match-1',
        '/media/new?groupId=g-football-u10',
        '/group/new',
        '/group/g-football-u10/invite',
        '/children/child-1/progress',
        '/account',
      ]);
      expectNoLayoutErrors();
    });
  }

  testWidgets('sign-in, guest map and pending-approval screens fit every size', (tester) async {
    for (final entry in sizes.entries) {
      final db = await boot(tester, entry.value);
      await visit(tester, entry.key, ['/auth/phone', '/explore']);
      currentLabel = '${entry.key} @ /auth/pending';
      await signInAs(tester, db, DemoIds.pendingCoach);
    }
    expectNoLayoutErrors();
  });

  testWidgets('onboarding fits every size, including phone landscape', (tester) async {
    for (final size in sizes.values) {
      await boot(tester, size, onboarded: false);
      if (find.text('ყველა ვარჯიში ერთ კალენდარში').evaluate().isEmpty) collected.add('onboarding not shown at $size');
    }
    expectNoLayoutErrors();
  });

  testWidgets('large text (1.4x) on iPhone does not overflow key screens', (tester) async {
    final db = await boot(tester, sizes['iPhone portrait']!, textScale: 1.4);
    await signInAs(tester, db, DemoIds.parent);
    await visit(tester, 'iPhone 1.4x', ['/parent/home', '/parent/calendar', '/parent/profile', '/payments']);
    expectNoLayoutErrors();
  });
}
