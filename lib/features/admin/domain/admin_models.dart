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

/// Certificate compliance per group — counts only, no names or documents.
class GroupCompliance {
  const GroupCompliance({
    required this.groupId,
    required this.groupName,
    required this.clubId,
    this.valid = 0,
    this.expiring = 0,
    this.expired = 0,
    this.missing = 0,
  });

  final String groupId;
  final String groupName;
  final String clubId;
  final int valid;
  final int expiring;
  final int expired;
  final int missing;

  factory GroupCompliance.fromMap(Map m) => GroupCompliance(
    groupId: m['groupId'] as String? ?? '',
    groupName: m['groupName'] as String? ?? '',
    clubId: m['clubId'] as String? ?? '',
    valid: (m['valid'] as num?)?.toInt() ?? 0,
    expiring: (m['expiring'] as num?)?.toInt() ?? 0,
    expired: (m['expired'] as num?)?.toInt() ?? 0,
    missing: (m['missing'] as num?)?.toInt() ?? 0,
  );
}

/// Attendance per group for one month (aggregates only).
class GroupAttendanceRow {
  const GroupAttendanceRow({
    required this.groupId,
    required this.groupName,
    required this.clubId,
    required this.sessions,
    required this.present,
    required this.recorded,
    required this.members,
  });

  final String groupId;
  final String groupName;
  final String clubId;
  final int sessions;
  final int present;
  final int recorded;
  final int members;

  double? get rate => recorded == 0 ? null : present / recorded;
}

class PlanOverview {
  const PlanOverview({
    required this.planId,
    required this.title,
    required this.typeName,
    required this.statusName,
    required this.groupNames,
    required this.coachName,
    required this.exercises,
    required this.startDate,
  });

  final String planId;
  final String title;
  final String typeName;
  final String statusName;
  final List<String> groupNames;
  final String coachName;
  final int exercises;
  final DateTime startDate;
}

/// v1.4: one authorized parent/coach download of a coach media post.
class MediaDownloadRow {
  const MediaDownloadRow({
    required this.postId,
    required this.userId,
    required this.userName,
    required this.role,
    required this.groupId,
    required this.mediaType,
    required this.at,
  });

  final String postId;
  final String userId;
  final String userName;
  final String role;
  final String? groupId;
  final String mediaType;
  final DateTime at;
}

abstract interface class AdminRepository {
  Future<List<GroupCompliance>> compliance();
  Future<List<GroupAttendanceRow>> attendanceReport({required int year, required int month});
  Stream<List<PlanOverview>> watchPlans();

  /// Club admin of the group's club / platform admin (financial permissions).
  Future<void> setPaymentManagers(String groupId, List<String> coachIds);

  /// v1.4 media policy: club admin of the group's club / platform admin.
  Future<void> setMediaDownloads(String groupId, {required bool enabled});

  /// v1.4 media download audit (scoped to the admin's clubs).
  Stream<List<MediaDownloadRow>> watchMediaDownloads();

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

  /// v1.9.1: organization admin edits a group of their organization.
  Future<void> updateGroupDetails(
    String groupId, {
    String? name,
    List<String>? coachIds,
    int? ageMin,
    int? ageMax,
    int? capacity,
    bool clearCapacity = false,
    String? scheduleNote,
  });

  /// v1.9.1: minimal roster for an organization admin of the group's club —
  /// first name, last-name initial and birth year only (data minimisation;
  /// admins still never read child records directly).
  Future<List<AdminRosterEntry>> groupRoster(String groupId);

  /// Removes a child from a group (organization admin). History is kept.
  Future<void> removeGroupMember(String groupId, String childId);

  Stream<List<ContentReport>> watchReports();
  Future<void> moderate(String reportId, ModerationDecision decision);

  Stream<List<AuditEntry>> watchAudit();

  /// Platform admins only: current admins (platform + club).
  Stream<List<AppUser>> watchAdmins();

  /// Platform admins only.
  Future<void> setAdminRole(String uid, AdminRole? role, {List<String> clubIds});
}

/// One row of [AdminRepository.groupRoster].
class AdminRosterEntry {
  const AdminRosterEntry({
    required this.childId,
    required this.firstName,
    required this.lastInitial,
    required this.birthYear,
  });

  factory AdminRosterEntry.fromMap(Map<String, dynamic> m) => AdminRosterEntry(
    childId: m['childId'] as String? ?? '',
    firstName: m['firstName'] as String? ?? '',
    lastInitial: m['lastInitial'] as String? ?? '',
    birthYear: (m['birthYear'] as num?)?.toInt() ?? 0,
  );

  final String childId;
  final String firstName;
  final String lastInitial;
  final int birthYear;

  String get displayName => lastInitial.isEmpty ? firstName : '$firstName $lastInitial.';
}
