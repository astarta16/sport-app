import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../authentication/domain/access_policy.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../trainings/domain/training.dart';
import '../../trainings/presentation/trainings_providers.dart';
import '../domain/attendance.dart';
import 'attendance_providers.dart';

/// Child progress (v1.2): recorded attendance only (never RSVPs), monthly
/// trend, achievements, coach feedback and history. Visible to the child's
/// parents and coaches only; no rankings.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final child = ref.watch(childProvider(childId));
    final stats = ref.watch(childStatsProvider(childId));
    final feedback = ref.watch(feedbackForChildProvider(childId));
    final records = ref.watch(attendanceForChildProvider(childId)).value ?? const <AttendanceRecord>[];
    final trainings = {for (final t in ref.watch(myTrainingsProvider).value ?? const <Training>[]) t.id: t};
    final groups = ref.watch(groupsByIdProvider);
    final me = ref.watch(currentUserProvider);
    final c = child.value;
    final coachGroups = c == null || me == null
        ? const <Group>[]
        : groups.values.where((g) => g.hasChild(childId) && AccessPolicy.canGiveFeedback(me, c, g)).toList();
    return Scaffold(
      appBar: AppBar(title: Text(c == null ? l.progressTitle : '${l.progressTitle} · ${c.firstName}')),
      floatingActionButton: coachGroups.isEmpty
          ? null
          : FloatingActionButton.extended(
              key: const Key('feedback-add'),
              onPressed: () => showFeedbackSheet(context, ref, child: c!, group: coachGroups.first),
              icon: const Icon(Icons.rate_review_rounded),
              label: Text(l.feedbackAdd),
            ),
      body: AsyncView<AttendanceStats>(
        value: stats,
        onRetry: () => ref.invalidate(attendanceForChildProvider(childId)),
        data: (s) {
          final month = s.monthOf(ref.watch(clockProvider)());
          final history = records.where((r) => trainings.containsKey(r.trainingId)).toList()
            ..sort((a, b) => trainings[b.trainingId]!.startAt.compareTo(trainings[a.trainingId]!.startAt));
          return ConstrainedContent(
            maxWidth: Breakpoints.readable,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
              children: [
                Text(l.progressPrivacyNote, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        key: const Key('progress-total'),
                        label: l.progressTrainings,
                        value: '${s.totalPresent}',
                        icon: Icons.sports_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _StatTile(
                        key: const Key('progress-rate'),
                        label: '${l.progressRate} · ${l.attendanceThisMonth}',
                        value: month.rate == null ? '—' : '${(month.rate! * 100).round()}%',
                        icon: Icons.fact_check_rounded,
                      ),
                    ),
                  ],
                ),
                SectionHeader(l.progressTrend),
                AppCard(
                  child: s.months.isEmpty
                      ? EmptyState(compact: true, icon: Icons.insights_rounded, title: l.attendanceNoData)
                      : _TrendChart(months: s.months.length > 6 ? s.months.sublist(s.months.length - 6) : s.months),
                ),
                SectionHeader(l.progressAchievements),
                _Achievements(earned: s.achievements),
                SectionHeader(l.progressFeedback),
                AsyncView<List<CoachFeedback>>(
                  value: feedback,
                  compact: true,
                  data: (list) => list.isEmpty
                      ? AppCard(
                          child: EmptyState(compact: true, icon: Icons.chat_outlined, title: l.progressNoFeedback),
                        )
                      : Column(children: [for (final fb in list) _FeedbackCard(feedback: fb)]),
                ),
                SectionHeader(l.attendanceHistory),
                if (history.isEmpty)
                  AppCard(
                    child: EmptyState(compact: true, icon: Icons.event_note_rounded, title: l.attendanceNoData),
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final r in history.take(30))
                          ListTile(
                            dense: true,
                            leading: Icon(Icons.circle, size: 12, color: attendanceColor(r.status)),
                            title: Text(Fmt.of(context).weekdayDayMonth(trainings[r.trainingId]!.startAt)),
                            subtitle: Text(groups[r.groupId]?.name ?? ''),
                            trailing: Text(attendanceLabel(context, r.status)),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({super.key, required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          Text(label, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Monthly attendance bars (last 6 months).
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.months});

  final List<MonthStats> months;

  @override
  Widget build(BuildContext context) {
    final f = Fmt.of(context);
    final t = Theme.of(context).textTheme;
    return SizedBox(
      key: const Key('progress-trend'),
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final m in months)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(m.rate == null ? '—' : '${(m.rate! * 100).round()}%', style: t.labelSmall),
                    const SizedBox(height: 4),
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: (m.rate ?? 0).clamp(0.04, 1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: (m.rate ?? 0) >= 0.8 ? AppColors.success : AppColors.warning,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(f.monthShort(DateTime(m.year, m.month)), style: t.labelSmall, maxLines: 1),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Achievements extends StatelessWidget {
  const _Achievements({required this.earned});

  final List<Achievement> earned;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final got = {for (final a in earned) a.kind};
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final k in AchievementKind.values)
          Opacity(
            opacity: got.contains(k) ? 1 : 0.4,
            child: Chip(
              key: Key('ach-${k.name}-${got.contains(k) ? 'on' : 'off'}'),
              avatar: Icon(achievementIcon(k), size: 18, color: got.contains(k) ? AppColors.warning : null),
              label: Text(
                got.contains(k) ? achievementLabel(context, k) : '${achievementLabel(context, k)} · ${l.achLocked}',
              ),
            ),
          ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});

  final CoachFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(feedback.coachName, style: t.titleSmall)),
                Text(Fmt.of(context).dayMonthShort(feedback.createdAt), style: t.labelSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final e in feedback.ratings.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(width: 120, child: Text(feedbackLabel(context, e.key), style: t.bodySmall)),
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        i <= e.value ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 18,
                        color: AppColors.warning,
                      ),
                  ],
                ),
              ),
            if (feedback.comment != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(feedback.comment!, style: t.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

/// Coach writes structured, constructive feedback for one child.
Future<void> showFeedbackSheet(
  BuildContext context,
  WidgetRef ref, {
  required Child child,
  required Group group,
}) async {
  final l = context.l10n;
  final ratings = <FeedbackCategory, int>{};
  final comment = TextEditingController();
  await showAdaptiveSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          key: const Key('feedback-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${l.feedbackAdd} · ${child.firstName}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final c in FeedbackCategory.values)
              Row(
                children: [
                  Expanded(child: Text(feedbackLabel(context, c))),
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      key: Key('fb-${c.name}-$i'),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => ratings[c] == i ? ratings.remove(c) : ratings[c] = i),
                      icon: Icon(
                        (ratings[c] ?? 0) >= i ? Icons.star_rounded : Icons.star_border_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                ],
              ),
            TextField(
              key: const Key('fb-comment'),
              controller: comment,
              maxLength: CoachFeedback.maxComment,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: l.feedbackComment, helperText: l.feedbackCommentHint),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              key: const Key('fb-save'),
              onPressed: () async {
                final ok = await runGuarded(
                  context,
                  () => ref
                      .read(attendanceRepositoryProvider)
                      .addFeedback(
                        childId: child.id,
                        groupId: group.id,
                        ratings: Map.of(ratings),
                        comment: comment.text,
                      ),
                  success: l.feedbackSaved,
                );
                if (ok && context.mounted) Navigator.pop(context);
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    ),
  );
  comment.dispose();
}
