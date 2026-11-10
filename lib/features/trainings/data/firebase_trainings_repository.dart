import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/bytes.dart';
import '../../../core/firebase/firebase_utils.dart';
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
    final photos = await _upload(old.groupId, id, d.newPhotos);
    await _col.doc(id).update({
      'venueId': d.venueId,
      'startAt': d.startAt,
      'durationMin': d.durationMin,
      'focus': d.focus.map((f) => f.name).toList(),
      'description': d.description.trim(),
      if (photos.isNotEmpty) 'photoUrls': FieldValue.arrayUnion(photos),
      if (moved) 'status': TrainingStatus.moved.name,
      if (moved) 'previousStartAt': old.startAt,
      'updatedAt': clock(),
    });
    return old.copyWith(venueId: d.venueId, startAt: d.startAt, durationMin: d.durationMin, focus: d.focus);
  });

  @override
  Future<void> cancel(String id) =>
      guardFirebase(() => _col.doc(id).update({'status': TrainingStatus.cancelled.name, 'updatedAt': clock()}));

  @override
  Future<void> reschedule(String id, DateTime newStart) => guardFirebase(() async {
    if (newStart.isBefore(clock())) throw const ValidationException('startInPast');
    final snap = await _col.doc(id).get();
    final old = snap.data() ?? (throw const NotFoundException());
    await _col.doc(id).update({
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
}
