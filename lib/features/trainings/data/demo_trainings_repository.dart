import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/access_policy.dart';
import '../../demo/data/demo_backend.dart';
import '../../notifications/domain/notification_models.dart';
import '../domain/training.dart';
import '../domain/trainings_repository.dart';

class DemoTrainingsRepository implements TrainingsRepository {
  DemoTrainingsRepository(this.db);

  final DemoBackend db;

  @override
  Stream<List<Training>> watchForGroups(List<String> groupIds) => db.watch(() {
        final me = db.me;
        final visible = groupIds.where((id) {
          final g = db.groups[id];
          return g != null && AccessPolicy.canViewTrainings(me, g);
        }).toSet();
        return db.trainings.values.where((t) => visible.contains(t.groupId)).toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
      });

  @override
  Stream<Training?> watchTraining(String id) => db.watch(() {
        final t = db.trainings[id];
        if (t == null) return null;
        final g = db.requireGroup(t.groupId);
        if (!AccessPolicy.canViewTrainings(db.me, g)) throw const PermissionDeniedException();
        return t;
      });

  void _guard(String groupId) {
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.canManageTrainings(db.me, g)) throw const PermissionDeniedException('not coach of group');
  }

  List<String> _storePhotos(List<PhotoUpload> photos) => [
        for (final p in photos) _storePhoto(p),
      ];

  String _storePhoto(PhotoUpload p) {
    if (!p.mimeType.startsWith('image/')) throw const ValidationException('fileType');
    if (p.bytes.length > 10 * 1024 * 1024) throw const ValidationException('fileTooLarge');
    final key = 'demo-mem://${db.newId('photo')}';
    db.photos[key] = Uint8List.fromList(p.bytes);
    return key;
  }

  @override
  Future<Training> create(TrainingDraft d) async {
    _guard(d.groupId);
    final errors = TrainingValidator.validate(d, now: db.clock());
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final t = Training(
      id: db.newId('tr'),
      groupId: d.groupId,
      venueId: d.venueId,
      startAt: d.startAt,
      durationMin: d.durationMin,
      focus: d.focus,
      description: d.description.trim(),
      createdBy: db.me.id,
      photoUrls: _storePhotos(d.newPhotos),
      updatedAt: db.clock(),
    );
    db.trainings[t.id] = t;
    db.dispatch(NotificationType.newTraining, db.groups[d.groupId]!, route: '/training/${t.id}');
    db.commit();
    return t;
  }

  @override
  Future<Training> update(String id, TrainingDraft d) async {
    final old = db.trainings[id] ?? (throw const NotFoundException());
    _guard(old.groupId);
    if (d.groupId != old.groupId) throw const PermissionDeniedException('group change');
    final errors = TrainingValidator.validate(d, now: db.clock(), isEdit: true);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final moved = !d.startAt.isAtSameMomentAs(old.startAt);
    final t = old.copyWith(
      venueId: d.venueId,
      startAt: d.startAt,
      durationMin: d.durationMin,
      focus: d.focus,
      description: d.description.trim(),
      photoUrls: [...old.photoUrls, ..._storePhotos(d.newPhotos)],
      status: moved ? TrainingStatus.moved : old.status,
      previousStartAt: moved ? old.startAt : null,
      updatedAt: db.clock(),
    );
    db.trainings[id] = t;
    if (moved || d.venueId != old.venueId) {
      db.dispatch(NotificationType.trainingChanged, db.groups[old.groupId]!, route: '/training/$id');
    }
    if (d.newPhotos.isNotEmpty) {
      db.dispatch(NotificationType.newPhotos, db.groups[old.groupId]!, route: '/training/$id');
    }
    db.commit();
    return t;
  }

  @override
  Future<void> cancel(String id) async {
    final t = db.trainings[id] ?? (throw const NotFoundException());
    _guard(t.groupId);
    db.trainings[id] = t.copyWith(status: TrainingStatus.cancelled, updatedAt: db.clock());
    db.dispatch(NotificationType.trainingChanged, db.groups[t.groupId]!, route: '/training/$id', args: {'kind': 'cancelled'});
    db.commit();
  }

  @override
  Future<void> reschedule(String id, DateTime newStart) async {
    final t = db.trainings[id] ?? (throw const NotFoundException());
    _guard(t.groupId);
    if (newStart.isBefore(db.clock())) throw const ValidationException('startInPast');
    db.trainings[id] = t.copyWith(
      status: TrainingStatus.moved,
      previousStartAt: t.startAt,
      startAt: newStart,
      updatedAt: db.clock(),
    );
    db.dispatch(NotificationType.trainingChanged, db.groups[t.groupId]!, route: '/training/$id', args: {'kind': 'moved'});
    db.commit();
  }

  @override
  Future<void> markDone(String id) async {
    final t = db.trainings[id] ?? (throw const NotFoundException());
    _guard(t.groupId);
    db.trainings[id] = t.copyWith(status: TrainingStatus.done, updatedAt: db.clock());
    db.commit();
  }

  @override
  Future<void> addPhotos(String id, List<PhotoUpload> photos, {required bool consentConfirmed}) async {
    final t = db.trainings[id] ?? (throw const NotFoundException());
    final g = db.requireGroup(t.groupId);
    if (!AccessPolicy.canUploadTrainingPhotos(db.me, g)) throw const PermissionDeniedException();
    if (!consentConfirmed) throw const ValidationException('photoConsentRequired');
    db.trainings[id] = t.copyWith(photoUrls: [...t.photoUrls, ..._storePhotos(photos)], updatedAt: db.clock());
    db.dispatch(NotificationType.newPhotos, g, route: '/training/$id');
    db.commit();
  }
}
