import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
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
import 'add_to_calendar.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

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
    if (user?.isParent ?? false) {
      final sel = ref.watch(parentSelectionProvider).value;
      if (!_allChildren && sel?.child != null) {
        groupFilter = groups.values.where((g) => g.hasChild(sel!.child!.id)).map((g) => g.id).toSet();
      }
    }

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
          if (user?.isParent ?? false)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(l.allChildren),
                selected: _allChildren,
                onSelected: (v) => setState(() => _allChildren = v),
              ),
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
          final calendarCard = AppCard(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: TableCalendar<Training>(
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
              eventLoader: (d) => CalendarLogic.onDay(byDay, d),
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
                  return Positioned(
                    bottom: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final e in events.take(3))
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: e.status == TrainingStatus.cancelled
                                  ? AppColors.danger
                                  : (e.status == TrainingStatus.moved
                                        ? AppColors.warning
                                        : SportVisuals.color(groups[e.groupId]?.sportId ?? '')),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
          List<Widget> lists({bool selectable = false}) => [
            SectionHeader(Fmt.of(context).weekdayDayMonth(selected)),
            if (dayList.isEmpty)
              AppCard(
                child: EmptyState(compact: true, icon: Icons.event_available_rounded, title: l.noTrainingsDay),
              )
            else
              ..._tiles(dayList, groups, showDate: false, selectable: selectable),
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
