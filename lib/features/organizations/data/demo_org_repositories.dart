import '../../../core/errors/app_exception.dart';
import '../../../core/utils/geo.dart';
import '../../admin/domain/admin_models.dart';
import '../../authentication/domain/access_policy.dart';
import '../../authentication/domain/app_user.dart';
import '../../brain_academy/domain/brain_models.dart';
import '../../brain_academy/domain/scoring.dart';
import '../../clubs/domain/club.dart';
import '../../demo/data/demo_backend.dart';
import '../../notifications/domain/notification_models.dart';
import '../../trainings/domain/training.dart';
import '../domain/coach_contact.dart';
import '../domain/organization.dart';
import '../domain/repositories.dart';
import '../domain/scheduling.dart';

/// Tenant membership resolved on the "server" (demo backend). Mirrors the
/// `isOrgMember()` rule: explicit membership records, admin claims, club
/// lists, or a child in one of the organization's groups.
class TenantAccess {
  TenantAccess._();

  static bool isMember(DemoBackend db, AppUser u, String orgId) {
    if (u.administersClub(orgId)) return true;
    final m = db.memberships['$orgId|${u.id}'];
    if (m != null && m.active) return true;
    if (u.clubIds.contains(orgId)) return true;
    final groups = db.groups.values.where((g) => g.clubId == orgId);
    if (u.isParent) return groups.any((g) => g.parentIds.contains(u.id));
    if (u.isStudent) {
      final c = db.children[u.lastContext.childId];
      return c != null && AccessPolicy.isStudentOf(u, c) && groups.any((g) => g.hasChild(c.id));
    }
    if (u.isCoach) return groups.any((g) => g.coachIds.contains(u.id));
    return false;
  }

  /// Organizations of a user (several are possible).
  static List<String> orgsOf(DemoBackend db, AppUser u) => [
    for (final id in db.clubs.keys)
      if (isMember(db, u, id)) id,
  ];
}

class DemoOrganizationsRepository implements OrganizationsRepository {
  DemoOrganizationsRepository(this.db);

  final DemoBackend db;

  AppUser _platform() {
    final me = db.me;
    if (!me.isPlatformAdmin) throw const PermissionDeniedException('platform');
    return me;
  }

  AppUser _orgAdmin(String orgId) {
    final me = db.me;
    if (!me.administersClub(orgId)) throw const PermissionDeniedException('org scope');
    return me;
  }

  void _requireClub(String orgId) {
    if (!db.clubs.containsKey(orgId)) throw const NotFoundException('organization');
  }

  @override
  Stream<List<OrgConfig>> watchConfigs() => db.watch(() {
    final me = db.me;
    final ids = me.isPlatformAdmin ? db.clubs.keys.toList() : TenantAccess.orgsOf(db, me);
    return [for (final id in ids) db.orgConfig(id)]..sort((a, b) => a.orgId.compareTo(b.orgId));
  });

  @override
  Stream<OrgConfig> watchConfig(String orgId) => db.watch(() {
    _requireClub(orgId);
    if (!TenantAccess.isMember(db, db.me, orgId)) throw const PermissionDeniedException('org');
    return db.orgConfig(orgId);
  });

  @override
  Future<Club> createOrganization({
    required ClubDraft club,
    required OrgPlan plan,
    required OrgBranding branding,
    String timezone = OrgTimeZones.tbilisi,
    String defaultLanguage = 'ka',
  }) async {
    db.requireOnline();
    _platform();
    final errors = ClubDraft.validate(club);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    if (!OrgBranding.validColor(branding.primaryColor)) throw const ValidationException('brandColor');
    final c = Club(
      id: db.newId('org'),
      name: club.name.trim(),
      address: club.address.trim(),
      sportIds: club.sportIds,
      location: GeoCoord(club.lat, club.lng),
      geohash: Geohash.encode(club.lat, club.lng),
      phone: club.phone,
      description: club.description,
    );
    db.clubs[c.id] = c;
    db.orgConfigs[c.id] = OrgConfig(
      orgId: c.id,
      plan: plan,
      allowedModules: plan.defaultModules,
      // Child-safety defaults: restricted modules start switched off.
      enabledModules: plan.defaultModules.difference(restrictedModules),
      branding: branding.names.isEmpty ? branding.copyWith(names: {'ka': c.name}) : branding,
      timezone: OrgTimeZones.normalize(timezone),
      defaultLanguage: defaultLanguage,
      limits: plan.defaultLimits,
      updatedAt: db.clock(),
    );
    db.auditLog('org.create', 'club', c.id, clubId: c.id, details: {'name': c.name, 'plan': plan.name});
    db.commit();
    return c;
  }

