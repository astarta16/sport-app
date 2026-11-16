import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/di.dart';
import '../core/l10n/l10n.dart';
import '../core/theme/app_theme.dart';
import '../features/authentication/presentation/session_providers.dart';
import '../features/clubs/presentation/clubs_providers.dart';
import '../features/authentication/presentation/splash_screen.dart';
import 'admin_app.dart';

/// Responsive admin layout: permanent sidebar on desktop (≥ 1000 px),
/// drawer on narrow windows.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final clubs = ref.watch(clubsByIdProvider);
    // v1.7: separate navigation. Platform pages (all tenants) are listed
    // only for the Super Admin; tenant pages work on the selected
    // organization (an organization admin only ever sees their own).
    final platform = <(String, IconData, String)>[
      (AdminRoutes.dashboard, Icons.space_dashboard_rounded, l.adminNavDashboard),
      (AdminRoutes.organizations, Icons.domain_rounded, l.adminNavOrganizations),
      (AdminRoutes.sports, Icons.category_rounded, l.adminNavSports),
      (AdminRoutes.coaches, Icons.sports_rounded, l.adminNavCoaches),
      (AdminRoutes.clubs, Icons.apartment_rounded, l.adminNavClubs),
      (AdminRoutes.admins, Icons.admin_panel_settings_rounded, l.adminNavAdmins),
      (AdminRoutes.moderation, Icons.flag_rounded, l.adminNavModeration),
      (AdminRoutes.audit, Icons.history_edu_rounded, l.adminNavAudit),
    ];
    final tenant = <(String, IconData, String)>[
      if (!user.isPlatformAdmin) (AdminRoutes.dashboard, Icons.space_dashboard_rounded, l.adminNavDashboard),
      (AdminRoutes.orgSettings, Icons.tune_rounded, l.adminNavOrgSettings),
      (AdminRoutes.programs, Icons.sports_handball_rounded, l.adminNavPrograms),
      (AdminRoutes.groups, Icons.groups_rounded, l.adminNavGroups),
      if (!user.isPlatformAdmin) (AdminRoutes.coaches, Icons.sports_rounded, l.adminNavCoaches),
      (AdminRoutes.rooms, Icons.meeting_room_rounded, l.adminNavRooms),
      (AdminRoutes.schedule, Icons.calendar_view_week_rounded, l.adminNavSchedule),
      (AdminRoutes.reports, Icons.assessment_rounded, l.adminNavReports),
      (AdminRoutes.attendance, Icons.fact_check_rounded, l.adminNavAttendance),
      (AdminRoutes.compliance, Icons.health_and_safety_rounded, l.adminNavCompliance),
      (AdminRoutes.plans, Icons.assignment_rounded, l.adminNavPlans),
      (AdminRoutes.payments, Icons.receipt_long_rounded, l.adminNavPayments),
      (AdminRoutes.mediaDownloads, Icons.download_for_offline_rounded, l.adminNavMediaDownloads),
      if (!user.isPlatformAdmin) (AdminRoutes.clubs, Icons.apartment_rounded, l.adminNavClubs),
      if (!user.isPlatformAdmin) (AdminRoutes.sports, Icons.category_rounded, l.adminNavSports),
      if (!user.isPlatformAdmin) (AdminRoutes.moderation, Icons.flag_rounded, l.adminNavModeration),
      if (!user.isPlatformAdmin) (AdminRoutes.audit, Icons.history_edu_rounded, l.adminNavAudit),
    ];
    final items = <(String, IconData, String)>[
      if (user.isPlatformAdmin) ...platform,
      ...tenant,
      (AdminRoutes.settings, Icons.settings_rounded, l.adminNavSettings),
    ];
    final headers = <int, String>{
      if (user.isPlatformAdmin) 0: l.adminNavSectionPlatform,
      (user.isPlatformAdmin ? platform.length : 0): l.adminNavSectionTenant,
    };
    final selected = items.indexWhere((i) => i.$1 == location).clamp(0, items.length - 1);
    final scope = user.isPlatformAdmin
        ? l.adminRolePlatform
        : '${l.adminRoleClub} · ${user.adminClubIds.map((c) => clubs[c]?.name ?? c).join(', ')}';
    Widget nav({required bool drawer}) => Material(
      color: AppColors.navy,
      child: SizedBox(
        width: 260,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    const BrandMark(size: 36),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l.adminTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                // A short list: built eagerly so every entry is reachable.
                child: SingleChildScrollView(
                  key: const Key('admin-nav-list'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (headers[i] != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 2),
                            child: Text(
                              headers[i]!.toUpperCase(),
                              key: Key('admin-nav-header-$i'),
                              style: const TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.2),
                            ),
                          ),
                        ListTile(
                          dense: true,
                          key: Key('admin-nav-${items[i].$1}'),
                          selected: i == selected,
                          selectedTileColor: Colors.white.withValues(alpha: 0.08),
                          leading: Icon(items[i].$2, color: i == selected ? AppColors.volt : Colors.white70),
                          title: Text(
                            items[i].$3,
                            style: TextStyle(color: i == selected ? Colors.white : Colors.white70),
                          ),
                          onTap: () {
                            if (drawer) Navigator.of(context).pop();
                            context.go(items[i].$1);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      scope,
                      key: const Key('admin-scope'),
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextButton.icon(
                      key: const Key('admin-sign-out'),
                      onPressed: () => ref.read(authRepositoryProvider).signOut(),
                      icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                      label: Text(l.signOut, style: const TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1000;
        return Scaffold(
          appBar: wide ? null : AppBar(title: Text(items[selected].$3)),
          drawer: wide ? null : Drawer(child: nav(drawer: true)),
          body: Row(
            children: [
              if (wide) nav(drawer: false),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
