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
import '../../../core/widgets/cancel_reason_dialog.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/visuals.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../clubs/presentation/clubs_providers.dart';
import '../../clubs/presentation/venue_picker.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import '../domain/match.dart';
import 'matches_providers.dart';
import '../../calendar/presentation/add_to_calendar.dart';
import '../../attendance/domain/scheduled_event.dart';
import '../../attendance/presentation/attendance_widgets.dart';
import 'match_result_widgets.dart';

/// Coach adds / edits a match (v1.1 §8): group, date & time, venue,
/// opponent, type, home/away, comment.
class MatchFormScreen extends ConsumerStatefulWidget {
  const MatchFormScreen({super.key, this.groupId, this.matchId});

  final String? groupId;
  final String? matchId;

  bool get isEdit => matchId != null;

  @override
  ConsumerState<MatchFormScreen> createState() => _MatchFormScreenState();
}

class _MatchFormScreenState extends ConsumerState<MatchFormScreen> {
  String? _groupId;
  DateTime? _date;
  TimeOfDay? _time;
  String? _venueId;
  final _opponent = TextEditingController();
  final _comment = TextEditingController();
  MatchType _type = MatchType.friendly;
  HomeAway _homeAway = HomeAway.home;
  bool _init = false;
  bool _saving = false;
  List<String> _errors = const [];

  @override
  void initState() {
    super.initState();
    _groupId = widget.groupId;
  }

  @override
  void dispose() {
    _opponent.dispose();
    _comment.dispose();
    super.dispose();
  }

  void _initFrom(SportMatch m) {
    if (_init) return;
    _init = true;
    _groupId = m.groupId;
    _date = DateUtils.dateOnly(m.startAt);
    _time = TimeOfDay.fromDateTime(m.startAt);
    _venueId = m.venueId;
    _opponent.text = m.opponentName;
    _comment.text = m.description ?? '';
    _type = m.matchType;
    _homeAway = m.homeAway;
  }

