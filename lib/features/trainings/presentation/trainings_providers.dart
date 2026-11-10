import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../groups/presentation/groups_providers.dart';
import '../domain/training.dart';

/// All trainings of every group visible to the user.
final myTrainingsProvider = StreamProvider<List<Training>>((ref) async* {
  if (ref.watch(currentUidProvider) == null) {
    yield const [];
    return;
  }
  final groups = await ref.watch(myGroupsProvider.future);
  final ids = groups.map((g) => g.id).toList()..sort();
  yield* ref.watch(trainingsRepositoryProvider).watchForGroups(ids);
});

final trainingProvider = StreamProvider.autoDispose.family<Training?, String>((ref, id) {
  ref.watch(currentUidProvider);
  return ref.watch(trainingsRepositoryProvider).watchTraining(id);
});

/// Next active training at or after [now] for the given groups.
Training? nextTraining(Iterable<Training> all, Set<String> groupIds, DateTime now) {
  final list =
      all.where((t) => groupIds.contains(t.groupId) && t.endAt.isAfter(now) && t.status != TrainingStatus.done).toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
  final active = list.where((t) => t.status.isActive);
  return active.isNotEmpty ? active.first : (list.isNotEmpty ? list.first : null);
}
