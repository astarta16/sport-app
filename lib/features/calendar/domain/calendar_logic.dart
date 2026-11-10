import '../../../core/utils/dates.dart';
import '../../trainings/domain/training.dart';

/// Pure helpers behind the calendar screen.
class CalendarLogic {
  CalendarLogic._();

  /// Trainings keyed by local calendar day, each day sorted by start time.
  static Map<DateTime, List<Training>> byDay(Iterable<Training> trainings) {
    final map = <DateTime, List<Training>>{};
    for (final t in trainings) {
      (map[dateOnly(t.startAt)] ??= []).add(t);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.startAt.compareTo(b.startAt));
    }
    return map;
  }

  static List<Training> onDay(Map<DateTime, List<Training>> byDay, DateTime day) => byDay[dateOnly(day)] ?? const [];

  /// Upcoming (not finished, not done) trainings, soonest first.
  static List<Training> upcoming(Iterable<Training> trainings, DateTime now, {int limit = 10}) {
    final list = trainings.where((t) => t.endAt.isAfter(now) && t.status != TrainingStatus.done).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return list.take(limit).toList();
  }

  /// Number of active trainings in the ISO week containing [now].
  static int countThisWeek(Iterable<Training> trainings, DateTime now) {
    final start = dateOnly(now).subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return trainings.where((t) => t.status.isActive && !t.startAt.isBefore(start) && t.startAt.isBefore(end)).length;
  }
}
