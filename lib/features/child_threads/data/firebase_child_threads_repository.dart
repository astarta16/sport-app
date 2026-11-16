import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_utils.dart';
import '../domain/child_thread.dart';

/// `childThreads/{childId}_{coachId}` (+ `messages`). Rules allow only the
/// child's current guardians and that coach while coaching the child;
/// onChildThreadMessageCreated notifies the other side.
class FirebaseChildThreadsRepository implements ChildThreadsRepository {
  FirebaseChildThreadsRepository(this.auth, this.db);

  final FirebaseAuth auth;
  final FirebaseFirestore db;

  CollectionReference<Map<String, dynamic>> get _col => db.collection('childThreads');

  @override
  Stream<List<ChildThreadMessage>> watchMessages(String childId, String coachId) => _col
      .doc(ChildThread.idOf(childId, coachId))
      .collection('messages')
      .orderBy('createdAt')
      .limitToLast(200)
      .snapshots()
      .map((s) => [for (final d in s.docs) ChildThreadMessage.fromMap(d.id, d.data())])
      .mapFirebaseErrors();

  @override
  Future<void> send(String childId, String coachId, String text) => guardFirebase(() async {
    final uid = requireUid(auth);
    final t = text.trim();
    if (t.isEmpty) throw const ValidationException('emptyMessage');
    if (t.length > ChildThreadMessage.maxLength) throw const ValidationException('messageTooLong');
    final me = (await db.collection('users').doc(uid).get()).data() ?? (throw const AuthException('not-signed-in'));
    final ref = _col.doc(ChildThread.idOf(childId, coachId));
    // Create-only thread doc; an existing one is refused by the rules (no
    // updates), which simply means it is already there.
    try {
      await ref.set({
        'childId': childId,
        'coachId': coachId,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }
    await ref.collection('messages').add({
      'senderId': uid,
      'senderName': '${me['firstName'] ?? ''} ${me['lastName'] ?? ''}'.trim(),
      'senderRole': me['role'],
      'text': t,
      'createdAt': FieldValue.serverTimestamp(),
    });
  });

  /// Parent: threads of own children; coach: threads about the members of
  /// the coach's groups (queries stay inside what the rules allow).
  @override
  Stream<List<ChildThread>> watchMyThreads() async* {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      yield const [];
      return;
    }
    final me = (await db.collection('users').doc(uid).get()).data() ?? const {};
    if (me['role'] == 'parent') {
      final kids = await db.collection('children').where('parentIds', arrayContains: uid).get();
      final ids = kids.docs.map((d) => d.id).take(30).toList();
      if (ids.isEmpty) {
        yield const [];
        return;
      }
      yield* _col.where('childId', whereIn: ids).snapshots().map(_map).mapFirebaseErrors();
    } else {
      final groups = await db.collection('groups').where('coachIds', arrayContains: uid).get();
      final ids = {for (final g in groups.docs) ...((g.data()['memberChildIds'] as List?) ?? const []).cast<String>()}
          .take(30)
          .toList();
      if (ids.isEmpty) {
        yield const [];
        return;
      }
      yield* _col
          .where('coachId', isEqualTo: uid)
          .where('childId', whereIn: ids)
          .snapshots()
          .map(_map)
          .mapFirebaseErrors();
    }
  }

  static List<ChildThread> _map(QuerySnapshot<Map<String, dynamic>> s) =>
      [for (final d in s.docs) ChildThread.fromMap(d.data())]
        ..sort((a, b) => (b.lastMessageAt ?? DateTime(0)).compareTo(a.lastMessageAt ?? DateTime(0)));
}
