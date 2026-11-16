import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/access_policy.dart';
import '../../children/domain/child.dart';
import '../../demo/data/demo_backend.dart';
import '../../groups/domain/group.dart';
import '../../organizations/domain/organization.dart';
import '../../training_plans/domain/training_plan.dart';
import '../domain/brain_models.dart';
import '../domain/student_view.dart';

/// Demo Brain Academy. Mirrors the `brainResults` / `brainAssignments`
/// rules and keeps demo progress on the device (SharedPreferences), so an
/// app restart does not reset achievements. Fictional data only.
class DemoBrainAcademyRepository implements BrainAcademyRepository {
  DemoBrainAcademyRepository(this.db, this.prefs) {
    _load();
  }

  final DemoBackend db;
  final SharedPreferences? prefs;

  static const storageKey = 'demo.brainAcademy.v1';

  void _load() {
    final raw = prefs?.getString(storageKey);
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final known = {for (final r in db.brainResults) r.id};
      for (final e in (m['results'] as Map? ?? const {}).entries) {
        if (!known.contains(e.key)) {
          db.brainResults.add(GameResult.fromMap(e.key as String, Map<String, dynamic>.from(e.value as Map)));
        }
      }
      for (final e in (m['assignments'] as Map? ?? const {}).entries) {
        db.brainAssignments[e.key as String] = ChallengeAssignment.fromMap(
          e.key as String,
          Map<String, dynamic>.from(e.value as Map),
        );
      }
      for (final id in (m['removed'] as List? ?? const [])) {
        db.brainAssignments.remove(id);
      }
    } catch (_) {
      // Corrupt local demo data is ignored (never blocks the app).
    }
  }

  final _removed = <String>{};

  Future<void> _save() async {
    final p = prefs;
    if (p == null) return;
    await p.setString(
      storageKey,
      jsonEncode({
        'results': {for (final r in db.brainResults) r.id: r.toMap()},
        'assignments': {for (final a in db.brainAssignments.values) a.id: a.toMap()},
        'removed': _removed.toList(),
      }),
    );
  }

  Child _child(String childId) => db.children[childId] ?? (throw const NotFoundException('child'));
  List<Group> _groupsOf(Child c) => db.groups.values.where((g) => g.hasChild(c.id)).toList();

  @override
  Stream<List<GameResult>> watchResults(String childId) => db.watch(() {
    final c = _child(childId);
    if (!AccessPolicy.canViewBrainProgress(db.me, c, _groupsOf(c))) throw const PermissionDeniedException('brain');
    return db.brainResults.where((r) => r.childId == childId).toList()
      ..sort((a, b) => a.playedAt.compareTo(b.playedAt));
  });

  @override
  Future<GameResult> recordResult(GameResult result) async {
    final me = db.me;
    final c = _child(result.childId);
    if (!AccessPolicy.isStudentOf(me, c)) throw const PermissionDeniedException('brain');
    final errors = GameResult.validate(result);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    // v1.7: Brain Academy must be enabled for (one of) the child's organizations.
    final orgs = {for (final g in _groupsOf(c)) g.clubId};
    if (orgs.isNotEmpty && !orgs.any((o) => db.orgConfig(o).isEnabled(OrgModule.brainAcademy))) {
      throw const ValidationException('moduleDisabled:brainAcademy');
    }
    // Idempotency: a client-generated id is stored once; a duplicate
    // submission (double finish, retry after reconnect) returns the original.
    if (result.id.isNotEmpty) {
      final existing = db.brainResults.where((r) => r.id == result.id).firstOrNull;
      if (existing != null) return existing;
    }
    // Results are stored offline as well — the games never need a network.
    final stored = GameResult(
      id: result.id.isNotEmpty ? result.id : db.newId('brain-${DateTime.now().microsecondsSinceEpoch}'),
      childId: result.childId,
      game: result.game,
      difficulty: result.difficulty,
      level: result.level,
      score: result.score,
      accuracy: result.accuracy,
      attempts: result.attempts,
      durationMs: result.durationMs,
      completed: result.completed,
      playedAt: db.clock(),
      detail: result.detail,
    );
    db.brainResults.add(stored);
    db.commit();
    await _save();
    return stored;
  }

  @override
  Stream<List<ChallengeAssignment>> watchAssignmentsForChild(String childId) => db.watch(() {
    final c = _child(childId);
    final groups = _groupsOf(c);
    if (!AccessPolicy.canViewBrainProgress(db.me, c, groups)) throw const PermissionDeniedException('brain');
    final ids = {for (final g in groups) g.id};
    return db.brainAssignments.values.where((a) => ids.contains(a.groupId)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  @override
  Stream<List<ChallengeAssignment>> watchAssignmentsForGroup(String groupId) => db.watch(() {
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.isCoachOf(db.me, g)) throw const PermissionDeniedException('brain');
    return db.brainAssignments.values.where((a) => a.groupId == groupId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  @override
  Future<ChallengeAssignment> assign({
    required String groupId,
    required BrainGame game,
    required GameDifficulty difficulty,
    DateTime? dueDate,
  }) async {
    db.requireOnline();
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.isCoachOf(db.me, g)) throw const PermissionDeniedException('brain');
    final now = db.clock();
    if (dueDate != null && dueDate.isBefore(DateTime(now.year, now.month, now.day))) {
      throw const ValidationException('dueInPast');
    }
    final a = ChallengeAssignment(
      id: db.newId('challenge-${DateTime.now().microsecondsSinceEpoch}'),
      groupId: groupId,
      coachId: db.me.id,
      game: game,
      difficulty: difficulty,
      createdAt: now,
      dueDate: dueDate,
    );
    db.brainAssignments[a.id] = a;
    db.commit();
    await _save();
    return a;
  }

  @override
  Future<void> removeAssignment(String id) async {
    db.requireOnline();
    final a = db.brainAssignments[id] ?? (throw const NotFoundException('challenge'));
    if (!AccessPolicy.isCoachOf(db.me, db.requireGroup(a.groupId))) throw const PermissionDeniedException('brain');
    db.brainAssignments.remove(id);
    _removed.add(id);
    db.commit();
    await _save();
  }
}

/// Demo student view: only the student's own child, groups and records.
class DemoStudentRepository implements StudentRepository {
  DemoStudentRepository(this.db);

  final DemoBackend db;

  @override
  Stream<StudentView> watchMyView() => db.watch(() {
    final me = db.me;
    final childId = me.lastContext.childId;
    final c = childId == null ? null : db.children[childId];
    if (c == null || !AccessPolicy.isStudentOf(me, c)) throw const PermissionDeniedException('student');
    final groups = db.groups.values.where((g) => g.isActive && g.hasChild(c.id)).toList();
    final ids = {for (final g in groups) g.id};
    return StudentView(
      child: c,
      groups: groups,
      coachNames: {
        for (final g in groups)
          for (final id in g.coachIds)
            if (db.users[id] case final u? when u.isApprovedCoach) id: u.fullName,
      },
      trainings: db.trainings.values.where((t) => ids.contains(t.groupId)).toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt)),
      matches: db.matches.values.where((m) => ids.contains(m.groupId)).toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt)),
      plans: db.trainingPlans.values
          .where((p) => p.status == PlanStatus.published && p.groupIds.any(ids.contains))
          .toList(),
      attendance: db.attendance.values.where((r) => r.childId == c.id).toList(),
      venues: {
        for (final id in {
          ...db.trainings.values.where((t) => ids.contains(t.groupId)).map((t) => t.venueId),
          ...db.matches.values.where((m) => ids.contains(m.groupId)).map((m) => m.venueId),
        })
          if (db.venues[id] case final v?) id: v,
      },
    );
  });
}
