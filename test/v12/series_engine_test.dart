import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/core/utils/dates.dart';
import 'package:sport_parent_app/features/trainings/domain/series.dart';
import 'package:sport_parent_app/features/trainings/domain/training.dart';

void main() {
  // Tuesday 2026-11-10 10:00 Tbilisi.
  final now = TbilisiTime.at(2026, 11, 10, 10);
  final today = LocalDate.tbilisi(now);
  TrainingSeries series({List<int> days = const [1, 3, 5], LocalDate? end, String id = 's1'}) => TrainingSeries(
    id: id,
    groupId: 'g1',
    venueId: 'v1',
    weekdays: days,
    startTime: const LocalTime(18, 0),
    durationMin: 90,
    focus: const [TrainingFocus.ball],
    startDate: today,
    endDate: end,
    createdBy: 'c1',
  );

  group('LocalDate / Tbilisi', () {
    test('Tbilisi date of an instant late at night UTC is the next day', () {
      expect(LocalDate.tbilisi(DateTime.utc(2026, 11, 10, 21)), const LocalDate(2026, 11, 11));
    });
    test('occurrence instant is 18:00 Tbilisi = 14:00 UTC (no DST shift in summer)', () {
      expect(const LocalDate(2026, 7, 1).at(18, 0), DateTime.utc(2026, 7, 1, 14));
      expect(const LocalDate(2026, 1, 1).at(18, 0), DateTime.utc(2026, 1, 1, 14));
    });
    test('weekday numbering: 2026-11-09 is Monday', () => expect(const LocalDate(2026, 11, 9).weekday, 1));
  });

  group('generation', () {
    test('Mon/Wed/Fri over the 8-week horizon with deterministic ids', () {
      final plan = RecurrenceEngine.reconcile(series(), existing: const [], now: now);
      expect(plan.create, hasLength(24)); // 8 weeks × 3
      expect(plan.create.first.id, 's1_20261111'); // first Wednesday
      expect(plan.create.every((t) => [1, 3, 5].contains(LocalDate.parse(t.occurrenceDate!).weekday)), isTrue);
      expect(plan.create.first.startAt, TbilisiTime.at(2026, 11, 11, 18));
    });

    test('is idempotent: re-running on its own output changes nothing', () {
      final first = RecurrenceEngine.reconcile(series(), existing: const [], now: now);
      final again = RecurrenceEngine.reconcile(series(), existing: first.create, now: now);
      expect(again.isEmpty, isTrue);
    });

    test('respects end date and never generates in the past', () {
      final s = series(end: today.addDays(6));
      final plan = RecurrenceEngine.reconcile(s, existing: const [], now: now);
      expect(plan.create.map((t) => t.occurrenceDate), ['2026-11-11', '2026-11-13', '2026-11-16']);
    });

    test('skips dates where a one-off training already starts at that moment (duplicate guard)', () {
      final clash = TbilisiTime.at(2026, 11, 11, 18);
      final plan = RecurrenceEngine.reconcile(
        series(end: today.addDays(3)),
        existing: const [],
        now: now,
        oneOffStarts: {clash},
      );
      expect(plan.skippedConflicts, [const LocalDate(2026, 11, 11)]);
      expect(plan.create.map((t) => t.occurrenceDate), ['2026-11-13']);
    });
  });

  group('changes', () {
    test('dropping a weekday deletes untouched occurrences, cancels ones with RSVPs/attendance', () {
      final created = RecurrenceEngine.reconcile(
        series(end: today.addDays(13)),
        existing: const [],
        now: now,
      ).create;
      final fridays = created.where((t) => LocalDate.parse(t.occurrenceDate!).weekday == 5).toList();
      final changed = series(days: const [1, 3], end: today.addDays(13));
      final plan = RecurrenceEngine.reconcile(changed, existing: created, now: now, withActivity: {fridays.first.id});
      expect(plan.cancel.map((t) => t.id), [fridays.first.id]);
      expect(plan.cancel.single.cancelReason, RecurrenceEngine.scheduleChangedReason);
      expect(plan.delete, fridays.skip(1).map((t) => t.id).toList());
      expect(plan.create, isEmpty);
    });

    test('time change updates in place and keeps ids (RSVPs stay attached)', () {
      final created = RecurrenceEngine.reconcile(
        series(end: today.addDays(6)),
        existing: const [],
        now: now,
      ).create;
      final later = TrainingSeries.fromMap('s1', {...series(end: today.addDays(6)).toMap(), 'startTime': '19:30'});
      final plan = RecurrenceEngine.reconcile(later, existing: created, now: now);
      expect(plan.update.map((t) => t.id), created.map((t) => t.id));
      expect(plan.update.first.startAt, TbilisiTime.at(2026, 11, 11, 19, 30));
      expect(plan.create, isEmpty);
    });

    test('detached and cancelled occurrences are never touched', () {
      final created = RecurrenceEngine.reconcile(
        series(end: today.addDays(6)),
        existing: const [],
        now: now,
      ).create;
      final detached = created[0].copyWith(detached: true, venueId: 'other');
      final cancelled = created[1].copyWith(status: TrainingStatus.cancelled);
      final plan = RecurrenceEngine.reconcile(
        TrainingSeries.fromMap('s1', {...series(end: today.addDays(6)).toMap(), 'venueId': 'v2'}),
        existing: [detached, cancelled, ...created.skip(2)],
        now: now,
      );
      expect(plan.update.map((t) => t.id), isNot(contains(detached.id)));
      expect(plan.update.map((t) => t.id), isNot(contains(cancelled.id)));
    });

    test('split: new series adopts the old future occurrences by date and keeps their ids', () {
      final old = series(end: today.addDays(13));
      final created = RecurrenceEngine.reconcile(old, existing: const [], now: now).create;
      final from = today.addDays(7);
      final (ended, next) = RecurrenceEngine.split(
        old,
        SeriesDraft(
          groupId: 'g1',
          venueId: 'v1',
          weekdays: const [1, 3],
          startTime: const LocalTime(18, 0),
          durationMin: 90,
          focus: const [TrainingFocus.ball],
          startDate: from,
        ),
        from: from,
        newId: 's2',
      );
      expect(ended.endDate, from.addDays(-1));
      final adopted = created.where((t) => LocalDate.parse(t.occurrenceDate!) >= from).toList();
      final plan = RecurrenceEngine.reconcile(next, existing: adopted, now: now);
      final kept = plan.update.map((t) => t.id).toSet();
      // Mon/Wed in the second week keep their old ids; Friday is removed.
      expect(kept, containsAll(adopted.where((t) => LocalDate.parse(t.occurrenceDate!).weekday != 5).map((t) => t.id)));
      expect(plan.update.every((t) => t.seriesId == 's2'), isTrue);
      expect(plan.delete.length, 1);
    });

    test('overlap detection blocks a second schedule on the same day and time', () {
      final draft = SeriesDraft(
        groupId: 'g1',
        venueId: 'v1',
        weekdays: const [3],
        startTime: const LocalTime(18, 0),
        durationMin: 60,
        focus: const [TrainingFocus.ball],
        startDate: today,
      );
      expect(SeriesDraft.overlaps(draft, series()), isTrue);
      expect(SeriesDraft.overlaps(draft, series(days: const [2])), isFalse);
    });

    test('validation', () {
      SeriesDraft d({List<int> days = const [1], LocalDate? start, LocalDate? end}) => SeriesDraft(
        groupId: 'g1',
        venueId: 'v1',
        weekdays: days,
        startTime: const LocalTime(18, 0),
        durationMin: 60,
        focus: const [TrainingFocus.ball],
        startDate: start ?? today,
        endDate: end,
      );
      expect(SeriesDraft.validate(d(days: const []), today: today), contains('weekdaysRequired'));
      expect(SeriesDraft.validate(d(start: today.addDays(-1)), today: today), contains('startInPast'));
      expect(SeriesDraft.validate(d(end: today.addDays(-1)), today: today), contains('endBeforeStart'));
      expect(SeriesDraft.validate(d(), today: today), isEmpty);
    });
  });
}
