// Pure, deterministic (seeded) rules for the six Brain Academy games. The
// widgets only render these and forward taps, so every rule is unit-tested.
import 'dart:math';

import 'brain_models.dart';

int _clampScore(num v) => v.isNaN ? 0 : v.round().clamp(0, 100000);

// ─── 1. Memory Match ───────────────────────────────────────────────────────

enum FlipOutcome { ignored, first, match, mismatch }

class MemoryEngine {
  MemoryEngine({required this.difficulty, required this.level, required int seed}) {
    final pairs = pairsFor(difficulty, level);
    final symbols = List.generate(symbolCount, (i) => i)..shuffle(Random(seed));
    cards = [
      for (final s in symbols.take(pairs)) ...[s, s],
    ]..shuffle(Random(seed + 1));
  }

  static const symbolCount = 12;

  /// Pairs grow with difficulty and slowly with the level (capped).
  static int pairsFor(GameDifficulty d, int level) {
    final base = switch (d) {
      GameDifficulty.easy => 4,
      GameDifficulty.medium => 6,
      GameDifficulty.hard => 8,
    };
    return min(base + (level - 1) ~/ 3, symbolCount);
  }

  final GameDifficulty difficulty;
  final int level;
  late final List<int> cards;
  final matched = <int>{};
  final faceUp = <int>[];
  int attempts = 0;

  int get pairs => cards.length ~/ 2;
  bool get isComplete => matched.length == cards.length;
  bool get waitingToHide => faceUp.length == 2;

  /// Flip card [i]. A mismatch leaves both cards up until [hideMismatch].
  FlipOutcome flip(int i) {
    if (i < 0 || i >= cards.length || matched.contains(i) || faceUp.contains(i) || waitingToHide) {
      return FlipOutcome.ignored;
    }
    faceUp.add(i);
    if (faceUp.length == 1) return FlipOutcome.first;
    attempts++;
    if (cards[faceUp[0]] == cards[faceUp[1]]) {
      matched.addAll(faceUp);
      faceUp.clear();
      return FlipOutcome.match;
    }
    return FlipOutcome.mismatch;
  }

  void hideMismatch() => faceUp.clear();

  /// Perfect play = one attempt per pair.
  double get accuracy => attempts == 0 ? 0 : (pairs / attempts).clamp(0, 1).toDouble();

  int score(Duration elapsed) => _clampScore(
    (pairs * 100 - (attempts - pairs) * 20 - elapsed.inSeconds * 2).clamp(pairs * 10, 100000) * difficulty.multiplier,
  );
}

// ─── 2. Logic Quest ────────────────────────────────────────────────────────

enum LogicShape { circle, square, triangle, star }

enum LogicColor { red, blue, green, yellow }

class LogicToken {
  const LogicToken(this.shape, this.color, [this.count = 1]);

  final LogicShape shape;
  final LogicColor color;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is LogicToken && other.shape == shape && other.color == color && other.count == count;

  @override
  int get hashCode => Object.hash(shape, color, count);
}

enum LogicKind { repeat, grow, missing }

class LogicPuzzle {
  const LogicPuzzle({
    required this.kind,
    required this.sequence,
    required this.missingIndex,
    required this.options,
    required this.answer,
  });

  final LogicKind kind;

  /// Full sequence; [missingIndex] is shown as "?".
  final List<LogicToken> sequence;
  final int missingIndex;
  final List<LogicToken> options;
  final int answer;
}

class LogicEngine {
  LogicEngine({required this.difficulty, required this.level, required int seed}) : _rng = Random(seed) {
    puzzles = [for (var i = 0; i < puzzleCount; i++) _make(i)];
  }

  static const puzzleCount = 8;

  final GameDifficulty difficulty;
  final int level;
  final Random _rng;
  late final List<LogicPuzzle> puzzles;
  int index = 0;
  int correct = 0;
  final answers = <bool>[];

  LogicPuzzle get current => puzzles[index];
  bool get isComplete => answers.length == puzzles.length;
  double get accuracy => answers.isEmpty ? 0 : correct / answers.length;

  LogicToken _token() => LogicToken(
    LogicShape.values[_rng.nextInt(LogicShape.values.length)],
    LogicColor.values[_rng.nextInt(LogicColor.values.length)],
  );

