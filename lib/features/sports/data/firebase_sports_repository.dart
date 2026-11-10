import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firebase_utils.dart';
import '../domain/sport.dart';
import '../domain/sports_repository.dart';

/// Sports catalog from Firestore (managed by platform admins, v1.1 §6).
class FirebaseSportsRepository implements SportsRepository {
  FirebaseSportsRepository(this.db);

  final FirebaseFirestore db;

  static List<Sport> _active(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map((d) => Sport.fromMap(d.id, d.data())).where((s) => s.active).toList()
        ..sort((a, b) => a.order != b.order ? a.order - b.order : a.name.compareTo(b.name));

  @override
  Future<List<Sport>> sports() => guardFirebase(() async => _active(await db.collection('sports').get()));

  @override
  Stream<List<Sport>> watchSports() => db.collection('sports').snapshots().map(_active).mapFirebaseErrors();
}
