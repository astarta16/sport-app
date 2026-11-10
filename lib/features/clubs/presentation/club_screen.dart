import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../sports/presentation/sports_providers.dart';
import '../domain/club.dart';
import 'clubs_providers.dart';

/// Club page: info, venues, groups and the membership request flow.
class ClubScreen extends ConsumerWidget {
  const ClubScreen({super.key, required this.clubId});

  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final clubs = ref.watch(clubsProvider);
    final groups = ref.watch(clubGroupsProvider(clubId));
    final venues = (ref.watch(venuesProvider).value ?? const <Venue>[]).where((v) => v.clubId == clubId).toList();
    final sports = ref.watch(sportsByIdProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.clubDetails)),
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: AsyncView<List<Club>>(
          value: clubs,
          data: (list) {
            final club = list.where((c) => c.id == clubId).firstOrNull;
            if (club == null) return EmptyState(icon: Icons.search_off_rounded, title: l.errorNotFound);
            final sport = club.sportIds.isEmpty ? '' : club.sportIds.first;
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
              children: [
                AppCard(
                  gradient: SportVisuals.gradient(sport),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16)),
                            child: Icon(SportVisuals.icon(sport), color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(club.name, style: t.titleLarge?.copyWith(color: Colors.white)),
                          ),
                        ],
                      ),
                      if (club.description != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(club.description!, style: t.bodyMedium?.copyWith(color: Colors.white)),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 6,
                        children: [
                          for (final s in club.sportIds)
                            Chip(
                              label: Text(sports[s]?.name ?? s),
                              backgroundColor: Colors.white,
                              side: BorderSide.none,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.place_rounded),
                        title: Text(club.address),
                        trailing: IconButton.filledTonal(
                          tooltip: l.directions,
                          onPressed: () => openDirections(context, club.location, club.name),
                          icon: const Icon(Icons.directions_rounded),
                        ),
                      ),
                      if (club.phone != null)
                        ListTile(
                          leading: const Icon(Icons.call_rounded),
                          title: Text(club.phone!),
                          onTap: () => callPhone(club.phone!),
                        ),
                    ],
                  ),
                ),
                if (venues.isNotEmpty) ...[
                  SectionHeader(l.venueLabel),
                  for (final v in venues)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          leading: Icon(venueTypeIcon(v.type)),
                          title: Text(v.name),
                          subtitle: Text('${venueTypeLabel(context, v.type)} · ${v.address}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.directions_rounded),
                            onPressed: () => openDirections(context, v.location, v.name),
                          ),
                        ),
                      ),
                    ),
                ],
                SectionHeader(l.groupsLabel),
                AsyncView<List<Group>>(
                  value: groups,
                  compact: true,
                  loading: const SkeletonList(count: 2, padding: EdgeInsets.zero),
                  data: (gs) => gs.isEmpty
                      ? AppCard(
                          child: EmptyState(compact: true, icon: Icons.groups_outlined, title: l.noGroupsInClub),
                        )
                      : Column(
                          children: [
                            for (final g in gs)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                                child: _GroupRow(club: club, group: g),
                              ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GroupRow extends ConsumerWidget {
  const _GroupRow({required this.club, required this.group});

  final Club club;
  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    final requests = ref.watch(myMembershipRequestsProvider).value ?? const <MembershipRequest>[];
    final pending = requests.any((r) => r.groupId == group.id && r.status == RequestStatus.pending);
    return AppCard(
      child: Row(
        children: [
          SportBadge(sportKey: group.sportId, size: 42),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  [
                    l.ageRange(group.ageMin, group.ageMax),
                    if (group.scheduleNote != null) group.scheduleNote!,
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (pending)
            StatusPill(label: l.requestPending, color: AppColors.warning, dense: true)
          else if (user == null)
            Tooltip(message: l.signInToJoin, child: const Icon(Icons.lock_outline_rounded))
          else if (user.isParent)
            FilledButton.tonal(
              key: Key('join-${group.id}'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () => _request(context, ref),
              child: Text(l.requestMembership, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Future<void> _request(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final children = ref.read(myChildrenProvider).value ?? const <Child>[];
    if (children.isEmpty) {
      showAppSnack(context, l.noChildrenTitle, error: true);
      return;
    }
    final now = ref.read(clockProvider)();
    final child = await showAdaptiveSheet<Child>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(l.selectChild, style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final c in children)
              ListTile(
                key: Key('pick-child-${c.id}'),
                leading: InitialsAvatar(name: c.fullName, size: 40),
                title: Text(c.fullName),
                subtitle: Text(l.yearsOld(c.ageOn(now))),
                onTap: () => Navigator.pop(context, c),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (child == null || !context.mounted) return;
    await runGuarded(
      context,
      () => ref.read(clubsRepositoryProvider).requestMembership(childId: child.id, clubId: club.id, groupId: group.id),
      success: l.requestSent,
    );
  }
}
