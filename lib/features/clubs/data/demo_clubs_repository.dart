import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/access_policy.dart';
import '../../demo/data/demo_backend.dart';
import '../domain/club.dart';
import '../domain/clubs_repository.dart';

class DemoClubsRepository implements ClubsRepository {
  DemoClubsRepository(this.db);

  final DemoBackend db;

  @override
  Future<List<Club>> clubs() async => db.clubs.values.toList();

  @override
  Future<Club?> club(String id) async => db.clubs[id];

  @override
  Future<List<Venue>> venues({String? clubId, String? sportId}) async => db.venues.values
      .where((v) => (clubId == null || v.clubId == clubId) && (sportId == null || v.sportIds.contains(sportId)))
      .toList();

  @override
  Future<Venue?> venue(String id) async => db.venues[id];

  @override
  Future<MembershipRequest> requestMembership({required String childId, required String clubId, String? groupId}) async {
    final me = db.me;
    final child = db.requireChild(childId);
    if (!AccessPolicy.isParentOf(me, child)) throw const PermissionDeniedException();
    if (groupId != null && db.groups[groupId]?.hasChild(childId) == true) {
      throw const ValidationException('alreadyMember');
    }
    final duplicate = db.requests.values.any((r) =>
        r.childId == childId && r.clubId == clubId && r.groupId == groupId && r.status == RequestStatus.pending);
    if (duplicate) throw const ValidationException('requestExists');
    final r = MembershipRequest(
      id: db.newId('req'),
      parentId: me.id,
      childId: childId,
      clubId: clubId,
      groupId: groupId,
      createdAt: db.clock(),
    );
    db.requests[r.id] = r;
    db.commit();
    return r;
  }

  @override
  Stream<List<MembershipRequest>> watchMyRequests() => db.watch(() {
        final me = db.me;
        return db.requests.values.where((r) => r.parentId == me.id).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });

  @override
  Stream<List<MembershipRequest>> watchIncomingRequests() => db.watch(() {
        final me = db.me;
        if (!me.isApprovedCoach) return const <MembershipRequest>[];
        return db.requests.values.where((r) {
          if (r.status != RequestStatus.pending) return false;
          final g = r.groupId == null ? null : db.groups[r.groupId];
          return g != null ? AccessPolicy.isCoachOf(me, g) : me.clubIds.contains(r.clubId);
        }).toList();
      });

  @override
  Future<void> decideRequest(String requestId, {required bool approve}) async {
    final r = db.requests[requestId] ?? (throw const NotFoundException());
    final g = r.groupId == null ? null : db.groups[r.groupId];
    if (g == null || !AccessPolicy.isCoachOf(db.me, g)) throw const PermissionDeniedException();
    db.requests[requestId] = MembershipRequest(
      id: r.id,
      parentId: r.parentId,
      childId: r.childId,
      clubId: r.clubId,
      groupId: r.groupId,
      createdAt: r.createdAt,
      status: approve ? RequestStatus.approved : RequestStatus.rejected,
    );
    if (approve && !g.hasChild(r.childId)) {
      db.groups[g.id] = g.copyWith(memberChildIds: [...g.memberChildIds, r.childId]);
      final c = db.children[r.childId];
      if (c != null && !c.sportIds.contains(g.sportId)) {
        db.children[c.id] = c.copyWith(sportIds: [...c.sportIds, g.sportId]);
      }
      db.recomputeMemberships();
    }
    db.commit();
  }
}
