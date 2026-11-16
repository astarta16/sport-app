import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_parent_app/features/brain_academy/domain/brain_models.dart';
import 'package:sport_parent_app/features/brain_academy/domain/engines.dart';
import 'package:sport_parent_app/features/brain_academy/presentation/brain_game_screen.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';

import '../responsive/responsive_screens_test.dart'
    show boot, signInAs, visit, pumpFrames, expectNoLayoutErrors, routerOf;

const seed = 42;

void main() {
  setUpAll(() => initializeDateFormatting());
  setUp(() => gameSeed = () => seed);
  const phone = Size(390, 844);

  Future<void> tap(WidgetTester tester, String key, {int frames = 2}) async {
    final f = find.byKey(Key(key));
    if (f.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        f,
        200,
        scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).last,
      );
    }
    await tester.ensureVisible(f.first);
    await tester.pump();
    await tester.tap(f.first);
    await pumpFrames(tester, frames);
  }

  Future<DemoBackend> openGame(WidgetTester tester, BrainGame g, {Size size = phone}) async {
    final db = await boot(tester, size);
    await signInAs(tester, db, DemoIds.student);
    await visit(tester, 'game', ['/kid/brain/${g.name}']);
    expect(find.byKey(const Key('game-instructions')), findsOneWidget);
    await tap(tester, 'game-start');
    return db;
  }

  Future<void> expectFinished(WidgetTester tester, DemoBackend db, BrainGame g, int before) async {
    await pumpFrames(tester, 6);
    expect(find.byKey(const Key('game-finished')), findsOneWidget);
    final mine = db.brainResults.where((r) => r.game == g && r.childId == 'child-1').toList();
    expect(mine.length, before + 1, reason: 'result saved');
    expect(mine.last.completed, isTrue);
    expect(mine.last.score, greaterThan(0));
    expectNoLayoutErrors();
  }

  int count(DemoBackend db, BrainGame g) => db.brainResults.where((r) => r.game == g).length;

  testWidgets('demo student login → student dashboard; no parent-only areas', (tester) async {
    final db = await boot(tester, phone);
    await visit(tester, 'login', ['/auth/phone']);
    await tester.scrollUntilVisible(
      find.byKey(const Key('demo-continue-student')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tap(tester, 'demo-continue-student', frames: 8);
    expect(find.byKey(const Key('student-welcome')), findsOneWidget);
    expect(find.textContaining('ლუკა'), findsWidgets);
    expect(find.byKey(const Key('student-brain-hero')), findsOneWidget);
    expect(find.byKey(const Key('payment-tile')), findsNothing);
    expect(find.byKey(const Key('certificate-tile')), findsNothing);
    // Parent / payment / chat routes bounce back to the student home.
    for (final r in [
      '/payments',
      '/chats',
      '/parent/home',
      '/certificates/child-1',
      '/group/g-football-u10/contacts',
    ]) {
      routerOf(tester).go(r);
      await pumpFrames(tester);
      expect(find.byKey(const Key('student-welcome')), findsOneWidget, reason: r);
    }
    await tap(tester, 'student-nav-brain');
    for (final g in BrainGame.values) {
      expect(find.byKey(Key('brain-game-${g.name}')), findsOneWidget);
    }
    expect(find.byKey(const Key('challenge-play-challenge-seed-1')), findsOneWidget, reason: 'coach challenge');
    await tap(tester, 'student-nav-progress');
    expect(find.byKey(const Key('brain-progress-child-1')), findsOneWidget);
    expectNoLayoutErrors();
    expect(db.session?.uid, DemoIds.student);
  });

  testWidgets('Memory Match: perfect play; pause blocks input, resume and restart work; next level', (tester) async {
    final db = await openGame(tester, BrainGame.memoryMatch);
    final before = count(db, BrainGame.memoryMatch);
    // Pause → overlay; resume.
    await tap(tester, 'game-pause');
    expect(find.byKey(const Key('game-paused')), findsOneWidget);
    await tap(tester, 'game-resume');
    expect(find.byKey(const Key('game-paused')), findsNothing);
    await tap(tester, 'game-restart');
    final e = MemoryEngine(difficulty: GameDifficulty.easy, level: 1, seed: seed);
    final done = <int>{};
    for (var i = 0; i < e.cards.length; i++) {
      if (done.contains(i)) continue;
      final j = e.cards.indexWhere((c) => c == e.cards[i], i + 1);
      await tap(tester, 'memory-card-$i', frames: 1);
      await tap(tester, 'memory-card-$j', frames: 1);
      done.addAll([i, j]);
    }
    await expectFinished(tester, db, BrainGame.memoryMatch, before);
    expect(db.brainResults.last.accuracy, 1);
    await tap(tester, 'game-next-level');
    expect(find.textContaining('2'), findsWidgets);
    expect(find.byKey(const Key('memory-card-0')), findsOneWidget, reason: 'level 2 started');
  });

  testWidgets('Logic Quest: answer every puzzle', (tester) async {
    final db = await openGame(tester, BrainGame.logicQuest);
    final before = count(db, BrainGame.logicQuest);
    final e = LogicEngine(difficulty: GameDifficulty.easy, level: 1, seed: seed);
    while (!e.isComplete) {
      final a = e.current.answer;
      e.answer(a);
      await tap(tester, 'logic-option-$a', frames: 1);
    }
    await expectFinished(tester, db, BrainGame.logicQuest, before);
  });

  testWidgets('Smart Play: choose, read the explanation, next', (tester) async {
    final db = await openGame(tester, BrainGame.smartPlay);
    final before = count(db, BrainGame.smartPlay);
    final e = SmartPlayEngine(difficulty: GameDifficulty.easy, level: 1, seed: seed);
    for (final s in e.scenarios) {
      await tap(tester, 'smart-option-${s.correctIndex}');
      expect(find.byKey(const Key('smart-explanation')), findsOneWidget);
      await tap(tester, 'smart-next');
    }
    await expectFinished(tester, db, BrainGame.smartPlay, before);
  });

  testWidgets('Quick Mind: tap the target in every round', (tester) async {
    final db = await openGame(tester, BrainGame.quickMind);
    final before = count(db, BrainGame.quickMind);
    final e = QuickMindEngine(difficulty: GameDifficulty.easy, level: 1, seed: seed);
    for (var i = 0; i < QuickMindEngine.rounds; i++) {
      final r = e.nextRound();
      await tap(tester, 'quick-item-${r.items.indexOf(r.target)}', frames: 1);
    }
    await expectFinished(tester, db, BrainGame.quickMind, before);
    expect(db.brainResults.last.accuracy, 1);
  });

  testWidgets('Quick Mind: a missed round times out (counted, not correct)', (tester) async {
    await openGame(tester, BrainGame.quickMind);
    await tester.pump(const Duration(milliseconds: 3600));
    await pumpFrames(tester, 2);
    expect(find.text('რაუნდი 2/12'), findsOneWidget);
  });

  testWidgets('Sequence Master: watch, then repeat five growing rounds', (tester) async {
    final db = await openGame(tester, BrainGame.sequenceMaster);
    final before = count(db, BrainGame.sequenceMaster);
    final e = SequenceEngine(difficulty: GameDifficulty.easy, level: 1, seed: seed);
    while (!e.isOver) {
      // Playback: one beat on + one off per item, plus the final beat.
      await tester.pump(Duration(milliseconds: 750 * (e.sequence.length * 2 + 2)));
      await pumpFrames(tester, 1);
      expect(find.text('შენი ჯერია!'), findsOneWidget);
      for (final s in List.of(e.sequence)) {
        e.input(s);
        await tester.tap(find.byKey(Key('sequence-pad-$s')));
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.pump(const Duration(milliseconds: 600));
    }
    await expectFinished(tester, db, BrainGame.sequenceMaster, before);
    expect(db.brainResults.last.detail['longest'], 7);
  });

  testWidgets('Path Finder: walk the shortest path to the goal', (tester) async {
    final db = await openGame(tester, BrainGame.pathFinder);
    final before = count(db, BrainGame.pathFinder);
    final m = MazeEngine(difficulty: GameDifficulty.easy, level: 1, seed: seed);
    final path = m.shortestPath(m.start, m.goal)!;
    for (var i = 1; i < path.length; i++) {
      final a = path[i - 1], b = path[i];
      final d = b.r < a.r
          ? 'up'
          : b.r > a.r
          ? 'down'
          : b.c < a.c
          ? 'left'
          : 'right';
      await tester.tap(find.byKey(Key('maze-$d')));
      await tester.pump(const Duration(milliseconds: 150));
    }
    await expectFinished(tester, db, BrainGame.pathFinder, before);
    expect(db.brainResults.last.accuracy, 1);
  });

  testWidgets('parent sees Brain Academy progress; coach assigns a challenge and reviews it', (tester) async {
    final db = await boot(tester, phone);
    await signInAs(tester, db, DemoIds.parent);
    await visit(tester, 'profile', ['/student/child-1']);
    final tabF = find.descendant(of: find.byKey(const Key('profile-tabs')), matching: find.text('ტვინის აკადემია'));
    await tester.ensureVisible(tabF);
    await tester.tap(tabF);
    await pumpFrames(tester);
    expect(find.byKey(const Key('brain-progress-child-1')), findsOneWidget);
    expect(find.byKey(const Key('challenge-challenge-seed-1')), findsOneWidget);
    expect(find.byKey(const Key('challenge-play-challenge-seed-1')), findsNothing, reason: 'parents do not play');
    expectNoLayoutErrors();

    await signInAs(tester, db, DemoIds.coach);
    await visit(tester, 'challenges', ['/group/g-football-u10/challenges']);
    final before = db.brainAssignments.length;
    await tap(tester, 'challenge-assign');
    await tap(tester, 'challenge-game-pathFinder');
    await tap(tester, 'challenge-diff-hard');
    await tap(tester, 'challenge-save', frames: 6);
    expect(db.brainAssignments.length, before + 1);
    final a = db.brainAssignments.values.firstWhere((x) => x.game == BrainGame.pathFinder);
    expect(a.difficulty, GameDifficulty.hard);
    expect(find.byKey(Key('assignment-completion-${a.id}')), findsOneWidget);
    expectNoLayoutErrors();
  });

  for (final entry in {
    'phone 320 ru': (const Size(320, 640), 'ru'),
    'phone landscape en': (const Size(844, 390), 'en'),
    'iPad portrait ka': (const Size(820, 1180), 'ka'),
    'iPad landscape ru': (const Size(1180, 820), 'ru'),
  }.entries) {
    testWidgets('student screens and every game setup fit — ${entry.key}', (tester) async {
      final db = await boot(tester, entry.value.$1, locale: entry.value.$2);
      await signInAs(tester, db, DemoIds.student);
      await visit(tester, entry.key, ['/kid/home']);
      for (final t in ['student-nav-brain', 'student-nav-progress', 'student-nav-home']) {
        await tester.tap(find.byKey(Key(t)));
        await pumpFrames(tester);
      }
      for (final g in BrainGame.values) {
        await visit(tester, entry.key, ['/kid/brain/${g.name}']);
        await tap(tester, 'game-start');
        await pumpFrames(tester, 4);
      }
      await visit(tester, entry.key, ['/kid/home']);
      expectNoLayoutErrors();
    });
  }
}
