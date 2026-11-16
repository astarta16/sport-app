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
import '../../chat/domain/receipts.dart';
import '../../chat/presentation/chat_providers.dart';
import '../../clubs/presentation/clubs_providers.dart';
import '../../authentication/presentation/session_providers.dart';
import '../domain/scheduled_event.dart';
import '../domain/attendance.dart';
import '../../organizations/presentation/org_widgets.dart';
import '../../organizations/domain/organization.dart';
import 'attendance_providers.dart';

/// Parent: "Will your child attend?" per own child in the group, the
/// current schedule, reconfirmation after a change, a separate
/// acknowledgment of the change ("გავეცანი") and the coach-recorded
/// attendance once it exists. RSVP ≠ acknowledgment ≠ attendance.
class RsvpSection extends ConsumerWidget {
  const RsvpSection({super.key, required this.event, required this.group});

  final ScheduledEvent event;
  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    if (!ref.watch(moduleOnForGroupProvider((group.id, OrgModule.attendance)))) return const SizedBox.shrink();
    final kids = (ref.watch(myChildrenProvider).value ?? const <Child>[]).where((c) => group.hasChild(c.id)).toList();
    if (kids.isEmpty) return const SizedBox.shrink();
    final rsvpsAsync = ref.watch(rsvpsForTrainingProvider(event.id));
    final rsvps = rsvpsAsync.value ?? const <Rsvp>[];
    // Until answers are loaded, nothing looks unanswered and nothing can be
    // answered twice by accident.
    final loading = !rsvpsAsync.hasValue;
    final records = ref.watch(attendanceForTrainingProvider(event.id)).value ?? const <AttendanceRecord>[];
    final now = ref.watch(clockProvider)();
    final open = event.active && now.isBefore(event.startAt);
    final ack = (ref.watch(pendingAcksProvider).value ?? const <PendingAck>[])
        .where((p) => p.eventId == event.id)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(open ? (event.type == EventType.match ? l.rsvpTitleMatch : l.rsvpTitle) : l.attendanceRecorded),
        if (ack != null) ...[_ScheduleChangeAck(event: event, ack: ack), const SizedBox(height: AppSpacing.xs)],
        // v1.9.1 (M11): siblings in the same group — one tap for all.
        if (open && kids.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _RsvpAllRow(event: event, kids: kids, rsvps: rsvps, loading: loading),
          ),
        for (final c in kids)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _ChildRsvpCard(
              event: event,
              child: c,
              rsvp: rsvps.where((r) => r.childId == c.id).firstOrNull,
              record: records.where((r) => r.childId == c.id).firstOrNull,
              open: open,
              loading: loading,
            ),
          ),
        if (open) Text(l.rsvpNotice, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// "Same answer for all children": answers for every own child in the
/// group with the same repository call as the per-child cards, which stay
/// below for individual answers and reasons.
class _RsvpAllRow extends ConsumerStatefulWidget {
  const _RsvpAllRow({required this.event, required this.kids, required this.rsvps, required this.loading});

  final ScheduledEvent event;
  final List<Child> kids;
  final List<Rsvp> rsvps;
  final bool loading;

  @override
  ConsumerState<_RsvpAllRow> createState() => _RsvpAllRowState();
}

class _RsvpAllRowState extends ConsumerState<_RsvpAllRow> {
  bool _saving = false;

  Future<void> _answerAll(RsvpResponse r) async {
    final l = context.l10n;
    setState(() => _saving = true);
    final repo = ref.read(attendanceRepositoryProvider);
    await runGuarded(context, () async {
      for (final c in widget.kids) {
        final previous = widget.rsvps.where((x) => x.childId == c.id).firstOrNull;
        await repo.respond(trainingId: widget.event.id, childId: c.id, response: r, reason: previous?.reason);
      }
    }, success: l.s191RsvpAllSaved);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Selected only when every child already has this (current) answer.
    final answers = {
      for (final c in widget.kids)
        widget.rsvps
            .where((x) => x.childId == c.id && !x.needsReconfirmation(widget.event.version))
            .firstOrNull
            ?.response,
    };
    final common = answers.length == 1 ? answers.first : null;
    return AppCard(
      key: const Key('rsvp-all'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(l.s191RsvpAllTitle, style: Theme.of(context).textTheme.titleSmall)),
              if (_saving) const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<RsvpResponse>(
            key: const Key('rsvp-all-buttons'),
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            segments: [
              for (final r in RsvpResponse.values)
                ButtonSegment(
                  value: r,
                  label: Text(rsvpLabel(context, r), key: Key('rsvp-all-${r.name}')),
                ),
            ],
            selected: {?common},
            onSelectionChanged: widget.loading || _saving ? null : (s) => s.isEmpty ? null : _answerAll(s.first),
          ),
        ],
      ),
    );
  }
}

