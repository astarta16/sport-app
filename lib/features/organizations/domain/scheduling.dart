import '../../../core/utils/dates.dart';
import 'organization.dart';

/// v1.7 room / facility scheduling. Pure logic shared by the demo backend,
/// the UI (instant warnings) and mirrored 1:1 by functions/src/lib/scheduling.ts,
/// which is the authority in production (transactional booking callable).
///
/// Boundaries are persisted as UTC instants. Recurring rules are expressed
/// in the organization's local wall-clock time and expanded with the
/// organization time zone ([OrgTimeZones]).

enum RoomStatus {
  active,

  /// Temporarily unavailable (repairs, closed); no new bookings.
  unavailable,
  archived;

  static RoomStatus fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => active);
}

/// Opening hours per ISO weekday (1 = Monday). Minutes from local midnight;
/// `close` may exceed 1440 to allow sessions that run past midnight.
class OperatingHours {
  const OperatingHours(this.byWeekday);

  /// 08:00–22:00 every day.
  static const standard = OperatingHours({
    1: (480, 1320),
    2: (480, 1320),
    3: (480, 1320),
    4: (480, 1320),
    5: (480, 1320),
    6: (480, 1320),
    7: (480, 1320),
  });

  final Map<int, (int, int)> byWeekday;

  /// Whether [startMin]..[startMin + durationMin] on [weekday] fits.
  bool allows(int weekday, int startMin, int durationMin) {
    final h = byWeekday[weekday];
    if (h == null) return false;
    return startMin >= h.$1 && startMin + durationMin <= h.$2;
  }

  Map<String, dynamic> toMap() => {
    for (final e in byWeekday.entries) '${e.key}': [e.value.$1, e.value.$2],
  };

  factory OperatingHours.fromMap(Object? m) {
    if (m is! Map) return standard;
    final out = <int, (int, int)>{};
    for (final e in m.entries) {
      final d = int.tryParse('${e.key}');
      final v = e.value;
      if (d != null && d >= 1 && d <= 7 && v is List && v.length == 2) {
        out[d] = ((v[0] as num).toInt(), (v[1] as num).toInt());
      }
    }
    return OperatingHours(out);
  }
}

class Room {
  const Room({
    required this.id,
    required this.orgId,
    required this.name,
    this.capacity = 30,
    this.sportIds = const [],
    this.hours = OperatingHours.standard,
    this.status = RoomStatus.active,
    this.venueId,
    this.note,
  });

  final String id;
  final String orgId;
  final String name;
  final int capacity;

  /// Empty = any sport.
  final List<String> sportIds;
  final OperatingHours hours;
  final RoomStatus status;

  /// Venue (address + map pin) the room belongs to.
  final String? venueId;
  final String? note;

  bool get bookable => status == RoomStatus.active;

  static List<String> validate(Room r) => [
    if (r.name.trim().length < 2 || r.name.length > 60) 'roomName',
    if (r.capacity < 1 || r.capacity > 1000) 'roomCapacity',
  ];

  Map<String, dynamic> toMap() => {
    'orgId': orgId,
    'clubId': orgId,
    'name': name,
    'capacity': capacity,
    'sportIds': sportIds,
    'hours': hours.toMap(),
    'status': status.name,
    'venueId': venueId,
    'note': note,
  };

  factory Room.fromMap(String id, Map<String, dynamic> m) => Room(
    id: id,
    orgId: m['orgId'] as String? ?? m['clubId'] as String? ?? '',
    name: m['name'] as String? ?? '',
    capacity: (m['capacity'] as num?)?.toInt() ?? 30,
    sportIds: readStringList(m['sportIds']),
    hours: OperatingHours.fromMap(m['hours']),
    status: RoomStatus.fromName(m['status'] as String?),
    venueId: m['venueId'] as String?,
    note: m['note'] as String?,
  );

  Room copyWith({
    String? name,
    int? capacity,
    List<String>? sportIds,
    OperatingHours? hours,
    RoomStatus? status,
    String? venueId,
    String? note,
  }) => Room(
    id: id,
    orgId: orgId,
    name: name ?? this.name,
    capacity: capacity ?? this.capacity,
    sportIds: sportIds ?? this.sportIds,
    hours: hours ?? this.hours,
    status: status ?? this.status,
    venueId: venueId ?? this.venueId,
    note: note ?? this.note,
  );
}

enum BookingKind {
  training,
  match,
  event,

  /// Blocks the room; conflicts with everything.
  maintenance;

  static BookingKind fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => training);
}

enum BookingStatus {
  active,
  cancelled;

  static BookingStatus fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => active);
}

