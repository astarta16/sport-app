import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_parent_app/admin/admin_app.dart';
import 'package:sport_parent_app/features/authentication/domain/app_user.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/moderation/domain/report.dart';

import '../helpers.dart';

Future<DemoBackend> bootAdmin(WidgetTester tester, {Size size = const Size(1440, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final (db, overrides) = await demoSetup();
  await tester.pumpWidget(ProviderScope(overrides: overrides, retry: (_, _) => null, child: const AdminApp()));
  await pump(tester);
  return db;
}

Future<void> pump(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await pump(tester);
}

AuthSession session(UserRole role, {AdminRole? admin}) => AuthSession(
  uid: 'u',
  phone: '',
  user: AppUser(id: 'u', role: role, firstName: 'a', lastName: 'b', phone: '', createdAt: testNow, adminRole: admin),
);

void main() {
  setUpAll(() => initializeDateFormatting());

  group('admin route guard', () {
    String? go(String loc, AuthSession? s) => resolveAdminRedirect(location: loc, session: AsyncData(s));
    test('signed out → login', () => expect(go('/', null), AdminRoutes.login));
    test('parent / coach → denied', () {
      expect(go('/', session(UserRole.parent)), AdminRoutes.denied);
      expect(go('/coaches', session(UserRole.coach)), AdminRoutes.denied);
    });
    test('club admin cannot open platform-only pages', () {
      expect(go(AdminRoutes.admins, session(UserRole.admin, admin: AdminRole.club)), AdminRoutes.dashboard);
      expect(go(AdminRoutes.coaches, session(UserRole.admin, admin: AdminRole.club)), isNull);
    });
    test(
      'platform admin passes',
      () => expect(go(AdminRoutes.admins, session(UserRole.admin, admin: AdminRole.platform)), isNull),
    );
  });

  testWidgets('parent account gets a permission-denied state, not the dashboard', (tester) async {
    await bootAdmin(tester);
    await tap(tester, find.byKey(const Key('admin-demo-parent')));
    expect(find.byKey(const Key('admin-denied')), findsOneWidget);
    expect(find.byKey(const Key('admin-stats')), findsNothing);
  });

  testWidgets('platform admin: dashboard stats, approve a coach, moderate a report', (tester) async {
    final db = await bootAdmin(tester);
    await tap(tester, find.byKey(const Key('admin-demo-${DemoIds.platformAdmin}')));
    expect(find.byKey(const Key('admin-stats')), findsOneWidget);
    expect(find.byKey(const Key('admin-nav-/admins')), findsOneWidget);

    await tap(tester, find.byKey(const Key('admin-nav-/coaches')));
    expect(find.byKey(const Key('coach-row-coach-5')), findsOneWidget);
    await tap(tester, find.byKey(const Key('approve-coach-5')));
    expect(db.users['coach-5']!.coachStatus, CoachStatus.approved);
    expect(db.audit.last.action, 'coach.approve');

    // Reject requires a reason.
    await tap(tester, find.byKey(const Key('reject-coach-6')));
    await tap(tester, find.byKey(const Key('admin-reason-ok')));
    expect(db.users['coach-6']!.coachStatus, CoachStatus.pending);
    await tester.enterText(find.byKey(const Key('admin-reason')), 'სერტიფიკატი არ არის');
    await tap(tester, find.byKey(const Key('admin-reason-ok')));
    expect(db.users['coach-6']!.coachStatus, CoachStatus.rejected);

    await tap(tester, find.byKey(const Key('admin-nav-/moderation')));
    await tap(tester, find.byKey(const Key('hide-rep-2')));
    expect(db.reports['rep-2']!.status, ReportStatus.resolved);
    expect(db.mediaPosts['post-3']!.hidden, isTrue);

    await tap(tester, find.byKey(const Key('admin-nav-/audit')));
    expect(find.text('moderation.decide'), findsWidgets);
  });

  testWidgets('club admin sees only their club and no platform controls', (tester) async {
    await bootAdmin(tester);
    await tap(tester, find.byKey(const Key('admin-demo-${DemoIds.clubAdmin}')));
    expect(find.byKey(const Key('admin-nav-/admins')), findsNothing);
    await tap(tester, find.byKey(const Key('admin-nav-/clubs')));
    expect(find.byKey(const Key('club-row-club-1')), findsOneWidget);
    expect(find.byKey(const Key('club-row-club-2')), findsNothing);
    expect(find.byKey(const Key('admin-new-club')), findsNothing);
    await tap(tester, find.byKey(const Key('admin-nav-/moderation')));
    expect(find.byKey(const Key('hide-rep-1')), findsOneWidget);
    expect(find.byKey(const Key('hide-rep-2')), findsNothing);
    await tap(tester, find.byKey(const Key('admin-nav-/sports')));
    expect(find.byKey(const Key('admin-new-sport')), findsNothing);
  });

  testWidgets('platform admin creates a sport and edits a club; table paginates', (tester) async {
    final db = await bootAdmin(tester);
    await tap(tester, find.byKey(const Key('admin-demo-${DemoIds.platformAdmin}')));
    await tap(tester, find.byKey(const Key('admin-nav-/sports')));
    await tap(tester, find.byKey(const Key('admin-new-sport')));
    await tester.enterText(find.byKey(const Key('sport-id')), 'kickboxing');
    await tester.enterText(find.byKey(const Key('sport-name')), 'კიკბოქსი');
    await tester.enterText(find.byKey(const Key('sport-age')), '10');
    await tap(tester, find.byKey(const Key('sport-save')));
    expect(db.sports['kickboxing']?.name, 'კიკბოქსი');

    await tap(tester, find.byKey(const Key('admin-nav-/clubs')));
    expect(find.byKey(const Key('admin-page-info')), findsOneWidget);
    await tap(tester, find.byKey(const Key('edit-club-club-1')));
    await tester.enterText(find.byKey(const Key('club-name')), 'საბურთალოს აკადემია');
    await tap(tester, find.byKey(const Key('club-save')));
    expect(db.clubs['club-1']!.name, 'საბურთალოს აკადემია');
    expect(db.audit.last.action, 'club.update');
  });

  testWidgets('admin layout works on a narrow window (drawer)', (tester) async {
    await bootAdmin(tester, size: const Size(700, 1000));
    await tap(tester, find.byKey(const Key('admin-demo-${DemoIds.platformAdmin}')));
    expect(find.byType(Drawer), findsNothing);
    expect(find.byKey(const Key('admin-stats')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
