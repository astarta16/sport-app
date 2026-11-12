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
    final items = <(String, IconData, String)>[
      (AdminRoutes.dashboard, Icons.space_dashboard_rounded, l.adminNavDashboard),
      (AdminRoutes.coaches, Icons.sports_rounded, l.adminNavCoaches),
      (AdminRoutes.clubs, Icons.apartment_rounded, l.adminNavClubs),
      (AdminRoutes.sports, Icons.category_rounded, l.adminNavSports),
      (AdminRoutes.groups, Icons.groups_rounded, l.adminNavGroups),
      (AdminRoutes.compliance, Icons.health_and_safety_rounded, l.adminNavCompliance),
      (AdminRoutes.attendance, Icons.fact_check_rounded, l.adminNavAttendance),
      (AdminRoutes.plans, Icons.assignment_rounded, l.adminNavPlans),
      (AdminRoutes.payments, Icons.receipt_long_rounded, l.adminNavPayments),
      (AdminRoutes.mediaDownloads, Icons.download_for_offline_rounded, l.adminNavMediaDownloads),
      (AdminRoutes.moderation, Icons.flag_rounded, l.adminNavModeration),
      (AdminRoutes.audit, Icons.history_edu_rounded, l.adminNavAudit),
      if (user.isPlatformAdmin) (AdminRoutes.admins, Icons.admin_panel_settings_rounded, l.adminNavAdmins),
      (AdminRoutes.settings, Icons.settings_rounded, l.adminNavSettings),
    ];
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
                child: ListView(
                  key: const Key('admin-nav-list'),
                  padding: EdgeInsets.zero,
                  children: [
                    for (var i = 0; i < items.length; i++)
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
