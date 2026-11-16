import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/visuals.dart';
import '../../attendance/domain/attendance.dart';
import '../../attendance/presentation/attendance_providers.dart';
import '../../authentication/domain/access_policy.dart';
import '../../authentication/domain/app_user.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../matches/domain/match.dart';
import '../../matches/presentation/match_result_widgets.dart';
import '../../matches/presentation/matches_providers.dart';
import '../../media/presentation/media_providers.dart';
import '../../media/presentation/media_screens.dart';
import '../../medical_certificates/domain/medical_certificate.dart';
import '../../medical_certificates/presentation/certificates_providers.dart';
import '../../payments/domain/payment.dart';
import '../../sports/presentation/sports_providers.dart';
import '../../payments/presentation/payments_providers.dart';
import '../../training_plans/domain/training_plan.dart';
import '../../training_plans/presentation/plans_providers.dart';
import '../../training_plans/presentation/plans_screens.dart';
import '../../trainings/domain/training.dart';
import '../../trainings/presentation/training_widgets.dart';
import '../../trainings/presentation/trainings_providers.dart';
import '../domain/child.dart';
import 'children_providers.dart';
import '../../sports/presentation/sport_label.dart';
import '../../brain_academy/presentation/student_home_screen.dart';

/// Who is looking at the profile, and which groups they may see data of.
/// Parents: all of the child's groups. Coaches: only their own active
/// groups that contain the child (never unrelated private information).
({bool isParent, bool isCoach, List<Group> groups}) profileScope(AppUser me, Child child, Iterable<Group> groups) {
  final isParent = me.isParent && child.parentIds.contains(me.id);
  final childGroups = groups.where((g) => g.hasChild(child.id)).toList();
  if (isParent) return (isParent: true, isCoach: false, groups: childGroups);
  final mine = childGroups.where((g) => g.isActive && AccessPolicy.isCoachOf(me, g)).toList();
  return (isParent: false, isCoach: mine.isNotEmpty, groups: mine);
}

