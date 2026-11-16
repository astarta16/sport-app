import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_utils.dart';
import '../../admin/domain/admin_models.dart';
import '../../attendance/domain/attendance.dart';
import '../../brain_academy/domain/brain_models.dart';
import '../../brain_academy/domain/scoring.dart';
import '../../clubs/domain/club.dart';
import '../domain/coach_contact.dart';
import '../domain/organization.dart';
import '../domain/platform.dart';
import '../domain/repositories.dart';
import '../domain/scheduling.dart';

/// Production organizations. Reads go through Firestore (tenant-scoped
/// rules); every privileged write is a callable Cloud Function that
/// re-checks the platform / organization-admin claims server-side.
class FirebaseOrganizationsRepository implements OrganizationsRepository {
  FirebaseOrganizationsRepository(this.auth, this.db, this.functions);

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseFunctions functions;

  OrgConfig _cfg(DocumentSnapshot<Map<String, dynamic>> d) =>
      d.exists ? OrgConfig.fromMap(d.id, d.data()!) : OrgConfig.legacy(d.id);

  @override
  Stream<List<OrgConfig>> watchConfigs() async* {
    final token = await auth.currentUser?.getIdTokenResult();
    final claims = token?.claims ?? const {};
    if (claims['admin'] == true) {
      yield* db.collection('orgConfigs').snapshots().map((s) => [for (final d in s.docs) _cfg(d)]).mapFirebaseErrors();
      return;
    }
    yield* watchMyMemberships().asyncExpand(
      (ms) => mergeLatestLists([
        for (final m in ms)
          db.collection('orgConfigs').doc(m.orgId).snapshots().map((d) => [_cfg(d)]).mapFirebaseErrors(),
      ]),
    );
  }

  @override
  Stream<OrgConfig> watchConfig(String orgId) =>
      db.collection('orgConfigs').doc(orgId).snapshots().map(_cfg).mapFirebaseErrors();

  @override
  Future<Club> createOrganization({
    required ClubDraft club,
    required OrgPlan plan,
    required OrgBranding branding,
    String timezone = OrgTimeZones.tbilisi,
    String defaultLanguage = 'ka',
  }) async {
    final r = await callFunction(functions, 'createOrganization', {
      'name': club.name,
      'address': club.address,
      'lat': club.lat,
      'lng': club.lng,
      'sportIds': club.sportIds,
      'phone': club.phone,
      'description': club.description,
      'plan': plan.name,
      'branding': branding.toMap(),
      'timezone': timezone,
      'defaultLanguage': defaultLanguage,
    });
    final id = r['id'] as String;
    final d = await db.collection('clubs').doc(id).get();
    return Club.fromMap(id, d.data() ?? const {});
  }

