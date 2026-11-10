import 'group.dart';

abstract interface class GroupsRepository {
  /// Groups visible to the signed-in user (coach: assigned; parent: children's).
  Stream<List<Group>> watchMyGroups();
  Stream<Group?> watchGroup(String id);

  /// Public listing of a club's groups (name, age range) for join requests.
  Future<List<Group>> clubGroups(String clubId);

  /// Coach removes a child; coach access to the child's data and medical
  /// certificates is revoked automatically (membership-based rules).
  Future<void> removeMember(String groupId, String childId);
}
