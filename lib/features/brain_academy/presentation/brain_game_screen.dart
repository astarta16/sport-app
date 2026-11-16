import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../authentication/presentation/session_providers.dart';
import '../domain/brain_models.dart';
import 'brain_providers.dart';
import 'game_feedback.dart';
import 'game_fx.dart';
import 'games/logic_quest_game.dart';
import 'games/memory_match_game.dart';
import 'games/path_finder_game.dart';
import 'games/quick_mind_game.dart';
import 'games/sequence_master_game.dart';
import 'games/smart_play_game.dart';

/// Why a play did not succeed (shown kindly on the result screen).
enum FailReason { outOfLives, lowAccuracy, tooSlow }

/// What a finished game reports back to the shell.
class GameOutcome {
  const GameOutcome({
    required this.won,
    required this.score,
    required this.accuracy,
    required this.attempts,
    this.detail = const {},
    this.failReason,
  });

  final bool won;
  final int score;
  final double accuracy;
  final int attempts;
  final Map<String, num> detail;
  final FailReason? failReason;
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
    required this.fx,
    required this.report,
  });

  final GameDifficulty difficulty;
  final int level;
  final int seed;

  /// Games stop their own timers while paused.
  final ValueListenable<bool> paused;
  final Duration Function() elapsed;
  final void Function(GameOutcome) onFinished;

  /// Sound + haptics (respect the persisted settings).
  final GameFx fx;

  /// Live score / progress / lives / streak for the HUD.
  final void Function(GameStats) report;
}

/// Seed source; tests replace it for deterministic boards.
int Function() gameSeed = () => Random().nextInt(1 << 30);