  @override
  Future<void> updatePlatformSettings(
    String orgId, {
    OrgStatus? status,
    OrgPlan? plan,
    Set<OrgModule>? allowedModules,
    OrgLimits? limits,
  }) async {
    db.requireOnline();
    _platform();
    _requireClub(orgId);
    final old = db.orgConfig(orgId);
    final allowed = allowedModules ?? (plan != null ? plan.defaultModules : old.allowedModules);
    db.orgConfigs[orgId] = old.copyWith(
      status: status,
      plan: plan,
      allowedModules: allowed,
      // Withdrawing a module also switches it off.
      enabledModules: old.enabledModules.intersection(allowed),
      limits: limits,
      updatedAt: db.clock(),
    );
    if (status != null) db.clubs[orgId] = db.clubs[orgId]!.copyWith(archived: status == OrgStatus.deactivated);
    db.auditLog(
      'org.platform',
      'club',
      orgId,
      clubId: orgId,
      details: {
        if (status != null) 'status': status.name,
        if (plan != null) 'plan': plan.name,
        'allowed': allowed.map((m) => m.name).join(','),
      },
    );
    db.commit();
  }

  @override
  Future<void> updateOrgSettings(
    String orgId, {
    Set<OrgModule>? enabledModules,
    OrgBranding? branding,
    String? defaultLanguage,
    String? timezone,
    LeaderboardSettings? leaderboard,
    int? bookingBufferMin,
    List<String>? sportIds,
  }) async {
    db.requireOnline();
    _orgAdmin(orgId);
    _requireClub(orgId);
    final old = db.orgConfig(orgId);
    if (!old.isActive) throw const ValidationException('orgInactive');
    if (enabledModules != null && !old.allowedModules.containsAll(enabledModules)) {
      throw const PermissionDeniedException('moduleNotAllowed');
    }
    if (branding != null && !OrgBranding.validColor(branding.primaryColor)) {
      throw const ValidationException('brandColor');
    }
    if (leaderboard != null && leaderboard.enabled && !old.allowedModules.contains(OrgModule.leaderboards)) {
      throw const PermissionDeniedException('moduleNotAllowed');
    }
    if (sportIds != null && sportIds.any((s) => !db.sports.containsKey(s))) throw const ValidationException('sport');
    db.orgConfigs[orgId] = old.copyWith(
      enabledModules: enabledModules,
      branding: branding,
      defaultLanguage: defaultLanguage,
      timezone: timezone == null ? null : OrgTimeZones.normalize(timezone),
      leaderboard: leaderboard,
      bookingBufferMin: bookingBufferMin?.clamp(0, 120),
      updatedAt: db.clock(),
    );
    if (sportIds != null) db.clubs[orgId] = db.clubs[orgId]!.copyWith(sportIds: sportIds);
    db.auditLog('org.settings', 'club', orgId, clubId: orgId);
    db.commit();
  }

  @override
  Future<void> setOrgAdmin(String orgId, String userId, {required bool admin}) async {
    db.requireOnline();
    final me = _platform();
    _requireClub(orgId);
    if (userId == me.id) throw const ValidationException('cannotChangeOwnRole');
    final u = db.users[userId] ?? (throw const NotFoundException('user'));
    final clubs = {...u.adminClubIds};
    admin ? clubs.add(orgId) : clubs.remove(orgId);
    db.users[userId] = AppUser.fromMap(userId, {
      ...u.toMap(),
      'role': u.role.name,
      'adminRole': u.isPlatformAdmin ? AdminRole.platform.name : (clubs.isEmpty ? null : AdminRole.club.name),
      'adminClubIds': clubs.toList(),
      'coachStatusReason': u.coachStatusReason,
    });
    final key = '$orgId|$userId';
    final m = db.memberships[key];
    final roles = {...?m?.roles};
    admin ? roles.add(OrgRole.admin) : roles.remove(OrgRole.admin);
    db.memberships[key] = OrgMembership(orgId: orgId, userId: userId, roles: roles, active: roles.isNotEmpty);
    db.clubs[orgId] = db.clubs[orgId]!.copyWith(
      adminIds: {...db.clubs[orgId]!.adminIds.where((a) => a != userId), if (admin) userId}.toList(),
    );
    db.auditLog(admin ? 'org.admin.assign' : 'org.admin.remove', 'user', userId, clubId: orgId);
    db.commit();
  }

