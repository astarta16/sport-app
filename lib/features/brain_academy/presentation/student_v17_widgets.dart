import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/services/launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../attendance/domain/attendance.dart';
import '../../attendance/domain/scheduled_event.dart';
import '../../clubs/domain/club.dart';
import '../../organizations/domain/coach_contact.dart';
import '../../organizations/domain/organization.dart';
import '../../organizations/presentation/org_providers.dart';
import '../../sports/presentation/sport_label.dart';
import '../../sports/presentation/sports_providers.dart';
import '../domain/brain_models.dart';
import '../domain/scoring.dart';
import '../domain/student_view.dart';
import 'brain_providers.dart';

/// v1.7 student dashboard: upcoming trainings AND matches with times,
/// venues, a map and external directions; cancellations and reschedules
/// are flagged. Only the student's own events and their public venues.
class StudentEventsSection extends ConsumerWidget {
  const StudentEventsSection({super.key, required this.view});

  final StudentView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = ref.watch(clockProvider)();
    final horizon = now.add(const Duration(days: 21));
    final events =
        [
            for (final t in view.trainings) ScheduledEvent.training(t),
            for (final m in view.matches) ScheduledEvent.match(m),
          ].where((e) => e.endAt.isAfter(now) && e.startAt.isBefore(horizon)).toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return Column(
      key: const Key('student-events'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.studentUpcomingEvents),
        if (events.isEmpty)
          Text(l.studentNothing, style: Theme.of(context).textTheme.bodySmall)
        else
          for (final e in events.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _StudentEventCard(event: e, view: view),
            ),
      ],
    );
  }
}

class _StudentEventCard extends StatelessWidget {
  const _StudentEventCard({required this.event, required this.view});

  final ScheduledEvent event;
  final StudentView view;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final t = Theme.of(context).textTheme;
    final venue = view.venues[event.venueId];
    final group = view.groups.where((g) => g.id == event.groupId).firstOrNull;
    final isMatch = event.type == EventType.match;
    return AppCard(
      key: Key('student-event-${event.id}'),
      color: event.cancelled ? AppColors.danger.withValues(alpha: 0.06) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isMatch ? Icons.emoji_events_rounded : Icons.sports_rounded, color: AppColors.blue),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  isMatch ? l.matchVs(event.title) : (group?.name ?? l.studentNextTraining),
                  style: t.titleSmall?.copyWith(decoration: event.cancelled ? TextDecoration.lineThrough : null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${f.weekdayDayMonth(event.startAt)} · ${f.time(event.startAt)}–${f.time(event.endAt)}',
            style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (venue != null) Text('${venue.name} · ${venue.address}', style: t.bodySmall),
          if (event.cancelled || event.rescheduled || event.previousVenueId != null) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (event.cancelled)
                  StatusPill(
                    key: Key('student-event-cancelled-${event.id}'),
                    label: l.statusCancelled,
                    color: AppColors.danger,
                    icon: Icons.cancel_rounded,
                    dense: true,
                  )
                else if (event.rescheduled)
                  StatusPill(
                    key: Key('student-event-moved-${event.id}'),
                    label: l.eventRescheduled,
                    color: AppColors.warning,
                    icon: Icons.update_rounded,
                    dense: true,
                  ),
                if (!event.cancelled && event.previousVenueId != null)
                  StatusPill(
                    label: l.eventLocationChanged,
                    color: AppColors.warning,
                    icon: Icons.wrong_location_rounded,
                    dense: true,
                  ),
              ],
            ),
          ],
          if (venue != null && !event.cancelled) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                OutlinedButton.icon(
                  key: Key('student-event-map-${event.id}'),
                  onPressed: () => showVenueMapSheet(context, venue),
                  icon: const Icon(Icons.map_rounded),
                  label: Text(l.eventShowMap),
                ),
                FilledButton.tonalIcon(
                  key: Key('student-event-directions-${event.id}'),
                  onPressed: () => openDirections(context, venue.location, venue.name),
                  icon: const Icon(Icons.directions_rounded),
                  label: Text(l.directions),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Venue location with a map marker and an external-directions button.
Future<void> showVenueMapSheet(BuildContext context, Venue venue) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) {
    final l = context.l10n;
    final point = LatLng(venue.location.latitude, venue.location.longitude);
    return SafeArea(
      child: Padding(
        key: const Key('venue-map-sheet'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(venue.name, style: Theme.of(context).textTheme.titleMedium),
            Text(venue.address, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              child: SizedBox(
                height: 220,
                child: FlutterMap(
                  options: MapOptions(initialCenter: point, initialZoom: 15),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'ge.sportparent.sport_parent_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          key: const Key('venue-marker'),
                          point: point,
                          width: 44,
                          height: 44,
                          child: const Icon(Icons.location_on_rounded, color: AppColors.danger, size: 44),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              key: const Key('venue-map-directions'),
              onPressed: () => openDirections(context, venue.location, venue.name),
              icon: const Icon(Icons.directions_rounded),
              label: Text(l.directions),
            ),
          ],
        ),
      ),
    );
  },
);

