import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../trainings/domain/training.dart';
import '../../trainings/presentation/trainings_providers.dart';
import '../domain/attendance.dart';
import 'attendance_providers.dart';
import 'attendance_widgets.dart';

/// Coach attendance roster for one training (v1.2): parent RSVP shown next
/// to each child, individual status, bulk "mark the rest present", and the
/// child's attendance rate. Only coaches of the group can write (rules).
class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key, required this.trainingId});

  final String trainingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final training = ref.watch(trainingProvider(trainingId));
    return Scaffold(
      appBar: AppBar(title: Text(l.attendanceTitle)),
      body: AsyncView<Training?>(
        value: training,
        data: (t) {
          if (t == null) return EmptyState(icon: Icons.search_off_rounded, title: l.errorNotFound);
          return _Roster(training: t);
        },
      ),
    );
  }
}

class _Roster extends ConsumerWidget {
  const _Roster({required this.training});

  final Training training;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final group = ref.watch(groupsByIdProvider)[training.groupId];
    final members = ref.watch(groupMembersProvider(training.groupId));
    final rsvps = ref.watch(rsvpsForTrainingProvider(training.id)).value ?? const <Rsvp>[];
    final records = ref.watch(attendanceForTrainingProvider(training.id));
    final stats = ref.watch(groupStatsProvider(training.groupId)).value;
    final recs = records.value ?? const <AttendanceRecord>[];
    int count(AttendanceStatus s) => recs.where((r) => r.status == s).length;
    return AsyncView<List<Child>>(
      value: members,
      data: (kids) => ConstrainedContent(
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
                kids.length - recs.length,
              ),
              key: const Key('attendance-summary'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                key: const Key('attendance-mark-all'),
                onPressed: recs.length == kids.length
                    ? null
                    : () => runGuarded(
                        context,
                        () => ref
                            .read(attendanceRepositoryProvider)
                            .markAll(trainingId: training.id, status: AttendanceStatus.present),
                      ),
                icon: const Icon(Icons.done_all_rounded),
                label: Text(l.attendanceMarkAllPresent),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final c in kids)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _RosterRow(
                  training: training,
                  child: c,
                  rsvp: rsvps.where((r) => r.childId == c.id).firstOrNull,
                  record: recs.where((r) => r.childId == c.id).firstOrNull,
                  rate: stats?.byChild[c.id]?.rate,
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
      ),
    );
  }
}

class _RosterRow extends ConsumerWidget {
  const _RosterRow({required this.training, required this.child, required this.rsvp, required this.record, this.rate});

  final Training training;
  final Child child;
  final Rsvp? rsvp;
  final AttendanceRecord? record;
  final double? rate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return AppCard(
      key: Key('att-row-${child.id}'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InitialsAvatar(name: child.fullName, size: 36),
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
                  label: Text(attendanceLabel(context, s), key: Key('att-${child.id}-${s.name}')),
                ),
            ],
            selected: {?record?.status},
            onSelectionChanged: (sel) => runGuarded(
              context,
              () => ref
                  .read(attendanceRepositoryProvider)
                  .mark(trainingId: training.id, childId: child.id, status: sel.isEmpty ? null : sel.first),
            ),
          ),
        ],
      ),
    );
  }
}
