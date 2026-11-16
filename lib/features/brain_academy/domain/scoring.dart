import '../../../core/utils/dates.dart';
import '../../organizations/domain/organization.dart';
import 'brain_models.dart';

/// v1.7 shared scoring service: ONE deterministic function turns validated
/// completion events into points. The student dashboard, the coach view and
/// the organization leaderboard all use it, and functions/src/lib/scoring.ts
/// mirrors it exactly — the server recomputes totals from stored results, so
/// a client can never submit an authoritative total.
///
/// Anti-farming: within one local day, the same (game, difficulty, level)
/// pays full points once, then half, then a quarter, then nothing; and
/// there is a daily cap. Harder levels pay more. Points are game points
/// for fun and practice — never an IQ or ability measurement.
class ScoringRules {
  const ScoringRules({
    this.base = const {GameDifficulty.easy: 10, GameDifficulty.medium: 20, GameDifficulty.hard: 30},
    this.perLevel = 2,
    this.accuracyBonusMax = 10,
    this.firstClearBonus = 15,
    this.repeatFactors = const [1, 0.5, 0.25],
    this.dailyCap = 300,
    this.minDurationMs = 3000,
  });

  static const standard = ScoringRules();

  final Map<GameDifficulty, int> base;
  final int perLevel;
  final int accuracyBonusMax;

  /// Paid once per (game, difficulty, level) ever.
  final int firstClearBonus;

  /// Multiplier for the 1st, 2nd, 3rd… completion of the same key per day;
  /// beyond the list the play earns 0.
  final List<double> repeatFactors;
  final int dailyCap;

  /// Plays shorter than this are implausible and earn nothing.
  final int minDurationMs;

  Map<String, dynamic> toMap() => {
    'base': {for (final e in base.entries) e.key.name: e.value},
    'perLevel': perLevel,
    'accuracyBonusMax': accuracyBonusMax,
    'firstClearBonus': firstClearBonus,
    'repeatFactors': repeatFactors,
    'dailyCap': dailyCap,
    'minDurationMs': minDurationMs,
  };
}

/// Points awarded for one stored result.
class ScoredResult {
  const ScoredResult(this.result, this.points, {this.firstClear = false, this.capped = false});

  final GameResult result;
  final int points;
  final bool firstClear;

  /// Reduced by the repeat factor or the daily cap.
  final bool capped;
}

/// Everything the progress dashboard shows, computed from real results.
class BrainProgressSummary {
  const BrainProgressSummary({
    required this.scored,
    required this.totalPoints,
    required this.gamesCompleted,
    required this.pointsByGame,
    required this.accuracyByGame,
    required this.highestLevel,
    required this.bestScoreByGame,
    required this.weeklyPoints,
    required this.badges,
  });

  /// Oldest first.
  final List<ScoredResult> scored;
  final int totalPoints;
  final int gamesCompleted;
  final Map<BrainGame, int> pointsByGame;

  /// Average accuracy of completed plays (0..1); absent = never played.
  final Map<BrainGame, double> accuracyByGame;

  /// Highest unlocked level per game, as "difficulty · level".
  final Map<BrainGame, (GameDifficulty, int)> highestLevel;
  final Map<BrainGame, int> bestScoreByGame;

  /// Points per local day for the last 7 days, oldest first.
  final List<int> weeklyPoints;
  final Set<BrainBadge> badges;

  int get pointsThisWeek => weeklyPoints.fold(0, (a, b) => a + b);
  List<ScoredResult> get recent => scored.reversed.take(10).toList();
}

class ScoringService {
  ScoringService._();

  static String _key(GameResult r) => '${r.game.name}|${r.difficulty.name}|${r.level}';

  /// Deterministic order: play time, then id.
  static List<GameResult> ordered(Iterable<GameResult> results) {
    final seen = <String>{};
    // Idempotency: the same result id is only ever counted once.
    final list = [
      for (final r in results)
        if (seen.add(r.id)) r,
    ]..sort((a, b) => a.playedAt != b.playedAt ? a.playedAt.compareTo(b.playedAt) : a.id.compareTo(b.id));
    return list;
  }

