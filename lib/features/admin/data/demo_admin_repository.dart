import '../../../core/errors/app_exception.dart';
import '../../../core/utils/geo.dart';
import '../../authentication/domain/access_policy.dart';
import '../../authentication/domain/app_user.dart';
import '../../clubs/domain/club.dart';
import '../../demo/data/demo_backend.dart';
import '../../groups/domain/group.dart';
import '../../moderation/data/demo_moderation_repository.dart';
import '../../moderation/domain/report.dart';
import '../../sports/domain/sport.dart';
import '../../attendance/domain/attendance.dart';
import '../../medical_certificates/domain/medical_certificate.dart';
import '../../trainings/domain/training.dart';
import '../../trainings/domain/series.dart';
import '../domain/admin_models.dart';

/// Demo stand-in for the admin callables. Every method re-checks the
/// caller's admin scope exactly like the server (hiding UI is not security).
class DemoAdminRepository implements AdminRepository {
  DemoAdminRepository(this.db);

  final DemoBackend db;

  AppUser _admin() {
    final me = db.me;
    if (!me.isAdmin) throw const PermissionDeniedException('admin');
    return me;
  }

  AppUser _platform() {
    final me = _admin();
    if (!me.isPlatformAdmin) throw const PermissionDeniedException('platform admin');
    return me;
  }

  bool _inScope(AppUser me, String clubId) => me.administersClub(clubId);

  Iterable<Group> _groups(AppUser me) => db.groups.values.where((g) => _inScope(me, g.clubId));

  @override
  Future<AdminStats> stats() async {
    final me = _admin();
    final now = db.clock();
    final groups = _groups(me).toList();
    final groupIds = groups.map((g) => g.id).toSet();
    final childIds = {for (final g in groups) ...g.memberChildIds};
    final parentIds = {for (final g in groups) ...g.parentIds};
    bool coachInScope(AppUser u) => u.isCoach && (me.isPlatformAdmin || u.clubIds.any(me.adminClubIds.contains));
    return AdminStats(
      parents: me.isPlatformAdmin ? db.users.values.where((u) => u.isParent).length : parentIds.length,
      children: me.isPlatformAdmin ? db.children.values.where((c) => !c.isPending).length : childIds.length,
      coaches: db.users.values.where((u) => coachInScope(u) && u.coachStatus == CoachStatus.approved).length,
      clubs: db.clubs.values.where((c) => !c.archived && _inScope(me, c.id)).length,
      activeGroups: groups.where((g) => g.isActive).length,
      upcomingTrainings: db.trainings.values
          .where(
            (t) =>
                groupIds.contains(t.groupId) &&
                t.status.isActive &&
                t.startAt.isAfter(now) &&
                t.startAt.isBefore(now.add(const Duration(days: 7))),
          )
          .length,
      upcomingMatches: db.matches.values
          .where((m) => groupIds.contains(m.groupId) && m.status.isActive && m.startAt.isAfter(now))
          .length,
      pendingCoaches: db.users.values.where((u) => coachInScope(u) && u.coachStatus == CoachStatus.pending).length,
      pendingRequests: db.requests.values
          .where((r) => r.status == RequestStatus.pending && _inScope(me, r.clubId))
          .length,
      openReports: db.reports.values.where((r) => r.isOpen && _inScope(me, r.clubId)).length,
    );
  }

  @override
  Stream<List<CoachSummary>> watchCoaches() => db.watch(() {
    final me = _admin();
    return db.users.values
        .where((u) => u.isCoach && (me.isPlatformAdmin || u.clubIds.any(me.adminClubIds.contains)))
        .map((u) => CoachSummary.fromUser(u, groupCount: db.groups.values.where((g) => g.hasCoach(u.id)).length))
        .toList()
      ..sort(
        (a, b) => a.status.index != b.status.index ? a.status.index - b.status.index : a.fullName.compareTo(b.fullName),
      );
  });

