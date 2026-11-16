import '../../../core/utils/dates.dart';

/// Parent intent before a training (v1.2). Never counted as attendance.
enum RsvpResponse {
  yes,
  no,
  maybe;

  static RsvpResponse fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => maybe);
}

/// Training or match (v1.7: RSVP and attendance cover both).
enum EventType {
  training,
  match;

  static EventType fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => training);
}

/// One guardian's answer for one child (v1.7, multiple guardians).
class GuardianResponse {
  const GuardianResponse({required this.response, required this.version, required this.at, this.reason});

  final RsvpResponse response;

  /// Event schedule version the answer was given for.
  final int version;
  final DateTime at;
  final String? reason;

  Map<String, dynamic> toMap() => {'response': response.name, 'version': version, 'at': at, 'reason': reason};

  factory GuardianResponse.fromMap(Object? m) {
    final map = m is Map ? m : const {};
    return GuardianResponse(
      response: RsvpResponse.fromName(map['response'] as String?),
      version: (map['version'] as num?)?.toInt() ?? 1,
      at: readDateOrNull(map['at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      reason: map['reason'] as String?,
    );
  }
}

/// Child-level attendance expectation for one event (`rsvps/{eventId}_{childId}`).
///
/// Several guardians may answer; each answer is kept in [guardianResponses]
/// (and appended to `rsvps/{id}/history`). The explicit child-level rule:
/// the most recent answer for the CURRENT schedule version is the child's
/// expectation ([response]/[parentId] mirror it). The child is counted once.
class Rsvp {
  const Rsvp({
    required this.trainingId,
    required this.groupId,
    required this.childId,
    required this.parentId,
    required this.response,
    required this.updatedAt,
    this.reason,
    this.eventType = EventType.training,
    this.scheduleVersion = 1,
    this.guardianResponses = const {},
  });

  /// Event id (training or match — see [eventType]). Name kept for v1.2 data.
  final String trainingId;
  final String groupId;
  final String childId;
  final String parentId;
  final RsvpResponse response;
  final String? reason;
  final DateTime updatedAt;
  final EventType eventType;

  /// Schedule version of the event this answer refers to. Lower than the
  /// event's current version = needs reconfirmation (the old answer stays).
  final int scheduleVersion;
  final Map<String, GuardianResponse> guardianResponses;

  String get eventId => trainingId;

  bool needsReconfirmation(int currentVersion) => scheduleVersion < currentVersion;

  /// Guardians disagree on the current version (shown to the coach).
  bool conflictingFor(int currentVersion) =>
      guardianResponses.values.where((g) => g.version == currentVersion).map((g) => g.response).toSet().length > 1;

  static String docId(String trainingId, String childId) => '${trainingId}_$childId';
  String get id => docId(trainingId, childId);

  static const maxReason = 200;

  Map<String, dynamic> toMap() => {
    'trainingId': trainingId,
    'eventId': trainingId,
    'eventType': eventType.name,
    'groupId': groupId,
    'childId': childId,
    'parentId': parentId,
    'response': response.name,
    'reason': reason,
    'updatedAt': updatedAt,
    'scheduleVersion': scheduleVersion,
    'guardianResponses': {for (final e in guardianResponses.entries) e.key: e.value.toMap()},
  };

  factory Rsvp.fromMap(Map<String, dynamic> m) => Rsvp(
    trainingId: (m['eventId'] ?? m['trainingId']) as String,
    groupId: m['groupId'] as String? ?? '',
    childId: m['childId'] as String,
    parentId: m['parentId'] as String? ?? '',
    response: RsvpResponse.fromName(m['response'] as String?),
    reason: m['reason'] as String?,
    updatedAt: readDate(m['updatedAt']),
    eventType: EventType.fromName(m['eventType'] as String?),
    scheduleVersion: (m['scheduleVersion'] as num?)?.toInt() ?? 1,
    guardianResponses: {
      for (final e in ((m['guardianResponses'] as Map?) ?? const {}).entries)
        e.key.toString(): GuardianResponse.fromMap(e.value),
    },
  );

  /// Applies one guardian's answer and returns the new child-level record.
  Rsvp withGuardianAnswer({
    required String guardianId,
    required RsvpResponse answer,
    required int version,
    required DateTime at,
    String? reason,
  }) {
    final responses = {
      ...guardianResponses,
      guardianId: GuardianResponse(response: answer, version: version, at: at, reason: reason),
    };
    return Rsvp(
      trainingId: trainingId,
      groupId: groupId,
      childId: childId,
      parentId: guardianId,
      response: answer,
      reason: reason,
      updatedAt: at,
      eventType: eventType,
      scheduleVersion: version,
      guardianResponses: responses,
    );
  }
}

/// One entry of the append-only RSVP history (`rsvps/{id}/history/{n}`).
class RsvpHistoryEntry {
  const RsvpHistoryEntry({
    required this.rsvpId,
    required this.guardianId,
    required this.response,
    required this.version,
    required this.at,
    this.reason,
  });

  final String rsvpId;
  final String guardianId;
  final RsvpResponse response;
  final int version;
  final DateTime at;
  final String? reason;
}

/// Child-level RSVP state the coach sees.
enum RsvpState { confirmed, declined, uncertain, notResponded, needsReconfirmation }

/// Counters for one event over its group members. Each child counts once.
class RsvpSummary {
  const RsvpSummary(this.byChild);

  final Map<String, RsvpState> byChild;

  int count(RsvpState s) => byChild.values.where((v) => v == s).length;

  static RsvpState stateOf(Rsvp? r, int currentVersion) {
    if (r == null) return RsvpState.notResponded;
    if (r.needsReconfirmation(currentVersion)) return RsvpState.needsReconfirmation;
    return switch (r.response) {
      RsvpResponse.yes => RsvpState.confirmed,
      RsvpResponse.no => RsvpState.declined,
      RsvpResponse.maybe => RsvpState.uncertain,
    };
  }

  static RsvpSummary compute(Iterable<String> memberChildIds, Iterable<Rsvp> rsvps, int currentVersion) {
    final byChild = {for (final r in rsvps) r.childId: r};
    return RsvpSummary({for (final c in memberChildIds.toSet()) c: stateOf(byChild[c], currentVersion)});
  }
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
    this.eventType = EventType.training,
  });

  /// Event id (training or match — see [eventType]).
  final String trainingId;
  final EventType eventType;
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
    'eventId': trainingId,
    'eventType': eventType.name,
    'groupId': groupId,
    'childId': childId,
    'status': status.name,
    'markedBy': markedBy,
    'markedAt': markedAt,
    'note': note,
  };

  factory AttendanceRecord.fromMap(Map<String, dynamic> m) => AttendanceRecord(
    trainingId: (m['eventId'] ?? m['trainingId']) as String,
    eventType: EventType.fromName(m['eventType'] as String?),
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

  /// v1.7 append-only answer history of one child for one event.
  Stream<List<RsvpHistoryEntry>> watchRsvpHistory(String eventId, String childId);

  /// Coach of the training's group. `status == null` clears the mark.
  Future<void> mark({required String trainingId, required String childId, AttendanceStatus? status, String? note});
  Future<void> markAll({required String trainingId, required AttendanceStatus status, bool onlyUnmarked = true});

  /// Saves several marks at once (null = clear). One batch in production.
  Future<void> saveBatch({required String trainingId, required Map<String, AttendanceStatus?> marks});
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
