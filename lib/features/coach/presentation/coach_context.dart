import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../parent/presentation/parent_context.dart';

/// The coach's selected group (persisted through `lastContext.groupId`).
final coachSelectedGroupProvider = Provider<AsyncValue<Group?>>((ref) {
  final groups = ref.watch(myGroupsProvider);
  final ctx = ref.watch(selectionContextProvider);
  return groups.whenData((list) {
    if (list.isEmpty) return null;
    return list.where((g) => g.id == ctx.groupId).firstOrNull ?? list.first;
  });
});
