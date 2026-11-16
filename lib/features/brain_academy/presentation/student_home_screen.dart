import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/visuals.dart';
import '../../attendance/domain/attendance.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../matches/domain/match.dart';
import '../../matches/presentation/match_result_widgets.dart';
import '../../sports/presentation/sports_providers.dart';
import '../../training_plans/domain/training_plan.dart';
import '../../trainings/domain/training.dart';
import '../domain/brain_models.dart';
import '../domain/student_view.dart';
import '../../sports/presentation/sport_label.dart';
import 'brain_providers.dart';
import '../../organizations/presentation/feature_gate.dart';
import '../../organizations/domain/organization.dart';
import 'student_v17_widgets.dart';

/// `/kid/home` — v1.6 student experience (demo mode only): Home, Brain
/// Academy and Progress. No payments, certificates, chat, phone numbers,
/// admin functions or other children's records.
class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final view = ref.watch(studentViewProvider);
    final titles = [l.studentNavHome, l.studentNavBrain, l.studentNavProgress];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        actions: [
          IconButton(
            key: const Key('student-language'),
            tooltip: l.languageLabel,
            icon: const Icon(Icons.translate_rounded),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const SafeArea(
                child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: LanguageSelector()),
              ),
            ),
          ),
          IconButton(
            key: const Key('student-sign-out'),
            tooltip: l.signOut,
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            key: const Key('student-nav-home'),
            icon: const Icon(Icons.home_rounded),
            label: l.studentNavHome,
          ),
          NavigationDestination(
            key: const Key('student-nav-brain'),
            icon: const Icon(Icons.psychology_rounded),
            label: l.studentNavBrain,
          ),
          NavigationDestination(
            key: const Key('student-nav-progress'),
            icon: const Icon(Icons.insights_rounded),
            label: l.studentNavProgress,
          ),
        ],
      ),
      body: AsyncView<StudentView>(
        value: view,
        onRetry: () => ref.invalidate(studentViewProvider),
        data: (v) => IndexedStack(
          index: _tab,
          children: [
            _HomeTab(view: v, openBrain: () => setState(() => _tab = 1)),
            BrainHub(childId: v.child.id),
            _page(const Key('student-progress'), [
              BrainPointsDashboard(childId: v.child.id),
              StudentLeaderboards(view: v),
              BrainProgressView(childId: v.child.id),
            ]),
          ],
        ),
      ),
    );
  }
}

Widget _page(Key key, List<Widget> children) => ConstrainedContent(
  maxWidth: Breakpoints.readable,
  child: ListView(
    key: key,
    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
    children: children,
  ),
);

Widget _nothing(BuildContext context) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Text(context.l10n.studentNothing, style: Theme.of(context).textTheme.bodySmall),
);

class _HomeTab extends ConsumerWidget {
  const _HomeTab({required this.view, required this.openBrain});

