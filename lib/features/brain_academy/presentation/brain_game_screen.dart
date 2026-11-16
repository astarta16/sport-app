import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../authentication/presentation/session_providers.dart';
import '../domain/brain_models.dart';
import 'brain_providers.dart';
import 'games/logic_quest_game.dart';
import 'games/memory_match_game.dart';
import 'games/path_finder_game.dart';
import 'games/quick_mind_game.dart';
import 'games/sequence_master_game.dart';
import 'games/smart_play_game.dart';

/// What a finished game reports back to the shell.
class GameOutcome {
  const GameOutcome({
    required this.won,
    required this.score,
    required this.accuracy,
    required this.attempts,
    this.detail = const {},
  });

  final bool won;
  final int score;
  final double accuracy;
  final int attempts;
  final Map<String, num> detail;
}

/// Everything a game widget needs from the shell.
class GameContext {
  const GameContext({
    required this.difficulty,
    required this.level,
    required this.seed,
    required this.paused,
    required this.elapsed,
    required this.onFinished,
    required this.feedback,
  });

  final GameDifficulty difficulty;
  final int level;
  final int seed;

  /// Games stop their own timers while paused.
  final ValueListenable<bool> paused;
  final Duration Function() elapsed;
  final void Function(GameOutcome) onFinished;

  /// Optional sound + haptic tick (respects the sound toggle).
  final void Function({bool good}) feedback;
}

/// Seed source; tests replace it for deterministic boards.
int Function() gameSeed = () => Random().nextInt(1 << 30);

enum _Phase { setup, playing, paused, finished }

/// `/kid/brain/:game` — the common shell around all six games.
class BrainGameScreen extends ConsumerStatefulWidget {
  const BrainGameScreen({super.key, required this.game});

  final BrainGame game;

  @override
  ConsumerState<BrainGameScreen> createState() => _BrainGameScreenState();
}

