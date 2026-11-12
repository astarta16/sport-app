import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/bytes.dart';
import '../../../core/firebase/firebase_utils.dart';
import '../domain/training_plan.dart';

/// `trainingPlans/{id}` with embedded exercises; media in private Storage
/// `plans/{planId}/{mediaId}_{file}`. Parents read via server `readerIds`.
class FirebaseTrainingPlansRepository implements TrainingPlansRepository {
  FirebaseTrainingPlansRepository(this.auth, this.db, this.storage, this.functions);

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseStorage storage;
  final FirebaseFunctions functions;

  CollectionReference<Map<String, dynamic>> get _col => db.collection('trainingPlans');

  List<TrainingPlan> _map(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => TrainingPlan.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));

  @override
  Stream<List<TrainingPlan>> watchPlans() async* {
    final me = await currentRole(auth, db);
    if (me.approvedCoach) {
      // `coachIds` is server-maintained (coaches of every listed group); a
      // plan the coach just created is also matched by `createdBy` until the
      // trigger has run. `groupIds array-contains-any` is not rule-checkable.
      yield* mergeLatestLists([
        _col.where('coachIds', arrayContains: me.uid).snapshots().map(_map),
        _col.where('createdBy', isEqualTo: me.uid).snapshots().map(_map),
      ]).map((all) {
        final byId = {for (final p in all) p.id: p};
        return byId.values.toList()..sort((a, b) => b.startDate.compareTo(a.startDate));
      }).mapFirebaseErrors();
    } else {
      yield* _col
          .where('readerIds', arrayContains: me.uid)
          .where('status', isEqualTo: PlanStatus.published.name)
          .snapshots()
          .map(_map)
          .mapFirebaseErrors();
    }
  }

  @override
  Stream<TrainingPlan?> watchPlan(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.data() == null ? null : TrainingPlan.fromMap(d.id, d.data()!))
      .mapFirebaseErrors();

  @override
  Future<TrainingPlan> save(PlanDraft d, {String? planId}) => guardFirebase(() async {
    final errors = PlanDraft.validate(d);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final uid = requireUid(auth);
    final ref = planId == null ? _col.doc() : _col.doc(planId);
    final old = planId == null ? null : (await ref.get()).data();
    final me = (await db.collection('users').doc(uid).get()).data() ?? const {};
    final group = (await db.collection('groups').doc(d.groupIds.first).get()).data() ?? const {};
    final now = DateTime.now();
    TrainingPlan build(List<Exercise> exercises) => TrainingPlan(
      id: ref.id,
      title: d.title.trim(),
      description: d.description.trim(),
      type: d.type,
      groupIds: d.groupIds,
      clubId: old?['clubId'] as String? ?? group['clubId'] as String? ?? '',
      startDate: d.startDate,
      endDate: d.endDate,
      status: PlanStatus.fromName(old?['status'] as String?),
      exercises: exercises,
      createdBy: old?['createdBy'] as String? ?? uid,
      coachName: old?['coachName'] as String? ?? '${me['firstName'] ?? ''} ${me['lastName'] ?? ''}'.trim(),
      createdAt: now,
      updatedAt: now,
    );
    Map<String, dynamic> dataOf(TrainingPlan p) => p.toMap()
      ..remove('publishedAt')
      ..['createdAt'] = old?['createdAt'] ?? now
      ..['updatedBy'] = uid;
    // Storage rules authorize plan media through the plan doc (createdBy), so
    // a new plan is written first without its pending uploads.
    if (old == null && d.newFiles.isNotEmpty) {
      await ref.set(
        dataOf(
          build([
            for (final e in d.exercises)
              e.copyWith(media: e.media.where((m) => !d.newFiles.containsKey(m.id)).toList()),
          ]),
        ),
      );
    }
    final exercises = <Exercise>[];
    for (final e in d.exercises) {
      final media = <ExerciseMedia>[];
      for (final m in e.media) {
        final f = d.newFiles[m.id];
        if (f == null) {
          media.add(m);
          continue;
        }
        final path = 'plans/${ref.id}/${m.id}_${f.fileName}';
        // Resumable upload (the SDK retries chunks on flaky networks).
        await storage.ref(path).putData(Uint8ListX.from(f.bytes), SettableMetadata(contentType: f.mimeType));
        media.add(ExerciseMedia(id: m.id, kind: m.kind, path: path, name: m.name));
      }
      exercises.add(e.copyWith(media: media));
    }
    final plan = build(exercises);
    final data = dataOf(plan);
    await ref.set(data, SetOptions(merge: true));
    return plan;
  });

  @override
  Future<void> setStatus(String planId, PlanStatus status) => guardFirebase(
    () => _col.doc(planId).update({
      'status': status.name,
      'updatedBy': requireUid(auth),
      'updatedAt': DateTime.now(),
      if (status == PlanStatus.published) 'publishedAt': DateTime.now(),
    }),
  );

  @override
  Future<void> delete(String planId) => guardFirebase(() => _col.doc(planId).delete());

  @override
  Future<List<int>?> loadMedia(String planId, ExerciseMedia media) async {
    final path = media.path;
    if (path == null) return null;
    try {
      return await storage.ref(path).getData(10 * 1024 * 1024);
    } on FirebaseException {
      return null;
    }
  }

  @override
  Future<void> recordView(String planId) => guardFirebase(() async {
    final uid = requireUid(auth);
    final ref = db.collection('planViews').doc('${planId}_$uid');
    final snap = await ref.get();
    await ref.set({
      'planId': planId,
      'parentId': uid,
      'firstViewedAt': snap.data()?['firstViewedAt'] ?? FieldValue.serverTimestamp(),
      'lastViewedAt': FieldValue.serverTimestamp(),
    });
  });

  @override
  Future<void> setProgress({
    required String planId,
    required String exerciseId,
    required String childId,
    required ProgressStatus status,
  }) => guardFirebase(() async {
    final uid = requireUid(auth);
    final plan = TrainingPlan.fromMap(
      planId,
      (await _col.doc(planId).get()).data() ?? (throw const NotFoundException()),
    );
    final child = (await db.collection('children').doc(childId).get()).data() ?? const {};
    final groupId = plan.groupIds.firstWhere(
      (g) => (child['groupIds'] as List? ?? const []).contains(g),
      orElse: () => throw const PermissionDeniedException('progress'),
    );
    await db.collection('exerciseProgress').doc(ExerciseProgress.docId(planId, exerciseId, childId)).set({
      'planId': planId,
      'exerciseId': exerciseId,
      'childId': childId,
      'groupId': groupId,
      'parentId': uid,
      'status': status.wire,
      'updatedAt': FieldValue.serverTimestamp(),
      'viewedAt': FieldValue.serverTimestamp(),
    });
  });

  /// Coaches read all progress of the plan; parents only their own rows
  /// (the query must match the rules).
  @override
  Stream<List<ExerciseProgress>> watchProgress(String planId) async* {
    final me = await currentRole(auth, db);
    var q = db.collection('exerciseProgress').where('planId', isEqualTo: planId);
    if (!me.approvedCoach) q = q.where('parentId', isEqualTo: me.uid);
    yield* q.snapshots().map((s) => s.docs.map((d) => ExerciseProgress.fromMap(d.data())).toList()).mapFirebaseErrors();
  }

  @override
  Stream<PlanStats> watchStats(String planId) {
    final views = db.collection('planViews').where('planId', isEqualTo: planId).snapshots();
    final progress = db.collection('exerciseProgress').where('planId', isEqualTo: planId).snapshots();
    late StreamController<PlanStats> out;
    var v = 0, done = 0;
    final subs = <StreamSubscription<Object?>>[];
    Future<void> emit() async {
      final p = (await _col.doc(planId).get()).data();
      final plan = p == null ? null : TrainingPlan.fromMap(planId, p);
      var kids = 0;
      for (final g in plan?.groupIds ?? const <String>[]) {
        kids += ((await db.collection('groups').doc(g).get()).data()?['memberChildIds'] as List? ?? const []).length;
      }
      out.add(PlanStats(viewers: v, completed: done, total: kids * (plan?.exercises.length ?? 0)));
    }

    out = StreamController<PlanStats>(
      onListen: () {
        subs.add(
          views.listen((s) {
            v = s.size;
            emit();
          }, onError: (Object e) => out.addError(mapFirebaseError(e))),
        );
        subs.add(
          progress.listen((s) {
            done = s.docs.where((d) => d['status'] == 'completed').length;
            emit();
          }, onError: (Object e) => out.addError(mapFirebaseError(e))),
        );
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return out.stream;
  }
}
