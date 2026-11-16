import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_parent_app/app/di.dart';
import 'package:sport_parent_app/features/brain_academy/domain/brain_models.dart';
import 'package:sport_parent_app/features/brain_academy/domain/engines.dart';
import 'package:sport_parent_app/features/brain_academy/presentation/brain_game_screen.dart';
import 'package:sport_parent_app/features/brain_academy/presentation/game_feedback.dart';
import 'package:sport_parent_app/features/brain_academy/presentation/game_fx.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';

import '../helpers.dart';
import '../responsive/responsive_screens_test.dart' show boot, signInAs, visit, pumpFrames, expectNoLayoutErrors;

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

  Future<DemoBackend> openGame(
    WidgetTester tester,
    BrainGame g, {
    Size size = phone,
    String? locale,
    GameDifficulty difficulty = GameDifficulty.easy,
  }) async {
    final db = await boot(tester, size, locale: locale);
    await signInAs(tester, db, DemoIds.student);
    await visit(tester, 'game', ['/kid/brain/${g.name}']);
    expect(find.byKey(const Key('game-objective')), findsOneWidget);
    if (difficulty != GameDifficulty.easy) await tap(tester, 'difficulty-${difficulty.name}');
    await tap(tester, 'game-start');
    return db;
  }

  group('feedback widgets', () {
    Future<void> pumpBanner(WidgetTester tester, FeedbackKind kind) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedbackBanner(kind: kind, title: 'T', detail: 'D'),
        ),
      ),
    );

    testWidgets('correct and wrong banners use icon + text, not only colour', (tester) async {
      await pumpBanner(tester, FeedbackKind.correct);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('feedback-correct')), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('T'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
      await pumpBanner(tester, FeedbackKind.wrong);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('feedback-wrong')), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    });

    test('stars: 0 on a loss, 1–3 by accuracy on a win', () {
      expect(starsFor(won: false, accuracy: 1), 0);
      expect(starsFor(won: true, accuracy: .5), 1);
      expect(starsFor(won: true, accuracy: .75), 2);
      expect(starsFor(won: true, accuracy: .95), 3);
    });
  });

  group('sound & vibration settings', () {
    test('toggles persist across app restarts', () async {
      final (_, overrides) = await demoSetup();
      final c1 = container(overrides);
      expect(c1.read(brainSettingsProvider).sound, isTrue);
      await c1.read(brainSettingsProvider.notifier).setSound(false);
      await c1.read(brainSettingsProvider.notifier).setHaptics(false);
      final sp = await SharedPreferences.getInstance();
      expect(sp.getBool(BrainSettingsNotifier.soundKey), isFalse);
      // A fresh container (= app restart) reads the saved values.
      final c2 = container([sharedPreferencesProvider.overrideWithValue(sp), ...overrides.skip(1)]);
      expect(c2.read(brainSettingsProvider).sound, isFalse);
      expect(c2.read(brainSettingsProvider).haptics, isFalse);
    });

    test('no sound is played when sound is off', () async {
      final (_, overrides) = await demoSetup();
      final c = container(overrides);
      await c.read(gameFxProvider).correct();
      expect(testSounds.played, [GameSound.correct]);
      await c.read(brainSettingsProvider.notifier).setSound(false);
      await c.read(gameFxProvider).wrong();
      expect(testSounds.played, [GameSound.correct]);
    });

    testWidgets('settings sheet opens from the game and switches sound off', (tester) async {
      await openGame(tester, BrainGame.memoryMatch);
      await tap(tester, 'game-sound', frames: 4);
      expect(find.byKey(const Key('setting-sound')), findsOneWidget);
      expect(find.byKey(const Key('setting-haptics')), findsOneWidget);
      await tap(tester, 'setting-sound');
      final sp = await SharedPreferences.getInstance();
      expect(sp.getBool(BrainSettingsNotifier.soundKey), isFalse);
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    });
  });

  testWidgets('HUD shows level, difficulty, score, time and progress', (tester) async {
    await openGame(tester, BrainGame.logicQuest);
    await pumpFrames(tester, 2);
    expect(find.byKey(const Key('game-hud')), findsOneWidget);
    expect(find.byKey(const Key('hud-score')), findsOneWidget);
    expect(find.byKey(const Key('game-timer')), findsOneWidget);
    expect(find.byKey(const Key('hud-progress')), findsOneWidget);
  });

  testWidgets('Logic Quest: wrong answer → red mark, correct one marked, explanation, Next', (tester) async {
    await openGame(tester, BrainGame.logicQuest);
    final e = LogicEngine(difficulty: GameDifficulty.easy, level: 1, seed: seed);
    final wrong = (e.current.answer + 1) % e.current.options.length;
    testSounds.played.clear();
    await tap(tester, 'logic-option-$wrong');
    expect(find.byKey(const Key('feedback-wrong')), findsOneWidget);
    expect(find.byKey(const Key('logic-mark-correct')), findsOneWidget);
    expect(find.byKey(const Key('logic-mark-wrong')), findsOneWidget);
    expect(find.byKey(const Key('logic-next')), findsOneWidget);
    expect(testSounds.played, contains(GameSound.wrong));
    // Options are locked until Next.
    await tap(tester, 'logic-option-${e.current.answer}');
    expect(find.byKey(const Key('logic-mark-wrong')), findsOneWidget);
    await tap(tester, 'logic-next');
    expect(find.byKey(const Key('logic-feedback')), findsNothing);
    expect(find.text('რაუნდი 2/8'), findsOneWidget);
  });

  testWidgets('Smart Play: after a wrong choice the best option stays clearly marked', (tester) async {
    await openGame(tester, BrainGame.smartPlay);
    final s = SmartPlayEngine(difficulty: GameDifficulty.easy, level: 1, seed: seed).current;
    final wrong = (s.correctIndex + 1) % s.options.length;
    await tap(tester, 'smart-option-$wrong');
    expect(find.byKey(const Key('smart-result-wrong')), findsOneWidget);
    expect(find.byKey(const Key('smart-best-tag')), findsOneWidget);
    expect(find.byKey(const Key('smart-your-tag')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(Key('smart-option-${s.correctIndex}')),
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byKey(Key('smart-option-$wrong')), matching: find.byIcon(Icons.cancel_rounded)),
      findsOneWidget,
    );
    expect(find.byKey(const Key('smart-explanation')), findsOneWidget);
    expect(find.text('მწვრთნელის რჩევა'), findsOneWidget);
  });

  testWidgets('Smart Play: correct choice → big Correct banner', (tester) async {
    await openGame(tester, BrainGame.smartPlay);
    final s = SmartPlayEngine(difficulty: GameDifficulty.easy, level: 1, seed: seed).current;
    await tap(tester, 'smart-option-${s.correctIndex}');
    expect(find.byKey(const Key('smart-result-correct')), findsOneWidget);
    expect(find.byKey(const Key('smart-your-tag')), findsNothing);
    expect(find.byKey(const Key('smart-best-tag')), findsOneWidget);
  });

  testWidgets('success result: stars, score, unlocked level, next / again / back buttons', (tester) async {
    await openGame(tester, BrainGame.memoryMatch);
    final e = MemoryEngine(difficulty: GameDifficulty.easy, level: 1, seed: seed);
    final done = <int>{};
    for (var i = 0; i < e.cards.length; i++) {
      if (done.contains(i)) continue;
      final j = e.cards.indexWhere((c) => c == e.cards[i], i + 1);
      await tap(tester, 'memory-card-$i', frames: 1);
      await tap(tester, 'memory-card-$j', frames: 1);
      done.addAll([i, j]);
    }
    await pumpFrames(tester, 6);
    expect(find.byKey(const Key('game-finished')), findsOneWidget);
    expect(find.byKey(const Key('result-success-title')), findsOneWidget);
    expect(find.byKey(const Key('result-stars-3')), findsOneWidget);
    expect(find.byKey(const Key('game-final-score')), findsOneWidget);
    expect(find.byKey(const Key('result-unlocked')), findsOneWidget);
    expect(find.byKey(const Key('game-next-level')), findsOneWidget);
    expect(find.byKey(const Key('game-again')), findsOneWidget);
    expect(find.byKey(const Key('game-easier')), findsNothing);
    await tester.scrollUntilVisible(find.byKey(const Key('game-back-hub')), 200);
    expect(find.byKey(const Key('game-back-hub')), findsOneWidget);
    expect(testSounds.played, contains(GameSound.levelComplete));
    await pumpFrames(tester, 25); // let confetti finish
    expectNoLayoutErrors();
  });

  testWidgets('failure result: kind message + reason, retry, try easier, back', (tester) async {
    final db = await openGame(tester, BrainGame.logicQuest, difficulty: GameDifficulty.medium);
    final e = LogicEngine(difficulty: GameDifficulty.medium, level: 1, seed: seed);
    while (!e.isComplete) {
      final wrong = (e.current.answer + 1) % e.current.options.length;
      e.answer(wrong);
      await tap(tester, 'logic-option-$wrong', frames: 1);
      await tap(tester, 'logic-next', frames: 1);
    }
    await pumpFrames(tester, 6);
    expect(find.byKey(const Key('game-failed')), findsOneWidget);
    expect(find.byKey(const Key('result-fail-title')), findsOneWidget);
    expect(find.byKey(const Key('result-fail-reason')), findsOneWidget);
    expect(find.byKey(const Key('result-stars-0')), findsNothing, reason: 'no empty stars on a loss');
    expect(find.byKey(const Key('game-next-level')), findsNothing);
    expect(find.byKey(const Key('game-again')), findsOneWidget);
    expect(find.byKey(const Key('game-easier')), findsOneWidget);
    expect(testSounds.played, contains(GameSound.fail));
    expect(db.brainResults.last.completed, isFalse);
    await tap(tester, 'game-easier');
    expect(find.byKey(const Key('game-hud')), findsOneWidget, reason: 'restarted on easy');
    expect(find.text('მარტივი'), findsWidgets);
    expectNoLayoutErrors();
  });

  testWidgets('Quick Mind: wrong tap shows the right target, then the next round', (tester) async {
    await openGame(tester, BrainGame.quickMind);
    final r = QuickMindEngine(difficulty: GameDifficulty.easy, level: 1, seed: seed).nextRound();
    final wrong = List.generate(r.items.length, (i) => i).firstWhere((i) => r.items[i] != r.target);
    await tap(tester, 'quick-item-$wrong', frames: 1);
    expect(find.byKey(const Key('quick-feedback-wrong')), findsOneWidget);
    final target = r.items.indexOf(r.target);
    expect(
      find.descendant(
        of: find.byKey(Key('quick-item-$target')).first,
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsNothing,
      reason: 'icon sits beside the tile, inside its Stack',
    );
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget, reason: 'right target is shown');
    expect(find.byIcon(Icons.cancel_rounded), findsWidgets);
    await tester.pump(const Duration(milliseconds: 700));
    await pumpFrames(tester, 1);
    expect(find.text('რაუნდი 2/12'), findsOneWidget, reason: 'next round started');
  });

  testWidgets('Path Finder: hitting a wall shows "Blocked!"', (tester) async {
    await openGame(tester, BrainGame.pathFinder);
    final m = MazeEngine(difficulty: GameDifficulty.easy, level: 1, seed: seed);
    final d = MazeDir.values.firstWhere((d) => m.blocked(m.start.step(d)));
    await tap(tester, 'maze-${d.name}', frames: 1);
    expect(find.byKey(const Key('maze-blocked')), findsOneWidget);
    expect(find.byKey(const Key('maze-start')), findsOneWidget);
    expect(find.byKey(const Key('maze-goal')), findsOneWidget);
  });

  testWidgets('Sequence Master: a mistake costs a life and shows feedback', (tester) async {
    await openGame(tester, BrainGame.sequenceMaster);
    final e = SequenceEngine(difficulty: GameDifficulty.easy, level: 1, seed: seed);
    await tester.pump(Duration(milliseconds: 750 * (e.sequence.length * 2 + 2)));
    await pumpFrames(tester, 1);
    expect(find.byKey(const Key('sequence-status')), findsWidgets);
    final wrong = (e.sequence.first + 1) % e.palette;
    await tap(tester, 'sequence-pad-$wrong', frames: 1);
    expect(find.byKey(const Key('sequence-mistake')), findsOneWidget);
    expect(find.byKey(const Key('hud-lives')), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  for (final entry in {
    'phone 320 ru': (const Size(320, 640), 'ru'),
    'phone landscape en': (const Size(844, 390), 'en'),
    'iPad portrait ka': (const Size(820, 1180), 'ka'),
    'iPad landscape ru': (const Size(1180, 820), 'ru'),
  }.entries) {
    testWidgets('every game in play + feedback fits — ${entry.key}', (tester) async {
      final db = await boot(tester, entry.value.$1, locale: entry.value.$2);
      await signInAs(tester, db, DemoIds.student);
      for (final g in BrainGame.values) {
        await visit(tester, entry.key, ['/kid/brain/${g.name}']);
        await tap(tester, 'game-start');
        await pumpFrames(tester, 3);
        // Trigger one piece of feedback per game.
        final key = switch (g) {
          BrainGame.memoryMatch => 'memory-card-0',
          BrainGame.logicQuest => 'logic-option-0',
          BrainGame.smartPlay => 'smart-option-0',
          BrainGame.quickMind => 'quick-item-0',
          BrainGame.sequenceMaster => null,
          BrainGame.pathFinder => 'maze-up',
        };
        if (key != null) await tap(tester, key, frames: 2);
        expect(find.byKey(const Key('game-hud')), findsOneWidget);
        await tester.pump(const Duration(seconds: 2));
        expectNoLayoutErrors();
      }
    });
  }

  test('every v1.6.1 string exists in ka, en and ru', () {
    Map<String, dynamic> arb(String l) =>
        jsonDecode(File('lib/l10n/app_$l.arb').readAsStringSync()) as Map<String, dynamic>;
    final en = arb('en'), ka = arb('ka'), ru = arb('ru');
    const keys = [
      'brainSettingsTitle',
      'settingsHaptics',
      'fbWrongTitle',
      'gameNext',
      'hudScore',
      'hudTime',
      'hudStreak',
      'hudProgress',
      'resultLevelComplete',
      'resultNewHighScore',
      'resultNextUnlocked',
      'resultChallengeDone',
      'resultBackToAcademy',
      'resultTryEasier',
      'resultFailTitle',
      'resultFailEncourage',
      'resultStars',
      'resultRetry',
      'failOutOfLives',
      'failLowAccuracy',
      'failTooSlow',
      'objMemory',
      'objLogic',
      'objSmart',
      'objQuick',
      'objSequence',
      'objPath',
      'diffEasyHint',
      'diffMediumHint',
      'diffHardHint',
      'levelsUnlocked',
      'logicWhyRepeat',
      'logicWhyGrow',
      'logicWhyMissing',
      'logicCorrectWas',
      'spCoachSays',
      'spYourChoice',
      'spBestChoice',
      'quickTooSlow',
      'quickHurry',
      'quickReaction',
      'seqRepeatHint',
      'seqRoundDone',
      'seqMistake',
      'mazeBlocked',
      'mazeStart',
      'memoryPair',
      'memoryNoPair',
      'comboLabel',
    ];
    for (final k in keys) {
      for (final (name, m) in [('en', en), ('ka', ka), ('ru', ru)]) {
        expect((m[k] as String?)?.trim(), isNotEmpty, reason: '$k missing in $name');
      }
      if (k == 'hudProgress') continue; // pure placeholders, identical everywhere
      expect(ka[k], isNot(en[k]), reason: '$k not translated to ka');
      expect(ru[k], isNot(en[k]), reason: '$k not translated to ru');
    }
  });

  test('bundled sounds exist for every game event', () {
    for (final s in GameSound.values) {
      expect(File('assets/sounds/${s.file}.wav').existsSync(), isTrue, reason: s.file);
    }
  });
}
