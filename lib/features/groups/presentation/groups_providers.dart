import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../authentication/presentation/session_providers.dart';
import '../domain/group.dart';

final myGroupsProvider = StreamProvider<List<Group>>((ref) {
  if (ref.watch(currentUidProvider) == null) return Stream.value(const []);
  return ref.watch(groupsRepositoryProvider).watchMyGroups();
});

final groupsByIdProvider = Provider<Map<String, Group>>((ref) {
  final list = ref.watch(myGroupsProvider).value ?? const [];
  return {for (final g in list) g.id: g};
});

final clubGroupsProvider = FutureProvider.autoDispose.family<List<Group>, String>(
  (ref, clubId) => ref.watch(groupsRepositoryProvider).clubGroups(clubId),
);