/// Weekly recurrence in local organization time.
class WeeklyRule {
  const WeeklyRule({
    required this.weekdays,
    required this.startMinute,
    required this.durationMin,
    required this.from,
    required this.until,
  });

  /// ISO weekdays (1 = Monday).
  final Set<int> weekdays;

  /// Local start, minutes after midnight.
  final int startMinute;
  final int durationMin;

  /// Inclusive local dates (UTC-midnight DateTimes).
  final DateTime from;
  final DateTime until;

  /// Generation window cap: recurring bookings are materialized (and every
  /// occurrence conflict-checked) at most this far ahead.
  static const maxWeeks = 26;

  /// Local start/end instants of every occurrence (UTC), oldest first.
  List<(DateTime, DateTime)> occurrences(String tz) {
    final out = <(DateTime, DateTime)>[];
    final last = until.isAfter(from.add(const Duration(days: maxWeeks * 7)))
        ? from.add(const Duration(days: maxWeeks * 7))
        : until;
    for (
      var d = DateTime.utc(from.year, from.month, from.day);
      !d.isAfter(last);
      d = DateTime.utc(d.year, d.month, d.day + 1)
    ) {
      if (!weekdays.contains(d.weekday)) continue;
      final start = OrgTimeZones.instant(tz, d.year, d.month, d.day, startMinute ~/ 60, startMinute % 60);
      out.add((start, start.add(Duration(minutes: durationMin))));
    }
    return out;
  }

  Map<String, dynamic> toMap() => {
    'weekdays': weekdays.toList()..sort(),
    'startMinute': startMinute,
    'durationMin': durationMin,
    'from': _ymd(from),
    'until': _ymd(until),
  };

  factory WeeklyRule.fromMap(Map<String, dynamic> m) => WeeklyRule(
    weekdays: {for (final d in (m['weekdays'] as List? ?? const [])) (d as num).toInt()},
    startMinute: (m['startMinute'] as num?)?.toInt() ?? 0,
    durationMin: (m['durationMin'] as num?)?.toInt() ?? 60,
    from: _parseYmd(m['from'] as String?),
    until: _parseYmd(m['until'] as String?),
  );

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static DateTime _parseYmd(String? s) {
    final p = (s ?? '1970-01-01').split('-').map(int.parse).toList();
    return DateTime.utc(p[0], p[1], p[2]);
  }
}

/// One reserved interval of one room (`clubs/{clubId}/bookings/{id}`).
/// A recurring series is materialized as one booking per occurrence that
/// share [seriesId]; editing one occurrence detaches it.
class Booking {
  const Booking({
    required this.id,
    required this.orgId,
    required this.roomId,
    required this.kind,
    required this.startAt,
    required this.endAt,
    this.title = '',
    this.coachId,
    this.groupId,
    this.programId,
    this.sportId,
    this.status = BookingStatus.active,
    this.seriesId,
    this.rule,
    this.eventId,
    this.expectedAttendees,
    this.createdBy = '',
    this.updatedAt,
  });

  final String id;
  final String orgId;
  final String roomId;
  final BookingKind kind;
  final DateTime startAt;
  final DateTime endAt;
  final String title;
  final String? coachId;
  final String? groupId;
  final String? programId;
  final String? sportId;
  final BookingStatus status;
  final String? seriesId;
  final WeeklyRule? rule;

  /// Linked training / match id — the room reservation and the event are
  /// kept consistent through this reference (one source of truth for time).
  final String? eventId;
  final int? expectedAttendees;
  final String createdBy;
  final DateTime? updatedAt;

  bool get isActive => status == BookingStatus.active;
  Duration get duration => endAt.difference(startAt);

  Map<String, dynamic> toMap() => {
    'orgId': orgId,
    'clubId': orgId,
    'roomId': roomId,
    'kind': kind.name,
    'startAt': startAt.toUtc(),
    'endAt': endAt.toUtc(),
    'title': title,
    'coachId': coachId,
    'groupId': groupId,
    'programId': programId,
    'sportId': sportId,
    'status': status.name,
    'seriesId': seriesId,
    'rule': rule?.toMap(),
    'eventId': eventId,
    'expectedAttendees': expectedAttendees,
    'createdBy': createdBy,
    'updatedAt': updatedAt,
  };

