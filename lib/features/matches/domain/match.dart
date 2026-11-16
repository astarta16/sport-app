import '../../../core/utils/dates.dart';
import '../../trainings/domain/training.dart';

enum MatchType {
  friendly,
  league,
  tournament;

  static MatchType fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => friendly);
}

enum HomeAway {
  home,
  away,
  neutral;

  static HomeAway fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => home);
}

enum MatchStatus {
  scheduled,
  cancelled,
  moved,
  played;

  static MatchStatus fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => scheduled);

  bool get isActive => this == scheduled || this == moved;
}

enum MatchOutcome {
  win,
  draw,
  loss;

  static MatchOutcome of(int our, int opponent) => our > opponent ? win : (our < opponent ? loss : draw);
}

/// v1.5 final score, always from the coached team's side. Written only by
/// the server (`recordMatchResult`): trusted times, correction history.
class MatchResult {
  const MatchResult({
    required this.ourScore,
    required this.opponentScore,
    required this.completedAt,
    this.summary,
    this.version = 1,
    this.recordedBy,
  });

  final int ourScore;
  final int opponentScore;
  final String? summary;
  final DateTime completedAt;
  final int version;
  final String? recordedBy;

  /// Derived, never stored independently of the score.
  MatchOutcome get outcome => MatchOutcome.of(ourScore, opponentScore);

  bool get corrected => version > 1;

  static MatchResult? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final our = (raw['ourScore'] as num?)?.toInt();
    final their = (raw['opponentScore'] as num?)?.toInt();
    if (our == null || their == null) return null;
    return MatchResult(
      ourScore: our,
      opponentScore: their,
      summary: raw['summary'] as String?,
      completedAt: readDateOrNull(raw['completedAt']) ?? DateTime.now(),
      version: (raw['version'] as num?)?.toInt() ?? 1,
      recordedBy: raw['recordedBy'] as String?,
    );
  }

  static const maxScore = 999;
  static const maxSummary = 1000;

  /// Mirrors functions/src/lib/matchResults.ts validateResult.
  static List<String> validate({
    required int? our,
    required int? their,
    required SportMatch match,
    required DateTime now,
    String? summary,
    DateTime? completedAt,
  }) => [
    if (match.status == MatchStatus.cancelled) 'resultCancelled',
    if (match.startAt.isAfter(now)) 'resultNotStarted',
    if (our == null || their == null || our < 0 || their < 0 || our > maxScore || their > maxScore) 'resultScore',
    if ((summary ?? '').length > maxSummary) 'descriptionTooLong',
    if (completedAt != null &&
        (completedAt.isBefore(match.startAt) || completedAt.isAfter(now.add(const Duration(minutes: 5)))))
      'resultCompletedAt',
  ];
}

/// A game against another team (v1.1 §8); v1.5 adds the final [result].
class SportMatch {
  const SportMatch({
    required this.id,
    required this.groupId,
    required this.venueId,
    required this.startAt,
    required this.opponentName,
    required this.createdBy,
    this.clubId = '',
    this.durationMin = 90,
    this.matchType = MatchType.friendly,
    this.homeAway = HomeAway.home,
    this.description,
    this.status = MatchStatus.scheduled,
    this.cancelReasonCode,
    this.cancelReason,
    this.cancelledAt,
    this.cancelledBy,
    this.previousStartAt,
    this.updatedAt,
    this.result,
    this.scheduleVersion = 1,
    this.previousVenueId,
  });

  final String id;
  final String groupId;

  /// v1.7: bumped on every material change (date, time or location).
  final int scheduleVersion;
  final String? previousVenueId;
  final String clubId;
  final String venueId;
  final DateTime startAt;
  final int durationMin;
  final String opponentName;
  final MatchType matchType;
  final HomeAway homeAway;
  final String? description;
  final MatchStatus status;
  final CancelReasonCode? cancelReasonCode;
  final String? cancelReason;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final DateTime? previousStartAt;
  final String createdBy;
  final DateTime? updatedAt;

  /// v1.5 final score (server-written).
  final MatchResult? result;

  DateTime get endAt => startAt.add(Duration(minutes: durationMin));

