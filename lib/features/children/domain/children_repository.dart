import 'child.dart';

abstract interface class ChildrenRepository {
  /// Children of the signed-in parent.
  Stream<List<Child>> watchMyChildren();
  Stream<Child?> watchChild(String childId);

  /// Roster of a group (coach of the group or parents in it).
  Stream<List<Child>> watchGroupMembers(String groupId);
  Future<Child> addChild(ChildDraft draft);
  Future<void> updateChild(Child child);
  Future<void> removeChild(String childId);
}
