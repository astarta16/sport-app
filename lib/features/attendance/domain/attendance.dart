import '../../../core/utils/dates.dart';

/// Parent intent before a training (v1.2). Never counted as attendance.
enum RsvpResponse {
  yes,
  no,
  maybe;

  static RsvpResponse fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => maybe);
}

class Rsvp {
  const Rsvp({
    required this.trainingId,
    required this.groupId,
    required this.childId,
    required this.parentId,
    required this.response,
    required this.updatedAt,
    this.reason,
  });

  final String trainingId;
  final String groupId;
  final String childId;
  final String parentId;
  final RsvpResponse response;
  final String? reason;
  final DateTime updatedAt;

  static String docId(String trainingId, String childId) => '${trainingId}_$childId';
  String get id => docId(trainingId, childId);

  static const maxReason = 200;

  Map<String, dynamic> toMap() => {
    'trainingId': trainingId,
    'groupId': groupId,
    'childId': childId,
    'parentId': parentId,
    'response': response.name,
    'reason': reason,
    'updatedAt': updatedAt,
  };

  factory Rsvp.fromMap(Map<String, dynamic> m) => Rsvp(
    trainingId: m['trainingId'] as String,
    groupId: m['groupId'] as String? ?? '',
    childId: m['childId'] as String,
    parentId: m['parentId'] as String? ?? '',
    response: RsvpResponse.fromName(m['response'] as String?),
    reason: m['reason'] as String?,
    updatedAt: readDate(m['updatedAt']),
  );
}

/// Coach-recorded actual attendance. "Not marked" = no record.
enum AttendanceStatus {
  present,
  absent,
  excused;

  static AttendanceStatus fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => absent);
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.trainingId,
    required this.groupId,
    required this.childId,
    required this.status,
    required this.markedBy,
    required this.markedAt,
    this.note,
  });

  final String trainingId;
  final String groupId;
  final String childId;
  final AttendanceStatus status;
  final String markedBy;
  final DateTime markedAt;
  final String? note;

  static String docId(String trainingId, String childId) => '${trainingId}_$childId';
  String get id => docId(trainingId, childId);

  Map<String, dynamic> toMap() => {
    'trainingId': trainingId,
    'groupId': groupId,
    'childId': childId,
    'status': status.name,
    'markedBy': markedBy,
    'markedAt': markedAt,
    'note': note,
  };

  factory AttendanceRecord.fromMap(Map<String, dynamic> m) => AttendanceRecord(
    trainingId: m['trainingId'] as String,
    groupId: m['groupId'] as String? ?? '',
    childId: m['childId'] as String,
    status: AttendanceStatus.fromName(m['status'] as String?),
    markedBy: m['markedBy'] as String? ?? '',
    markedAt: readDate(m['markedAt']),
    note: m['note'] as String?,
  );
}

/// Structured, constructive coach feedback (v1.2 progress).
enum FeedbackCategory { technique, discipline, teamwork, effort, improvement }

class CoachFeedback {
  const CoachFeedback({
    required this.id,
    required this.childId,
    required this.groupId,
    required this.coachId,
    required this.createdAt,
    required this.ratings,
    this.trainingId,
    this.comment,
    this.coachName = '',
  });

  final String id;
  final String childId;
  final String groupId;
  final String coachId;
  final String coachName;
  final String? trainingId;
  final DateTime createdAt;

  /// 1–5 per category; only the rated categories are present.
  final Map<FeedbackCategory, int> ratings;
  final String? comment;

  static const maxComment = 500;

  static String? validate(Map<FeedbackCategory, int> ratings, String? comment) {
    if (ratings.isEmpty && (comment ?? '').trim().isEmpty) return 'feedbackEmpty';
    if (ratings.values.any((r) => r < 1 || r > 5)) return 'feedbackRating';
    if ((comment ?? '').length > maxComment) return 'validationTooLong';
    return null;
  }

  Map<String, dynamic> toMap() => {
    'childId': childId,
    'groupId': groupId,
    'coachId': coachId,
    'coachName': coachName,
    'trainingId': trainingId,
    'createdAt': createdAt,
    'ratings': {for (final e in ratings.entries) e.key.name: e.value},
    'comment': comment,
    'visibleToParent': true,
  };

  factory CoachFeedback.fromMap(String id, Map<String, dynamic> m) => CoachFeedback(
    id: id,
    childId: m['childId'] as String,
    groupId: m['groupId'] as String? ?? '',
    coachId: m['coachId'] as String? ?? '',
    coachName: m['coachName'] as String? ?? '',
    trainingId: m['trainingId'] as String?,
    createdAt: readDate(m['createdAt']),
    ratings: {
      for (final e in ((m['ratings'] as Map?) ?? const {}).entries)
        for (final c in FeedbackCategory.values)
          if (c.name == e.key) c: (e.value as num).toInt(),
    },
    comment: m['comment'] as String?,
  );
}

enum AchievementKind {
  firstTraining,
  attended5,
  attended10,
  attended25,
  attended50,
  attended100,
  perfectMonth,
  streak3Months,
}

class Achievement {
  const Achievement(this.kind, this.achievedOn);

  final AchievementKind kind;
  final DateTime achievedOn;
}

