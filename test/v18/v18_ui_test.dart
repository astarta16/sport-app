import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed_v17.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed_v18.dart';
import 'package:sport_parent_app/features/organizations/domain/organization.dart';
import 'package:sport_parent_app/features/organizations/domain/platform.dart';
import 'package:go_router/go_router.dart';

import '../responsive/responsive_screens_test.dart' show boot, signInAs, visit, pumpFrames, expectNoLayoutErrors;
import '../v17/v17_ui_test.dart' show tapKey, bootAdmin, adminSignIn;

/// Platform change outside the UI (another administrator, another device).
void disableFor(DemoBackend db, String orgId, Set<OrgModule> modules) {
  final c = db.orgConfig(orgId);
  db.saveConfig(
    c.copyWith(allowedModules: c.allowedModules.difference(modules)),
    expectedVersion: c.version,
    reason: 'test: disabled elsewhere',
    action: 'org.entitlements',
  );
  db.commit();
}

void adminGo(WidgetTester tester, String location) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);

/// Taps without ensureVisible(), which would slide a TabBarView page
/// sideways to align the target with the viewport edge.
Future<void> tapIn(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)).first);
  await pumpFrames(tester);
}

void main() {
  setUpAll(() => initializeDateFormatting());

  group('feature gating in the mobile app', () {
    testWidgets('government school coach never sees payments; private club coach does', (tester) async {
      final db = await boot(tester, const Size(1376, 1032));
      await signInAs(tester, db, DemoSeedV17.volleyCoach);
      expect(find.byKey(const Key('coach-quick-actions')), findsOneWidget);
      expect(find.byKey(const Key('qa-payments')), findsNothing);
      // A direct link to a disabled feature is redirected.
      await visit(tester, 'blocked', ['/group/${DemoSeedV17.volleyGroup}/payments']);
      expect(find.byKey(const Key('coach-quick-actions')), findsOneWidget);

      await signInAs(tester, db, DemoSeedV18.saburtaloCoach);
      expect(find.byKey(const Key('qa-payments')), findsOneWidget);
      expectNoLayoutErrors();
    });

    testWidgets('disabling payments on the platform hides them live (no app rebuild)', (tester) async {
      final db = await boot(tester, const Size(1376, 1032));
      await signInAs(tester, db, DemoSeedV18.saburtaloCoach);
      expect(find.byKey(const Key('qa-payments')), findsOneWidget);
      disableFor(db, DemoSeedV18.saburtalo, DemoSeedV18.paymentModules);
      await pumpFrames(tester);
      expect(find.byKey(const Key('qa-payments')), findsNothing);
      expect(db.payments['pay-saburtalo-1'], isNotNull, reason: 'historical data is kept');
      expectNoLayoutErrors();
    });
  });

  group('Platform Control Center', () {
    testWidgets('navigation and pages render for the super admin', (tester) async {
      await bootAdmin(tester);
      await adminSignIn(tester, DemoIds.platformAdmin);
      for (final (route, key) in [
        ('/platform', 'platform-overview'),
        ('/templates', 'template-row-${OrgTemplate.government}'),
        ('/features', 'catalog-payments'),
        ('/packages', 'package-row-${SubscriptionPackage.professionalId}'),
        ('/subscriptions', 'sub-row-${DemoSeedV17.tianeti}'),
        ('/invitations', 'inv-status-${DemoSeedV18.invitationId}'),
      ]) {
        await tapKey(tester, 'admin-nav-$route');
        // Paginated tables: narrow down to the row.
        final q = {'/features': 'payments', '/subscriptions': 'თიანეთ'}[route];
        if (q != null) {
          await tester.enterText(find.byKey(const Key('admin-search')), q);
          await pumpFrames(tester);
        }
        expect(find.byKey(Key(key)), findsWidgets, reason: route);
      }
      await tapKey(tester, 'admin-nav-/health');
      await tapKey(tester, 'health-refresh');
      expectNoLayoutErrors();
    });

    testWidgets('organization admin has no Control Center pages', (tester) async {
      await bootAdmin(tester);
      await adminSignIn(tester, DemoSeedV17.tianetiAdmin);
      for (final r in ['/platform', '/templates', '/features', '/packages', '/subscriptions', '/health']) {
        expect(find.byKey(Key('admin-nav-$r')), findsNothing, reason: r);
      }
      await tapKey(tester, 'admin-nav-/members');
      expect(find.byKey(const Key('org-members')), findsOneWidget);
      expectNoLayoutErrors();
    });

    testWidgets('Features tab: toggle, unsaved warning, reason, versioned save', (tester) async {
      final db = await bootAdmin(tester);
      await adminSignIn(tester, DemoIds.platformAdmin);
      final before = db.orgConfig(DemoSeedV18.saburtalo);
      adminGo(tester, '/organizations/${DemoSeedV18.saburtalo}');
      await pumpFrames(tester);
      expect(find.byKey(const Key('org-detail-${DemoSeedV18.saburtalo}')), findsOneWidget);
      await tester.tap(find.widgetWithText(Tab, 'ფუნქციები'));
      await pumpFrames(tester);
      await tapIn(tester, 'features-cat-communication');
      await tapIn(tester, 'feature-toggle-media');
      expect(find.byKey(const Key('features-dirty')), findsOneWidget);
      await tapIn(tester, 'features-save');
      await tester.enterText(find.byKey(const Key('change-reason')), 'media rights not cleared');
      await tapIn(tester, 'change-reason-ok');
      final after = db.orgConfig(DemoSeedV18.saburtalo);
      expect(after.allowedModules, isNot(contains(OrgModule.media)));
      expect(after.version, before.version + 1);
      expect(after.changeReason, 'media rights not cleared');
      expectNoLayoutErrors();
    });

    testWidgets('Features tab: a concurrent edit is reported, not overwritten', (tester) async {
      final db = await bootAdmin(tester);
      await adminSignIn(tester, DemoIds.platformAdmin);
      adminGo(tester, '/organizations/${DemoSeedV18.saburtalo}');
      await pumpFrames(tester);
      await tester.tap(find.widgetWithText(Tab, 'ფუნქციები'));
      await pumpFrames(tester);
      await tapIn(tester, 'features-cat-learning');
      await tapIn(tester, 'feature-toggle-trainingPlans');
      // Someone else saves first (the editor still holds the old version).
      final c = db.orgConfig(DemoSeedV18.saburtalo);
      db.orgConfigs[DemoSeedV18.saburtalo] = c.copyWith(version: c.version + 1);
      await tapIn(tester, 'features-save');
      await tester.enterText(find.byKey(const Key('change-reason')), 'stale edit');
      await tapIn(tester, 'change-reason-ok');
      expect(find.byKey(const Key('config-conflict')), findsOneWidget);
      expect(db.orgConfig(DemoSeedV18.saburtalo).allowedModules, contains(OrgModule.trainingPlans));
    });

    testWidgets('dependencies are offered before saving', (tester) async {
      final db = await bootAdmin(tester);
      await adminSignIn(tester, DemoIds.platformAdmin);
      adminGo(tester, '/organizations/${DemoSeedV18.saburtalo}');
      await pumpFrames(tester);
      await tester.tap(find.widgetWithText(Tab, 'ფუნქციები'));
      await pumpFrames(tester);
      await tapIn(tester, 'features-cat-finance');
      await tapIn(tester, 'feature-toggle-payments');
      expect(find.byKey(const Key('features-missing')), findsOneWidget);
      expect(db.orgConfig(DemoSeedV18.saburtalo).allowedModules, contains(OrgModule.payments));
    });
  });

  group('invitations', () {
    testWidgets('invited parent accepts on the admin web and gets the organization admin UI', (tester) async {
      final db = await bootAdmin(tester);
      await tapKey(tester, 'admin-demo-parent');
      expect(find.byKey(const Key('admin-denied')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('invitation-token-input')), DemoSeedV18.demoInviteToken);
      await tapKey(tester, 'invitation-accept');
      await pumpFrames(tester);
      expect(db.users[DemoIds.parent]!.administersClub(DemoSeedV18.saburtalo), isTrue);
      expect(find.byKey(const Key('admin-nav-/org-settings')), findsOneWidget);
      expect(find.byKey(const Key('admin-nav-/platform')), findsNothing);
      expectNoLayoutErrors();
    });
  });
}