  Future<void> _save() async {
    final l = context.l10n;
    final start = _date == null || _time == null
        ? null
        : DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    final draft = MatchDraft(
      groupId: _groupId ?? '',
      venueId: _venueId ?? '',
      startAt: start ?? DateTime.fromMillisecondsSinceEpoch(0),
      opponentName: _opponent.text,
      matchType: _type,
      homeAway: _homeAway,
      description: _comment.text.trim().isEmpty ? null : _comment.text,
    );
    final errors = [
      if (_groupId == null || start == null) 'required',
      ...MatchDraft.validate(draft, now: ref.read(clockProvider)(), isEdit: widget.isEdit),
    ];
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    setState(() => _saving = true);
    final repo = ref.read(matchesRepositoryProvider);
    final ok = await runGuarded(
      context,
      () => widget.isEdit ? repo.update(widget.matchId!, draft) : repo.create(draft),
      success: l.matchSaved,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) context.popOrHome();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (widget.isEdit) {
      final async = ref.watch(matchProvider(widget.matchId!));
      final m = async.value;
      if (m != null) _initFrom(m);
      if (!_init) {
        return Scaffold(
          appBar: AppBar(title: Text(l.editMatch)),
          body: async.hasError
              ? ErrorView(error: async.error!, onRetry: () => ref.invalidate(matchProvider(widget.matchId!)))
              : async.hasValue
              ? EmptyState(icon: Icons.event_busy_rounded, title: l.itemGoneTitle, body: l.itemGoneBody)
              : const SkeletonList(),
        );
      }
    }
    final me = ref.watch(currentUserProvider);
    final groups = (ref.watch(myGroupsProvider).value ?? const <Group>[])
        .where((g) => g.hasCoach(me?.id ?? ''))
        .toList();
    final group = groups.where((g) => g.id == _groupId).firstOrNull ?? (groups.length == 1 ? groups.first : null);
    _groupId ??= group?.id;
    final now = ref.watch(clockProvider)();
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? l.editMatch : l.newMatch)),
      body: SafeArea(
        child: ConstrainedContent(
          maxWidth: Breakpoints.readable,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (!widget.isEdit && groups.length > 1) ...[
                SectionHeader(l.groupLabel),
                DropdownButtonFormField<String>(
                  key: const Key('match-group'),
                  initialValue: _groupId,
                  isExpanded: true,
                  items: [for (final g in groups) DropdownMenuItem(value: g.id, child: Text(g.name))],
                  onChanged: (v) => setState(() {
                    _groupId = v;
                    _venueId = null;
                  }),
                ),
              ],
              SectionHeader(l.matchOpponent),
              TextField(
                key: const Key('match-opponent'),
                controller: _opponent,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(hintText: l.matchOpponent),
              ),
              SectionHeader(l.dateLabel),
              DateTimeRow(
                keyPrefix: 'match',
                date: _date,
                time: _time,
                firstDate: widget.isEdit ? now.subtract(const Duration(days: 30)) : DateUtils.dateOnly(now),
                onDate: (d) => setState(() => _date = d),
                onTime: (t) => setState(() => _time = t),
              ),
              SectionHeader(l.venueLabel),
              VenuePicker(
                fieldKey: const Key('match-venue'),
                group: group,
                value: _venueId,
                onChanged: (v) => setState(() => _venueId = v),
              ),
              SectionHeader(l.matchType),
              SegmentedButton<MatchType>(
                segments: [
                  for (final t in MatchType.values) ButtonSegment(value: t, label: Text(matchTypeLabel(context, t))),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              SectionHeader(l.matchHomeAway),
              SegmentedButton<HomeAway>(
                segments: [
                  for (final h in HomeAway.values) ButtonSegment(value: h, label: Text(homeAwayLabel(context, h))),
                ],
                selected: {_homeAway},
                onSelectionChanged: (s) => setState(() => _homeAway = s.first),
              ),
              SectionHeader(l.matchComment),
              TextField(controller: _comment, maxLength: 1000, minLines: 2, maxLines: 5),
              FormErrors(errors: _errors),
              const SizedBox(height: AppSpacing.md),
              LoadingButton(
                key: const Key('match-save'),
                label: l.save,
                loading: _saving,
                onPressed: _save,
                icon: Icons.check_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final match = ref.watch(matchProvider(matchId));
    return Scaffold(
      appBar: AppBar(title: Text(l.matchTitle)),
      body: AsyncView<SportMatch?>(
        value: match,
        onRetry: () => ref.invalidate(matchProvider(matchId)),
        data: (m) {
          if (m == null) return EmptyState(icon: Icons.search_off_rounded, title: l.errorNotFound);
          return _MatchBody(match: m);
        },
      ),
    );
  }
}

class _MatchBody extends ConsumerWidget {
  const _MatchBody({required this.match});

  final SportMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final t = Theme.of(context).textTheme;
    final group = ref.watch(groupsByIdProvider)[match.groupId];
    final venue = ref.watch(venuesByIdProvider)[match.venueId];
    final me = ref.watch(currentUserProvider);
    final isCoach = me != null && group != null && group.hasCoach(me.id) && me.isApprovedCoach;
    final cancelled = match.status == MatchStatus.cancelled;
    final now = ref.watch(clockProvider)();
    return ConstrainedContent(
      maxWidth: Breakpoints.readable,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            gradient: cancelled ? AppColors.nightGradient : SportVisuals.gradient(group?.sportId ?? ''),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      StatusPill(label: l.matchBadge, color: AppColors.volt, dense: true),
                      StatusPill(label: matchTypeLabel(context, match.matchType), color: Colors.white, dense: true),
                      if (cancelled) StatusPill(label: l.statusCancelled, color: AppColors.coral, dense: true),
                      if (match.status == MatchStatus.played)
                        StatusPill(label: l.matchPlayed, color: Colors.white, dense: true),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l.matchVs(match.opponentName),
                    style: t.headlineSmall?.copyWith(
                      color: Colors.white,
                      decoration: cancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${f.weekdayDayMonth(match.startAt)} · ${f.time(match.startAt)}',
                    style: t.titleMedium?.copyWith(color: Colors.white),
                  ),
                  if (group != null)
                    Text(
                      '${group.name} · ${homeAwayLabel(context, match.homeAway)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),
          ),
          if (!cancelled)
            AddToCalendarButton(
              key: const Key('match-add-calendar'),
              event: matchIcsEvent(context, match, group, venue),
              kind: 'match',
              slug: match.id,
            ),
          if (match.result != null) ...[const SizedBox(height: AppSpacing.sm), MatchResultCard(match: match)],
          if (isCoach && match.result != null) _ResultHistory(matchId: match.id),
          if (cancelled && match.cancelReason != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              key: const Key('match-cancel-reason'),
              color: AppColors.danger.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.danger),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(l.cancelledWithReason(cancelReasonText(context, match.cancelReason!)))),
                ],
              ),
            ),
          ],
          if (venue != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Row(
                children: [
                  Icon(venueTypeIcon(venue.type)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(venue.name, style: t.titleSmall),
                        Text(venue.address, style: t.bodySmall),
                      ],
                    ),
                  ),
                  if (!cancelled)
                    FilledButton.tonalIcon(
                      onPressed: () => openDirections(context, venue.location, venue.name),
                      icon: const Icon(Icons.directions_rounded),
                      label: Text(l.directions),
                    ),
                ],
              ),
            ),
          ],
          if ((match.description ?? '').isNotEmpty) ...[SectionHeader(l.matchComment), Text(match.description!)],
          if (isCoach && !cancelled) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  key: const Key('match-edit'),
                  onPressed: () => context.push(Routes.editMatch(match.id)),
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(l.edit),
                ),
                if (match.startAt.isBefore(now))
                  FilledButton.icon(
                    key: const Key('match-result-enter'),
                    onPressed: () => showMatchResultDialog(context, ref, match),
                    icon: const Icon(Icons.scoreboard_rounded),
                    label: Text(match.result == null ? l.matchResultEnter : l.matchResultCorrect),
                  ),
                if (match.status != MatchStatus.played && match.result == null && match.startAt.isBefore(now))
                  OutlinedButton.icon(
                    onPressed: () =>
                        runGuarded(context, () => ref.read(matchesRepositoryProvider).markPlayed(match.id)),
                    icon: const Icon(Icons.flag_rounded),
                    label: Text(l.markPlayed),
                  ),
                OutlinedButton.icon(
                  key: const Key('match-cancel'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                  onPressed: () async {
                    final reason = await showCancelReasonDialog(context, title: l.cancelMatch);
                    if (reason == null || !context.mounted) return;
                    await runGuarded(
                      context,
                      () => ref.read(matchesRepositoryProvider).cancel(match.id, reason),
                      success: l.matchCancelledSnack,
                    );
                  },
                  icon: const Icon(Icons.cancel_rounded),
                  label: Text(l.cancelMatch),
                ),
              ],
            ),
          ],
          // v1.7: matches have the same RSVP and attendance workflow as trainings.
          if (isCoach) CoachAttendanceSummary(event: ScheduledEvent.match(match), group: group),
          if (me != null && me.isParent && group != null) RsvpSection(event: ScheduledEvent.match(match), group: group),
        ],
      ),
    );
  }
}

