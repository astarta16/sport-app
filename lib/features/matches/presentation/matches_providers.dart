import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../groups/presentation/groups_providers.dart';
import '../domain/match.dart';

/// Matches of every group visible to the user.
final myMatchesProvider = StreamProvider<List<SportMatch>>((ref) async* {
  if (ref.watch(currentUidProvider) == null) {
    yield const [];
    return;
  }
  final groups = await ref.watch(myGroupsProvider.future);
  final ids = groups.map((g) => g.id).toList()..sort();
  yield* ref.watch(matchesRepositoryProvider).watchForGroups(ids);
});

final matchProvider = StreamProvider.autoDispose.family<SportMatch?, String>((ref, id) {
  ref.watch(currentUidProvider);
  return ref.watch(matchesRepositoryProvider).watchMatch(id);
});

/// Next active match for the given groups.
SportMatch? nextMatch(Iterable<SportMatch> all, Set<String> groupIds, DateTime now) {
  final list = all.where((m) => groupIds.contains(m.groupId) && m.status.isActive && m.endAt.isAfter(now)).toList()
    ..sort((a, b) => a.startAt.compareTo(b.startAt));
  return list.firstOrNull;
}