  @override
  Future<void> setCoachStatus(String coachId, CoachStatus status, {String? reason}) async {
    db.requireOnline();
    final me = _admin();
    final coach = db.users[coachId];
    if (coach == null || !coach.isCoach) throw const NotFoundException('coach');
    if (!AccessPolicy.canDecideCoach(me, coach)) throw const PermissionDeniedException('coach scope');
    final needsReason =
        status == CoachStatus.rejected || status == CoachStatus.suspended || status == CoachStatus.revoked;
    final r = (reason ?? '').trim();
    if (needsReason && r.length < 5) throw const ValidationException('reasonRequired');
    db.users[coachId] = AppUser.fromMap(coachId, {
      ...coach.toMap(),
      'coachStatus': status.name,
      'coachStatusReason': needsReason ? r : null,
      'adminRole': coach.adminRole?.name,
      'adminClubIds': coach.adminClubIds,
    });
    final action = switch (status) {
      CoachStatus.approved => 'coach.approve',
      CoachStatus.rejected => 'coach.reject',
      CoachStatus.suspended => 'coach.suspend',
      CoachStatus.revoked => 'coach.revoke',
      CoachStatus.pending => 'coach.reset',
    };
    db.auditLog(action, 'user', coachId, clubId: coach.clubIds.firstOrNull, details: {if (r.isNotEmpty) 'reason': r});
    db.commit();
  }

  @override
  Future<void> assignCoach({required String clubId, required String coachId, required bool assign}) async {
    db.requireOnline();
    final me = _admin();
    if (!AccessPolicy.canManageClub(me, clubId)) throw const PermissionDeniedException('club scope');
    final coach = db.users[coachId];
    if (coach == null || !coach.isCoach) throw const NotFoundException('coach');
    final ids = {...coach.clubIds};
    assign ? ids.add(clubId) : ids.remove(clubId);
    db.users[coachId] = coach.copyWith(clubIds: ids.toList());
    if (!assign) {
      // Unassigning removes the coach from that club's groups.
      for (final g in db.groups.values.where((g) => g.clubId == clubId && g.hasCoach(coachId)).toList()) {
        db.groups[g.id] = g.copyWith(coachIds: g.coachIds.where((c) => c != coachId).toList());
      }
    }
    db.auditLog(assign ? 'club.assignCoach' : 'club.unassignCoach', 'user', coachId, clubId: clubId);
    db.commit();
  }

  @override
  Stream<List<ClubOverview>> watchClubs() => db.watch(() {
    final me = _admin();
    return db.clubs.values.where((c) => _inScope(me, c.id)).map((c) {
      final groups = db.groups.values.where((g) => g.clubId == c.id && g.isActive).toList();
      return ClubOverview(
        club: c,
        groups: groups.length,
        members: {for (final g in groups) ...g.memberChildIds}.length,
        coaches: db.users.values.where((u) => u.isApprovedCoach && u.clubIds.contains(c.id)).length,
      );
    }).toList()..sort(
      (a, b) => a.club.archived != b.club.archived ? (a.club.archived ? 1 : -1) : a.club.name.compareTo(b.club.name),
    );
  });

  @override
  Future<Club> upsertClub(ClubDraft d, {String? clubId}) async {
    db.requireOnline();
    final me = clubId == null ? _platform() : _admin();
    if (clubId != null && !AccessPolicy.canManageClub(me, clubId)) throw const PermissionDeniedException('club scope');
    final errors = ClubDraft.validate(d);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final base = clubId == null ? null : (db.clubs[clubId] ?? (throw const NotFoundException('club')));
    final c = Club(
      id: clubId ?? db.newId('club'),
      name: d.name.trim(),
      address: d.address.trim(),
      sportIds: d.sportIds,
      location: GeoCoord(d.lat, d.lng),
      geohash: Geohash.encode(d.lat, d.lng),
      phone: d.phone,
      description: d.description,
      archived: base?.archived ?? false,
      adminIds: base?.adminIds ?? const [],
    );
    db.clubs[c.id] = c;
    db.auditLog(clubId == null ? 'club.create' : 'club.update', 'club', c.id, clubId: c.id, details: {'name': c.name});
    db.commit();
    return c;
  }

  @override
  Future<void> archiveClub(String clubId, {required bool archived}) async {
    db.requireOnline();
    _platform();
    final c = db.clubs[clubId] ?? (throw const NotFoundException('club'));
    db.clubs[clubId] = c.copyWith(archived: archived);
    db.auditLog(archived ? 'club.archive' : 'club.restore', 'club', clubId, clubId: clubId);
    db.commit();
  }

  @override
  Stream<List<Sport>> watchSports() => db.watch(() {
    _admin();
    return db.sports.values.toList()..sort((a, b) => a.order != b.order ? a.order - b.order : a.name.compareTo(b.name));
  });