  factory Booking.fromMap(String id, Map<String, dynamic> m) => Booking(
    id: id,
    orgId: m['orgId'] as String? ?? m['clubId'] as String? ?? '',
    roomId: m['roomId'] as String? ?? '',
    kind: BookingKind.fromName(m['kind'] as String?),
    startAt: readDate(m['startAt']).toUtc(),
    endAt: readDate(m['endAt']).toUtc(),
    title: m['title'] as String? ?? '',
    coachId: m['coachId'] as String?,
    groupId: m['groupId'] as String?,
    programId: m['programId'] as String?,
    sportId: m['sportId'] as String?,
    status: BookingStatus.fromName(m['status'] as String?),
    seriesId: m['seriesId'] as String?,
    rule: m['rule'] is Map ? WeeklyRule.fromMap(Map<String, dynamic>.from(m['rule'] as Map)) : null,
    eventId: m['eventId'] as String?,
    expectedAttendees: (m['expectedAttendees'] as num?)?.toInt(),
    createdBy: m['createdBy'] as String? ?? '',
    updatedAt: readDateOrNull(m['updatedAt']),
  );

  Booking copyWith({
    String? id,
    String? roomId,
    BookingKind? kind,
    DateTime? startAt,
    DateTime? endAt,
    String? title,
    String? coachId,
    String? groupId,
    String? programId,
    String? sportId,
    BookingStatus? status,
    String? seriesId,
    bool clearSeries = false,
    WeeklyRule? rule,
    String? eventId,
    int? expectedAttendees,
    String? createdBy,
    DateTime? updatedAt,
  }) => Booking(
    id: id ?? this.id,
    orgId: orgId,
    roomId: roomId ?? this.roomId,
    kind: kind ?? this.kind,
    startAt: startAt ?? this.startAt,
    endAt: endAt ?? this.endAt,
    title: title ?? this.title,
    coachId: coachId ?? this.coachId,
    groupId: groupId ?? this.groupId,
    programId: programId ?? this.programId,
    sportId: sportId ?? this.sportId,
    status: status ?? this.status,
    seriesId: clearSeries ? null : (seriesId ?? this.seriesId),
    rule: clearSeries ? null : (rule ?? this.rule),
    eventId: eventId ?? this.eventId,
    expectedAttendees: expectedAttendees ?? this.expectedAttendees,
    createdBy: createdBy ?? this.createdBy,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

enum ConflictCode {
  invalidRange,
  tooLong,
  roomNotBookable,
  outsideHours,
  overCapacity,
  roomOverlap,
  maintenance,
  coachOverlap,
  groupOverlap,
  wrongTenant;

  /// Group double-booking is a warning the admin may override; everything
  /// else blocks the booking.
  bool get blocking => this != groupOverlap;
}

class BookingConflict {
  const BookingConflict(this.code, {this.otherId, this.start, this.end});

  final ConflictCode code;

  /// The existing booking it collides with, if any.
  final String? otherId;
  final DateTime? start;
  final DateTime? end;

  @override
  String toString() => 'BookingConflict(${code.name}${otherId == null ? '' : ' vs $otherId'})';
}

/// Interval-overlap conflict detection.
class ConflictChecker {
  ConflictChecker._();

  static const maxDuration = Duration(hours: 12);

  /// Half-open intervals [aStart, aEnd) and [bStart, bEnd) overlap when
  /// `aStart < bEnd && aEnd > bStart`. Touching (09–10 and 10–11) does not
  /// overlap. [buffer] widens the existing interval on both sides.
  static bool overlaps(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd, {
    Duration buffer = Duration.zero,
  }) => aStart.isBefore(bEnd.add(buffer)) && aEnd.isAfter(bStart.subtract(buffer));

  /// All conflicts of [candidate] against [existing] bookings. Bookings
  /// whose id is in [ignoreIds] (the booking being edited) are skipped.
  static List<BookingConflict> check(
    Booking candidate, {
    required Room room,
    required Iterable<Booking> existing,
    required String timezone,
    int bufferMin = 0,
    bool checkGroup = true,
    Set<String> ignoreIds = const {},
  }) {
    final out = <BookingConflict>[];
    final s = candidate.startAt, e = candidate.endAt;
    if (!e.isAfter(s)) return [const BookingConflict(ConflictCode.invalidRange)];
    if (e.difference(s) > maxDuration) out.add(const BookingConflict(ConflictCode.tooLong));
    if (room.orgId != candidate.orgId) out.add(const BookingConflict(ConflictCode.wrongTenant));
    if (!room.bookable) out.add(const BookingConflict(ConflictCode.roomNotBookable));
    if (candidate.kind != BookingKind.maintenance) {
      final w = OrgTimeZones.wall(s, timezone);
      if (!room.hours.allows(w.weekday, w.hour * 60 + w.minute, e.difference(s).inMinutes)) {
        out.add(const BookingConflict(ConflictCode.outsideHours));
      }
      final n = candidate.expectedAttendees;
      if (n != null && n > room.capacity) out.add(const BookingConflict(ConflictCode.overCapacity));
    }
    final buffer = Duration(minutes: bufferMin);
    for (final b in existing) {
      if (!b.isActive || b.id == candidate.id || ignoreIds.contains(b.id) || b.orgId != candidate.orgId) continue;
      if (b.roomId == candidate.roomId && overlaps(s, e, b.startAt, b.endAt, buffer: buffer)) {
        out.add(
          BookingConflict(
            b.kind == BookingKind.maintenance ? ConflictCode.maintenance : ConflictCode.roomOverlap,
            otherId: b.id,
            start: b.startAt,
            end: b.endAt,
          ),
        );
        continue;
      }
      if (!overlaps(s, e, b.startAt, b.endAt)) continue;
      if (candidate.coachId != null && candidate.coachId == b.coachId) {
        out.add(BookingConflict(ConflictCode.coachOverlap, otherId: b.id, start: b.startAt, end: b.endAt));
      } else if (checkGroup && candidate.groupId != null && candidate.groupId == b.groupId) {
        out.add(BookingConflict(ConflictCode.groupOverlap, otherId: b.id, start: b.startAt, end: b.endAt));
      }
    }
    return out;
  }

  static bool isBlocked(Iterable<BookingConflict> c) => c.any((x) => x.code.blocking);

  /// Up to [limit] conflict-free start times for [candidate] on the same
  /// local day (30-minute grid), nearest to the requested time first.
  static List<DateTime> alternatives(
    Booking candidate, {
    required Room room,
    required Iterable<Booking> existing,
    required String timezone,
    int bufferMin = 0,
    int limit = 3,
    Set<String> ignoreIds = const {},
  }) {
    final dur = candidate.endAt.difference(candidate.startAt);
    final w = OrgTimeZones.wall(candidate.startAt, timezone);
    final dayStart = OrgTimeZones.instant(timezone, w.year, w.month, w.day);
    final slots = <DateTime>[];
    for (var m = 0; m + dur.inMinutes <= 24 * 60; m += 30) {
      final start = dayStart.add(Duration(minutes: m));
      if (start == candidate.startAt) continue;
      final c = check(
        candidate.copyWith(startAt: start, endAt: start.add(dur)),
        room: room,
        existing: existing,
        timezone: timezone,
        bufferMin: bufferMin,
        ignoreIds: ignoreIds,
      );
      if (!isBlocked(c)) slots.add(start);
    }
    slots.sort(
      (a, b) =>
          a.difference(candidate.startAt).inMinutes.abs().compareTo(b.difference(candidate.startAt).inMinutes.abs()),
    );
    return slots.take(limit).toList();
  }

  /// Other bookable rooms free at the requested time.
  static List<Room> freeRooms(
    Booking candidate, {
    required Iterable<Room> rooms,
    required Iterable<Booking> existing,
    required String timezone,
    int bufferMin = 0,
  }) => [
    for (final r in rooms)
      if (r.id != candidate.roomId &&
          r.orgId == candidate.orgId &&
          !isBlocked(
            check(
              candidate.copyWith(roomId: r.id),
              room: r,
              existing: existing,
              timezone: timezone,
              bufferMin: bufferMin,
            ),
          ))
        r,
  ];

  /// Checks every occurrence of a recurring booking; returns conflicts per
  /// occurrence start. Empty map = the whole series can be committed.
  static Map<DateTime, List<BookingConflict>> checkSeries(
    Booking template,
    WeeklyRule rule, {
    required Room room,
    required Iterable<Booking> existing,
    required String timezone,
    int bufferMin = 0,
    Set<String> ignoreIds = const {},
  }) {
    final out = <DateTime, List<BookingConflict>>{};
    final list = existing.toList();
    for (final (s, e) in rule.occurrences(timezone)) {
      final c = check(
        template.copyWith(startAt: s, endAt: e),
        room: room,
        existing: list,
        timezone: timezone,
        bufferMin: bufferMin,
        ignoreIds: ignoreIds,
      );
      if (isBlocked(c)) out[s] = c;
    }
    return out;
  }
}

/// Typed failure of a booking operation (server-side rejection).
class BookingRejected implements Exception {
  const BookingRejected(this.conflicts, {this.alternatives = const [], this.freeRooms = const []});

  final List<BookingConflict> conflicts;
  final List<DateTime> alternatives;
  final List<Room> freeRooms;

  ConflictCode get primary => conflicts.firstWhere((c) => c.code.blocking, orElse: () => conflicts.first).code;

  @override
  String toString() => 'BookingRejected($conflicts)';
}

/// Scope of an edit to a recurring booking.
enum SeriesEditScope { thisOccurrence, thisAndFuture }
