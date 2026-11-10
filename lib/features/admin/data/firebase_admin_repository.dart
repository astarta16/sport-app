import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firebase/firebase_utils.dart';
import '../../authentication/domain/app_user.dart';
import '../../clubs/domain/club.dart';
import '../../groups/domain/group.dart';
import '../../moderation/domain/report.dart';
import '../../sports/domain/sport.dart';
import '../../training_plans/domain/training_plan.dart';
import '../domain/admin_models.dart';

/// Admin dashboard backed by Firestore reads (rules scope them by the
/// `admin` / `clubAdmin` custom claims) and callables for every mutation
/// (each re-checks the claims and writes `auditLog`).
class FirebaseAdminRepository implements AdminRepository {
  FirebaseAdminRepository(this.auth, this.db, this.functions);

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseFunctions functions;

  Future<({bool platform, List<String> clubs})> _scope() async {
    final token = await auth.currentUser?.getIdTokenResult();
    final claims = token?.claims ?? const {};
    return (platform: claims['admin'] == true, clubs: ((claims['clubAdmin'] as List?) ?? const []).cast<String>());
  }

  /// Firestore `whereIn` is limited to 30 values.
  Stream<List<T>> _scoped<T>(
    String col,
    T Function(String, Map<String, dynamic>) map, {
    String field = 'clubId',
  }) async* {
    final s = await _scope();
    final Query<Map<String, dynamic>> q = s.platform
        ? db.collection(col)
        : db.collection(col).where(field, whereIn: s.clubs.isEmpty ? ['-'] : s.clubs.take(30).toList());
    yield* q.snapshots().map((snap) => snap.docs.map((d) => map(d.id, d.data())).toList()).mapFirebaseErrors();
  }

  @override
  Future<AdminStats> stats() async => AdminStats.fromMap(await callFunction(functions, 'adminStats'));

  @override
  Stream<List<CoachSummary>> watchCoaches() async* {
    final s = await _scope();
    var q = db.collection('users').where('role', isEqualTo: 'coach');
    if (!s.platform) q = q.where('clubIds', arrayContainsAny: s.clubs.isEmpty ? ['-'] : s.clubs.take(30).toList());
    yield* q
        .snapshots()
        .map((snap) => snap.docs.map((d) => CoachSummary.fromUser(AppUser.fromMap(d.id, d.data()))).toList())
        .mapFirebaseErrors();
  }

  @override
  Future<void> setCoachStatus(String coachId, CoachStatus status, {String? reason}) =>
      callFunction(functions, 'setCoachStatus', {'uid': coachId, 'status': status.name, 'reason': reason});

  @override
  Future<void> assignCoach({required String clubId, required String coachId, required bool assign}) =>
      callFunction(functions, 'assignCoach', {'clubId': clubId, 'coachId': coachId, 'assign': assign});

