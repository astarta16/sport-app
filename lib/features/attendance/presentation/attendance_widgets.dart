import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../../groups/domain/group.dart';
import '../../trainings/domain/training.dart';
import '../domain/attendance.dart';
import 'attendance_providers.dart';

/// Parent: "Coming to training?" per own child in the group, plus the
/// coach-recorded attendance once it exists. RSVP ≠ attendance.
class RsvpSection extends ConsumerWidget {
  const RsvpSection({super.key, required this.training, required this.group});

  final Training training;
  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final kids = (ref.watch(myChildrenProvider).value ?? const <Child>[]).where((c) => group.hasChild(c.id)).toList();
    if (kids.isEmpty) return const SizedBox.shrink();
    final rsvps = ref.watch(rsvpsForTrainingProvider(training.id)).value ?? const <Rsvp>[];
    final records = ref.watch(attendanceForTrainingProvider(training.id)).value ?? const <AttendanceRecord>[];
    final now = ref.watch(clockProvider)();
    final open = training.status.isActive && now.isBefore(training.startAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(open ? l.rsvpTitle : l.attendanceRecorded),
        for (final c in kids)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _ChildRsvpCard(
              training: training,
              child: c,
              rsvp: rsvps.where((r) => r.childId == c.id).firstOrNull,
              record: records.where((r) => r.childId == c.id).firstOrNull,
              open: open,
            ),
          ),
        if (open) Text(l.rsvpNotice, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ChildRsvpCard extends ConsumerStatefulWidget {
  const _ChildRsvpCard({
    required this.training,
    required this.child,
    required this.rsvp,
    required this.record,
    required this.open,
  });

  final Training training;
  final Child child;
  final Rsvp? rsvp;
  final AttendanceRecord? record;
  final bool open;

  @override
  ConsumerState<_ChildRsvpCard> createState() => _ChildRsvpCardState();
}

class _ChildRsvpCardState extends ConsumerState<_ChildRsvpCard> {
  final _reason = TextEditingController();
  RsvpResponse? _pending;

  @override
  void initState() {
    super.initState();
    _reason.text = widget.rsvp?.reason ?? '';
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _respond(RsvpResponse r) async {
    setState(() => _pending = r);
    await runGuarded(
      context,
      () => ref
          .read(attendanceRepositoryProvider)
          .respond(trainingId: widget.training.id, childId: widget.child.id, response: r, reason: _reason.text),
      success: context.l10n.rsvpSaved,
    );
    if (mounted) setState(() => _pending = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final current = _pending ?? widget.rsvp?.response;
    final rec = widget.record;
    return AppCard(
      key: Key('rsvp-${widget.child.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(name: widget.child.fullName, size: 36),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(widget.child.firstName, style: Theme.of(context).textTheme.titleSmall)),
              if (rec != null)
                StatusPill(
                  key: Key('recorded-${widget.child.id}'),
                  label: attendanceLabel(context, rec.status),
                  color: attendanceColor(rec.status),
                )
              else if (!widget.open && widget.rsvp != null)
                StatusPill(label: rsvpLabel(context, widget.rsvp!.response), color: rsvpColor(widget.rsvp!.response)),
            ],
          ),
          if (widget.open) ...[
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<RsvpResponse>(
              key: Key('rsvp-buttons-${widget.child.id}'),
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              segments: [
                for (final r in RsvpResponse.values)
                  ButtonSegment(
                    value: r,
                    label: Text(rsvpLabel(context, r), key: Key('rsvp-${widget.child.id}-${r.name}')),
                  ),
              ],
              selected: {?current},
              onSelectionChanged: (s) => s.isEmpty ? null : _respond(s.first),
            ),
            if (current == RsvpResponse.no || current == RsvpResponse.maybe) ...[
              const SizedBox(height: AppSpacing.xs),
              TextField(
                key: Key('rsvp-reason-${widget.child.id}'),
                controller: _reason,
                maxLength: Rsvp.maxReason,
                decoration: InputDecoration(
                  hintText: l.rsvpReasonHint,
                  suffixIcon: IconButton(icon: const Icon(Icons.send_rounded), onPressed: () => _respond(current!)),
                ),
                onSubmitted: (_) => _respond(current!),
              ),
            ],
          ] else if (rec == null && widget.training.status.isActive)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(l.rsvpClosedNote, style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

/// Coach: summary of parent responses + entry to the attendance roster.
class CoachAttendanceSummary extends ConsumerWidget {
  const CoachAttendanceSummary({super.key, required this.training, required this.group});

  final Training training;
  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final rsvps = ref.watch(rsvpsForTrainingProvider(training.id)).value ?? const <Rsvp>[];
    final records = ref.watch(attendanceForTrainingProvider(training.id)).value ?? const <AttendanceRecord>[];
    int n(RsvpResponse r) => rsvps.where((x) => x.response == r).length;
    int a(AttendanceStatus s) => records.where((x) => x.status == s).length;
    final total = group.memberChildIds.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.attendanceTitle),
        AppCard(
          key: const Key('coach-attendance-summary'),
          onTap: training.status == TrainingStatus.cancelled
              ? null
              : () => context.push(Routes.attendance(training.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.responsesTitle, style: Theme.of(context).textTheme.labelMedium),
              Text(l.responsesCount(n(RsvpResponse.yes), n(RsvpResponse.no), n(RsvpResponse.maybe))),
              if (records.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(l.attendanceRecorded, style: Theme.of(context).textTheme.labelMedium),
                Text(
                  l.attendanceSummary(
                    a(AttendanceStatus.present),
                    a(AttendanceStatus.absent),
                    a(AttendanceStatus.excused),
                    total - records.length,
                  ),
                ),
              ],
              if (training.status != TrainingStatus.cancelled) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    key: const Key('open-attendance'),
                    onPressed: () => context.push(Routes.attendance(training.id)),
                    icon: const Icon(Icons.fact_check_rounded),
                    label: Text(l.attendanceOpen),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Small pill row: "92% this month" etc.
class AttendanceRateBar extends StatelessWidget {
  const AttendanceRateBar({super.key, required this.rate, this.height = 8});

  final double? rate;
  final double height;

  @override
  Widget build(BuildContext context) {
    final r = rate ?? 0;
    final color = r >= 0.8 ? AppColors.success : (r >= 0.6 ? AppColors.warning : AppColors.danger);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: rate == null ? 0 : r,
        minHeight: height,
        color: color,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
    );
  }
}