/// `/student/:childId` — v1.5 dedicated student profile for parents and the
/// child's coaches.
class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(currentUserProvider);
    final child = ref.watch(childProvider(childId));
    final groups = ref.watch(groupsByIdProvider).values;
    // Loading / denied states keep the app bar (back navigation).
    if (!child.hasValue) {
      return Scaffold(
        appBar: AppBar(title: Text(l.studentProfileTitle)),
        body: AsyncView<Child?>(
          value: child,
          onRetry: () => ref.invalidate(childProvider(childId)),
          data: (_) => const SizedBox.shrink(),
        ),
      );
    }
    return Builder(
      builder: (context) {
        final c = child.value;
        final scope = c == null || me == null ? null : profileScope(me, c, groups);
        if (c == null || scope == null || (!scope.isParent && !scope.isCoach)) {
          return Scaffold(
            appBar: AppBar(title: Text(l.studentProfileTitle)),
            body: EmptyState(icon: Icons.lock_outline_rounded, title: l.errorPermission),
          );
        }
        final tabs = [l.tabOverview, l.tabTrainings, l.tabPlans, l.tabMedia, l.tabMatches, l.brainAcademy];
        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: Text(c.fullName, maxLines: 1, overflow: TextOverflow.ellipsis),
              bottom: TabBar(
                key: const Key('profile-tabs'),
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [for (final t in tabs) Tab(text: t)],
              ),
            ),
            body: TabBarView(
              children: [
                _Overview(child: c, scope: scope),
                _TrainingsTab(child: c, groups: scope.groups),
                _PlansTab(groups: scope.groups),
                _MediaTab(groups: scope.groups),
                _MatchesTab(groups: scope.groups),
                // v1.6: Brain Academy progress, badges and challenge status.
                _page(key: const Key('profile-brain'), [
                  Text(l.brainParentNote, style: Theme.of(context).textTheme.bodySmall),
                  ChallengesList(childId: c.id),
                  BrainProgressView(childId: c.id),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _page(List<Widget> children, {Key? key}) => ConstrainedContent(
  maxWidth: Breakpoints.readable,
  child: ListView(
    key: key,
    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
    children: children,
  ),
);

Widget _empty(BuildContext context) => Padding(
  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
  child: Text(context.l10n.profileEmpty, style: Theme.of(context).textTheme.bodySmall),
);

/// Coaches of the given groups (approved, from group data).
Set<String> _coachIds(List<Group> groups) => {for (final g in groups) ...g.coachIds};

class _Overview extends ConsumerWidget {
  const _Overview({required this.child, required this.scope});

  final Child child;
  final ({bool isParent, bool isCoach, List<Group> groups}) scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final now = ref.watch(clockProvider)();
    final me = ref.watch(currentUserProvider)!;
    final groupIds = {for (final g in scope.groups) g.id};
    final trainings =
        (ref.watch(myTrainingsProvider).value ?? const <Training>[])
            .where(
              (tr) => groupIds.contains(tr.groupId) && tr.startAt.isAfter(now) && tr.status != TrainingStatus.cancelled,
            )
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final matches =
        (ref.watch(myMatchesProvider).value ?? const <SportMatch>[])
            .where((m) => groupIds.contains(m.groupId) && m.status.isActive && m.startAt.isAfter(now))
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final certs =
        ref.watch(certificatesForChildrenProvider(childrenKey([child.id]))).value ?? const <MedicalCertificate>[];
    final certStatus = CertificatePolicy.childStatus(certs.where((c) => c.childId == child.id), now);
    final payments = scope.isParent
        ? (ref.watch(myPaymentsProvider).value ?? const <Payment>[]).where((p) => p.childId == child.id).toList()
        : [
            for (final g in scope.groups)
              if (AccessPolicy.canManagePayments(me, g))
                ...(ref.watch(groupPaymentsProvider(g.id)).value ?? const <Payment>[]).where(
                  (p) => p.childId == child.id,
                ),
          ];
    payments.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    final coachIds = _coachIds(scope.groups);
    return _page(key: const Key('profile-overview'), [
      AppCard(
        child: Row(
          children: [
            UserAvatar(name: child.fullName, photoPath: child.photoPath, size: 56),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(child.fullName, style: t.titleMedium),
                  Text(l.yearsOld(child.ageOn(now)), style: t.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
      if (scope.isCoach)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(l.profileCoachScope, style: t.bodySmall),
        ),
      const SizedBox(height: AppSpacing.sm),
      _ContactActions(child: child, scope: scope, coachIds: coachIds),
      SectionHeader(l.profileSportsGroups),
      if (scope.groups.isEmpty) _empty(context),
      for (final g in scope.groups)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: SportBadge(sportKey: g.sportId, size: 36),
          title: Text(g.name),
          subtitle: Text(ref.watch(sportsByIdProvider)[g.sportId]?.label(context) ?? g.sportId),
        ),
      SectionHeader(l.profileCoaches),
      if (coachIds.isEmpty) _empty(context),
      for (final id in coachIds) _CoachRow(coachId: id),
      SectionHeader(l.profileUpcomingTrainings),
      if (trainings.isEmpty) _empty(context),
      for (final tr in trainings.take(3))
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: TrainingTile(training: tr, group: scope.groups.where((g) => g.id == tr.groupId).firstOrNull),
        ),
      SectionHeader(l.profileUpcomingMatches),
      if (matches.isEmpty) _empty(context),
      for (final m in matches.take(3))
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: MatchResultTile(match: m),
        ),
      SectionHeader(l.profileCertificate),
      Align(alignment: Alignment.centerLeft, child: StatusPill.of(StatusVisual.certificate(context, certStatus))),
      if (payments.isNotEmpty) ...[
        SectionHeader(l.profilePayments),
        for (final p in payments.take(3))
          Padding(
            key: Key('profile-payment-${p.id}'),
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text('${Fmt.of(context).money(p.amount)} · ${l.dueOn(Fmt.of(context).dayMonth(p.dueDate))}'),
                ),
                StatusPill.of(StatusVisual.payment(context, p, now), dense: true),
              ],
            ),
          ),
      ],
    ]);
  }
}

class _CoachRow extends ConsumerWidget {
  const _CoachRow({required this.coachId});

  final String coachId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(publicProfileProvider(coachId)).value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: InitialsAvatar(name: p?.fullName ?? '?', size: 36),
      title: Text(p?.fullName ?? '…'),
      subtitle: Text(context.l10n.roleCoach),
    );
  }
}

/// Parent: message (child-context) or call the coach. Coach: message or call
/// this child's guardians.
class _ContactActions extends ConsumerWidget {
  const _ContactActions({required this.child, required this.scope, required this.coachIds});

  final Child child;
  final ({bool isParent, bool isCoach, List<Group> groups}) scope;
  final Set<String> coachIds;

  Future<void> _message(BuildContext context, WidgetRef ref) async {
    final me = ref.read(currentUserProvider)!;
    if (scope.isCoach) {
      await context.push('/student/${child.id}/coach/${me.id}');
      return;
    }
    if (coachIds.isEmpty) return;
    var coachId = coachIds.first;
    if (coachIds.length > 1) {
      final picked = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(ctx.l10n.chooseCoach, style: Theme.of(ctx).textTheme.titleMedium)),
              for (final id in coachIds)
                Consumer(
                  builder: (ctx, ref, _) => ListTile(
                    key: Key('choose-coach-$id'),
                    leading: const Icon(Icons.sports_rounded),
                    title: Text(ref.watch(publicProfileProvider(id)).value?.fullName ?? '…'),
                    onTap: () => Navigator.pop(ctx, id),
                  ),
                ),
            ],
          ),
        ),
      );
      if (picked == null) return;
      coachId = picked;
    }
    if (context.mounted) await context.push('/student/${child.id}/coach/$coachId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final gid = scope.groups.firstOrNull?.id;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        if (scope.isParent ? coachIds.isNotEmpty : true)
          FilledButton.icon(
            key: const Key('profile-contact-coach'),
            onPressed: () => _message(context, ref),
            icon: const Icon(Icons.forum_rounded),
            label: Text(scope.isParent ? l.contactCoachAbout(child.firstName) : l.contactParentsAction),
          ),
        if (gid != null)
          OutlinedButton.icon(
            key: const Key('profile-call'),
            onPressed: () =>
                context.push(scope.isParent ? '/group/$gid/contacts' : '/group/$gid/contacts?childId=${child.id}'),
            icon: const Icon(Icons.call_rounded),
            label: Text(l.call),
          ),
      ],
    );
  }
}

