import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../../groups/presentation/groups_providers.dart';
import '../domain/brain_models.dart';
import 'brain_providers.dart';

/// `/group/:groupId/challenges` — coach assigns Brain Academy games
/// (difficulty, optional due date) and reviews completion per child.
class CoachChallengesScreen extends ConsumerWidget {
  const CoachChallengesScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final group = ref.watch(groupsByIdProvider)[groupId];
    final list = ref.watch(groupChallengesProvider(groupId));
    final members = ref.watch(groupMembersProvider(groupId)).value ?? const <Child>[];
    return Scaffold(
      appBar: AppBar(title: Text([l.coachChallengesTitle, ?group?.name].join(' · '), maxLines: 2)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('challenge-assign'),
        onPressed: () => showAssignChallengeSheet(context, ref, groupId),
        icon: const Icon(Icons.add_task_rounded),
        label: Text(l.challengeAssign),
      ),
      body: AsyncView<List<ChallengeAssignment>>(
        value: list,
        onRetry: () => ref.invalidate(groupChallengesProvider(groupId)),
        data: (items) => ConstrainedContent(
          maxWidth: Breakpoints.readable,
          child: ListView(
            key: const Key('challenge-list'),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
            children: [
              Text(l.brainParentNote, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              if (items.isEmpty) EmptyState(icon: Icons.psychology_outlined, title: l.challengeEmpty),
              for (final a in items) _AssignmentCard(assignment: a, members: members),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentCard extends ConsumerWidget {
  const _AssignmentCard({required this.assignment, required this.members});

  final ChallengeAssignment assignment;
  final List<Child> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final a = assignment;
    final done = [
      for (final c in members)
        if (a.doneBy(ref.watch(brainResultsProvider(c.id)).value ?? const [])) c,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        key: Key('assignment-${a.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(gameIcon(a.game), color: gameColor(a.game)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text('${gameName(context, a.game)} · ${difficultyLabel(context, a.difficulty)}')),
                IconButton(
                  key: Key('assignment-remove-${a.id}'),
                  tooltip: l.challengeRemove,
                  onPressed: () =>
                      runGuarded(context, () => ref.read(brainAcademyRepositoryProvider).removeAssignment(a.id)),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            Text(
              a.dueDate == null ? l.challengeNoDue : l.challengeDue(f.dayMonth(a.dueDate!)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            StatusPill(
              key: Key('assignment-completion-${a.id}'),
              label: l.challengeCompletion(done.length, members.length),
              color: done.length == members.length && members.isNotEmpty ? AppColors.success : AppColors.blue,
              dense: true,
            ),
            if (done.isNotEmpty)
              Text(done.map((c) => c.firstName).join(', '), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

Future<void> showAssignChallengeSheet(BuildContext context, WidgetRef ref, String groupId) async {
  final l = context.l10n;
  var game = BrainGame.memoryMatch;
  var difficulty = GameDifficulty.easy;
  DateTime? due;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => SafeArea(
        child: ListView(
          key: const Key('challenge-sheet'),
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(l.challengeAssign, style: Theme.of(ctx).textTheme.titleLarge),
            SectionHeader(l.challengeGame),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final g in BrainGame.values)
                  ChoiceChip(
                    key: Key('challenge-game-${g.name}'),
                    avatar: Icon(gameIcon(g), size: 18),
                    label: Text(gameName(ctx, g)),
                    selected: g == game,
                    onSelected: (_) => setState(() => game = g),
                  ),
              ],
            ),
            SectionHeader(l.challengeDifficulty),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final d in GameDifficulty.values)
                  ChoiceChip(
                    key: Key('challenge-diff-${d.name}'),
                    label: Text(difficultyLabel(ctx, d)),
                    selected: d == difficulty,
                    onSelected: (_) => setState(() => difficulty = d),
                  ),
              ],
            ),
            SectionHeader(l.challengeDueDate),
            OutlinedButton.icon(
              key: const Key('challenge-due'),
              onPressed: () async {
                final now = ref.read(clockProvider)();
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: due ?? now.add(const Duration(days: 7)),
                  firstDate: DateTime(now.year, now.month, now.day),
                  lastDate: now.add(const Duration(days: 365)),
                );
                if (d != null) setState(() => due = DateTime(d.year, d.month, d.day, 23, 59));
              },
              icon: const Icon(Icons.event_rounded),
              label: Text(due == null ? l.challengeNoDue : Fmt.of(ctx).dayMonth(due!)),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              key: const Key('challenge-save'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.challengeAssign),
            ),
          ],
        ),
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  await runGuarded(
    context,
    () => ref
        .read(brainAcademyRepositoryProvider)
        .assign(groupId: groupId, game: game, difficulty: difficulty, dueDate: due),
    success: l.challengeAssigned,
  );
}