  @override
  Future<void> upsertSport(Sport sport) async {
    db.requireOnline();
    _platform();
    if (sport.name.trim().length < 2) throw const ValidationException('validationRequired');
    if (sport.ageMin != null && (sport.ageMin! < 3 || sport.ageMin! > 18)) throw const ValidationException('ageRange');
    db.sports[sport.id] = sport;
    db.auditLog('sport.upsert', 'sport', sport.id, details: {'name': sport.name, 'active': '${sport.active}'});
    db.commit();
  }

  @override
  Stream<List<GroupOverview>> watchGroups() => db.watch(() {
    final me = _admin();
    final now = db.clock();
    return _groups(me).map((g) {
      final series = db.series.values.where((s) => s.groupId == g.id && s.status == SeriesStatus.active).toList();
      return GroupOverview(
        group: g,
        coachNames: g.coachIds.map((id) => db.users[id]?.fullName ?? '—').toList(),
        memberCount: g.memberChildIds.length,
        pendingRequests: db.requests.values.where((r) => r.groupId == g.id && r.status == RequestStatus.pending).length,
        upcomingTrainings: db.trainings.values
            .where((t) => t.groupId == g.id && t.status.isActive && t.startAt.isAfter(now))
            .length,
        scheduleSummary: series.isNotEmpty
            ? series.map((s) => '${s.weekdays.join(',')} · ${s.startTime}').join('; ')
            : (g.scheduleNote ?? ''),
      );
    }).toList()..sort((a, b) => a.group.name.compareTo(b.group.name));
  });