  /// Points for each result (in [ordered] order).
  static List<ScoredResult> score(Iterable<GameResult> results, {ScoringRules rules = ScoringRules.standard}) {
    final out = <ScoredResult>[];
    final cleared = <String>{};
    final perDayKey = <String, int>{};
    final perDay = <String, int>{};
    for (final r in ordered(results)) {
      if (!r.completed || GameResult.validate(r).isNotEmpty || r.durationMs < rules.minDurationMs) {
        out.add(ScoredResult(r, 0));
        continue;
      }
      final day = TbilisiTime.calendarDay(r.playedAt).toIso8601String();
      final key = _key(r);
      final n = perDayKey['$day|$key'] ?? 0;
      perDayKey['$day|$key'] = n + 1;
      final factor = n < rules.repeatFactors.length ? rules.repeatFactors[n] : 0.0;
      final raw =
          (rules.base[r.difficulty] ?? 10) +
          rules.perLevel * (r.level - 1) +
          (rules.accuracyBonusMax * r.accuracy.clamp(0, 1)).round();
      final first = cleared.add(key);
      var pts = (raw * factor).round() + (first ? rules.firstClearBonus : 0);
      final used = perDay[day] ?? 0;
      final capped = factor < 1 || used + pts > rules.dailyCap;
      if (used + pts > rules.dailyCap) pts = (rules.dailyCap - used).clamp(0, pts);
      perDay[day] = used + pts;
      out.add(ScoredResult(r, pts, firstClear: first, capped: capped));
    }
    return out;
  }

  static int total(Iterable<GameResult> results, {ScoringRules rules = ScoringRules.standard}) =>
      score(results, rules: rules).fold(0, (a, s) => a + s.points);

  static BrainProgressSummary summarize(
    Iterable<GameResult> results, {
    required DateTime now,
    ScoringRules rules = ScoringRules.standard,
  }) {
    final scored = score(results, rules: rules);
    final pointsByGame = <BrainGame, int>{};
    final acc = <BrainGame, List<double>>{};
    final best = <BrainGame, int>{};
    final highest = <BrainGame, (GameDifficulty, int)>{};
    for (final s in scored) {
      final r = s.result;
      if (!r.completed) continue;
      pointsByGame[r.game] = (pointsByGame[r.game] ?? 0) + s.points;
      (acc[r.game] ??= []).add(r.accuracy);
      if (r.score > (best[r.game] ?? -1)) best[r.game] = r.score;
      final h = highest[r.game];
      if (h == null || r.difficulty.index > h.$1.index || (r.difficulty == h.$1 && r.level > h.$2)) {
        highest[r.game] = (r.difficulty, r.level);
      }
    }
    final today = TbilisiTime.calendarDay(now);
    final weekly = List<int>.filled(7, 0);
    for (final s in scored) {
      final d = today.difference(TbilisiTime.calendarDay(s.result.playedAt)).inDays;
      if (d >= 0 && d < 7) weekly[6 - d] += s.points;
    }
    return BrainProgressSummary(
      scored: scored,
      totalPoints: scored.fold(0, (a, s) => a + s.points),
      gamesCompleted: scored.where((s) => s.result.completed).length,
      pointsByGame: pointsByGame,
      accuracyByGame: {for (final e in acc.entries) e.key: e.value.reduce((a, b) => a + b) / e.value.length},
      highestLevel: highest,
      bestScoreByGame: best,
      weeklyPoints: weekly,
      badges: BrainBadge.earned(results),
    );
  }
}

/// How a child appears on a leaderboard. Never the legal full name.
enum DisplayNameMode {
  /// Generated "Swift Falcon 7" style name.
  pseudonym,

  /// First name and last-name initial ("ლუკა ბ.").
  firstNameInitial;

  static DisplayNameMode fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => pseudonym);
}

/// Guardian consent for one child in one organization
/// (`clubs/{clubId}/leaderboardConsents/{childId}`). Revocable at any time.
class LeaderboardConsent {
  const LeaderboardConsent({
    required this.orgId,
    required this.childId,
    required this.guardianId,
    required this.granted,
    required this.mode,
    required this.displayName,
    required this.at,
  });

  final String orgId;
  final String childId;
  final String guardianId;
  final bool granted;
  final DisplayNameMode mode;
  final String displayName;
  final DateTime at;

  static String pseudonymFor(String childId) {
    const adj = ['Swift', 'Brave', 'Clever', 'Bright', 'Bold', 'Calm', 'Quick', 'Sharp', 'Lucky', 'Happy'];
    const animal = ['Falcon', 'Tiger', 'Dolphin', 'Wolf', 'Eagle', 'Fox', 'Panda', 'Lynx', 'Owl', 'Bear'];
    var h = 0;
    for (final c in childId.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return '${adj[h % adj.length]} ${animal[(h ~/ 10) % animal.length]} ${h % 90 + 10}';
  }

  static String firstNameInitial(String first, String last) =>
      last.isEmpty ? first : '$first ${String.fromCharCode(last.runes.first)}.';

  Map<String, dynamic> toMap() => {
    'orgId': orgId,
    'childId': childId,
    'guardianId': guardianId,
    'granted': granted,
    'mode': mode.name,
    'displayName': displayName,
    'at': at,
  };

  factory LeaderboardConsent.fromMap(Map<String, dynamic> m) => LeaderboardConsent(
    orgId: m['orgId'] as String? ?? '',
    childId: m['childId'] as String? ?? '',
    guardianId: m['guardianId'] as String? ?? '',
    granted: m['granted'] as bool? ?? false,
    mode: DisplayNameMode.fromName(m['mode'] as String?),
    displayName: m['displayName'] as String? ?? '',
    at: readDate(m['at']),
  );
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.childId,
    required this.displayName,
    required this.points,
    required this.badges,
  });

  final int rank;

  /// Only used to highlight "you"; never shown.
  final String childId;
  final String displayName;
  final int points;
  final int badges;
}