  final StudentView view;
  final VoidCallback openBrain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final t = Theme.of(context).textTheme;
    final now = ref.watch(clockProvider)();
    final c = view.child;
    final next = view.trainings
        .where((tr) => tr.startAt.isAfter(now) && tr.status != TrainingStatus.cancelled)
        .firstOrNull;
    final upcoming = view.matches.where((m) => m.status.isActive && m.startAt.isAfter(now)).take(3).toList();
    final results = view.matches.where((m) => m.result != null).toList()
      ..sort((a, b) => b.result!.completedAt.compareTo(a.result!.completedAt));
    final homework = view.plans.where((p) => p.type == PlanType.homework).toList();
    final plans = view.plans.where((p) => p.type != PlanType.homework).toList();
    final starts = {
      for (final tr in view.trainings)
        if (tr.status != TrainingStatus.cancelled && !tr.startAt.isAfter(now)) tr.id: tr.startAt,
    };
    final stats = AttendanceStats.compute(view.attendance, starts);
    final brain = ref.watch(brainResultsProvider(c.id)).value ?? const <GameResult>[];
    final badges = BrainBadge.earned(brain);
    final sports = ref.watch(sportsByIdProvider);
    return _page(const Key('student-home'), [
      AppCard(
        gradient: AppColors.nightGradient,
        child: Row(
          children: [
            UserAvatar(name: c.fullName, photoPath: c.photoPath, size: 64),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                l.studentWelcome(c.firstName),
                key: const Key('student-welcome'),
                style: t.titleLarge?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      // Brain Academy is the hero of the student dashboard.
      if (ref.watch(featureOnProvider(OrgModule.brainAcademy)))
        AppCard(
          key: const Key('student-brain-hero'),
          onTap: openBrain,
          color: const Color(0xFF7C4DFF).withValues(alpha: 0.14),
          child: Row(
            children: [
              const Icon(Icons.psychology_rounded, size: 48, color: Color(0xFF7C4DFF)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.brainAcademy, style: t.titleLarge),
                    Text(l.brainTagline, style: t.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ChallengesList(childId: c.id, compact: true),
      SectionHeader(l.studentMySports),
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final g in view.groups)
            Chip(
              avatar: SportBadge(sportKey: g.sportId, size: 24),
              label: Text('${sports[g.sportId]?.label(context) ?? g.sportId} · ${g.name}'),
            ),
        ],
      ),
      StudentCoachesSection(view: view),
      SectionHeader(l.studentNextTraining),
      if (next == null)
        _nothing(context)
      else
        AppCard(
          key: const Key('student-next-training'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.weekdayDayMonth(next.startAt), style: t.titleSmall),
              Text('${f.time(next.startAt)} – ${f.time(next.endAt)}', style: t.headlineSmall),
              Text(view.groups.where((g) => g.id == next.groupId).firstOrNull?.name ?? ''),
            ],
          ),
        ),
      StudentEventsSection(view: view),
      SectionHeader(l.studentUpcomingMatches),
      if (upcoming.isEmpty) _nothing(context),
      for (final m in upcoming) _MatchLine(match: m),
      SectionHeader(l.studentMatchResults),
      if (results.isEmpty) _nothing(context),
      for (final m in results.take(3)) _MatchLine(match: m),
      SectionHeader(l.studentHomework),
      if (homework.isEmpty) _nothing(context),
      for (final p in homework) _PlanLine(plan: p),
      SectionHeader(l.studentPlans),
      if (plans.isEmpty) _nothing(context),
      for (final p in plans) _PlanLine(plan: p),
      SectionHeader(l.studentAttendance),
      Text(
        stats.rate == null ? l.studentNothing : l.studentAttendanceRate((stats.rate! * 100).round()),
        key: const Key('student-attendance'),
        style: t.titleMedium,
      ),
      SectionHeader(l.studentAchievements),
      Wrap(
        key: const Key('student-achievements'),
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final a in stats.achievements)
            Chip(
              avatar: const Icon(Icons.military_tech_rounded, color: AppColors.warning),
              label: Text(achievementLabel(context, a.kind)),
            ),
          for (final b in badges)
            Chip(
              avatar: Icon(badgeIcon(b), color: const Color(0xFF7C4DFF)),
              label: Text(badgeLabel(context, b)),
            ),
          if (stats.achievements.isEmpty && badges.isEmpty) _nothing(context),
        ],
      ),
    ]);
  }
}

/// Read-only match line (students do not open match/venue details).
class _MatchLine extends StatelessWidget {
  const _MatchLine({required this.match});

  final SportMatch match;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final r = match.result;
    return Padding(
      key: Key('student-match-${match.id}'),
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: r == null ? AppColors.neutral : outcomeColor(r.outcome)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.matchVs(match.opponentName), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(f.dateTime(match.startAt), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (r != null) ...[
              Text(
                '${r.ourScore}:${r.opponentScore}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(width: 6),
              StatusPill(label: outcomeLabel(context, r.outcome), color: outcomeColor(r.outcome), dense: true),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanLine extends StatelessWidget {
  const _PlanLine({required this.plan});

  final TrainingPlan plan;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: AppCard(
      key: Key('student-plan-${plan.id}'),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(plan.title, style: Theme.of(ctx).textTheme.titleLarge),
              if (plan.description.isNotEmpty) Text(plan.description),
              const SizedBox(height: AppSpacing.sm),
              for (final e in plan.exercises)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fitness_center_rounded),
                  title: Text(e.name),
                  subtitle: e.instructions.isEmpty ? null : Text(e.instructions),
                ),
            ],
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(plan.type == PlanType.homework ? Icons.home_work_rounded : Icons.assignment_rounded),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(plan.title, maxLines: 2, overflow: TextOverflow.ellipsis)),
          Text('${plan.exercises.length}'),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

/// The six games + coach challenges.
class BrainHub extends ConsumerWidget {
  const BrainHub({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final results = ref.watch(brainResultsProvider(childId)).value ?? const <GameResult>[];
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 520 ? 2 : 1);
        return ListView(
          key: const Key('student-brain'),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
          children: [
            Text(l.brainTagline, style: Theme.of(context).textTheme.titleMedium),
            Text(l.brainNotIq, style: Theme.of(context).textTheme.bodySmall),
            ChallengesList(childId: childId),
            const SizedBox(height: AppSpacing.sm),
            ResponsiveGrid(
              minItemWidth: c.maxWidth / cols - 16,
              maxColumns: cols,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [for (final g in BrainGame.values) _GameCard(game: g, progress: GameProgress.of(g, results))],
            ),
          ],
        );
      },
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.progress});

  final BrainGame game;
  final GameProgress progress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = gameColor(game);
    return AppCard(
      key: Key('brain-game-${game.name}'),
      onTap: () => context.push(Routes.brainGame(game.name)),
      color: color.withValues(alpha: 0.10),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            child: Icon(gameIcon(game), color: Colors.white, size: 32),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gameName(context, game), style: Theme.of(context).textTheme.titleMedium),
                Text(gameDescription(context, game), style: Theme.of(context).textTheme.bodySmall),
                Text(
                  progress.plays == 0 ? l.brainNoPlays : l.gameBestScore(progress.bestScore),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.play_circle_fill_rounded, size: 36),
        ],
      ),
    );
  }
}