  @override
  Future<void> setOrgCoach(String orgId, String coachId, {required bool member}) async {
    db.requireOnline();
    _orgAdmin(orgId);
    _requireClub(orgId);
    final u = db.users[coachId] ?? (throw const NotFoundException('user'));
    if (!u.isCoach) throw const ValidationException('notCoach');
    final cfg = db.orgConfig(orgId);
    final coaches = db.users.values.where((x) => x.isCoach && x.clubIds.contains(orgId)).length;
    if (member && !u.clubIds.contains(orgId) && coaches >= cfg.limits.maxCoaches) {
      throw const ValidationException('limitCoaches');
    }
    final clubs = {...u.clubIds};
    member ? clubs.add(orgId) : clubs.remove(orgId);
    db.users[coachId] = u.copyWith(clubIds: clubs.toList());
    final key = '$orgId|$coachId';
    final roles = {...?db.memberships[key]?.roles};
    member ? roles.add(OrgRole.coach) : roles.remove(OrgRole.coach);
    db.memberships[key] = OrgMembership(orgId: orgId, userId: coachId, roles: roles, active: roles.isNotEmpty);
    db.auditLog(member ? 'org.coach.add' : 'org.coach.remove', 'user', coachId, clubId: orgId);
    db.commit();
  }

  @override
  Stream<List<OrgMembership>> watchMyMemberships() => db.watch(() {
    final me = db.me;
    return [
      for (final id in TenantAccess.orgsOf(db, me))
        db.memberships['$id|${me.id}'] ??
            OrgMembership(
              orgId: id,
              userId: me.id,
              roles: {
                if (me.administersClub(id)) OrgRole.admin,
                if (me.isCoach) OrgRole.coach,
                if (me.isParent) OrgRole.parent,
                if (me.isStudent) OrgRole.student,
              },
            ),
    ];
  });

  @override
  Stream<List<OrgMembership>> watchMembers(String orgId) => db.watch(() {
    _orgAdmin(orgId);
    return db.memberships.values.where((m) => m.orgId == orgId).toList();
  });

  @override
  Stream<List<SportsProgram>> watchPrograms(String orgId) => db.watch(() {
    if (!TenantAccess.isMember(db, db.me, orgId)) throw const PermissionDeniedException('org');
    return db.programs.values.where((p) => p.orgId == orgId).toList()..sort((a, b) => a.name.compareTo(b.name));
  });

  @override
  Future<SportsProgram> upsertProgram(SportsProgram p) async {
    db.requireOnline();
    _orgAdmin(p.orgId);
    _requireClub(p.orgId);
    if (!db.orgConfig(p.orgId).isActive) throw const ValidationException('orgInactive');
    final errors = SportsProgram.validate(p);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    if (!(db.clubs[p.orgId]!.sportIds.contains(p.sportId))) throw const ValidationException('sportNotInOrg');
    for (final g in p.groupIds) {
      if (db.groups[g]?.clubId != p.orgId) throw const PermissionDeniedException('wrongTenant');
    }
    for (final c in p.coachIds) {
      if (!(db.users[c]?.clubIds.contains(p.orgId) ?? false)) throw const ValidationException('coachNotInOrg');
    }
    if (p.roomId != null && db.rooms[p.roomId]?.orgId != p.orgId) throw const PermissionDeniedException('wrongTenant');
    final saved = p.id.isEmpty ? SportsProgram.fromMap(db.newId('program'), p.toMap()) : p;
    db.programs[saved.id] = saved;
    db.auditLog('program.upsert', 'program', saved.id, clubId: p.orgId, details: {'name': p.name});
    db.commit();
    return saved;
  }