/// Assigned coaches (public profile only) and the parent-mediated
/// "Contact coach" request. Students never get phone numbers or a private
/// chat with an adult; their guardian decides and uses the parent–coach
/// chat or call.
class StudentCoachesSection extends ConsumerWidget {
  const StudentCoachesSection({super.key, required this.view});

  final StudentView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final sports = ref.watch(sportsByIdProvider);
    final requests = ref.watch(myContactRequestsProvider).value ?? const <CoachContactRequest>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.studentMyCoach),
        if (view.coachNames.isEmpty) Text(l.studentNothing, style: Theme.of(context).textTheme.bodySmall),
        for (final e in view.coachNames.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: AppCard(
              key: Key('student-coach-${e.key}'),
              child: Row(
                children: [
                  InitialsAvatar(name: e.value, size: 44),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.value, style: Theme.of(context).textTheme.titleSmall),
                        Text(
                          [
                            for (final g in view.groups.where((g) => g.coachIds.contains(e.key)))
                              '${sports[g.sportId]?.label(context) ?? g.sportId} · ${g.name}',
                          ].join('\n'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (requests.any((r) => r.coachId == e.key && r.status == ContactRequestStatus.open))
                          Text(
                            l.contactCoachPending,
                            key: Key('contact-pending-${e.key}'),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning),
                          ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    key: Key('contact-coach-${e.key}'),
                    tooltip: l.contactCoach,
                    onPressed: () => _contactSheet(context, ref, e.key, e.value),
                    icon: const Icon(Icons.forum_rounded),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _contactSheet(BuildContext context, WidgetRef ref, String coachId, String coachName) async {
    final l = context.l10n;
    final group = view.groups.where((g) => g.coachIds.contains(coachId)).first;
    final topic = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          key: const Key('contact-coach-sheet'),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.contactCoachTitle(coachName), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(l.contactCoachExplain, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              for (final t in CoachContactRequest.topics)
                ListTile(
                  key: Key('contact-topic-$t'),
                  leading: const Icon(Icons.chat_bubble_outline_rounded),
                  title: Text(contactTopicLabel(context, t)),
                  onTap: () => Navigator.pop(context, t),
                ),
            ],
          ),
        ),
      ),
    );
    if (topic == null || !context.mounted) return;
    await runGuarded(
      context,
      () => ref.read(coachContactRepositoryProvider).request(coachId: coachId, groupId: group.id, topic: topic),
      success: l.contactCoachSent,
    );
  }
}

String contactTopicLabel(BuildContext context, String topic) {
  final l = context.l10n;
  return switch (topic) {
    'question' => l.contactTopicQuestion,
    'absence' => l.contactTopicAbsence,
    'training' => l.contactTopicTraining,
    _ => l.contactTopicOther,
  };
}

