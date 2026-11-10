import 'series.dart';
import 'training.dart';

abstract interface class TrainingsRepository {
  Stream<List<Training>> watchForGroups(List<String> groupIds);
  Stream<Training?> watchTraining(String id);
  Future<Training> create(TrainingDraft draft);

  /// Edits one training. For a recurring occurrence this detaches it from
  /// the series ("edit only this occurrence").
  Future<Training> update(String id, TrainingDraft draft);

  /// Reason is mandatory (v1.1 §7) — validated here and in the rules.
  Future<void> cancel(String id, CancelReason reason);
  Future<void> reschedule(String id, DateTime newStart);
  Future<void> markDone(String id);
  Future<void> addPhotos(String id, List<PhotoUpload> photos, {required bool consentConfirmed});

  // ── v1.2 recurring schedules ──────────────────────────────────────────
  Stream<List<TrainingSeries>> watchSeries(String groupId);
  Future<TrainingSeries> createSeries(SeriesDraft draft);

  /// "Edit this and future occurrences" starting at [from] (inclusive).
  Future<TrainingSeries> updateSeriesFrom(String seriesId, SeriesDraft draft, {required LocalDate from});

  /// Stops the series after [lastDate]; later occurrences are removed
  /// (or cancelled when parents already responded).
  Future<void> endSeries(String seriesId, {required LocalDate lastDate});
}
