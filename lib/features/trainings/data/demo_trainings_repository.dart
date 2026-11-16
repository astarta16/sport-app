import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/access_policy.dart';
import '../../demo/data/demo_backend.dart';
import '../../organizations/domain/organization.dart';
import '../../notifications/domain/notification_models.dart';
import '../domain/series.dart';
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

  List<String> _storePhotos(List<PhotoUpload> photos) => [for (final p in photos) _storePhoto(p)];

  String _storePhoto(PhotoUpload p) {
    if (!p.mimeType.startsWith('image/')) throw const ValidationException('fileType');
    if (p.bytes.length > 10 * 1024 * 1024) throw const ValidationException('fileTooLarge');
    final key = 'demo-mem://${db.newId('photo')}';
    db.photos[key] = Uint8List.fromList(p.bytes);
    return key;
  }

  @override
  Future<Training> create(TrainingDraft d) async {
    db.requireOnline();
    _guard(d.groupId);
    db.requireModule(db.clubOfGroup(d.groupId), OrgModule.trainings);
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
    db.requireOnline();
    final old = db.trainings[id] ?? (throw const NotFoundException());
    _guard(old.groupId);
    if (d.groupId != old.groupId) throw const PermissionDeniedException('group change');
    final errors = TrainingValidator.validate(d, now: db.clock(), isEdit: true);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final moved = !d.startAt.isAtSameMomentAs(old.startAt);
    final material = moved || d.venueId != old.venueId || d.durationMin != old.durationMin;
    final t = old.copyWith(
      scheduleVersion: material ? old.scheduleVersion + 1 : null,
      previousVenueId: d.venueId != old.venueId ? old.venueId : null,
      venueId: d.venueId,
      startAt: d.startAt,
      durationMin: d.durationMin,
      focus: d.focus,
      description: d.description.trim(),
      photoUrls: [...old.photoUrls, ..._storePhotos(d.newPhotos)],
      status: moved ? TrainingStatus.moved : old.status,
      previousStartAt: moved ? old.startAt : null,
      updatedAt: db.clock(),
      // Editing one occurrence of a series detaches it ("only this one").
      detached: old.isRecurring ? true : null,
    );
    if (material) db.moveLinkedBooking(id, t.startAt, t.durationMin);
    db.trainings[id] = t;
    if (material) {
      db.dispatch(
        NotificationType.trainingChanged,
        db.groups[old.groupId]!,
        route: '/training/$id',
        dedupeKey: 'training:$id:v${t.scheduleVersion}',
      );
      db.announceScheduleChange(
        db.groups[old.groupId]!,
        eventId: id,
        eventType: 'training',
        version: t.scheduleVersion,
        text: 'ვარჯიშის განრიგი შეიცვალა: ${_fmt(t.startAt)}. გთხოვთ, დაადასტუროთ დასწრება.',
        route: '/training/$id',
        args: {'when': _fmt(t.startAt)},
      );
    }
    if (d.newPhotos.isNotEmpty) {
      db.dispatch(NotificationType.newPhotos, db.groups[old.groupId]!, route: '/training/$id');
    }
    db.commit();
    return t;
  }

  @override
  Future<void> cancel(String id, CancelReason reason) async {
    db.requireOnline();
    final t = db.trainings[id] ?? (throw const NotFoundException());
    _guard(t.groupId);
    final error = CancelReason.validate(reason.code, reason.text);
    if (error != null) throw ValidationException(error);
    if (t.status == TrainingStatus.cancelled) return;
    db.trainings[id] = t.copyWith(
      status: TrainingStatus.cancelled,
      cancelReasonCode: reason.code,
      cancelReason: reason.text.trim(),
      cancelledAt: db.clock(),
      cancelledBy: db.me.id,
      detached: t.isRecurring ? true : null,
      updatedAt: db.clock(),
    );
    final g = db.groups[t.groupId]!;
    db.dispatch(
      NotificationType.trainingChanged,
      g,
      route: '/training/$id',
      args: {'kind': 'cancelled', 'reason': reason.text.trim()},
      dedupeKey: 'cancel:$id',
    );
    db.systemMessage(
      t.groupId,
      'ვარჯიში გაუქმდა (${_fmt(t.startAt)}). მიზეზი: ${reason.text.trim()}',
      key: 'trainingCancelled',
      args: {'when': _fmt(t.startAt), 'reason': reason.text.trim()},
    );
    db.commit();
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Future<void> reschedule(String id, DateTime newStart) async {
    db.requireOnline();
    final t = db.trainings[id] ?? (throw const NotFoundException());
    _guard(t.groupId);
    if (newStart.isBefore(db.clock())) throw const ValidationException('startInPast');
    db.moveLinkedBooking(id, newStart, t.durationMin);
    db.trainings[id] = t.copyWith(
      status: TrainingStatus.moved,
      previousStartAt: t.startAt,
      startAt: newStart,
      updatedAt: db.clock(),
      detached: t.isRecurring ? true : null,
      scheduleVersion: t.scheduleVersion + 1,
    );
    db.announceScheduleChange(
      db.groups[t.groupId]!,
      eventId: id,
      eventType: 'training',
      version: t.scheduleVersion + 1,
      text: 'ვარჯიშის განრიგი შეიცვალა: ${_fmt(newStart)}. გთხოვთ, დაადასტუროთ დასწრება.',
      route: '/training/$id',
      args: {'when': _fmt(newStart)},
    );
    db.systemMessage(
      t.groupId,
      'ვარჯიში გადაიდო: ${_fmt(t.startAt)} → ${_fmt(newStart)}',
      key: 'trainingMoved',
      args: {'from': _fmt(t.startAt), 'to': _fmt(newStart)},
    );
    db.dispatch(
      NotificationType.trainingChanged,
      db.groups[t.groupId]!,
      route: '/training/$id',
      args: {'kind': 'moved'},
    );
    db.commit();
  }

  @override
  Future<void> markDone(String id) async {
    db.requireOnline();
    final t = db.trainings[id] ?? (throw const NotFoundException());
    _guard(t.groupId);
    db.trainings[id] = t.copyWith(status: TrainingStatus.done, updatedAt: db.clock());
    db.commit();
  }

  @override
  Future<void> addPhotos(String id, List<PhotoUpload> photos, {required bool consentConfirmed}) async {
    db.requireOnline();
    final t = db.trainings[id] ?? (throw const NotFoundException());
    final g = db.requireGroup(t.groupId);
    if (!AccessPolicy.canUploadTrainingPhotos(db.me, g)) throw const PermissionDeniedException();
    if (!consentConfirmed) throw const ValidationException('photoConsentRequired');
    db.trainings[id] = t.copyWith(photoUrls: [...t.photoUrls, ..._storePhotos(photos)], updatedAt: db.clock());
    db.dispatch(NotificationType.newPhotos, g, route: '/training/$id');
    db.commit();
  }

  // ── recurring series ───────────────────────────────────────────────────

  @override
  Stream<List<TrainingSeries>> watchSeries(String groupId) => db.watch(() {
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.canViewTrainings(db.me, g)) throw const PermissionDeniedException();
    return db.series.values.where((s) => s.groupId == groupId).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  });

  /// Server equivalent: `onSeriesWritten` / `extendTrainingSeries`.
  SeriesPlan applySeries(TrainingSeries s) {
    final existing = db.trainings.values
        .where(
          (t) =>
              t.seriesId == s.id ||
              (s.parentSeriesId != null &&
                  t.seriesId == s.parentSeriesId &&
                  t.occurrenceDate != null &&
                  LocalDate.parse(t.occurrenceDate!) >= s.startDate),
        )
        .toList();
    final ids = existing.map((t) => t.id).toSet();
    final activity = <String>{
      ...db.rsvps.values.where((r) => ids.contains(r.trainingId)).map((r) => r.trainingId),
      ...db.attendance.values.where((a) => ids.contains(a.trainingId)).map((a) => a.trainingId),
    };
    final oneOffs = db.trainings.values
        .where((t) => t.groupId == s.groupId && t.seriesId == null && t.status.isActive)
        .map((t) => t.startAt)
        .toSet();
    final plan = RecurrenceEngine.reconcile(
      s,
      existing: existing,
      now: db.clock(),
      withActivity: activity,
      oneOffStarts: oneOffs,
    );
    for (final t in [...plan.create, ...plan.update, ...plan.cancel]) {
      db.trainings[t.id] = t;
    }
    for (final id in plan.delete) {
      db.trainings.remove(id);
    }
    return plan;
  }

  /// Daily job equivalent: extends every active series to the horizon.
  void extendAll() {
    for (final s in db.series.values.where((s) => s.status == SeriesStatus.active).toList()) {
      applySeries(s);
    }
  }

  void _validateSeries(SeriesDraft d, {String? ignoreSeriesId, String? ignoreParent}) {
    final errors = SeriesDraft.validate(d, today: LocalDate.tbilisi(db.clock()));
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final overlap = db.series.values.any(
      (s) => s.id != ignoreSeriesId && s.id != ignoreParent && SeriesDraft.overlaps(d, s),
    );
    if (overlap) throw const ValidationException('seriesOverlap');
  }

  @override
  Future<TrainingSeries> createSeries(SeriesDraft d) async {
    db.requireOnline();
    _guard(d.groupId);
    _validateSeries(d);
    final g = db.groups[d.groupId]!;
    final s = TrainingSeries(
      id: db.newId('ser'),
      groupId: d.groupId,
      clubId: g.clubId,
      venueId: d.venueId,
      weekdays: ([...d.weekdays.toSet()]..sort()),
      startTime: d.startTime,
      durationMin: d.durationMin,
      focus: d.focus,
      description: d.description.trim(),
      startDate: d.startDate,
      endDate: d.endDate,
      createdBy: db.me.id,
    );
    db.series[s.id] = s;
    applySeries(s);
    db.dispatch(
      NotificationType.scheduleChanged,
      g,
      route: '/calendar',
      args: {'kind': 'created'},
      dedupeKey: 'series:${s.id}:created',
    );
    db.systemMessage(g.id, 'დაემატა ვარჯიშების განრიგი', key: 'scheduleCreated');
    db.commit();
    return s;
  }

  @override
  Future<TrainingSeries> updateSeriesFrom(String seriesId, SeriesDraft d, {required LocalDate from}) async {
    db.requireOnline();
    final old = db.series[seriesId] ?? (throw const NotFoundException());
    _guard(old.groupId);
    if (d.groupId != old.groupId) throw const PermissionDeniedException('group change');
    final today = LocalDate.tbilisi(db.clock());
    final start = from < today ? today : from;
    _validateSeries(
      SeriesDraft(
        groupId: d.groupId,
        venueId: d.venueId,
        weekdays: d.weekdays,
        startTime: d.startTime,
        durationMin: d.durationMin,
        focus: d.focus,
        startDate: start,
        endDate: d.endDate,
        description: d.description,
      ),
      ignoreSeriesId: seriesId,
    );
    final (ended, next) = RecurrenceEngine.split(
      old,
      SeriesDraft(
        groupId: d.groupId,
        venueId: d.venueId,
        weekdays: d.weekdays,
        startTime: d.startTime,
        durationMin: d.durationMin,
        focus: d.focus,
        startDate: start,
        endDate: d.endDate,
        description: d.description,
      ),
      from: start,
      newId: db.newId('ser'),
    );
    db.series[ended.id] = ended;
    db.series[next.id] = next;
    // New series adopts the old one's future occurrences by date first.
    applySeries(next);
    applySeries(ended);
    final g = db.groups[old.groupId]!;
    db.dispatch(
      NotificationType.scheduleChanged,
      g,
      route: '/calendar',
      args: {'kind': 'changed'},
      dedupeKey: 'series:${next.id}:changed',
    );
    final fromLabel = '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}';
    db.systemMessage(
      g.id,
      'ვარჯიშების განრიგი შეიცვალა $fromLabel-დან',
      key: 'scheduleChanged',
      args: {'from': fromLabel},
    );
    db.commit();
    return next;
  }

  @override
  Future<void> endSeries(String seriesId, {required LocalDate lastDate}) async {
    db.requireOnline();
    final s = db.series[seriesId] ?? (throw const NotFoundException());
    _guard(s.groupId);
    final ended = s.copyWith(
      endDate: lastDate,
      status: lastDate < LocalDate.tbilisi(db.clock()) ? SeriesStatus.ended : null,
    );
    db.series[seriesId] = ended;
    applySeries(ended.status == SeriesStatus.ended ? ended : ended);
    final g = db.groups[s.groupId]!;
    db.dispatch(
      NotificationType.scheduleChanged,
      g,
      route: '/calendar',
      args: {'kind': 'ended'},
      dedupeKey: 'series:$seriesId:ended:$lastDate',
    );
    db.commit();
  }
}
