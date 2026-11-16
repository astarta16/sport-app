import '../../../core/utils/dates.dart';

/// Brain Academy (v1.6). Scores are game points for practice and fun — they
/// are NOT IQ or any scientifically validated measurement.
enum BrainGame {
  memoryMatch,
  logicQuest,
  smartPlay,
  quickMind,
  sequenceMaster,
  pathFinder;

  static BrainGame? fromName(String? n) => values.where((v) => v.name == n).firstOrNull;
}

enum GameDifficulty {
  easy,
  medium,
  hard;

  static GameDifficulty fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => easy);

  /// Score multiplier per difficulty.
  double get multiplier => switch (this) {
    easy => 1,
    medium => 1.5,
    hard => 2,
  };
}

/// Levels per difficulty; completing level n unlocks n + 1.
const maxLevel = 10;

/// One finished (or abandoned) play.
class GameResult {
  const GameResult({
    required this.id,
    required this.childId,
    required this.game,
    required this.difficulty,
    required this.level,
    required this.score,
    required this.accuracy,
    required this.attempts,
    required this.durationMs,
    required this.completed,
    required this.playedAt,
    this.detail = const {},
  });

  final String id;
  final String childId;
  final BrainGame game;
  final GameDifficulty difficulty;
  final int level;
  final int score;

  /// 0..1 (share of correct answers / optimal moves).
  final double accuracy;
  final int attempts;
  final int durationMs;
  final bool completed;
  final DateTime playedAt;

  /// Game-specific numbers (e.g. longest sequence, average reaction ms).
  final Map<String, num> detail;

  Map<String, dynamic> toMap() => {
    'childId': childId,
    'game': game.name,
    'difficulty': difficulty.name,
    'level': level,
    'score': score,
    'accuracy': accuracy,
    'attempts': attempts,
    'durationMs': durationMs,
    'completed': completed,
    'playedAt': playedAt.toIso8601String(),
    'detail': detail,
  };

  factory GameResult.fromMap(String id, Map<String, dynamic> m) => GameResult(
    id: id,
    childId: m['childId'] as String? ?? '',
    game: BrainGame.fromName(m['game'] as String?) ?? BrainGame.memoryMatch,
    difficulty: GameDifficulty.fromName(m['difficulty'] as String?),
    level: (m['level'] as num?)?.toInt() ?? 1,
    score: (m['score'] as num?)?.toInt() ?? 0,
    accuracy: (m['accuracy'] as num?)?.toDouble() ?? 0,
    attempts: (m['attempts'] as num?)?.toInt() ?? 0,
    durationMs: (m['durationMs'] as num?)?.toInt() ?? 0,
    completed: m['completed'] as bool? ?? false,
    playedAt: readDateOrNull(m['playedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    detail: {
      for (final e in ((m['detail'] as Map?) ?? const {}).entries)
        if (e.value is num) e.key.toString(): e.value as num,
    },
  );

  /// Server/rules bounds; anything outside is rejected.
  static List<String> validate(GameResult r) => [
    if (r.level < 1 || r.level > maxLevel) 'level',
    if (r.score < 0 || r.score > 100000) 'score',
    if (r.accuracy < 0 || r.accuracy > 1) 'accuracy',
    if (r.attempts < 0 || r.attempts > 10000) 'attempts',
    if (r.durationMs < 0 || r.durationMs > 3 * 60 * 60 * 1000) 'duration',
  ];
}

/// Per-game summary for the progress dashboard.
class GameProgress {
  const GameProgress({
    required this.game,
    required this.plays,
    required this.completed,
    required this.bestScore,
    required this.bestAccuracy,
    required this.bestTimeMs,
    required this.unlocked,
    required this.recentScores,
  });

  final BrainGame game;
  final int plays;
  final int completed;
  final int bestScore;
  final double bestAccuracy;
  final int? bestTimeMs;

  /// Highest playable level per difficulty (1 + highest completed).
  final Map<GameDifficulty, int> unlocked;

  /// Last ten scores, oldest first (improvement over time).
  final List<int> recentScores;

  int unlockedFor(GameDifficulty d) => unlocked[d] ?? 1;

