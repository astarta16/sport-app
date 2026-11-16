import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/engines.dart';
import '../brain_game_screen.dart';
import '../game_feedback.dart';
import 'game_widgets.dart';

class LogicQuestGame extends StatefulWidget {
  const LogicQuestGame({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<LogicQuestGame> createState() => _LogicQuestGameState();
}

class _LogicQuestGameState extends State<LogicQuestGame> {
  late final engine = LogicEngine(difficulty: widget.ctx.difficulty, level: widget.ctx.level, seed: widget.ctx.seed);

  /// The puzzle just answered (shown with its explanation until "Next").
  LogicPuzzle? _shown;
  int? _picked;
  int _streak = 0;
  int _pulse = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
  }

  void _report() => widget.ctx.report(
    GameStats(
      score: engine.correct * 100,
      done: engine.answers.length,
      total: LogicEngine.puzzleCount,
      streak: _streak,
    ),
  );

  void _answer(int i) {
    if (_picked != null) return;
    final puzzle = engine.current;
    final ok = engine.answer(i);
    ok ? widget.ctx.fx.correct() : widget.ctx.fx.wrong();
    setState(() {
      _shown = puzzle;
      _picked = i;
      _streak = ok ? _streak + 1 : 0;
      _pulse++;
    });
    _report();
  }

  void _next() {
    widget.ctx.fx.tap();
    if (engine.isComplete) {
      widget.ctx.onFinished(
        GameOutcome(
          won: engine.accuracy >= 0.5,
          score: engine.score(widget.ctx.elapsed()),
          accuracy: engine.accuracy,
          attempts: engine.answers.length,
          failReason: engine.accuracy >= 0.5 ? null : FailReason.lowAccuracy,
        ),
      );
      return;
    }
    setState(() {
      _shown = null;
      _picked = null;
    });
  }

  static int _periodOf(LogicPuzzle p) {
    final s = p.sequence;
    for (var n = 1; n < s.length; n++) {
      var ok = true;
      for (var k = n; k < s.length; k++) {
        if (s[k] != s[k % n]) {
          ok = false;
          break;
        }
      }
      if (ok) return n;
    }
    return s.length;
  }

  String _why(BuildContext context, LogicPuzzle p) {
    final l = context.l10n;
    return switch (p.kind) {
      LogicKind.repeat => l.logicWhyRepeat(_periodOf(p)),
      LogicKind.grow => l.logicWhyGrow,
      LogicKind.missing => l.logicWhyMissing,
    };
  }

  Widget _token(LogicToken t, {double size = 28}) =>
      TokenView(shape: t.shape.index, color: t.color.index, count: t.count, size: size);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final p = _shown ?? engine.current;
    final answered = _picked != null;
    final ok = answered && _picked == p.answer;
    final round = engine.answers.length + (answered ? 0 : 1);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          l.gameRound(round.clamp(1, LogicEngine.puzzleCount), LogicEngine.puzzleCount),
          key: const Key('logic-round'),
          textAlign: TextAlign.center,
          style: t.labelLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l.logicWhatsMissing, style: t.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < p.sequence.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: i == p.missingIndex && answered
                      ? (ok ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7))
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: i == p.missingIndex
                        ? (answered ? FeedbackColors.good : FeedbackColors.warn)
                        : Theme.of(context).colorScheme.outline,
                    width: i == p.missingIndex ? 3 : 1,
                  ),
                ),
                child: Center(
                  child: i == p.missingIndex && !answered
                      ? const Text('?', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))
                      : _token(p.sequence[i], size: 24),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [for (var i = 0; i < p.options.length; i++) _option(i, p)],
        ),
        const SizedBox(height: AppSpacing.md),
        if (answered) ...[
          FeedbackBanner(
            key: const Key('logic-feedback'),
            kind: ok ? FeedbackKind.correct : FeedbackKind.wrong,
            title: ok ? l.gameCorrect : l.fbWrongTitle,
            detail: ok ? _why(context, p) : '${l.logicCorrectWas} ${_why(context, p)}',
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            key: const Key('logic-next'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: _next,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(engine.isComplete ? l.gameComplete : l.gameNext),
          ),
        ],
      ],
    );
  }

  Widget _option(int i, LogicPuzzle p) {
    final answered = _picked != null;
    final isAnswer = i == p.answer;
    final isPicked = i == _picked;
    final Color? border = !answered ? null : (isAnswer ? FeedbackColors.good : (isPicked ? FeedbackColors.bad : null));
    final Color? fill = !answered
        ? null
        : (isAnswer ? const Color(0xFFDCFCE7) : (isPicked ? const Color(0xFFFEE2E2) : null));
    Widget tile = SizedBox.square(
      dimension: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: BigTile(
              key: Key('logic-option-$i'),
              onTap: answered ? null : () => _answer(i),
              color: fill,
              border: border,
              semanticLabel: answered && isAnswer ? context.l10n.gameCorrect : null,
              child: Opacity(opacity: answered && !isAnswer && !isPicked ? .45 : 1, child: _token(p.options[i])),
            ),
          ),
          if (answered && (isAnswer || isPicked))
            Positioned(
              right: -6,
              top: -6,
              child: Icon(
                isAnswer ? Icons.check_circle_rounded : Icons.cancel_rounded,
                key: Key(isAnswer ? 'logic-mark-correct' : 'logic-mark-wrong'),
                color: isAnswer ? FeedbackColors.good : FeedbackColors.bad,
                size: 26,
              ),
            ),
        ],
      ),
    );
    if (answered && isPicked && !isAnswer) tile = Shake(trigger: _pulse, child: tile);
    if (answered && isAnswer) tile = GlowPop(trigger: _pulse, child: tile);
    return tile;
  }
}
