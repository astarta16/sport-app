import '../../../core/utils/dates.dart';

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
  });

  final String id;
  final String clubId;
  final String sportId;
  final List<String> coachIds;
  final String name;
  final int ageMin;
  final int ageMax;
  final List<String> memberChildIds;

  /// Denormalized by a Cloud Function so rules can check parent membership.
  final List<String> parentIds;
  final String? scheduleNote;

  bool hasCoach(String uid) => coachIds.contains(uid);
  bool hasParent(String uid) => parentIds.contains(uid);
  bool hasChild(String childId) => memberChildIds.contains(childId);

  Group copyWith({List<String>? memberChildIds, List<String>? parentIds}) => Group(
    id: id,
    clubId: clubId,
    sportId: sportId,
    coachIds: coachIds,
    name: name,
    ageMin: ageMin,
    ageMax: ageMax,
    memberChildIds: memberChildIds ?? this.memberChildIds,
    parentIds: parentIds ?? this.parentIds,
    scheduleNote: scheduleNote,
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
  );
}