  @override
  Future<TenantHealth> health(String orgId) async {
    final me = db.me;
    if (!me.administersClub(orgId)) throw const PermissionDeniedException('org scope');
    final now = db.clock();
    final groups = db.groups.values.where((g) => g.clubId == orgId).toList();
    final ids = {for (final g in groups) g.id};
    final children = {for (final g in groups) ...g.memberChildIds};
    final weekEnd = now.add(const Duration(days: 7));
    return TenantHealth(
      orgId: orgId,
      students: children.length,
      coaches: db.users.values.where((u) => u.isCoach && u.clubIds.contains(orgId)).length,
      groups: groups.length,
      rooms: db.rooms.values.where((r) => r.orgId == orgId && r.status != RoomStatus.archived).length,
      upcomingEvents:
          db.trainings.values
              .where((t) => ids.contains(t.groupId) && t.status.isActive && t.startAt.isAfter(now))
              .length +
          db.matches.values.where((m) => ids.contains(m.groupId) && m.status.isActive && m.startAt.isAfter(now)).length,
      bookingsThisWeek: db.bookings.values
          .where((b) => b.orgId == orgId && b.isActive && b.startAt.isAfter(now) && b.startAt.isBefore(weekEnd))
          .length,
      brainPlays7d: db.brainResults
          .where((r) => children.contains(r.childId) && r.playedAt.isAfter(now.subtract(const Duration(days: 7))))
          .length,
    );
  }
}

/// Demo scheduling. Every write is validated here (the "server") and runs
/// without an `await` between the conflict check and the insert, so two
/// concurrent requests can never both reserve the same slot — the same
/// guarantee the production callable gets from a Firestore transaction
/// over per-room-day lock documents.
class DemoSchedulingRepository implements SchedulingRepository {
  DemoSchedulingRepository(this.db);

  final DemoBackend db;

  AppUser _orgAdmin(String orgId) {
    final me = db.me;
    if (!me.administersClub(orgId)) throw const PermissionDeniedException('org scope');
    db.requireModule(orgId, OrgModule.roomScheduling);
    return me;
  }

  Room _room(String orgId, String roomId) {
    final r = db.rooms[roomId] ?? (throw const NotFoundException('room'));
    if (r.orgId != orgId) throw const PermissionDeniedException('wrongTenant');
    return r;
  }

  Iterable<Booking> _orgBookings(String orgId) => db.bookings.values.where((b) => b.orgId == orgId);

  @override
  Stream<List<Room>> watchRooms(String orgId) => db.watch(() {
    if (!TenantAccess.isMember(db, db.me, orgId)) throw const PermissionDeniedException('org');
    return db.rooms.values.where((r) => r.orgId == orgId).toList()..sort((a, b) => a.name.compareTo(b.name));
  });

  @override
  Future<Room> upsertRoom(Room r) async {
    db.requireOnline();
    _orgAdmin(r.orgId);
    final errors = Room.validate(r);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final isNew = r.id.isEmpty;
    if (!isNew) _room(r.orgId, r.id);
    final count = db.rooms.values.where((x) => x.orgId == r.orgId && x.status != RoomStatus.archived).length;
    if (isNew && count >= db.orgConfig(r.orgId).limits.maxRooms) throw const ValidationException('limitRooms');
    final saved = isNew ? Room.fromMap(db.newId('room'), r.toMap()) : r;
    db.rooms[saved.id] = saved;
    db.auditLog(isNew ? 'room.create' : 'room.update', 'room', saved.id, clubId: r.orgId, details: {'name': r.name});
    db.commit();
    return saved;
  }

  @override
  Future<void> setRoomStatus(String orgId, String roomId, RoomStatus status) async {
    db.requireOnline();
    _orgAdmin(orgId);
    final r = _room(orgId, roomId);
    db.rooms[roomId] = r.copyWith(status: status);
    db.auditLog('room.status', 'room', roomId, clubId: orgId, details: {'status': status.name});
    db.commit();
  }

  @override
  Stream<List<Booking>> watchBookings(String orgId, {required DateTime from, required DateTime to}) => db.watch(() {
    final me = db.me;
    if (!TenantAccess.isMember(db, me, orgId)) throw const PermissionDeniedException('org');
    final admin = me.administersClub(orgId);
    return _orgBookings(orgId)
        .where((b) => b.startAt.isBefore(to) && b.endAt.isAfter(from))
        // Coaches see the whole room plan (to pick free slots); parents and
        // students never get room bookings, only their own events.
        .where((_) => admin || me.isApprovedCoach)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  });