class _TrainingsTab extends ConsumerWidget {
  const _TrainingsTab({required this.child, required this.groups});

  final Child child;
  final List<Group> groups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = ref.watch(clockProvider)();
    final groupIds = {for (final g in groups) g.id};
    final past =
        (ref.watch(myTrainingsProvider).value ?? const <Training>[])
            .where((tr) => groupIds.contains(tr.groupId) && tr.startAt.isBefore(now))
            .toList()
          ..sort((a, b) => b.startAt.compareTo(a.startAt));
    final records = {
      for (final r in ref.watch(attendanceForChildProvider(child.id)).value ?? const <AttendanceRecord>[])
        r.trainingId: r,
    };
    final stats = ref.watch(childStatsProvider(child.id)).value;
    return _page(key: const Key('profile-trainings'), [
      SectionHeader(l.profileAttendance),
      Text(
        stats?.rate == null ? l.rosterNoAttendance : l.rosterAttendanceRate((stats!.rate! * 100).round()),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      TextButton.icon(
        key: const Key('profile-progress'),
        onPressed: () => context.push(Routes.progress(child.id)),
        icon: const Icon(Icons.insights_rounded),
        label: Text(l.progressShort),
      ),
      SectionHeader(l.profileTrainingHistory),
      if (past.isEmpty) _empty(context),
      for (final tr in past.take(30))
        Padding(
          key: Key('profile-history-${tr.id}'),
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TrainingTile(training: tr, group: groups.where((g) => g.id == tr.groupId).firstOrNull),
              if (records[tr.id] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: AppSpacing.sm),
                  child: Text(
                    attendanceLabel(context, records[tr.id]!.status),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
            ],
          ),
        ),
    ]);
  }
}

class _PlansTab extends ConsumerWidget {
  const _PlansTab({required this.groups});

  final List<Group> groups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final groupIds = {for (final g in groups) g.id};
    final names = {for (final g in groups) g.id: g.name};
    final plans = (ref.watch(plansProvider).value ?? const <TrainingPlan>[])
        .where((p) => p.status == PlanStatus.published && p.groupIds.any(groupIds.contains))
        .toList();
    final homework = plans.where((p) => p.type == PlanType.homework).toList();
    final other = plans.where((p) => p.type != PlanType.homework).toList();
    Widget card(TrainingPlan p) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: PlanCard(plan: p, groupNames: [for (final g in p.groupIds) ?names[g]]),
    );
    return _page(key: const Key('profile-plans'), [
      SectionHeader(l.profileHomework),
      if (homework.isEmpty) _empty(context),
      ...homework.map(card),
      SectionHeader(l.tabPlans),
      if (other.isEmpty) _empty(context),
      ...other.map(card),
    ]);
  }
}

class _MediaTab extends ConsumerWidget {
  const _MediaTab({required this.groups});

  final List<Group> groups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupIds = {for (final g in groups) g.id};
    final posts = (ref.watch(mediaFeedProvider).value ?? const [])
        .where((p) => !p.hidden && p.groupIds.any(groupIds.contains))
        .toList();
    final sport = groups.firstOrNull?.sportId ?? 'football';
    return _page(key: const Key('profile-media'), [
      if (posts.isEmpty) _empty(context),
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [for (final p in posts) MediaPostTile(post: p, sportKey: sport, size: 104)],
      ),
    ]);
  }
}

class _MatchesTab extends ConsumerWidget {
  const _MatchesTab({required this.groups});

  final List<Group> groups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = ref.watch(clockProvider)();
    final groupIds = {for (final g in groups) g.id};
    final all = ref.watch(myMatchesProvider).value ?? const <SportMatch>[];
    final results = resultsFor(all, groupIds);
    final upcoming =
        all.where((m) => groupIds.contains(m.groupId) && m.status.isActive && m.startAt.isAfter(now)).toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return _page(key: const Key('profile-matches'), [
      SectionHeader(l.profileMatchResults),
      if (results.isEmpty) _empty(context),
      for (final m in results)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: MatchResultTile(match: m),
        ),
      SectionHeader(l.profileUpcomingMatches),
      if (upcoming.isEmpty) _empty(context),
      for (final m in upcoming)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: MatchResultTile(match: m),
        ),
    ]);
  }
}
