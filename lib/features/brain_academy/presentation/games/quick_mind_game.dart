import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/engines.dart';
import '../brain_game_screen.dart';
import 'game_widgets.dart';

class QuickMindGame extends StatefulWidget {
  const QuickMindGame({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<QuickMindGame> createState() => _QuickMindGameState();
}

class _QuickMindGameState extends State<QuickMindGame> {
  late final engine = QuickMindEngine(
    difficulty: widget.ctx.difficulty,
    level: widget.ctx.level,
    seed: widget.ctx.seed,
  );
  late QuickRound round = engine.nextRound();
  final _watch = Stopwatch();
  Timer? _limit;
  bool? _last;

  @override
  void initState() {
    super.initState();
    widget.ctx.paused.addListener(_onPause);
    _arm();
  }

  @override
  void dispose() {
    widget.ctx.paused.removeListener(_onPause);
    _limit?.cancel();
    super.dispose();
  }

  void _onPause() {
    if (widget.ctx.paused.value) {
      _watch.stop();
      _limit?.cancel();
    } else {
      _watch.start();
      _limit = Timer(
        Duration(milliseconds: (round.limitMs - _watch.elapsedMilliseconds).clamp(0, round.limitMs)),
        _timeout,
      );
    }
  }

  void _arm() {
    _watch
      ..reset()
      ..start();
    _limit?.cancel();
    _limit = Timer(Duration(milliseconds: round.limitMs), _timeout);
  }

  void _timeout() {
    if (!mounted || engine.isComplete) return;
    engine.timeout();
    widget.ctx.feedback(good: false);
    setState(() => _last = false);
    _next();
  }

  void _tap(int i) {
    if (engine.isComplete) return;
    _limit?.cancel();
    final ok = engine.tap(round, i, _watch.elapsedMilliseconds);
    widget.ctx.feedback(good: ok);
    setState(() => _last = ok);
    _next();
  }

  void _next() {
    if (engine.isComplete) {
      _watch.stop();
      widget.ctx.onFinished(
        GameOutcome(
          won: engine.accuracy >= 0.6,
          score: engine.score(),
          accuracy: engine.accuracy,
          attempts: engine.played,
          detail: {'avgReactionMs': engine.avgReactionMs},
        ),
      );
      return;
    }
    setState(() => round = engine.nextRound());
    _arm();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cols = round.items.length <= 4 ? 2 : 3;
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
              child: Container(
                key: const Key('quick-target'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.warning, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TokenView(shape: round.target.symbol, color: round.target.color, size: 56),
              ),
            ),
            TweenAnimationBuilder<double>(
              key: ValueKey('bar-${engine.played}'),
              tween: Tween(begin: 1, end: 0),
              duration: Duration(milliseconds: round.limitMs),
              builder: (_, v, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: LinearProgressIndicator(value: v, minHeight: 8, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < round.items.length; i++)
                    SizedBox.square(
                      dimension: tile,
                      child: BigTile(
                        key: Key('quick-item-$i'),
                        onTap: () => _tap(i),
                        child: TokenView(shape: round.items[i].symbol, color: round.items[i].color, size: tile * .45),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_last != null)
              Text(
                _last! ? l.gameCorrect : l.gameWrong,
                textAlign: TextAlign.center,
                style: TextStyle(color: _last! ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w800),
              ),
          ],
        );
      },
    );
  }
}
