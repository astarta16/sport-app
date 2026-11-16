import '../../../core/utils/dates.dart';

enum GroupStatus {
  active,
  archived;

  static GroupStatus fromName(String? n) => n == 'archived' ? archived : active;
}

class Group {
  const Group({
    required this.id,
    required this.clubId,
    required this.sportId,
    required this.coachIds,
    required this.name,
    required this.ageMin,
    required this.ageMax,
    this.memberChildIds = const [],
    this.parentIds = const [],
    this.scheduleNote,
    this.inviteCode = '',
    this.createdBy,
    this.status = GroupStatus.active,
    this.paymentManagerIds = const [],
    this.mediaDownloadsEnabled = true,
    this.capacity,
  });

  final String id;
  final String clubId;

  /// v1.9.1: optional maximum number of children (null = no limit).
  final int? capacity;

  bool get isFull => capacity != null && memberChildIds.length >= capacity!;
  final String sportId;
  final List<String> coachIds;
  final String name;
  final int ageMin;
  final int ageMax;
  final List<String> memberChildIds;

  /// Denormalized by a Cloud Function so rules can check parent membership.
  final List<String> parentIds;
  final String? scheduleNote;

  /// 6-character join code, generated server-side (v1.1 §2).
  final String inviteCode;
  final String? createdBy;
  final GroupStatus status;

  /// Coaches explicitly allowed to verify payments (v1.3). Set by admins only.
  final List<String> paymentManagerIds;

  /// v1.4 media policy, set by club admins through the server (updateGroup):
  /// false = parents cannot download this group's photos/videos.
  /// Server-managed, therefore not part of [toMap].
  final bool mediaDownloadsEnabled;

  bool hasCoach(String uid) => coachIds.contains(uid);
  bool hasParent(String uid) => parentIds.contains(uid);
  bool hasChild(String childId) => memberChildIds.contains(childId);
  bool get isActive => status == GroupStatus.active;

  Group copyWith({
    List<String>? memberChildIds,
    List<String>? parentIds,
    List<String>? coachIds,
    String? name,
    int? ageMin,
    int? ageMax,
    String? scheduleNote,
    String? inviteCode,
    GroupStatus? status,
    List<String>? paymentManagerIds,
    int? capacity,
    bool clearCapacity = false,
    bool? mediaDownloadsEnabled,
  }) => Group(
    id: id,
    clubId: clubId,
    sportId: sportId,
    coachIds: coachIds ?? this.coachIds,
    name: name ?? this.name,
    ageMin: ageMin ?? this.ageMin,
    ageMax: ageMax ?? this.ageMax,
    memberChildIds: memberChildIds ?? this.memberChildIds,
    parentIds: parentIds ?? this.parentIds,
    scheduleNote: scheduleNote ?? this.scheduleNote,
    inviteCode: inviteCode ?? this.inviteCode,
    createdBy: createdBy,
    status: status ?? this.status,
    paymentManagerIds: paymentManagerIds ?? this.paymentManagerIds,
    capacity: clearCapacity ? null : (capacity ?? this.capacity),
    mediaDownloadsEnabled: mediaDownloadsEnabled ?? this.mediaDownloadsEnabled,
  );

  Map<String, dynamic> toMap() => {
    'clubId': clubId,
    'sportId': sportId,
    'coachIds': coachIds,
    'name': name,
    'ageMin': ageMin,
    'ageMax': ageMax,
    'memberChildIds': memberChildIds,
    'parentIds': parentIds,
    'scheduleNote': scheduleNote,
    'inviteCode': inviteCode,
    'createdBy': createdBy,
    'status': status.name,
    'paymentManagerIds': paymentManagerIds,
    'capacity': ?capacity,
  };

  factory Group.fromMap(String id, Map<String, dynamic> m) => Group(
    id: id,
    clubId: m['clubId'] as String? ?? '',
    sportId: m['sportId'] as String? ?? '',
    coachIds: readStringList(m['coachIds']),
    name: m['name'] as String? ?? '',
    ageMin: (m['ageMin'] as num?)?.toInt() ?? 0,
    ageMax: (m['ageMax'] as num?)?.toInt() ?? 18,
    memberChildIds: readStringList(m['memberChildIds']),
    parentIds: readStringList(m['parentIds']),
    scheduleNote: m['scheduleNote'] as String?,
    inviteCode: m['inviteCode'] as String? ?? '',
    createdBy: m['createdBy'] as String?,
    status: GroupStatus.fromName(m['status'] as String?),
    paymentManagerIds: readStringList(m['paymentManagerIds']),
    mediaDownloadsEnabled: m['mediaDownloadsEnabled'] as bool? ?? true,
    capacity: (m['capacity'] as num?)?.toInt(),
  );
}