  @override
  Future<void> updatePlatformSettings(
    String orgId, {
    OrgStatus? status,
    OrgPlan? plan,
    Set<OrgModule>? allowedModules,
    OrgLimits? limits,
  }) => callFunction(functions, 'updateOrgPlatform', {
    'orgId': orgId,
    'status': ?status?.name,
    'plan': ?plan?.name,
    if (allowedModules != null) 'allowedModules': [for (final m in allowedModules) m.name],
    if (limits != null) 'limits': limits.toMap(),
  });

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
    OrgSettings? settings,
    int? expectedVersion,
    String? reason,
  }) => callFunction(functions, 'updateOrgSettings', {
    if (settings != null) 'settings': settings.toMap(),
    'expectedVersion': ?expectedVersion,
    'reason': ?reason,
    'orgId': orgId,
    if (enabledModules != null) 'enabledModules': [for (final m in enabledModules) m.name],
    if (branding != null) 'branding': branding.toMap(),
    'defaultLanguage': ?defaultLanguage,
    'timezone': ?timezone,
    if (leaderboard != null) 'leaderboard': leaderboard.toMap(),
    'bookingBufferMin': ?bookingBufferMin,
    'sportIds': ?sportIds,
  });

  @override
  Future<void> setOrgAdmin(String orgId, String userId, {required bool admin}) =>
      callFunction(functions, 'setOrgAdmin', {'orgId': orgId, 'userId': userId, 'admin': admin});

  @override
  Future<void> setOrgCoach(String orgId, String coachId, {required bool member}) =>
      callFunction(functions, 'setOrgCoach', {'orgId': orgId, 'coachId': coachId, 'member': member});

  @override
  Stream<List<OrgMembership>> watchMyMemberships() => db
      .collectionGroup('orgMembers')
      .where('userId', isEqualTo: requireUid(auth))
      .snapshots()
      .map((s) => [for (final d in s.docs) OrgMembership.fromMap(d.data())])
      .mapFirebaseErrors();

  @override
  Stream<List<OrgMembership>> watchMembers(String orgId) => db
      .collection('clubs')
      .doc(orgId)
      .collection('orgMembers')
      .snapshots()
      .map((s) => [for (final d in s.docs) OrgMembership.fromMap(d.data())])
      .mapFirebaseErrors();

  @override
  Stream<List<SportsProgram>> watchPrograms(String orgId) => db
      .collection('clubs')
      .doc(orgId)
      .collection('programs')
      .snapshots()
      .map((s) => [for (final d in s.docs) SportsProgram.fromMap(d.id, d.data())])
      .mapFirebaseErrors();

  @override
  Future<SportsProgram> upsertProgram(SportsProgram p) async {
    final r = await callFunction(functions, 'upsertProgram', {'id': p.id, ...p.toMap()});
    return SportsProgram.fromMap(r['id'] as String, p.toMap());
  }

  @override
  Future<List<EventRsvpRow>> rsvpReport(String orgId, {required DateTime from, required DateTime to}) async {
    final r = await callFunction(functions, 'orgReport', {
      'orgId': orgId,
      'kind': 'rsvp',
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
    });
    return [
      for (final e in (r['rows'] as List?) ?? const [])
        EventRsvpRow(
          eventId: (e as Map)['eventId'] as String,
          type: EventType.fromName(e['type'] as String?),
          groupId: e['groupId'] as String? ?? '',
          groupName: e['groupName'] as String? ?? '',
          startAt: DateTime.parse(e['startAt'] as String),
          version: (e['version'] as num?)?.toInt() ?? 1,
          counts: {for (final st in RsvpState.values) st: ((e['counts'] as Map?)?[st.name] as num?)?.toInt() ?? 0},
        ),
    ];
  }

  @override
  Future<List<EventAttendanceRow>> attendanceReport(
    String orgId, {
    required DateTime from,
    required DateTime to,
    String? groupId,
  }) async {
    final r = await callFunction(functions, 'orgReport', {
      'orgId': orgId,
      'kind': 'attendance',
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
      'groupId': ?groupId,
    });
    int n(Map e, String k) => (e[k] as num?)?.toInt() ?? 0;
    return [
      for (final e in (r['rows'] as List?) ?? const [])
        EventAttendanceRow(
          eventId: (e as Map)['eventId'] as String,
          type: EventType.fromName(e['type'] as String?),
          groupId: e['groupId'] as String? ?? '',
          groupName: e['groupName'] as String? ?? '',
          startAt: DateTime.parse(e['startAt'] as String),
          present: n(e, 'present'),
          absent: n(e, 'absent'),
          excused: n(e, 'excused'),
          unmarked: n(e, 'unmarked'),
        ),
    ];
  }

  @override
  Future<List<BrainSummaryRow>> brainSummary(String orgId) async {
    final r = await callFunction(functions, 'orgReport', {'orgId': orgId, 'kind': 'brain'});
    return [
      for (final e in (r['rows'] as List?) ?? const [])
        BrainSummaryRow(
          childId: (e as Map)['childId'] as String,
          displayName: e['displayName'] as String? ?? '',
          groupNames: ((e['groupNames'] as List?) ?? const []).cast<String>(),
          points: (e['points'] as num?)?.toInt() ?? 0,
          gamesCompleted: (e['gamesCompleted'] as num?)?.toInt() ?? 0,
          lastPlayed: e['lastPlayed'] == null ? null : DateTime.parse(e['lastPlayed'] as String),
        ),
    ];
  }

  @override
  Future<TenantHealth> health(String orgId) async {
    final r = await callFunction(functions, 'tenantHealth', {'orgId': orgId});
    int n(String k) => (r[k] as num?)?.toInt() ?? 0;
    return TenantHealth(
      orgId: orgId,
      students: n('students'),
      coaches: n('coaches'),
      groups: n('groups'),
      rooms: n('rooms'),
      upcomingEvents: n('upcomingEvents'),
      bookingsThisWeek: n('bookingsThisWeek'),
      brainPlays7d: n('brainPlays7d'),
    );
  }
}

/// Bookings are written ONLY by the transactional `createBooking` /
/// `createRecurringBookings` / `updateBooking` / `cancelBooking` callables;
/// the rules deny direct client writes.
class FirebaseSchedulingRepository implements SchedulingRepository {
  FirebaseSchedulingRepository(this.db, this.functions);

