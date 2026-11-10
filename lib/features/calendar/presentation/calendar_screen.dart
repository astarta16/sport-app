import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../parent/presentation/parent_context.dart';
import '../../trainings/domain/training.dart';
import '../../trainings/presentation/training_widgets.dart';
import '../../trainings/presentation/trainings_providers.dart';
import '../domain/calendar_logic.dart';

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
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xxl),
            children: [
              AppCard(
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
              ),
              SectionHeader(Fmt.of(context).weekdayDayMonth(selected)),
              if (dayList.isEmpty)
                AppCard(
                  child: EmptyState(compact: true, icon: Icons.event_available_rounded, title: l.noTrainingsDay),
                )
              else
                ..._tiles(dayList, groups, showDate: false),
              SectionHeader(l.upcoming),
              if (upcoming.isEmpty)
                AppCard(
                  child: EmptyState(compact: true, icon: Icons.event_busy_rounded, title: l.noUpcomingTrainings),
                )
              else
                ..._tiles(upcoming, groups),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _tiles(List<Training> list, Map<String, Group> groups, {bool showDate = true}) => [
    for (final t in list)
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: TrainingTile(training: t, group: groups[t.groupId], showDate: showDate),
      ),
  ];
}
