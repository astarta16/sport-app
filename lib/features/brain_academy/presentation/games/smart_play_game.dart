import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/engines.dart';
import '../brain_game_screen.dart';

String playOptionLabel(BuildContext context, PlayOption o) {
  final l = context.l10n;
  return switch (o.action) {
    PlayAction.passTo => l.spPassTo(o.target ?? ''),
    PlayAction.passBack => l.spPassBack(o.target ?? ''),
    PlayAction.dribble => l.spDribble,
    PlayAction.shoot => l.spShoot,
    PlayAction.hold => l.spHold,
  };
}

String explanation(BuildContext context, String key) {
  final l = context.l10n;
  return switch (key) {
    'spExplain1' => l.spExplain1,
    'spExplain2' => l.spExplain2,
    'spExplain3' => l.spExplain3,
    'spExplain4' => l.spExplain4,
    'spExplain5' => l.spExplain5,
    'spExplain6' => l.spExplain6,
    'spExplain7' => l.spExplain7,
    'spExplain8' => l.spExplain8,
    _ => l.spExplain9,
  };
}

class SmartPlayGame extends StatefulWidget {
  const SmartPlayGame({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<SmartPlayGame> createState() => _SmartPlayGameState();
}

class _SmartPlayGameState extends State<SmartPlayGame> {
  late final engine = SmartPlayEngine(
    difficulty: widget.ctx.difficulty,
    level: widget.ctx.level,
    seed: widget.ctx.seed,
  );

  void _choose(int i) {
    final ok = engine.choose(i);
    widget.ctx.feedback(good: ok);
    setState(() {});
  }

  void _next() {
    engine.next();
    if (engine.isComplete) {
      widget.ctx.onFinished(
        GameOutcome(
          won: engine.accuracy >= 0.5,
          score: engine.score(),
          accuracy: engine.accuracy,
          attempts: engine.scenarios.length,
        ),
      );
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = engine.current;
    final choice = engine.lastChoice;
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > c.maxHeight && c.maxWidth > 600;
        final pitch = AspectRatio(
          aspectRatio: 0.72,
          child: CustomPaint(key: Key('pitch-${s.id}'), painter: _PitchPainter(s)),
        );
        final panel = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.gameRound(engine.index + 1, engine.scenarios.length), key: const Key('smart-round')),
            const SizedBox(height: 4),
            Text(l.spQuestion, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < s.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: FilledButton.tonal(
                  key: Key('smart-option-$i'),
                  // After answering the buttons are disabled; the disabled
                  // colours carry the right/wrong highlight.
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    disabledForegroundColor: Theme.of(context).colorScheme.onSurface,
                    disabledBackgroundColor: choice == null
                        ? null
                        : (s.options[i].correct
                              ? AppColors.success.withValues(alpha: .35)
                              : (choice == i ? AppColors.danger.withValues(alpha: .3) : null)),
                  ),
                  onPressed: choice == null ? () => _choose(i) : null,
                  child: Text(playOptionLabel(context, s.options[i])),
                ),
              ),
            if (choice != null) ...[
              Card(
                key: const Key('smart-explanation'),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.options[choice].correct ? l.gameCorrect : l.gameWrong,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: s.options[choice].correct ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      Text(explanation(context, s.explanationKey)),
                    ],
                  ),
                ),
              ),
              FilledButton(
                key: const Key('smart-next'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: _next,
                child: Text(l.spNext),
              ),
            ],
          ],
        );
        return wide
            ? Row(
                children: [
                  Padding(padding: const EdgeInsets.all(AppSpacing.md), child: pitch),
                  Expanded(
                    child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.md), child: panel),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Center(
                    child: ConstrainedBox(constraints: const BoxConstraints(maxHeight: 340), child: pitch),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  panel,
                ],
              );
      },
    );
  }
}

/// Pitch seen from our half (their goal at the top).
class _PitchPainter extends CustomPainter {
  _PitchPainter(this.s);

  final StrategyScenario s;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12));
    canvas.drawRRect(r, Paint()..color = const Color(0xFF2E7D32));
    final line = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(r.deflate(6), line);
    canvas.drawLine(Offset(6, size.height / 2), Offset(size.width - 6, size.height / 2), line);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * .14, line);
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width / 2, 12), width: size.width * .4, height: 20), line);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(size.width / 2, size.height - 12), width: size.width * .4, height: 20),
      line,
    );
    final radius = size.width * .055;
    for (final p in s.players) {
      final o = Offset(p.x * size.width, p.y * size.height);
      canvas.drawCircle(
        o,
        radius,
        Paint()..color = p.team == Team.us ? const Color(0xFF1E88E5) : const Color(0xFFE53935),
      );
      if (p.hasBall) {
        canvas.drawCircle(
          o,
          radius + 5,
          Paint()
            ..color = const Color(0xFFFFEB3B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
      final label = p.id == 'me' ? '●' : (p.team == Team.us ? p.id : '');
      if (label.isEmpty) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: Colors.white, fontSize: radius, fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_PitchPainter old) => old.s.id != s.id;
}
