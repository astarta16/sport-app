import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../attendance/presentation/attendance_providers.dart';
import '../../attendance/presentation/attendance_widgets.dart';
import '../../matches/domain/match.dart';
import '../../matches/presentation/match_screens.dart';
import '../../matches/presentation/matches_providers.dart';
import '../../media/presentation/media_screens.dart';
import '../../trainings/domain/series.dart';
import '../../training_plans/presentation/plans_screens.dart';
import '../../training_plans/presentation/plans_providers.dart';
import '../../training_plans/domain/training_plan.dart';
import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../attendance/domain/scheduled_event.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/top_bar_actions.dart';
import '../../../core/widgets/visuals.dart';
import '../../calendar/domain/calendar_logic.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../authentication/domain/app_user.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../children/presentation/children_providers.dart';
import '../../children/domain/child.dart';
import '../../clubs/presentation/clubs_providers.dart';
import '../../groups/domain/group.dart';
import '../../medical_certificates/domain/medical_certificate.dart';
import '../../medical_certificates/presentation/certificates_providers.dart';
import '../../notifications/presentation/notifications_providers.dart';
import '../../payments/domain/payment.dart';
import '../../payments/presentation/payments_providers.dart';
import '../../sports/presentation/sports_providers.dart';
import '../../trainings/domain/training.dart';
import '../../trainings/presentation/training_widgets.dart';
import '../../trainings/presentation/trainings_providers.dart';
import 'parent_context.dart';
import '../../chat/presentation/chat_providers.dart';
import '../../sports/presentation/sport_label.dart';
import '../../organizations/presentation/org_widgets.dart';
import '../../organizations/presentation/feature_gate.dart';
import '../../organizations/domain/organization.dart';
import '../../matches/presentation/match_result_widgets.dart';

