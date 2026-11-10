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

  /// Optional child avatar, visible only to the child's coaches (v1.1 §3).
  Future<void> setChildPhoto(String childId, List<int>? jpegBytes);

  /// Media consent (photos/videos) with a timestamp (v1.0 §8, v1.1 §5).
  Future<void> setMediaConsent(String childId, bool consent);
}
