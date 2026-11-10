import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firebase/firebase_utils.dart';
import '../domain/group.dart';
import '../domain/groups_repository.dart';

class FirebaseGroupsRepository implements GroupsRepository {
  FirebaseGroupsRepository(this.auth, this.db);

  final FirebaseAuth auth;
  final FirebaseFirestore db;

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
}
