import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firebase/firebase_utils.dart';
import '../domain/club.dart';
import '../domain/clubs_repository.dart';

class FirebaseClubsRepository implements ClubsRepository {
  FirebaseClubsRepository(this.auth, this.db);

  final FirebaseAuth auth;
  final FirebaseFirestore db;

  @override
  Future<List<Club>> clubs() => guardFirebase(
    () async => (await db.collection('clubs').get()).docs.map((d) => Club.fromMap(d.id, d.data())).toList(),
  );

  @override
  Future<Club?> club(String id) => guardFirebase(() async {
    final d = await db.collection('clubs').doc(id).get();
    return d.data() == null ? null : Club.fromMap(d.id, d.data()!);
  });

  @override
  Future<List<Venue>> venues({String? clubId, String? sportId}) => guardFirebase(() async {
    Query<Map<String, dynamic>> q = db.collection('venues');
    if (clubId != null) q = q.where('clubId', isEqualTo: clubId);
    if (sportId != null) q = q.where('sportIds', arrayContains: sportId);
    return (await q.get()).docs.map((d) => Venue.fromMap(d.id, d.data())).toList();
  });

  @override
  Future<Venue?> venue(String id) => guardFirebase(() async {
    final d = await db.collection('venues').doc(id).get();
    return d.data() == null ? null : Venue.fromMap(d.id, d.data()!);
  });

  @override
  Future<MembershipRequest> requestMembership({required String childId, required String clubId, String? groupId}) =>
      guardFirebase(() async {
        final uid = requireUid(auth);
        final child = (await db.collection('children').doc(childId).get()).data();
        final ref = db.collection('membershipRequests').doc();
        await ref.set({
          'parentId': uid,
          'childId': childId,
          'clubId': clubId,
          'groupId': groupId,
          'status': RequestStatus.pending.name,
          'createdAt': FieldValue.serverTimestamp(),
          'childName': child?['firstName'] as String? ?? '',
        });
        return MembershipRequest(
          id: ref.id,
          parentId: uid,
          childId: childId,
          clubId: clubId,
          groupId: groupId,
          createdAt: DateTime.now(),
          childName: child?['firstName'] as String? ?? '',
        );
      });

  MembershipRequest _read(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
      MembershipRequest.fromMap(d.id, {...d.data(), 'createdAt': d.data()['createdAt'] ?? DateTime.now()});

  @override
  Stream<List<MembershipRequest>> watchMyRequests() => db
      .collection('membershipRequests')
      .where('parentId', isEqualTo: requireUid(auth))
      .snapshots()
      .map((s) => s.docs.map(_read).toList())
      .mapFirebaseErrors();

  @override
  Stream<List<MembershipRequest>> watchIncomingRequests() async* {
    final uid = requireUid(auth);
    final me = (await db.collection('users').doc(uid).get()).data() ?? const {};
    final clubIds = ((me['clubIds'] as List?) ?? const []).cast<String>();
    if (me['coachStatus'] != 'approved' || clubIds.isEmpty) {
      yield const [];
      return;
    }
    yield* db
        .collection('membershipRequests')
        .where('clubId', whereIn: clubIds.take(10).toList())
        .where('status', isEqualTo: RequestStatus.pending.name)
        .snapshots()
        .map((s) => s.docs.map(_read).toList())
        .mapFirebaseErrors();
  }

  /// Rules allow the club's coach to set status (+ groupId); the
  /// `onMembershipRequestUpdated` trigger adds the child to the group.
  @override
  Future<void> decideRequest(String requestId, {required bool approve}) => guardFirebase(
    () => db.collection('membershipRequests').doc(requestId).update({
      'status': (approve ? RequestStatus.approved : RequestStatus.rejected).name,
    }),
  );
}
