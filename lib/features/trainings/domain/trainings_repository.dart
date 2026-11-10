import 'training.dart';

abstract interface class TrainingsRepository {
  Stream<List<Training>> watchForGroups(List<String> groupIds);
  Stream<Training?> watchTraining(String id);
  Future<Training> create(TrainingDraft draft);
  Future<Training> update(String id, TrainingDraft draft);
  Future<void> cancel(String id);
  Future<void> reschedule(String id, DateTime newStart);
  Future<void> markDone(String id);
  Future<void> addPhotos(String id, List<PhotoUpload> photos, {required bool consentConfirmed});
}
