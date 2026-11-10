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

  // ── v1.1 §2: groups and invitations ───────────────────────────────────

  /// Approved coach creates a group in one of their clubs; the server
  /// assigns a unique 6-character invite code.
  Future<Group> createGroup(GroupDraft draft);

  /// Coach invites the parent of a registered child found by search.
  Future<GroupInvite> inviteExistingChild({required String groupId, required String childId});

  /// Coach creates a pending child and invites the parent by phone. The
  /// child joins only after the parent accepts.
  Future<GroupInvite> invitePendingChild({required String groupId, required PendingChildDraft child});

  /// Coach search by name: minimal results only (no contact/health data).
  Future<List<ChildSearchResult>> searchChildren(String query, {required String groupId});

  Stream<List<GroupInvite>> watchGroupInvites(String groupId);
  Future<void> revokeInvite(String inviteId);

  /// Invites addressed to the signed-in parent.
  Stream<List<GroupInvite>> watchMyInvites();

  /// Parent accepts or declines. On accept [linkedChildId] links one of the
  /// parent's existing children instead of the coach-created record, which
  /// is then discarded — this is how duplicates are prevented.
  Future<void> respondInvite(String inviteId, {required bool accept, String? linkedChildId, bool mediaConsent = false});

  /// Parent enters a group code for their child → membership request the
  /// coach approves. Returns the group name.
  Future<String> joinByCode({required String code, required String childId});

  /// Parent removes their child from a group at any time.
  Future<void> leaveGroup({required String groupId, required String childId});
}