  List<BookingConflict> _check(Booking b, {bool allowGroupOverlap = false, Set<String> ignore = const {}}) {
    final cfg = db.orgConfig(b.orgId);
    final room = _room(b.orgId, b.roomId);
    return ConflictChecker.check(
      b,
      room: room,
      existing: _orgBookings(b.orgId),
      timezone: cfg.timezone,
      bufferMin: cfg.bookingBufferMin,
      ignoreIds: ignore,
    ).where((c) => !(allowGroupOverlap && c.code == ConflictCode.groupOverlap)).toList();
  }

  Never _reject(Booking b, List<BookingConflict> conflicts, {Set<String> ignore = const {}}) {
    final cfg = db.orgConfig(b.orgId);
    final room = db.rooms[b.roomId];
    throw BookingRejected(
      conflicts,
      alternatives: room == null
          ? const []
          : ConflictChecker.alternatives(
              b,
              room: room,
              existing: _orgBookings(b.orgId),
              timezone: cfg.timezone,
              bufferMin: cfg.bookingBufferMin,
              ignoreIds: ignore,
            ),
      freeRooms: ConflictChecker.freeRooms(
        b,
        rooms: db.rooms.values.where((r) => r.orgId == b.orgId),
        existing: _orgBookings(b.orgId).where((x) => !ignore.contains(x.id)),
        timezone: cfg.timezone,
        bufferMin: cfg.bookingBufferMin,
      ),
    );
  }

  void _validateRefs(Booking b) {
    if (b.groupId != null && db.groups[b.groupId]?.clubId != b.orgId) {
      throw const PermissionDeniedException('wrongTenant');
    }
    if (b.coachId != null && !(db.users[b.coachId]?.clubIds.contains(b.orgId) ?? false)) {
      throw const ValidationException('coachNotInOrg');
    }
    if (b.programId != null && db.programs[b.programId]?.orgId != b.orgId) {
      throw const PermissionDeniedException('wrongTenant');
    }
  }

  @override
  Future<List<BookingConflict>> preview(Booking draft, {Set<String> ignoreIds = const {}}) async {
    _orgAdmin(draft.orgId);
    return _check(draft, ignore: ignoreIds);
  }

  /// Linked training for a group training booking: the booking is the
  /// source of truth for time and room; the training mirrors it.
  Training? _linkTraining(Booking b) {
    if (b.kind != BookingKind.training || b.groupId == null) return null;
    final room = db.rooms[b.roomId]!;
    final t = Training(
      id: db.newId('tr'),
      groupId: b.groupId!,
      venueId: room.venueId ?? '',
      startAt: b.startAt,
      durationMin: b.duration.inMinutes,
      focus: const [],
      description: b.title,
      createdBy: db.me.id,
      updatedAt: db.clock(),
      roomId: b.roomId,
    );
    db.trainings[t.id] = t;
    return t;
  }

  @override
  Future<Booking> createBooking(Booking draft, {bool allowGroupOverlap = false}) async {
    db.requireOnline();
    final me = _orgAdmin(draft.orgId);
    _validateRefs(draft);
    // ── atomic section: check + write, no await in between ──
    final conflicts = _check(draft, allowGroupOverlap: allowGroupOverlap);
    if (conflicts.isNotEmpty) _reject(draft, conflicts);
    var b = draft.copyWith(id: db.newId('booking'), createdBy: me.id, updatedAt: db.clock());
    final t = _linkTraining(b);
    if (t != null) b = b.copyWith(eventId: t.id);
    db.bookings[b.id] = b;
    if (t != null) db.dispatch(NotificationType.newTraining, db.groups[t.groupId]!, route: '/training/${t.id}');
    db.auditLog('booking.create', 'booking', b.id, clubId: b.orgId, details: {'room': b.roomId});
    db.commit();
    return b;
  }