/// Real progress from stored results (shared scoring service): points,
/// completed games, per-game points / accuracy / level / best, weekly
/// points and recent history. Nothing here is static or invented.
class BrainPointsDashboard extends ConsumerWidget {
  const BrainPointsDashboard({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final t = Theme.of(context).textTheme;
    final results = ref.watch(brainResultsProvider(childId)).value ?? const <GameResult>[];
    final now = ref.watch(clockProvider)();
    final s = ScoringService.summarize(results, now: now);
    final maxWeek = s.weeklyPoints.fold<int>(1, (a, b) => b > a ? b : a);
    return Column(
      key: Key('brain-points-$childId'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          color: const Color(0xFF7C4DFF).withValues(alpha: 0.10),
          child: Row(
            children: [
              _Stat(key: const Key('points-total'), value: '${s.totalPoints}', label: l.pointsTotal),
              _Stat(key: const Key('points-games'), value: '${s.gamesCompleted}', label: l.pointsGamesCompleted),
              _Stat(key: const Key('points-week'), value: '${s.pointsThisWeek}', label: l.pointsThisWeek),
            ],
          ),
        ),
        SectionHeader(l.pointsWeekly),
        SizedBox(
          height: 90,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${s.weeklyPoints[i]}', style: t.labelSmall),
                        Container(
                          height: 60 * s.weeklyPoints[i] / maxWeek + 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF).withValues(alpha: i == 6 ? 1 : .55),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SectionHeader(l.pointsByGame),
        for (final g in BrainGame.values)
          ListTile(
            key: Key('points-game-${g.name}'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(gameIcon(g)),
            title: Text(gameName(context, g)),
            subtitle: s.accuracyByGame[g] == null
                ? Text(l.studentNothing)
                : Text(
                    '${l.pointsAccuracy((s.accuracyByGame[g]! * 100).round())} · '
                    '${difficultyLabel(context, s.highestLevel[g]!.$1)} ${l.gameLevel(s.highestLevel[g]!.$2)} · '
                    '${l.pointsBest(s.bestScoreByGame[g] ?? 0)}',
                  ),
            trailing: Text(l.pointsValue(s.pointsByGame[g] ?? 0), style: t.titleSmall),
          ),
        SectionHeader(l.pointsRecent),
        if (s.recent.isEmpty) Text(l.studentNothing, style: t.bodySmall),
        for (final r in s.recent)
          ListTile(
            key: Key('history-${r.result.id}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              r.result.completed ? Icons.check_circle_rounded : Icons.replay_rounded,
              color: r.result.completed ? AppColors.success : AppColors.neutral,
            ),
            title: Text('${gameName(context, r.result.game)} · ${difficultyLabel(context, r.result.difficulty)}'),
            subtitle: Text('${f.weekdayDayMonth(r.result.playedAt)} ${f.time(r.result.playedAt)}'),
            trailing: Text(l.pointsValue(r.points)),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

/// Organization leaderboards the student may see (one per organization
/// that has them enabled). Without consent or enough participants the
/// student sees a note and keeps their private progress.
class StudentLeaderboards extends ConsumerWidget {
  const StudentLeaderboards({super.key, required this.view});

  final StudentView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgs = {for (final g in view.groups) g.clubId}.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final o in orgs)
          if (ref.watch(orgConfigProvider(o)).value case final cfg? when cfg.leaderboardOn)
            LeaderboardCard(orgId: o, childId: view.child.id, config: cfg),
      ],
    );
  }
}

class LeaderboardCard extends ConsumerStatefulWidget {
  const LeaderboardCard({super.key, required this.orgId, required this.childId, required this.config});

  final String orgId;
  final String childId;
  final OrgConfig config;

  @override
  ConsumerState<LeaderboardCard> createState() => _LeaderboardCardState();
}

class _LeaderboardCardState extends ConsumerState<LeaderboardCard> {
  LeaderboardPeriod? _period;
  BrainGame? _game;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final periods = LeaderboardPeriod.values.where(widget.config.leaderboard.periods.contains).toList();
    final period = _period ?? (periods.isEmpty ? LeaderboardPeriod.week : periods.first);
    final board = ref.watch(leaderboardProvider((widget.orgId, widget.childId, period, _game)));
    return Column(
      key: Key('leaderboard-${widget.orgId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.leaderboardTitle(widget.config.branding.nameFor(locale, fallback: widget.orgId))),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final p in periods)
              ChoiceChip(
                key: Key('lb-period-${p.name}'),
                label: Text(leaderboardPeriodLabel(context, p)),
                selected: p == period,
                onSelected: (_) => setState(() => _period = p),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: DropdownButton<BrainGame?>(
                key: const Key('lb-game'),
                isExpanded: true,
                value: _game,
                items: [
                  DropdownMenuItem(value: null, child: Text(l.leaderboardAllGames)),
                  for (final g in widget.config.leaderboard.effectiveGames)
                    DropdownMenuItem(value: g, child: Text(gameName(context, g))),
                ],
                onChanged: (g) => setState(() => _game = g),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        AsyncView<LeaderboardBoard>(
          value: board,
          data: (b) {
            if (b.unavailable != null) {
              return AppCard(
                key: Key('lb-unavailable-${b.unavailable!.name}'),
                child: Text(switch (b.unavailable!) {
                  LeaderboardUnavailable.disabled => l.leaderboardDisabled,
                  LeaderboardUnavailable.notConsented => l.leaderboardNoConsent,
                  LeaderboardUnavailable.tooFewParticipants => l.leaderboardTooFew,
                }),
              );
            }
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (b.ageBand != null)
                    Text(l.leaderboardAgeBand(b.ageBand!), style: Theme.of(context).textTheme.bodySmall),
                  for (final e in b.entries.take(10))
                    ListTile(
                      key: Key('lb-row-${e.rank}'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      selected: e.childId == widget.childId,
                      leading: CircleAvatar(radius: 14, child: Text('${e.rank}')),
                      title: Text(
                        e.childId == widget.childId ? '${e.displayName} (${l.leaderboardYou})' : e.displayName,
                      ),
                      subtitle: e.badges == 0 ? null : Text(l.leaderboardBadges(e.badges)),
                      trailing: Text(l.pointsValue(e.points)),
                    ),
                  Text(l.leaderboardPrivacyNote, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

String leaderboardPeriodLabel(BuildContext context, LeaderboardPeriod p) {
  final l = context.l10n;
  return switch (p) {
    LeaderboardPeriod.week => l.leaderboardWeek,
    LeaderboardPeriod.month => l.leaderboardMonth,
    LeaderboardPeriod.allTime => l.leaderboardAllTime,
  };
}
