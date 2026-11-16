import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/engines.dart';
import '../brain_game_screen.dart';
import '../game_feedback.dart';

class PathFinderGame extends StatefulWidget {
  const PathFinderGame({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<PathFinderGame> createState() => _PathFinderGameState();
}

class _PathFinderGameState extends State<PathFinderGame> {
  late final engine = MazeEngine(difficulty: widget.ctx.difficulty, level: widget.ctx.level, seed: widget.ctx.seed);
  final _focus = FocusNode();
  int _bumpPulse = 0;
  bool _bumped = false;
  bool _done = false;
  Timer? _clear;
  Timer? _finish;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
  }

  @override
  void dispose() {
    _focus.dispose();
    _clear?.cancel();
    _finish?.cancel();
    super.dispose();
  }

  void _report() {
    final left = (engine.shortestPath(engine.player, engine.goal)?.length ?? 1) - 1;
    widget.ctx.report(
      GameStats(
        score: max(0, engine.optimal * 30 - engine.bumps * 2),
        done: (engine.optimal - left).clamp(0, engine.optimal),
        total: engine.optimal,
      ),
    );
  }

  void _move(MazeDir d) {
    if (_done) return;
    final ok = engine.move(d);
    if (!ok) {
      widget.ctx.fx.wrong();
      _clear?.cancel();
      setState(() {
        _bumped = true;
        _bumpPulse++;
      });
      _clear = Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _bumped = false);
      });
      return;
    }
    widget.ctx.fx.tap();
    setState(() => _bumped = false);
    _report();
    if (engine.isComplete) {
      widget.ctx.fx.correct();
      setState(() => _done = true);
      _finish = Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        widget.ctx.onFinished(
          GameOutcome(
            won: true,
            score: engine.score(widget.ctx.elapsed()),
            accuracy: engine.accuracy,
            attempts: engine.moves,
            detail: {'optimal': engine.optimal, 'bumps': engine.bumps},
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final reduce = reduceMotion(context);
    Widget arrow(MazeDir d, IconData icon, String label) => Padding(
      padding: const EdgeInsets.all(4),
      child: IconButton.filled(
        key: Key('maze-${d.name}'),
        tooltip: label,
        iconSize: 32,
        style: IconButton.styleFrom(minimumSize: const Size(60, 60)),
        onPressed: _done ? null : () => _move(d),
        icon: Icon(icon),
      ),
    );
    final pad = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        arrow(MazeDir.up, Icons.keyboard_arrow_up_rounded, l.mazeUp),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            arrow(MazeDir.left, Icons.keyboard_arrow_left_rounded, l.mazeLeft),
            const SizedBox(width: 60),
            arrow(MazeDir.right, Icons.keyboard_arrow_right_rounded, l.mazeRight),
          ],
        ),
        arrow(MazeDir.down, Icons.keyboard_arrow_down_rounded, l.mazeDown),
      ],
    );
    final banner = _done
        ? FeedbackBanner(key: const Key('maze-finished'), kind: FeedbackKind.correct, title: l.gameComplete)
        : _bumped
        ? FeedbackBanner(key: const Key('maze-blocked'), kind: FeedbackKind.wrong, title: l.mazeBlocked)
        : FeedbackBanner(key: const Key('maze-objective'), kind: FeedbackKind.info, title: l.objPath);
    return KeyboardListener(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (e) {
        if (e is! KeyDownEvent) return;
        final d = switch (e.logicalKey) {
          LogicalKeyboardKey.arrowUp => MazeDir.up,
          LogicalKeyboardKey.arrowDown => MazeDir.down,
          LogicalKeyboardKey.arrowLeft => MazeDir.left,
          LogicalKeyboardKey.arrowRight => MazeDir.right,
          _ => null,
        };
        if (d != null) _move(d);
      },
      child: LayoutBuilder(
        builder: (context, c) {
          final landscape = c.maxWidth > c.maxHeight;
          Widget boardFor(double boardMax) {
            final cell = max(12.0, (boardMax / engine.size).floorToDouble());
            return GestureDetector(
              onPanEnd: (d) {
                final v = d.velocity.pixelsPerSecond;
                if (v.distance < 100) return;
                _move(
                  v.dx.abs() > v.dy.abs()
                      ? (v.dx > 0 ? MazeDir.right : MazeDir.left)
                      : (v.dy > 0 ? MazeDir.down : MazeDir.up),
                );
              },
              child: Shake(
                trigger: _bumpPulse,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: _bumped ? FeedbackColors.bad : const Color(0xFF1B5E20), width: 4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox(
                    key: const Key('maze-board'),
                    width: cell * engine.size,
                    height: cell * engine.size,
                    child: Stack(
                      children: [
                        for (var r = 0; r < engine.size; r++)
                          for (var col = 0; col < engine.size; col++)
                            Positioned(
                              left: col * cell,
                              top: r * cell,
                              width: cell,
                              height: cell,
                              child: _Cell(engine: engine, pos: MazePos(r, col), cell: cell, done: _done),
                            ),
                        AnimatedPositioned(
                          duration: Duration(milliseconds: reduce ? 0 : 140),
                          curve: Curves.easeOut,
                          left: engine.player.c * cell,
                          top: engine.player.r * cell,
                          width: cell,
                          height: cell,
                          child: GlowPop(
                            trigger: _done ? 1 : 0,
                            color: FeedbackColors.warn,
                            radius: cell,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: _bumped ? FeedbackColors.bad : AppColors.navy, width: 2),
                              ),
                              child: Icon(
                                Icons.sports_soccer_rounded,
                                key: const Key('maze-player'),
                                size: cell * .8,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          // The board takes whatever space is left after the controls.
          final board = LayoutBuilder(
            builder: (context, b) => Center(child: boardFor(min(b.maxWidth, b.maxHeight) - 8)),
          );
          final info = Text(l.gameMoves(engine.moves), key: const Key('maze-moves'));
          final legend = Wrap(
            spacing: AppSpacing.sm,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              _legend(const Icon(Icons.flag_rounded, color: FeedbackColors.info, size: 18), l.mazeStart),
              _legend(const Icon(Icons.sports_score_rounded, color: FeedbackColors.good, size: 18), l.mazeGoal),
              _legend(const _ConeIcon(size: 18), l.mazeBlocked),
            ],
          );
          final top = Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: KeyedSubtree(key: ValueKey('$_done-$_bumped-$_bumpPulse'), child: banner),
            ),
          );
          return Stack(
            children: [
              if (landscape)
                Row(
                  children: [
                    Expanded(child: board),
                    SizedBox(
                      width: 230,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [top, const SizedBox(height: 6), info, legend, pad],
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    const SizedBox(height: 6),
                    top,
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.center,
                      children: [info, legend],
                    ),
                    Expanded(child: board),
                    pad,
                  ],
                ),
              if (_done) const Positioned.fill(child: IgnorePointer(child: Confetti())),
            ],
          );
        },
      ),
    );
  }

  Widget _legend(Widget icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      icon,
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 12)),
    ],
  );
}