  int get _period => switch (difficulty) {
    GameDifficulty.easy => 2,
    GameDifficulty.medium => 3,
    GameDifficulty.hard => 3 + (level > 3 ? 1 : 0),
  };

  LogicPuzzle _make(int i) {
    final kinds = difficulty == GameDifficulty.easy ? const [LogicKind.repeat, LogicKind.grow] : LogicKind.values;
    final kind = kinds[i % kinds.length];
    late List<LogicToken> seq;
    late int missing;
    switch (kind) {
      case LogicKind.repeat:
        final unit = <LogicToken>[];
        while (unit.length < _period) {
          final t = _token();
          if (!unit.contains(t)) unit.add(t);
        }
        seq = [for (var k = 0; k < _period * 2 + 1; k++) unit[k % _period]];
        missing = seq.length - 1;
      case LogicKind.grow:
        final t = _token();
        final step = difficulty == GameDifficulty.hard ? 2 : 1;
        seq = [for (var k = 0; k < 5; k++) LogicToken(t.shape, t.color, 1 + k * step)];
        missing = seq.length - 1;
      case LogicKind.missing:
        final unit = <LogicToken>[];
        while (unit.length < _period) {
          final t = _token();
          if (!unit.contains(t)) unit.add(t);
        }
        seq = [for (var k = 0; k < _period * 2 + 1; k++) unit[k % _period]];
        missing = 1 + _rng.nextInt(seq.length - 2);
    }
    final answer = seq[missing];
    final opts = <LogicToken>{answer};
    var guard = 0;
    while (opts.length < 4 && guard++ < 200) {
      final d = _rng.nextInt(3);
      opts.add(switch (d) {
        0 => LogicToken(LogicShape.values[_rng.nextInt(4)], answer.color, answer.count),
        1 => LogicToken(answer.shape, LogicColor.values[_rng.nextInt(4)], answer.count),
        _ => LogicToken(answer.shape, answer.color, max(1, answer.count + (_rng.nextBool() ? 1 : -1))),
      });
    }
    final list = opts.toList()..shuffle(_rng);
    return LogicPuzzle(kind: kind, sequence: seq, missingIndex: missing, options: list, answer: list.indexOf(answer));
  }

  /// Returns whether [option] is right and moves to the next puzzle.
  bool answer(int option) {
    if (isComplete) return false;
    final ok = option == current.answer;
    if (ok) correct++;
    answers.add(ok);
    if (index < puzzles.length - 1) index++;
    return ok;
  }

  int score(Duration elapsed) => _clampScore(
    (correct * 100 + max(0, 120 - elapsed.inSeconds) * (correct == puzzles.length ? 1 : 0)) * difficulty.multiplier,
  );
}

// ─── 3. Smart Play (sports strategy) ───────────────────────────────────────

enum StrategySport { football }

enum Team { us, them }

class FieldPlayer {
  const FieldPlayer(this.id, this.team, this.x, this.y, {this.hasBall = false});

  final String id;
  final Team team;

  /// 0..1 across the pitch (x: left→right, y: own goal (1) → their goal (0)).
  final double x;
  final double y;
  final bool hasBall;
}

enum PlayAction { passTo, dribble, shoot, passBack, hold }

class PlayOption {
  const PlayOption(this.action, {this.target, this.correct = false});

  final PlayAction action;
  final String? target;
  final bool correct;
}

class StrategyScenario {
  const StrategyScenario({
    required this.id,
    required this.sport,
    required this.difficulty,
    required this.players,
    required this.options,
    required this.explanationKey,
  });

  final String id;
  final StrategySport sport;
  final GameDifficulty difficulty;
  final List<FieldPlayer> players;
  final List<PlayOption> options;

  /// l10n key of the explanation shown after answering.
  final String explanationKey;

  int get correctIndex => options.indexWhere((o) => o.correct);
}

/// Scenario library per sport; add a sport by adding its list here.
abstract final class StrategyLibrary {
  static const Map<StrategySport, List<StrategyScenario>> scenarios = {StrategySport.football: _football};

  static List<StrategyScenario> forGame(StrategySport sport, GameDifficulty d) =>
      (scenarios[sport] ?? const []).where((s) => s.difficulty.index <= d.index).toList();

