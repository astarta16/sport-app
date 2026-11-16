import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/settings.dart';
import '../core/l10n/l10n.dart';
import '../core/theme/app_theme.dart';
import '../features/authentication/domain/app_user.dart';
import '../features/authentication/presentation/session_providers.dart';
import 'admin_shell.dart';
import 'pages/admin_login_page.dart';
import 'pages/audit_page.dart';
import 'pages/clubs_page.dart';
import 'pages/coaches_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/groups_page.dart';
import 'pages/moderation_page.dart';
import 'pages/admins_page.dart';
import 'pages/sports_page.dart';
import 'pages/v13_pages.dart';
import 'pages/v14_pages.dart';
import 'pages/v17_pages.dart';

class AdminRoutes {
  AdminRoutes._();

  static const login = '/login';
  static const denied = '/denied';
  static const dashboard = '/';
  static const coaches = '/coaches';
  static const clubs = '/clubs';
  static const sports = '/sports';
  static const groups = '/groups';
  static const moderation = '/moderation';
  static const audit = '/audit';
  static const admins = '/admins';
  static const compliance = '/compliance';
  static const attendance = '/attendance';
  static const plans = '/plans';
  static const payments = '/payments';
  static const settings = '/settings';
  static const mediaDownloads = '/media-downloads';

  // v1.7 multi-tenant administration.
  static const organizations = '/organizations';
  static const orgSettings = '/org-settings';
  static const programs = '/programs';
  static const rooms = '/rooms';
  static const schedule = '/schedule';
  static const reports = '/reports';

  /// Pages a club admin may not open (platform scope only).
  static const platformOnly = {admins, organizations};
}

/// Pure guard, unit-tested in test/admin/admin_redirect_test.dart. Hiding
/// navigation is not the security boundary — the repositories/callables
/// re-check the role — but non-admins never get the admin UI at all.
String? resolveAdminRedirect({required String location, required AsyncValue<AuthSession?> session}) {
  if (session is AsyncLoading && !session.hasValue) return null;
  final user = session.value?.user;
  if (user == null) return location == AdminRoutes.login ? null : AdminRoutes.login;
  if (!user.isAdmin) return location == AdminRoutes.denied ? null : AdminRoutes.denied;
  if (location == AdminRoutes.login || location == AdminRoutes.denied) return AdminRoutes.dashboard;
  if (AdminRoutes.platformOnly.contains(location) && !user.isPlatformAdmin) return AdminRoutes.dashboard;
  return null;
}

final adminRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authSessionProvider, (_, _) => refresh.value++);
  NoTransitionPage<void> page(Widget child) => NoTransitionPage(child: child);
  final router = GoRouter(
    initialLocation: AdminRoutes.dashboard,
    refreshListenable: refresh,
    redirect: (_, state) =>
        resolveAdminRedirect(location: state.matchedLocation, session: ref.read(authSessionProvider)),
    routes: [
      GoRoute(path: AdminRoutes.login, builder: (_, _) => const AdminLoginPage()),
      GoRoute(path: AdminRoutes.denied, builder: (_, _) => const AdminDeniedPage()),
      ShellRoute(
        builder: (_, state, child) => AdminShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: AdminRoutes.dashboard, pageBuilder: (_, _) => page(const DashboardPage())),
          GoRoute(path: AdminRoutes.coaches, pageBuilder: (_, _) => page(const CoachesPage())),
          GoRoute(path: AdminRoutes.clubs, pageBuilder: (_, _) => page(const ClubsPage())),
          GoRoute(path: AdminRoutes.sports, pageBuilder: (_, _) => page(const SportsPage())),
          GoRoute(path: AdminRoutes.groups, pageBuilder: (_, _) => page(const GroupsPage())),
          GoRoute(path: AdminRoutes.moderation, pageBuilder: (_, _) => page(const ModerationPage())),
          GoRoute(path: AdminRoutes.audit, pageBuilder: (_, _) => page(const AuditPage())),
          GoRoute(path: AdminRoutes.admins, pageBuilder: (_, _) => page(const AdminsPage())),
          GoRoute(path: AdminRoutes.compliance, pageBuilder: (_, _) => page(const CompliancePage())),
          GoRoute(path: AdminRoutes.attendance, pageBuilder: (_, _) => page(const AttendanceReportPage())),
          GoRoute(path: AdminRoutes.plans, pageBuilder: (_, _) => page(const PlansOversightPage())),
          GoRoute(path: AdminRoutes.payments, pageBuilder: (_, _) => page(const PaymentQueuePage())),
          GoRoute(path: AdminRoutes.mediaDownloads, pageBuilder: (_, _) => page(const MediaDownloadsPage())),
          GoRoute(path: AdminRoutes.settings, pageBuilder: (_, _) => page(const AdminSettingsPage())),
          GoRoute(path: AdminRoutes.organizations, pageBuilder: (_, _) => page(const OrganizationsPage())),
          GoRoute(path: AdminRoutes.orgSettings, pageBuilder: (_, _) => page(const OrgSettingsPage())),
          GoRoute(path: AdminRoutes.programs, pageBuilder: (_, _) => page(const ProgramsPage())),
          GoRoute(path: AdminRoutes.rooms, pageBuilder: (_, _) => page(const RoomsPage())),
          GoRoute(path: AdminRoutes.schedule, pageBuilder: (_, _) => page(const SchedulePage())),
          GoRoute(path: AdminRoutes.reports, pageBuilder: (_, _) => page(const OrgReportsPage())),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.adminTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(adminRouterProvider),
    );
  }
}

String adminRoleLabel(BuildContext context, AppUser u) =>
    u.isPlatformAdmin ? context.l10n.adminRolePlatform : context.l10n.adminRoleClub;