/// A traffic cone: orange triangle with white stripe and dark outline, so it
/// reads by shape, not only colour.
class _ConeIcon extends StatelessWidget {
  const _ConeIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _ConePainter());
}

class _ConePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final path = Path()
      ..moveTo(s.width / 2, s.height * .08)
      ..lineTo(s.width * .85, s.height * .85)
      ..lineTo(s.width * .15, s.height * .85)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFF97316));
    canvas.drawRect(
      Rect.fromLTWH(s.width * .32, s.height * .45, s.width * .36, s.height * .12),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(s.width * .08, s.height * .82, s.width * .84, s.height * .12),
      Paint()..color = const Color(0xFF7C2D12),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF7C2D12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1, s.width * .06),
    );
  }

  @override
  bool shouldRepaint(_ConePainter old) => false;
}

class _Cell extends StatelessWidget {
  const _Cell({required this.engine, required this.pos, required this.cell, required this.done});

  final MazeEngine engine;
  final MazePos pos;
  final double cell;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final wall = engine.walls[pos.r][pos.c];
    final cone = engine.obstacles.contains(pos);
    final goal = pos == engine.goal;
    final start = pos == engine.start;
    final checker = (pos.r + pos.c).isEven;
    return Container(
      decoration: BoxDecoration(
        color: wall
            ? const Color(0xFF14532D)
            : goal
            ? const Color(0xFFBBF7D0)
            : (checker ? const Color(0xFFD9F99D) : const Color(0xFFC8E6C9)),
        border: wall ? null : Border.all(color: Colors.black.withValues(alpha: .04)),
      ),
      child: cone
          ? Padding(
              padding: EdgeInsets.all(cell * .08),
              child: _ConeIcon(size: cell * .84),
            )
          : goal
          ? _GoalPulse(cell: cell, done: done)
          : start
          ? Icon(Icons.flag_rounded, key: const Key('maze-start'), size: cell * .6, color: FeedbackColors.info)
          : null,
    );
  }
}

class _GoalPulse extends StatefulWidget {
  const _GoalPulse({required this.cell, required this.done});

  final double cell;
  final bool done;

  @override
  State<_GoalPulse> createState() => _GoalPulseState();
}

class _GoalPulseState extends State<_GoalPulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    key: const Key('maze-goal'),
    scale: Tween(begin: .85, end: 1.1).animate(_c),
    child: Icon(Icons.sports_score_rounded, size: widget.cell * .85, color: const Color(0xFF15803D)),
  );
}