class _BrainGameScreenState extends ConsumerState<BrainGameScreen> with WidgetsBindingObserver {
  _Phase _phase = _Phase.setup;
  GameDifficulty _difficulty = GameDifficulty.easy;
  int _level = 1;
  int _seed = 0;
  int _round = 0;
  final _stopwatch = Stopwatch();
  final _paused = ValueNotifier(false);
  Timer? _ticker;
  bool _sound = true;
  GameOutcome? _outcome;
  Duration _finalTime = Duration.zero;
  Set<BrainBadge> _newBadges = const {};
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _paused.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _phase == _Phase.playing) _pause();
  }

  String? get _childId => ref.read(currentUserProvider)?.lastContext.childId;

  void _start() {
    setState(() {
      _seed = gameSeed();
      _round++;
      _outcome = null;
      _newBadges = const {};
      _saveFailed = false;
      _phase = _Phase.playing;
    });
    _paused.value = false;
    _stopwatch
      ..reset()
      ..start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && _phase == _Phase.playing) setState(() {});
    });
  }

  void _pause() {
    if (_phase != _Phase.playing) return;
    _stopwatch.stop();
    _paused.value = true;
    setState(() => _phase = _Phase.paused);
  }

  void _resume() {
    if (_phase != _Phase.paused) return;
    _stopwatch.start();
    _paused.value = false;
    setState(() => _phase = _Phase.playing);
  }

  void _feedback({bool good = true}) {
    if (!_sound) return;
    SystemSound.play(SystemSoundType.click);
    good ? HapticFeedback.selectionClick() : HapticFeedback.lightImpact();
  }

  Future<void> _finished(GameOutcome o) async {
    if (_phase == _Phase.finished) return;
    _stopwatch.stop();
    _ticker?.cancel();
    final time = _stopwatch.elapsed;
    setState(() {
      _outcome = o;
      _finalTime = time;
      _phase = _Phase.finished;
    });
    final childId = _childId;
    if (childId == null) return;
    final repo = ref.read(brainAcademyRepositoryProvider);
    final before = BrainBadge.earned(ref.read(brainResultsProvider(childId)).value ?? const []);
    try {
      final saved = await repo.recordResult(
        GameResult(
          id: '',
          childId: childId,
          game: widget.game,
          difficulty: _difficulty,
          level: _level,
          score: o.score,
          accuracy: o.accuracy.clamp(0, 1).toDouble(),
          attempts: o.attempts,
          durationMs: time.inMilliseconds,
          completed: o.won,
          playedAt: DateTime.now(),
          detail: o.detail,
        ),
      );
      final after = BrainBadge.earned([...?ref.read(brainResultsProvider(childId)).value, saved]);
      if (mounted) setState(() => _newBadges = after.difference(before));
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    }
  }

  Widget _game(GameContext c) => switch (widget.game) {
    BrainGame.memoryMatch => MemoryMatchGame(ctx: c),
    BrainGame.logicQuest => LogicQuestGame(ctx: c),
    BrainGame.smartPlay => SmartPlayGame(ctx: c),
    BrainGame.quickMind => QuickMindGame(ctx: c),
    BrainGame.sequenceMaster => SequenceMasterGame(ctx: c),
    BrainGame.pathFinder => PathFinderGame(ctx: c),
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final childId = ref.watch(currentUserProvider)?.lastContext.childId;
    final progress = GameProgress.of(
      widget.game,
      childId == null ? const <GameResult>[] : (ref.watch(brainResultsProvider(childId)).value ?? const []),
    );
    final color = gameColor(widget.game);
    final playing = _phase == _Phase.playing || _phase == _Phase.paused;
    return Scaffold(
      appBar: AppBar(
        title: Text(gameName(context, widget.game), maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          key: const Key('game-close'),
          tooltip: l.gameQuit,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.studentHome),
        ),
        actions: [
          IconButton(
            key: const Key('game-sound'),
            tooltip: l.gameSound,
            onPressed: () => setState(() => _sound = !_sound),
            icon: Icon(_sound ? Icons.volume_up_rounded : Icons.volume_off_rounded),
          ),
          if (playing) ...[
            IconButton(
              key: const Key('game-restart'),
              tooltip: l.gameRestart,
              onPressed: _start,
              icon: const Icon(Icons.replay_rounded),
            ),
            IconButton(
              key: const Key('game-pause'),
              tooltip: _phase == _Phase.paused ? l.gameResume : l.gamePause,
              onPressed: _phase == _Phase.paused ? _resume : _pause,
              icon: Icon(_phase == _Phase.paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: switch (_phase) {
          _Phase.setup => _Setup(
            game: widget.game,
            progress: progress,
            difficulty: _difficulty,
            level: _level,
            onDifficulty: (d) => setState(() {
              _difficulty = d;
              _level = progress.unlockedFor(d);
            }),
            onLevel: (v) => setState(() => _level = v),
            onStart: _start,
          ),
          _Phase.playing || _Phase.paused => Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
                    child: Row(
                      children: [
                        StatusPill(label: difficultyLabel(context, _difficulty), color: color, dense: true),
                        const SizedBox(width: AppSpacing.xs),
                        StatusPill(label: l.gameLevel(_level), color: AppColors.blue, dense: true),
                        const Spacer(),
                        Text(
                          l.gameTime(formatGameTime(_stopwatch.elapsedMilliseconds)),
                          key: const Key('game-timer'),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AbsorbPointer(
                      absorbing: _phase == _Phase.paused,
                      child: KeyedSubtree(
                        key: ValueKey('round-$_round'),
                        child: _game(
                          GameContext(
                            difficulty: _difficulty,
                            level: _level,
                            seed: _seed,
                            paused: _paused,
                            elapsed: () => _stopwatch.elapsed,
                            onFinished: _finished,
                            feedback: _feedback,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_phase == _Phase.paused)
                Positioned.fill(
                  child: ColoredBox(
                    key: const Key('game-paused'),
                    color: Colors.black54,
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l.gamePaused, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: AppSpacing.md),
                              FilledButton.icon(
                                key: const Key('game-resume'),
                                onPressed: _resume,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text(l.gameResume),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              OutlinedButton.icon(
                                onPressed: _start,
                                icon: const Icon(Icons.replay_rounded),
                                label: Text(l.gameRestart),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          _Phase.finished => _Finished(
            outcome: _outcome!,
            time: _finalTime,
            best: max(progress.bestScore, _outcome!.score),
            badges: _newBadges,
            saveFailed: _saveFailed,
            canNext: _outcome!.won && _level < maxLevel,
            onNext: () {
              setState(() => _level = min(maxLevel, _level + 1));
              _start();
            },
            onAgain: _start,
            onMenu: () => setState(() => _phase = _Phase.setup),
          ),
        },
      ),
    );
  }
}

class _Setup extends StatelessWidget {
  const _Setup({
    required this.game,
    required this.progress,
    required this.difficulty,
    required this.level,
    required this.onDifficulty,
    required this.onLevel,
    required this.onStart,
  });

  final BrainGame game;
  final GameProgress progress;
  final GameDifficulty difficulty;
  final int level;
  final ValueChanged<GameDifficulty> onDifficulty;
  final ValueChanged<int> onLevel;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final unlocked = progress.unlockedFor(difficulty);
    final color = gameColor(game);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          key: const Key('game-setup'),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: Icon(gameIcon(game), size: 48, color: color),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(gameName(context, game), style: t.headlineSmall, textAlign: TextAlign.center),
            Text(gameDescription(context, game), style: t.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              key: const Key('game-instructions'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.gameInstructions, style: t.titleSmall),
                  const SizedBox(height: 4),
                  Text(gameHowTo(context, game)),
                ],
              ),
            ),
            SectionHeader(l.gameChooseDifficulty),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final d in GameDifficulty.values)
                  ChoiceChip(
                    key: Key('difficulty-${d.name}'),
                    label: Text(difficultyLabel(context, d)),
                    selected: d == difficulty,
                    onSelected: (_) => onDifficulty(d),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                IconButton(
                  key: const Key('level-down'),
                  onPressed: level > 1 ? () => onLevel(level - 1) : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Expanded(
                  child: Text(
                    l.gameLevel(level),
                    key: const Key('game-level'),
                    style: t.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  key: const Key('level-up'),
                  onPressed: level < unlocked ? () => onLevel(level + 1) : null,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
            if (progress.plays > 0)
              Text(l.gameBestScore(progress.bestScore), textAlign: TextAlign.center, style: t.bodySmall),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: const Key('game-start'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), backgroundColor: color),
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l.gameStart),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l.brainNotIq, style: t.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _Finished extends StatelessWidget {
  const _Finished({
    required this.outcome,
    required this.time,
    required this.best,
    required this.badges,
    required this.saveFailed,
    required this.canNext,
    required this.onNext,
    required this.onAgain,
    required this.onMenu,
  });

  final GameOutcome outcome;
  final Duration time;
  final int best;
  final Set<BrainBadge> badges;
  final bool saveFailed;
  final bool canNext;
  final VoidCallback onNext;
  final VoidCallback onAgain;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final reduce = MediaQuery.of(context).disableAnimations;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          key: const Key('game-finished'),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: reduce ? 1 : 0.6, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Icon(
                outcome.won ? Icons.emoji_events_rounded : Icons.sentiment_satisfied_rounded,
                size: 88,
                color: outcome.won ? AppColors.warning : AppColors.blue,
              ),
            ),
            Text(outcome.won ? l.gameComplete : l.gameTryAgain, style: t.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.gameScore(outcome.score),
              key: const Key('game-final-score'),
              style: t.displaySmall?.copyWith(fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            Text(l.gameBestScore(best), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                StatusPill(label: l.gameAccuracy((outcome.accuracy * 100).round()), color: AppColors.success),
                StatusPill(label: l.gameTime(formatGameTime(time.inMilliseconds)), color: AppColors.blue),
                StatusPill(label: l.gameAttempts(outcome.attempts), color: AppColors.neutral),
              ],
            ),
            if (badges.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(l.gameNewBadge, style: t.titleMedium, textAlign: TextAlign.center),
              Wrap(
                key: const Key('game-new-badges'),
                alignment: WrapAlignment.center,
                spacing: AppSpacing.xs,
                children: [
                  for (final b in badges)
                    Chip(
                      avatar: Icon(badgeIcon(b), color: AppColors.warning),
                      label: Text(badgeLabel(context, b)),
                    ),
                ],
              ),
            ],
            if (saveFailed)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(l.gameSaveFailed, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: AppSpacing.md),
            if (canNext)
              FilledButton.icon(
                key: const Key('game-next-level'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: onNext,
                icon: const Icon(Icons.trending_up_rounded),
                label: Text(l.gameNextLevel),
              ),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton.icon(
              key: const Key('game-again'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: onAgain,
              icon: const Icon(Icons.replay_rounded),
              label: Text(l.gamePlayAgain),
            ),
            TextButton(key: const Key('game-menu'), onPressed: onMenu, child: Text(l.gameChooseDifficulty)),
          ],
        ),
      ),
    );
  }
}
