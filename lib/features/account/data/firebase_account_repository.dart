import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firebase/firebase_utils.dart';
import '../domain/account_request.dart';

/// Deletion/export are processed server-side (`processAccountRequests`);
/// the export is only reachable through a short-lived signed URL.
class FirebaseAccountRepository implements AccountRepository {
  FirebaseAccountRepository(this.auth, this.db, this.functions);

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseFunctions functions;

  @override
  Stream<List<AccountRequest>> watchMyRequests() {
    final uid = auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return db
        .collection('accountRequests')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => AccountRequest.fromMap(d.id, d.data())).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        )
        .mapFirebaseErrors();
  }

  @override
  Future<DeletionImpact> deletionImpact() => guardFirebase(() async {
    final uid = requireUid(auth);
    final kids = await db.collection('children').where('parentIds', arrayContains: uid).get();
    final del = <String>[], unlink = <String>[];
    for (final d in kids.docs) {
      final name = '${d['firstName']} ${d['lastName']}';
      ((d['parentIds'] as List).length > 1 ? unlink : del).add(name);
    }
    return DeletionImpact(deletedChildren: del, unlinkedChildren: unlink);
  });

  Future<AccountRequest> _get(String id) async {
    final snap = await db.collection('accountRequests').doc(id).get();
    return AccountRequest.fromMap(id, snap.data() ?? {'uid': auth.currentUser?.uid, 'createdAt': DateTime.now()});
  }

  @override
  Future<AccountRequest> requestDeletion() async =>
      _get((await callFunction(functions, 'requestAccountDeletion'))['requestId'] as String);

  @override
  Future<AccountRequest> requestExport() async =>
      _get((await callFunction(functions, 'requestDataExport'))['requestId'] as String);
}
