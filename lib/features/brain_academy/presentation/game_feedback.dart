import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/brain_models.dart';
import 'brain_providers.dart';

bool reduceMotion(BuildContext context) => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Colours used for game feedback; every state also has an icon + label.
abstract final class FeedbackColors {
  static const good = Color(0xFF16A34A);
  static const bad = Color(0xFFDC2626);
  static const info = Color(0xFF2563EB);
  static const warn = Color(0xFFF59E0B);
}

/// Shakes its child horizontally each time [trigger] changes (wrong answer).
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !reduceMotion(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (_, child) =>
        Transform.translate(offset: Offset(sin(_c.value * pi * 6) * 10 * (1 - _c.value), 0), child: child),
  );
}

/// Pulsing glow + slight pop each time [trigger] changes (correct answer).
class GlowPop extends StatefulWidget {
  const GlowPop({
    super.key,
    required this.trigger,
    required this.child,
    this.color = FeedbackColors.good,
    this.radius = 16,
  });

  final int trigger;
  final Widget child;
  final Color color;
  final double radius;

  @override
  State<GlowPop> createState() => _GlowPopState();
}

class _GlowPopState extends State<GlowPop> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void didUpdateWidget(GlowPop old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !reduceMotion(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (_, child) {
      final v = sin(_c.value * pi);
      return Transform.scale(
        scale: 1 + v * 0.06,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: v == 0
                ? null
                : [
                    BoxShadow(
                      color: widget.color.withValues(alpha: .55 * v),
                      blurRadius: 24 * v,
                      spreadRadius: 4 * v,
                    ),
                  ],
          ),
          child: child,
        ),
      );
    },
  );
}

enum FeedbackKind { correct, wrong, info, warning }

/// Big, unmistakable feedback line: icon + bold label (+ optional detail).
/// Colour is never the only signal.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({super.key, required this.kind, required this.title, this.detail});

  final FeedbackKind kind;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (kind) {
      FeedbackKind.correct => (FeedbackColors.good, Icons.check_circle_rounded),
      FeedbackKind.wrong => (FeedbackColors.bad, Icons.cancel_rounded),
      FeedbackKind.info => (FeedbackColors.info, Icons.info_rounded),
      FeedbackKind.warning => (FeedbackColors.warn, Icons.timer_off_rounded),
    };
    // Neutral hints are calmer and smaller than right/wrong feedback.
    final info = kind == FeedbackKind.info;
    return TweenAnimationBuilder<double>(
      key: ValueKey('${kind.name}-$title-$detail'),
      tween: Tween(begin: reduceMotion(context) ? 1 : 0.85, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Semantics(
        liveRegion: true,
        label: [title, ?detail].join('. '),
        child: Container(
          key: Key('feedback-${kind.name}'),
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: info ? 6 : AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color, width: 2.5),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: info ? 24 : 36),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: (info ? Theme.of(context).textTheme.titleSmall : Theme.of(context).textTheme.titleLarge)
                          ?.copyWith(color: info ? Colors.black87 : color, fontWeight: FontWeight.w900),
                    ),
                    if (detail != null) Text(detail!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live game state shown in the HUD (reported by each game).
class GameStats {
  const GameStats({this.score = 0, this.done = 0, this.total = 0, this.lives, this.maxLives, this.streak = 0});

  final int score;
  final int done;
  final int total;
  final int? lives;
  final int? maxLives;
  final int streak;

  double get progress => total == 0 ? 0 : (done / total).clamp(0, 1).toDouble();
}

/// Level, difficulty, score, time, lives, streak and progress. Wraps on
/// small screens so nothing overflows.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.game,
    required this.difficulty,
    required this.level,
    required this.stats,
    required this.timeLabel,
  });

  final BrainGame game;
  final GameDifficulty difficulty;
  final int level;
  final GameStats stats;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = gameColor(game);
    Widget chip(IconData icon, String text, Color c, {Key? key}) => Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: .5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontWeight: FontWeight.w800, color: c, fontSize: 13),
          ),
        ],
      ),
    );
    return Padding(
      key: const Key('game-hud'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              chip(Icons.signal_cellular_alt_rounded, difficultyLabel(context, difficulty), color),
              chip(Icons.flag_rounded, l.gameLevel(level), FeedbackColors.info),
              chip(
                Icons.star_rounded,
                '${l.hudScore} ${stats.score}',
                FeedbackColors.warn,
                key: const Key('hud-score'),
              ),
              chip(Icons.timer_rounded, timeLabel, const Color(0xFF475569), key: const Key('game-timer')),
              if (stats.lives != null)
                Semantics(
                  label: l.gameLives(stats.lives!),
                  child: Row(
                    key: const Key('hud-lives'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < (stats.maxLives ?? stats.lives!); i++)
                        Icon(
                          i < stats.lives! ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: FeedbackColors.bad,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              if (stats.streak >= 2)
                chip(
                  Icons.local_fire_department_rounded,
                  l.hudStreak(stats.streak),
                  const Color(0xFFEA580C),
                  key: const Key('hud-streak'),
                ),
            ],
          ),
          if (stats.total > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: stats.progress),
                    duration: const Duration(milliseconds: 350),
                    builder: (_, v, _) => LinearProgressIndicator(
                      key: const Key('hud-progress'),
                      value: v,
                      minHeight: 10,
                      color: color,
                      backgroundColor: color.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(l.hudProgress(stats.done, stats.total), style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 0–3 stars: success gives at least one; accuracy decides the rest.
int starsFor({required bool won, required double accuracy}) {
  if (!won) return 0;
  if (accuracy >= 0.9) return 3;
  if (accuracy >= 0.7) return 2;
  return 1;
}

class StarsRow extends StatelessWidget {
  const StarsRow({super.key, required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.resultStars(stars),
    child: Row(
      key: Key('result-stars-$stars'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: reduceMotion(context) ? 1 : 0, end: 1),
            duration: Duration(milliseconds: 350 + i * 220),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              size: i == 1 ? 64 : 52,
              color: i < stars ? const Color(0xFFFBBF24) : Colors.black26,
            ),
          ),
      ],
    ),
  );
}

/// Lightweight celebration (falling confetti) — skipped with reduced motion.
class Confetti extends StatefulWidget {
  const Confetti({super.key});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();
  final _rng = Random(7);
  late final _bits = List.generate(
    48,
    (i) => (
      x: _rng.nextDouble(),
      speed: .6 + _rng.nextDouble() * .8,
      drift: _rng.nextDouble() - .5,
      color: _palette[i % _palette.length],
      size: 6 + _rng.nextDouble() * 6,
    ),
  );
  static const _palette = [
    Color(0xFFF43F5E),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFFFBBF24),
    Color(0xFFA855F7),
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_bits, _c.value)),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.bits, this.t);

  final List<({double x, double speed, double drift, Color color, double size})> bits;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bits) {
      final y = (t * b.speed) * size.height * 1.1 - 20;
      final x = (b.x + b.drift * t * .3) * size.width;
      final p = Paint()..color = b.color.withValues(alpha: (1 - t).clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 8 * b.drift);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: b.size, height: b.size * .6),
          const Radius.circular(2),
        ),
        p,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Soft, playful background tinted with the game's colour.
BoxDecoration gameBackground(BrainGame game) {
  final c = gameColor(game);
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [c.withValues(alpha: .16), c.withValues(alpha: .04), Colors.white.withValues(alpha: 0)],
      stops: const [0, .45, 1],
    ),
  );
}