/// Coach input for a new group (v1.1 §2).
class GroupDraft {
  const GroupDraft({
    required this.clubId,
    required this.sportId,
    required this.name,
    required this.ageMin,
    required this.ageMax,
    this.scheduleNote,
    this.coachIds = const [],
    this.capacity,
  });

  final String clubId;
  final String sportId;
  final String name;
  final int ageMin;
  final int ageMax;
  final String? scheduleNote;

  /// v1.9.1: set by an organization admin (coaches of the club). Empty when
  /// a coach creates a group for themself.
  final List<String> coachIds;
  final int? capacity;

  static List<String> validate(GroupDraft d) => [
    if (d.name.trim().length < 2) 'groupNameRequired',
    if (d.name.trim().length > 60) 'validationTooLong',
    if (d.ageMin < 3 || d.ageMax > 18 || d.ageMin > d.ageMax) 'groupAgeRange',
    if (d.capacity != null && (d.capacity! < 1 || d.capacity! > 500)) 'groupCapacity',
  ];
}

/// Invite codes: 6 chars without ambiguous 0/O/1/I (v1.1 §2).
class InviteCodes {
  InviteCodes._();

  static const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String normalize(String raw) => raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static bool isValid(String code) => code.length == 6 && code.split('').every(alphabet.contains);

  static String generate(int Function(int max) nextInt) =>
      List.generate(6, (_) => alphabet[nextInt(alphabet.length)]).join();
}

enum InviteStatus {
  sent,
  accepted,
  declined,
  revoked;

  static InviteStatus fromName(String? n) =>
      InviteStatus.values.firstWhere((s) => s.name == n, orElse: () => InviteStatus.sent);
}

/// Coach → parent invitation to put a child in a group (v1.1 §2). The child
/// joins only after the parent accepts; nothing is ever linked automatically
/// by name or phone.
class GroupInvite {
  const GroupInvite({
    required this.id,
    required this.groupId,
    required this.clubId,
    required this.sportId,
    required this.groupName,
    required this.childFirstName,
    required this.childLastName,
    required this.phone,
    required this.createdBy,
    required this.createdAt,
    this.childId,
    this.parentId,
    this.status = InviteStatus.sent,
    this.decidedAt,
    this.linkedChildId,
  });

  final String id;
  final String groupId;
  final String clubId;
  final String sportId;
  final String groupName;

  /// Existing child (search flow) or the coach-created pending child.
  final String? childId;
  final String childFirstName;
  final String childLastName;
  final String phone;

  /// Registered parent the invite is addressed to (server-resolved).
  final String? parentId;
  final InviteStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? decidedAt;
  final String? linkedChildId;

  String get childName => '$childFirstName $childLastName'.trim();

  GroupInvite copyWith({InviteStatus? status, DateTime? decidedAt, String? linkedChildId, String? parentId}) =>
      GroupInvite(
        id: id,
        groupId: groupId,
        clubId: clubId,
        sportId: sportId,
        groupName: groupName,
        childFirstName: childFirstName,
        childLastName: childLastName,
        phone: phone,
        createdBy: createdBy,
        createdAt: createdAt,
        childId: childId,
        parentId: parentId ?? this.parentId,
        status: status ?? this.status,
        decidedAt: decidedAt ?? this.decidedAt,
        linkedChildId: linkedChildId ?? this.linkedChildId,
      );

  factory GroupInvite.fromMap(String id, Map<String, dynamic> m) => GroupInvite(
    id: id,
    groupId: m['groupId'] as String? ?? '',
    clubId: m['clubId'] as String? ?? '',
    sportId: m['sportId'] as String? ?? '',
    groupName: m['groupName'] as String? ?? '',
    childId: m['childId'] as String?,
    childFirstName: m['childFirstName'] as String? ?? '',
    childLastName: m['childLastName'] as String? ?? '',
    phone: m['phone'] as String? ?? '',
    parentId: m['parentId'] as String?,
    status: InviteStatus.fromName(m['status'] as String?),
    createdBy: m['createdBy'] as String? ?? '',
    createdAt: readDate(m['createdAt']),
    decidedAt: readDateOrNull(m['decidedAt']),
    linkedChildId: m['linkedChildId'] as String?,
  );
}

/// Coach-entered data for a child that is not registered yet (v1.1 §2.3).
class PendingChildDraft {
  const PendingChildDraft({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.parentPhone,
  });

  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String parentPhone;
}

/// Minimal search result for the coach "find a registered child" flow —
/// never includes parent contact data, health data or groups.
class ChildSearchResult {
  const ChildSearchResult({
    required this.childId,
    required this.firstName,
    required this.lastName,
    required this.birthYear,
  });

  final String childId;
  final String firstName;
  final String lastName;
  final int birthYear;

  String get fullName => '$firstName $lastName';
}