  @override
  Future<List<Booking>> createRecurring(Booking template, WeeklyRule rule, {bool allowGroupOverlap = false}) async {
    db.requireOnline();
    final me = _orgAdmin(template.orgId);
    _validateRefs(template);
    if (rule.weekdays.isEmpty || rule.until.isBefore(rule.from)) throw const ValidationException('recurrence');
    final cfg = db.orgConfig(template.orgId);
    final occ = rule.occurrences(cfg.timezone);
    if (occ.isEmpty) throw const ValidationException('recurrence');
    // Check EVERY occurrence (also against each other) before writing.
    final pending = <Booking>[];
    final seriesId = db.newId('series');
    for (final (s, e) in occ) {
      final b = template.copyWith(
        id: '$seriesId-${pending.length}',
        startAt: s,
        endAt: e,
        seriesId: seriesId,
        rule: rule,
      );
      final conflicts = ConflictChecker.check(
        b,
        room: _room(b.orgId, b.roomId),
        existing: [..._orgBookings(b.orgId), ...pending],
        timezone: cfg.timezone,
        bufferMin: cfg.bookingBufferMin,
      ).where((c) => !(allowGroupOverlap && c.code == ConflictCode.groupOverlap)).toList();
      if (conflicts.isNotEmpty) _reject(b, conflicts);
      pending.add(b);
    }
    final out = <Booking>[];
    for (final p in pending) {
      var b = p.copyWith(id: db.newId('booking'), createdBy: me.id, updatedAt: db.clock());
      final t = _linkTraining(b);
      if (t != null) b = b.copyWith(eventId: t.id);
      db.bookings[b.id] = b;
      out.add(b);
    }
    if (template.groupId != null && template.kind == BookingKind.training) {
      db.dispatch(
        NotificationType.newTraining,
        db.groups[template.groupId]!,
        route: '/calendar',
        dedupeKey: 'series:$seriesId',
      );
    }
    db.auditLog('booking.series', 'booking', seriesId, clubId: template.orgId, details: {'count': '${out.length}'});
    db.commit();
    return out;
  }

  void _syncTraining(Booking before, Booking after) {
    final t = after.eventId == null ? null : db.trainings[after.eventId];
    if (t == null) return;
    final moved = before.startAt != after.startAt || before.endAt != after.endAt || before.roomId != after.roomId;
    if (!moved) return;
    final room = db.rooms[after.roomId];
    final next = t.copyWith(
      startAt: after.startAt,
      durationMin: after.duration.inMinutes,
      venueId: room?.venueId ?? t.venueId,
      roomId: after.roomId,
      status: TrainingStatus.moved,
      previousStartAt: t.startAt,
      previousVenueId: (room?.venueId ?? t.venueId) != t.venueId ? t.venueId : null,
      scheduleVersion: t.scheduleVersion + 1,
      updatedAt: db.clock(),
      detached: t.isRecurring ? true : null,
    );
    db.trainings[t.id] = next;
    final g = db.groups[t.groupId];
    if (g != null) {
      db.announceScheduleChange(
        g,
        eventId: t.id,
        eventType: 'training',
        version: next.scheduleVersion,
        text: 'ვარჯიშის განრიგი შეიცვალა. გთხოვთ, დაადასტუროთ დასწრება.',
        route: '/training/${t.id}',
      );
    }
  }

  @override
  Future<Booking> updateBooking(Booking updated, {bool allowGroupOverlap = false}) async {
    db.requireOnline();
    _orgAdmin(updated.orgId);
    final old = db.bookings[updated.id] ?? (throw const NotFoundException('booking'));
    if (old.orgId != updated.orgId) throw const PermissionDeniedException('wrongTenant');
    _validateRefs(updated);
    final conflicts = _check(updated, allowGroupOverlap: allowGroupOverlap);
    if (conflicts.isNotEmpty) _reject(updated, conflicts, ignore: {updated.id});
    // Editing one occurrence detaches it from its series.
    final b = updated.copyWith(updatedAt: db.clock(), clearSeries: old.seriesId != null);
    db.bookings[b.id] = b;
    _syncTraining(old, b);
    db.auditLog('booking.update', 'booking', b.id, clubId: b.orgId);
    db.commit();
    return b;
  }

