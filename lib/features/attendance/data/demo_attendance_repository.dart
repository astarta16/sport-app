import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/access_policy.dart';
import '../../demo/data/demo_backend.dart';
import '../../notifications/domain/notification_models.dart';
import '../../trainings/domain/training.dart';
import '../domain/attendance.dart';

class DemoAttendanceRepository implements AttendanceRepository {
  DemoAttendanceRepository(this.db);

  final DemoBackend db;

  Training _training(String id) => db.trainings[id] ?? (throw const NotFoundException('training'));

  @override
  Future<void> respond({
    required String trainingId,
    required String childId,
    required RsvpResponse response,
    String? reason,
  }) async {
    db.requireOnline();
    final me = db.me;
    final t = _training(trainingId);
    final g = db.requireGroup(t.groupId);
    final c = db.requireChild(childId);
    if (!AccessPolicy.isParentOf(me, c) || !g.hasChild(childId)) throw const PermissionDeniedException('rsvp');
    if (!AccessPolicy.canRsvp(me, c, g, t.startAt, db.clock())) throw const ValidationException('rsvpClosed');
    if (!t.status.isActive) throw const ValidationException('trainingCancelled');
    final r = (reason ?? '').trim();
    if (r.length > Rsvp.maxReason) throw const ValidationException('validationTooLong');
    final rsvp = Rsvp(
      trainingId: trainingId,
      groupId: g.id,
      childId: childId,
      parentId: me.id,
      response: response,
      reason: response == RsvpResponse.yes || r.isEmpty ? null : r,
      updatedAt: db.clock(),
    );
    db.rsvps[rsvp.id] = rsvp;
    db.commit();
  }

  @override
  Stream<List<Rsvp>> watchRsvpsForTraining(String trainingId) => db.watch(() {
    final me = db.me;
    final t = _training(trainingId);
    final g = db.requireGroup(t.groupId);
    final coach = AccessPolicy.isCoachOf(me, g);
    if (!coach && !AccessPolicy.isParentInGroup(me, g)) throw const PermissionDeniedException();
    // Parents only see their own children's responses.
    return db.rsvps.values
        .where(
          (r) => r.trainingId == trainingId && (coach || (db.children[r.childId]?.parentIds.contains(me.id) ?? false)),
        )
        .toList();
  });

  @override
  Stream<List<Rsvp>> watchRsvpsForChild(String childId) => db.watch(() {
    final c = db.requireChild(childId);
    if (!AccessPolicy.canViewProgress(db.me, c, db.groupsOfChild(childId))) throw const PermissionDeniedException();
    return db.rsvps.values.where((r) => r.childId == childId).toList();
  });

  @override
  Future<void> mark({
    required String trainingId,
    required String childId,
    AttendanceStatus? status,
    String? note,
  }) async {
    db.requireOnline();
    final t = _training(trainingId);
    final g = db.requireGroup(t.groupId);
    if (!AccessPolicy.canMarkAttendance(db.me, g)) throw const PermissionDeniedException('attendance');
    if (!g.hasChild(childId)) throw const ValidationException('notMember');
    if (t.status == TrainingStatus.cancelled) throw const ValidationException('trainingCancelled');
    if (t.startAt.isAfter(db.clock().add(const Duration(hours: 1)))) {
      throw const ValidationException('attendanceTooEarly');
    }
    final id = AttendanceRecord.docId(trainingId, childId);
    if (status == null) {
      db.attendance.remove(id);
    } else {
      db.attendance[id] = AttendanceRecord(
        trainingId: trainingId,
        groupId: g.id,
        childId: childId,
        status: status,
        markedBy: db.me.id,
        markedAt: db.clock(),
        note: (note ?? '').trim().isEmpty ? null : note!.trim(),
      );
      final c = db.children[childId];
      for (final p in c?.parentIds ?? const <String>[]) {
        db.notifyUser(
          p,
          NotificationType.attendanceRecorded,
          route: '/children/$childId/progress',
          args: {'child': c!.firstName, 'status': status.name},
          childId: childId,
          groupId: g.id,
          dedupeKey: 'att:$id',
        );
      }
    }
    db.commit();
  }

