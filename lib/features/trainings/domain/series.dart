import '../../../core/utils/dates.dart';
import 'training.dart';

/// A Tbilisi calendar date (`YYYY-MM-DD`), independent of device timezone.
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  factory LocalDate.parse(String s) {
    final p = s.split('-');
    if (p.length != 3) throw FormatException('Bad date: $s');
    return LocalDate(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  /// The Tbilisi calendar day of [instant].
  factory LocalDate.tbilisi(DateTime instant) {
    final w = TbilisiTime.wallClock(instant);
    return LocalDate(w.year, w.month, w.day);
  }

  factory LocalDate.fromDateTime(DateTime d) => LocalDate(d.year, d.month, d.day);

  DateTime get _utc => DateTime.utc(year, month, day);

  /// 1 = Monday … 7 = Sunday.
  int get weekday => _utc.weekday;

  LocalDate addDays(int n) {
    final d = _utc.add(Duration(days: n));
    return LocalDate(d.year, d.month, d.day);
  }

  int daysUntil(LocalDate other) => other._utc.difference(_utc).inDays;

  /// Instant of [hour]:[minute] Tbilisi time on this date.
  DateTime at(int hour, int minute) => TbilisiTime.at(year, month, day, hour, minute);

  DateTime toDateTime() => DateTime(year, month, day);

  String get compact => '$year${_two(month)}${_two(day)}';

  bool operator <(LocalDate o) => compareTo(o) < 0;
  bool operator <=(LocalDate o) => compareTo(o) <= 0;
  bool operator >(LocalDate o) => compareTo(o) > 0;
  bool operator >=(LocalDate o) => compareTo(o) >= 0;

  @override
  int compareTo(LocalDate o) => _utc.compareTo(o._utc);

  @override
  bool operator ==(Object other) =>
      other is LocalDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$year-${_two(month)}-${_two(day)}';

  static String _two(int n) => n.toString().padLeft(2, '0');
}

/// `HH:mm` wall-clock time.
class LocalTime {
  const LocalTime(this.hour, this.minute);

  final int hour;
  final int minute;

  factory LocalTime.parse(String s) {
    final p = s.split(':');
    final t = LocalTime(int.parse(p[0]), int.parse(p[1]));
    if (t.hour < 0 || t.hour > 23 || t.minute < 0 || t.minute > 59) throw FormatException('Bad time: $s');
    return t;
  }

  @override
  bool operator ==(Object other) => other is LocalTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

enum SeriesStatus {
  active,
  ended;

  static SeriesStatus fromName(String? n) => n == 'ended' ? ended : active;
}

/// Weekly recurrence rule (v1.2). Stored separately from its occurrences
/// (`trainingSeries/{id}`); occurrences are regular trainings with the
/// deterministic id `{seriesId}_{YYYYMMDD}`.
class TrainingSeries {
  const TrainingSeries({
    required this.id,
    required this.groupId,
    required this.venueId,
    required this.weekdays,
    required this.startTime,
    required this.durationMin,
    required this.focus,
    required this.startDate,
    required this.createdBy,
    this.description = '',
    this.endDate,
    this.status = SeriesStatus.active,
    this.parentSeriesId,
    this.clubId = '',
  });

  final String id;
  final String groupId;
  final String clubId;
  final String venueId;

  /// 1 = Monday … 7 = Sunday, sorted, unique.
  final List<int> weekdays;
  final LocalTime startTime;
  final int durationMin;
  final List<TrainingFocus> focus;
  final String description;
  final LocalDate startDate;
  final LocalDate? endDate;
  final SeriesStatus status;
  final String createdBy;

  /// Set when this series was split off by "edit this and future".
  final String? parentSeriesId;

  bool coversDate(LocalDate d) => weekdays.contains(d.weekday) && d >= startDate && (endDate == null || d <= endDate!);

  String occurrenceId(LocalDate d) => '${id}_${d.compact}';

  TrainingSeries copyWith({
    String? venueId,
    List<int>? weekdays,
    LocalTime? startTime,
    int? durationMin,
    List<TrainingFocus>? focus,
    String? description,
    LocalDate? startDate,
    LocalDate? endDate,
    bool clearEndDate = false,
    SeriesStatus? status,
  }) => TrainingSeries(
    id: id,
    groupId: groupId,
    clubId: clubId,
    venueId: venueId ?? this.venueId,
    weekdays: weekdays ?? this.weekdays,
    startTime: startTime ?? this.startTime,
    durationMin: durationMin ?? this.durationMin,
    focus: focus ?? this.focus,
    description: description ?? this.description,
    startDate: startDate ?? this.startDate,
    endDate: clearEndDate ? null : (endDate ?? this.endDate),
    status: status ?? this.status,
    createdBy: createdBy,
    parentSeriesId: parentSeriesId,
  );

  TrainingSeries withId(String newId, {String? parentSeriesId}) => TrainingSeries(
    id: newId,
    groupId: groupId,
    clubId: clubId,
    venueId: venueId,
    weekdays: weekdays,
    startTime: startTime,
    durationMin: durationMin,
    focus: focus,
    description: description,
    startDate: startDate,
    endDate: endDate,
    status: status,
    createdBy: createdBy,
    parentSeriesId: parentSeriesId ?? this.parentSeriesId,
  );

  Map<String, dynamic> toMap() => {
    'groupId': groupId,
    'clubId': clubId,
    'venueId': venueId,
    'weekdays': weekdays,
    'startTime': startTime.toString(),
    'durationMin': durationMin,
    'focus': focus.map((f) => f.name).toList(),
    'description': description,
    'startDate': startDate.toString(),
    'endDate': endDate?.toString(),
    'status': status.name,
    'createdBy': createdBy,
    'parentSeriesId': parentSeriesId,
  };

  factory TrainingSeries.fromMap(String id, Map<String, dynamic> m) => TrainingSeries(
    id: id,
    groupId: m['groupId'] as String? ?? '',
    clubId: m['clubId'] as String? ?? '',
    venueId: m['venueId'] as String? ?? '',
    weekdays: (m['weekdays'] as List? ?? const []).map((e) => (e as num).toInt()).toList(),
    startTime: LocalTime.parse(m['startTime'] as String? ?? '00:00'),
    durationMin: (m['durationMin'] as num?)?.toInt() ?? 60,
    focus: readStringList(m['focus']).map(TrainingFocus.fromName).whereType<TrainingFocus>().toList(),
    description: m['description'] as String? ?? '',
    startDate: LocalDate.parse(m['startDate'] as String),
    endDate: m['endDate'] == null ? null : LocalDate.parse(m['endDate'] as String),
    status: SeriesStatus.fromName(m['status'] as String?),
    createdBy: m['createdBy'] as String? ?? '',
    parentSeriesId: m['parentSeriesId'] as String?,
  );
}

/// Coach input for a recurring schedule.
class SeriesDraft {
  const SeriesDraft({
    required this.groupId,
    required this.venueId,
    required this.weekdays,
    required this.startTime,
    required this.durationMin,
    required this.focus,
    required this.startDate,
    this.endDate,
    this.description = '',
  });

  final String groupId;
  final String venueId;
  final List<int> weekdays;
  final LocalTime startTime;
  final int durationMin;
  final List<TrainingFocus> focus;
  final LocalDate startDate;
  final LocalDate? endDate;
  final String description;

  /// Error codes; [today] is the Tbilisi date of "now".
  static List<String> validate(SeriesDraft d, {required LocalDate today}) => [
    if (d.venueId.isEmpty) 'venueRequired',
    if (d.weekdays.isEmpty || d.weekdays.any((w) => w < 1 || w > 7)) 'weekdaysRequired',
    if (d.durationMin < TrainingValidator.minDuration || d.durationMin > TrainingValidator.maxDuration) 'durationRange',
    if (d.focus.isEmpty) 'focusRequired',
    if (d.description.trim().length > 1000) 'descriptionTooLong',
    if (d.startDate < today) 'startInPast',
    if (d.endDate != null && d.endDate! < d.startDate) 'endBeforeStart',
    if (d.endDate != null && d.startDate.daysUntil(d.endDate!) > 366) 'seriesTooLong',
  ];

  /// Two active series of the same group overlap when they share a weekday
  /// at the same start time and their date ranges intersect.
  static bool overlaps(SeriesDraft d, TrainingSeries s) {
    if (s.groupId != d.groupId || s.status != SeriesStatus.active) return false;
    if (s.startTime != d.startTime) return false;
    if (!d.weekdays.any(s.weekdays.contains)) return false;
    final aEnd = d.endDate, bEnd = s.endDate;
    final startsBeforeOtherEnds = bEnd == null || d.startDate <= bEnd;
    final otherStartsBeforeEnd = aEnd == null || s.startDate <= aEnd;
    return startsBeforeOtherEnds && otherStartsBeforeEnd;
  }
}

/// How a change to a series is applied to its occurrences.
class SeriesPlan {
  const SeriesPlan({
    this.create = const [],
    this.update = const [],
    this.cancel = const [],
    this.delete = const [],
    this.skippedConflicts = const [],
  });

  final List<Training> create;
  final List<Training> update;
  final List<Training> cancel;
  final List<String> delete;

  /// Dates skipped because a one-off training of the group already starts
  /// at the same moment (duplicate prevention).
  final List<LocalDate> skippedConflicts;

  bool get isEmpty => create.isEmpty && update.isEmpty && cancel.isEmpty && delete.isEmpty;
}

/// Pure occurrence generation and reconciliation (mirrored by the
/// `extendTrainingSeries` / `onSeriesWritten` Cloud Functions).
///
/// Rules:
/// * occurrences are generated from max(today, startDate) up to
///   min(endDate, today + [horizonDays]); the past is never touched;
/// * ids are deterministic, so re-running is idempotent;
/// * detached (individually edited) and done/cancelled occurrences are kept;
/// * a future occurrence that the rule no longer covers is deleted, unless
///   parents already responded or attendance exists — then it is cancelled
///   with reason "schedule changed" so the history stays explainable.
class RecurrenceEngine {
  RecurrenceEngine._();

  static const horizonDays = 56;
  static const scheduleChangedReason = 'განრიგი შეიცვალა';

  static List<LocalDate> dates(TrainingSeries s, {required LocalDate from, required LocalDate until}) {
    final start = from > s.startDate ? from : s.startDate;
    final end = s.endDate != null && s.endDate! < until ? s.endDate! : until;
    final out = <LocalDate>[];
    for (var d = start; d <= end; d = d.addDays(1)) {
      if (s.weekdays.contains(d.weekday)) out.add(d);
    }
    return out;
  }

  static Training occurrence(TrainingSeries s, LocalDate d, {required DateTime now, String? id}) => Training(
    id: id ?? s.occurrenceId(d),
    groupId: s.groupId,
    venueId: s.venueId,
    startAt: d.at(s.startTime.hour, s.startTime.minute),
    durationMin: s.durationMin,
    focus: s.focus,
    description: s.description,
    createdBy: s.createdBy,
    updatedAt: now,
    seriesId: s.id,
    occurrenceDate: d.toString(),
  );

  /// [existing]: occurrences of this series, plus — for a split-off series —
  /// the parent series' occurrences on or after its start date (they are
  /// adopted by date so RSVPs/attendance keep their training id).
  /// [withActivity]: training ids that have RSVPs or attendance.
  /// [oneOffStarts]: start instants of non-series trainings of the group.
  static SeriesPlan reconcile(
    TrainingSeries s, {
    required List<Training> existing,
    required DateTime now,
    Set<String> withActivity = const {},
    Set<DateTime> oneOffStarts = const {},
  }) {
    final today = LocalDate.tbilisi(now);
    final desired = s.status == SeriesStatus.active
        ? dates(s, from: today, until: today.addDays(horizonDays)).toSet()
        : <LocalDate>{};
    final byDate = <LocalDate, Training>{};
    for (final t in existing) {
      if (t.occurrenceDate == null) continue;
      byDate[LocalDate.parse(t.occurrenceDate!)] = t;
    }

    final create = <Training>[], update = <Training>[], cancel = <Training>[], delete = <String>[];
    final conflicts = <LocalDate>[];

    for (final d in desired.toList()..sort()) {
      final want = occurrence(s, d, now: now);
      if (!want.startAt.isAfter(now)) continue; // already started today
      final have = byDate[d];
      if (have == null) {
        if (oneOffStarts.any((o) => o.isAtSameMomentAs(want.startAt))) {
          conflicts.add(d);
          continue;
        }
        create.add(want);
        continue;
      }
      if (have.detached || have.status == TrainingStatus.cancelled || have.status == TrainingStatus.done) continue;
      final adopted = Training(
        id: have.id,
        groupId: want.groupId,
        venueId: want.venueId,
        startAt: want.startAt,
        durationMin: want.durationMin,
        focus: want.focus,
        description: want.description,
        createdBy: have.createdBy,
        photoUrls: have.photoUrls,
        status: have.status,
        updatedAt: now,
        previousStartAt: have.startAt.isAtSameMomentAs(want.startAt) ? have.previousStartAt : have.startAt,
        seriesId: s.id,
        occurrenceDate: d.toString(),
      );
      if (_differs(have, adopted)) update.add(adopted);
    }

    for (final e in byDate.entries) {
      final t = e.value;
      if (desired.contains(e.key)) continue;
      if (!t.startAt.isAfter(now)) continue; // never rewrite history
      if (t.detached || t.status == TrainingStatus.cancelled || t.status == TrainingStatus.done) continue;
      // Within the horizon but no longer covered by the rule, or beyond a new end date.
      if (withActivity.contains(t.id)) {
        cancel.add(
          t.copyWith(
            status: TrainingStatus.cancelled,
            cancelReasonCode: CancelReasonCode.other,
            cancelReason: scheduleChangedReason,
            cancelledAt: now,
            cancelledBy: s.createdBy,
            updatedAt: now,
          ),
        );
      } else {
        delete.add(t.id);
      }
    }
    return SeriesPlan(create: create, update: update, cancel: cancel, delete: delete, skippedConflicts: conflicts);
  }

  static bool _differs(Training a, Training b) =>
      a.seriesId != b.seriesId ||
      !a.startAt.isAtSameMomentAs(b.startAt) ||
      a.venueId != b.venueId ||
      a.durationMin != b.durationMin ||
      a.description != b.description ||
      a.focus.length != b.focus.length ||
      !a.focus.every(b.focus.contains);

  /// "Edit this and future occurrences" from [from]: the old series ends the
  /// day before; a new series (id [newId]) starts at [from] with [draft].
  static (TrainingSeries ended, TrainingSeries next) split(
    TrainingSeries old,
    SeriesDraft draft, {
    required LocalDate from,
    required String newId,
  }) {
    final ended = old.copyWith(
      endDate: from.addDays(-1),
      status: from <= old.startDate ? SeriesStatus.ended : SeriesStatus.active,
    );
    final next = TrainingSeries(
      id: newId,
      groupId: old.groupId,
      clubId: old.clubId,
      venueId: draft.venueId,
      weekdays: ([...draft.weekdays.toSet()]..sort()),
      startTime: draft.startTime,
      durationMin: draft.durationMin,
      focus: draft.focus,
      description: draft.description.trim(),
      startDate: from,
      endDate: draft.endDate,
      createdBy: old.createdBy,
      parentSeriesId: old.id,
    );
    return (ended, next);
  }
}
