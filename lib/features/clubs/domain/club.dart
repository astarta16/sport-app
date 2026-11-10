import '../../../core/utils/dates.dart';
import '../../../core/utils/geo.dart';

class Club {
  const Club({
    required this.id,
    required this.name,
    required this.address,
    required this.sportIds,
    required this.location,
    required this.geohash,
    this.phone,
    this.description,
    this.archived = false,
    this.adminIds = const [],
  });

  final String id;
  final String name;
  final String address;
  final String? phone;

  /// Archived clubs are hidden from search and cannot get new groups.
  final bool archived;

  /// Club admins (server-managed mirror of the `clubAdmin` claims).
  final List<String> adminIds;
  final List<String> sportIds;
  final GeoCoord location;
  final String geohash;
  final String? description;

  Map<String, dynamic> toMap() => {
    'name': name,
    'address': address,
    'phone': phone,
    'sportIds': sportIds,
    'location': location.toMap(),
    'geohash': geohash,
    'description': description,
    'status': archived ? 'archived' : 'active',
  };

  Club copyWith({
    String? name,
    String? address,
    String? phone,
    String? description,
    List<String>? sportIds,
    GeoCoord? location,
    String? geohash,
    bool? archived,
    List<String>? adminIds,
  }) => Club(
    id: id,
    name: name ?? this.name,
    address: address ?? this.address,
    phone: phone ?? this.phone,
    description: description ?? this.description,
    sportIds: sportIds ?? this.sportIds,
    location: location ?? this.location,
    geohash: geohash ?? this.geohash,
    archived: archived ?? this.archived,
    adminIds: adminIds ?? this.adminIds,
  );

  factory Club.fromMap(String id, Map<String, dynamic> m) => Club(
    id: id,
    name: m['name'] as String? ?? '',
    address: m['address'] as String? ?? '',
    phone: m['phone'] as String?,
    sportIds: readStringList(m['sportIds']),
    location: GeoCoord.fromMap(m['location']),
    geohash: m['geohash'] as String? ?? '',
    description: m['description'] as String?,
    archived: m['status'] == 'archived',
    adminIds: readStringList(m['adminIds']),
  );
}

enum VenueType {
  stadium,
  hall,
  field,
  pool;

  static VenueType fromName(String? n) =>
      VenueType.values.firstWhere((v) => v.name == n, orElse: () => VenueType.field);
}

/// Stadium, hall or pitch (spec §5 `venues`).
class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.geohash,
    required this.sportIds,
    this.clubId,
    this.type = VenueType.field,
    this.verified = true,
    this.createdBy,
  });

  final String id;
  final String? clubId;
  final String name;
  final String address;
  final GeoCoord location;
  final String geohash;
  final List<String> sportIds;
  final VenueType type;

  /// Coach-pinned venues start unverified (v1.1 §9).
  final bool verified;
  final String? createdBy;

  Map<String, dynamic> toMap() => {
    'clubId': clubId,
    'name': name,
    'address': address,
    'location': location.toMap(),
    'geohash': geohash,
    'sportIds': sportIds,
    'type': type.name,
    'verified': verified,
    'createdBy': createdBy,
  };

  factory Venue.fromMap(String id, Map<String, dynamic> m) => Venue(
    id: id,
    clubId: m['clubId'] as String?,
    name: m['name'] as String? ?? '',
    address: m['address'] as String? ?? '',
    location: GeoCoord.fromMap(m['location']),
    geohash: m['geohash'] as String? ?? '',
    sportIds: readStringList(m['sportIds']),
    type: VenueType.fromName(m['type'] as String?),
    verified: m['verified'] as bool? ?? true,
    createdBy: m['createdBy'] as String?,
  );
}

enum RequestStatus {
  pending,
  approved,
  rejected;

  static RequestStatus fromName(String? n) =>
      RequestStatus.values.firstWhere((v) => v.name == n, orElse: () => RequestStatus.pending);
}

class MembershipRequest {
  const MembershipRequest({
    required this.id,
    required this.parentId,
    required this.childId,
    required this.clubId,
    required this.createdAt,
    this.groupId,
    this.status = RequestStatus.pending,
    this.childName = '',
    this.source = 'request',
  });

  final String id;
  final String parentId;
  final String childId;

  /// Denormalized first name so the coach can review a request without
  /// read access to a non-member child's profile.
  final String childName;
  final String clubId;
  final String? groupId;
  final RequestStatus status;
  final DateTime createdAt;

  /// `request` (club page) or `code` (joined with a group invite code).
  final String source;

  Map<String, dynamic> toMap() => {
    'source': source,
    'parentId': parentId,
    'childId': childId,
    'clubId': clubId,
    'groupId': groupId,
    'status': status.name,
    'createdAt': createdAt,
    'childName': childName,
  };

  MembershipRequest withStatus(RequestStatus s) => MembershipRequest(
    id: id,
    parentId: parentId,
    childId: childId,
    clubId: clubId,
    groupId: groupId,
    createdAt: createdAt,
    status: s,
    childName: childName,
    source: source,
  );

  factory MembershipRequest.fromMap(String id, Map<String, dynamic> m) => MembershipRequest(
    id: id,
    parentId: m['parentId'] as String,
    childId: m['childId'] as String,
    clubId: m['clubId'] as String,
    groupId: m['groupId'] as String?,
    status: RequestStatus.fromName(m['status'] as String?),
    createdAt: readDate(m['createdAt']),
    childName: m['childName'] as String? ?? '',
    source: m['source'] as String? ?? 'request',
  );
}
