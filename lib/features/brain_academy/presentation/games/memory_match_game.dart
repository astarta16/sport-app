import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/engines.dart';
import '../brain_game_screen.dart';
import 'game_widgets.dart';

const _sportIcons = [
  Icons.sports_soccer_rounded,
  Icons.sports_basketball_rounded,
  Icons.sports_tennis_rounded,
  Icons.pool_rounded,
  Icons.sports_volleyball_rounded,
  Icons.sports_handball_rounded,
  Icons.sports_rugby_rounded,
  Icons.sports_baseball_rounded,
  Icons.sports_hockey_rounded,
  Icons.sports_martial_arts_rounded,
  Icons.directions_run_rounded,
  Icons.emoji_events_rounded,
];

class MemoryMatchGame extends StatefulWidget {
  const MemoryMatchGame({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  late final engine = MemoryEngine(difficulty: widget.ctx.difficulty, level: widget.ctx.level, seed: widget.ctx.seed);
  Timer? _hide;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _tap(int i) {
    final r = engine.flip(i);
    if (r == FlipOutcome.ignored) return;
    setState(() {});
    if (r == FlipOutcome.match) widget.ctx.feedback(good: true);
    if (r == FlipOutcome.mismatch) {
      widget.ctx.feedback(good: false);
      _hide = Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(engine.hideMismatch);
      });
    }
    if (engine.isComplete) {
      final elapsed = widget.ctx.elapsed();
      widget.ctx.onFinished(
        GameOutcome(won: true, score: engine.score(elapsed), accuracy: engine.accuracy, attempts: engine.attempts),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final n = engine.cards.length;
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > c.maxHeight ? (n > 12 ? 6 : 4) : (n > 12 ? 4 : 3);
        final rows = (n / cols).ceil();
        final size = min((c.maxWidth - 32) / cols, (c.maxHeight - 72) / rows) - 8;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Text(l.gameAttempts(engine.attempts), key: const Key('memory-attempts')),
            ),
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 0; i < n; i++)
                      SizedBox.square(
                        dimension: max(56, size),
                        child: _Card(
                          key: Key('memory-card-$i'),
                          open: engine.faceUp.contains(i) || engine.matched.contains(i),
                          matched: engine.matched.contains(i),
                          icon: _sportIcons[engine.cards[i] % _sportIcons.length],
                          onTap: () => _tap(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.open, required this.matched, required this.icon, required this.onTap});

  final bool open;
  final bool matched;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return BigTile(
      onTap: open ? null : onTap,
      color: matched ? AppColors.success.withValues(alpha: .18) : (open ? Colors.white : AppColors.blue),
      semanticLabel: open ? icon.codePoint.toString() : 'card',
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: reduce ? 0 : 250),
        transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
        child: open
            ? Icon(icon, key: ValueKey('open-$icon'), size: 36, color: AppColors.navy)
            : const Icon(Icons.question_mark_rounded, key: ValueKey('closed'), color: Colors.white, size: 30),
      ),
    );
  }
}
