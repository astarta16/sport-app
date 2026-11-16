import '../../authentication/domain/app_user.dart';
import '../../brain_academy/domain/brain_models.dart';
import 'demo_backend.dart';
import 'demo_seed.dart';

/// v1.6 demo student (fictional): Luka Beridze, 11, football, coach Giorgi
/// Kapanadze, linked to his demo parent Nino Beridze. Student sign-in exists
/// only in demo mode. A few earlier Brain Academy plays and one coach
/// challenge are seeded so the progress screens are not empty.
class DemoSeedV16 {
  DemoSeedV16._();

  static const seededChallenge = 'challenge-seed-1';

  static void seed(DemoBackend db) {
    final now = db.clock();
    db.users[DemoIds.student] = AppUser(
      id: DemoIds.student,
      role: UserRole.child,
      firstName: 'ლუკა',
      lastName: 'ბერიძე',
      phone: '+995555000301',
      createdAt: now.subtract(const Duration(days: 30)),
      lastContext: const UserContext(childId: 'child-1', sportId: 'football', groupId: 'g-football-u10'),
      dataConsentAt: now.subtract(const Duration(days: 30)),
    );
    final luka = db.children['child-1'];
    if (luka != null) db.children['child-1'] = luka.copyWith(userId: DemoIds.student);

    GameResult r(
      String id,
      BrainGame g,
      GameDifficulty d,
      int level,
      int score,
      double acc,
      int ms,
      int daysAgo, [
      Map<String, num> detail = const {},
    ]) => GameResult(
      id: id,
      childId: 'child-1',
      game: g,
      difficulty: d,
      level: level,
      score: score,
      accuracy: acc,
      attempts: 8,
      durationMs: ms,
      completed: true,
      playedAt: now.subtract(Duration(days: daysAgo)),
      detail: detail,
    );
    db.brainResults.addAll([
      r('brain-seed-1', BrainGame.memoryMatch, GameDifficulty.easy, 1, 310, .67, 52000, 6),
      r('brain-seed-2', BrainGame.memoryMatch, GameDifficulty.easy, 2, 360, .8, 44000, 4),
      r('brain-seed-3', BrainGame.logicQuest, GameDifficulty.easy, 1, 640, .75, 70000, 3),
      r('brain-seed-4', BrainGame.sequenceMaster, GameDifficulty.easy, 1, 180, .71, 61000, 2, {'longest': 6}),
    ]);
    db.brainAssignments[seededChallenge] = ChallengeAssignment(
      id: seededChallenge,
      groupId: 'g-football-u10',
      coachId: DemoIds.coach,
      game: BrainGame.smartPlay,
      difficulty: GameDifficulty.easy,
      createdAt: now.subtract(const Duration(days: 1)),
      dueDate: now.add(const Duration(days: 5)),
    );
  }
}