/// Coach: score corrections (who / when / from → to), newest first.
class _ResultHistory extends ConsumerWidget {
  const _ResultHistory({required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    // Re-read whenever the match (its result version) changes.
    final version = ref.watch(matchProvider(matchId)).value?.result?.version;
    return FutureBuilder<List<MatchResultChange>>(
      key: ValueKey('history-$matchId-$version'),
      future: ref.read(matchesRepositoryProvider).resultHistory(matchId),
      builder: (context, snap) {
        final list = snap.data ?? const <MatchResultChange>[];
        if (list.length < 2) return const SizedBox.shrink();
        String pair((int, int)? p) => p == null ? '—' : '${p.$1}:${p.$2}';
        return Column(
          key: const Key('match-result-history'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(l.matchResultHistory),
            for (final c in list)
              Text(
                '${f.dateTime(c.at)} · ${pair(c.from)} → ${pair(c.to)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        );
      },
    );
  }
}

/// Compact "next match" card for dashboards (v1.1 §8).
class NextMatchCard extends ConsumerWidget {
  const NextMatchCard({super.key, required this.match});

  final SportMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final group = ref.watch(groupsByIdProvider)[match.groupId];
    final venue = ref.watch(venuesByIdProvider)[match.venueId];
    return AppCard(
      key: const Key('next-match-card'),
      onTap: () => context.push(Routes.match(match.id)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.volt.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: AppColors.navy),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.nextMatch, style: Theme.of(context).textTheme.labelMedium),
                Text(
                  l.matchVs(match.opponentName),
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [
                    f.dateTime(match.startAt),
                    if (venue != null) venue.name,
                    if (group != null) homeAwayLabel(context, match.homeAway),
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
