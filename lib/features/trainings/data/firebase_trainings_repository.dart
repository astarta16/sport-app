import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/bytes.dart';
import '../../../core/firebase/firebase_utils.dart';
import '../domain/series.dart';
import '../domain/training.dart';
import '../domain/trainings_repository.dart';

/// Trainings in Firestore; photos in private Storage paths
/// `trainingPhotos/{groupId}/{trainingId}/{file}` (no public URLs stored).
/// Rules enforce that only approved coaches of the group can write.
class FirebaseTrainingsRepository implements TrainingsRepository {
  FirebaseTrainingsRepository(this.auth, this.db, this.storage, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseStorage storage;
  final DateTime Function() clock;

  CollectionReference<Map<String, dynamic>> get _col => db.collection('trainings');

  @override
  Stream<List<Training>> watchForGroups(List<String> groupIds) {
    if (groupIds.isEmpty) return Stream.value(const []);
    // Firestore `whereIn` accepts up to 30 values.
    return _col
        .where('groupId', whereIn: groupIds.take(30).toList())
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => Training.fromMap(d.id, d.data())).toList()
                ..sort((a, b) => a.startAt.compareTo(b.startAt)),
        )
        .mapFirebaseErrors();
  }

  @override
  Stream<Training?> watchTraining(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.data() == null ? null : Training.fromMap(d.id, d.data()!))
      .mapFirebaseErrors();

  Future<List<String>> _upload(String groupId, String trainingId, List<PhotoUpload> photos) async {
    final paths = <String>[];
    for (final p in photos) {
      if (!p.mimeType.startsWith('image/')) throw const ValidationException('fileType');
      if (p.bytes.length > 10 * 1024 * 1024) throw const ValidationException('fileTooLarge');
      final path = 'trainingPhotos/$groupId/$trainingId/${DateTime.now().microsecondsSinceEpoch}_${p.fileName}';
      await storage.ref(path).putData(Uint8ListX.from(p.bytes), SettableMetadata(contentType: p.mimeType));
      paths.add(path);
    }
    return paths;
  }

  @override
  Future<Training> create(TrainingDraft d) => guardFirebase(() async {
    final errors = TrainingValidator.validate(d, now: clock());
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final ref = _col.doc();
    final photos = await _upload(d.groupId, ref.id, d.newPhotos);
    final t = Training(
      id: ref.id,
      groupId: d.groupId,
      venueId: d.venueId,
      startAt: d.startAt,
      durationMin: d.durationMin,
      focus: d.focus,
      description: d.description.trim(),
      createdBy: requireUid(auth),
      photoUrls: photos,
      updatedAt: clock(),
    );
    await ref.set(t.toMap()..removeWhere((_, v) => v == null));
    return t;
  });

  @override
  Future<Training> update(String id, TrainingDraft d) => guardFirebase(() async {
    final snap = await _col.doc(id).get();
    final old = Training.fromMap(id, snap.data() ?? (throw const NotFoundException()));
    final errors = TrainingValidator.validate(d, now: clock(), isEdit: true);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final moved = !d.startAt.isAtSameMomentAs(old.startAt);
    // v1.7: a material change (date, time, place) bumps the schedule version;
    // the rules require it and onEventScheduleChanged asks parents to reconfirm.
    final material = moved || d.venueId != old.venueId;
    final photos = await _upload(old.groupId, id, d.newPhotos);
    await _col.doc(id).update({
      if (material) 'scheduleVersion': old.scheduleVersion + 1,
      if (d.venueId != old.venueId) 'previousVenueId': old.venueId,
      'venueId': d.venueId,
      'startAt': d.startAt,
      'durationMin': d.durationMin,
      'focus': d.focus.map((f) => f.name).toList(),
      'description': d.description.trim(),
      if (photos.isNotEmpty) 'photoUrls': FieldValue.arrayUnion(photos),
      if (moved) 'status': TrainingStatus.moved.name,
      if (moved) 'previousStartAt': old.startAt,
      if (old.isRecurring) 'detached': true,
      'updatedAt': clock(),
    });
    return old.copyWith(venueId: d.venueId, startAt: d.startAt, durationMin: d.durationMin, focus: d.focus);
  });

  @override
  Future<void> cancel(String id, CancelReason reason) => guardFirebase(() async {
    final error = CancelReason.validate(reason.code, reason.text);
    if (error != null) throw ValidationException(error);
    final snap = await _col.doc(id).get();
    final old = snap.data() ?? (throw const NotFoundException());
    // Push + system chat message are sent by the onTrainingWritten trigger.
    await _col.doc(id).update({
      'status': TrainingStatus.cancelled.name,
      'cancelReasonCode': reason.code.name,
      'cancelReason': reason.text.trim(),
      'cancelledAt': clock(),
      'cancelledBy': requireUid(auth),
      'updatedAt': clock(),
      if (old['seriesId'] != null) 'detached': true,
    });
  });

  @override
  Future<void> reschedule(String id, DateTime newStart) => guardFirebase(() async {
    if (newStart.isBefore(clock())) throw const ValidationException('startInPast');
    final snap = await _col.doc(id).get();
    final old = snap.data() ?? (throw const NotFoundException());
    await _col.doc(id).update({
      if (old['seriesId'] != null) 'detached': true,
      'scheduleVersion': ((old['scheduleVersion'] as num?)?.toInt() ?? 1) + 1,
      'status': TrainingStatus.moved.name,
      'previousStartAt': old['startAt'],
      'startAt': newStart,
      'updatedAt': clock(),
    });
  });

  @override
  Future<void> markDone(String id) =>
      guardFirebase(() => _col.doc(id).update({'status': TrainingStatus.done.name, 'updatedAt': clock()}));

  @override
  Future<void> addPhotos(String id, List<PhotoUpload> photos, {required bool consentConfirmed}) =>
      guardFirebase(() async {
        if (!consentConfirmed) throw const ValidationException('photoConsentRequired');
        final snap = await _col.doc(id).get();
        final groupId = (snap.data() ?? (throw const NotFoundException()))['groupId'] as String;
        final paths = await _upload(groupId, id, photos);
        await _col.doc(id).update({'photoUrls': FieldValue.arrayUnion(paths), 'updatedAt': clock()});
      });

  // ── recurring series: the rule is written here; occurrences are generated
  // server-side by onSeriesWritten / extendTrainingSeries (deterministic ids).

  CollectionReference<Map<String, dynamic>> get _series => db.collection('trainingSeries');

  @override
  Stream<List<TrainingSeries>> watchSeries(String groupId) => _series
      .where('groupId', isEqualTo: groupId)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => TrainingSeries.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => a.startDate.compareTo(b.startDate)),
      )
      .mapFirebaseErrors();

  Future<void> _checkOverlap(SeriesDraft d, {String? ignore}) async {
    final existing = await _series.where('groupId', isEqualTo: d.groupId).where('status', isEqualTo: 'active').get();
    for (final doc in existing.docs) {
      if (doc.id == ignore) continue;
      if (SeriesDraft.overlaps(d, TrainingSeries.fromMap(doc.id, doc.data()))) {
        throw const ValidationException('seriesOverlap');
      }
    }
  }

  @override
  Future<TrainingSeries> createSeries(SeriesDraft d) => guardFirebase(() async {
    final errors = SeriesDraft.validate(d, today: LocalDate.tbilisi(clock()));
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    await _checkOverlap(d);
    final group = (await db.collection('groups').doc(d.groupId).get()).data() ?? const {};
    final ref = _series.doc();
    final s = TrainingSeries(
      id: ref.id,
      groupId: d.groupId,
      clubId: group['clubId'] as String? ?? '',
      venueId: d.venueId,
      weekdays: ([...d.weekdays.toSet()]..sort()),
      startTime: d.startTime,
      durationMin: d.durationMin,
      focus: d.focus,
      description: d.description.trim(),
      startDate: d.startDate,
      endDate: d.endDate,
      createdBy: requireUid(auth),
    );
    await ref.set({...s.toMap(), 'createdAt': clock(), 'updatedAt': clock()});
    return s;
  });

  @override
  Future<TrainingSeries> updateSeriesFrom(String seriesId, SeriesDraft d, {required LocalDate from}) =>
      guardFirebase(() async {
        final snap = await _series.doc(seriesId).get();
        final old = TrainingSeries.fromMap(seriesId, snap.data() ?? (throw const NotFoundException()));
        final today = LocalDate.tbilisi(clock());
        final start = from < today ? today : from;
        final draft = SeriesDraft(
          groupId: old.groupId,
          venueId: d.venueId,
          weekdays: d.weekdays,
          startTime: d.startTime,
          durationMin: d.durationMin,
          focus: d.focus,
          startDate: start,
          endDate: d.endDate,
          description: d.description,
        );
        final errors = SeriesDraft.validate(draft, today: today);
        if (errors.isNotEmpty) throw ValidationException(errors.first);
        await _checkOverlap(draft, ignore: seriesId);
        final ref = _series.doc();
        final (ended, next) = RecurrenceEngine.split(old, draft, from: start, newId: ref.id);
        final batch = db.batch()
          ..update(_series.doc(seriesId), {
            'endDate': ended.endDate.toString(),
            'status': ended.status.name,
            'updatedAt': clock(),
          })
          ..set(ref, {...next.toMap(), 'createdAt': clock(), 'updatedAt': clock()});
        await batch.commit();
        return next;
      });

  @override
  Future<void> endSeries(String seriesId, {required LocalDate lastDate}) => guardFirebase(() async {
    await _series.doc(seriesId).update({
      'endDate': lastDate.toString(),
      if (lastDate < LocalDate.tbilisi(clock())) 'status': SeriesStatus.ended.name,
      'updatedAt': clock(),
    });
  });
}
