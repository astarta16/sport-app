import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/engines.dart';
import '../brain_game_screen.dart';
import '../game_feedback.dart';

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

const _letters = ['A', 'B', 'C', 'D'];

class _SmartPlayGameState extends State<SmartPlayGame> {
  late final engine = SmartPlayEngine(
    difficulty: widget.ctx.difficulty,
    level: widget.ctx.level,
    seed: widget.ctx.seed,
  );
  int _streak = 0;
  int _pulse = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
  }

  void _report() => widget.ctx.report(
    GameStats(
      score: engine.score(),
      done: engine.index + (engine.answered ? 1 : 0),
      total: engine.scenarios.length,
      streak: _streak,
    ),
  );

  void _choose(int i) {
    final ok = engine.choose(i);
    ok ? widget.ctx.fx.correct() : widget.ctx.fx.wrong();
    setState(() {
      _streak = ok ? _streak + 1 : 0;
      _pulse++;
    });
    _report();
  }

  void _next() {
    widget.ctx.fx.tap();
    engine.next();
    if (engine.isComplete) {
      widget.ctx.onFinished(
        GameOutcome(
          won: engine.accuracy >= 0.5,
          score: engine.score(),
          accuracy: engine.accuracy,
          attempts: engine.scenarios.length,
          failReason: engine.accuracy >= 0.5 ? null : FailReason.lowAccuracy,
        ),
      );
      return;
    }
    setState(() {});
    _report();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final s = engine.current;
    final choice = engine.lastChoice;
    final ok = choice != null && s.options[choice].correct;
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > c.maxHeight && c.maxWidth > 600;
        final pitch = Semantics(
          label: l.spQuestion,
          child: AspectRatio(
            aspectRatio: 0.72,
            child: CustomPaint(key: Key('pitch-${s.id}'), painter: _PitchPainter(s, choice)),
          ),
        );
        final panel = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.gameRound(engine.index + 1, engine.scenarios.length), key: const Key('smart-round')),
            const SizedBox(height: 4),
            Text(l.spQuestion, style: t.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (choice != null) ...[
              Shake(
                trigger: ok ? 0 : _pulse,
                child: GlowPop(
                  trigger: ok ? _pulse : 0,
                  child: FeedbackBanner(
                    key: Key(ok ? 'smart-result-correct' : 'smart-result-wrong'),
                    kind: ok ? FeedbackKind.correct : FeedbackKind.wrong,
                    title: ok ? l.gameCorrect : l.fbWrongTitle,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            for (var i = 0; i < s.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _OptionButton(
                  key: Key('smart-option-$i'),
                  letter: _letters[i % _letters.length],
                  label: playOptionLabel(context, s.options[i]),
                  state: choice == null
                      ? _OptState.idle
                      : s.options[i].correct
                      ? _OptState.best
                      : (choice == i ? _OptState.wrongPick : _OptState.other),
                  picked: choice == i,
                  onTap: choice == null ? () => _choose(i) : null,
                ),
              ),
            if (choice != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                key: const Key('smart-explanation'),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FeedbackColors.info.withValues(alpha: .4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: FeedbackColors.info,
                      child: Icon(Icons.sports_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.spCoachSays,
                            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            explanation(context, s.explanationKey),
                            style: t.bodyMedium?.copyWith(color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                key: const Key('smart-next'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: _next,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(l.spNext),
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
                    child: ConstrainedBox(constraints: const BoxConstraints(maxHeight: 270), child: pitch),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  panel,
                ],
              );
      },
    );
  }
}

enum _OptState { idle, best, wrongPick, other }

/// An answer button. After answering, the best option is always marked
/// (green + check + "Best choice"), and a wrong pick is marked (red + cross +
/// "Your choice") — never colour alone.
class _OptionButton extends StatelessWidget {
  const _OptionButton({
    super.key,
    required this.letter,
    required this.label,
    required this.state,
    required this.picked,
    required this.onTap,
  });

  final String letter;
  final String label;
  final _OptState state;
  final bool picked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (Color bg, Color border, IconData? icon, String? tag) = switch (state) {
      _OptState.idle => (const Color(0xFFF1F5F9), const Color(0xFFCBD5E1), null, null),
      _OptState.best => (const Color(0xFFDCFCE7), FeedbackColors.good, Icons.check_circle_rounded, l.spBestChoice),
      _OptState.wrongPick => (const Color(0xFFFEE2E2), FeedbackColors.bad, Icons.cancel_rounded, l.spYourChoice),
      _OptState.other => (const Color(0xFFF8FAFC), const Color(0xFFE2E8F0), null, null),
    };
    final fg = state == _OptState.other ? Colors.black45 : Colors.black87;
    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: picked,
      label: tag == null ? label : '$label, $tag',
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: state == _OptState.idle || state == _OptState.other ? 1 : 3),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: state == _OptState.idle ? FeedbackColors.info : border,
                    child: Text(
                      letter,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(fontWeight: FontWeight.w700, color: fg),
                        ),
                        if (tag != null)
                          Text(
                            tag,
                            key: Key(state == _OptState.best ? 'smart-best-tag' : 'smart-your-tag'),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: border),
                          ),
                      ],
                    ),
                  ),
                  if (icon != null) Icon(icon, color: border, size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pitch seen from our half (their goal at the top), with an arrow per
/// option (lettered). After answering only the best move (green) and a wrong
/// pick (red, dashed) remain.
class _PitchPainter extends CustomPainter {
  _PitchPainter(this.s, this.choice);

  final StrategyScenario s;
  final int? choice;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12));
    canvas.drawRRect(r, Paint()..color = const Color(0xFF2E7D32));
    // Mowing stripes for a friendlier pitch.
    final stripe = Paint()..color = const Color(0xFF388E3C);
    for (var i = 0; i < 8; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(6, 6 + i * (size.height - 12) / 8, size.width - 12, (size.height - 12) / 8),
        stripe,
      );
    }
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
    Offset at(FieldPlayer p) => Offset(p.x * size.width, p.y * size.height);
    final me = s.players.firstWhere((p) => p.hasBall, orElse: () => s.players.first);
    final from = at(me);

    // Option arrows (labels are drawn last, on top of the players).
    final labels = <(Offset, String, Color)>[];
    final seenTargets = <String, int>{};
    for (var i = 0; i < s.options.length; i++) {
      final o = s.options[i];
      final answered = choice != null;
      if (answered && !o.correct && i != choice) continue;
      final color = !answered ? Colors.white : (o.correct ? const Color(0xFF4ADE80) : const Color(0xFFF87171));
      final dashed = answered && !o.correct;
      Offset? to;
      switch (o.action) {
        case PlayAction.passTo || PlayAction.passBack:
          final target = s.players.where((p) => p.id == o.target).firstOrNull;
          if (target != null) to = at(target);
        case PlayAction.shoot:
          to = Offset(size.width / 2, 8);
        case PlayAction.dribble:
          to = from + Offset(0, -size.height * .16);
        case PlayAction.hold:
          to = null;
      }
      if (to == null) {
        canvas.drawCircle(
          from,
          radius + 12,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        labels.add((from + Offset(radius + 14, -radius - 14), _letters[i % _letters.length], color));
        continue;
      }
      _arrow(canvas, from, to, color, radius, dashed: dashed, width: answered ? 5 : 3);
      // Two options to the same player (pass / pass back): spread their labels.
      final dup = seenTargets.update('${to.dx.round()},${to.dy.round()}', (v) => v + 1, ifAbsent: () => 0);
      labels.add((Offset.lerp(from, to, dup == 0 ? .45 : .7)!, _letters[i % _letters.length], color));
    }

    for (final p in s.players) {
      final o = at(p);
      final us = p.team == Team.us;
      canvas.drawCircle(o + const Offset(0, 2), radius, Paint()..color = Colors.black26);
      if (us) {
        canvas.drawCircle(o, radius, Paint()..color = const Color(0xFF1E88E5));
      } else {
        // Opponents: red squares (shape differs, not only colour).
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCircle(center: o, radius: radius * .95), Radius.circular(radius * .3)),
          Paint()..color = const Color(0xFFE53935),
        );
      }
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
      final label = p.id == 'me' ? '●' : (us ? p.id : '×');
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: Colors.white, fontSize: radius, fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }
    for (final (at, text, color) in labels) {
      _label(canvas, at, text, color, radius);
    }
  }

  void _arrow(Canvas canvas, Offset a, Offset b, Color color, double radius, {bool dashed = false, double width = 3}) {
    final d = b - a;
    final len = d.distance;
    if (len < 1) return;
    final u = d / len;
    final start = a + u * (radius + 6);
    final end = b - u * (radius + 4);
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    if (dashed) {
      final total = (end - start).distance;
      for (double t = 0; t < total; t += 12) {
        canvas.drawLine(start + u * t, start + u * (t + 7).clamp(0, total), paint);
      }
    } else {
      canvas.drawLine(start, end, paint);
    }
    final n = Offset(-u.dy, u.dx);
    final head = Path()
      ..moveTo(end.dx + u.dx * 4, end.dy + u.dy * 4)
      ..lineTo(end.dx - u.dx * 10 + n.dx * 7, end.dy - u.dy * 10 + n.dy * 7)
      ..lineTo(end.dx - u.dx * 10 - n.dx * 7, end.dy - u.dy * 10 - n.dy * 7)
      ..close();
    canvas.drawPath(head, Paint()..color = color);
  }

  void _label(Canvas canvas, Offset at, String text, Color color, double radius) {
    canvas.drawCircle(at, radius * .75, Paint()..color = Colors.black54);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: radius * .9, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_PitchPainter old) => old.s.id != s.id || old.choice != choice;
}
