import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_parent_app/app/router.dart';
import 'package:sport_parent_app/app/routes.dart';
import 'package:sport_parent_app/core/errors/app_exception.dart';
import 'package:sport_parent_app/features/authentication/domain/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_parent_app/features/brain_academy/data/demo_brain_repositories.dart';
import 'package:sport_parent_app/features/brain_academy/domain/brain_models.dart';
import 'package:sport_parent_app/features/chat/data/demo_chat_repository.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/payments/data/demo_payments_repository.dart';

final denied = throwsA(isA<PermissionDeniedException>());

GameResult result({String childId = 'child-1', BrainGame game = BrainGame.memoryMatch, bool completed = true}) =>
    GameResult(
      id: '',
      childId: childId,
      game: game,
      difficulty: GameDifficulty.easy,
      level: 1,
      score: 250,
      accuracy: .8,
      attempts: 6,
      durationMs: 30000,
      completed: completed,
      playedAt: DateTime(2026, 11, 16),
    );

void main() {
  final now = DateTime(2026, 11, 16, 12);
  late DemoBackend db;
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = DemoSeed.create(clock: () => now);
  });
  void as(String uid) => db.session = (uid: uid, phone: db.users[uid]!.phone);

  group('demo student account', () {
    test('Luka (11, football, coach Giorgi) is linked to child-1 and to Nino', () {
      final u = db.users[DemoIds.student]!;
      expect(u.isStudent, isTrue);
      expect(u.lastContext.childId, 'child-1');
      final c = db.children['child-1']!;
      expect(c.userId, DemoIds.student);
      expect(c.parentIds, contains(DemoIds.parent));
      expect(c.ageOn(now), 11);
      expect(
        db.groups.values
            .where((g) => g.hasChild('child-1'))
            .any((g) => g.sportId == 'football' && g.hasCoach(DemoIds.coach)),
        isTrue,
      );
    });

    test('student routes only in demo mode; production keeps child sign-in disabled', () {
      final session = AsyncValue<AuthSession?>.data(
        AuthSession(uid: DemoIds.student, phone: '', user: db.users[DemoIds.student]),
      );
      String? go(String loc, {required bool demo}) =>
          resolveRedirect(location: loc, session: session, onboardingSeen: true, studentAccountsEnabled: demo);
      expect(go('/parent/home', demo: true), Routes.studentHome);
      expect(go('/payments', demo: true), Routes.studentHome);
      expect(go('/chats', demo: true), Routes.studentHome);
      expect(go('/certificates/child-1', demo: true), Routes.studentHome);
      expect(go('/kid/home', demo: true), isNull);
      expect(go('/kid/brain/memoryMatch', demo: true), isNull);
      expect(go('/kid/home', demo: false), Routes.childUnsupported);
    });

    test('student view: own child only; no chat or payments through other repositories', () async {
      as(DemoIds.student);
      final v = await DemoStudentRepository(db).watchMyView().first;
      expect(v.child.id, 'child-1');
      expect(v.groups.every((g) => g.hasChild('child-1')), isTrue);
      expect(v.attendance.every((r) => r.childId == 'child-1'), isTrue);
      expect(v.coachNames.values, contains('გიორგი კაპანაძე'));
      await expectLater(DemoChatRepository(db).watchMessages('g-football-u10').first, denied);
      final pays = await DemoPaymentsRepository(db).watchMyPayments().first.catchError((_) => const <Never>[]);
      expect(pays, isEmpty, reason: 'no financial records for students');
      as(DemoIds.parent);
      await expectLater(DemoStudentRepository(db).watchMyView().first, denied, reason: 'parents are not students');
    });
  });

  group('Brain Academy repository', () {
    test('the student records results; others cannot record for the child', () async {
      final repo = DemoBrainAcademyRepository(db, prefs);
      as(DemoIds.student);
      final saved = await repo.recordResult(result());
      expect(saved.id, isNotEmpty);
      expect(saved.playedAt, now, reason: 'trusted (backend) time');
      await expectLater(repo.recordResult(result(childId: 'child-4')), denied);
      as(DemoIds.parent);
      await expectLater(repo.recordResult(result()), denied);
      as(DemoIds.coach);
      await expectLater(repo.recordResult(result()), denied);
    });

    test('progress is visible to the student, the parent and the coach — not to others', () async {
      final repo = DemoBrainAcademyRepository(db, prefs);
      for (final uid in [DemoIds.student, DemoIds.parent, DemoSeedV16Ids.secondGuardian, DemoIds.coach]) {
        as(uid);
        expect(await repo.watchResults('child-1').first, isNotEmpty, reason: uid);
      }
      for (final uid in ['parent-2', 'coach-2', DemoIds.platformAdmin]) {
        as(uid);
        await expectLater(repo.watchResults('child-1').first, denied, reason: uid);
      }
    });

    test('progress survives an app restart (local demo storage)', () async {
      final repo = DemoBrainAcademyRepository(db, prefs);
      as(DemoIds.student);
      await repo.recordResult(result(game: BrainGame.pathFinder));
      // A fresh backend (app restart) loads the stored plays again.
      final db2 = DemoSeed.create(clock: () => now);
      final repo2 = DemoBrainAcademyRepository(db2, prefs);
      db2.session = (uid: DemoIds.student, phone: '');
      final list = await repo2.watchResults('child-1').first;
      expect(list.where((r) => r.game == BrainGame.pathFinder), hasLength(1));
      expect(list.where((r) => r.id == 'brain-seed-1'), hasLength(1), reason: 'seeded plays are not duplicated');
    });

    test(
      'coach assigns challenges (difficulty, due date); parents and the student see them; status follows play',
      () async {
        final repo = DemoBrainAcademyRepository(db, prefs);
        as(DemoIds.coach);
        final a = await repo.assign(
          groupId: 'g-football-u10',
          game: BrainGame.quickMind,
          difficulty: GameDifficulty.medium,
          dueDate: now.add(const Duration(days: 3)),
        );
        await expectLater(
          repo.assign(
            groupId: 'g-football-u10',
            game: BrainGame.quickMind,
            difficulty: GameDifficulty.easy,
            dueDate: now.subtract(const Duration(days: 2)),
          ),
          throwsA(isA<ValidationException>()),
        );
        expect((await repo.watchAssignmentsForGroup('g-football-u10').first).map((x) => x.id), contains(a.id));
        as(DemoIds.parent);
        expect((await repo.watchAssignmentsForChild('child-1').first).map((x) => x.id), contains(a.id));
        await expectLater(
          repo.assign(groupId: 'g-football-u10', game: BrainGame.logicQuest, difficulty: GameDifficulty.easy),
          denied,
        );
        as(DemoIds.student);
        expect(a.doneBy(await repo.watchResults('child-1').first), isFalse);
        await repo.recordResult(
          GameResult(
            id: '',
            childId: 'child-1',
            game: BrainGame.quickMind,
            difficulty: GameDifficulty.hard,
            level: 1,
            score: 900,
            accuracy: .9,
            attempts: 12,
            durationMs: 20000,
            completed: true,
            playedAt: now,
          ),
        );
        expect(a.doneBy(await repo.watchResults('child-1').first), isTrue);
        as('coach-2');
        await expectLater(repo.watchAssignmentsForGroup('g-football-u10').first, denied);
        await expectLater(repo.removeAssignment(a.id), denied);
        as(DemoIds.coach);
        await repo.removeAssignment(a.id);
        expect((await repo.watchAssignmentsForGroup('g-football-u10').first).map((x) => x.id), isNot(contains(a.id)));
      },
    );

    test('games work offline: results are stored without a connection', () async {
      final repo = DemoBrainAcademyRepository(db, prefs);
      db.setOffline(true);
      as(DemoIds.student);
      expect((await repo.recordResult(result())).id, isNotEmpty);
    });
  });
}

/// Second guardian id from the v1.4 seed (kept local to this test).
abstract final class DemoSeedV16Ids {
  static const secondGuardian = 'parent-5';
}
