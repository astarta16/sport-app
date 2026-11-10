import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../trainings/domain/training.dart';
import '../../trainings/presentation/trainings_providers.dart';
import '../domain/attendance.dart';

final rsvpsForTrainingProvider = StreamProvider.autoDispose.family<List<Rsvp>, String>((ref, trainingId) {
  ref.watch(currentUidProvider);
  return ref.watch(attendanceRepositoryProvider).watchRsvpsForTraining(trainingId);
});

final rsvpsForChildProvider = StreamProvider.autoDispose.family<List<Rsvp>, String>((ref, childId) {
  ref.watch(currentUidProvider);
  return ref.watch(attendanceRepositoryProvider).watchRsvpsForChild(childId);
});

final attendanceForTrainingProvider = StreamProvider.autoDispose.family<List<AttendanceRecord>, String>((ref, id) {
  ref.watch(currentUidProvider);
  return ref.watch(attendanceRepositoryProvider).watchForTraining(id);
});

final attendanceForChildProvider = StreamProvider.autoDispose.family<List<AttendanceRecord>, String>((ref, childId) {
  ref.watch(currentUidProvider);
  return ref.watch(attendanceRepositoryProvider).watchForChild(childId);
});

final attendanceForGroupProvider = StreamProvider.autoDispose.family<List<AttendanceRecord>, String>((ref, groupId) {
  ref.watch(currentUidProvider);
  return ref.watch(attendanceRepositoryProvider).watchForGroup(groupId);
});

final feedbackForChildProvider = StreamProvider.autoDispose.family<List<CoachFeedback>, String>((ref, childId) {
  ref.watch(currentUidProvider);
  return ref.watch(attendanceRepositoryProvider).watchFeedback(childId);
});

/// Training start instants used to order/bucket attendance.
final trainingStartsProvider = Provider<Map<String, DateTime>>((ref) {
  final all = ref.watch(myTrainingsProvider).value ?? const <Training>[];
  return {for (final t in all) t.id: t.startAt};
});

/// Statistics from coach-recorded attendance only (RSVPs never count).
final childStatsProvider = Provider.autoDispose.family<AsyncValue<AttendanceStats>, String>((ref, childId) {
  final records = ref.watch(attendanceForChildProvider(childId));
  final starts = ref.watch(trainingStartsProvider);
  return records.whenData((r) => AttendanceStats.compute(r, starts));
});

/// Group-level stats for the coach: rate per child and overall.
class GroupAttendanceStats {
  const GroupAttendanceStats({required this.overall, required this.byChild});

  final AttendanceStats overall;
  final Map<String, AttendanceStats> byChild;
}

final groupStatsProvider = Provider.autoDispose.family<AsyncValue<GroupAttendanceStats>, String>((ref, groupId) {
  final records = ref.watch(attendanceForGroupProvider(groupId));
  final starts = ref.watch(trainingStartsProvider);
  return records.whenData((r) {
    final byChild = <String, List<AttendanceRecord>>{};
    for (final a in r) {
      (byChild[a.childId] ??= []).add(a);
    }
    return GroupAttendanceStats(
      overall: AttendanceStats.compute(r, starts),
      byChild: {for (final e in byChild.entries) e.key: AttendanceStats.compute(e.value, starts)},
    );
  });
});
