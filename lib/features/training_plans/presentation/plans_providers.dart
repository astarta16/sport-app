import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../authentication/presentation/session_providers.dart';
import '../domain/training_plan.dart';

final plansProvider = StreamProvider<List<TrainingPlan>>((ref) {
  if (ref.watch(currentUidProvider) == null) return Stream.value(const []);
  return ref.watch(trainingPlansRepositoryProvider).watchPlans();
});

final planProvider = StreamProvider.autoDispose.family<TrainingPlan?, String>((ref, id) {
  ref.watch(currentUidProvider);
  return ref.watch(trainingPlansRepositoryProvider).watchPlan(id);
});

final planProgressProvider = StreamProvider.autoDispose.family<List<ExerciseProgress>, String>((ref, id) {
  ref.watch(currentUidProvider);
  return ref.watch(trainingPlansRepositoryProvider).watchProgress(id);
});

final planStatsProvider = StreamProvider.autoDispose.family<PlanStats, String>((ref, id) {
  ref.watch(currentUidProvider);
  return ref.watch(trainingPlansRepositoryProvider).watchStats(id);
});

final planMediaBytesProvider = FutureProvider.autoDispose.family<List<int>?, ({String planId, ExerciseMedia media})>((
  ref,
  key,
) {
  ref.watch(currentUidProvider);
  return ref.watch(trainingPlansRepositoryProvider).loadMedia(key.planId, key.media);
});