  static const _football = [
    StrategyScenario(
      id: 'fb-1',
      sport: StrategySport.football,
      difficulty: GameDifficulty.easy,
      players: [
        FieldPlayer('me', Team.us, .5, .55, hasBall: true),
        FieldPlayer('7', Team.us, .8, .35),
        FieldPlayer('9', Team.us, .45, .2),
        FieldPlayer('d1', Team.them, .5, .4),
        FieldPlayer('d2', Team.them, .4, .25),
      ],
      options: [
        PlayOption(PlayAction.passTo, target: '7', correct: true),
        PlayOption(PlayAction.passTo, target: '9'),
        PlayOption(PlayAction.dribble),
      ],
      explanationKey: 'spExplain1',
    ),
    StrategyScenario(
      id: 'fb-2',
      sport: StrategySport.football,
      difficulty: GameDifficulty.easy,
      players: [
        FieldPlayer('me', Team.us, .5, .2, hasBall: true),
        FieldPlayer('gk', Team.them, .5, .03),
        FieldPlayer('7', Team.us, .85, .3),
        FieldPlayer('d1', Team.them, .8, .25),
      ],
      options: [
        PlayOption(PlayAction.shoot, correct: true),
        PlayOption(PlayAction.passTo, target: '7'),
        PlayOption(PlayAction.passBack, target: '7'),
      ],
      explanationKey: 'spExplain2',
    ),
    StrategyScenario(
      id: 'fb-3',
      sport: StrategySport.football,
      difficulty: GameDifficulty.easy,
      players: [
        FieldPlayer('me', Team.us, .3, .7, hasBall: true),
        FieldPlayer('d1', Team.them, .3, .62),
        FieldPlayer('d2', Team.them, .4, .66),
        FieldPlayer('4', Team.us, .3, .88),
        FieldPlayer('8', Team.us, .75, .6),
      ],
      options: [
        PlayOption(PlayAction.dribble),
        PlayOption(PlayAction.passBack, target: '4', correct: true),
        PlayOption(PlayAction.shoot),
      ],
      explanationKey: 'spExplain3',
    ),
    StrategyScenario(
      id: 'fb-4',
      sport: StrategySport.football,
      difficulty: GameDifficulty.medium,
      players: [
        FieldPlayer('me', Team.us, .5, .5, hasBall: true),
        FieldPlayer('10', Team.us, .5, .3),
        FieldPlayer('11', Team.us, .15, .35),
        FieldPlayer('d1', Team.them, .5, .38),
        FieldPlayer('d2', Team.them, .55, .25),
      ],
      options: [
        PlayOption(PlayAction.passTo, target: '10'),
        PlayOption(PlayAction.passTo, target: '11', correct: true),
        PlayOption(PlayAction.hold),
      ],
      explanationKey: 'spExplain4',
    ),
    StrategyScenario(
      id: 'fb-5',
      sport: StrategySport.football,
      difficulty: GameDifficulty.medium,
      players: [
        FieldPlayer('me', Team.us, .85, .4, hasBall: true),
        FieldPlayer('9', Team.us, .5, .15),
        FieldPlayer('d1', Team.them, .55, .2),
        FieldPlayer('10', Team.us, .45, .3),
        FieldPlayer('d2', Team.them, .8, .32),
      ],
      options: [
        PlayOption(PlayAction.passTo, target: '9'),
        PlayOption(PlayAction.passTo, target: '10', correct: true),
        PlayOption(PlayAction.shoot),
      ],
      explanationKey: 'spExplain5',
    ),
    StrategyScenario(
      id: 'fb-6',
      sport: StrategySport.football,
      difficulty: GameDifficulty.medium,
      players: [
        FieldPlayer('me', Team.us, .5, .85, hasBall: true),
        FieldPlayer('d1', Team.them, .5, .75),
        FieldPlayer('5', Team.us, .15, .8),
        FieldPlayer('6', Team.us, .85, .8),
        FieldPlayer('d2', Team.them, .2, .72),
      ],
      options: [
        PlayOption(PlayAction.dribble),
        PlayOption(PlayAction.passTo, target: '5'),
        PlayOption(PlayAction.passTo, target: '6', correct: true),
      ],
      explanationKey: 'spExplain6',
    ),
    StrategyScenario(
      id: 'fb-7',
      sport: StrategySport.football,
      difficulty: GameDifficulty.hard,
      players: [
        FieldPlayer('me', Team.us, .5, .45, hasBall: true),
        FieldPlayer('9', Team.us, .5, .2),
        FieldPlayer('7', Team.us, .85, .25),
        FieldPlayer('d1', Team.them, .45, .22),
        FieldPlayer('d2', Team.them, .55, .22),
        FieldPlayer('d3', Team.them, .6, .4),
      ],
      options: [
        PlayOption(PlayAction.passTo, target: '9'),
        PlayOption(PlayAction.passTo, target: '7', correct: true),
        PlayOption(PlayAction.dribble),
      ],
      explanationKey: 'spExplain7',
    ),
    StrategyScenario(
      id: 'fb-8',
      sport: StrategySport.football,
      difficulty: GameDifficulty.hard,
      players: [
        FieldPlayer('me', Team.us, .2, .25, hasBall: true),
        FieldPlayer('d1', Team.them, .25, .18),
        FieldPlayer('9', Team.us, .5, .12),
        FieldPlayer('d2', Team.them, .5, .2),
        FieldPlayer('10', Team.us, .55, .32),
      ],
      options: [
        PlayOption(PlayAction.passTo, target: '9'),
        PlayOption(PlayAction.shoot),
        PlayOption(PlayAction.passTo, target: '10', correct: true),
      ],
      explanationKey: 'spExplain8',
    ),
    StrategyScenario(
      id: 'fb-9',
      sport: StrategySport.football,
      difficulty: GameDifficulty.hard,
      players: [
        FieldPlayer('me', Team.us, .5, .6, hasBall: true),
        FieldPlayer('d1', Team.them, .5, .5),
        FieldPlayer('d2', Team.them, .4, .55),
        FieldPlayer('d3', Team.them, .6, .55),
        FieldPlayer('2', Team.us, .9, .55),
        FieldPlayer('3', Team.us, .1, .7),
      ],
      options: [
        PlayOption(PlayAction.passTo, target: '2', correct: true),
        PlayOption(PlayAction.dribble),
        PlayOption(PlayAction.hold),
      ],
      explanationKey: 'spExplain9',
    ),
  ];
}

