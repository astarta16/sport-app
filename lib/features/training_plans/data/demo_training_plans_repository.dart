import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/access_policy.dart';
import '../../demo/data/demo_backend.dart';
import '../../groups/domain/group.dart';
import '../../notifications/domain/notification_models.dart';
import '../../organizations/domain/organization.dart';
import '../domain/training_plan.dart';

/// Demo training plans. Visibility mirrors the server `readerIds`: parents
/// see published plans of groups their child is *currently* in.
class DemoTrainingPlansRepository implements TrainingPlansRepository {
  DemoTrainingPlansRepository(this.db);

  final DemoBackend db;

  List<Group> _groups(TrainingPlan p) => p.groupIds.map((id) => db.groups[id]).whereType<Group>().toList();

  bool _canRead(TrainingPlan p) {
    final me = db.me;
    final gs = _groups(p);
    if (gs.any((g) => AccessPolicy.isCoachOf(me, g))) return true;
    return p.isPublished && gs.any((g) => AccessPolicy.isParentInGroup(me, g));
  }

  bool _isCoach(TrainingPlan p) => _groups(p).any((g) => AccessPolicy.isCoachOf(db.me, g));

  @override
  Stream<List<TrainingPlan>> watchPlans() => db.watch(() {
    final me = db.currentUser;
    if (me == null) return const <TrainingPlan>[];
    return db.trainingPlans.values.where(_canRead).toList()..sort((a, b) => b.startDate.compareTo(a.startDate));
  });

  @override
  Stream<TrainingPlan?> watchPlan(String id) => db.watch(() {
    final p = db.trainingPlans[id];
    if (p == null) return null;
    if (!_canRead(p)) throw const PermissionDeniedException('plan');
    return p;
  });

  @override
  Future<TrainingPlan> save(PlanDraft d, {String? planId}) async {
    db.requireOnline();
    final me = db.me;
    final groups = d.groupIds.map(db.requireGroup).toList();
    for (final g in groups) {
      db.requireModule(g.clubId, OrgModule.trainingPlans);
    }
    if (!AccessPolicy.canManagePlan(me, groups)) throw const PermissionDeniedException('plan groups');
    final existing = planId == null ? null : (db.trainingPlans[planId] ?? (throw const NotFoundException('plan')));
    if (existing != null && !_isCoach(existing)) throw const PermissionDeniedException('plan');
    final errors = PlanDraft.validate(d, publishing: existing?.isPublished ?? false);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final id = planId ?? db.newId('plan');
    // "Upload" new files to private demo storage.
    final exercises = [
      for (final e in d.exercises)
        e.copyWith(
          media: [
            for (final m in e.media)
              if (d.newFiles.containsKey(m.id))
                ExerciseMedia(
                  id: m.id,
                  kind: m.kind,
                  path: _store(id, m.id, d.newFiles[m.id]!.bytes, d.newFiles[m.id]!.mimeType),
                  name: m.name,
                )
              else
                m,
          ],
        ),
    ];
    final now = db.clock();
    final plan = TrainingPlan(
      id: id,
      title: d.title.trim(),
      description: d.description.trim(),
      type: d.type,
      groupIds: d.groupIds,
      clubId: groups.first.clubId,
      startDate: d.startDate,
      endDate: d.endDate,
      status: existing?.status ?? PlanStatus.draft,
      exercises: exercises,
      createdBy: existing?.createdBy ?? me.id,
      coachName: existing?.coachName ?? me.fullName,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      publishedAt: existing?.publishedAt,
    );
    db.trainingPlans[id] = plan;
    db.commit();
    return plan;
  }

  String _store(String planId, String mediaId, List<int> bytes, String mime) {
    if (mime.startsWith('video/') ? bytes.length > 100 * 1024 * 1024 : bytes.length > 10 * 1024 * 1024) {
      throw const ValidationException('fileTooLarge');
    }
    final key = 'demo-mem://plans/$planId/$mediaId';
    db.photos[key] = Uint8List.fromList(bytes);
    return key;
  }

