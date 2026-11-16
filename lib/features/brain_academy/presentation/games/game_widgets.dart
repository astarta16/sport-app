import 'package:flutter/material.dart';

import '../../domain/engines.dart';

/// Colour + icon pairs used by Logic Quest and Quick Mind. Every colour also
/// has a distinct shape, so the games work without colour vision.
const gamePalette = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFDD835),
  Color(0xFF8E24AA),
  Color(0xFFFB8C00),
];

IconData shapeIcon(int shape) => switch (shape % 4) {
  0 => Icons.circle,
  1 => Icons.square_rounded,
  2 => Icons.change_history_rounded,
  _ => Icons.star_rounded,
};

IconData logicShapeIcon(LogicShape s) => shapeIcon(s.index);

String shapeSemantic(int shape) => const ['circle', 'square', 'triangle', 'star'][shape % 4];
String colorSemantic(int color) => const ['red', 'blue', 'green', 'yellow', 'purple', 'orange'][color % 6];

/// A shape token (with a count) drawn from icons.
class TokenView extends StatelessWidget {
  const TokenView({super.key, required this.shape, required this.color, this.count = 1, this.size = 28});

  final int shape;
  final int color;
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$count ${colorSemantic(color)} ${shapeSemantic(shape)}',
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 1,
      runSpacing: 1,
      children: [
        for (var i = 0; i < count; i++)
          Icon(shapeIcon(shape), color: gamePalette[color % gamePalette.length], size: count > 3 ? size * .6 : size),
      ],
    ),
  );
}

/// Large, child-friendly tap target.
class BigTile extends StatelessWidget {
  const BigTile({super.key, required this.child, required this.onTap, this.color, this.semanticLabel, this.border});

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final String? semanticLabel;
  final Color? border;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    child: Material(
      color: color ?? Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border ?? Theme.of(context).colorScheme.outline, width: border == null ? 1 : 3),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
          child: Center(child: child),
        ),
      ),
    ),
  );
}
