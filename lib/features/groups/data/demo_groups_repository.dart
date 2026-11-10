import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/access_policy.dart';
import '../../demo/data/demo_backend.dart';
import '../domain/group.dart';
import '../domain/groups_repository.dart';

class DemoGroupsRepository implements GroupsRepository {
  DemoGroupsRepository(this.db);

  final DemoBackend db;

  @override
  Stream<List<Group>> watchMyGroups() => db.watch(() {
        final me = db.me;
        return db.groups.values.where((g) => AccessPolicy.canViewGroup(me, g)).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
      });

  @override
  Stream<Group?> watchGroup(String id) => db.watch(() {
        final g = db.groups[id];
        if (g == null) return null;
        if (!AccessPolicy.canViewGroup(db.me, g)) throw const PermissionDeniedException();
        return g;
      });

  /// Public info only — member/parent lists are stripped.
  @override
  Future<List<Group>> clubGroups(String clubId) async => db.groups.values
      .where((g) => g.clubId == clubId)
      .map((g) => g.copyWith(memberChildIds: const [], parentIds: const []))
      .toList();

  @override
  Future<void> removeMember(String groupId, String childId) async {
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.isCoachOf(db.me, g)) throw const PermissionDeniedException();
    db.groups[groupId] = g.copyWith(memberChildIds: g.memberChildIds.where((c) => c != childId).toList());
    db.recomputeMemberships();
    db.commit();
  }
}
