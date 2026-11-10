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
  });

  final String id;
  final String name;
  final String address;
  final String? phone;
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
      };

  factory Club.fromMap(String id, Map<String, dynamic> m) => Club(
        id: id,
        name: m['name'] as String? ?? '',
        address: m['address'] as String? ?? '',
        phone: m['phone'] as String?,
        sportIds: readStringList(m['sportIds']),
        location: GeoCoord.fromMap(m['location']),
        geohash: m['geohash'] as String? ?? '',
        description: m['description'] as String?,
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
  });

  final String id;
  final String? clubId;
  final String name;
  final String address;
  final GeoCoord location;
  final String geohash;
  final List<String> sportIds;
  final VenueType type;

  Map<String, dynamic> toMap() => {
        'clubId': clubId,
        'name': name,
        'address': address,
        'location': location.toMap(),
        'geohash': geohash,
        'sportIds': sportIds,
        'type': type.name,
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
  });

  final String id;
  final String parentId;
  final String childId;
  final String clubId;
  final String? groupId;
  final RequestStatus status;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'parentId': parentId,
        'childId': childId,
        'clubId': clubId,
        'groupId': groupId,
        'status': status.name,
        'createdAt': createdAt,
      };

  factory MembershipRequest.fromMap(String id, Map<String, dynamic> m) => MembershipRequest(
        id: id,
        parentId: m['parentId'] as String,
        childId: m['childId'] as String,
        clubId: m['clubId'] as String,
        groupId: m['groupId'] as String?,
        status: RequestStatus.fromName(m['status'] as String?),
        createdAt: readDate(m['createdAt']),
      );
}
