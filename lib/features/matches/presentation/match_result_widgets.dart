import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../groups/presentation/groups_providers.dart';
import '../domain/match.dart';
import 'matches_providers.dart';

String outcomeLabel(BuildContext context, MatchOutcome o) {
  final l = context.l10n;
  return switch (o) {
    MatchOutcome.win => l.matchWin,
    MatchOutcome.draw => l.matchDraw,
    MatchOutcome.loss => l.matchLoss,
  };
}

Color outcomeColor(MatchOutcome o) => switch (o) {
  MatchOutcome.win => AppColors.success,
  MatchOutcome.draw => AppColors.warning,
  MatchOutcome.loss => AppColors.danger,
};

/// Finished matches with a result, newest first, for the given groups.
List<SportMatch> resultsFor(Iterable<SportMatch> all, Set<String> groupIds) =>
    all.where((m) => groupIds.contains(m.groupId) && m.result != null).toList()
      ..sort((a, b) => b.result!.completedAt.compareTo(a.result!.completedAt));

/// Big score: "our team 3 — 1 opponent", outcome, date, coach summary.
class MatchResultCard extends ConsumerWidget {
  const MatchResultCard({super.key, required this.match});

  final SportMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final t = Theme.of(context).textTheme;
    final r = match.result!;
    final group = ref.watch(groupsByIdProvider)[match.groupId];
    final ours = group?.name ?? l.matchResultOurTeam;
    Widget side(String name, String caption, CrossAxisAlignment a) => Expanded(
      child: Column(
        crossAxisAlignment: a,
        children: [
          Text(caption, style: t.labelSmall),
          Text(
            name,
            style: t.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: a == CrossAxisAlignment.end ? TextAlign.end : TextAlign.start,
          ),
        ],
      ),
    );
    return AppCard(
      key: Key('match-result-${match.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l.matchResultTitle, style: t.labelLarge),
              StatusPill(
                key: Key('match-outcome-${match.id}'),
                label: outcomeLabel(context, r.outcome),
                color: outcomeColor(r.outcome),
                dense: true,
              ),
              if (r.corrected) StatusPill(label: l.matchResultCorrected, color: AppColors.neutral, dense: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              side(ours, l.matchResultOurTeam, CrossAxisAlignment.start),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  '${r.ourScore} — ${r.opponentScore}',
                  key: Key('match-score-${match.id}'),
                  style: t.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              side(match.opponentName, l.matchResultOpponent, CrossAxisAlignment.end),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l.matchResultFinishedAt(f.dateTime(r.completedAt)), style: t.bodySmall),
          if ((r.summary ?? '').isNotEmpty) ...[const SizedBox(height: AppSpacing.xs), Text(r.summary!)],
        ],
      ),
    );
  }
}

/// Compact row for dashboards, the student profile and the calendar.
class MatchResultTile extends ConsumerWidget {
  const MatchResultTile({super.key, required this.match});

  final SportMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final t = Theme.of(context).textTheme;
    final r = match.result;
    final group = ref.watch(groupsByIdProvider)[match.groupId];
    return AppCard(
      key: Key('result-tile-${match.id}'),
      onTap: () => context.push(Routes.match(match.id)),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (r == null ? AppColors.volt : outcomeColor(r.outcome)).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: r == null
                ? const Icon(Icons.emoji_events_rounded)
                : Text(
                    '${r.ourScore}:${r.opponentScore}',
                    style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: outcomeColor(r.outcome)),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.matchVs(match.opponentName), style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  [f.dayMonth(match.startAt), if (group != null) group.name].join(' · '),
                  style: t.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (r != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: StatusPill(label: outcomeLabel(context, r.outcome), color: outcomeColor(r.outcome), dense: true),
            ),
        ],
      ),
    );
  }
}

/// Dashboard: most recent final score of the child's groups.
class LatestResultCard extends ConsumerWidget {
  const LatestResultCard({super.key, required this.groupIds});

  final Set<String> groupIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = resultsFor(ref.watch(myMatchesProvider).value ?? const [], groupIds).firstOrNull;
    if (latest == null) return const SizedBox.shrink();
    return Padding(
      key: const Key('dashboard-latest-result'),
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(context.l10n.matchResultLatest),
          MatchResultTile(match: latest),
        ],
      ),
    );
  }
}

/// Coach: enter or correct the final score (server-validated and audited).
Future<void> showMatchResultDialog(BuildContext context, WidgetRef ref, SportMatch match) async {
  final l = context.l10n;
  final prev = match.result;
  final our = TextEditingController(text: prev?.ourScore.toString() ?? '');
  final their = TextEditingController(text: prev?.opponentScore.toString() ?? '');
  final summary = TextEditingController(text: prev?.summary ?? '');
  DateTime? finishedAt = prev?.completedAt;
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final f = Fmt.of(ctx);
        final now = ref.read(clockProvider)();
        Widget score(TextEditingController c, String label, String key) => Expanded(
          child: TextField(
            key: Key(key),
            controller: c,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
            textAlign: TextAlign.center,
            style: Theme.of(ctx).textTheme.headlineSmall,
            decoration: InputDecoration(labelText: label),
          ),
        );
        return AlertDialog(
          key: const Key('match-result-dialog'),
          title: Text(prev == null ? l.matchResultEnter : l.matchResultCorrect),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    score(our, l.matchResultOurTeam, 'result-our'),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('—')),
                    score(their, l.matchResultOpponent, 'result-their'),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  key: const Key('result-summary'),
                  controller: summary,
                  maxLength: MatchResult.maxSummary,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: l.matchResultSummary),
                ),
                OutlinedButton.icon(
                  key: const Key('result-finished-at'),
                  onPressed: () async {
                    final day = await showDatePicker(
                      context: ctx,
                      initialDate: finishedAt ?? now,
                      firstDate: match.startAt,
                      lastDate: now,
                    );
                    if (day == null || !ctx.mounted) return;
                    final tm = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(finishedAt ?? now),
                    );
                    if (tm == null) return;
                    setState(() => finishedAt = DateTime(day.year, day.month, day.day, tm.hour, tm.minute));
                  },
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(l.matchResultFinishedAt(f.dateTime(finishedAt ?? now))),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l.matchResultNotice, style: Theme.of(ctx).textTheme.bodySmall),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            FilledButton(key: const Key('result-save'), onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
          ],
        );
      },
    ),
  );
  if (saved != true || !context.mounted) return;
  await runGuarded(
    context,
    () => ref
        .read(matchesRepositoryProvider)
        .recordResult(
          match.id,
          our: int.tryParse(our.text) ?? -1,
          their: int.tryParse(their.text) ?? -1,
          summary: summary.text,
          completedAt: finishedAt,
        ),
    success: l.matchResultSaved,
  );
}