  @override
  Stream<List<ClubOverview>> watchClubs() async* {
    final s = await _scope();
    final Query<Map<String, dynamic>> q = s.platform
        ? db.collection('clubs')
        : db
              .collection('clubs')
              .where(FieldPath.documentId, whereIn: s.clubs.isEmpty ? ['-'] : s.clubs.take(30).toList());
    yield* q
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ClubOverview(club: Club.fromMap(d.id, d.data()), groups: 0, members: 0, coaches: 0))
              .toList(),
        )
        .mapFirebaseErrors();
  }

  @override
  Future<Club> upsertClub(ClubDraft d, {String? clubId}) async {
    final r = await callFunction(functions, 'upsertClub', {
      'clubId': clubId,
      'name': d.name,
      'address': d.address,
      'lat': d.lat,
      'lng': d.lng,
      'sportIds': d.sportIds,
      'phone': d.phone,
      'description': d.description,
    });
    final snap = await db.collection('clubs').doc(r['clubId'] as String).get();
    return Club.fromMap(snap.id, snap.data() ?? const {});
  }

  @override
  Future<void> archiveClub(String clubId, {required bool archived}) =>
      callFunction(functions, 'archiveClub', {'clubId': clubId, 'archived': archived});

  @override
  Stream<List<Sport>> watchSports() => db
      .collection('sports')
      .snapshots()
      .map((s) => s.docs.map((d) => Sport.fromMap(d.id, d.data())).toList()..sort((a, b) => a.order - b.order))
      .mapFirebaseErrors();

  @override
  Future<void> upsertSport(Sport sport) => callFunction(functions, 'upsertSport', {'id': sport.id, ...sport.toMap()});

  @override
  Stream<List<GroupOverview>> watchGroups() => _scoped('groups', (id, m) {
    final g = Group.fromMap(id, m);
    return GroupOverview(
      group: g,
      coachNames: const [],
      memberCount: g.memberChildIds.length,
      pendingRequests: 0,
      upcomingTrainings: 0,
      scheduleSummary: g.scheduleNote ?? '',
    );
  });

  @override
  Future<void> archiveGroup(String groupId, {required bool archived}) =>
      callFunction(functions, 'updateGroup', {'groupId': groupId, 'status': archived ? 'archived' : 'active'});

  @override
  Stream<List<ContentReport>> watchReports() => _scoped('reports', ContentReport.fromMap);

  @override
  Future<void> moderate(String reportId, ModerationDecision decision) =>
      callFunction(functions, 'moderate', {'reportId': reportId, 'decision': decision.name});

  @override
  Stream<List<AuditEntry>> watchAudit() async* {
    final s = await _scope();
    var q = db.collection('auditLog').orderBy('at', descending: true).limit(200);
    if (!s.platform) {
      q = db
          .collection('auditLog')
          .where('clubId', whereIn: s.clubs.isEmpty ? ['-'] : s.clubs.take(30).toList())
          .limit(200);
    }
    yield* q
        .snapshots()
        .map((snap) => snap.docs.map((d) => AuditEntry.fromMap(d.id, d.data())).toList())
        .mapFirebaseErrors();
  }

  @override
  Stream<List<AppUser>> watchAdmins() => db
      .collection('users')
      .where('role', isEqualTo: 'admin')
      .snapshots()
      .map((s) => s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList())
      .mapFirebaseErrors();

  @override
  Future<void> setAdminRole(String uid, AdminRole? role, {List<String> clubIds = const []}) =>
      callFunction(functions, 'setAdminRole', {'uid': uid, 'role': role?.name, 'clubIds': clubIds});

  @override
  Future<List<GroupCompliance>> compliance() async {
    final r = await callFunction(functions, 'adminCompliance');
    return [for (final m in (r['groups'] as List? ?? const [])) GroupCompliance.fromMap(m as Map)];
  }

  /// Aggregated client-side from attendance the admin may read (club scope).
  @override
  Future<List<GroupAttendanceRow>> attendanceReport({required int year, required int month}) => guardFirebase(() async {
    final s = await _scope();
    final groups = s.platform
        ? await db.collection('groups').get()
        : await db
              .collection('groups')
              .where('clubId', whereIn: s.clubs.isEmpty ? ['-'] : s.clubs.take(30).toList())
              .get();
    final from = DateTime(year, month), to = DateTime(year, month + 1);
    final rows = <GroupAttendanceRow>[];
    for (final g in groups.docs) {
      final trainings = await db
          .collection('trainings')
          .where('groupId', isEqualTo: g.id)
          .where('startAt', isGreaterThanOrEqualTo: from)
          .where('startAt', isLessThan: to)
          .get();
      final ids = trainings.docs.where((d) => d['status'] != 'cancelled').map((d) => d.id).toSet();
      final att = await db.collection('attendance').where('groupId', isEqualTo: g.id).get();
      final recs = att.docs.where((d) => ids.contains(d['trainingId'])).toList();
      rows.add(
        GroupAttendanceRow(
          groupId: g.id,
          groupName: g['name'] as String? ?? '',
          clubId: g['clubId'] as String? ?? '',
          sessions: recs.map((d) => d['trainingId']).toSet().length,
          present: recs.where((d) => d['status'] == 'present').length,
          recorded: recs.length,
          members: (g.data()['memberChildIds'] as List? ?? const []).length,
        ),
      );
    }
    return rows;
  });

  @override
  Stream<List<PlanOverview>> watchPlans() => _scoped('trainingPlans', (id, m) {
    final p = TrainingPlan.fromMap(id, m);
    return PlanOverview(
      planId: id,
      title: p.title,
      typeName: p.type.name,
      statusName: p.status.name,
      groupNames: p.groupIds,
      coachName: p.coachName,
      exercises: p.exercises.length,
      startDate: p.startDate.toDateTime(),
    );
  });

  @override
  Future<void> setPaymentManagers(String groupId, List<String> coachIds) =>
      callFunction(functions, 'updateGroup', {'groupId': groupId, 'paymentManagerIds': coachIds});
}
