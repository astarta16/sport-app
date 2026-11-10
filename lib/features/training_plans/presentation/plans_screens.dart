import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../trainings/domain/series.dart';
import '../domain/training_plan.dart';
import 'plan_widgets.dart';
import 'plans_providers.dart';

/// Coach: all plans of their groups (drafts included). Parent: published
/// plans of their children's groups, optionally for one child.
class PlansListScreen extends ConsumerWidget {
  const PlansListScreen({super.key, this.childId});

  final String? childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(currentUserProvider);
    final plans = ref.watch(plansProvider);
    final groups = ref.watch(groupsByIdProvider);
    final child = childId == null ? null : ref.watch(childProvider(childId!)).value;
    final isCoach = me?.isApprovedCoach ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(child == null ? l.plansTitle : '${l.plansTitle} · ${child.firstName}')),
      floatingActionButton: isCoach
          ? FloatingActionButton.extended(
              key: const Key('plan-new'),
              onPressed: () => context.push(Routes.newPlan()),
              icon: const Icon(Icons.add_rounded),
              label: Text(l.planNew),
            )
          : null,
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: AsyncView<List<TrainingPlan>>(
          value: plans,
          data: (all) {
            final list = child == null ? all : all.where((p) => p.groupIds.any(child.groupIds.contains)).toList();
            if (list.isEmpty) return EmptyState(icon: Icons.assignment_outlined, title: l.plansEmpty);
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
              children: [
                for (final p in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: PlanCard(
                      plan: p,
                      groupNames: p.groupIds.map((g) => groups[g]?.name).whereType<String>().toList(),
                      showStatus: isCoach,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan, required this.groupNames, this.showStatus = false});

  final TrainingPlan plan;
  final List<String> groupNames;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      key: Key('plan-card-${plan.id}'),
      onTap: () => context.push(Routes.plan(plan.id)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              plan.type == PlanType.homework ? Icons.home_work_rounded : Icons.assignment_rounded,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [
                    planTypeLabel(context, plan.type),
                    periodLabel(context, plan),
                    '${plan.exercises.length} · ${l.planExercises}',
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (groupNames.isNotEmpty)
                  Text(
                    groupNames.join(', '),
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (showStatus) ...[
                  const SizedBox(height: 4),
                  StatusPill(
                    label: planStatusLabel(context, plan.status),
                    color: planStatusColor(plan.status),
                    dense: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainingPlansRepositoryProvider).recordView(widget.planId).catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final plan = ref.watch(planProvider(widget.planId));
    return Scaffold(
      appBar: AppBar(title: Text(l.plansTitle)),
      body: AsyncView<TrainingPlan?>(
        value: plan,
        data: (p) =>
            p == null ? EmptyState(icon: Icons.search_off_rounded, title: l.errorNotFound) : _PlanBody(plan: p),
      ),
    );
  }
}

class _PlanBody extends ConsumerWidget {
  const _PlanBody({required this.plan});

  final TrainingPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(currentUserProvider);
    final groups = ref.watch(groupsByIdProvider);
    final planGroups = plan.groupIds.map((g) => groups[g]).whereType<Group>().toList();
    final isCoach = me != null && planGroups.any((g) => g.hasCoach(me.id) && me.isApprovedCoach);
    final kids = me != null && me.isParent
        ? (ref.watch(myChildrenProvider).value ?? const <Child>[])
              .where((c) => plan.groupIds.any(c.groupIds.contains))
              .toList()
        : const <Child>[];
    final progress = ref.watch(planProgressProvider(plan.id)).value ?? const <ExerciseProgress>[];
    final today = LocalDate.tbilisi(ref.watch(clockProvider)());
    return ConstrainedContent(
      maxWidth: Breakpoints.readable,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(plan.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              StatusPill(label: planTypeLabel(context, plan.type), color: AppColors.blue, dense: true),
              StatusPill(label: periodLabel(context, plan), color: AppColors.neutral, dense: true),
              if (isCoach)
                StatusPill(
                  key: const Key('plan-status'),
                  label: planStatusLabel(context, plan.status),
                  color: planStatusColor(plan.status),
                  dense: true,
                ),
              if (plan.activeOn(today) && plan.type == PlanType.homework)
                StatusPill(label: l.planHomeworkDue, color: AppColors.warning, dense: true),
            ],
          ),
          if (plan.description.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), Text(plan.description)],
          const SizedBox(height: 4),
          Text(
            '${plan.coachName} · ${planGroups.map((g) => g.name).join(', ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (isCoach) _CoachPanel(plan: plan),
          if (!isCoach && kids.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            DemoBanner(text: l.planSelfReported),
          ],
          SectionHeader(l.planExercises),
          for (var i = 0; i < plan.exercises.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ExerciseCard(index: i, plan: plan, exercise: plan.exercises[i], kids: kids, progress: progress),
            ),
        ],
      ),
    );
  }
}

class _CoachPanel extends ConsumerWidget {
  const _CoachPanel({required this.plan});

  final TrainingPlan plan;

  Future<void> _status(BuildContext context, WidgetRef ref, PlanStatus s, String success) =>
      runGuarded(context, () => ref.read(trainingPlansRepositoryProvider).setStatus(plan.id, s), success: success);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final stats = ref.watch(planStatsProvider(plan.id)).value;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AppCard(
        key: const Key('plan-coach-panel'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stats != null) ...[
              Text(l.planViews(stats.viewers), key: const Key('plan-views')),
              Text(l.planCompletion('${stats.completed}', stats.total), key: const Key('plan-completion')),
              Text(l.planSelfReported, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
            ],
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                OutlinedButton.icon(
                  key: const Key('plan-edit'),
                  onPressed: () => context.push(Routes.editPlan(plan.id)),
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(l.edit),
                ),
                if (plan.status == PlanStatus.draft)
                  FilledButton.icon(
                    key: const Key('plan-publish-now'),
                    onPressed: () => _status(context, ref, PlanStatus.published, l.planPublished),
                    icon: const Icon(Icons.publish_rounded),
                    label: Text(l.planPublish),
                  ),
                if (plan.status == PlanStatus.published) ...[
                  OutlinedButton(
                    onPressed: () => _status(context, ref, PlanStatus.draft, l.planSaved),
                    child: Text(l.planUnpublish),
                  ),
                  OutlinedButton(
                    key: const Key('plan-archive'),
                    onPressed: () => _status(context, ref, PlanStatus.archived, l.planArchived),
                    child: Text(l.planArchive),
                  ),
                ],
                if (plan.status == PlanStatus.draft)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                    onPressed: () async {
                      final ok = await confirmDialog(
                        context,
                        title: l.delete,
                        message: plan.title,
                        confirmLabel: l.delete,
                        destructive: true,
                      );
                      if (!ok || !context.mounted) return;
                      final done = await runGuarded(
                        context,
                        () => ref.read(trainingPlansRepositoryProvider).delete(plan.id),
                      );
                      if (done && context.mounted) context.pop();
                    },
                    child: Text(l.delete),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
    required this.index,
    required this.plan,
    required this.exercise,
    required this.kids,
    required this.progress,
  });

  final int index;
  final TrainingPlan plan;
  final Exercise exercise;
  final List<Child> kids;
  final List<ExerciseProgress> progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final e = exercise;
    final facts = [
      if (e.durationMin != null) l.exerciseMinutes(e.durationMin!),
      if (e.sets != null && e.reps != null)
        l.exerciseSummary('${e.sets}', '${e.reps}')
      else if (e.reps != null)
        '${e.reps} ×',
      if (e.restSec != null) l.exerciseRestSec(e.restSec!),
    ];
    return AppCard(
      key: Key('exercise-${e.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1}. ${e.name}', style: Theme.of(context).textTheme.titleSmall),
          if (facts.isNotEmpty) Text(facts.join(' · '), style: Theme.of(context).textTheme.labelMedium),
          if (e.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(e.description)),
          if (e.instructions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(e.instructions, style: Theme.of(context).textTheme.bodySmall),
            ),
          if (e.media.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final m in e.media) ExerciseMediaTile(planId: plan.id, media: m)],
            ),
          ],
          for (final c in kids) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(l.progressFor(c.firstName), style: Theme.of(context).textTheme.labelMedium),
            SegmentedButton<ProgressStatus>(
              key: Key('progress-${e.id}-${c.id}'),
              showSelectedIcon: false,
              segments: [
                for (final s in ProgressStatus.values)
                  ButtonSegment(
                    value: s,
                    label: FittedBox(
                      child: Text(progressLabel(context, s), key: Key('progress-${e.id}-${c.id}-${s.name}')),
                    ),
                  ),
              ],
              selected: {
                progress.where((p) => p.exerciseId == e.id && p.childId == c.id).firstOrNull?.status ??
                    ProgressStatus.notStarted,
              },
              onSelectionChanged: (s) => runGuarded(
                context,
                () => ref
                    .read(trainingPlansRepositoryProvider)
                    .setProgress(planId: plan.id, exerciseId: e.id, childId: c.id, status: s.first),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
