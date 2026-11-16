import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/visuals.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../roster/presentation/export_sheet.dart';
import '../domain/attendance.dart';
import '../domain/scheduled_event.dart';
import 'attendance_providers.dart';
import 'attendance_widgets.dart';

/// Coach attendance for one training occurrence (v1.3): the parent RSVP is
/// shown next to each child but never written; marks are edited locally
/// (individually or in bulk) and saved in one batch. Recorded attendance
/// can be edited later the same way.
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key, required this.trainingId});

  final String trainingId;

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  /// childId → new status (null = clear). Only changed rows are present.
  final Map<String, AttendanceStatus?> _draft = {};
  bool _saving = false;

  AttendanceStatus? _effective(String childId, List<AttendanceRecord> recs) =>
      _draft.containsKey(childId) ? _draft[childId] : recs.where((r) => r.childId == childId).firstOrNull?.status;

  void _set(String childId, AttendanceStatus? s, List<AttendanceRecord> recs) {
    final saved = recs.where((r) => r.childId == childId).firstOrNull?.status;
    setState(() => s == saved ? _draft.remove(childId) : _draft[childId] = s);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await runGuarded(
      context,
      () => ref.read(attendanceRepositoryProvider).saveBatch(trainingId: widget.trainingId, marks: Map.of(_draft)),
      success: context.l10n.attendanceSaved,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _draft.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final training = ref.watch(scheduledEventProvider(widget.trainingId));
    final group = training.value == null ? null : ref.watch(groupsByIdProvider)[training.value!.groupId];
    return PopScope(
      canPop: _draft.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await confirmDialog(
          context,
          title: l.attendanceUnsaved(_draft.length),
          message: l.attendanceEditNote,
          confirmLabel: l.attendanceDiscard,
          destructive: true,
        );
        if (discard && context.mounted) {
          setState(_draft.clear);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.attendanceTitle),
          actions: [
            if (group != null)
              IconButton(
                key: const Key('attendance-export'),
                tooltip: l.exportTitle,
                onPressed: () => showExportSheet(context, ref, group: group),
                icon: const Icon(Icons.ios_share_rounded),
              ),
          ],
        ),
        bottomNavigationBar: _draft.isEmpty
            ? null
            : SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(l.attendanceUnsaved(_draft.length), key: const Key('attendance-unsaved'))),
                      TextButton(onPressed: () => setState(_draft.clear), child: Text(l.attendanceDiscard)),
                      const SizedBox(width: AppSpacing.xs),
                      FilledButton.icon(
                        key: const Key('attendance-save'),
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(l.attendanceSave),
                      ),
                    ],
                  ),
                ),
              ),
        body: AsyncView<ScheduledEvent?>(
          value: training,
          data: (t) {
            if (t == null) return EmptyState(icon: Icons.search_off_rounded, title: l.errorNotFound);
            return _body(context, t);
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ScheduledEvent training) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final group = ref.watch(groupsByIdProvider)[training.groupId];
    final members = ref.watch(groupMembersProvider(training.groupId));
    final rsvps = ref.watch(rsvpsForTrainingProvider(training.id)).value ?? const <Rsvp>[];
    final recs = ref.watch(attendanceForTrainingProvider(training.id)).value ?? const <AttendanceRecord>[];
    final stats = ref.watch(groupStatsProvider(training.groupId)).value;
    return AsyncView<List<Child>>(
      value: members,
      data: (kids) {
        int count(AttendanceStatus s) => kids.where((c) => _effective(c.id, recs) == s).length;
        final unmarked = kids.where((c) => _effective(c.id, recs) == null).length;
        return ConstrainedContent(
          maxWidth: Breakpoints.readable,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                '${group?.name ?? ''} · ${f.weekdayDayMonth(training.startAt)} ${f.time(training.startAt)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l.attendanceSummary(
                  count(AttendanceStatus.present),
                  count(AttendanceStatus.absent),
                  count(AttendanceStatus.excused),
                  unmarked,
                ),
                key: const Key('attendance-summary'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (recs.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(l.attendanceEditNote, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  FilledButton.tonalIcon(
                    key: const Key('attendance-mark-all'),
                    onPressed: unmarked == 0
                        ? null
                        : () => setState(() {
                            for (final c in kids) {
                              if (_effective(c.id, recs) == null) _draft[c.id] = AttendanceStatus.present;
                            }
                          }),
                    icon: const Icon(Icons.done_all_rounded),
                    label: Text(l.attendanceMarkAllPresent),
                  ),
                  for (final s in [AttendanceStatus.absent, AttendanceStatus.excused])
                    OutlinedButton(
                      key: Key('attendance-all-${s.name}'),
                      onPressed: () => setState(() {
                        for (final c in kids) {
                          _set(c.id, s, recs);
                        }
                      }),
                      child: Text('${l.attendanceMarkAll}: ${attendanceLabel(context, s)}'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final c in kids)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _RosterRow(
                    child: c,
                    rsvp: rsvps.where((r) => r.childId == c.id).firstOrNull,
                    status: _effective(c.id, recs),
                    changed: _draft.containsKey(c.id),
                    rate: stats?.byChild[c.id]?.rate,
                    onChanged: (s) => _set(c.id, s, recs),
                  ),
                ),
              if (stats != null && stats.overall.recorded > 0) ...[
                SectionHeader(l.attendanceGroupStats),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.attendanceRate(((stats.overall.rate ?? 0) * 100).round())),
                      const SizedBox(height: 6),
                      AttendanceRateBar(rate: stats.overall.rate),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({
    required this.child,
    required this.rsvp,
    required this.status,
    required this.changed,
    required this.onChanged,
    this.rate,
  });

  final Child child;
  final Rsvp? rsvp;
  final AttendanceStatus? status;
  final bool changed;
  final double? rate;
  final ValueChanged<AttendanceStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      key: Key('att-row-${child.id}'),
      color: changed ? AppColors.volt.withValues(alpha: 0.15) : null,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              UserAvatar(name: child.fullName, photoPath: child.photoPath, size: 36),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.fullName, style: Theme.of(context).textTheme.titleSmall),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (rsvp != null)
                          Text(
                            l.attendanceRsvpLabel(rsvpLabel(context, rsvp!.response)) +
                                (rsvp!.reason == null ? '' : ' — ${rsvp!.reason}'),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: rsvpColor(rsvp!.response)),
                          ),
                        if (rate != null)
                          Text(l.attendanceRate((rate! * 100).round()), style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<AttendanceStatus>(
            key: Key('att-buttons-${child.id}'),
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            segments: [
              for (final s in AttendanceStatus.values)
                ButtonSegment(
                  value: s,
                  label: FittedBox(child: Text(attendanceLabel(context, s), key: Key('att-${child.id}-${s.name}'))),
                ),
            ],
            selected: {?status},
            onSelectionChanged: (sel) => onChanged(sel.isEmpty ? null : sel.first),
          ),
        ],
      ),
    );
  }
}