class SmartPlayEngine {
  SmartPlayEngine({
    required this.difficulty,
    required this.level,
    required int seed,
    this.sport = StrategySport.football,
  }) {
    final pool = StrategyLibrary.forGame(sport, difficulty)..shuffle(Random(seed));
    // Harder scenarios first get more weight on higher difficulties.
    pool.sort((a, b) => b.difficulty.index.compareTo(a.difficulty.index));
    scenarios = pool.take(min(pool.length, 3 + difficulty.index * 2)).toList()..shuffle(Random(seed + level));
  }

  final StrategySport sport;
  final GameDifficulty difficulty;
  final int level;
  late final List<StrategyScenario> scenarios;
  int index = 0;
  int correct = 0;
  int? lastChoice;

  StrategyScenario get current => scenarios[index];
  bool get answered => lastChoice != null;
  bool get isLast => index == scenarios.length - 1;
  bool isComplete = false;
  double get accuracy => (index + (answered ? 1 : 0)) == 0 ? 0 : correct / (index + (answered ? 1 : 0));

  bool choose(int option) {
    if (answered || isComplete) return false;
    lastChoice = option;
    final ok = current.options[option].correct;
    if (ok) correct++;
    return ok;
  }

  /// Next scenario after the explanation; completes after the last one.
  void next() {
    if (!answered) return;
    if (isLast) {
      isComplete = true;
      return;
    }
    index++;
    lastChoice = null;
  }

  int score() => _clampScore(correct * 150 * difficulty.multiplier);
}

// ─── 4. Quick Mind ─────────────────────────────────────────────────────────

class QuickItem {
  const QuickItem(this.symbol, this.color);

  final int symbol;
  final int color;

  @override
  bool operator ==(Object other) => other is QuickItem && other.symbol == symbol && other.color == color;

  @override
  int get hashCode => Object.hash(symbol, color);
}

class QuickRound {
  const QuickRound(this.target, this.items, this.limitMs);

  final QuickItem target;
  final List<QuickItem> items;
  final int limitMs;
}

