// Renders representative screens to PNG with real fonts (English UI) for
// the before/after comparison in docs/ux-v1.9-workflow-comparison.md.
// Not part of the normal suite. Run:
//   CAPTURE=1 flutter test test/screenshots/capture_test.dart --update-goldens
// Output: test/screenshots/out/*.png (git-ignored; copied to docs/screenshots).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_parent_app/admin/admin_app.dart';
import 'package:sport_parent_app/core/theme/app_theme.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed_v17.dart';
import '../helpers.dart';
import '../responsive/responsive_screens_test.dart' show boot, signInAs, visit, pumpFrames;

final _capture = Platform.environment.containsKey('CAPTURE');
final _sdk = Platform.environment['FLUTTER_ROOT'] ?? '/Users/ninigedeshuri/development/flutter';

Future<void> _fonts() async {
  final dir = '$_sdk/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    roboto.addFont(Future.value(ByteData.sublistView(File('$dir/Roboto-$w.ttf').readAsBytesSync())));
  }
  await roboto.load();
  // Georgian glyphs (demo names are Georgian): the app's bundled font,
  // used as a fallback in screenshots only.
  final ka = FontLoader('NotoSansGeorgian')..addFont(rootBundle.load('assets/fonts/NotoSansGeorgian.ttf'));
  await ka.load();
  AppTheme.debugFontFallback = const ['NotoSansGeorgian'];
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(File('$dir/MaterialIcons-Regular.otf').readAsBytesSync())));
  await icons.load();
}

Future<void> _shot(WidgetTester tester, String name) async {
  await pumpFrames(tester, 6);
  await expectLater(find.byType(Navigator).first, matchesGoldenFile('out/$name.png'));
}

Future<void> _admin(WidgetTester tester, String uid) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final (_, overrides) = await demoSetup(prefs: {'settings.locale': 'en'});
  await tester.pumpWidget(ProviderScope(overrides: overrides, retry: (_, _) => null, child: const AdminApp()));
  await pumpFrames(tester, 6);
  await tester.tap(find.byKey(Key('admin-demo-$uid')));
  await pumpFrames(tester);
}

void _go(WidgetTester tester, String route) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    if (_capture) await _fonts();
  });
  const phone = Size(390, 844);

  for (final (name, uid, route) in [
    ('parent_home', DemoIds.parent, '/parent/home'),
    ('coach_home', DemoIds.coach, '/coach/home'),
    ('coach_new_group', DemoIds.coach, '/group/new'),
  ]) {
    testWidgets(name, skip: !_capture, (tester) async {
      final db = await boot(tester, phone, locale: 'en');
      await signInAs(tester, db, uid);
      await visit(tester, name, [route]);
      await _shot(tester, name);
    });
  }

  testWidgets('student_home', skip: !_capture, (tester) async {
    final db = await boot(tester, phone, locale: 'en');
    await signInAs(tester, db, DemoIds.student);
    await _shot(tester, 'student_home');
    await tester.tap(find.byKey(const Key('student-nav-brain')));
    await _shot(tester, 'brain_academy');
  });

  for (final (name, uid, route) in [
    ('org_admin_overview', DemoSeedV17.tianetiAdmin, '/'),
    ('room_scheduling', DemoSeedV17.tianetiAdmin, '/schedule'),
    ('org_settings_add_coach', DemoSeedV17.tianetiAdmin, '/org-settings'),
    ('super_admin_overview', DemoIds.platformAdmin, '/platform'),
    ('feature_management', DemoIds.platformAdmin, '/organizations/org-saburtalo'),
  ]) {
    testWidgets(name, skip: !_capture, (tester) async {
      await _admin(tester, uid);
      _go(tester, route);
      await pumpFrames(tester);
      if (name == 'feature_management') {
        await tester.tap(find.widgetWithText(Tab, 'Features'));
        await pumpFrames(tester);
      }
      await _shot(tester, name);
    });
  }

  testWidgets('organization_creation', skip: !_capture, (tester) async {
    await _admin(tester, DemoIds.platformAdmin);
    _go(tester, '/organizations');
    await pumpFrames(tester);
    await tester.tap(find.byKey(const Key('org-new')));
    await _shot(tester, 'organization_creation');
  });
}