/// One eligible participant (opted in, in the organization).
class LeaderboardParticipant {
  const LeaderboardParticipant({required this.childId, required this.displayName, required this.ageBand});

  final String childId;
  final String displayName;
  final String ageBand;
}

enum LeaderboardUnavailable { disabled, notConsented, tooFewParticipants }

class LeaderboardBoard {
  const LeaderboardBoard({this.entries = const [], this.unavailable, this.ageBand});

  final List<LeaderboardEntry> entries;
  final LeaderboardUnavailable? unavailable;
  final String? ageBand;
}

class LeaderboardService {
  LeaderboardService._();

  static DateTime periodStart(LeaderboardPeriod p, DateTime now) {
    final d = TbilisiTime.calendarDay(now);
    return switch (p) {
      LeaderboardPeriod.week => TbilisiTime.at(d.year, d.month, d.day - (d.weekday - 1)),
      LeaderboardPeriod.month => TbilisiTime.at(d.year, d.month, 1),
      LeaderboardPeriod.allTime => DateTime.utc(2000),
    };
  }

  /// Server-side ranking (the demo backend and the Cloud Function both call
  /// the same logic). Tie-break: points desc, then whoever reached the total
  /// first, then a stable id order — no ties are left ambiguous.
  static List<LeaderboardEntry> rank({
    required Iterable<LeaderboardParticipant> participants,
    required Iterable<GameResult> results,
    required LeaderboardSettings settings,
    required LeaderboardPeriod period,
    required DateTime now,
    Set<BrainGame>? games,
    ScoringRules rules = ScoringRules.standard,
  }) {
    final from = periodStart(period, now);
    final allowed = (games == null || games.isEmpty)
        ? settings.effectiveGames
        : games.intersection(settings.effectiveGames);
    final byChild = <String, List<GameResult>>{};
    for (final r in results) {
      (byChild[r.childId] ??= []).add(r);
    }
    final rows = <(LeaderboardParticipant, int, DateTime, int)>[];
    for (final p in participants) {
      // Scoring runs over the full history (first-clear and repeat state),
      // then only the period's points are summed.
      final scored = ScoringService.score(byChild[p.childId] ?? const [], rules: rules);
      var pts = 0;
      var reached = DateTime.utc(2000);
      for (final s in scored) {
        if (s.points == 0 || !allowed.contains(s.result.game) || s.result.playedAt.isBefore(from)) continue;
        pts += s.points;
        reached = s.result.playedAt;
      }
      rows.add((p, pts, reached, BrainBadge.earned(byChild[p.childId] ?? const []).length));
    }
    rows.sort((a, b) {
      if (a.$2 != b.$2) return b.$2.compareTo(a.$2);
      if (a.$3 != b.$3) return a.$3.compareTo(b.$3);
      return a.$1.childId.compareTo(b.$1.childId);
    });
    return [
      for (var i = 0; i < rows.length; i++)
        LeaderboardEntry(
          rank: i + 1,
          childId: rows[i].$1.childId,
          displayName: rows[i].$1.displayName,
          points: rows[i].$2,
          badges: rows[i].$4,
        ),
    ];
  }

  /// The board a viewer may see: own age band only (when configured), and
  /// nothing at all below the minimum participant count.
  static LeaderboardBoard boardFor({
    required String viewerChildId,
    required bool orgEnabled,
    required bool viewerConsented,
    required String viewerAgeBand,
    required Iterable<LeaderboardParticipant> participants,
    required Iterable<GameResult> results,
    required LeaderboardSettings settings,
    required LeaderboardPeriod period,
    required DateTime now,
    Set<BrainGame>? games,
  }) {
    if (!orgEnabled) return const LeaderboardBoard(unavailable: LeaderboardUnavailable.disabled);
    if (!viewerConsented) return const LeaderboardBoard(unavailable: LeaderboardUnavailable.notConsented);
    final pool = settings.byAgeBand
        ? participants.where((p) => p.ageBand == viewerAgeBand).toList()
        : participants.toList();
    if (pool.length < settings.minParticipants) {
      return LeaderboardBoard(unavailable: LeaderboardUnavailable.tooFewParticipants, ageBand: viewerAgeBand);
    }
    return LeaderboardBoard(
      entries: rank(participants: pool, results: results, settings: settings, period: period, now: now, games: games),
      ageBand: settings.byAgeBand ? viewerAgeBand : null,
    );
  }
}
