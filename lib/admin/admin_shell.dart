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
import 'pages/v17_pages.dart';
import '../features/organizations/presentation/org_providers.dart';
import '../features/organizations/domain/organization.dart';

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
    // v1.9: task-based sections. The Platform context (all tenants) is
    // only for the Super Admin and is visually separated from the
    // Organization context, which always works on ONE selected
    // organization. Organization pages whose feature is off for that
    // organization are not listed (and their routes show a feature-off
    // state instead of an empty or broken page).
    final orgId = ref.watch(adminOrgProvider);
    final cfg = orgId == null ? null : ref.watch(orgConfigProvider(orgId)).value;
    bool on(OrgModule? m) => m == null || cfg == null || cfg.isEnabled(m, now: DateTime.now());
    final sections = <(String?, List<AdminNavItem>)>[
      if (user.isPlatformAdmin) ...[
        (
          l.adminNavSectionPlatform,
          [
            AdminNavItem(AdminRoutes.platform, Icons.insights_rounded, l.adminNavOverview),
            AdminNavItem(AdminRoutes.organizations, Icons.domain_rounded, l.adminNavOrganizations),
            AdminNavItem(AdminRoutes.templates, Icons.copy_all_rounded, l.adminNavTemplates),
            AdminNavItem(AdminRoutes.features, Icons.toggle_on_rounded, l.adminNavFeatureCatalog),
            AdminNavItem(AdminRoutes.packages, Icons.inventory_2_rounded, l.adminNavPackages),
            AdminNavItem(AdminRoutes.subscriptions, Icons.card_membership_rounded, l.subscriptionsTitle),
            AdminNavItem(AdminRoutes.invitations, Icons.mail_rounded, l.adminNavInvitations),
            AdminNavItem(AdminRoutes.health, Icons.monitor_heart_rounded, l.adminNavHealth),
            AdminNavItem(AdminRoutes.audit, Icons.history_edu_rounded, l.adminNavAudit),
            AdminNavItem(AdminRoutes.admins, Icons.admin_panel_settings_rounded, l.adminNavPlatformUsers),
          ],
        ),
        (
          l.adminNavSecCatalog,
          [
            AdminNavItem(AdminRoutes.dashboard, Icons.space_dashboard_rounded, l.adminNavActivity),
            AdminNavItem(AdminRoutes.sports, Icons.category_rounded, l.adminNavSports),
            AdminNavItem(AdminRoutes.coaches, Icons.sports_rounded, l.adminNavCoaches),
            AdminNavItem(AdminRoutes.clubs, Icons.apartment_rounded, l.adminNavClubs),
            AdminNavItem(AdminRoutes.moderation, Icons.flag_rounded, l.adminNavModeration),
          ],
        ),
      ],
      if (!user.isPlatformAdmin)
        (null, [AdminNavItem(AdminRoutes.dashboard, Icons.space_dashboard_rounded, l.adminNavDashboard)]),
      (
        l.adminNavSecPeople,
        [
          AdminNavItem(AdminRoutes.members, Icons.people_alt_rounded, l.adminNavMembers),
          if (!user.isPlatformAdmin) AdminNavItem(AdminRoutes.coaches, Icons.sports_rounded, l.adminNavCoaches),
        ],
      ),
      (
        l.adminNavSecPrograms,
        [
          AdminNavItem(AdminRoutes.programs, Icons.sports_handball_rounded, l.adminNavPrograms),
          AdminNavItem(AdminRoutes.groups, Icons.groups_rounded, l.adminNavGroups),
          AdminNavItem(AdminRoutes.plans, Icons.assignment_rounded, l.adminNavPlans, OrgModule.trainingPlans),
          if (!user.isPlatformAdmin) AdminNavItem(AdminRoutes.sports, Icons.category_rounded, l.adminNavSports),
        ],
      ),
      (
        l.adminNavSecCalendar,
        [
          AdminNavItem(
            AdminRoutes.schedule,
            Icons.calendar_view_week_rounded,
            l.adminNavSchedule,
            OrgModule.roomScheduling,
          ),
          AdminNavItem(AdminRoutes.rooms, Icons.meeting_room_rounded, l.adminNavRooms, OrgModule.facilities),
          AdminNavItem(AdminRoutes.attendance, Icons.fact_check_rounded, l.adminNavAttendance, OrgModule.attendance),
          AdminNavItem(
            AdminRoutes.compliance,
            Icons.health_and_safety_rounded,
            l.adminNavCompliance,
            OrgModule.medicalCertificates,
          ),
        ],
      ),
      (
        l.adminNavSecCommunication,
        [
          if (!user.isPlatformAdmin)
            AdminNavItem(AdminRoutes.moderation, Icons.flag_rounded, l.adminNavModeration, OrgModule.communication),
          AdminNavItem(
            AdminRoutes.mediaDownloads,
            Icons.download_for_offline_rounded,
            l.adminNavMediaDownloads,
            OrgModule.media,
          ),
        ],
      ),
      (
        l.adminNavSecFinanceReports,
        [
          AdminNavItem(AdminRoutes.payments, Icons.receipt_long_rounded, l.adminNavPayments, OrgModule.payments),
          AdminNavItem(AdminRoutes.reports, Icons.assessment_rounded, l.adminNavReports, OrgModule.reports),
          if (!user.isPlatformAdmin) AdminNavItem(AdminRoutes.audit, Icons.history_edu_rounded, l.adminNavAudit),
        ],
      ),
      (
        l.adminNavSecOrganization,
        [
          AdminNavItem(AdminRoutes.orgSettings, Icons.tune_rounded, l.adminNavOrgSettings),
          if (!user.isPlatformAdmin) AdminNavItem(AdminRoutes.clubs, Icons.apartment_rounded, l.adminNavClubs),
          AdminNavItem(AdminRoutes.settings, Icons.settings_rounded, l.adminNavSettings),
        ],
      ),
    ];
    final visible = [
      for (final (h, list) in sections)
        if (list.any((i) => on(i.module)))
          (
            h,
            [
              for (final i in list)
                if (on(i.module)) i,
            ],
          ),
    ];
    final items = [for (final (_, list) in visible) ...list];
    // Header index → title; the organization switcher sits above the first
    // organization section.
    final headers = <int, String>{};
    var n = 0;
    var orgSectionStart = -1;
    for (final (h, list) in visible) {
      if (h != null) headers[n] = h;
      if (orgSectionStart < 0 &&
          list.any(
            (i) => i.route == AdminRoutes.members || i.route == AdminRoutes.dashboard && !user.isPlatformAdmin,
          )) {
        orgSectionStart = n;
      }
      n += list.length;
    }
    final selected = items.indexWhere(
      (i) =>
          i.route == location ||
          (i.route == AdminRoutes.organizations && location.startsWith('${AdminRoutes.organizations}/')),
    );
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
                        if (i == orgSectionStart && orgId != null) AdminOrgSwitcherTile(orgId: orgId, drawer: drawer),
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
                          key: Key('admin-nav-${items[i].route}'),
                          selected: i == selected,
                          selectedTileColor: Colors.white.withValues(alpha: 0.08),
                          leading: Icon(items[i].icon, color: i == selected ? AppColors.volt : Colors.white70),
                          title: Text(
                            items[i].label,
                            style: TextStyle(color: i == selected ? Colors.white : Colors.white70),
                          ),
                          onTap: () {
                            if (drawer) Navigator.of(context).pop();
                            context.go(items[i].route);
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
          appBar: wide ? null : AppBar(title: Text(selected < 0 ? l.adminTitle : items[selected].label)),
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

class AdminNavItem {
  const AdminNavItem(this.route, this.icon, this.label, [this.module]);

  final String route;
  final IconData icon;
  final String label;

  /// Feature the page belongs to; hidden when it is off for the selected
  /// organization.
  final OrgModule? module;
}

/// Sidebar block that names the organization every page below works on
/// and switches it through a searchable picker (Super Admin: all
/// organizations; organization admin: their own).
class AdminOrgSwitcherTile extends ConsumerWidget {
  const AdminOrgSwitcherTile({super.key, required this.orgId, required this.drawer});

  final String orgId;
  final bool drawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ids = ref.watch(adminOrgIdsProvider);
    final cfg = ref.watch(orgConfigProvider(orgId)).value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.sm, AppSpacing.xs),
      child: Material(
        color: Colors.white.withValues(alpha: .06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          side: const BorderSide(color: Colors.white24),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          key: const Key('admin-org-switcher'),
          dense: true,
          leading: CircleAvatar(radius: 12, backgroundColor: Color(cfg?.branding.primaryColor ?? 0xFF2F6BFF)),
          title: Text(
            orgName(context, ref, orgId),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          subtitle: Text(l.adminOrgContext, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          trailing: ids.length > 1 ? const Icon(Icons.unfold_more_rounded, color: Colors.white70) : null,
          onTap: ids.length < 2 ? null : () => pickAdminOrg(context, ref),
        ),
      ),
    );
  }
}