/// Sports dashboard for the selected child and sport (spec §6.1).
class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(parentSelectionProvider);
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(myChildrenProvider),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Bounded(child: _Header(user: user)),
              ),
              ...switch (selection) {
                AsyncData(:final value) => _content(context, ref, value),
                AsyncError(:final error) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(error: error, onRetry: () => ref.invalidate(myChildrenProvider)),
                  ),
                ],
                _ => [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Skeleton(height: 64),
                          SizedBox(height: AppSpacing.md),
                          Skeleton(height: 280, radius: AppSpacing.radius),
                          SizedBox(height: AppSpacing.md),
                          Skeleton(height: 110, radius: AppSpacing.radius),
                        ],
                      ),
                    ),
                  ),
                ],
              },
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, WidgetRef ref, ParentSelection s) {
    final l = context.l10n;
    if (!s.hasChildren) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.child_care_rounded,
            title: l.noChildrenTitle,
            body: l.noChildrenBody,
            actionLabel: l.addChild,
            onAction: () => context.push(Routes.newChild),
          ),
        ),
      ];
    }
    final child = s.child!;
    final noGroup = AppCard(
      child: EmptyState(
        compact: true,
        icon: Icons.groups_rounded,
        title: l.noGroupTitle(child.firstName),
        body: l.noGroupBody,
        actionLabel: l.findClub,
        onAction: () => context.go(Routes.parentMap),
      ),
    );
    // v1.8: only features the child's organization offers.
    final certOn = ref.watch(featureOnProvider(OrgModule.medicalCertificates));
    final payOn = ref.watch(featureOnProvider(OrgModule.payments));
    final tiles = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (certOn) Expanded(child: _CertificateTile(child: child)),
        if (certOn && payOn) const SizedBox(width: AppSpacing.sm),
        if (payOn)
          Expanded(
            child: _PaymentTile(child: child, sportId: s.sportId),
          ),
      ],
    );
    final group = s.group;
    return [
      SliverToBoxAdapter(
        child: _Bounded(child: _ChildSelector(selection: s)),
      ),
      SliverToBoxAdapter(
        child: _Bounded(
          child: Align(
            alignment: Alignment.centerLeft,
            // v1.9.1 (M29): the child's details no longer need a hidden
            // long-press on the avatar.
            child: Wrap(
              spacing: AppSpacing.xs,
              children: [
                TextButton.icon(
                  key: const Key('open-student-profile'),
                  onPressed: () => context.push('/student/${child.id}'),
                  icon: const Icon(Icons.badge_rounded),
                  label: Text('${context.l10n.studentProfileOpen} · ${child.firstName}'),
                ),
                TextButton.icon(
                  key: const Key('open-child-details'),
                  onPressed: () => context.push(Routes.child(child.id)),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text(context.l10n.s191ChildDetails(child.firstName)),
                ),
              ],
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: _Bounded(
          child: _SportTabs(child: child, selectedSportId: s.sportId),
        ),
      ),
      SliverConstrained(
        maxWidth: Breakpoints.dashboard,
        minPadding: AppSpacing.lg,
        sliver: SliverToBoxAdapter(
          child: LayoutBuilder(
            builder: (context, c) {
              // Phone & narrow windows: the original single-column dashboard.
              if (c.maxWidth < Breakpoints.expanded - 80) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _InvitesBanner(),
                    const _PendingAcksBanner(),
                    const ParentContactRequestsBanner(),
                    const SizedBox(height: AppSpacing.md),
                    if (group == null) noGroup else _NextTrainingSection(group: group),
                    if (group != null) _MatchesBlock(groupIds: {group.id}),
                    const SizedBox(height: AppSpacing.md),
                    tiles,
                    const SizedBox(height: AppSpacing.sm),
                    _AttendanceCard(child: child),
                    FeatureGate(
                      module: OrgModule.trainingPlans,
                      child: _PlansSection(child: child),
                    ),
                    if (group != null) ...[
                      SectionHeader(
                        l.weekSchedule,
                        actionLabel: l.seeAll,
                        onAction: () => context.go(Routes.parentCalendar),
                      ),
                      _WeekStrip(groupIds: child.groupIds.toSet()),
                      SectionHeader(l.mediaRecent),
                      FeatureGate(
                        module: OrgModule.media,
                        child: MediaStrip(groupIds: {group.id}, sportKey: group.sportId),
                      ),
                    ],
                  ],
                );
              }
              // Tablet: training + communication on the left, status,
              // schedule and notifications on the right.
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _InvitesBanner(),
                          const _PendingAcksBanner(),
                          const ParentContactRequestsBanner(),
                          if (group == null) noGroup else _NextTrainingSection(group: group),
                          if (group != null) ...[
                            _MatchesBlock(groupIds: {group.id}),
                            FeatureGate(
                              module: OrgModule.trainingPlans,
                              child: _PlansSection(child: child),
                            ),
                            SectionHeader(l.weekSchedule),
                            _WeekStrip(groupIds: child.groupIds.toSet()),
                            SectionHeader(l.mediaRecent),
                            FeatureGate(
                              module: OrgModule.media,
                              child: MediaStrip(groupIds: {group.id}, sportKey: group.sportId),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      flex: 2,
                      child: Column(
                        key: const Key('parent-dashboard-side'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          tiles,
                          const SizedBox(height: AppSpacing.sm),
                          _AttendanceCard(child: child),
                          if (group != null) ...[
                            SectionHeader(
                              l.upcoming,
                              actionLabel: l.seeAll,
                              onAction: () => context.go(Routes.parentCalendar),
                            ),
                            _UpcomingList(groupId: group.id),
                          ],
                          SectionHeader(
                            l.notificationsTitle,
                            actionLabel: l.seeAll,
                            onAction: () => context.push(Routes.notifications),
                          ),
                          const _NotificationsPreview(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ];
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final hour = ref.watch(clockProvider)().hour;
    final name = user?.firstName ?? '';
    final greeting = hour < 12 ? l.greetingMorning(name) : (hour < 18 ? l.greetingDay(name) : l.greetingEvening(name));
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.appName.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const OrgSwitcherChip(),
              ],
            ),
          ),
          const TopBarActions(),
        ],
      ),
    );
  }
}

class _ChildSelector extends ConsumerWidget {
  const _ChildSelector({required this.selection});

  final ParentSelection selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = ref.watch(clockProvider)();
    // Grows with the user's text size (accessibility).
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return SizedBox(
      height: 72 + 50 * textScale,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
        children: [
          for (final c in selection.children)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Semantics(
                button: true,
                selected: c.id == selection.child?.id,
                label: c.fullName,
                hint: l.s191ChildChipHint,
                onLongPressHint: l.s191ChildDetails(c.firstName),
                child: GestureDetector(
                  key: Key('child-chip-${c.id}'),
                  onTap: () => ref.read(selectionContextProvider.notifier).selectChild(c.id),
                  onLongPress: () => context.push(Routes.child(c.id)),
                  child: Column(
                    children: [
                      InitialsAvatar(name: c.fullName, size: 56, selected: c.id == selection.child?.id),
                      const SizedBox(height: 6),
                      Text(
                        c.firstName,
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(fontWeight: c.id == selection.child?.id ? FontWeight.w800 : FontWeight.w600),
                      ),
                      Text(l.yearsOld(c.ageOn(now)), style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
            ),
          // v1.9.1 (M30): a real button for screen readers and keyboards.
          Semantics(
            button: true,
            label: l.addChild,
            excludeSemantics: true,
            child: InkWell(
              key: const Key('home-add-child'),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              onTap: () => context.push(Routes.newChild),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.5),
                    ),
                    child: Icon(Icons.add_rounded, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 6),
                  Text(l.addChild, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SportTabs extends ConsumerWidget {
  const _SportTabs({required this.child, required this.selectedSportId});

  final Child child;
  final String? selectedSportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sports = ref.watch(sportsByIdProvider);
    if (child.sportIds.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
        children: [
          for (final id in child.sportIds)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                key: Key('sport-tab-$id'),
                avatar: Icon(
                  SportVisuals.icon(sports[id]?.icon ?? id),
                  size: 18,
                  color: id == selectedSportId ? Theme.of(context).colorScheme.primary : SportVisuals.color(id),
                ),
                label: Text(sports[id]?.label(context) ?? id),
                selected: id == selectedSportId,
                onSelected: (_) => ref.read(selectionContextProvider.notifier).selectSport(id),
              ),
            ),
        ],
      ),
    );
  }
}

class _NextTrainingSection extends ConsumerWidget {
  const _NextTrainingSection({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final trainings = ref.watch(myTrainingsProvider);
    final now = ref.watch(clockProvider)();
    final coachId = group.coachIds.isEmpty ? null : group.coachIds.first;
    final coach = coachId == null ? null : ref.watch(publicProfileProvider(coachId)).value;
    return AsyncView<List<Training>>(
      value: trainings,
      loading: const Skeleton(height: 290, radius: AppSpacing.radius),
      data: (list) {
        final next = nextTraining(list, {group.id}, now);
        if (next == null) {
          return AppCard(
            child: EmptyState(compact: true, icon: Icons.event_busy_rounded, title: l.noUpcomingTrainings),
          );
        }
        final venue = ref.watch(venuesByIdProvider)[next.venueId];
        final card = TweenAnimationBuilder<double>(
          key: ValueKey(next.id),
          tween: Tween(begin: 0, end: 1),
          // v1.9: no entrance animation when reduced motion is requested.
          duration: AppMotion.of(context, const Duration(milliseconds: 400)),
          curve: Curves.easeOutCubic,
          builder: (_, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
          ),
          child: NextTrainingCard(
            training: next,
            group: group,
            now: now,
            coachName: coach?.fullName,
            onDirections: venue == null ? null : () => openDirections(context, venue.location, venue.name),
          ),
        );
        // v1.9: answer "Will … attend?" right here — no need to open the
        // training first (the reschedule acknowledgment is shown too).
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            card,
            Padding(
              key: const Key('home-rsvp'),
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: RsvpSection(event: ScheduledEvent.training(next), group: group),
            ),
          ],
        );
      },
    );
  }
}

class _CertificateTile extends ConsumerWidget {
  const _CertificateTile({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = ref.watch(clockProvider)();
    final certs = ref.watch(childCertificatesProvider(child.id));
    final status = CertificatePolicy.childStatus(certs.value ?? const [], now);
    final v = StatusVisual.certificate(context, status);
    final latest = (certs.value ?? const <MedicalCertificate>[]).firstOrNull;
    return AppCard(
      key: const Key('certificate-tile'),
      onTap: () => context.push(Routes.certificates(child.id)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 108),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.health_and_safety_rounded, color: v.color),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.medicalStatus,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            certs.isLoading && !certs.hasValue ? const Skeleton(height: 22, width: 80) : StatusPill.of(v),
            if (latest != null && status != CertificateStatus.missing) ...[
              const SizedBox(height: 4),
              Text(Fmt.of(context).numericDate(latest.validUntil), style: Theme.of(context).textTheme.labelSmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends ConsumerWidget {
  const _PaymentTile({required this.child, required this.sportId});

  final Child child;
  final String? sportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final now = ref.watch(clockProvider)();
    final payments =
        (ref.watch(myPaymentsProvider).value ?? const <Payment>[])
            .where((p) => p.childId == child.id && p.status == PaymentStatus.pending)
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final total = pendingTotal(payments);
    final overdue = payments.any((p) => p.isOverdue(now));
    return AppCard(
      key: const Key('payment-tile'),
      onTap: () => context.push(Routes.payments),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 108),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              color: overdue ? AppColors.danger : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l.paymentSummary, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(
              payments.isEmpty ? l.allPaid : f.money(total),
              style: payments.isEmpty ? Theme.of(context).textTheme.titleSmall : Theme.of(context).textTheme.titleLarge,
            ),
            if (payments.isNotEmpty)
              Text(
                l.nextDue(f.dayMonthShort(payments.first.dueDate)),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: overdue ? AppColors.danger : null),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bounded extends StatelessWidget {
  const _Bounded({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ConstrainedContent(maxWidth: Breakpoints.dashboard + 2 * AppSpacing.lg, child: child);
}

class _UpcomingList extends ConsumerWidget {
  const _UpcomingList({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final groups = ref.watch(groupsByIdProvider);
    final all = ref.watch(myTrainingsProvider).value ?? const <Training>[];
    final list = CalendarLogic.upcoming(all.where((t) => t.groupId == groupId), now, limit: 4);
    if (list.isEmpty) {
      return AppCard(
        child: EmptyState(compact: true, icon: Icons.event_busy_rounded, title: context.l10n.noUpcomingTrainings),
      );
    }
    return Column(
      children: [
        for (final t in list)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: TrainingTile(training: t, group: groups[t.groupId]),
          ),
      ],
    );
  }
}

class _NotificationsPreview extends ConsumerWidget {
  const _NotificationsPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final inbox = ref.watch(inboxProvider).value ?? const [];
    if (inbox.isEmpty) {
      return AppCard(
        child: EmptyState(compact: true, icon: Icons.notifications_none_rounded, title: l.notificationsEmpty),
      );
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (final n in inbox.take(3))
            ListTile(
              leading: Icon(notificationIcon(n.type), color: Theme.of(context).colorScheme.primary),
              title: Text(notificationTitle(context, n.type), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(notificationBody(context, n), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: n.read ? null : const CircleAvatar(radius: 4, backgroundColor: AppColors.blue),
              onTap: () {
                ref.read(notificationsRepositoryProvider).markRead(n.id);
                if (n.route != null) context.push(n.route!);
              },
            ),
        ],
      ),
    );
  }
}

/// Open group invitations for this parent (v1.1 §2).
/// v1.4: outstanding acknowledgment requests. Shows only counts and group
/// names (no message text); tapping opens the group chat.
class _PendingAcksBanner extends ConsumerWidget {
  const _PendingAcksBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingAcksProvider).value ?? const [];
    if (pending.isEmpty) return const SizedBox.shrink();
    final groups = ref.watch(groupsByIdProvider);
    final groupIds = pending.map((p) => p.groupId).toSet().toList();
    final names = groupIds.map((g) => groups[g]?.name).whereType<String>().join(', ');
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AppCard(
        key: const Key('dashboard-acks'),
        color: AppColors.coral.withValues(alpha: 0.14),
        // v1.7: a schedule-change acknowledgment opens the event itself
        // (current schedule, "got it" and the attendance answer together).
        onTap: () {
          final ev = pending.where((p) => p.eventId != null).firstOrNull;
          context.push(
            ev == null
                ? '/chat/${groupIds.first}'
                : (ev.eventType == 'match' ? '/match/${ev.eventId}' : '/training/${ev.eventId}'),
          );
        },
        child: Row(
          children: [
            const Icon(Icons.task_alt_rounded, color: AppColors.coral),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.dashboardAcksTitle, style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    l.dashboardAcksBody(pending.length, names),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _InvitesBanner extends ConsumerWidget {
  const _InvitesBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(openInvitesProvider);
    if (open.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AppCard(
        key: const Key('invites-banner'),
        color: AppColors.volt.withValues(alpha: 0.25),
        onTap: () => context.push(Routes.invites),
        child: Row(
          children: [
            const Icon(Icons.group_add_rounded),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(context.l10n.inviteBanner(open.length), style: Theme.of(context).textTheme.titleSmall),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _NextMatch extends ConsumerWidget {
  const _NextMatch({required this.groupIds});

  final Set<String> groupIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = nextMatch(ref.watch(myMatchesProvider).value ?? const [], groupIds, ref.watch(clockProvider)());
    if (m == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: NextMatchCard(match: m),
    );
  }
}

/// v1.5: latest final score + next match.
class _MatchesBlock extends StatelessWidget {
  const _MatchesBlock({required this.groupIds});

  final Set<String> groupIds;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _NextMatch(groupIds: groupIds),
      LatestResultCard(groupIds: groupIds),
    ],
  );
}

/// Recorded attendance this month (coach-recorded only).
class _AttendanceCard extends ConsumerWidget {
  const _AttendanceCard({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final stats = ref.watch(childStatsProvider(child.id)).value;
    final month = stats?.monthOf(ref.watch(clockProvider)());
    return AppCard(
      key: const Key('attendance-tile'),
      onTap: () => context.push(Routes.progress(child.id)),
      child: Row(
        children: [
          const Icon(Icons.fact_check_rounded, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.attendanceTile, style: Theme.of(context).textTheme.labelMedium),
                Text(
                  month?.rate == null ? l.attendanceNoData : l.attendanceTileValue((month!.rate! * 100).round()),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (month?.rate != null) ...[const SizedBox(height: 6), AttendanceRateBar(rate: month!.rate)],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l.progressShort,
            style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

/// Trainings and matches of the next 7 days, one chip per day.
class _WeekStrip extends ConsumerWidget {
  const _WeekStrip({required this.groupIds});

  final Set<String> groupIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final now = ref.watch(clockProvider)();
    final end = DateUtils.dateOnly(now).add(const Duration(days: 7));
    final trainings = (ref.watch(myTrainingsProvider).value ?? const <Training>[])
        .where((t) => groupIds.contains(t.groupId) && t.endAt.isAfter(now) && t.startAt.isBefore(end))
        .toList();
    final matches = (ref.watch(myMatchesProvider).value ?? const <SportMatch>[])
        .where((m) => groupIds.contains(m.groupId) && m.endAt.isAfter(now) && m.startAt.isBefore(end))
        .toList();
    final items = <(DateTime, String, bool, bool, String)>[
      for (final t in trainings)
        (t.startAt, Routes.training(t.id), false, t.status == TrainingStatus.cancelled, f.time(t.startAt)),
      for (final m in matches)
        (m.startAt, Routes.match(m.id), true, m.status == MatchStatus.cancelled, f.time(m.startAt)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    if (items.isEmpty) {
      return AppCard(
        child: EmptyState(compact: true, icon: Icons.event_available_rounded, title: l.weekEmpty),
      );
    }
    return SizedBox(
      height: 84,
      child: ListView.separated(
        key: const Key('week-strip'),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, i) {
          final (at, route, isMatch, cancelled, time) = items[i];
          return AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            color: isMatch ? AppColors.volt.withValues(alpha: 0.25) : null,
            onTap: () => context.push(route),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(f.weekdayShort(at), style: Theme.of(context).textTheme.labelSmall),
                Text(
                  time,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(decoration: cancelled ? TextDecoration.lineThrough : null),
                ),
                Icon(isMatch ? Icons.emoji_events_rounded : Icons.sports_rounded, size: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Assigned training plans for the selected child; homework first (v1.3).
class _PlansSection extends ConsumerWidget {
  const _PlansSection({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final today = LocalDate.tbilisi(ref.watch(clockProvider)());
    final plans =
        (ref.watch(plansProvider).value ?? const <TrainingPlan>[])
            .where((p) => p.activeOn(today) && p.groupIds.any(child.groupIds.contains))
            .toList()
          ..sort((a, b) => (a.type == PlanType.homework ? 0 : 1).compareTo(b.type == PlanType.homework ? 0 : 1));
    if (plans.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('dashboard-plans'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          l.plansTitle,
          actionLabel: l.seeAll,
          onAction: () => context.push('${Routes.plans}?childId=${child.id}'),
        ),
        for (final p in plans.take(2))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: PlanCard(plan: p, groupNames: const []),
          ),
      ],
    );
  }
}
