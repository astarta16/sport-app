/// Date helpers shared by the app and the reminder logic.
///
/// Georgia (Asia/Tbilisi) has used UTC+4 all year round since 2005 (no DST),
/// so a fixed offset is exact and avoids shipping the full tz database.
class TbilisiTime {
  TbilisiTime._();

  static const Duration offset = Duration(hours: 4);

  /// Wall-clock time in Tbilisi, represented as a UTC [DateTime] whose
  /// fields (year, month, day, hour…) read as Tbilisi local time.
  static DateTime wallClock(DateTime instant) => instant.toUtc().add(offset);

  /// The Tbilisi calendar day of [instant], as a UTC midnight.
  static DateTime calendarDay(DateTime instant) {
    final w = wallClock(instant);
    return DateTime.utc(w.year, w.month, w.day);
  }

  /// Whole calendar days from [from] to [to] in Tbilisi (can be negative).
  static int daysBetween(DateTime from, DateTime to) =>
      calendarDay(to).difference(calendarDay(from)).inDays;

  /// Builds the instant for a Tbilisi wall-clock date and time.
  static DateTime at(int year, int month, int day, [int hour = 0, int minute = 0]) =>
      DateTime.utc(year, month, day, hour, minute).subtract(offset);
}

/// Strips the time part, keeping the local calendar date.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Age in completed years on [on].
int ageInYears(DateTime birthDate, DateTime on) {
  var age = on.year - birthDate.year;
  final hadBirthday = on.month > birthDate.month ||
      (on.month == birthDate.month && on.day >= birthDate.day);
  if (!hadBirthday) age--;
  return age;
}

/// Reads a date from any storage representation: [DateTime], ISO string,
/// epoch millis, or a Firestore `Timestamp` (anything with `toDate()`).
DateTime readDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value != null) {
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      // fall through
    }
  }
  throw FormatException('Unsupported date value: $value');
}

DateTime? readDateOrNull(Object? value) => value == null ? null : readDate(value);

List<String> readStringList(Object? value) =>
    value is List ? value.map((e) => e.toString()).toList() : const [];
