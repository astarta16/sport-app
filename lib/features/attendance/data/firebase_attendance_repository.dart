import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_utils.dart';
import '../domain/attendance.dart';

/// `rsvps/{trainingId}_{childId}`, `attendance/{trainingId}_{childId}`,
/// `feedback/{id}`. Rules enforce: parents RSVP only for their own children
/// before the start; only approved coaches of the group mark attendance.
class FirebaseAttendanceRepository implements AttendanceRepository {
  FirebaseAttendanceRepository(this.auth, this.db, {DateTime Function()? clock}) : clock = clock ?? DateTime.now;

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final DateTime Function() clock;

  CollectionReference<Map<String, dynamic>> get _rsvps => db.collection('rsvps');
  CollectionReference<Map<String, dynamic>> get _att => db.collection('attendance');
  CollectionReference<Map<String, dynamic>> get _fb => db.collection('feedback');

  /// The event (training first, then match) with its `eventType`.
  Future<Map<String, dynamic>> _eventData(String id) async {
    final t = (await db.collection('trainings').doc(id).get()).data();
    if (t != null) return {...t, 'eventType': EventType.training.name};
    final m = (await db.collection('matches').doc(id).get()).data();
    if (m != null) return {...m, 'eventType': EventType.match.name};
    throw const NotFoundException();
  }

  @override
  Future<void> respond({
    required String trainingId,
    required String childId,
    required RsvpResponse response,
    String? reason,
  }) => guardFirebase(() async {
    final t = await _eventData(trainingId);
    final r = (reason ?? '').trim();
    if (r.length > Rsvp.maxReason) throw const ValidationException('validationTooLong');
    final uid = requireUid(auth);
    final version = (t['scheduleVersion'] as num?)?.toInt() ?? 1;
    final kept = response == RsvpResponse.yes || r.isEmpty ? null : r;
    final ref = _rsvps.doc(Rsvp.docId(trainingId, childId));
    // Child-level record + this guardian's answer + append-only history,
    // atomically. Older answers stay in history (audit).
    final batch = db.batch();
    batch.set(ref, {
      'trainingId': trainingId,
      'eventId': trainingId,
      'eventType': t['eventType'],
      'groupId': t['groupId'],
      'childId': childId,
      'parentId': uid,
      'response': response.name,
      'reason': kept,
      'scheduleVersion': version,
      'updatedAt': FieldValue.serverTimestamp(),
      'guardianResponses': {
        uid: {'response': response.name, 'version': version, 'at': FieldValue.serverTimestamp(), 'reason': kept},
      },
    }, SetOptions(merge: true));
    batch.set(ref.collection('history').doc(), {
      'guardianId': uid,
      'response': response.name,
      'version': version,
      'reason': kept,
      'at': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  });

  @override
  Stream<List<RsvpHistoryEntry>> watchRsvpHistory(String eventId, String childId) {
    final id = Rsvp.docId(eventId, childId);
    return _rsvps
        .doc(id)
        .collection('history')
        .orderBy('at', descending: true)
        .snapshots()
        .map(
          (s) => [
            for (final d in s.docs)
              RsvpHistoryEntry(
                rsvpId: id,
                guardianId: d.data()['guardianId'] as String? ?? '',
                response: RsvpResponse.fromName(d.data()['response'] as String?),
                version: (d.data()['version'] as num?)?.toInt() ?? 1,
                at: d.data()['at'] == null ? DateTime.now() : (d.data()['at'] as Timestamp).toDate(),
                reason: d.data()['reason'] as String?,
              ),
          ],
        )
        .mapFirebaseErrors();
  }

  Stream<List<Rsvp>> _rsvpQuery(Query<Map<String, dynamic>> q) => q
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => Rsvp.fromMap({...d.data(), 'updatedAt': d.data()['updatedAt'] ?? DateTime.now()}))
            .toList(),
      )
      .mapFirebaseErrors();

  @override
  Stream<List<Rsvp>> watchRsvpsForTraining(String trainingId) =>
      _rsvpQuery(_rsvps.where('trainingId', isEqualTo: trainingId));

  @override
  Stream<List<Rsvp>> watchRsvpsForChild(String childId) => _rsvpQuery(_rsvps.where('childId', isEqualTo: childId));