/// "The schedule changed — I have read it" (reuses the chat acknowledgment
/// record). Acknowledging never answers the attendance question.
class _ScheduleChangeAck extends ConsumerWidget {
  const _ScheduleChangeAck({required this.event, required this.ack});

  final ScheduledEvent event;
  final PendingAck ack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    return AppCard(
      key: const Key('schedule-change-ack'),
      // v1.9: theme-aware (the fixed light colour was unreadable in dark mode).
      color: AppColors.warning.withValues(alpha: .14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.update_rounded, color: AppColors.warning),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(l.scheduleChangedTitle, style: Theme.of(context).textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: 4),
          Text(l.scheduleChangedBody('${f.weekdayDayMonth(event.startAt)} ${f.time(event.startAt)}')),
          const SizedBox(height: AppSpacing.xs),
          Text(l.ackIsNotRsvp, style: Theme.of(context).textTheme.bodySmall),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              key: const Key('schedule-ack-button'),
              onPressed: () => runGuarded(
                context,
                () => ref.read(chatRepositoryProvider).acknowledge(ack.groupId, ack.messageId),
                success: l.ackDone,
              ),
              icon: const Icon(Icons.done_rounded),
              label: Text(l.ackButton),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildRsvpCard extends ConsumerStatefulWidget {
  const _ChildRsvpCard({
    required this.event,
    required this.child,
    required this.rsvp,
    required this.record,
    required this.open,
    this.loading = false,
  });

  final ScheduledEvent event;
  final Child child;
  final Rsvp? rsvp;
  final AttendanceRecord? record;
  final bool open;
  final bool loading;

  @override
  ConsumerState<_ChildRsvpCard> createState() => _ChildRsvpCardState();
}

class _ChildRsvpCardState extends ConsumerState<_ChildRsvpCard> {
  final _reason = TextEditingController();
  final _reasonFocus = FocusNode();
  RsvpResponse? _pending;
  bool _justSaved = false;

  @override
  void initState() {
    super.initState();
    _reason.text = widget.rsvp?.reason ?? '';
    // v1.9: the optional reason is saved when the field is left — it is no
    // longer lost when the parent doesn't find the small send button.
    _reasonFocus.addListener(() {
      final r = widget.rsvp;
      if (!_reasonFocus.hasFocus && r != null && _reason.text.trim() != (r.reason ?? '')) {
        _respond(r.response, reasonOnly: true);
      }
    });
  }

  @override
  void dispose() {
    _reason.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  Future<void> _respond(RsvpResponse r, {bool reasonOnly = false}) async {
    setState(() {
      _pending = r;
      _justSaved = false;
    });
    final ok = await runGuarded(
      context,
      () => ref
          .read(attendanceRepositoryProvider)
          .respond(trainingId: widget.event.id, childId: widget.child.id, response: r, reason: _reason.text),
      success: reasonOnly ? context.l10n.rsvpReasonSaved : context.l10n.rsvpSaved,
    );
    if (mounted) {
      setState(() {
        _pending = null;
        _justSaved = ok;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final rsvp = widget.rsvp;
    final needsReconfirm = rsvp != null && rsvp.needsReconfirmation(widget.event.version);
    // An answer for an older schedule is shown, but not pre-selected.
    final current = _pending ?? (needsReconfirm ? null : rsvp?.response);
    final rec = widget.record;
    final venue = ref.watch(venuesByIdProvider)[widget.event.venueId];
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
              else if (!needsReconfirm && !widget.open && rsvp != null)
                StatusPill(label: rsvpLabel(context, rsvp.response), color: rsvpColor(rsvp.response)),
            ],
          ),
          // Own line: the label is long in Georgian and Russian.
          if (rec == null && needsReconfirm)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: StatusPill(
                key: Key('reconfirm-${widget.child.id}'),
                label: l.rsvpNeedsReconfirm,
                color: AppColors.warning,
                icon: Icons.priority_high_rounded,
                dense: true,
              ),
            ),
          if (widget.open) ...[
            const SizedBox(height: AppSpacing.xs),
            // The current schedule, shown before the parent answers.
            Text(
              '${f.weekdayDayMonth(widget.event.startAt)} · ${f.time(widget.event.startAt)}–${f.time(widget.event.endAt)}'
              '${venue == null ? '' : ' · ${venue.name}'}',
              key: Key('rsvp-schedule-${widget.child.id}'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (needsReconfirm)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l.rsvpPreviousAnswer(rsvpLabel(context, rsvp.response)),
                  key: Key('rsvp-previous-${widget.child.id}'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
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
              onSelectionChanged: widget.loading ? null : (s) => s.isEmpty ? null : _respond(s.first),
            ),
            if (_justSaved && current != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  key: Key('rsvp-saved-${widget.child.id}'),
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        l.rsvpSavedInline(rsvpLabel(context, current)),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            if (current == RsvpResponse.no || current == RsvpResponse.maybe) ...[
              const SizedBox(height: AppSpacing.xs),
              TextField(
                key: Key('rsvp-reason-${widget.child.id}'),
                controller: _reason,
                focusNode: _reasonFocus,
                maxLength: Rsvp.maxReason,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l.rsvpReasonLabel,
                  hintText: l.rsvpReasonHint,
                  suffixIcon: IconButton(
                    tooltip: l.rsvpSaveReason,
                    icon: const Icon(Icons.send_rounded),
                    onPressed: () => _respond(current!, reasonOnly: true),
                  ),
                ),
                onSubmitted: (_) => _respond(current!, reasonOnly: true),
              ),
            ],
          ] else if (rec == null && widget.event.active)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(l.rsvpClosedNote, style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

/// Coach: child-level RSVP counters (each child once), per-child answers
/// with every guardian's response, and the entry to the attendance roster.
class CoachAttendanceSummary extends ConsumerWidget {
  const CoachAttendanceSummary({super.key, required this.event, required this.group});

  final ScheduledEvent event;
  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    if (!ref.watch(moduleOnForGroupProvider((group.id, OrgModule.attendance)))) return const SizedBox.shrink();
    final rsvps = ref.watch(rsvpsForTrainingProvider(event.id)).value ?? const <Rsvp>[];
    final records = ref.watch(attendanceForTrainingProvider(event.id)).value ?? const <AttendanceRecord>[];
    final kids = ref.watch(groupMembersProvider(group.id)).value ?? const <Child>[];
    final summary = RsvpSummary.compute(group.memberChildIds, rsvps, event.version);
    int a(AttendanceStatus s) => records.where((x) => x.status == s).length;
    final total = group.memberChildIds.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.attendanceTitle),
        AppCard(
          key: const Key('coach-attendance-summary'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.responsesTitle, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final st in RsvpState.values)
                    StatusPill(
                      key: Key('rsvp-count-${st.name}'),
                      label: '${rsvpStateLabel(context, st)}: ${summary.count(st)}',
                      color: rsvpStateColor(st),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final c in kids)
                _ChildResponseRow(
                  child: c,
                  rsvp: rsvps.where((r) => r.childId == c.id).firstOrNull,
                  state: summary.byChild[c.id] ?? RsvpState.notResponded,
                  version: event.version,
                ),
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
              if (!event.cancelled) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    key: const Key('open-attendance'),
                    onPressed: () => context.push(Routes.attendance(event.id)),
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

class _ChildResponseRow extends ConsumerWidget {
  const _ChildResponseRow({required this.child, required this.rsvp, required this.state, required this.version});

  final Child child;
  final Rsvp? rsvp;
  final RsvpState state;
  final int version;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final r = rsvp;
    final answers = r?.guardianResponses.entries.toList() ?? const [];
    return Padding(
      key: Key('coach-rsvp-${child.id}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(child.fullName, style: Theme.of(context).textTheme.bodyMedium),
              StatusPill(label: rsvpStateLabel(context, state), color: rsvpStateColor(state), dense: true),
            ],
          ),
          if (r != null && r.conflictingFor(version))
            Text(
              l.rsvpGuardiansDisagree,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning),
            ),
          for (final e in answers)
            Text(
              '${ref.watch(publicProfileProvider(e.key)).value?.firstName ?? l.guardianLabel}: '
              '${rsvpLabel(context, e.value.response)}'
              '${e.value.version < version ? ' (${l.rsvpOldSchedule})' : ''}'
              '${(e.value.reason ?? '').isEmpty ? '' : ' — ${e.value.reason}'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

String rsvpStateLabel(BuildContext context, RsvpState s) {
  final l = context.l10n;
  return switch (s) {
    RsvpState.confirmed => l.rsvpStateConfirmed,
    RsvpState.declined => l.rsvpStateDeclined,
    RsvpState.uncertain => l.rsvpStateUncertain,
    RsvpState.notResponded => l.rsvpStateNotResponded,
    RsvpState.needsReconfirmation => l.rsvpNeedsReconfirm,
  };
}

Color rsvpStateColor(RsvpState s) => switch (s) {
  RsvpState.confirmed => AppColors.success,
  RsvpState.declined => AppColors.danger,
  RsvpState.uncertain => AppColors.warning,
  RsvpState.notResponded => AppColors.neutral,
  RsvpState.needsReconfirmation => const Color(0xFFB45309),
};

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
