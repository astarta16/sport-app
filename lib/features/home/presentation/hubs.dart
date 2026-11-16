import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../../clubs/presentation/clubs_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../organizations/domain/organization.dart';
import '../../organizations/presentation/feature_gate.dart';
import '../../sports/presentation/sport_label.dart';
import '../../sports/presentation/sports_providers.dart';
import '../../trainings/domain/training.dart';
import '../../trainings/presentation/trainings_providers.dart';

/// v1.9 Parent "Children" tab: one card per child with the things a parent
/// does for that child (profile, progress, documents, homework, payments),
/// so nothing child-specific hides behind a long-press or the profile.
class ChildrenHubScreen extends ConsumerWidget {
  const ChildrenHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navChildren),
        actions: [
          IconButton(
            key: const Key('hub-add-child'),
            tooltip: l.addChild,
            onPressed: () => context.push(Routes.newChild),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      body: AsyncView<List<Child>>(
        value: ref.watch(myChildrenProvider),
        onRetry: () => ref.invalidate(myChildrenProvider),
        data: (children) => children.isEmpty
            ? EmptyState(
                icon: Icons.child_care_rounded,
                title: l.noChildrenTitle,
                body: l.hubNoChildrenBody,
                actionLabel: l.addChild,
                onAction: () => context.push(Routes.newChild),
              )
            : ConstrainedContent(
                child: ListView(
                  key: const Key('children-hub'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [for (final c in children) _ChildCard(child: c)],
                ),
              ),
      ),
    );
  }
}

class _ChildCard extends ConsumerWidget {
  const _ChildCard({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sports = ref.watch(sportsByIdProvider);
    final now = ref.watch(clockProvider)();
    final payOn = ref.watch(featureOnProvider(OrgModule.payments));
    final plansOn = ref.watch(featureOnProvider(OrgModule.trainingPlans));
    final certOn = ref.watch(featureOnProvider(OrgModule.medicalCertificates));
    Widget action(String key, IconData icon, String label, String route) => ActionChip(
      key: Key('hub-child-$key-${child.id}'),
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => context.push(route),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        key: Key('hub-child-${child.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InitialsAvatar(name: child.fullName, size: 48),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.fullName, style: t.titleMedium),
                      Text(
                        [
                          l.yearsOld(child.ageOn(now)),
                          ...child.sportIds.map((s) => sports[s]?.label(context) ?? s),
                        ].join(' · '),
                        style: t.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                action('profile', Icons.badge_rounded, l.hubChildProfile, Routes.child(child.id)),
                action('progress', Icons.trending_up_rounded, l.hubChildProgress, Routes.progress(child.id)),
                if (certOn)
                  action(
                    'certificates',
                    Icons.health_and_safety_rounded,
                    l.hubChildDocuments,
                    Routes.certificates(child.id),
                  ),
                if (plansOn)
                  action('plans', Icons.assignment_rounded, l.plansTitle, '${Routes.plans}?childId=${child.id}'),
                if (payOn) action('payments', Icons.account_balance_wallet_rounded, l.paymentsTitle, Routes.payments),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// v1.9 Coach "Groups" tab: every group with its next session and the
/// actions a coach repeats daily (attendance, roster, new training, chat).
class GroupsHubScreen extends ConsumerWidget {
  const GroupsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.groupsLabel),
        actions: [
          IconButton(
            key: const Key('hub-new-group'),
            tooltip: l.newGroup,
            onPressed: () => context.push(Routes.newGroup),
            icon: const Icon(Icons.group_add_rounded),
          ),
        ],
      ),
      body: AsyncView<List<Group>>(
        value: ref.watch(myGroupsProvider),
        onRetry: () => ref.invalidate(myGroupsProvider),
        data: (groups) => groups.isEmpty
            ? EmptyState(
                icon: Icons.groups_rounded,
                title: l.hubNoGroupsTitle,
                body: l.hubNoGroupsBody,
                actionLabel: l.newGroup,
                onAction: () => context.push(Routes.newGroup),
              )
            : ConstrainedContent(
                child: ListView(
                  key: const Key('groups-hub'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [for (final g in groups.where((g) => g.isActive)) _GroupCard(group: g)],
                ),
              ),
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final f = Fmt.of(context);
    final now = ref.watch(clockProvider)();
    final sport = ref.watch(sportsByIdProvider)[group.sportId];
    final club = ref.watch(clubsByIdProvider)[group.clubId];
    final trainings =
        (ref.watch(myTrainingsProvider).value ?? const <Training>[])
            .where((x) => x.groupId == group.id && x.status.isActive)
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final next = trainings.where((x) => x.startAt.add(Duration(minutes: x.durationMin)).isAfter(now)).firstOrNull;
    // The session to take attendance for: today's, already started.
    final today = trainings
        .where((x) => isSameDay(x.startAt, now) && !x.startAt.isAfter(now.add(const Duration(minutes: 30))))
        .lastOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        key: Key('hub-group-${group.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SportBadge(sportKey: sport?.icon ?? group.sportId, size: 44),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, style: t.titleMedium),
                      Text(
                        [
                          sport?.label(context) ?? group.sportId,
                          if (club != null) club.name,
                          l.groupMembers(group.memberChildIds.length),
                        ].join(' · '),
                        style: t.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (next != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text('${l.hubNextSession}: ${f.dateTime(next.startAt)}', style: t.bodyMedium),
              ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (today != null)
                  FilledButton.icon(
                    key: Key('hub-attendance-${group.id}'),
                    onPressed: () => context.push(Routes.attendance(today.id)),
                    icon: const Icon(Icons.fact_check_rounded),
                    label: Text(l.hubTakeAttendance),
                  ),
                ActionChip(
                  key: Key('hub-roster-${group.id}'),
                  avatar: const Icon(Icons.groups_rounded, size: 18),
                  label: Text(l.roster),
                  onPressed: () => context.push(Routes.roster(group.id)),
                ),
                ActionChip(
                  key: Key('hub-new-training-${group.id}'),
                  avatar: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l.newTraining),
                  onPressed: () => context.push(Routes.newTraining(group.id)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
