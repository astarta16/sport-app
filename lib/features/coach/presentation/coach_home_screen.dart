import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../calendar/domain/calendar_logic.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../../clubs/domain/club.dart';
import '../../clubs/presentation/clubs_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../medical_certificates/domain/medical_certificate.dart';
import '../../medical_certificates/presentation/certificates_providers.dart';
import '../../notifications/presentation/notifications_providers.dart';
import '../../parent/presentation/parent_context.dart';
import '../../trainings/domain/training.dart';
import '../../trainings/presentation/training_widgets.dart';
import '../../trainings/presentation/trainings_providers.dart';
import 'coach_context.dart';

/// Coach dashboard (spec §6.2): group selection, roster with certificate
/// status, trainings and quick actions.
class CoachHomeScreen extends ConsumerWidget {
  const CoachHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    final groups = ref.watch(myGroupsProvider);
    final selected = ref.watch(coachSelectedGroupProvider);
    final unread = ref.watch(unreadCountProvider);
    final group = selected.value;
    final showGroupPanel = context.windowSize == WindowSize.large && (groups.value?.length ?? 0) > 1;
    return Scaffold(
      floatingActionButton: group == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('new-training-fab'),
              onPressed: () => context.push(Routes.newTraining(group.id)),
              icon: const Icon(Icons.add_rounded),
              label: Text(l.newTraining),
            ),
      body: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showGroupPanel) ...[
              SizedBox(
                width: 300,
                child: _GroupListPanel(groups: groups.value!, selectedId: group?.id),
              ),
              VerticalDivider(width: 1, color: Theme.of(context).colorScheme.outline),
            ],
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.coachHomeSubtitle.toUpperCase(),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l.greetingDay(user?.firstName ?? ''),
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: l.notificationsTitle,
                            onPressed: () => context.push(Routes.notifications),
                            icon: Badge(
                              isLabelVisible: unread > 0,
                              label: Text('$unread'),
                              child: const Icon(Icons.notifications_none_rounded, size: 28),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!showGroupPanel)
                    SliverToBoxAdapter(
                      child: AsyncView<List<Group>>(
                        value: groups,
                        loading: const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Skeleton(height: 48)),
                        data: (list) => list.isEmpty
                            ? const SizedBox.shrink()
                            : SizedBox(
                                height: 60,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                                  children: [
                                    for (final g in list)
                                      Padding(
                                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                                        child: ChoiceChip(
                                          key: Key('group-chip-${g.id}'),
                                          avatar: Icon(
                                            SportVisuals.icon(g.sportId),
                                            size: 18,
                                            color: SportVisuals.color(g.sportId),
                                          ),
                                          label: Text(g.name),
                                          selected: g.id == group?.id,
                                          onSelected: (_) =>
                                              ref.read(selectionContextProvider.notifier).selectGroup(g.id),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  if (groups.hasValue && (groups.value?.isEmpty ?? true))
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(icon: Icons.groups_rounded, title: l.noGroupsCoach),
                    )
                  else if (group != null)
                    SliverConstrained(
                      maxWidth: Breakpoints.dashboard,
                      minPadding: context.pagePadding,
                      sliver: SliverPadding(
                        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 100),
                        sliver: SliverToBoxAdapter(child: _GroupDashboard(group: group)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Master list of groups (large windows): the dashboard is the detail pane.
class _GroupListPanel extends ConsumerWidget {
  const _GroupListPanel({required this.groups, required this.selectedId});

  final List<Group> groups;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final clubs = ref.watch(clubsByIdProvider);
    return ListView(
      key: const Key('coach-group-panel'),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
          child: Text(l.groupsLabel, style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final g in groups)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Material(
              color: g.id == selectedId ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: ListTile(
                key: Key('group-tile-${g.id}'),
                selected: g.id == selectedId,
                leading: SportBadge(sportKey: g.sportId, size: 40),
                title: Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${clubs[g.clubId]?.name ?? ''} · ${l.groupMembers(g.memberChildIds.length)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => ref.read(selectionContextProvider.notifier).selectGroup(g.id),
              ),
            ),
          ),
      ],
    );
  }
}

/// Group dashboard. Phone: the original single column. Tablet: two columns
/// (overview + schedule | quick actions, requests, roster).
class _GroupDashboard extends StatelessWidget {
  const _GroupDashboard({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rosterHeader = SectionHeader(
      l.roster,
      actionLabel: l.seeAll,
      onAction: () => context.push(Routes.roster(group.id)),
    );
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < Breakpoints.expanded - 80) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GroupOverview(group: group),
              const _IncomingRequests(),
              SectionHeader(l.todayTrainings),
              _UpcomingTrainings(group: group),
              rosterHeader,
              _RosterPreview(group: group),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GroupOverview(group: group),
                  SectionHeader(l.todayTrainings),
                  _UpcomingTrainings(group: group, limit: 6),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _QuickActions(group: group),
                  const _IncomingRequests(),
                  rosterHeader,
                  _RosterPreview(group: group, limit: 10),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final actions = [
      (Icons.add_circle_rounded, l.newTraining, Routes.newTraining(group.id), const Key('qa-new-training')),
      (Icons.chat_bubble_rounded, l.navChat, Routes.chat(group.id), const Key('qa-chat')),
      (Icons.groups_rounded, l.roster, Routes.roster(group.id), const Key('qa-roster')),
      (Icons.payments_rounded, l.paymentsTitle, Routes.groupPayments(group.id), const Key('qa-payments')),
    ];
    return AppCard(
      key: const Key('coach-quick-actions'),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final (icon, label, route, key) in actions)
            ActionChip(
              key: key,
              avatar: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
              label: Text(label),
              onPressed: () => context.push(route),
            ),
        ],
      ),
    );
  }
}

class _GroupOverview extends ConsumerWidget {
  const _GroupOverview({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final now = ref.watch(clockProvider)();
    final trainings = (ref.watch(myTrainingsProvider).value ?? const <Training>[]).where((x) => x.groupId == group.id);
    final certs = ref.watch(certificatesForChildrenProvider(childrenKey(group.memberChildIds))).value ?? const [];
    final alerts = group.memberChildIds.where((id) {
      final s = CertificatePolicy.childStatus(certs.where((c) => c.childId == id), now);
      return s != CertificateStatus.valid;
    }).length;
    final club = ref.watch(clubsByIdProvider)[group.clubId];
    return AppCard(
      gradient: SportVisuals.gradient(group.sportId),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(SportVisuals.icon(group.sportId), color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(group.name, style: t.titleLarge?.copyWith(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${club?.name ?? ''} · ${l.ageRange(group.ageMin, group.ageMax)}',
            style: t.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Stat(value: '${group.memberChildIds.length}', label: l.statMembers),
              _Stat(value: '${CalendarLogic.countThisWeek(trainings, now)}', label: l.statThisWeek),
              _Stat(value: '$alerts', label: l.statCertAlerts, highlight: alerts > 0),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: () => context.push(Routes.chat(group.id)),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: Text(l.navChat),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('group-payments-button'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: () => context.push(Routes.groupPayments(group.id)),
                  icon: const Icon(Icons.payments_rounded, size: 18),
                  label: Text(l.paymentsTitle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.highlight = false});

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: t.headlineMedium?.copyWith(color: highlight ? AppColors.volt : Colors.white)),
          Text(
            label,
            style: t.labelSmall?.copyWith(color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _IncomingRequests extends ConsumerWidget {
  const _IncomingRequests();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final requests = ref.watch(incomingRequestsProvider).value ?? const <MembershipRequest>[];
    if (requests.isEmpty) return const SizedBox.shrink();
    final groups = ref.watch(groupsByIdProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l.membershipRequests),
        for (final r in requests)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_add_alt_1_rounded),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          l.wantsToJoin(r.childName, groups[r.groupId]?.name ?? ''),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => runGuarded(
                            context,
                            () => ref.read(clubsRepositoryProvider).decideRequest(r.id, approve: false),
                            success: l.requestRejected,
                          ),
                          child: Text(l.reject),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
                          onPressed: () => runGuarded(
                            context,
                            () => ref.read(clubsRepositoryProvider).decideRequest(r.id, approve: true),
                            success: l.requestApproved,
                          ),
                          child: Text(l.approve),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _UpcomingTrainings extends ConsumerWidget {
  const _UpcomingTrainings({required this.group, this.limit = 4});

  final Group group;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = ref.watch(clockProvider)();
    final trainings = ref.watch(myTrainingsProvider);
    return AsyncView<List<Training>>(
      value: trainings,
      compact: true,
      loading: const SkeletonList(count: 2, padding: EdgeInsets.zero),
      data: (all) {
        final list = CalendarLogic.upcoming(all.where((t) => t.groupId == group.id), now, limit: limit);
        if (list.isEmpty) {
          return AppCard(
            child: EmptyState(compact: true, icon: Icons.event_note_rounded, title: l.noUpcomingTrainings),
          );
        }
        return Column(
          children: [
            for (final t in list)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: TrainingTile(training: t, group: group),
              ),
          ],
        );
      },
    );
  }
}

class _RosterPreview extends ConsumerWidget {
  const _RosterPreview({required this.group, this.limit = 5});

  final Group group;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(groupMembersProvider(group.id));
    final now = ref.watch(clockProvider)();
    final certs = ref.watch(certificatesForChildrenProvider(childrenKey(group.memberChildIds))).value ?? const [];
    return AsyncView<List<Child>>(
      value: members,
      compact: true,
      loading: const SkeletonList(count: 3, itemHeight: 56, padding: EdgeInsets.zero),
      data: (list) => AppCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        onTap: () => context.push(Routes.roster(group.id)),
        child: Column(
          children: [
            for (final c in list.take(limit))
              RosterRow(
                child: c,
                status: CertificatePolicy.childStatus(certs.where((x) => x.childId == c.id), now),
                now: now,
              ),
          ],
        ),
      ),
    );
  }
}

/// ✅ valid · ⚠ expiring · ❌ missing/expired (spec §6.2).
class RosterRow extends StatelessWidget {
  const RosterRow({super.key, required this.child, required this.status, required this.now, this.onTap, this.trailing});

  final Child child;
  final CertificateStatus status;
  final DateTime now;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final v = StatusVisual.certificate(context, status);
    return ListTile(
      onTap: onTap,
      leading: InitialsAvatar(name: child.fullName, size: 40),
      title: Text(child.fullName, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(context.l10n.yearsOld(child.ageOn(now))),
      trailing: trailing ?? StatusPill.of(v, dense: true),
    );
  }
}