  @override
  Future<void> archiveGroup(String groupId, {required bool archived}) async {
    db.requireOnline();
    final me = _admin();
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.canManageClub(me, g.clubId)) throw const PermissionDeniedException('club scope');
    db.groups[groupId] = g.copyWith(status: archived ? GroupStatus.archived : GroupStatus.active);
    db.auditLog(
      'group.update',
      'group',
      groupId,
      clubId: g.clubId,
      details: {'status': archived ? 'archived' : 'active'},
    );
    db.commit();
  }

  @override
  Stream<List<ContentReport>> watchReports() => db.watch(() {
    final me = _admin();
    return db.reports.values.where((r) => _inScope(me, r.clubId)).toList()
      ..sort((a, b) => a.isOpen != b.isOpen ? (a.isOpen ? -1 : 1) : b.createdAt.compareTo(a.createdAt));
  });

  @override
  Future<void> moderate(String reportId, ModerationDecision decision) async {
    db.requireOnline();
    final me = _admin();
    final r = db.reports[reportId] ?? (throw const NotFoundException('report'));
    if (!AccessPolicy.canModerate(me, r.clubId)) throw const PermissionDeniedException('club scope');
    if (!r.isOpen) throw const ValidationException('reportClosed');
    DemoModeration.apply(db, r, decision);
    db.reports[reportId] = r.decide(decision, me.id, db.clock());
    // Other open reports on the same content are resolved together.
    for (final o
        in db.reports.values.where((o) => o.id != reportId && o.targetPath == r.targetPath && o.isOpen).toList()) {
      db.reports[o.id] = o.decide(decision, me.id, db.clock());
    }
    db.auditLog(
      'moderation.decide',
      r.targetType.name,
      r.targetPath,
      clubId: r.clubId,
      details: {'decision': decision.name},
    );
    db.commit();
  }

  @override
  Stream<List<AuditEntry>> watchAudit() => db.watch(() {
    final me = _admin();
    return db.audit.where((e) => AccessPolicy.canViewAudit(me, e.clubId)).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
  });

  @override
  Stream<List<AppUser>> watchAdmins() => db.watch(() {
    _platform();
    return db.users.values.where((u) => u.isAdmin).toList()..sort((a, b) => a.fullName.compareTo(b.fullName));
  });

  @override
  Future<void> setAdminRole(String uid, AdminRole? role, {List<String> clubIds = const []}) async {
    db.requireOnline();
    final me = _platform();
    if (uid == me.id) throw const ValidationException('cannotChangeOwnRole');
    final u = db.users[uid] ?? (throw const NotFoundException('user'));
    db.users[uid] = AppUser.fromMap(uid, {
      ...u.toMap(),
      // A coach/parent keeps their role; admin rights live in the claims.
      'role': u.role.name,
      'adminRole': role?.name,
      'adminClubIds': role == AdminRole.club ? clubIds : const <String>[],
      'coachStatusReason': u.coachStatusReason,
    });
    db.auditLog('role.set', 'user', uid, details: {'role': role?.name ?? 'none', 'clubs': clubIds.join(',')});
    db.commit();
  }

  // ── v1.3 ─────────────────────────────────────────────────────────────

  /// Mirrors `adminCompliance`: counts only (no names, no documents).
  @override
  Future<List<GroupCompliance>> compliance() async {
    final me = _admin();
    final now = db.clock();
    return [
      for (final g in _groups(me).where((g) => g.isActive))
        () {
          var v = 0, e = 0, x = 0, m = 0;
          for (final cid in g.memberChildIds) {
            final certs = db.certificates.values.where((c) => c.childId == cid);
            switch (CertificatePolicy.childStatus(certs, now, sportId: g.sportId)) {
              case CertificateStatus.valid:
                v++;
              case CertificateStatus.expiring:
                e++;
              case CertificateStatus.expired:
                x++;
              case CertificateStatus.missing:
                m++;
            }
          }
          return GroupCompliance(
            groupId: g.id,
            groupName: g.name,
            clubId: g.clubId,
            valid: v,
            expiring: e,
            expired: x,
            missing: m,
          );
        }(),
    ];
  }

  @override
  Future<List<GroupAttendanceRow>> attendanceReport({required int year, required int month}) async {
    final me = _admin();
    final rows = <GroupAttendanceRow>[];
    for (final g in _groups(me)) {
      final ids = db.trainings.values
          .where(
            (t) =>
                t.groupId == g.id &&
                t.startAt.year == year &&
                t.startAt.month == month &&
                t.status != TrainingStatus.cancelled,
          )
          .map((t) => t.id)
          .toSet();
      final recs = db.attendance.values.where((a) => ids.contains(a.trainingId)).toList();
      rows.add(
        GroupAttendanceRow(
          groupId: g.id,
          groupName: g.name,
          clubId: g.clubId,
          sessions: recs.map((r) => r.trainingId).toSet().length,
          present: recs.where((r) => r.status == AttendanceStatus.present).length,
          recorded: recs.length,
          members: g.memberChildIds.length,
        ),
      );
    }
    return rows;
  }

  @override
  Stream<List<PlanOverview>> watchPlans() => db.watch(() {
    final me = _admin();
    return db.trainingPlans.values.where((p) => _inScope(me, p.clubId)).map((p) {
      return PlanOverview(
        planId: p.id,
        title: p.title,
        typeName: p.type.name,
        statusName: p.status.name,
        groupNames: p.groupIds.map((id) => db.groups[id]?.name ?? id).toList(),
        coachName: p.coachName,
        exercises: p.exercises.length,
        startDate: p.startDate.toDateTime(),
      );
    }).toList()..sort((a, b) => b.startDate.compareTo(a.startDate));
  });

  @override
  Future<void> setPaymentManagers(String groupId, List<String> coachIds) async {
    db.requireOnline();
    final me = _admin();
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.canManageClub(me, g.clubId)) throw const PermissionDeniedException('club scope');
    final valid = coachIds.where(g.coachIds.contains).toList();
    db.groups[groupId] = g.copyWith(paymentManagerIds: valid);
    db.auditLog('group.paymentManagers', 'group', groupId, clubId: g.clubId, details: {'coaches': valid.join(',')});
    db.commit();
  }

  @override
  Future<void> setMediaDownloads(String groupId, {required bool enabled}) async {
    db.requireOnline();
    final me = _admin();
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.canManageClub(me, g.clubId)) throw const PermissionDeniedException('club scope');
    db.groups[groupId] = g.copyWith(mediaDownloadsEnabled: enabled);
    db.auditLog('group.mediaPolicy', 'group', groupId, clubId: g.clubId, details: {'downloads': '$enabled'});
    db.commit();
  }

  @override
  Stream<List<MediaDownloadRow>> watchMediaDownloads() => db.watch(() {
    final me = _admin();
    return [
      for (final e in db.mediaDownloads)
        if (_inScope(me, e.clubId))
          MediaDownloadRow(
            postId: e.postId,
            userId: e.userId,
            userName: db.users[e.userId]?.fullName ?? e.userId,
            role: e.role,
            groupId: e.groupId,
            mediaType: e.mediaType,
            at: e.at,
          ),
    ]..sort((a, b) => b.at.compareTo(a.at));
  });
}