  static GameProgress of(BrainGame game, Iterable<GameResult> all) {
    final list = all.where((r) => r.game == game).toList()..sort((a, b) => a.playedAt.compareTo(b.playedAt));
    final done = list.where((r) => r.completed).toList();
    return GameProgress(
      game: game,
      plays: list.length,
      completed: done.length,
      bestScore: list.fold(0, (a, r) => r.score > a ? r.score : a),
      bestAccuracy: list.fold(0.0, (a, r) => r.accuracy > a ? r.accuracy : a),
      bestTimeMs: done.isEmpty ? null : done.map((r) => r.durationMs).reduce((a, b) => a < b ? a : b),
      unlocked: {
        for (final d in GameDifficulty.values)
          d: (done.where((r) => r.difficulty == d).fold(0, (a, r) => r.level > a ? r.level : a) + 1).clamp(1, maxLevel),
      },
      recentScores: [for (final r in list.skip(list.length > 10 ? list.length - 10 : 0)) r.score],
    );
  }
}

/// Badges (no ranking against other children, no public leaderboard).
enum BrainBadge {
  firstGame,
  explorer,
  tenCompleted,
  memoryHard,
  perfectLogic,
  tactician,
  quickReflexes,
  sequenceSeven,
  mazeHard;

  static Set<BrainBadge> earned(Iterable<GameResult> results) {
    final done = results.where((r) => r.completed).toList();
    bool any(bool Function(GameResult) f) => done.any(f);
    return {
      if (done.isNotEmpty) firstGame,
      if (BrainGame.values.every((g) => done.any((r) => r.game == g))) explorer,
      if (done.length >= 10) tenCompleted,
      if (any((r) => r.game == BrainGame.memoryMatch && r.difficulty == GameDifficulty.hard)) memoryHard,
      if (any((r) => r.game == BrainGame.logicQuest && r.accuracy >= 1)) perfectLogic,
      if (any((r) => r.game == BrainGame.smartPlay && r.accuracy >= 0.8 && r.difficulty != GameDifficulty.easy))
        tactician,
      if (any((r) => r.game == BrainGame.quickMind && r.accuracy >= 0.8 && (r.detail['avgReactionMs'] ?? 9999) <= 900))
        quickReflexes,
      if (any((r) => r.game == BrainGame.sequenceMaster && (r.detail['longest'] ?? 0) >= 7)) sequenceSeven,
      if (any((r) => r.game == BrainGame.pathFinder && r.difficulty == GameDifficulty.hard)) mazeHard,
    };
  }
}

/// A coach's challenge for a group (optionally due by a date).
class ChallengeAssignment {
  const ChallengeAssignment({
    required this.id,
    required this.groupId,
    required this.coachId,
    required this.game,
    required this.difficulty,
    required this.createdAt,
    this.dueDate,
  });

  final String id;
  final String groupId;
  final String coachId;
  final BrainGame game;
  final GameDifficulty difficulty;
  final DateTime createdAt;
  final DateTime? dueDate;

  /// Done when the child completed this game at this (or a harder)
  /// difficulty after the challenge was set.
  bool doneBy(Iterable<GameResult> results) => results.any(
    (r) => r.completed && r.game == game && r.difficulty.index >= difficulty.index && !r.playedAt.isBefore(createdAt),
  );

  bool overdue(DateTime now, Iterable<GameResult> results) =>
      dueDate != null && now.isAfter(dueDate!) && !doneBy(results);

  Map<String, dynamic> toMap() => {
    'groupId': groupId,
    'coachId': coachId,
    'game': game.name,
    'difficulty': difficulty.name,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
  };

  factory ChallengeAssignment.fromMap(String id, Map<String, dynamic> m) => ChallengeAssignment(
    id: id,
    groupId: m['groupId'] as String? ?? '',
    coachId: m['coachId'] as String? ?? '',
    game: BrainGame.fromName(m['game'] as String?) ?? BrainGame.memoryMatch,
    difficulty: GameDifficulty.fromName(m['difficulty'] as String?),
    createdAt: readDateOrNull(m['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    dueDate: readDateOrNull(m['dueDate']),
  );
}

abstract interface class BrainAcademyRepository {
  /// Student (own), the child's parents and the child's coaches.
  Stream<List<GameResult>> watchResults(String childId);

  /// Student only (their own linked child).
  Future<GameResult> recordResult(GameResult result);

  /// Challenges of the child's groups (student, parents, coaches).
  Stream<List<ChallengeAssignment>> watchAssignmentsForChild(String childId);

  /// Coach of the group.
  Stream<List<ChallengeAssignment>> watchAssignmentsForGroup(String groupId);
  Future<ChallengeAssignment> assign({
    required String groupId,
    required BrainGame game,
    required GameDifficulty difficulty,
    DateTime? dueDate,
  });
  Future<void> removeAssignment(String id);
}
