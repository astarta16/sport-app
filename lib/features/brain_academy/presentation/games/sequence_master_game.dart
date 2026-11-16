import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/brain_models.dart';
import '../../domain/engines.dart';
import '../brain_game_screen.dart';
import 'game_widgets.dart';

class SequenceMasterGame extends StatefulWidget {
  const SequenceMasterGame({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<SequenceMasterGame> createState() => _SequenceMasterGameState();
}

class _SequenceMasterGameState extends State<SequenceMasterGame> {
  late final engine = SequenceEngine(difficulty: widget.ctx.difficulty, level: widget.ctx.level, seed: widget.ctx.seed);
  bool _showing = true;
  int? _lit;
  int _step = 0;
  Timer? _timer;

  Duration get _beat => switch (widget.ctx.difficulty) {
    GameDifficulty.easy => const Duration(milliseconds: 750),
    GameDifficulty.medium => const Duration(milliseconds: 600),
    GameDifficulty.hard => const Duration(milliseconds: 480),
  };

  @override
  void initState() {
    super.initState();
    widget.ctx.paused.addListener(_onPause);
    _play();
  }

  @override
  void dispose() {
    widget.ctx.paused.removeListener(_onPause);
    _timer?.cancel();
    super.dispose();
  }

  /// Pausing during playback replays the whole sequence on resume.
  void _onPause() {
    if (widget.ctx.paused.value) {
      _timer?.cancel();
      setState(() => _lit = null);
    } else if (_showing) {
      _play();
    }
  }

  void _play() {
    _timer?.cancel();
    setState(() {
      _showing = true;
      _step = 0;
      _lit = null;
    });
    _timer = Timer.periodic(_beat, (t) {
      if (!mounted) return t.cancel();
      setState(() {
        if (_lit != null) {
          _lit = null;
          return;
        }
        if (_step >= engine.sequence.length) {
          t.cancel();
          _showing = false;
          return;
        }
        _lit = engine.sequence[_step++];
      });
    });
  }

  void _tap(int i) {
    if (_showing || engine.isOver) return;
    final r = engine.input(i);
    widget.ctx.feedback(good: r != SequenceInput.wrong);
    setState(() => _lit = i);
    Timer(const Duration(milliseconds: 180), () {
      if (mounted && !_showing) setState(() => _lit = null);
    });
    if (engine.isOver) {
      widget.ctx.onFinished(
        GameOutcome(
          won: engine.won,
          score: engine.score(),
          accuracy: engine.accuracy,
          attempts: engine.completedRounds + engine.mistakes,
          detail: {'longest': engine.longest},
        ),
      );
      return;
    }
    if (r == SequenceInput.roundComplete || r == SequenceInput.wrong) {
      Timer(const Duration(milliseconds: 500), () {
        if (mounted && !widget.ctx.paused.value) _play();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pads = engine.palette;
    return LayoutBuilder(
      builder: (context, c) {
        final cols = pads <= 4 ? 2 : 3;
        final tile = ((c.maxWidth - 48) / cols).clamp(72.0, 140.0);
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                Text(
                  l.gameRound(
                    engine.completedRounds + 1 > engine.target ? engine.target : engine.completedRounds + 1,
                    engine.target,
                  ),
                  key: const Key('sequence-round'),
                ),
                Text(l.gameLives(engine.lives), key: const Key('sequence-lives')),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _showing ? l.gameWatch : l.gameYourTurn,
              key: const Key('sequence-status'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: _showing ? AppColors.blue : AppColors.success),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < pads; i++)
                    AnimatedScale(
                      scale: _lit == i ? 1.08 : 1,
                      duration: const Duration(milliseconds: 120),
                      child: SizedBox.square(
                        dimension: tile,
                        child: BigTile(
                          key: Key('sequence-pad-$i'),
                          semanticLabel: '${colorSemantic(i)} ${shapeSemantic(i)}',
                          color: gamePalette[i].withValues(alpha: _lit == i ? 1 : .35),
                          border: _lit == i ? Colors.white : null,
                          onTap: _showing ? null : () => _tap(i),
                          child: Icon(shapeIcon(i), color: Colors.white, size: tile * .4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
