import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_utils.dart';
import '../domain/group.dart';
import '../domain/groups_repository.dart';

class FirebaseGroupsRepository implements GroupsRepository {
  FirebaseGroupsRepository(this.auth, this.db, this.functions);

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseFunctions functions;

  @override
  Stream<List<Group>> watchMyGroups() async* {
    final me = await currentRole(auth, db);
    if (me.role == 'coach' && !me.approvedCoach) {
      yield const [];
      return;
    }
    final field = me.role == 'coach' ? 'coachIds' : 'parentIds';
    yield* db
        .collection('groups')
        .where(field, arrayContains: me.uid)
        .snapshots()
        .map((s) => s.docs.map((d) => Group.fromMap(d.id, d.data())).toList()..sort((a, b) => a.name.compareTo(b.name)))
        .mapFirebaseErrors();
  }

  @override
  Stream<Group?> watchGroup(String id) => db
      .collection('groups')
      .doc(id)
      .snapshots()
      .map((d) => d.data() == null ? null : Group.fromMap(d.id, d.data()!))
      .mapFirebaseErrors();

  /// Public group listing for join requests. Production exposes it through a
  /// read-only `clubGroups` projection; falls back to an empty list when the
  /// caller may not list groups directly.
  @override
  Future<List<Group>> clubGroups(String clubId) async {
    try {
      final snap = await db.collection('clubs').doc(clubId).collection('publicGroups').get();
      return snap.docs.map((d) => Group.fromMap(d.id, {...d.data(), 'clubId': clubId})).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> removeMember(String groupId, String childId) => guardFirebase(
    () => db.collection('groups').doc(groupId).update({
      'memberChildIds': FieldValue.arrayRemove([childId]),
    }),
  );

  // ── v1.1 groups & invitations (server callables; rules forbid direct writes) ──

  @override
  Future<Group> createGroup(GroupDraft d) async {
    final errors = GroupDraft.validate(d);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final r = await callFunction(functions, 'createGroup', {
      'clubId': d.clubId,
      'sportId': d.sportId,
      'name': d.name.trim(),
      'ageMin': d.ageMin,
      'ageMax': d.ageMax,
      'scheduleNote': d.scheduleNote,
      if (d.coachIds.isNotEmpty) 'coachIds': d.coachIds,
      'capacity': ?d.capacity,
    });
    final snap = await db.collection('groups').doc(r['groupId'] as String).get();
    return Group.fromMap(snap.id, snap.data() ?? const {});
  }

  Future<GroupInvite> _invite(String id) async {
    final snap = await db.collection('invites').doc(id).get();
    return GroupInvite.fromMap(snap.id, snap.data() ?? const {});
  }

  @override
  Future<GroupInvite> inviteExistingChild({required String groupId, required String childId}) async {
    final r = await callFunction(functions, 'createInvite', {'groupId': groupId, 'childId': childId});
    return _invite(r['inviteId'] as String);
  }

  @override
  Future<GroupInvite> invitePendingChild({required String groupId, required PendingChildDraft child}) async {
    final r = await callFunction(functions, 'createInvite', {
      'groupId': groupId,
      'pendingChild': {
        'firstName': child.firstName.trim(),
        'lastName': child.lastName.trim(),
        'birthDate': child.birthDate.toIso8601String(),
        'parentPhone': child.parentPhone,
      },
    });
    return _invite(r['inviteId'] as String);
  }

  @override
  Future<List<ChildSearchResult>> searchChildren(String query, {required String groupId}) async {
    if (query.trim().length < 2) return const [];
    final r = await callFunction(functions, 'searchChildren', {'groupId': groupId, 'query': query.trim()});
    return [
      for (final m in (r['results'] as List? ?? const []).cast<Map>())
        ChildSearchResult(
          childId: m['childId'] as String,
          firstName: m['firstName'] as String? ?? '',
          lastName: m['lastName'] as String? ?? '',
          birthYear: (m['birthYear'] as num?)?.toInt() ?? 0,
        ),
    ];
  }

  @override
  Stream<List<GroupInvite>> watchGroupInvites(String groupId) => db
      .collection('invites')
      .where('groupId', isEqualTo: groupId)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => GroupInvite.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      )
      .mapFirebaseErrors();

  @override
  Future<void> revokeInvite(String inviteId) => callFunction(functions, 'revokeInvite', {'inviteId': inviteId});

  @override
  Stream<List<GroupInvite>> watchMyInvites() {
    final uid = auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return db
        .collection('invites')
        .where('parentId', isEqualTo: uid)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => GroupInvite.fromMap(d.id, d.data())).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        )
        .mapFirebaseErrors();
  }

  @override
  Future<void> respondInvite(
    String inviteId, {
    required bool accept,
    String? linkedChildId,
    bool mediaConsent = false,
  }) => callFunction(functions, 'respondInvite', {
    'inviteId': inviteId,
    'accept': accept,
    'linkedChildId': linkedChildId,
    'mediaConsent': mediaConsent,
  });

  @override
  Future<String> joinByCode({required String code, required String childId}) async {
    final c = InviteCodes.normalize(code);
    if (!InviteCodes.isValid(c)) throw const ValidationException('invalidGroupCode');
    final r = await callFunction(functions, 'joinGroupByCode', {'code': c, 'childId': childId});
    return r['groupName'] as String? ?? '';
  }

  @override
  Future<void> leaveGroup({required String groupId, required String childId}) =>
      callFunction(functions, 'leaveGroup', {'groupId': groupId, 'childId': childId});
}
