import 'club.dart';

abstract interface class ClubsRepository {
  Future<List<Club>> clubs();
  Future<Club?> club(String id);
  Future<List<Venue>> venues({String? clubId, String? sportId});
  Future<Venue?> venue(String id);

  /// Venues within [radiusMeters] (v1.1 §9: shown before a new pin is saved).
  Future<List<Venue>> venuesNear(double lat, double lng, {double radiusMeters = 200});

  /// Approved coach pins a new, unverified venue on the map.
  Future<Venue> createVenue({
    required String name,
    required String address,
    required double lat,
    required double lng,
    required List<String> sportIds,
    String? clubId,
  });
  Future<MembershipRequest> requestMembership({required String childId, required String clubId, String? groupId});
  Stream<List<MembershipRequest>> watchMyRequests();

  /// Requests for groups the signed-in coach manages.
  Stream<List<MembershipRequest>> watchIncomingRequests();

  /// Coach/club admin decision; approval adds the child to the group.
  Future<void> decideRequest(String requestId, {required bool approve});
}
