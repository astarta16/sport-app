import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firebase_utils.dart';
import '../domain/sport.dart';
import '../domain/sports_repository.dart';

class FirebaseSportsRepository implements SportsRepository {
  FirebaseSportsRepository(this.db);

  final FirebaseFirestore db;

  @override
  Future<List<Sport>> sports() => guardFirebase(() async {
    final snap = await db.collection('sports').get();
    return snap.docs.map((d) => Sport.fromMap(d.id, d.data())).toList();
  });
}
