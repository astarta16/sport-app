import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/engines.dart';
import '../brain_game_screen.dart';
import 'game_widgets.dart';

class LogicQuestGame extends StatefulWidget {
  const LogicQuestGame({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<LogicQuestGame> createState() => _LogicQuestGameState();
}

class _LogicQuestGameState extends State<LogicQuestGame> {
  late final engine = LogicEngine(difficulty: widget.ctx.difficulty, level: widget.ctx.level, seed: widget.ctx.seed);
  bool? _last;

  void _answer(int i) {
    final ok = engine.answer(i);
    widget.ctx.feedback(good: ok);
    setState(() => _last = ok);
    if (engine.isComplete) {
      widget.ctx.onFinished(
        GameOutcome(
          won: engine.accuracy >= 0.5,
          score: engine.score(widget.ctx.elapsed()),
          accuracy: engine.accuracy,
          attempts: engine.answers.length,
        ),
      );
    }
  }

  Widget _token(LogicToken t, {double size = 28}) =>
      TokenView(shape: t.shape.index, color: t.color.index, count: t.count, size: size);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = engine.current;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          l.gameRound(engine.answers.length + (engine.isComplete ? 0 : 1), LogicEngine.puzzleCount),
          key: const Key('logic-round'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l.logicWhatsMissing, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < p.sequence.length; i++)
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: i == p.missingIndex ? AppColors.warning : Theme.of(context).colorScheme.outline,
                    width: i == p.missingIndex ? 3 : 1,
                  ),
                ),
                child: Center(
                  child: i == p.missingIndex
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
          children: [
            for (var i = 0; i < p.options.length; i++)
              SizedBox.square(
                dimension: 84,
                child: BigTile(
                  key: Key('logic-option-$i'),
                  onTap: engine.isComplete ? null : () => _answer(i),
                  child: _token(p.options[i]),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_last != null)
          Text(
            _last! ? l.gameCorrect : l.gameWrong,
            key: const Key('logic-feedback'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _last! ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
      ],
    );
  }
}
