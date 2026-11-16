import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/engines.dart';
import '../brain_game_screen.dart';
import '../game_feedback.dart';
import 'game_widgets.dart';

class QuickMindGame extends StatefulWidget {
  const QuickMindGame({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<QuickMindGame> createState() => _QuickMindGameState();
}

enum _Last { correct, wrong, slow }

class _QuickMindGameState extends State<QuickMindGame> {
  late final engine = QuickMindEngine(
    difficulty: widget.ctx.difficulty,
    level: widget.ctx.level,
    seed: widget.ctx.seed,
  );
  late QuickRound round = engine.nextRound();
  final _watch = Stopwatch();
  Timer? _limit;
  Timer? _hurry;
  Timer? _gap;
  _Last? _last;
  int? _lastMs;
  int? _tapped;
  bool _between = false;
  bool _urgent = false;
  int _streak = 0;
  int _timeouts = 0;
  int _pulse = 0;

  @override
  void initState() {
    super.initState();
    widget.ctx.paused.addListener(_onPause);
    _arm();
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
  }

  @override
  void dispose() {
    widget.ctx.paused.removeListener(_onPause);
    _limit?.cancel();
    _hurry?.cancel();
    _gap?.cancel();
    super.dispose();
  }

  void _report() => widget.ctx.report(
    GameStats(score: engine.correct * 100, done: engine.played, total: QuickMindEngine.rounds, streak: _streak),
  );

  void _onPause() {
    if (_between) return;
    if (widget.ctx.paused.value) {
      _watch.stop();
      _limit?.cancel();
      _hurry?.cancel();
    } else {
      _watch.start();
      final left = (round.limitMs - _watch.elapsedMilliseconds).clamp(0, round.limitMs);
      _limit = Timer(Duration(milliseconds: left), _timeout);
      _scheduleHurry(left);
    }
  }

  void _scheduleHurry(int leftMs) {
    _hurry?.cancel();
    final until = leftMs - (round.limitMs * .35).round();
    if (until <= 0) {
      _setUrgent();
    } else {
      _hurry = Timer(Duration(milliseconds: until), _setUrgent);
    }
  }

  void _setUrgent() {
    if (!mounted || _between) return;
    widget.ctx.fx.tick();
    setState(() => _urgent = true);
  }

  void _arm() {
    _urgent = false;
    _watch
      ..reset()
      ..start();
    _limit?.cancel();
    _limit = Timer(Duration(milliseconds: round.limitMs), _timeout);
    _scheduleHurry(round.limitMs);
  }

  void _timeout() {
    if (!mounted || engine.isComplete || _between) return;
    engine.timeout();
    widget.ctx.fx.wrong();
    _timeouts++;
    _settle(_Last.slow, null);
  }

  void _tap(int i) {
    if (engine.isComplete || _between) return;
    _limit?.cancel();
    final ms = _watch.elapsedMilliseconds;
    final ok = engine.tap(round, i, ms);
    ok ? widget.ctx.fx.correct() : widget.ctx.fx.wrong();
    _settle(ok ? _Last.correct : _Last.wrong, i, ms: ok ? ms : null);
  }

  /// Show the result of this round for a short moment, then move on.
  void _settle(_Last r, int? tapped, {int? ms}) {
    _hurry?.cancel();
    _watch.stop();
    setState(() {
      _last = r;
      _lastMs = ms;
      _tapped = tapped;
      _between = true;
      _urgent = false;
      _streak = r == _Last.correct ? _streak + 1 : 0;
      _pulse++;
    });
    _report();
    _gap = Timer(const Duration(milliseconds: 650), _next);
  }

  void _next() {
    if (!mounted) return;
    if (engine.isComplete) {
      final won = engine.accuracy >= 0.6;
      widget.ctx.onFinished(
        GameOutcome(
          won: won,
          score: engine.score(),
          accuracy: engine.accuracy,
          attempts: engine.played,
          detail: {'avgReactionMs': engine.avgReactionMs},
          failReason: won
              ? null
              : (_timeouts * 2 >= engine.played - engine.correct ? FailReason.tooSlow : FailReason.lowAccuracy),
        ),
      );
      return;
    }
    setState(() {
      round = engine.nextRound();
      _between = false;
      _tapped = null;
    });
    _arm();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cols = round.items.length <= 4 ? 2 : 3;
    final banner = switch (_last) {
      null => FeedbackBanner(kind: FeedbackKind.info, title: l.objQuick),
      _Last.correct => FeedbackBanner(
        key: const Key('quick-feedback-correct'),
        kind: FeedbackKind.correct,
        title: l.gameCorrect,
        detail: _lastMs == null ? null : l.quickReaction((_lastMs! / 1000).toStringAsFixed(2)),
      ),
      _Last.wrong => FeedbackBanner(
        key: const Key('quick-feedback-wrong'),
        kind: FeedbackKind.wrong,
        title: l.fbWrongTitle,
      ),
      _Last.slow => FeedbackBanner(key: const Key('quick-too-slow'), kind: FeedbackKind.warning, title: l.quickTooSlow),
    };
    return LayoutBuilder(
      builder: (context, c) {
        final tile = ((c.maxWidth - 48) / cols).clamp(64.0, 120.0);
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              l.gameRound(
                engine.played + 1 > QuickMindEngine.rounds ? QuickMindEngine.rounds : engine.played + 1,
                QuickMindEngine.rounds,
              ),
              key: const Key('quick-round'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: AnimatedScale(
                scale: _urgent && !reduceMotion(context) ? 1.08 : 1,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  key: const Key('quick-target'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _urgent ? FeedbackColors.bad : FeedbackColors.warn, width: 4),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: (_urgent ? FeedbackColors.bad : FeedbackColors.warn).withValues(alpha: .35),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: TokenView(shape: round.target.symbol, color: round.target.color, size: 56),
                ),
              ),
            ),
            if (!_between)
              TweenAnimationBuilder<double>(
                key: ValueKey('bar-${engine.played}'),
                tween: Tween(begin: 1, end: 0),
                duration: Duration(milliseconds: round.limitMs),
                builder: (_, v, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        v < .35 ? Icons.hourglass_bottom_rounded : Icons.hourglass_top_rounded,
                        color: v < .35 ? FeedbackColors.bad : FeedbackColors.info,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: LinearProgressIndicator(
                          key: const Key('quick-timer-bar'),
                          value: v,
                          minHeight: 12,
                          color: Color.lerp(FeedbackColors.bad, FeedbackColors.good, v.clamp(0, 1)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      if (v < .35) ...[
                        const SizedBox(width: 6),
                        Text(
                          l.quickHurry,
                          key: const Key('quick-hurry'),
                          style: const TextStyle(color: FeedbackColors.bad, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              const SizedBox(height: 12 + AppSpacing.sm * 2),
            Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [for (var i = 0; i < round.items.length; i++) _item(i, tile)],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: KeyedSubtree(key: ValueKey(_pulse), child: banner),
            ),
          ],
        );
      },
    );
  }

  Widget _item(int i, double tile) {
    final isTarget = round.items[i] == round.target;
    final showCorrect = _between && isTarget;
    final showWrong = _between && _tapped == i && !isTarget;
    Widget w = SizedBox.square(
      dimension: tile,
      child: Stack(
        children: [
          Positioned.fill(
            child: BigTile(
              key: Key('quick-item-$i'),
              onTap: _between ? null : () => _tap(i),
              color: showCorrect ? const Color(0xFFDCFCE7) : (showWrong ? const Color(0xFFFEE2E2) : null),
              border: showCorrect ? FeedbackColors.good : (showWrong ? FeedbackColors.bad : null),
              child: TokenView(shape: round.items[i].symbol, color: round.items[i].color, size: tile * .45),
            ),
          ),
          if (showCorrect || showWrong)
            Positioned(
              right: 4,
              top: 4,
              child: Icon(
                showCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: showCorrect ? FeedbackColors.good : FeedbackColors.bad,
              ),
            ),
        ],
      ),
    );
    if (showWrong) w = Shake(trigger: _pulse, child: w);
    if (showCorrect && _last == _Last.correct) w = GlowPop(trigger: _pulse, child: w);
    return w;
  }
}
