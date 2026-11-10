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

/// A game against another team (v1.1 §8). Results are out of scope.
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
  });

  final String id;
  final String groupId;
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
  );

  Map<String, dynamic> toMap() => {
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
}