  @override
  Future<void> markAll({required String trainingId, required AttendanceStatus status, bool onlyUnmarked = true}) async {
    db.requireOnline();
    final t = _training(trainingId);
    final g = db.requireGroup(t.groupId);
    if (!AccessPolicy.canMarkAttendance(db.me, g)) throw const PermissionDeniedException('attendance');
    for (final childId in g.memberChildIds) {
      final id = AttendanceRecord.docId(trainingId, childId);
      if (onlyUnmarked && db.attendance.containsKey(id)) continue;
      await mark(trainingId: trainingId, childId: childId, status: status);
    }
  }

  @override
  Future<void> saveBatch({required String trainingId, required Map<String, AttendanceStatus?> marks}) async {
    db.requireOnline();
    final t = _training(trainingId);
    final g = db.requireGroup(t.groupId);
    if (!AccessPolicy.canMarkAttendance(db.me, g)) throw const PermissionDeniedException('attendance');
    // Validate everything first so a batch is all-or-nothing.
    for (final childId in marks.keys) {
      if (!g.hasChild(childId)) throw const ValidationException('notMember');
    }
    for (final e in marks.entries) {
      await mark(trainingId: trainingId, childId: e.key, status: e.value);
    }
  }

  @override
  Stream<List<AttendanceRecord>> watchForTraining(String trainingId) => db.watch(() {
    final me = db.me;
    final t = _training(trainingId);
    final g = db.requireGroup(t.groupId);
    final coach = AccessPolicy.isCoachOf(me, g);
    if (!coach && !AccessPolicy.isParentInGroup(me, g)) throw const PermissionDeniedException();
    return db.attendance.values
        .where(
          (a) => a.trainingId == trainingId && (coach || (db.children[a.childId]?.parentIds.contains(me.id) ?? false)),
        )
        .toList();
  });

  @override
  Stream<List<AttendanceRecord>> watchForChild(String childId) => db.watch(() {
    final c = db.requireChild(childId);
    final me = db.me;
    final groups = db.groupsOfChild(childId);
    if (!AccessPolicy.canViewProgress(me, c, groups)) throw const PermissionDeniedException();
    // Coaches only see records from their own groups.
    final parent = AccessPolicy.isParentOf(me, c);
    final coachGroups = groups.where((g) => AccessPolicy.isCoachOf(me, g)).map((g) => g.id).toSet();
    return db.attendance.values
        .where((a) => a.childId == childId && (parent || coachGroups.contains(a.groupId)))
        .toList();
  });

  @override
  Stream<List<AttendanceRecord>> watchForGroup(String groupId) => db.watch(() {
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.isCoachOf(db.me, g)) throw const PermissionDeniedException();
    return db.attendance.values.where((a) => a.groupId == groupId).toList();
  });

  @override
  Future<void> addFeedback({
    required String childId,
    required String groupId,
    required Map<FeedbackCategory, int> ratings,
    String? comment,
    String? trainingId,
  }) async {
    db.requireOnline();
    final me = db.me;
    final c = db.requireChild(childId);
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.canGiveFeedback(me, c, g)) throw const PermissionDeniedException('feedback');
    final error = CoachFeedback.validate(ratings, comment);
    if (error != null) throw ValidationException(error);
    final f = CoachFeedback(
      id: db.newId('fb'),
      childId: childId,
      groupId: groupId,
      coachId: me.id,
      coachName: me.fullName,
      trainingId: trainingId,
      createdAt: db.clock(),
      ratings: ratings,
      comment: (comment ?? '').trim().isEmpty ? null : comment!.trim(),
    );
    db.feedback[f.id] = f;
    for (final p in c.parentIds) {
      db.notifyUser(
        p,
        NotificationType.feedbackAdded,
        route: '/children/$childId/progress',
        args: {'child': c.firstName},
        childId: childId,
        groupId: groupId,
        dedupeKey: 'fb:${f.id}',
      );
    }
    db.commit();
  }

  @override
  Stream<List<CoachFeedback>> watchFeedback(String childId) => db.watch(() {
    final me = db.me;
    final c = db.requireChild(childId);
    final groups = db.groupsOfChild(childId);
    if (!AccessPolicy.canViewProgress(me, c, groups)) throw const PermissionDeniedException();
    final parent = AccessPolicy.isParentOf(me, c);
    final coachGroups = groups.where((g) => AccessPolicy.isCoachOf(me, g)).map((g) => g.id).toSet();
    return db.feedback.values.where((f) => f.childId == childId && (parent || coachGroups.contains(f.groupId))).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });
}