  @override
  Future<void> setStatus(String planId, PlanStatus status) async {
    db.requireOnline();
    final p = db.trainingPlans[planId] ?? (throw const NotFoundException('plan'));
    if (!_isCoach(p) || !AccessPolicy.canManagePlan(db.me, _groups(p))) throw const PermissionDeniedException('plan');
    if (p.status == status) return;
    if (status == PlanStatus.published && p.exercises.isEmpty) throw const ValidationException('planExercises');
    final now = db.clock();
    db.trainingPlans[planId] = p.copyWith(
      status: status,
      updatedAt: now,
      publishedAt: status == PlanStatus.published ? now : null,
    );
    if (status == PlanStatus.published) {
      for (final g in _groups(p)) {
        db.dispatch(
          NotificationType.trainingPlanPublished,
          g,
          route: '/plans/$planId',
          args: {'title': p.title},
          dedupeKey: 'plan:$planId:published',
        );
        db.systemMessage(
          g.id,
          'გამოქვეყნდა სავარჯიშო გეგმა: ${p.title}',
          key: 'planPublished',
          args: {'title': p.title},
        );
      }
      db.auditLog('plan.publish', 'trainingPlan', planId, clubId: p.clubId);
    } else if (status == PlanStatus.archived) {
      db.auditLog('plan.archive', 'trainingPlan', planId, clubId: p.clubId);
    }
    db.commit();
  }

  @override
  Future<void> delete(String planId) async {
    db.requireOnline();
    final p = db.trainingPlans[planId] ?? (throw const NotFoundException('plan'));
    if (!_isCoach(p)) throw const PermissionDeniedException('plan');
    if (p.status != PlanStatus.draft) throw const ValidationException('planNotDraft');
    db.trainingPlans.remove(planId);
    db.commit();
  }

  @override
  Future<List<int>?> loadMedia(String planId, ExerciseMedia media) async {
    final p = db.trainingPlans[planId] ?? (throw const NotFoundException('plan'));
    if (!_canRead(p)) throw const PermissionDeniedException('plan media');
    final path = media.path;
    if (path == null || path.startsWith('demo://')) return null;
    return db.photos[path];
  }

  @override
  Future<void> recordView(String planId) async {
    final me = db.currentUser;
    final p = db.trainingPlans[planId];
    if (me == null || p == null || !me.isParent || !_canRead(p)) return;
    final key = '${planId}_${me.id}';
    final old = db.planViews[key];
    db.planViews[key] = PlanView(
      planId: planId,
      parentId: me.id,
      firstViewedAt: old?.firstViewedAt ?? db.clock(),
      lastViewedAt: db.clock(),
    );
    db.commit();
  }

  @override
  Future<void> setProgress({
    required String planId,
    required String exerciseId,
    required String childId,
    required ProgressStatus status,
  }) async {
    db.requireOnline();
    final me = db.me;
    final p = db.trainingPlans[planId] ?? (throw const NotFoundException('plan'));
    final child = db.requireChild(childId);
    if (!AccessPolicy.isParentOf(me, child) || !p.isPublished) throw const PermissionDeniedException('progress');
    final group =
        _groups(p).where((g) => g.hasChild(childId)).firstOrNull ?? (throw const PermissionDeniedException('progress'));
    if (!p.exercises.any((e) => e.id == exerciseId)) throw const NotFoundException('exercise');
    final id = ExerciseProgress.docId(planId, exerciseId, childId);
    db.exerciseProgress[id] = ExerciseProgress(
      planId: planId,
      exerciseId: exerciseId,
      childId: childId,
      groupId: group.id,
      parentId: me.id,
      status: status,
      updatedAt: db.clock(),
      viewedAt: db.exerciseProgress[id]?.viewedAt ?? db.clock(),
    );
    db.commit();
  }

  @override
  Stream<List<ExerciseProgress>> watchProgress(String planId) => db.watch(() {
    final me = db.me;
    final p = db.trainingPlans[planId];
    if (p == null || !_canRead(p)) throw const PermissionDeniedException();
    final coach = _isCoach(p);
    return db.exerciseProgress.values.where((x) => x.planId == planId && (coach || x.parentId == me.id)).toList();
  });

  @override
  Stream<PlanStats> watchStats(String planId) => db.watch(() {
    final p = db.trainingPlans[planId] ?? (throw const NotFoundException());
    if (!_isCoach(p)) throw const PermissionDeniedException();
    final kids = {for (final g in _groups(p)) ...g.memberChildIds};
    final done = db.exerciseProgress.values
        .where((x) => x.planId == planId && x.status == ProgressStatus.completed)
        .length;
    return PlanStats(
      viewers: db.planViews.values.where((v) => v.planId == planId).length,
      completed: done,
      total: kids.length * p.exercises.length,
    );
  });
}
