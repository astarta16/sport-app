import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_utils.dart';
import '../../attendance/domain/attendance.dart';
import '../../children/domain/child.dart';
import '../../groups/domain/group.dart';
import '../../matches/domain/match.dart';
import '../../training_plans/domain/training_plan.dart';
import '../../trainings/domain/training.dart';
import '../domain/brain_models.dart';
import '../../clubs/domain/club.dart';
import '../domain/student_view.dart';

/// `brainResults` (create-only by the linked student, readable by the
/// student, the child's parents and coaches) and `brainAssignments`
/// (written by group coaches). Not connected to a real project in v1.6:
/// student sign-in stays disabled outside demo mode.
class FirebaseBrainAcademyRepository implements BrainAcademyRepository {
  FirebaseBrainAcademyRepository(this.auth, this.db);

  final FirebaseAuth auth;
  final FirebaseFirestore db;

  @override
  Stream<List<GameResult>> watchResults(String childId) => db
      .collection('brainResults')
      .where('childId', isEqualTo: childId)
      .orderBy('playedAt')
      .limitToLast(500)
      .snapshots()
      .map((s) => [for (final d in s.docs) GameResult.fromMap(d.id, d.data())])
      .mapFirebaseErrors();

  @override
  Future<GameResult> recordResult(GameResult r) => guardFirebase(() async {
    final errors = GameResult.validate(r);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    // v1.7: the client-generated id is the idempotency key (create-only
    // rule: a duplicate submission cannot overwrite or double count). Points
    // and leaderboard totals are computed server-side from stored results.
    final ref = r.id.isEmpty ? db.collection('brainResults').doc() : db.collection('brainResults').doc(r.id);
    final write = ref.set({
      ...r.toMap(),
      'playedAt': FieldValue.serverTimestamp(),
      'clientPlayedAt': r.playedAt.toIso8601String(),
    });
    // Offline: Firestore keeps the write queued and syncs on reconnect; the
    // game does not wait for the server acknowledgement.
    await write.timeout(const Duration(seconds: 4), onTimeout: () {});
    return GameResult.fromMap(ref.id, r.toMap());
  });

  @override
  Stream<List<ChallengeAssignment>> watchAssignmentsForChild(String childId) async* {
    final child = (await db.collection('children').doc(childId).get()).data();
    final groups = ((child?['groupIds'] as List?) ?? const []).cast<String>().take(30).toList();
    if (groups.isEmpty) {
      yield const [];
      return;
    }
    yield* db
        .collection('brainAssignments')
        .where('groupId', whereIn: groups)
        .snapshots()
        .map((s) => [for (final d in s.docs) ChallengeAssignment.fromMap(d.id, d.data())])
        .mapFirebaseErrors();
  }

  @override
  Stream<List<ChallengeAssignment>> watchAssignmentsForGroup(String groupId) => db
      .collection('brainAssignments')
      .where('groupId', isEqualTo: groupId)
      .snapshots()
      .map((s) => [for (final d in s.docs) ChallengeAssignment.fromMap(d.id, d.data())])
      .mapFirebaseErrors();

  @override
  Future<ChallengeAssignment> assign({
    required String groupId,
    required BrainGame game,
    required GameDifficulty difficulty,
    DateTime? dueDate,
  }) => guardFirebase(() async {
    final uid = requireUid(auth);
    final ref = db.collection('brainAssignments').doc();
    await ref.set({
      'groupId': groupId,
      'coachId': uid,
      'game': game.name,
      'difficulty': difficulty.name,
      'createdAt': FieldValue.serverTimestamp(),
      'dueDate': dueDate,
    });
    return ChallengeAssignment(
      id: ref.id,
      groupId: groupId,
      coachId: uid,
      game: game,
      difficulty: difficulty,
      createdAt: DateTime.now(),
      dueDate: dueDate,
    );
  });

  @override
  Future<void> removeAssignment(String id) => guardFirebase(() => db.collection('brainAssignments').doc(id).delete());
}

/// Student view from the collections the student-account rules allow.
class FirebaseStudentRepository implements StudentRepository {
  FirebaseStudentRepository(this.auth, this.db);