/// Monthly bucket of recorded attendance.
class MonthStats {
  const MonthStats({required this.year, required this.month, this.present = 0, this.absent = 0, this.excused = 0});

  final int year;
  final int month;
  final int present;
  final int absent;
  final int excused;

  int get recorded => present + absent + excused;

  /// Present / recorded, or null when nothing was recorded.
  double? get rate => recorded == 0 ? null : present / recorded;
}

/// Pure statistics over coach-recorded attendance only. RSVPs are never
/// counted (a "will attend" is not attendance). Mirrors functions/src/lib/attendance.ts.
class AttendanceStats {
  const AttendanceStats({
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalExcused,
    required this.months,
    required this.achievements,
  });

  final int totalPresent;
  final int totalAbsent;
  final int totalExcused;

  /// Oldest first.
  final List<MonthStats> months;
  final List<Achievement> achievements;

  int get recorded => totalPresent + totalAbsent + totalExcused;
  double? get rate => recorded == 0 ? null : totalPresent / recorded;

  MonthStats monthOf(DateTime d) {
    final w = TbilisiTime.wallClock(d);
    return months.firstWhere(
      (m) => m.year == w.year && m.month == w.month,
      orElse: () => MonthStats(year: w.year, month: w.month),
    );
  }

  /// [trainingStarts] maps training id → start instant, used to order the
  /// records and bucket them by Tbilisi month.
  static AttendanceStats compute(Iterable<AttendanceRecord> records, Map<String, DateTime> trainingStarts) {
    final list = records.where((r) => trainingStarts.containsKey(r.trainingId)).toList()
      ..sort((a, b) => trainingStarts[a.trainingId]!.compareTo(trainingStarts[b.trainingId]!));
    final buckets = <(int, int), List<int>>{};
    var p = 0, a = 0, e = 0;
    final achievements = <Achievement>[];
    const milestones = {
      1: AchievementKind.firstTraining,
      5: AchievementKind.attended5,
      10: AchievementKind.attended10,
      25: AchievementKind.attended25,
      50: AchievementKind.attended50,
      100: AchievementKind.attended100,
    };
    for (final r in list) {
      final when = trainingStarts[r.trainingId]!;
      final w = TbilisiTime.wallClock(when);
      final b = buckets.putIfAbsent((w.year, w.month), () => [0, 0, 0]);
      switch (r.status) {
        case AttendanceStatus.present:
          p++;
          b[0]++;
          final kind = milestones[p];
          if (kind != null) achievements.add(Achievement(kind, when));
        case AttendanceStatus.absent:
          a++;
          b[1]++;
        case AttendanceStatus.excused:
          e++;
          b[2]++;
      }
    }
    final keys = buckets.keys.toList()..sort((x, y) => x.$1 != y.$1 ? x.$1 - y.$1 : x.$2 - y.$2);
    final months = [
      for (final k in keys)
        MonthStats(year: k.$1, month: k.$2, present: buckets[k]![0], absent: buckets[k]![1], excused: buckets[k]![2]),
    ];
    var streak = 0;
    (int, int)? prev;
    var streakAwarded = false;
    for (final m in months) {
      final perfect = m.recorded >= 4 && m.present == m.recorded;
      if (perfect) achievements.add(Achievement(AchievementKind.perfectMonth, DateTime.utc(m.year, m.month, 28)));
      final consecutive =
          prev != null &&
          ((m.year == prev.$1 && m.month == prev.$2 + 1) || (m.year == prev.$1 + 1 && prev.$2 == 12 && m.month == 1));
      final good = m.recorded >= 4 && (m.rate ?? 0) >= 0.75;
      streak = good ? (consecutive && streak > 0 ? streak + 1 : 1) : 0;
      if (streak >= 3 && !streakAwarded) {
        achievements.add(Achievement(AchievementKind.streak3Months, DateTime.utc(m.year, m.month, 28)));
        streakAwarded = true;
      }
      prev = (m.year, m.month);
    }
    return AttendanceStats(
      totalPresent: p,
      totalAbsent: a,
      totalExcused: e,
      months: months,
      achievements: achievements,
    );
  }
}

abstract interface class AttendanceRepository {
  /// Parent RSVP for one child; allowed until the training starts.
  Future<void> respond({
    required String trainingId,
    required String childId,
    required RsvpResponse response,
    String? reason,
  });
  Stream<List<Rsvp>> watchRsvpsForTraining(String trainingId);
  Stream<List<Rsvp>> watchRsvpsForChild(String childId);

  /// Coach of the training's group. `status == null` clears the mark.
  Future<void> mark({required String trainingId, required String childId, AttendanceStatus? status, String? note});
  Future<void> markAll({required String trainingId, required AttendanceStatus status, bool onlyUnmarked = true});
  Stream<List<AttendanceRecord>> watchForTraining(String trainingId);
  Stream<List<AttendanceRecord>> watchForChild(String childId);
  Stream<List<AttendanceRecord>> watchForGroup(String groupId);

  Future<void> addFeedback({
    required String childId,
    required String groupId,
    required Map<FeedbackCategory, int> ratings,
    String? comment,
    String? trainingId,
  });
  Stream<List<CoachFeedback>> watchFeedback(String childId);
}
