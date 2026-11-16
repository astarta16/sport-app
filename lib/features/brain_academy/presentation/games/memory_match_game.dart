import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/engines.dart';
import '../brain_game_screen.dart';
import '../game_feedback.dart';

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
  int _combo = 0;
  int _bestCombo = 0;

  /// Last pair result (true = match) and a counter that re-triggers animations.
  bool? _last;
  int _pulse = 0;
  Set<int> _wrongPair = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _report() => widget.ctx.report(
    GameStats(
      score: engine.matched.length ~/ 2 * 50 + _bestCombo * 10,
      done: engine.matched.length ~/ 2,
      total: engine.pairs,
      streak: _combo,
    ),
  );

  void _tap(int i) {
    if (engine.waitingToHide) return;
    final open = List.of(engine.faceUp);
    final r = engine.flip(i);
    if (r == FlipOutcome.ignored) return;
    switch (r) {
      case FlipOutcome.first:
        widget.ctx.fx.tap();
      case FlipOutcome.match:
        _combo++;
        _bestCombo = max(_bestCombo, _combo);
        _last = true;
        _pulse++;
        _wrongPair = const {};
        widget.ctx.fx.correct();
      case FlipOutcome.mismatch:
        _combo = 0;
        _last = false;
        _pulse++;
        _wrongPair = {...open, i};
        widget.ctx.fx.wrong();
        _hide = Timer(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          setState(() {
            engine.hideMismatch();
            _wrongPair = const {};
          });
        });
      case FlipOutcome.ignored:
        break;
    }
    setState(() {});
    _report();
    if (engine.isComplete) {
      final elapsed = widget.ctx.elapsed();
      widget.ctx.onFinished(
        GameOutcome(
          won: true,
          score: engine.score(elapsed),
          accuracy: engine.accuracy,
          attempts: engine.attempts,
          detail: {'bestCombo': _bestCombo},
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final n = engine.cards.length;
    final banner = switch (_last) {
      null => FeedbackBanner(key: const Key('memory-hint'), kind: FeedbackKind.info, title: l.objMemory),
      true => FeedbackBanner(
        kind: FeedbackKind.correct,
        title: _combo > 1 ? '${l.memoryPair} ${l.comboLabel(_combo)}' : l.memoryPair,
      ),
      false => FeedbackBanner(kind: FeedbackKind.wrong, title: l.memoryNoPair),
    };
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > c.maxHeight ? (n > 12 ? 6 : 4) : (n > 12 ? 4 : 3);
        final rows = (n / cols).ceil();
        final size = min((c.maxWidth - 32) / cols, (c.maxHeight - 120) / rows) - 8;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, 0),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: KeyedSubtree(key: ValueKey(_pulse), child: banner),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(l.gameAttempts(engine.attempts), key: const Key('memory-attempts')),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < n; i++)
                        SizedBox.square(
                          dimension: max(56, size),
                          child: Shake(
                            trigger: _wrongPair.contains(i) ? _pulse : 0,
                            child: _FlipCard(
                              key: Key('memory-card-$i'),
                              open: engine.faceUp.contains(i) || engine.matched.contains(i),
                              matched: engine.matched.contains(i),
                              wrong: _wrongPair.contains(i),
                              glow: engine.matched.contains(i) && _last == true ? _pulse : 0,
                              icon: _sportIcons[engine.cards[i] % _sportIcons.length],
                              onTap: () => _tap(i),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A card that flips in 3D between its back (?) and its sport icon.
class _FlipCard extends StatelessWidget {
  const _FlipCard({
    super.key,
    required this.open,
    required this.matched,
    required this.wrong,
    required this.glow,
    required this.icon,
    required this.onTap,
  });

  final bool open;
  final bool matched;
  final bool wrong;
  final int glow;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotion(context);
    return Semantics(
      button: !open,
      label: matched ? 'matched' : (open ? 'open card' : 'card'),
      child: GestureDetector(
        onTap: open ? null : onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: open ? 1 : 0),
          duration: Duration(milliseconds: reduce ? 0 : 320),
          curve: Curves.easeInOut,
          builder: (context, v, _) {
            final showFront = v >= .5;
            final angle = v * pi;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(angle),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(showFront ? pi : 0),
                child: GlowPop(trigger: glow, child: showFront ? _front(context) : _back()),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _back() => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
    ),
    child: const Center(child: Icon(Icons.question_mark_rounded, color: Colors.white, size: 30)),
  );

  Widget _front(BuildContext context) {
    final border = matched ? FeedbackColors.good : (wrong ? FeedbackColors.bad : Colors.black12);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: matched ? const Color(0xFFDCFCE7) : (wrong ? const Color(0xFFFEE2E2) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: matched || wrong ? 3 : 1),
      ),
      child: Stack(
        children: [
          Center(child: Icon(icon, size: 36, color: AppColors.navy)),
          if (matched)
            const Positioned(
              right: 4,
              top: 4,
              child: Icon(Icons.check_circle_rounded, color: FeedbackColors.good, size: 18),
            ),
          if (wrong)
            const Positioned(right: 4, top: 4, child: Icon(Icons.cancel_rounded, color: FeedbackColors.bad, size: 18)),
        ],
      ),
    );
  }
}