class QuickMindEngine {
  QuickMindEngine({required this.difficulty, required this.level, required int seed}) : _rng = Random(seed);

  static const symbols = 4;
  static const colors = 4;
  static const rounds = 12;

  final GameDifficulty difficulty;
  final int level;
  final Random _rng;
  int played = 0;
  int correct = 0;
  final reactions = <int>[];

  int get gridSize => switch (difficulty) {
    GameDifficulty.easy => 4,
    GameDifficulty.medium => 6,
    GameDifficulty.hard => 9,
  };

  /// Time per round shrinks with difficulty, level and correct streaks.
  int get limitMs {
    final base = switch (difficulty) {
      GameDifficulty.easy => 3500,
      GameDifficulty.medium => 2600,
      GameDifficulty.hard => 2000,
    };
    return max(900, base - (level - 1) * 120 - correct * 40);
  }

  bool get isComplete => played >= rounds;
  double get accuracy => played == 0 ? 0 : correct / played;
  int get avgReactionMs => reactions.isEmpty ? 0 : reactions.reduce((a, b) => a + b) ~/ reactions.length;

  /// Exactly one item matches the target; on hard, decoys share the shape
  /// or the colour.
  QuickRound nextRound() {
    final target = QuickItem(_rng.nextInt(symbols), _rng.nextInt(colors));
    final items = <QuickItem>[target];
    var guard = 0;
    while (items.length < gridSize && guard++ < 500) {
      final c = difficulty == GameDifficulty.hard && _rng.nextBool()
          ? (_rng.nextBool()
                ? QuickItem(target.symbol, _rng.nextInt(colors))
                : QuickItem(_rng.nextInt(symbols), target.color))
          : QuickItem(_rng.nextInt(symbols), _rng.nextInt(colors));
      if (c != target) items.add(c);
    }
    items.shuffle(_rng);
    return QuickRound(target, items, limitMs);
  }

  /// Tap within the time limit; returns whether it was the target.
  bool tap(QuickRound r, int index, int elapsedMs) {
    played++;
    final ok = elapsedMs <= r.limitMs && r.items[index] == r.target;
    if (ok) {
      correct++;
      reactions.add(elapsedMs);
    }
    return ok;
  }

  void timeout() => played++;

  int score() => _clampScore(
    (correct * 100 + reactions.fold<int>(0, (a, ms) => a + max(0, (2000 - ms) ~/ 20))) * difficulty.multiplier,
  );
}

// ─── 5. Sequence Master ────────────────────────────────────────────────────

enum SequenceInput { correct, wrong, roundComplete }

class SequenceEngine {
  SequenceEngine({required this.difficulty, required this.level, required int seed}) : _rng = Random(seed) {
    lives = difficulty == GameDifficulty.easy ? 2 : 1;
    sequence = [for (var i = 0; i < startLength; i++) _rng.nextInt(palette)];
  }

  final GameDifficulty difficulty;
  final int level;
  final Random _rng;
  late List<int> sequence;
  int position = 0;
  int completedRounds = 0;
  int longest = 0;
  int mistakes = 0;
  late int lives;

  int get palette => difficulty == GameDifficulty.easy ? 4 : 6;
  int get startLength =>
      (switch (difficulty) {
        GameDifficulty.easy => 3,
        GameDifficulty.medium => 4,
        GameDifficulty.hard => 5,
      }) +
      (level - 1) ~/ 3;

  /// Rounds needed to complete the level.
  int get target => 5;
  bool get isOver => lives <= 0 || completedRounds >= target;
  bool get won => completedRounds >= target;

  SequenceInput input(int symbol) {
    if (isOver) return SequenceInput.wrong;
    if (symbol != sequence[position]) {
      mistakes++;
      lives--;
      position = 0;
      return SequenceInput.wrong;
    }
    position++;
    if (position < sequence.length) return SequenceInput.correct;
    completedRounds++;
    longest = max(longest, sequence.length);
    position = 0;
    sequence = [...sequence, _rng.nextInt(palette)];
    return SequenceInput.roundComplete;
  }

  double get accuracy {
    final total = completedRounds + mistakes;
    return total == 0 ? 0 : completedRounds / total;
  }

  int score() => _clampScore(completedRounds * longest * 10 * difficulty.multiplier);
}

// ─── 6. Path Finder ────────────────────────────────────────────────────────