String objectiveText(BuildContext context, BrainGame g) {
  final l = context.l10n;
  return switch (g) {
    BrainGame.memoryMatch => l.objMemory,
    BrainGame.logicQuest => l.objLogic,
    BrainGame.smartPlay => l.objSmart,
    BrainGame.quickMind => l.objQuick,
    BrainGame.sequenceMaster => l.objSequence,
    BrainGame.pathFinder => l.objPath,
  };
}

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
  GameStats _stats = const GameStats();
  GameOutcome? _outcome;
  Duration _finalTime = Duration.zero;
  Set<BrainBadge> _newBadges = const {};
  bool _newHigh = false;
  bool _challengeDone = false;
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
  GameFx get _fx => ref.read(gameFxProvider);

  void _start() {
    _fx.tap();
    setState(() {
      _seed = gameSeed();
      _round++;
      _outcome = null;
      _stats = const GameStats();
      _newBadges = const {};
      _newHigh = false;
      _challengeDone = false;
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
    _fx.tap();
    _stopwatch.start();
    _paused.value = false;
    setState(() => _phase = _Phase.playing);
  }

  void _report(GameStats s) {
    if (!mounted) return;
    // Games may report during their own build/initState; defer to be safe.
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _stats = s);
      });
    } else {
      setState(() => _stats = s);
    }
  }

  Future<void> _finished(GameOutcome o) async {
    if (_phase == _Phase.finished) return;
    _stopwatch.stop();
    _ticker?.cancel();
    final time = _stopwatch.elapsed;
    final childId = _childId;
    final previous = childId == null
        ? const <GameResult>[]
        : (ref.read(brainResultsProvider(childId)).value ?? const <GameResult>[]);
    final best = GameProgress.of(widget.game, previous).bestScore;
    setState(() {
      _outcome = o;
      _finalTime = time;
      _newHigh = o.score > best && previous.any((r) => r.game == widget.game);
      _phase = _Phase.finished;
    });
    o.won ? _fx.levelComplete() : _fx.fail();
    if (childId == null) return;
    final challenges = ref.read(childChallengesProvider(childId)).value ?? const <ChallengeAssignment>[];
    final before = BrainBadge.earned(previous);
    try {
      final saved = await ref
          .read(brainAcademyRepositoryProvider)
          .recordResult(
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
      final after = [...previous, saved];
      final badges = BrainBadge.earned(after).difference(before);
      final challengeDone = challenges.any((a) => !a.doneBy(previous) && a.doneBy(after));
      if (!mounted) return;
      setState(() {
        _newBadges = badges;
        _challengeDone = challengeDone;
      });
      if (badges.isNotEmpty || challengeDone) _fx.reward();
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    }
  }

  void _openSettings() => showModalBottomSheet<void>(context: context, builder: (_) => const BrainSettingsSheet());

  Widget _game(GameContext c) => switch (widget.game) {
    BrainGame.memoryMatch => MemoryMatchGame(ctx: c),
    BrainGame.logicQuest => LogicQuestGame(ctx: c),
    BrainGame.smartPlay => SmartPlayGame(ctx: c),
    BrainGame.quickMind => QuickMindGame(ctx: c),
    BrainGame.sequenceMaster => SequenceMasterGame(ctx: c),
    BrainGame.pathFinder => PathFinderGame(ctx: c),
  };

  void _toHub() => context.canPop() ? context.pop() : context.go(Routes.studentHome);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final childId = ref.watch(currentUserProvider)?.lastContext.childId;
    if (childId != null) ref.watch(childChallengesProvider(childId));
    final progress = GameProgress.of(
      widget.game,
      childId == null ? const <GameResult>[] : (ref.watch(brainResultsProvider(childId)).value ?? const []),
    );
    final playing = _phase == _Phase.playing || _phase == _Phase.paused;
    final sound = ref.watch(brainSettingsProvider).sound;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: gameColor(widget.game).withValues(alpha: .16),
        // Light, tinted bar → dark status-bar icons.
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(gameName(context, widget.game), maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          key: const Key('game-close'),
          tooltip: l.gameQuit,
          icon: const Icon(Icons.close_rounded),
          onPressed: _toHub,
        ),
        actions: [
          IconButton(
            key: const Key('game-sound'),
            tooltip: l.brainSettingsTitle,
            onPressed: _openSettings,
            icon: Icon(sound ? Icons.volume_up_rounded : Icons.volume_off_rounded),
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
      body: DecoratedBox(
        decoration: gameBackground(widget.game),
        child: SafeArea(
          child: switch (_phase) {
            _Phase.setup => _Setup(
              game: widget.game,
              progress: progress,
              difficulty: _difficulty,
              level: _level,
              onDifficulty: (d) {
                _fx.tap();
                setState(() {
                  _difficulty = d;
                  _level = progress.unlockedFor(d);
                });
              },
              onLevel: (v) {
                _fx.tap();
                setState(() => _level = v);
              },
              onStart: _start,
            ),
            _Phase.playing || _Phase.paused => Stack(
              children: [
                Column(
                  children: [
                    GameHud(
                      game: widget.game,
                      difficulty: _difficulty,
                      level: _level,
                      stats: _stats,
                      timeLabel: formatGameTime(_stopwatch.elapsedMilliseconds),
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
                              fx: _fx,
                              report: _report,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_phase == _Phase.paused) _PausedOverlay(onResume: _resume, onRestart: _start),
              ],
            ),
            _Phase.finished => _Result(
              outcome: _outcome!,
              time: _finalTime,
              best: max(progress.bestScore, _outcome!.score),
              newHigh: _newHigh,
              badges: _newBadges,
              challengeDone: _challengeDone,
              saveFailed: _saveFailed,
              level: _level,
              canNext: _outcome!.won && _level < maxLevel,
              canEasier: !_outcome!.won && _difficulty != GameDifficulty.easy,
              onNext: () {
                setState(() => _level = min(maxLevel, _level + 1));
                _start();
              },
              onAgain: _start,
              onEasier: () {
                final easier = GameDifficulty.values[_difficulty.index - 1];
                setState(() {
                  _difficulty = easier;
                  _level = progress.unlockedFor(easier);
                });
                _start();
              },
              onHub: _toHub,
            ),
          },
        ),
      ),
    );
  }
}

/// Sound / vibration switches (persisted).
class BrainSettingsSheet extends ConsumerWidget {
  const BrainSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(brainSettingsProvider);
    final n = ref.read(brainSettingsProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.brainSettingsTitle, style: Theme.of(context).textTheme.titleLarge),
            SwitchListTile(
              key: const Key('setting-sound'),
              secondary: const Icon(Icons.volume_up_rounded),
              title: Text(l.gameSound),
              value: s.sound,
              onChanged: n.setSound,
            ),
            SwitchListTile(
              key: const Key('setting-haptics'),
              secondary: const Icon(Icons.vibration_rounded),
              title: Text(l.settingsHaptics),
              value: s.haptics,
              onChanged: n.setHaptics,
            ),
          ],
        ),
      ),
    );
  }
}