  final FirebaseAuth auth;
  final FirebaseFirestore db;

  /// Public venue documents of the student's own events (read once each).
  Future<void> _loadVenues(Iterable<String> ids, Map<String, Venue> into) async {
    for (final id in ids.toSet()) {
      if (id.isEmpty || into.containsKey(id)) continue;
      try {
        final d = await db.collection('venues').doc(id).get();
        if (d.exists) into[id] = Venue.fromMap(d.id, d.data()!);
      } catch (_) {
        // A venue that cannot be read is simply not shown.
      }
    }
  }

  @override
  Stream<StudentView> watchMyView() async* {
    final uid = auth.currentUser?.uid ?? (throw const AuthException('not-signed-in'));
    final me = (await db.collection('users').doc(uid).get()).data() ?? const {};
    final childId = ((me['lastContext'] as Map?) ?? const {})['childId'] as String?;
    if (me['role'] != 'child' || childId == null) throw const PermissionDeniedException('student');
    final childSnap = await db.collection('children').doc(childId).get();
    final child = Child.fromMap(childSnap.id, childSnap.data() ?? const {});
    final coachIds = ((childSnap.data()?['coachIds'] as List?) ?? const []).cast<String>();
    final groupIds = child.groupIds.take(10).toList();
    if (groupIds.isEmpty) {
      yield StudentView(
        child: child,
        groups: const [],
        coachNames: const {},
        trainings: const [],
        matches: const [],
        plans: const [],
        attendance: const [],
      );
      return;
    }
    // Students never read full group docs (they hold other families' ids):
    // the public projection gives name and sport; coaches come from the
    // child's own server-maintained coachIds.
    final pub = await db.collectionGroup('publicGroups').where('groupId', whereIn: groupIds).get();
    final groups = [
      for (final d in pub.docs)
        Group.fromMap(d.id, {...d.data(), 'clubId': d.reference.parent.parent?.id ?? '', 'coachIds': coachIds}),
    ];
    final coachNames = <String, String>{};
    for (final c in coachIds) {
      final p = (await db.collection('publicProfiles').doc(c).get()).data();
      if (p != null) coachNames[c] = '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'.trim();
    }
    var trainings = <Training>[];
    var matches = <SportMatch>[];
    var plans = <TrainingPlan>[];
    var attendance = <AttendanceRecord>[];
    final venues = <String, Venue>{};
    final out = StreamController<StudentView>();
    void emit() => out.add(
      StudentView(
        venues: Map.of(venues),
        child: child,
        groups: groups,
        coachNames: coachNames,
        trainings: trainings,
        matches: matches,
        plans: plans,
        attendance: attendance,
      ),
    );
    final subs = [
      db.collection('trainings').where('groupId', whereIn: groupIds).snapshots().listen((s) {
        trainings = [for (final d in s.docs) Training.fromMap(d.id, d.data())];
        emit();
        _loadVenues(trainings.map((t) => t.venueId), venues).then((_) => emit());
      }, onError: (Object e) => out.addError(mapFirebaseError(e))),
      db.collection('matches').where('groupId', whereIn: groupIds).snapshots().listen((s) {
        matches = [for (final d in s.docs) SportMatch.fromMap(d.id, d.data())];
        emit();
        _loadVenues(matches.map((m) => m.venueId), venues).then((_) => emit());
      }, onError: (Object e) => out.addError(mapFirebaseError(e))),
      db
          .collection('trainingPlans')
          .where('groupIds', arrayContainsAny: groupIds)
          .where('status', isEqualTo: 'published')
          .snapshots()
          .listen((s) {
            plans = [for (final d in s.docs) TrainingPlan.fromMap(d.id, d.data())];
            emit();
          }, onError: (Object e) => out.addError(mapFirebaseError(e))),
      db.collection('attendance').where('childId', isEqualTo: childId).snapshots().listen((s) {
        attendance = [for (final d in s.docs) AttendanceRecord.fromMap(d.data())];
        emit();
      }, onError: (Object e) => out.addError(mapFirebaseError(e))),
    ];
    out.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };
    yield* out.stream;
  }
}
