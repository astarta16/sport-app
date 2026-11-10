import '../../../core/utils/dates.dart';
import '../../authentication/domain/app_user.dart';
import '../../clubs/domain/club.dart';
import '../../groups/domain/group.dart';
import '../../moderation/domain/report.dart';
import '../../sports/domain/sport.dart';

/// Dashboard aggregates (server `count()` in production, scoped to the
/// admin's clubs for club admins).
class AdminStats {
  const AdminStats({
    this.parents = 0,
    this.children = 0,
    this.coaches = 0,
    this.clubs = 0,
    this.activeGroups = 0,
    this.upcomingTrainings = 0,
    this.upcomingMatches = 0,
    this.pendingCoaches = 0,
    this.pendingRequests = 0,
    this.openReports = 0,
  });

  final int parents;
  final int children;
  final int coaches;
  final int clubs;
  final int activeGroups;
  final int upcomingTrainings;
  final int upcomingMatches;
  final int pendingCoaches;
  final int pendingRequests;
  final int openReports;

  factory AdminStats.fromMap(Map<String, dynamic> m) {
    int n(String k) => (m[k] as num?)?.toInt() ?? 0;
    return AdminStats(
      parents: n('parents'),
      children: n('children'),
      coaches: n('coaches'),
      clubs: n('clubs'),
      activeGroups: n('activeGroups'),
      upcomingTrainings: n('upcomingTrainings'),
      upcomingMatches: n('upcomingMatches'),
      pendingCoaches: n('pendingCoaches'),
      pendingRequests: n('pendingRequests'),
      openReports: n('openReports'),
    );
  }
}

/// Coach as seen by admins: identity, status, clubs. No child data.
class CoachSummary {
  const CoachSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.status,
    required this.clubIds,
    required this.sportIds,
    required this.createdAt,
    this.reason,
    this.groupCount = 0,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final CoachStatus status;
  final String? reason;
  final List<String> clubIds;
  final List<String> sportIds;
  final DateTime createdAt;
  final int groupCount;

  String get fullName => '$firstName $lastName';

  factory CoachSummary.fromUser(AppUser u, {int groupCount = 0}) => CoachSummary(
    id: u.id,
    firstName: u.firstName,
    lastName: u.lastName,
    phone: u.phone,
    status: u.coachStatus ?? CoachStatus.pending,
    reason: u.coachStatusReason,
    clubIds: u.clubIds,
    sportIds: u.sportIds,
    createdAt: u.createdAt,
    groupCount: groupCount,
  );
}

/// Group oversight row (sizes only — no member identities).
class GroupOverview {
  const GroupOverview({
    required this.group,
    required this.coachNames,
    required this.memberCount,
    required this.pendingRequests,
    required this.upcomingTrainings,
    this.scheduleSummary = '',
  });

  final Group group;
  final List<String> coachNames;
  final int memberCount;
  final int pendingRequests;
  final int upcomingTrainings;
  final String scheduleSummary;
}

class ClubOverview {
  const ClubOverview({required this.club, required this.groups, required this.members, required this.coaches});

  final Club club;
  final int groups;
  final int members;
  final int coaches;
}

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.action,
    required this.actorId,
    required this.actorName,
    required this.targetType,
    required this.targetId,
    required this.at,
    this.clubId,
    this.details = const {},
  });

  final String id;
  final String action;
  final String actorId;
  final String actorName;
  final String targetType;
  final String targetId;
  final String? clubId;
  final Map<String, String> details;
  final DateTime at;

  factory AuditEntry.fromMap(String id, Map<String, dynamic> m) => AuditEntry(
    id: id,
    action: m['action'] as String? ?? '',
    actorId: m['actorId'] as String? ?? '',
    actorName: m['actorName'] as String? ?? '',
    targetType: m['targetType'] as String? ?? '',
    targetId: m['targetId'] as String? ?? '',
    clubId: m['clubId'] as String?,
    details: (m['details'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? const {},
    at: readDate(m['at']),
  );
}

class ClubDraft {
  const ClubDraft({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.sportIds,
    this.phone,
    this.description,
  });

  final String name;
  final String address;
  final double lat;
  final double lng;
  final List<String> sportIds;
  final String? phone;
  final String? description;

  static List<String> validate(ClubDraft d) => [
    if (d.name.trim().length < 2) 'validationRequired',
    if (d.address.trim().length < 3) 'validationRequired',
    if (d.lat < 41 || d.lat > 43.6 || d.lng < 40 || d.lng > 46.8) 'locationOutsideGeorgia',
    if (d.sportIds.isEmpty) 'validationSportRequired',
  ];
}

/// Page of results for admin tables.
class AdminPage<T> {
  const AdminPage(this.items, this.total);

  final List<T> items;
  final int total;
}

abstract interface class AdminRepository {
  Future<AdminStats> stats();

  Stream<List<CoachSummary>> watchCoaches();
  Future<void> setCoachStatus(String coachId, CoachStatus status, {String? reason});
  Future<void> assignCoach({required String clubId, required String coachId, required bool assign});

  Stream<List<ClubOverview>> watchClubs();
  Future<Club> upsertClub(ClubDraft draft, {String? clubId});
  Future<void> archiveClub(String clubId, {required bool archived});

  Stream<List<Sport>> watchSports();
  Future<void> upsertSport(Sport sport);

  Stream<List<GroupOverview>> watchGroups();
  Future<void> archiveGroup(String groupId, {required bool archived});

  Stream<List<ContentReport>> watchReports();
  Future<void> moderate(String reportId, ModerationDecision decision);

  Stream<List<AuditEntry>> watchAudit();

  /// Platform admins only.
  Future<void> setAdminRole(String uid, AdminRole? role, {List<String> clubIds});
}
