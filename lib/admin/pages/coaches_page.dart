import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_widgets.dart';
import '../../features/admin/domain/admin_models.dart';
import '../../features/authentication/domain/app_user.dart';
import '../../features/authentication/presentation/session_providers.dart';
import '../../features/clubs/presentation/clubs_providers.dart';
import '../../features/sports/presentation/sports_providers.dart';
import '../widgets.dart';
import '../../features/sports/presentation/sport_label.dart';
import 'admin_providers.dart';

String coachStatusLabel(BuildContext context, CoachStatus s) {
  final l = context.l10n;
  return switch (s) {
    CoachStatus.pending => l.adminCoachStatusPending,
    CoachStatus.approved => l.adminCoachStatusApproved,
    CoachStatus.rejected => l.adminCoachStatusRejected,
    CoachStatus.suspended => l.adminCoachStatusSuspended,
    CoachStatus.revoked => l.adminCoachStatusRevoked,
  };
}

Color coachStatusColor(CoachStatus s) => switch (s) {
  CoachStatus.pending => AppColors.warning,
  CoachStatus.approved => AppColors.success,
  CoachStatus.rejected || CoachStatus.revoked => AppColors.danger,
  CoachStatus.suspended => AppColors.neutral,
};

/// Coach verification: approve, reject (reason), suspend (reason), revoke
/// (reason), reinstate, club assignment. Every decision is audited
/// server-side; club admins only see coaches of their clubs.
class CoachesPage extends ConsumerWidget {
  const CoachesPage({super.key});

  Future<void> _set(
    BuildContext context,
    WidgetRef ref,
    CoachSummary c,
    CoachStatus status, {
    bool reason = false,
  }) async {
    final l = context.l10n;
    String? r;
    if (reason) {
      r = await askReason(context, title: coachStatusLabel(context, status));
      if (r == null) return;
    }
    if (!context.mounted) return;
    await runGuarded(
      context,
      () => ref.read(adminRepositoryProvider).setCoachStatus(c.id, status, reason: r),
      success: l.adminCoachUpdated,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final coaches = ref.watch(adminCoachesProvider);
    final clubs = ref.watch(clubsByIdProvider);
    final sports = ref.watch(sportsByIdProvider);
    final me = ref.watch(currentUserProvider);
    final f = Fmt.of(context);
    return AdminSection(
      title: l.adminNavCoaches,
      child: AsyncView<List<CoachSummary>>(
        value: coaches,
        data: (list) => AdminTable<CoachSummary>(
          rows: list,
          searchText: (c) => '${c.fullName} ${c.phone}',
          filters: [
            (l.adminFilterAll, (_) => true),
            for (final s in CoachStatus.values) (coachStatusLabel(context, s), (c) => c.status == s),
          ],
          columns: [
            AdminColumn(
              l.adminColName,
              (c) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.fullName,
                    key: Key('coach-row-${c.id}'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(Validators.formatPhone(c.phone), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              flex: 3,
              sortKey: (c) => c.fullName,
            ),
            AdminColumn(
              l.adminColStatus,
              (c) => Align(
                alignment: Alignment.centerLeft,
                child: Tooltip(
                  message: c.reason ?? '',
                  child: StatusPill(
                    label: coachStatusLabel(context, c.status),
                    color: coachStatusColor(c.status),
                    dense: true,
                  ),
                ),
              ),
              flex: 2,
              sortKey: (c) => c.status.index,
            ),
            AdminColumn(l.adminColClubs, (c) => Text(c.clubIds.map((id) => clubs[id]?.name ?? id).join(', ')), flex: 3),
            AdminColumn(
              l.adminColSports,
              (c) => Text(c.sportIds.map((id) => sports[id]?.label(context) ?? id).join(', ')),
              flex: 2,
            ),
            AdminColumn(l.adminColGroups, (c) => Text('${c.groupCount}')),
            AdminColumn(
              l.adminColApplied,
              (c) => Text(f.numericDate(c.createdAt)),
              flex: 2,
              sortKey: (c) => c.createdAt,
            ),
            AdminColumn(
              l.adminColActions,
              (c) => Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (c.status == CoachStatus.pending) ...[
                    FilledButton(
                      key: Key('approve-${c.id}'),
                      onPressed: () => _set(context, ref, c, CoachStatus.approved),
                      child: Text(l.adminApprove),
                    ),
                    OutlinedButton(
                      key: Key('reject-${c.id}'),
                      onPressed: () => _set(context, ref, c, CoachStatus.rejected, reason: true),
                      child: Text(l.adminReject),
                    ),
                  ],
                  if (c.status == CoachStatus.approved) ...[
                    OutlinedButton(
                      key: Key('suspend-${c.id}'),
                      onPressed: () => _set(context, ref, c, CoachStatus.suspended, reason: true),
                      child: Text(l.adminSuspend),
                    ),
                    TextButton(
                      key: Key('revoke-${c.id}'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                      onPressed: () => _set(context, ref, c, CoachStatus.revoked, reason: true),
                      child: Text(l.adminRevoke),
                    ),
                  ],
                  if (c.status == CoachStatus.suspended || c.status == CoachStatus.rejected)
                    OutlinedButton(
                      key: Key('reinstate-${c.id}'),
                      onPressed: () => _set(context, ref, c, CoachStatus.approved),
                      child: Text(l.adminReinstate),
                    ),
                  if (me != null && me.isAdmin)
                    PopupMenuButton<String>(
                      tooltip: l.adminAssignClub,
                      icon: const Icon(Icons.apartment_rounded),
                      itemBuilder: (_) => [
                        for (final club in clubs.values.where((x) => me.administersClub(x.id)))
                          PopupMenuItem(
                            value: club.id,
                            child: Text(
                              '${c.clubIds.contains(club.id) ? l.adminUnassignClub : l.adminAssignClub}: ${club.name}',
                            ),
                          ),
                      ],
                      onSelected: (clubId) => runGuarded(
                        context,
                        () => ref
                            .read(adminRepositoryProvider)
                            .assignCoach(clubId: clubId, coachId: c.id, assign: !c.clubIds.contains(clubId)),
                        success: l.adminSaved,
                      ),
                    ),
                ],
              ),
              flex: 4,
            ),
          ],
        ),
      ),
    );
  }
}