  final FirebaseFirestore db;
  final FirebaseFunctions functions;

  CollectionReference<Map<String, dynamic>> _rooms(String orgId) =>
      db.collection('clubs').doc(orgId).collection('rooms');
  CollectionReference<Map<String, dynamic>> _bookings(String orgId) =>
      db.collection('clubs').doc(orgId).collection('bookings');

  /// Maps the `booking-conflict` HttpsError details to [BookingRejected].
  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    try {
      final r = await functions.httpsCallable(name).call<Object?>(data);
      final d = r.data;
      return d is Map ? d.map((k, v) => MapEntry(k.toString(), v)) : <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      if (e.code == 'failed-precondition' && details is Map && details['conflicts'] is List) {
        throw BookingRejected(
          [
            for (final c in details['conflicts'] as List)
              BookingConflict(
                ConflictCode.values.firstWhere(
                  (x) => x.name == (c as Map)['code'],
                  orElse: () => ConflictCode.roomOverlap,
                ),
                otherId: (c as Map)['otherId'] as String?,
              ),
          ],
          alternatives: [for (final a in (details['alternatives'] as List?) ?? const []) DateTime.parse(a as String)],
        );
      }
      return guardFirebase(() => Future.error(e));
    }
  }

  @override
  Stream<List<Room>> watchRooms(String orgId) =>
      _rooms(orgId).snapshots().map((s) => [for (final d in s.docs) Room.fromMap(d.id, d.data())]).mapFirebaseErrors();

  @override
  Future<Room> upsertRoom(Room r) async {
    final res = await _call('upsertRoom', {'id': r.id, ...r.toMap()});
    return Room.fromMap(res['id'] as String, r.toMap());
  }

  @override
  Future<void> setRoomStatus(String orgId, String roomId, RoomStatus status) =>
      _call('setRoomStatus', {'orgId': orgId, 'roomId': roomId, 'status': status.name});

  @override
  Stream<List<Booking>> watchBookings(String orgId, {required DateTime from, required DateTime to}) => _bookings(orgId)
      .where('startAt', isLessThan: Timestamp.fromDate(to))
      .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from.subtract(ConflictChecker.maxDuration)))
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            if (Booking.fromMap(d.id, d.data()) case final b when b.endAt.isAfter(from)) b,
        ],
      )
      .mapFirebaseErrors();

  Map<String, dynamic> _wire(Booking b) => {
    ...b.toMap(),
    'id': b.id,
    'startAt': b.startAt.toUtc().toIso8601String(),
    'endAt': b.endAt.toUtc().toIso8601String(),
    'updatedAt': null,
  };

  @override
  Future<List<BookingConflict>> preview(Booking draft, {Set<String> ignoreIds = const {}}) async {
    // Client-side hint only; the callable is the authority.
    final room = await _rooms(draft.orgId).doc(draft.roomId).get();
    final cfgDoc = await db.collection('orgConfigs').doc(draft.orgId).get();
    final cfg = cfgDoc.exists ? OrgConfig.fromMap(cfgDoc.id, cfgDoc.data()!) : OrgConfig.legacy(draft.orgId);
    final day = draft.startAt.subtract(const Duration(hours: 12));
    final existing = await _bookings(draft.orgId)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(day))
        .where('startAt', isLessThan: Timestamp.fromDate(draft.endAt))
        .get();
    return ConflictChecker.check(
      draft,
      room: Room.fromMap(room.id, room.data() ?? const {}),
      existing: [for (final d in existing.docs) Booking.fromMap(d.id, d.data())],
      timezone: cfg.timezone,
      bufferMin: cfg.bookingBufferMin,
      ignoreIds: ignoreIds,
    );
  }

  @override
  Future<Booking> createBooking(Booking draft, {bool allowGroupOverlap = false}) async {
    final r = await _call('createBooking', {..._wire(draft), 'allowGroupOverlap': allowGroupOverlap});
    return draft.copyWith(id: r['id'] as String, eventId: r['eventId'] as String?);
  }

  @override
  Future<List<Booking>> createRecurring(Booking template, WeeklyRule rule, {bool allowGroupOverlap = false}) async {
    final r = await _call('createRecurringBookings', {
      ..._wire(template),
      'rule': rule.toMap(),
      'allowGroupOverlap': allowGroupOverlap,
    });
    final ids = ((r['ids'] as List?) ?? const []).cast<String>();
    final occ = rule.occurrences(r['timezone'] as String? ?? OrgTimeZones.tbilisi);
    return [
      for (var i = 0; i < ids.length && i < occ.length; i++)
        template.copyWith(id: ids[i], startAt: occ[i].$1, endAt: occ[i].$2, seriesId: r['seriesId'] as String?),
    ];
  }

  @override
  Future<Booking> updateBooking(Booking updated, {bool allowGroupOverlap = false}) async {
    await _call('updateBooking', {..._wire(updated), 'allowGroupOverlap': allowGroupOverlap});
    return updated;
  }

  @override
  Future<List<Booking>> updateSeriesFrom(
    Booking anchor, {
    required int startMinute,
    required int durationMin,
    String? roomId,
  }) async {
    await _call('updateBookingSeries', {
      'orgId': anchor.orgId,
      'bookingId': anchor.id,
      'startMinute': startMinute,
      'durationMin': durationMin,
      'roomId': roomId,
    });
    return const [];
  }

  @override
  Future<void> cancelBooking(Booking booking, {SeriesEditScope scope = SeriesEditScope.thisOccurrence}) =>
      _call('cancelBooking', {'orgId': booking.orgId, 'bookingId': booking.id, 'scope': scope.name});
}