  @override
  Future<List<Booking>> updateSeriesFrom(
    String bookingId, {
    required int startMinute,
    required int durationMin,
    String? roomId,
  }) async {
    db.requireOnline();
    final anchor = db.bookings[bookingId] ?? (throw const NotFoundException('booking'));
    _orgAdmin(anchor.orgId);
    final sid = anchor.seriesId ?? (throw const ValidationException('notRecurring'));
    final cfg = db.orgConfig(anchor.orgId);
    final affected =
        db.bookings.values.where((b) => b.seriesId == sid && b.isActive && !b.startAt.isBefore(anchor.startAt)).toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final ignore = {for (final b in affected) b.id};
    final next = <Booking>[];
    for (final b in affected) {
      final w = OrgTimeZones.wall(b.startAt, cfg.timezone);
      final s = OrgTimeZones.instant(cfg.timezone, w.year, w.month, w.day, startMinute ~/ 60, startMinute % 60);
      final n = b.copyWith(
        startAt: s,
        endAt: s.add(Duration(minutes: durationMin)),
        roomId: roomId,
      );
      final conflicts = ConflictChecker.check(
        n,
        room: _room(n.orgId, n.roomId),
        existing: [..._orgBookings(n.orgId).where((x) => !ignore.contains(x.id)), ...next],
        timezone: cfg.timezone,
        bufferMin: cfg.bookingBufferMin,
      );
      if (conflicts.isNotEmpty) _reject(n, conflicts, ignore: ignore);
      next.add(n);
    }
    for (var i = 0; i < next.length; i++) {
      db.bookings[next[i].id] = next[i].copyWith(updatedAt: db.clock());
      _syncTraining(affected[i], next[i]);
    }
    db.auditLog('booking.series.update', 'booking', sid, clubId: anchor.orgId, details: {'count': '${next.length}'});
    db.commit();
    return next;
  }

  @override
  Future<void> cancelBooking(String bookingId, {SeriesEditScope scope = SeriesEditScope.thisOccurrence}) async {
    db.requireOnline();
    final b = db.bookings[bookingId] ?? (throw const NotFoundException('booking'));
    _orgAdmin(b.orgId);
    final targets = scope == SeriesEditScope.thisAndFuture && b.seriesId != null
        ? db.bookings.values.where((x) => x.seriesId == b.seriesId && !x.startAt.isBefore(b.startAt)).toList()
        : [b];
    for (final x in targets) {
      db.bookings[x.id] = x.copyWith(status: BookingStatus.cancelled, updatedAt: db.clock());
      final t = x.eventId == null ? null : db.trainings[x.eventId];
      if (t != null && t.status.isActive) {
        db.trainings[t.id] = t.copyWith(
          status: TrainingStatus.cancelled,
          cancelReasonCode: CancelReasonCode.venueBusy,
          cancelReason: 'დარბაზის დაჯავშნა გაუქმდა',
          cancelledAt: db.clock(),
          cancelledBy: db.me.id,
          updatedAt: db.clock(),
        );
        final g = db.groups[t.groupId];
        if (g != null) {
          db.dispatch(
            NotificationType.trainingChanged,
            g,
            route: '/training/${t.id}',
            args: {'kind': 'cancelled'},
            dedupeKey: 'cancel:${t.id}',
          );
        }
      }
    }
    db.auditLog('booking.cancel', 'booking', bookingId, clubId: b.orgId, details: {'count': '${targets.length}'});
    db.commit();
  }
}

class DemoLeaderboardRepository implements LeaderboardRepository {
  DemoLeaderboardRepository(this.db);

  final DemoBackend db;

  bool _canSee(AppUser me, String childId) {
    final c = db.children[childId];
    if (c == null) return false;
    return AccessPolicy.isParentOf(me, c) || AccessPolicy.isStudentOf(me, c);
  }

  bool _inOrg(String orgId, String childId) =>
      db.groups.values.any((g) => g.clubId == orgId && g.isActive && g.hasChild(childId));

  @override
  Stream<LeaderboardConsent?> watchConsent(String orgId, String childId) => db.watch(() {
    if (!_canSee(db.me, childId)) throw const PermissionDeniedException('consent');
    return db.leaderboardConsents['$orgId|$childId'];
  });

  @override
  Future<void> setConsent(
    String orgId,
    String childId, {
    required bool granted,
    DisplayNameMode mode = DisplayNameMode.pseudonym,
  }) async {
    db.requireOnline();
    final me = db.me;
    final c = db.requireChild(childId);
    // Only a guardian decides — never the child, coach or organization.
    if (!AccessPolicy.isParentOf(me, c)) throw const PermissionDeniedException('consent');
    if (!_inOrg(orgId, childId)) throw const PermissionDeniedException('wrongTenant');
    db.leaderboardConsents['$orgId|$childId'] = LeaderboardConsent(
      orgId: orgId,
      childId: childId,
      guardianId: me.id,
      granted: granted,
      mode: mode,
      displayName: mode == DisplayNameMode.pseudonym
          ? LeaderboardConsent.pseudonymFor(childId)
          : LeaderboardConsent.firstNameInitial(c.firstName, c.lastName),
      at: db.clock(),
    );
    db.auditLog(granted ? 'leaderboard.consent' : 'leaderboard.revoke', 'child', childId, clubId: orgId);
    db.commit();
  }

