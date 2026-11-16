import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/features/brain_academy/domain/brain_models.dart';
import 'package:sport_parent_app/features/brain_academy/domain/engines.dart';

void main() {
  group('Memory Match', () {
    test('pairs per difficulty and level; deterministic deck', () {
      expect(MemoryEngine.pairsFor(GameDifficulty.easy, 1), 4);
      expect(MemoryEngine.pairsFor(GameDifficulty.medium, 1), 6);
      expect(MemoryEngine.pairsFor(GameDifficulty.hard, 1), 8);
      expect(MemoryEngine.pairsFor(GameDifficulty.easy, 4), 5, reason: 'harder every 3 levels');
      final a = MemoryEngine(difficulty: GameDifficulty.easy, level: 1, seed: 7);
      final b = MemoryEngine(difficulty: GameDifficulty.easy, level: 1, seed: 7);
      expect(a.cards, b.cards);
      expect(a.cards.length, 8);
      for (final s in a.cards.toSet()) {
        expect(a.cards.where((c) => c == s).length, 2);
      }
    });
    test('flip rules: match stays open, mismatch must be hidden, attempts and accuracy', () {
      final e = MemoryEngine(difficulty: GameDifficulty.easy, level: 1, seed: 3);
      final first = e.cards[0];
      final pair = e.cards.indexWhere((c) => c == first, 1);
      final other = e.cards.indexWhere((c) => c != first);
      expect(e.flip(0), FlipOutcome.first);
      expect(e.flip(0), FlipOutcome.ignored, reason: 'same card twice');
      expect(e.flip(other), FlipOutcome.mismatch);
      expect(e.flip(pair), FlipOutcome.ignored, reason: 'wait until the mismatch is hidden');
      e.hideMismatch();
      expect(e.flip(0), FlipOutcome.first);
      expect(e.flip(pair), FlipOutcome.match);
      expect(e.matched, containsAll([0, pair]));
      expect(e.attempts, 2);
      // Solve the rest perfectly.
      for (var i = 0; i < e.cards.length; i++) {
        if (e.matched.contains(i)) continue;
        final j = e.cards.indexWhere((c) => c == e.cards[i], i + 1);
        e.flip(i);
        e.flip(j);
      }
      expect(e.isComplete, isTrue);
      expect(e.accuracy, 4 / 5);
      expect(e.score(const Duration(seconds: 20)), greaterThan(0));
      final perfect = MemoryEngine(difficulty: GameDifficulty.hard, level: 1, seed: 3);
      for (var i = 0; i < perfect.cards.length; i++) {
        if (perfect.matched.contains(i)) continue;
        perfect.flip(i);
        perfect.flip(perfect.cards.indexWhere((c) => c == perfect.cards[i], i + 1));
      }
      expect(perfect.accuracy, 1);
      expect(
        perfect.score(const Duration(seconds: 20)),
        greaterThan(e.score(const Duration(seconds: 20))),
        reason: 'harder + perfect scores more',
      );
    });
  });

  group('Logic Quest', () {
    test('every puzzle has exactly one correct option matching the hidden element', () {
      for (final d in GameDifficulty.values) {
        final e = LogicEngine(difficulty: d, level: 5, seed: 11);
        expect(e.puzzles.length, LogicEngine.puzzleCount);
        for (final p in e.puzzles) {
          expect(p.options.toSet().length, p.options.length, reason: 'distinct options');
          expect(p.options.where((o) => o == p.sequence[p.missingIndex]).length, 1);
          expect(p.options[p.answer], p.sequence[p.missingIndex]);
        }
      }
    });
    test('repeat puzzles follow their period; grow puzzles count up', () {
      final e = LogicEngine(difficulty: GameDifficulty.medium, level: 1, seed: 5);
      for (final p in e.puzzles) {
        if (p.kind == LogicKind.grow) {
          for (var i = 1; i < p.sequence.length; i++) {
            expect(p.sequence[i].count, greaterThan(p.sequence[i - 1].count));
          }
        } else {
          for (var i = 3; i < p.sequence.length; i++) {
            expect(p.sequence[i], p.sequence[i - 3], reason: 'period 3 on medium');
          }
        }
      }
    });
    test('scoring and accuracy', () {
      final e = LogicEngine(difficulty: GameDifficulty.easy, level: 1, seed: 2);
      for (var i = 0; i < 6; i++) {
        expect(e.answer(e.current.answer), isTrue);
      }
      expect(e.answer((e.current.answer + 1) % 4), isFalse);
      expect(e.answer(e.current.answer), isTrue);
      expect(e.isComplete, isTrue);
      expect(e.accuracy, 7 / 8);
      expect(e.score(const Duration(seconds: 30)), 700, reason: 'no speed bonus unless perfect');
      expect(e.answer(0), isFalse, reason: 'ignored after completion');
    });
  });

  group('Smart Play', () {
    test('library: every scenario has one correct option, a ball carrier and an explanation', () {
      for (final s in StrategyLibrary.scenarios[StrategySport.football]!) {
        expect(s.options.where((o) => o.correct).length, 1, reason: s.id);
        expect(s.players.where((p) => p.hasBall).length, 1, reason: s.id);
        expect(s.explanationKey, startsWith('spExplain'));
        for (final o in s.options.where((o) => o.target != null)) {
          expect(s.players.any((p) => p.id == o.target && p.team == Team.us), isTrue, reason: '${s.id} target exists');
        }
      }
    });
    test('progressively harder sets; explanation step before the next scenario', () {
      expect(
        SmartPlayEngine(
          difficulty: GameDifficulty.easy,
          level: 1,
          seed: 1,
        ).scenarios.every((s) => s.difficulty == GameDifficulty.easy),
        isTrue,
      );
      final hard = SmartPlayEngine(difficulty: GameDifficulty.hard, level: 1, seed: 1);
      expect(hard.scenarios.length, greaterThan(3));
      expect(hard.scenarios.any((s) => s.difficulty == GameDifficulty.hard), isTrue);
      final e = SmartPlayEngine(difficulty: GameDifficulty.medium, level: 1, seed: 9);
      var n = 0;
      while (!e.isComplete) {
        expect(e.choose(e.current.correctIndex), isTrue);
        expect(e.choose(0), isFalse, reason: 'one answer per scenario');
        e.next();
        n++;
      }
      expect(n, e.scenarios.length);
      expect(e.accuracy, 1);
      expect(e.score(), (e.scenarios.length * 150 * 1.5).round());
    });
  });

  group('Quick Mind', () {
    test('each round has exactly one target among grid-size items', () {
      for (final d in GameDifficulty.values) {
        final e = QuickMindEngine(difficulty: d, level: 1, seed: 4);
        for (var i = 0; i < 20; i++) {
          final r = e.nextRound();
          expect(r.items.length, e.gridSize);
          expect(r.items.where((x) => x == r.target).length, 1);
        }
      }
    });
    test('accuracy, reaction time, timeouts and shrinking time limits', () {
      final e = QuickMindEngine(difficulty: GameDifficulty.medium, level: 1, seed: 8);
      final start = e.limitMs;
      final r1 = e.nextRound();
      expect(e.tap(r1, r1.items.indexOf(r1.target), 600), isTrue);
      final r2 = e.nextRound();
      expect(e.tap(r2, (r2.items.indexOf(r2.target) + 1) % r2.items.length, 500), isFalse);
      final r3 = e.nextRound();
      expect(e.tap(r3, r3.items.indexOf(r3.target), r3.limitMs + 1), isFalse, reason: 'too late');
      e.timeout();
      expect(e.played, 4);
      expect(e.accuracy, 0.25);
      expect(e.avgReactionMs, 600);
      expect(e.limitMs, lessThan(start), reason: 'faster after a correct answer');
      expect(
        QuickMindEngine(difficulty: GameDifficulty.hard, level: 5, seed: 1).limitMs,
        lessThan(QuickMindEngine(difficulty: GameDifficulty.easy, level: 1, seed: 1).limitMs),
      );
    });
  });

  group('Sequence Master', () {
    test('repeat the sequence → it grows; mistakes cost lives; completion after 5 rounds', () {
      final e = SequenceEngine(difficulty: GameDifficulty.easy, level: 1, seed: 6);
      expect(e.sequence.length, 3);
      expect(e.lives, 2);
      for (var i = 0; i < e.sequence.length - 1; i++) {
        expect(e.input(e.sequence[i]), SequenceInput.correct);
      }
      expect(e.input(e.sequence.last), SequenceInput.roundComplete);
      expect(e.sequence.length, 4);
      expect(e.input((e.sequence[0] + 1) % e.palette), SequenceInput.wrong);
      expect(e.lives, 1);
      expect(e.position, 0, reason: 'restart the same round');
      while (!e.isOver) {
        for (final s in List.of(e.sequence)) {
          if (e.input(s) == SequenceInput.roundComplete) break;
        }
      }
      expect(e.won, isTrue);
      expect(e.completedRounds, 5);
      expect(e.longest, 7);
      expect(e.score(), greaterThan(0));
    });
    test('hard starts longer with one life', () {
      final e = SequenceEngine(difficulty: GameDifficulty.hard, level: 4, seed: 1);
      expect(e.sequence.length, 6);
      expect(e.lives, 1);
      e.input((e.sequence[0] + 1) % e.palette);
      expect(e.isOver, isTrue);
      expect(e.won, isFalse);
    });
  });

  group('Path Finder', () {
    test('mazes are solvable, obstacles never block the shortest path', () {
      for (final d in GameDifficulty.values) {
        for (var seed = 0; seed < 20; seed++) {
          final m = MazeEngine(difficulty: d, level: 1, seed: seed);
          final path = m.shortestPath(m.start, m.goal);
          expect(path, isNotNull);
          expect(path!.any(m.obstacles.contains), isFalse);
          expect(m.optimal, path.length - 1);
        }
      }
    });
    test('moves: walls and cones stop you (bumps); reaching the goal completes', () {
      final m = MazeEngine(difficulty: GameDifficulty.medium, level: 1, seed: 12);
      expect(m.move(MazeDir.up), isFalse, reason: 'outer wall');
      expect(m.bumps, 1);
      final path = m.shortestPath(m.start, m.goal)!;
      for (var i = 1; i < path.length; i++) {
        final a = path[i - 1], b = path[i];
        final d = b.r < a.r
            ? MazeDir.up
            : b.r > a.r
            ? MazeDir.down
            : b.c < a.c
            ? MazeDir.left
            : MazeDir.right;
        expect(m.move(d), isTrue);
      }
      expect(m.isComplete, isTrue);
      expect(m.moves, m.optimal);
      expect(m.accuracy, 1);
      expect(m.score(const Duration(seconds: 10)), greaterThan(0));
      expect(m.move(MazeDir.left), isFalse, reason: 'no moves after the goal');
    });
  });

  group('progress, levels and badges', () {
    GameResult r(
      BrainGame g,
      GameDifficulty d,
      int level, {
      bool done = true,
      int score = 100,
      double acc = .9,
      Map<String, num> detail = const {},
    }) => GameResult(
      id: '$g$d$level$score',
      childId: 'c',
      game: g,
      difficulty: d,
      level: level,
      score: score,
      accuracy: acc,
      attempts: 1,
      durationMs: 1000 * level,
      completed: done,
      playedAt: DateTime(2026, 11, level),
      detail: detail,
    );
    test('completing level n unlocks n + 1 per difficulty; best score/time', () {
      final p = GameProgress.of(BrainGame.memoryMatch, [
        r(BrainGame.memoryMatch, GameDifficulty.easy, 1, score: 200),
        r(BrainGame.memoryMatch, GameDifficulty.easy, 2, score: 350),
        r(BrainGame.memoryMatch, GameDifficulty.easy, 3, done: false, score: 50),
        r(BrainGame.logicQuest, GameDifficulty.easy, 5),
      ]);
      expect(p.plays, 3);
      expect(p.completed, 2);
      expect(p.unlockedFor(GameDifficulty.easy), 3);
      expect(p.unlockedFor(GameDifficulty.hard), 1);
      expect(p.bestScore, 350);
      expect(p.bestTimeMs, 1000);
      expect(p.recentScores, [200, 350, 50]);
    });
    test('badges come from real play only', () {
      expect(BrainBadge.earned(const []), isEmpty);
      final all = [for (final g in BrainGame.values) r(g, GameDifficulty.easy, 1)];
      expect(BrainBadge.earned(all), containsAll([BrainBadge.firstGame, BrainBadge.explorer]));
      expect(
        BrainBadge.earned([
          r(BrainGame.sequenceMaster, GameDifficulty.easy, 1, detail: {'longest': 7}),
        ]),
        contains(BrainBadge.sequenceSeven),
      );
      expect(BrainBadge.earned([r(BrainGame.pathFinder, GameDifficulty.hard, 1)]), contains(BrainBadge.mazeHard));
      expect(
        BrainBadge.earned([r(BrainGame.memoryMatch, GameDifficulty.hard, 1, done: false)]),
        isNot(contains(BrainBadge.memoryHard)),
      );
    });
    test('challenge status: done only after assignment, at or above the difficulty; overdue', () {
      final a = ChallengeAssignment(
        id: 'a',
        groupId: 'g',
        coachId: 'k',
        game: BrainGame.quickMind,
        difficulty: GameDifficulty.medium,
        createdAt: DateTime(2026, 11, 3),
        dueDate: DateTime(2026, 11, 10),
      );
      expect(a.doneBy([r(BrainGame.quickMind, GameDifficulty.hard, 4)]), isTrue);
      expect(a.doneBy([r(BrainGame.quickMind, GameDifficulty.easy, 4)]), isFalse);
      expect(a.doneBy([r(BrainGame.quickMind, GameDifficulty.hard, 2)]), isFalse, reason: 'played before it was set');
      expect(a.overdue(DateTime(2026, 11, 11), const []), isTrue);
    });
    test('result validation bounds', () {
      final ok = r(BrainGame.logicQuest, GameDifficulty.easy, 1);
      expect(GameResult.validate(ok), isEmpty);
      expect(GameResult.validate(r(BrainGame.logicQuest, GameDifficulty.easy, 11)), contains('level'));
      expect(GameResult.fromMap('x', ok.toMap()).toMap(), ok.toMap());
    });
  });
}
