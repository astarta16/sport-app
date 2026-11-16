import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../features/admin/domain/admin_models.dart';
import '../admin_app.dart';
import '../widgets.dart';
import 'admin_providers.dart';
import 'v191_setup_checklist.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final stats = ref.watch(adminStatsProvider);
    return AdminSection(
      title: l.adminNavDashboard,
      subtitle: l.adminChildDataNote,
      child: AsyncView<AdminStats>(
        value: stats,
        onRetry: () => ref.invalidate(adminStatsProvider),
        data: (s) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // v1.9.1: first-time setup from saved data (hidden when complete).
            const OrgSetupChecklist(),
            ResponsiveGrid(
              key: const Key('admin-stats'),
              minItemWidth: 200,
              maxColumns: 5,
              children: [
                StatCard(label: l.adminStatParents, value: s.parents, icon: Icons.family_restroom_rounded),
                StatCard(label: l.adminStatChildren, value: s.children, icon: Icons.child_care_rounded),
                StatCard(label: l.adminStatCoaches, value: s.coaches, icon: Icons.sports_rounded),
                StatCard(label: l.adminStatClubs, value: s.clubs, icon: Icons.apartment_rounded),
                StatCard(label: l.adminStatGroups, value: s.activeGroups, icon: Icons.groups_rounded),
                StatCard(label: l.adminStatTrainings, value: s.upcomingTrainings, icon: Icons.event_rounded),
                StatCard(label: l.adminStatMatches, value: s.upcomingMatches, icon: Icons.emoji_events_rounded),
              ],
            ),
            SectionHeader(l.adminNeedsAttention),
            ResponsiveGrid(
              minItemWidth: 240,
              maxColumns: 3,
              children: [
                InkWell(
                  key: const Key('admin-attn-coaches'),
                  onTap: () => context.go(AdminRoutes.coaches),
                  child: StatCard(
                    label: l.adminStatPendingCoaches,
                    value: s.pendingCoaches,
                    icon: Icons.how_to_reg_rounded,
                    highlight: true,
                  ),
                ),
                InkWell(
                  onTap: () => context.go(AdminRoutes.groups),
                  child: StatCard(
                    label: l.adminStatPendingRequests,
                    value: s.pendingRequests,
                    icon: Icons.person_add_rounded,
                    highlight: true,
                  ),
                ),
                InkWell(
                  key: const Key('admin-attn-reports'),
                  onTap: () => context.go(AdminRoutes.moderation),
                  child: StatCard(
                    label: l.adminStatReports,
                    value: s.openReports,
                    icon: Icons.flag_rounded,
                    highlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            DemoBanner(text: l.adminChildDataNote),
          ],
        ),
      ),
    );
  }
}