class _PausedOverlay extends StatelessWidget {
  const _PausedOverlay({required this.onResume, required this.onRestart});

  final VoidCallback onResume;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Positioned.fill(
      child: ColoredBox(
        key: const Key('game-paused'),
        color: Colors.black54,
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pause_circle_filled_rounded, size: 64, color: FeedbackColors.info),
                  Text(l.gamePaused, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    key: const Key('game-resume'),
                    style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(l.gameResume),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(200, 48)),
                    onPressed: onRestart,
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(l.gameRestart),
                  ),
                ],
              ),
            ),
          ),
        ),
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
    String hint(GameDifficulty d) => switch (d) {
      GameDifficulty.easy => l.diffEasyHint,
      GameDifficulty.medium => l.diffMediumHint,
      GameDifficulty.hard => l.diffHardHint,
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          key: const Key('game-setup'),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, .25)!]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: color.withValues(alpha: .35), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(gameIcon(game), size: 38, color: color),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gameName(context, game),
                          style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          objectiveText(context, game),
                          key: const Key('game-objective'),
                          style: t.bodyMedium?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              key: const Key('game-instructions'),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_rounded, color: color),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.gameInstructions, style: t.titleSmall),
                          const SizedBox(height: 4),
                          Text(gameHowTo(context, game)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l.gameChooseDifficulty, style: t.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            for (final d in GameDifficulty.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: d == difficulty ? color.withValues(alpha: .16) : Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: d == difficulty ? color : Colors.black12, width: d == difficulty ? 2.5 : 1),
                  ),
                  child: InkWell(
                    key: Key('difficulty-${d.name}'),
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onDifficulty(d),
                    child: Semantics(
                      selected: d == difficulty,
                      button: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              d == difficulty ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                              color: d == difficulty ? color : Colors.black38,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(difficultyLabel(context, d), style: t.titleSmall),
                                  Text(hint(d), style: t.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          key: const Key('level-down'),
                          iconSize: 32,
                          onPressed: level > 1 ? () => onLevel(level - 1) : null,
                          icon: const Icon(Icons.remove_circle_rounded),
                        ),
                        Expanded(
                          child: Text(
                            l.gameLevel(level),
                            key: const Key('game-level'),
                            style: t.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          key: const Key('level-up'),
                          iconSize: 32,
                          onPressed: level < unlocked ? () => onLevel(level + 1) : null,
                          icon: const Icon(Icons.add_circle_rounded),
                        ),
                      ],
                    ),
                    Text(l.levelsUnlocked(unlocked), style: t.bodySmall, textAlign: TextAlign.center),
                    if (progress.plays > 0)
                      Text(l.gameBestScore(progress.bestScore), style: t.bodySmall, textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: const Key('game-start'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: color,
                textStyle: t.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded, size: 32),
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

class _Result extends StatelessWidget {
  const _Result({
    required this.outcome,
    required this.time,
    required this.best,
    required this.newHigh,
    required this.badges,
    required this.challengeDone,
    required this.saveFailed,
    required this.level,
    required this.canNext,
    required this.canEasier,
    required this.onNext,
    required this.onAgain,
    required this.onEasier,
    required this.onHub,
  });

  final GameOutcome outcome;
  final Duration time;
  final int best;
  final bool newHigh;
  final Set<BrainBadge> badges;
  final bool challengeDone;
  final bool saveFailed;
  final int level;
  final bool canNext;
  final bool canEasier;
  final VoidCallback onNext;
  final VoidCallback onAgain;
  final VoidCallback onEasier;
  final VoidCallback onHub;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final won = outcome.won;
    final reduce = reduceMotion(context);
    final reason = switch (outcome.failReason) {
      FailReason.outOfLives => l.failOutOfLives,
      FailReason.lowAccuracy => l.failLowAccuracy,
      FailReason.tooSlow => l.failTooSlow,
      null => null,
    };
    Widget stat(IconData i, String label, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: .5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(i, color: c, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    return Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              key: Key(won ? 'game-finished' : 'game-failed'),
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: reduce ? 1 : 0.5, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: Icon(
                    won ? Icons.emoji_events_rounded : Icons.sentiment_satisfied_alt_rounded,
                    size: 96,
                    color: won ? FeedbackColors.warn : FeedbackColors.info,
                  ),
                ),
                Text(
                  won ? l.resultLevelComplete : l.resultFailTitle,
                  key: Key(won ? 'result-success-title' : 'result-fail-title'),
                  style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                if (won)
                  StarsRow(stars: starsFor(won: true, accuracy: outcome.accuracy))
                else ...[
                  const SizedBox(height: 4),
                  Text(l.resultFailEncourage, textAlign: TextAlign.center, style: t.bodyLarge),
                  if (reason != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: FeedbackBanner(
                        key: const Key('result-fail-reason'),
                        kind: FeedbackKind.info,
                        title: reason,
                      ),
                    ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l.gameScore(outcome.score),
                  key: const Key('game-final-score'),
                  style: t.displaySmall?.copyWith(fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                if (newHigh)
                  Center(
                    child: Container(
                      key: const Key('result-new-high'),
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: FeedbackColors.warn, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: FeedbackColors.warn),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              l.resultNewHighScore,
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text(l.gameBestScore(best), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    stat(
                      Icons.gps_fixed_rounded,
                      l.gameAccuracy((outcome.accuracy * 100).round()),
                      FeedbackColors.good,
                    ),
                    stat(Icons.timer_rounded, l.gameTime(formatGameTime(time.inMilliseconds)), FeedbackColors.info),
                    stat(Icons.touch_app_rounded, l.gameAttempts(outcome.attempts), const Color(0xFF64748B)),
                  ],
                ),
                if (challengeDone)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: FeedbackBanner(
                      key: const Key('result-challenge-done'),
                      kind: FeedbackKind.correct,
                      title: l.resultChallengeDone,
                    ),
                  ),
                if (badges.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(l.gameNewBadge, style: t.titleLarge, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    key: const Key('game-new-badges'),
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final (i, b) in badges.indexed)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: reduce ? 1 : 0, end: 1),
                          duration: Duration(milliseconds: 600 + i * 250),
                          curve: Curves.elasticOut,
                          builder: (_, v, child) => Transform.scale(scale: v, child: child),
                          child: Chip(
                            avatar: Icon(badgeIcon(b), color: FeedbackColors.warn),
                            label: Text(
                              badgeLabel(context, b),
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
                            ),
                            backgroundColor: const Color(0xFFFEF3C7),
                          ),
                        ),
                    ],
                  ),
                ],
                if (canNext)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      l.resultNextUnlocked(level + 1),
                      key: const Key('result-unlocked'),
                      textAlign: TextAlign.center,
                      style: t.titleSmall?.copyWith(color: FeedbackColors.good),
                    ),
                  ),
                if (saveFailed)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(l.gameSaveFailed, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                const SizedBox(height: AppSpacing.md),
                if (canNext) ...[
                  FilledButton.icon(
                    key: const Key('game-next-level'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: FeedbackColors.good,
                    ),
                    onPressed: onNext,
                    icon: const Icon(Icons.trending_up_rounded),
                    label: Text(l.gameNextLevel),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                FilledButton.tonalIcon(
                  key: const Key('game-again'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: onAgain,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(won ? l.gamePlayAgain : l.resultRetry),
                ),
                if (canEasier) ...[
                  const SizedBox(height: AppSpacing.xs),
                  OutlinedButton.icon(
                    key: const Key('game-easier'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: onEasier,
                    icon: const Icon(Icons.south_rounded),
                    label: Text(l.resultTryEasier),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                TextButton.icon(
                  key: const Key('game-back-hub'),
                  onPressed: onHub,
                  icon: const Icon(Icons.psychology_rounded),
                  label: Text(l.resultBackToAcademy),
                ),
              ],
            ),
          ),
        ),
        if (won) const Positioned.fill(child: IgnorePointer(child: Confetti())),
      ],
    );
  }
}
