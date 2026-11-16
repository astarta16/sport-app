import '../../../app/routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/visuals.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../clubs/presentation/venue_picker.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import '../domain/series.dart';
import '../domain/training.dart';

/// Weekly recurring schedule (v1.2). New: creates a series. Edit with
/// [fromDate]: "this and following trainings" — the old series ends the day
/// before and a new one starts at [fromDate] (occurrences keep their ids
/// where the date still matches, so RSVPs and attendance stay attached).
class SeriesFormScreen extends ConsumerStatefulWidget {
  const SeriesFormScreen({super.key, this.groupId, this.seriesId, this.fromDate});

  final String? groupId;
  final String? seriesId;
  final String? fromDate;

  bool get isEdit => seriesId != null;

  @override
  ConsumerState<SeriesFormScreen> createState() => _SeriesFormScreenState();
}

class _SeriesFormScreenState extends ConsumerState<SeriesFormScreen> {
  String? _groupId;
  final _weekdays = <int>{};
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  int _duration = 90;
  String? _venueId;
  final _focus = <TrainingFocus>{};
  final _description = TextEditingController();
  DateTime? _start;
  DateTime? _end;
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
    _description.dispose();
    super.dispose();
  }

  void _initFrom(TrainingSeries s) {
    if (_init) return;
    _init = true;
    _groupId = s.groupId;
    _weekdays.addAll(s.weekdays);
    _time = TimeOfDay(hour: s.startTime.hour, minute: s.startTime.minute);
    _duration = s.durationMin;
    _venueId = s.venueId;
    _focus.addAll(s.focus);
    _description.text = s.description;
    final from = widget.fromDate == null ? null : LocalDate.parse(widget.fromDate!);
    _start = (from ?? s.startDate).toDateTime();
    _end = s.endDate?.toDateTime();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final now = ref.read(clockProvider)();
    final start = _start == null ? LocalDate.tbilisi(now) : LocalDate.fromDateTime(_start!);
    final draft = SeriesDraft(
      groupId: _groupId ?? '',
      venueId: _venueId ?? '',
      weekdays: (_weekdays.toList()..sort()),
      startTime: LocalTime(_time.hour, _time.minute),
      durationMin: _duration,
      focus: _focus.toList(),
      startDate: start,
      endDate: _end == null ? null : LocalDate.fromDateTime(_end!),
      description: _description.text,
    );
    final errors = [if (_groupId == null) 'required', ...SeriesDraft.validate(draft, today: LocalDate.tbilisi(now))];
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    setState(() => _saving = true);
    final repo = ref.read(trainingsRepositoryProvider);
    final ok = await runGuarded(
      context,
      () => widget.isEdit ? repo.updateSeriesFrom(widget.seriesId!, draft, from: start) : repo.createSeries(draft),
      success: l.seriesSaved,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) context.popOrHome();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final me = ref.watch(currentUserProvider);
    final groups = (ref.watch(myGroupsProvider).value ?? const <Group>[])
        .where((g) => g.hasCoach(me?.id ?? ''))
        .toList();
    if (widget.isEdit) {
      final gid = widget.groupId ?? groups.map((g) => g.id).firstOrNull;
      final asyncs = [for (final g in groups) ref.watch(seriesForGroupProvider(g.id))];
      final all = [for (final a in asyncs) ...?a.value];
      final s = all.where((x) => x.id == widget.seriesId).firstOrNull;
      if (s != null) _initFrom(s);
      if (!_init) {
        final failed = asyncs.where((a) => a.hasError).firstOrNull;
        final loaded = gid != null && asyncs.every((a) => a.hasValue);
        // v1.9: never a blank page or an endless skeleton.
        return Scaffold(
          appBar: AppBar(title: Text(l.seriesEdit)),
          body: failed != null
              ? ErrorView(error: failed.error!, onRetry: () => ref.invalidate(myGroupsProvider))
              : (loaded || (gid == null && ref.watch(myGroupsProvider).hasValue))
              ? EmptyState(icon: Icons.event_busy_rounded, title: l.itemGoneTitle, body: l.itemGoneBody)
              : const SkeletonList(),
        );
      }
    }
    final group = groups.where((g) => g.id == _groupId).firstOrNull ?? (groups.length == 1 ? groups.first : null);
    _groupId ??= group?.id;
    final now = ref.watch(clockProvider)();
    final f = Fmt.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? l.seriesEdit : l.seriesNew)),
      body: SafeArea(
        child: ConstrainedContent(
          maxWidth: Breakpoints.readable,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (widget.isEdit) DemoBanner(text: '${l.editScopeFuture} · ${f.dayMonth(_start ?? now)}'),
              if (!widget.isEdit && groups.length > 1) ...[
                SectionHeader(l.groupLabel),
                DropdownButtonFormField<String>(
                  key: const Key('series-group'),
                  initialValue: _groupId,
                  isExpanded: true,
                  items: [for (final g in groups) DropdownMenuItem(value: g.id, child: Text(g.name))],
                  onChanged: (v) => setState(() {
                    _groupId = v;
                    _venueId = null;
                  }),
                ),
              ],
              SectionHeader(l.seriesWeekdays),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var d = 1; d <= 7; d++)
                    FilterChip(
                      key: Key('series-day-$d'),
                      label: Text(weekdayShortName(context, d)),
                      selected: _weekdays.contains(d),
                      onSelected: (v) => setState(() => v ? _weekdays.add(d) : _weekdays.remove(d)),
                    ),
                ],
              ),
              SectionHeader(l.seriesStartTime),
              Row(
                children: [
                  Expanded(
                    child: PickerField(
                      key: const Key('series-time'),
                      icon: Icons.schedule_rounded,
                      label: _time.format(context),
                      filled: true,
                      onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: _time);
                        if (t != null) setState(() => _time = t);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _duration,
                      items: [
                        for (final d in const [45, 60, 75, 90, 120])
                          DropdownMenuItem(value: d, child: Text(l.durationMinutes(d))),
                      ],
                      onChanged: (v) => setState(() => _duration = v ?? 90),
                    ),
                  ),
                ],
              ),
              SectionHeader(l.venueLabel),
              VenuePicker(
                fieldKey: const Key('series-venue'),
                group: group,
                value: _venueId,
                onChanged: (v) => setState(() => _venueId = v),
              ),
              SectionHeader(l.trainingFocus),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final fo in TrainingFocus.values)
                    FilterChip(
                      key: Key('series-focus-${fo.name}'),
                      avatar: Icon(focusIcon(fo), size: 18),
                      label: Text(focusLabel(context, fo)),
                      selected: _focus.contains(fo),
                      onSelected: (v) => setState(() => v ? _focus.add(fo) : _focus.remove(fo)),
                    ),
                ],
              ),
              SectionHeader(l.seriesStartDate),
              PickerField(
                key: const Key('series-start'),
                icon: Icons.event_rounded,
                label: f.weekdayDayMonth(_start ?? now),
                filled: true,
                onTap: widget.isEdit
                    ? () {}
                    : () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _start ?? now,
                          firstDate: DateUtils.dateOnly(now),
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (d != null) setState(() => _start = d);
                      },
              ),
              SectionHeader(l.seriesEndDate),
              Row(
                children: [
                  Expanded(
                    child: PickerField(
                      key: const Key('series-end'),
                      icon: Icons.event_busy_rounded,
                      label: _end == null ? l.seriesNoEnd : f.weekdayDayMonth(_end!),
                      filled: _end != null,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _end ?? (_start ?? now).add(const Duration(days: 90)),
                          firstDate: _start ?? DateUtils.dateOnly(now),
                          lastDate: now.add(const Duration(days: 366)),
                        );
                        if (d != null) setState(() => _end = d);
                      },
                    ),
                  ),
                  if (_end != null)
                    IconButton(onPressed: () => setState(() => _end = null), icon: const Icon(Icons.clear_rounded)),
                ],
              ),
              SectionHeader(l.trainingDescription),
              TextField(controller: _description, maxLength: 1000, minLines: 2, maxLines: 4),
              Text(l.seriesHorizonNote, style: Theme.of(context).textTheme.bodySmall),
              FormErrors(errors: _errors),
              const SizedBox(height: AppSpacing.md),
              LoadingButton(
                key: const Key('series-save'),
                label: l.save,
                loading: _saving,
                onPressed: _save,
                icon: Icons.event_repeat_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Human summary of a series: "ორშ, ოთხ · 18:00".
String seriesSummary(BuildContext context, TrainingSeries s) =>
    context.l10n.seriesSummary(s.weekdays.map((d) => weekdayShortName(context, d)).join(', '), s.startTime.toString());