class FirebaseLeaderboardRepository implements LeaderboardRepository {
  FirebaseLeaderboardRepository(this.db, this.functions);

  final FirebaseFirestore db;
  final FirebaseFunctions functions;

  @override
  Stream<LeaderboardConsent?> watchConsent(String orgId, String childId) => db
      .collection('clubs')
      .doc(orgId)
      .collection('leaderboardConsents')
      .doc(childId)
      .snapshots()
      .map((d) => d.exists ? LeaderboardConsent.fromMap(d.data()!) : null)
      .mapFirebaseErrors();

  @override
  Future<void> setConsent(
    String orgId,
    String childId, {
    required bool granted,
    DisplayNameMode mode = DisplayNameMode.pseudonym,
  }) => callFunction(functions, 'setLeaderboardConsent', {
    'orgId': orgId,
    'childId': childId,
    'granted': granted,
    'mode': mode.name,
  });

  /// Ranked by the `getLeaderboard` callable (server-side scoring); the
  /// client never computes or submits authoritative totals.
  @override
  Stream<LeaderboardBoard> watchBoard(
    String orgId,
    String childId, {
    required LeaderboardPeriod period,
    BrainGame? game,
  }) async* {
    final r = await callFunction(functions, 'getLeaderboard', {
      'orgId': orgId,
      'childId': childId,
      'period': period.name,
      'game': ?game?.name,
    });
    final unavailable = r['unavailable'] as String?;
    yield LeaderboardBoard(
      unavailable: unavailable == null ? null : LeaderboardUnavailable.values.firstWhere((u) => u.name == unavailable),
      ageBand: r['ageBand'] as String?,
      entries: [
        for (final e in (r['entries'] as List?) ?? const [])
          LeaderboardEntry(
            rank: ((e as Map)['rank'] as num).toInt(),
            childId: e['me'] == true ? childId : '',
            displayName: e['displayName'] as String? ?? '',
            points: (e['points'] as num?)?.toInt() ?? 0,
            badges: (e['badges'] as num?)?.toInt() ?? 0,
          ),
      ],
    );
  }
}

class FirebaseCoachContactRepository implements CoachContactRepository {
  FirebaseCoachContactRepository(this.auth, this.db, this.functions);

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseFunctions functions;

  @override
  Future<CoachContactRequest> request({required String coachId, required String groupId, required String topic}) async {
    final r = await callFunction(functions, 'requestCoachContact', {
      'coachId': coachId,
      'groupId': groupId,
      'topic': topic,
    });
    final d = await db.collection('coachContactRequests').doc(r['id'] as String).get();
    return CoachContactRequest.fromMap(d.id, d.data() ?? (throw const NotFoundException()));
  }

  Stream<List<CoachContactRequest>> _q(Query<Map<String, dynamic>> q) => q
      .snapshots()
      .map((s) => [for (final d in s.docs) CoachContactRequest.fromMap(d.id, d.data())])
      .mapFirebaseErrors();

  @override
  Stream<List<CoachContactRequest>> watchForParent() =>
      _q(db.collection('coachContactRequests').where('parentIds', arrayContains: requireUid(auth)));

  @override
  Stream<List<CoachContactRequest>> watchMine() =>
      _q(db.collection('coachContactRequests').where('studentUid', isEqualTo: requireUid(auth)));

  @override
  Future<void> markHandled(String id) =>
      db.collection('coachContactRequests').doc(id).update({'status': 'handled', 'handledBy': requireUid(auth)});
}
