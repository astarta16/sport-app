import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../calendar/domain/calendar_logic.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../authentication/domain/app_user.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../chat/presentation/chat_providers.dart';
import '../../children/presentation/children_providers.dart';
import '../../children/domain/child.dart';
import '../../clubs/presentation/clubs_providers.dart';
import '../../groups/domain/group.dart';
import '../../media/presentation/media_providers.dart';
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
    final tiles = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _CertificateTile(child: child)),
        const SizedBox(width: AppSpacing.sm),
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
                    const SizedBox(height: AppSpacing.md),
                    if (group == null) noGroup else _NextTrainingSection(group: group),
                    const SizedBox(height: AppSpacing.md),
                    tiles,
                    if (group != null) ...[
                      SectionHeader(
                        l.coachMessages,
                        actionLabel: l.openChat,
                        onAction: () => context.push(Routes.chat(group.id)),
                      ),
                      _CoachMessages(group: group),
                      SectionHeader(l.recentPhotos),
                      _RecentPhotos(group: group),
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
                          if (group == null) noGroup else _NextTrainingSection(group: group),
                          if (group != null) ...[
                            SectionHeader(
                              l.coachMessages,
                              actionLabel: l.openChat,
                              onAction: () => context.push(Routes.chat(group.id)),
                            ),
                            _CoachMessages(group: group),
                            SectionHeader(l.recentPhotos),
                            _RecentPhotos(group: group),
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
    final unread = ref.watch(unreadCountProvider);
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
              ],
            ),
          ),
          IconButton(
            key: const Key('notifications-button'),
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
          GestureDetector(
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
                label: Text(sports[id]?.name ?? id),
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
        return TweenAnimationBuilder<double>(
          key: ValueKey(next.id),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 400),
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

class _CoachMessages extends ConsumerWidget {
  const _CoachMessages({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final messages = ref.watch(chatMessagesProvider(group.id));
    return AsyncView(
      value: messages,
      compact: true,
      loading: const Skeleton(height: 90, radius: AppSpacing.radius),
      data: (list) {
        final fromCoach = list.where((m) => m.senderRole == UserRole.coach).toList().reversed.take(3).toList();
        if (fromCoach.isEmpty) {
          return AppCard(
            child: EmptyState(compact: true, icon: Icons.chat_bubble_outline_rounded, title: l.noMessages),
          );
        }
        return AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          onTap: () => context.push(Routes.chat(group.id)),
          child: Column(
            children: [
              for (final m in fromCoach)
                ListTile(
                  leading: InitialsAvatar(name: m.senderName, size: 38),
                  title: Text(
                    m.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  subtitle: Text(
                    '${m.senderName} · ${f.dateTime(m.createdAt)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentPhotos extends ConsumerWidget {
  const _RecentPhotos({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final trainings = ref.watch(myTrainingsProvider).value ?? const <Training>[];
    final withPhotos = trainings.where((t) => t.groupId == group.id && t.photoUrls.isNotEmpty).toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
    final photos = [
      for (final t in withPhotos.take(4))
        for (final p in t.photoUrls) (t, p),
    ].take(10).toList();
    if (photos.isEmpty) {
      return AppCard(
        child: EmptyState(compact: true, icon: Icons.photo_library_outlined, title: l.noPhotos),
      );
    }
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, i) {
          final (t, p) = photos[i];
          return GestureDetector(
            onTap: () => context.push(Routes.training(t.id)),
            child: MediaPhoto(refPath: p, sportKey: group.sportId, size: 120),
          );
        },
      ),
    );
  }
}

/// Caps header rows to the dashboard width on large windows.
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