  SportMatch copyWith({
    String? venueId,
    DateTime? startAt,
    String? opponentName,
    MatchType? matchType,
    HomeAway? homeAway,
    String? description,
    MatchStatus? status,
    CancelReasonCode? cancelReasonCode,
    String? cancelReason,
    DateTime? cancelledAt,
    String? cancelledBy,
    DateTime? previousStartAt,
    DateTime? updatedAt,
    MatchResult? result,
    int? scheduleVersion,
    String? previousVenueId,
  }) => SportMatch(
    id: id,
    groupId: groupId,
    clubId: clubId,
    venueId: venueId ?? this.venueId,
    startAt: startAt ?? this.startAt,
    durationMin: durationMin,
    opponentName: opponentName ?? this.opponentName,
    matchType: matchType ?? this.matchType,
    homeAway: homeAway ?? this.homeAway,
    description: description ?? this.description,
    status: status ?? this.status,
    cancelReasonCode: cancelReasonCode ?? this.cancelReasonCode,
    cancelReason: cancelReason ?? this.cancelReason,
    cancelledAt: cancelledAt ?? this.cancelledAt,
    cancelledBy: cancelledBy ?? this.cancelledBy,
    previousStartAt: previousStartAt ?? this.previousStartAt,
    createdBy: createdBy,
    updatedAt: updatedAt ?? this.updatedAt,
    result: result ?? this.result,
    scheduleVersion: scheduleVersion ?? this.scheduleVersion,
    previousVenueId: previousVenueId ?? this.previousVenueId,
  );

  Map<String, dynamic> toMap() => {
    'scheduleVersion': scheduleVersion,
    'previousVenueId': previousVenueId,
    'groupId': groupId,
    'clubId': clubId,
    'venueId': venueId,
    'startAt': startAt,
    'durationMin': durationMin,
    'opponentName': opponentName,
    'matchType': matchType.name,
    'homeAway': homeAway.name,
    'description': description,
    'status': status.name,
    'cancelReasonCode': cancelReasonCode?.name,
    'cancelReason': cancelReason,
    'cancelledAt': cancelledAt,
    'cancelledBy': cancelledBy,
    'previousStartAt': previousStartAt,
    'createdBy': createdBy,
    'updatedAt': updatedAt,
  };

  factory SportMatch.fromMap(String id, Map<String, dynamic> m) => SportMatch(
    id: id,
    groupId: m['groupId'] as String? ?? '',
    clubId: m['clubId'] as String? ?? '',
    venueId: m['venueId'] as String? ?? '',
    startAt: readDate(m['startAt']),
    durationMin: (m['durationMin'] as num?)?.toInt() ?? 90,
    opponentName: m['opponentName'] as String? ?? '',
    matchType: MatchType.fromName(m['matchType'] as String?),
    homeAway: HomeAway.fromName(m['homeAway'] as String?),
    description: m['description'] as String?,
    status: MatchStatus.fromName(m['status'] as String?),
    cancelReasonCode: CancelReasonCode.fromName(m['cancelReasonCode'] as String?),
    cancelReason: m['cancelReason'] as String?,
    cancelledAt: readDateOrNull(m['cancelledAt']),
    cancelledBy: m['cancelledBy'] as String?,
    previousStartAt: readDateOrNull(m['previousStartAt']),
    createdBy: m['createdBy'] as String? ?? '',
    updatedAt: readDateOrNull(m['updatedAt']),
    result: MatchResult.fromMap(m['result']),
    scheduleVersion: (m['scheduleVersion'] as num?)?.toInt() ?? 1,
    previousVenueId: m['previousVenueId'] as String?,
  );
}

class MatchDraft {
  const MatchDraft({
    required this.groupId,
    required this.venueId,
    required this.startAt,
    required this.opponentName,
    this.matchType = MatchType.friendly,
    this.homeAway = HomeAway.home,
    this.description,
    this.durationMin = 90,
  });

  final String groupId;
  final String venueId;
  final DateTime startAt;
  final String opponentName;
  final MatchType matchType;
  final HomeAway homeAway;
  final String? description;
  final int durationMin;

  static List<String> validate(MatchDraft d, {required DateTime now, bool isEdit = false}) => [
    if (d.venueId.isEmpty) 'venueRequired',
    if (d.opponentName.trim().length < 2) 'opponentRequired',
    if (d.opponentName.trim().length > 80) 'validationTooLong',
    if ((d.description ?? '').length > 1000) 'descriptionTooLong',
    if (!isEdit && d.startAt.isBefore(now.subtract(const Duration(minutes: 5)))) 'startInPast',
  ];
}

abstract interface class MatchesRepository {
  Stream<List<SportMatch>> watchForGroups(List<String> groupIds);
  Stream<SportMatch?> watchMatch(String id);
  Future<SportMatch> create(MatchDraft draft);
  Future<SportMatch> update(String id, MatchDraft draft);

  /// Reason is mandatory (v1.1 §7).
  Future<void> cancel(String id, CancelReason reason);
  Future<void> markPlayed(String id);

  /// v1.5: coach of the group records or corrects the final score. Parents
  /// are notified on the first result; corrections are audited.
  Future<void> recordResult(String id, {required int our, required int their, String? summary, DateTime? completedAt});

  /// v1.5: correction history (coach of the group), newest first.
  Future<List<MatchResultChange>> resultHistory(String id);
}

class MatchResultChange {
  const MatchResultChange({required this.version, required this.by, required this.at, this.from, this.to});

  final int version;
  final String by;
  final DateTime at;
  final (int, int)? from;
  final (int, int)? to;
}
