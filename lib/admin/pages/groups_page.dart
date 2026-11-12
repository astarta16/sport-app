import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../features/admin/domain/admin_models.dart';
import '../../features/clubs/presentation/clubs_providers.dart';
import '../../features/groups/domain/group.dart';
import '../widgets.dart';
import 'admin_providers.dart';
import 'v13_pages.dart';

/// Group oversight: sizes, coaches, schedules, pending requests — never
/// the identities of the children (data minimisation).
class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final groups = ref.watch(adminGroupsProvider);
    final clubs = ref.watch(clubsByIdProvider);
    return AdminSection(
      title: l.adminNavGroups,
      subtitle: l.adminChildDataNote,
      child: AsyncView<List<GroupOverview>>(
        value: groups,
        data: (list) => AdminTable<GroupOverview>(
          rows: list,
          searchText: (g) => '${g.group.name} ${clubs[g.group.clubId]?.name ?? ''} ${g.coachNames.join(' ')}',
          filters: [
            (l.adminFilterAll, (_) => true),
            (l.adminColRequests, (g) => g.pendingRequests > 0),
            (l.adminArchived, (g) => !g.group.isActive),
          ],
          columns: [
            AdminColumn(
              l.adminColName,
              (g) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.group.name,
                    key: Key('group-row-${g.group.id}'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(clubs[g.group.clubId]?.name ?? '', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              flex: 3,
              sortKey: (g) => g.group.name,
            ),
            AdminColumn(l.adminColCoach, (g) => Text(g.coachNames.isEmpty ? '—' : g.coachNames.join(', ')), flex: 2),
            AdminColumn(l.adminColMembers, (g) => Text('${g.memberCount}'), sortKey: (g) => g.memberCount),
            AdminColumn(l.adminColSchedule, (g) => Text(g.scheduleSummary), flex: 2),
            AdminColumn(l.adminColRequests, (g) => Text('${g.pendingRequests}'), sortKey: (g) => g.pendingRequests),
            AdminColumn(l.adminColUpcoming, (g) => Text('${g.upcomingTrainings}')),
            AdminColumn(
              l.adminColActions,
              (g) => Row(
                children: [
                  if (!g.group.isActive) StatusPill(label: l.adminArchived, color: AppColors.neutral, dense: true),
                  IconButton(
                    key: Key('reviewers-${g.group.id}'),
                    tooltip: l.adminSetReviewers,
                    onPressed: () => showReviewersDialog(context, ref, g),
                    icon: Badge(
                      isLabelVisible: g.group.paymentManagerIds.isNotEmpty,
                      label: Text('${g.group.paymentManagerIds.length}'),
                      child: const Icon(Icons.price_check_rounded),
                    ),
                  ),
                  Tooltip(
                    message: l.adminMediaPolicy,
                    child: Switch(
                      key: Key('media-policy-${g.group.id}'),
                      value: g.group.mediaDownloadsEnabled,
                      onChanged: (v) => runGuarded(
                        context,
                        () => ref.read(adminRepositoryProvider).setMediaDownloads(g.group.id, enabled: v),
                        success: l.adminSaved,
                      ),
                    ),
                  ),
                  IconButton(
                    key: Key('archive-group-${g.group.id}'),
                    tooltip: g.group.isActive ? l.adminArchive : l.adminRestore,
                    onPressed: () => runGuarded(
                      context,
                      () => ref
                          .read(adminRepositoryProvider)
                          .archiveGroup(g.group.id, archived: g.group.status == GroupStatus.active),
                      success: l.adminSaved,
                    ),
                    icon: Icon(g.group.isActive ? Icons.archive_rounded : Icons.unarchive_rounded),
                  ),
                ],
              ),
              flex: 2,
            ),
          ],
        ),
      ),
    );
  }
}