  /// Server-side ranking over stored results only.
  @override
  Stream<LeaderboardBoard> watchBoard(
    String orgId,
    String childId, {
    required LeaderboardPeriod period,
    BrainGame? game,
  }) => db.watch(() {
    final me = db.me;
    if (!_canSee(me, childId) || !_inOrg(orgId, childId)) throw const PermissionDeniedException('leaderboard');
    final cfg = db.orgConfig(orgId);
    final now = db.clock();
    final participants = <LeaderboardParticipant>[];
    for (final consent in db.leaderboardConsents.values) {
      if (consent.orgId != orgId || !consent.granted || !_inOrg(orgId, consent.childId)) continue;
      final c = db.children[consent.childId];
      if (c == null) continue;
      participants.add(
        LeaderboardParticipant(
          childId: c.id,
          displayName: consent.displayName,
          ageBand: LeaderboardSettings.ageBandOf(c.ageOn(now)),
        ),
      );
    }
    final viewer = db.children[childId]!;
    return LeaderboardService.boardFor(
      viewerChildId: childId,
      orgEnabled: cfg.leaderboardOn && cfg.leaderboard.periods.contains(period),
      viewerConsented: db.leaderboardConsents['$orgId|$childId']?.granted ?? false,
      viewerAgeBand: LeaderboardSettings.ageBandOf(viewer.ageOn(now)),
      participants: participants,
      results: db.brainResults,
      settings: cfg.leaderboard,
      period: period,
      now: now,
      games: game == null ? null : {game},
    );
  });
}

class DemoCoachContactRepository implements CoachContactRepository {
  DemoCoachContactRepository(this.db);

  final DemoBackend db;

  @override
  Future<CoachContactRequest> request({required String coachId, required String groupId, required String topic}) async {
    db.requireOnline();
    final me = db.me;
    final c = db.children[me.lastContext.childId];
    if (c == null || !AccessPolicy.isStudentOf(me, c)) throw const PermissionDeniedException('student');
    final g = db.requireGroup(groupId);
    if (!g.hasChild(c.id) || !g.coachIds.contains(coachId)) throw const PermissionDeniedException('coach');
    if (!CoachContactRequest.topics.contains(topic)) throw const ValidationException('topic');
    db.rateLimit('coachContact', 5);
    final r = CoachContactRequest(
      id: db.newId('contact'),
      childId: c.id,
      coachId: coachId,
      groupId: groupId,
      topic: topic,
      createdAt: db.clock(),
    );
    db.coachContactRequests[r.id] = r;
    // Only the guardians are notified; the coach is contacted by them.
    for (final p in c.parentIds) {
      db.notifyUser(
        p,
        NotificationType.ackRequested,
        route: '/contacts',
        args: {'child': c.firstName, 'coach': db.users[coachId]?.fullName ?? '', 'kind': 'coachContact'},
        childId: c.id,
        groupId: groupId,
        dedupeKey: 'contact:${r.id}',
      );
    }
    db.commit();
    return r;
  }

  @override
  Stream<List<CoachContactRequest>> watchForParent() => db.watch(() {
    final me = db.me;
    if (!me.isParent) return const <CoachContactRequest>[];
    return db.coachContactRequests.values
        .where((r) => db.children[r.childId]?.parentIds.contains(me.id) ?? false)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  @override
  Stream<List<CoachContactRequest>> watchMine() => db.watch(() {
    final me = db.me;
    final c = db.children[me.lastContext.childId];
    if (c == null || !AccessPolicy.isStudentOf(me, c)) return const <CoachContactRequest>[];
    return db.coachContactRequests.values.where((r) => r.childId == c.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  @override
  Future<void> markHandled(String id) async {
    db.requireOnline();
    final r = db.coachContactRequests[id] ?? (throw const NotFoundException('contact'));
    if (!(db.children[r.childId]?.parentIds.contains(db.me.id) ?? false)) throw const PermissionDeniedException();
    db.coachContactRequests[id] = r.handled(db.me.id);
    db.commit();
  }
}
