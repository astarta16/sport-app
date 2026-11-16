import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/brain_models.dart';
import '../../domain/engines.dart';
import '../brain_game_screen.dart';
import '../game_feedback.dart';
import 'game_widgets.dart';

class SequenceMasterGame extends StatefulWidget {
  const SequenceMasterGame({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<SequenceMasterGame> createState() => _SequenceMasterGameState();
}

enum _SeqMsg { none, roundDone, mistake }

class _SequenceMasterGameState extends State<SequenceMasterGame> {
  late final engine = SequenceEngine(difficulty: widget.ctx.difficulty, level: widget.ctx.level, seed: widget.ctx.seed);
  late final int _maxLives = engine.lives;
  bool _showing = true;
  int? _lit;
  int? _wrongPad;
  int _step = 0;
  int _streak = 0;
  int _pulse = 0;
  _SeqMsg _msg = _SeqMsg.none;
  Timer? _timer;
  Timer? _after;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
  }

  @override
  void dispose() {
    widget.ctx.paused.removeListener(_onPause);
    _timer?.cancel();
    _after?.cancel();
    super.dispose();
  }

  void _report() => widget.ctx.report(
    GameStats(
      score: engine.score(),
      done: engine.completedRounds,
      total: engine.target,
      lives: engine.lives,
      maxLives: _maxLives,
      streak: _streak,
    ),
  );

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
      _wrongPad = null;
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
          _msg = _SeqMsg.none;
          return;
        }
        _lit = engine.sequence[_step++];
        widget.ctx.fx.tap();
      });
    });
  }

  void _tap(int i) {
    if (_showing || engine.isOver) return;
    final r = engine.input(i);
    switch (r) {
      case SequenceInput.correct:
        widget.ctx.fx.tap();
      case SequenceInput.roundComplete:
        widget.ctx.fx.correct();
      case SequenceInput.wrong:
        widget.ctx.fx.wrong();
    }
    setState(() {
      _lit = r == SequenceInput.wrong ? null : i;
      if (r == SequenceInput.wrong) {
        _wrongPad = i;
        _streak = 0;
        _msg = _SeqMsg.mistake;
        _pulse++;
      } else if (r == SequenceInput.roundComplete) {
        _streak++;
        _msg = _SeqMsg.roundDone;
        _pulse++;
      }
    });
    _report();
    Timer(const Duration(milliseconds: 180), () {
      if (mounted && !_showing && _lit == i) setState(() => _lit = null);
    });
    if (engine.isOver) {
      _after = Timer(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        widget.ctx.onFinished(
          GameOutcome(
            won: engine.won,
            score: engine.score(),
            accuracy: engine.accuracy,
            attempts: engine.completedRounds + engine.mistakes,
            detail: {'longest': engine.longest},
            failReason: engine.won ? null : FailReason.outOfLives,
          ),
        );
      });
      return;
    }
    if (r == SequenceInput.roundComplete || r == SequenceInput.wrong) {
      _after = Timer(const Duration(milliseconds: 1100), () {
        if (mounted && !widget.ctx.paused.value) _play();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final pads = engine.palette;
    final phase = switch (_msg) {
      _SeqMsg.roundDone => FeedbackBanner(
        key: const Key('sequence-round-done'),
        kind: FeedbackKind.correct,
        title: l.seqRoundDone,
      ),
      _SeqMsg.mistake => FeedbackBanner(
        key: const Key('sequence-mistake'),
        kind: FeedbackKind.wrong,
        title: l.seqMistake,
      ),
      _SeqMsg.none => Container(
        key: const Key('sequence-phase'),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: _showing ? const Color(0xFFEFF6FF) : const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _showing ? FeedbackColors.info : FeedbackColors.good, width: 2),
        ),
        child: Row(
          children: [
            Icon(
              _showing ? Icons.visibility_rounded : Icons.touch_app_rounded,
              color: _showing ? FeedbackColors.info : FeedbackColors.good,
              size: 30,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _showing ? l.gameWatch : l.gameYourTurn,
                    key: const Key('sequence-status'),
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.black87),
                  ),
                  if (!_showing) Text(l.seqRepeatHint, style: t.bodySmall?.copyWith(color: Colors.black87)),
                ],
              ),
            ),
            if (!_showing)
              Text(
                '${engine.position}/${engine.sequence.length}',
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.black87),
              ),
          ],
        ),
      ),
    };
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(key: ValueKey('${_msg.name}-$_showing-$_pulse'), child: phase),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Shake(
                trigger: _msg == _SeqMsg.mistake ? _pulse : 0,
                child: Wrap(spacing: 12, runSpacing: 12, children: [for (var i = 0; i < pads; i++) _pad(i, tile)]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pad(int i, double tile) {
    final lit = _lit == i;
    final wrong = _wrongPad == i;
    final color = gamePalette[i];
    return AnimatedScale(
      scale: lit ? 1.1 : 1,
      duration: const Duration(milliseconds: 120),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (lit) BoxShadow(color: color.withValues(alpha: .9), blurRadius: 28, spreadRadius: 6),
            if (wrong) const BoxShadow(color: FeedbackColors.bad, blurRadius: 18, spreadRadius: 3),
          ],
        ),
        child: SizedBox.square(
          dimension: tile,
          child: Stack(
            children: [
              Positioned.fill(
                child: BigTile(
                  key: Key('sequence-pad-$i'),
                  semanticLabel: '${colorSemantic(i)} ${shapeSemantic(i)}',
                  color: color.withValues(alpha: lit ? 1 : (_showing ? .3 : .6)),
                  border: lit ? Colors.white : (wrong ? FeedbackColors.bad : null),
                  onTap: _showing ? null : () => _tap(i),
                  child: Icon(shapeIcon(i), color: Colors.white, size: tile * .4),
                ),
              ),
              if (wrong)
                const Positioned(right: 6, top: 6, child: Icon(Icons.cancel_rounded, color: Colors.white, size: 26)),
            ],
          ),
        ),
      ),
    );
  }
}