  @override
  Future<void> mark({required String trainingId, required String childId, AttendanceStatus? status, String? note}) =>
      guardFirebase(() async {
        final ref = _att.doc(AttendanceRecord.docId(trainingId, childId));
        if (status == null) {
          await ref.delete();
          return;
        }
        final t = await _eventData(trainingId);
        await ref.set({
          'trainingId': trainingId,
          'eventId': trainingId,
          'eventType': t['eventType'],
          'groupId': t['groupId'],
          'childId': childId,
          'status': status.name,
          'markedBy': requireUid(auth),
          'markedAt': FieldValue.serverTimestamp(),
          'note': (note ?? '').trim().isEmpty ? null : note!.trim(),
        });
      });

  @override
  Future<void> markAll({required String trainingId, required AttendanceStatus status, bool onlyUnmarked = true}) =>
      guardFirebase(() async {
        final t = await _eventData(trainingId);
        final g = (await db.collection('groups').doc(t['groupId'] as String).get()).data() ?? const {};
        final existing = (await _att.where('trainingId', isEqualTo: trainingId).get()).docs.map((d) => d.id).toSet();
        final batch = db.batch();
        for (final childId in (g['memberChildIds'] as List? ?? const []).cast<String>()) {
          final id = AttendanceRecord.docId(trainingId, childId);
          if (onlyUnmarked && existing.contains(id)) continue;
          batch.set(_att.doc(id), {
            'trainingId': trainingId,
            'eventId': trainingId,
            'eventType': t['eventType'],
            'groupId': t['groupId'],
            'childId': childId,
            'status': status.name,
            'markedBy': requireUid(auth),
            'markedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      });

  @override
  Future<void> saveBatch({required String trainingId, required Map<String, AttendanceStatus?> marks}) =>
      guardFirebase(() async {
        final t = await _eventData(trainingId);
        final batch = db.batch();
        for (final e in marks.entries) {
          final ref = _att.doc(AttendanceRecord.docId(trainingId, e.key));
          if (e.value == null) {
            batch.delete(ref);
          } else {
            batch.set(ref, {
              'trainingId': trainingId,
              'eventId': trainingId,
              'eventType': t['eventType'],
              'groupId': t['groupId'],
              'childId': e.key,
              'status': e.value!.name,
              'markedBy': requireUid(auth),
              'markedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        await batch.commit();
      });

  Stream<List<AttendanceRecord>> _attQuery(Query<Map<String, dynamic>> q) => q
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => AttendanceRecord.fromMap({...d.data(), 'markedAt': d.data()['markedAt'] ?? DateTime.now()}))
            .toList(),
      )
      .mapFirebaseErrors();

  @override
  Stream<List<AttendanceRecord>> watchForTraining(String trainingId) =>
      _attQuery(_att.where('trainingId', isEqualTo: trainingId));

  @override
  Stream<List<AttendanceRecord>> watchForChild(String childId) => _attQuery(_att.where('childId', isEqualTo: childId));

  @override
  Stream<List<AttendanceRecord>> watchForGroup(String groupId) => _attQuery(_att.where('groupId', isEqualTo: groupId));

  @override
  Future<void> addFeedback({
    required String childId,
    required String groupId,
    required Map<FeedbackCategory, int> ratings,
    String? comment,
    String? trainingId,
  }) => guardFirebase(() async {
    final error = CoachFeedback.validate(ratings, comment);
    if (error != null) throw ValidationException(error);
    final uid = requireUid(auth);
    final me = (await db.collection('users').doc(uid).get()).data() ?? const {};
    final f = CoachFeedback(
      id: '',
      childId: childId,
      groupId: groupId,
      coachId: uid,
      coachName: '${me['firstName'] ?? ''} ${me['lastName'] ?? ''}'.trim(),
      trainingId: trainingId,
      createdAt: clock(),
      ratings: ratings,
      comment: (comment ?? '').trim().isEmpty ? null : comment!.trim(),
    );
    await _fb.add(f.toMap()..removeWhere((_, v) => v == null));
  });

  @override
  Stream<List<CoachFeedback>> watchFeedback(String childId) => _fb
      .where('childId', isEqualTo: childId)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => CoachFeedback.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      )
      .mapFirebaseErrors();
}
