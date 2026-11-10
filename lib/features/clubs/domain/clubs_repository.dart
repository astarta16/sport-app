import 'club.dart';

abstract interface class ClubsRepository {
  Future<List<Club>> clubs();
  Future<Club?> club(String id);
  Future<List<Venue>> venues({String? clubId, String? sportId});
  Future<Venue?> venue(String id);
  Future<MembershipRequest> requestMembership({required String childId, required String clubId, String? groupId});
  Stream<List<MembershipRequest>> watchMyRequests();

  /// Requests for groups the signed-in coach manages.
  Stream<List<MembershipRequest>> watchIncomingRequests();

  /// Coach/club admin decision; approval adds the child to the group.
  Future<void> decideRequest(String requestId, {required bool approve});
}