enum MazeDir { up, down, left, right }

class MazePos {
  const MazePos(this.r, this.c);

  final int r;
  final int c;

  MazePos step(MazeDir d) => switch (d) {
    MazeDir.up => MazePos(r - 1, c),
    MazeDir.down => MazePos(r + 1, c),
    MazeDir.left => MazePos(r, c - 1),
    MazeDir.right => MazePos(r, c + 1),
  };

  @override
  bool operator ==(Object other) => other is MazePos && other.r == r && other.c == c;

  @override
  int get hashCode => Object.hash(r, c);
}

/// Perfect maze (randomised depth-first carve) on an odd grid; walls are
/// `true`. Obstacles (cones) block some open cells that are NOT on the
/// shortest path, so the goal always stays reachable.
class MazeEngine {
  MazeEngine({required this.difficulty, required this.level, required int seed}) : _rng = Random(seed) {
    size =
        switch (difficulty) {
          GameDifficulty.easy => 7,
          GameDifficulty.medium => 9,
          GameDifficulty.hard => 11,
        } +
        ((level - 1) ~/ 3) * 2;
    walls = List.generate(size, (_) => List.filled(size, true));
    _carve(const MazePos(1, 1));
    start = const MazePos(1, 1);
    goal = MazePos(size - 2, size - 2);
    final path = shortestPath(start, goal)!;
    final onPath = path.toSet();
    final open = [
      for (var r = 1; r < size - 1; r++)
        for (var c = 1; c < size - 1; c++)
          if (!walls[r][c] && !onPath.contains(MazePos(r, c))) MazePos(r, c),
    ]..shuffle(_rng);
    final count = switch (difficulty) {
      GameDifficulty.easy => 1,
      GameDifficulty.medium => 3,
      GameDifficulty.hard => 5,
    };
    obstacles = open.take(min(count, open.length)).toSet();
    optimal = path.length - 1;
    player = start;
  }

  final GameDifficulty difficulty;
  final int level;
  final Random _rng;
  late final int size;
  late final List<List<bool>> walls;
  late final MazePos start;
  late final MazePos goal;

  /// Empty while the maze is carved and the clear path computed.
  Set<MazePos> obstacles = {};
  late final int optimal;
  late MazePos player;
  int moves = 0;
  int bumps = 0;

  void _carve(MazePos p) {
    walls[p.r][p.c] = false;
    final dirs = MazeDir.values.toList()..shuffle(_rng);
    for (final d in dirs) {
      final mid = p.step(d);
      final next = mid.step(d);
      if (next.r > 0 && next.r < size - 1 && next.c > 0 && next.c < size - 1 && walls[next.r][next.c]) {
        walls[mid.r][mid.c] = false;
        _carve(next);
      }
    }
  }

  bool blocked(MazePos p) =>
      p.r < 0 || p.c < 0 || p.r >= size || p.c >= size || walls[p.r][p.c] || obstacles.contains(p);

  /// BFS over open, unobstructed cells.
  List<MazePos>? shortestPath(MazePos from, MazePos to) {
    final prev = <MazePos, MazePos>{};
    final queue = [from];
    final seen = {from};
    while (queue.isNotEmpty) {
      final p = queue.removeAt(0);
      if (p == to) {
        final out = [p];
        var cur = p;
        while (prev.containsKey(cur)) {
          cur = prev[cur]!;
          out.insert(0, cur);
        }
        return out;
      }
      for (final d in MazeDir.values) {
        final n = p.step(d);
        if (!blocked(n) && seen.add(n)) {
          prev[n] = p;
          queue.add(n);
        }
      }
    }
    return null;
  }

  bool get isComplete => player == goal;

  /// Moves one cell; walls and obstacles stop the move (counted as a bump).
  bool move(MazeDir d) {
    if (isComplete) return false;
    final n = player.step(d);
    if (blocked(n)) {
      bumps++;
      return false;
    }
    player = n;
    moves++;
    return true;
  }

  double get accuracy => moves == 0 ? 0 : (optimal / moves).clamp(0, 1).toDouble();

  int score(Duration elapsed) =>
      _clampScore((optimal * 30 * accuracy + max(0, 90 - elapsed.inSeconds) * 2 - bumps * 2) * difficulty.multiplier);
}
