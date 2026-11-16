import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_picker.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../parent/presentation/parent_context.dart';
import '../../trainings/domain/training.dart';
import '../../trainings/presentation/training_detail_screen.dart';
import '../../trainings/presentation/training_widgets.dart';
import '../../trainings/presentation/trainings_providers.dart';
import '../domain/calendar_logic.dart';
import '../../clubs/presentation/clubs_providers.dart';
import '../../matches/domain/match.dart';
import '../../matches/presentation/match_result_widgets.dart';
import '../../matches/presentation/matches_providers.dart';
import 'add_to_calendar.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

const _allKey = 'all';

String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

Color _trainingColor(Training e, Map<String, Group> groups) => e.status == TrainingStatus.cancelled
    ? AppColors.danger
    : (e.status == TrainingStatus.moved ? AppColors.warning : SportVisuals.color(groups[e.groupId]?.sportId ?? ''));

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focused = ref.read(clockProvider)();
  DateTime? _selected;
  CalendarFormat _format = CalendarFormat.month;
  bool _allChildren = false;

  /// Training shown in the detail pane on large windows.
  String? _detailId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    final now = ref.watch(clockProvider)();
    final trainings = ref.watch(myTrainingsProvider);
    final groups = ref.watch(groupsByIdProvider);
    final scheme = Theme.of(context).colorScheme;

    // Parents see the selected child's groups (or all children); coaches see
    // all assigned groups.
    Set<String>? groupFilter;
    ParentSelection? sel;
    if (user?.isParent ?? false) {
      sel = ref.watch(parentSelectionProvider).value;
      if (!_allChildren && sel?.child != null) {
        groupFilter = groups.values.where((g) => g.hasChild(sel!.child!.id)).map((g) => g.id).toSet();
      }
    }
    // v1.9.1 (M27): matches load separately; an error is shown with a retry
    // instead of looking like "no matches".
    final matchesAsync = ref.watch(myMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navCalendar),
        actions: [
          IconButton(
            key: const Key('calendar-export'),
            tooltip: l.exportSchedule,
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () {
              final all = trainings.value ?? const <Training>[];
              final venues = ref.read(venuesByIdProvider);
              final horizon = now.add(const Duration(days: 60));
              final events = [
                for (final t in all)
                  if ((groupFilter == null || groupFilter.contains(t.groupId)) &&
                      t.status != TrainingStatus.cancelled &&
                      t.startAt.isAfter(now) &&
                      t.startAt.isBefore(horizon))
                    trainingIcsEvent(context, t, groups[t.groupId], venues[t.venueId]),
              ]..sort((a, b) => a.start.compareTo(b.start));
              shareIcs(context, ref, events, kind: 'schedule', slug: user?.id ?? 'me');
            },
          ),
        ],
      ),
      body: AsyncView<List<Training>>(
        value: trainings,
        onRetry: () => ref.invalidate(myTrainingsProvider),
        data: (all) {
          final visible = groupFilter == null ? all : all.where((t) => groupFilter!.contains(t.groupId)).toList();
          final byDay = CalendarLogic.byDay(visible);
          final selected = _selected ?? DateUtils.dateOnly(now);
          final dayList = CalendarLogic.onDay(byDay, selected);
          final upcoming = CalendarLogic.upcoming(visible, now, limit: 8);
          // v1.5: matches of the same groups on the selected day, with final scores.
          final visibleGroups = groupFilter ?? groups.keys.toSet();
          final allMatches = matchesAsync.value ?? const <SportMatch>[];
          final visibleMatches = allMatches.where((m) => visibleGroups.contains(m.groupId)).toList();
          // Keyed by local y-m-d (table_calendar hands out UTC days).
          final matchesByDay = <String, List<SportMatch>>{};
          for (final m in visibleMatches) {
            (matchesByDay[_dayKey(m.startAt)] ??= []).add(m);
          }
          final dayMatches = [...?matchesByDay[_dayKey(selected)]]..sort((a, b) => a.startAt.compareTo(b.startAt));
          final recentResults = resultsFor(allMatches, visibleGroups).take(3).toList();
          final table = AppCard(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: TableCalendar<Object>(
              locale: context.localeName,
              firstDay: now.subtract(const Duration(days: 365)),
              lastDay: now.add(const Duration(days: 365)),
              focusedDay: _focused,
              calendarFormat: _format,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableCalendarFormats: {
                CalendarFormat.month: l.navCalendar,
                CalendarFormat.twoWeeks: '2w',
                CalendarFormat.week: '1w',
              },
              onFormatChanged: (f) => setState(() => _format = f),
              selectedDayPredicate: (d) => isSameDay(d, selected),
              onDaySelected: (s, f) => setState(() {
                _selected = s;
                _focused = f;
              }),
              onPageChanged: (f) => _focused = f,
              eventLoader: (d) => [...CalendarLogic.onDay(byDay, d), ...?matchesByDay[_dayKey(d)]],
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: Theme.of(context).textTheme.titleMedium!,
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
                todayTextStyle: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800),
                selectedDecoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                weekendTextStyle: TextStyle(color: scheme.onSurfaceVariant),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  final dayTrainings = events.whereType<Training>().take(3);
                  final hasMatch = events.any((e) => e is SportMatch);
                  return Positioned(
                    bottom: 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final e in dayTrainings) _TrainingDot(color: _trainingColor(e, groups)),
                        // Matches: a trophy (different shape and colour from
                        // the training dots), explained by the legend below.
                        if (hasMatch) _MatchMarker(key: Key('calendar-match-marker-${_dayKey(day)}')),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
          final calendarCard = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sel != null && sel.children.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppChoiceGroup<String>(
                    key: const Key('calendar-child-selector'),
                    keyPrefix: 'calendar-child',
                    label: l.s191CalendarWhose,
                    value: _allChildren || sel.child == null ? _allKey : sel.child!.id,
                    choices: [
                      (_allKey, l.allChildren, Icons.groups_rounded),
                      for (final c in sel.children) (c.id, c.firstName, null),
                    ],
                    onChanged: (v) {
                      setState(() => _allChildren = v == _allKey);
                      // Same selection as the child chips on Home.
                      if (v != _allKey) ref.read(selectionContextProvider.notifier).selectChild(v);
                    },
                  ),
                ),
              table,
              const SizedBox(height: AppSpacing.xs),
              const _CalendarLegend(),
            ],
          );
          List<Widget> lists({bool selectable = false}) => [
            SectionHeader(Fmt.of(context).weekdayDayMonth(selected)),
            if (dayList.isEmpty && dayMatches.isEmpty)
              AppCard(
                child: EmptyState(compact: true, icon: Icons.event_available_rounded, title: l.noTrainingsDay),
              )
            else
              ..._tiles(dayList, groups, showDate: false, selectable: selectable),
            if (matchesAsync is AsyncError)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: AppCard(
                  key: const Key('calendar-matches-error'),
                  child: Column(
                    children: [
                      Text(l.s191CalendarMatchesError, style: Theme.of(context).textTheme.titleSmall),
                      ErrorView(
                        error: matchesAsync.error!,
                        compact: true,
                        onRetry: () => ref.invalidate(myMatchesProvider),
                      ),
                    ],
                  ),
                ),
              )
            else if (matchesAsync.isLoading && !matchesAsync.hasValue)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xs),
                child: Skeleton(key: Key('calendar-matches-loading'), height: 64, radius: AppSpacing.radius),
              ),
            for (final m in dayMatches)
              Padding(
                key: Key('calendar-match-${m.id}'),
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: MatchResultTile(match: m),
              ),
            if (recentResults.isNotEmpty) ...[
              SectionHeader(l.profileMatchResults),
              for (final m in recentResults)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: MatchResultTile(match: m),
                ),
            ],
            SectionHeader(l.upcoming),
            if (upcoming.isEmpty)
              AppCard(
                child: EmptyState(compact: true, icon: Icons.event_busy_rounded, title: l.noUpcomingTrainings),
              )
            else
              ..._tiles(upcoming, groups, selectable: selectable),
          ];
          return LayoutBuilder(
            builder: (context, c) {
              const pad = EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xxl);
              // Phone / narrow: single scrolling column (original design).
              if (c.maxWidth < Breakpoints.expanded) {
                return ListView(padding: pad, children: [calendarCard, ...lists()]);
              }
              // Large pane (e.g. iPad Pro landscape beside the sidebar):
              // calendar + lists on the left, training detail on the right.
              if (c.maxWidth >= 1080) {
                final detailId = _detailId ?? (dayList.isNotEmpty ? dayList.first.id : upcoming.firstOrNull?.id);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 440,
                      child: ListView(padding: pad, children: [calendarCard, ...lists(selectable: true)]),
                    ),
                    VerticalDivider(width: 1, color: Theme.of(context).colorScheme.outline),
                    Expanded(
                      child: detailId == null
                          ? EmptyState(icon: Icons.event_note_rounded, title: l.noUpcomingTrainings)
                          : TrainingDetailScreen(key: ValueKey(detailId), trainingId: detailId, embedded: true),
                    ),
                  ],
                );
              }
              // Expanded: calendar beside the lists.
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(padding: pad, children: [calendarCard]),
                  ),
                  Expanded(
                    child: ListView(padding: pad, children: lists()),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _tiles(
    List<Training> list,
    Map<String, Group> groups, {
    bool showDate = true,
    bool selectable = false,
  }) => [
    for (final t in list)
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: TrainingTile(
          training: t,
          group: groups[t.groupId],
          showDate: showDate,
          selected: selectable && t.id == _detailId,
          onTap: selectable ? () => setState(() => _detailId = t.id) : null,
        ),
      ),
  ];
}

class _TrainingDot extends StatelessWidget {
  const _TrainingDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    margin: const EdgeInsets.symmetric(horizontal: 1),
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

/// Match day marker: a trophy, so it differs from training dots by shape
/// as well as colour.
class _MatchMarker extends StatelessWidget {
  const _MatchMarker({super.key});

  static const color = AppColors.coral;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.s191CalendarLegendMatch,
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 1),
      child: Icon(Icons.emoji_events_rounded, size: 10, color: color),
    ),
  );
}

/// Explains the markers: dot = training, trophy = match.
class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final style = Theme.of(context).textTheme.bodySmall;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      key: const Key('calendar-legend'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: 4,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TrainingDot(color: scheme.primary),
              const SizedBox(width: 6),
              Text(l.s191CalendarLegendTraining, style: style),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, size: 14, color: _MatchMarker.color),
              const SizedBox(width: 4),
              Text(l.s191CalendarLegendMatch, style: style),
            ],
          ),
        ],
      ),
    );
  }
}