/// Coach challenges for the child with done / to-do / overdue state.
/// Students get a play button; parents and coaches see status only.
class ChallengesList extends ConsumerWidget {
  const ChallengesList({super.key, required this.childId, this.compact = false});

  final String childId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final now = ref.watch(clockProvider)();
    final me = ref.watch(currentUserProvider);
    final list = ref.watch(childChallengesProvider(childId)).value ?? const <ChallengeAssignment>[];
    final results = ref.watch(brainResultsProvider(childId)).value ?? const <GameResult>[];
    final shown = compact ? list.where((a) => !a.doneBy(results)).toList() : list;
    if (shown.isEmpty) return compact ? const SizedBox.shrink() : const SizedBox.shrink();
    return Column(
      key: Key('challenges-$childId'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.studentChallenges),
        for (final a in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: AppCard(
              key: Key('challenge-${a.id}'),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(gameIcon(a.game), color: gameColor(a.game)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${gameName(context, a.game)} · ${difficultyLabel(context, a.difficulty)}'),
                        if (a.dueDate != null)
                          Text(l.challengeDue(f.dayMonth(a.dueDate!)), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (a.doneBy(results))
                    StatusPill(label: l.challengeDone, color: AppColors.success, dense: true)
                  else if (a.overdue(now, results))
                    StatusPill(label: l.challengeOverdue, color: AppColors.danger, dense: true)
                  else if (me?.isStudent ?? false)
                    FilledButton(
                      key: Key('challenge-play-${a.id}'),
                      onPressed: () => context.push(Routes.brainGame(a.game.name)),
                      child: Text(l.challengeOpenAction),
                    )
                  else
                    StatusPill(label: l.challengeOpen, color: AppColors.warning, dense: true),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Per-game progress, improvement over time and badges. Used by the
/// student, the child's parents and the child's coaches.
class BrainProgressView extends ConsumerWidget {
  const BrainProgressView({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final results = ref.watch(brainResultsProvider(childId));
    return AsyncView<List<GameResult>>(
      value: results,
      onRetry: () => ref.invalidate(brainResultsProvider(childId)),
      data: (list) {
        final badges = BrainBadge.earned(list);
        return Column(
          key: Key('brain-progress-$childId'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.brainNotIq, style: t.bodySmall),
            SectionHeader(l.brainBadges),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final b in BrainBadge.values)
                  Chip(
                    key: Key('badge-${b.name}'),
                    avatar: Icon(badgeIcon(b), color: badges.contains(b) ? AppColors.warning : AppColors.neutral),
                    label: Text(badgeLabel(context, b)),
                    backgroundColor: badges.contains(b) ? AppColors.volt.withValues(alpha: .3) : null,
                  ),
              ],
            ),
            for (final g in BrainGame.values) _GameProgressCard(progress: GameProgress.of(g, list)),
          ],
        );
      },
    );
  }
}

class _GameProgressCard extends StatelessWidget {
  const _GameProgressCard({required this.progress});

  final GameProgress progress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final g = progress.game;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AppCard(
        key: Key('progress-${g.name}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(gameIcon(g), color: gameColor(g)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(gameName(context, g), style: t.titleSmall)),
                Text(progress.plays == 0 ? l.brainNoPlays : l.brainPlays(progress.plays), style: t.bodySmall),
              ],
            ),
            if (progress.plays > 0) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: 4,
                children: [
                  StatusPill(label: l.gameBestScore(progress.bestScore), color: gameColor(g), dense: true),
                  StatusPill(
                    label: l.gameAccuracy((progress.bestAccuracy * 100).round()),
                    color: AppColors.success,
                    dense: true,
                  ),
                  if (progress.bestTimeMs != null)
                    StatusPill(
                      label: l.gameTime(formatGameTime(progress.bestTimeMs!)),
                      color: AppColors.blue,
                      dense: true,
                    ),
                ],
              ),
              Text(
                l.brainUnlocked(
                  [for (final d in GameDifficulty.values) '${difficultyLabel(context, d)} ${progress.unlockedFor(d)}']
                      .join(' · '),
                ),
                style: t.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(l.brainRecentScores, style: t.labelSmall),
              SizedBox(
                height: 40,
                width: double.infinity,
                child: CustomPaint(painter: _Sparkline(progress.recentScores, gameColor(g))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Simple bar sparkline of recent scores (improvement over time).
class _Sparkline extends CustomPainter {
  _Sparkline(this.values, this.color);

  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = max(1, values.reduce(max));
    final w = size.width / max(values.length, 1);
    final p = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      final h = (values[i] / maxV) * (size.height - 4) + 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(i * w + 2, size.height - h, w - 4, h), const Radius.circular(3)),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_Sparkline old) => old.values != values;
}
