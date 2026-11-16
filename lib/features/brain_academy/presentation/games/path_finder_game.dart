import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/engines.dart';
import '../brain_game_screen.dart';

class PathFinderGame extends StatefulWidget {
  const PathFinderGame({super.key, required this.ctx});

  final GameContext ctx;

  @override
  State<PathFinderGame> createState() => _PathFinderGameState();
}

class _PathFinderGameState extends State<PathFinderGame> {
  late final engine = MazeEngine(difficulty: widget.ctx.difficulty, level: widget.ctx.level, seed: widget.ctx.seed);
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _move(MazeDir d) {
    final ok = engine.move(d);
    if (!ok) widget.ctx.feedback(good: false);
    setState(() {});
    if (engine.isComplete) {
      widget.ctx.feedback(good: true);
      widget.ctx.onFinished(
        GameOutcome(
          won: true,
          score: engine.score(widget.ctx.elapsed()),
          accuracy: engine.accuracy,
          attempts: engine.moves,
          detail: {'optimal': engine.optimal, 'bumps': engine.bumps},
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final reduce = MediaQuery.of(context).disableAnimations;
    Widget arrow(MazeDir d, IconData icon, String label) => Padding(
      padding: const EdgeInsets.all(4),
      child: IconButton.filled(
        key: Key('maze-${d.name}'),
        tooltip: label,
        iconSize: 32,
        style: IconButton.styleFrom(minimumSize: const Size(60, 60)),
        onPressed: () => _move(d),
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
          final boardMax = landscape
              ? min(c.maxHeight - 24, c.maxWidth - 240)
              : min(c.maxWidth - 24, c.maxHeight - 260);
          final cell = (boardMax / engine.size).floorToDouble();
          final board = GestureDetector(
            onPanEnd: (d) {
              final v = d.velocity.pixelsPerSecond;
              if (v.distance < 100) return;
              _move(
                v.dx.abs() > v.dy.abs()
                    ? (v.dx > 0 ? MazeDir.right : MazeDir.left)
                    : (v.dy > 0 ? MazeDir.down : MazeDir.up),
              );
            },
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
                        child: _Cell(engine: engine, pos: MazePos(r, col), cell: cell),
                      ),
                  AnimatedPositioned(
                    duration: Duration(milliseconds: reduce ? 0 : 120),
                    left: engine.player.c * cell,
                    top: engine.player.r * cell,
                    width: cell,
                    height: cell,
                    child: Icon(
                      Icons.sports_soccer_rounded,
                      key: const Key('maze-player'),
                      size: cell * .85,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
          );
          final info = Text(l.gameMoves(engine.moves), key: const Key('maze-moves'));
          return Center(
            child: landscape
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      board,
                      const SizedBox(width: 16),
                      Column(mainAxisSize: MainAxisSize.min, children: [info, pad]),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [info, const SizedBox(height: 8), board, const SizedBox(height: 8), pad],
                  ),
          );
        },
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.engine, required this.pos, required this.cell});

  final MazeEngine engine;
  final MazePos pos;
  final double cell;

  @override
  Widget build(BuildContext context) {
    final wall = engine.walls[pos.r][pos.c];
    final cone = engine.obstacles.contains(pos);
    final goal = pos == engine.goal;
    return Container(
      color: wall ? const Color(0xFF1B5E20) : const Color(0xFFC8E6C9),
      child: cone
          ? Icon(Icons.warning_amber_rounded, size: cell * .8, color: Colors.deepOrange)
          : (goal ? Icon(Icons.sports_score_rounded, size: cell * .85, color: AppColors.navy) : null),
    );
  }
}
