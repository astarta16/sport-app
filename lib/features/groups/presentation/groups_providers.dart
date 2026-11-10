import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../trainings/domain/series.dart';
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

final myInvitesProvider = StreamProvider<List<GroupInvite>>((ref) {
  if (ref.watch(currentUidProvider) == null) return Stream.value(const []);
  return ref.watch(groupsRepositoryProvider).watchMyInvites();
});

/// Invitations addressed to me that still wait for an answer.
final openInvitesProvider = Provider<List<GroupInvite>>(
  (ref) => (ref.watch(myInvitesProvider).value ?? const []).where((i) => i.status == InviteStatus.sent).toList(),
);

final groupInvitesProvider = StreamProvider.autoDispose.family<List<GroupInvite>, String>((ref, groupId) {
  ref.watch(currentUidProvider);
  return ref.watch(groupsRepositoryProvider).watchGroupInvites(groupId);
});

final groupProvider = StreamProvider.autoDispose.family<Group?, String>((ref, id) {
  ref.watch(currentUidProvider);
  return ref.watch(groupsRepositoryProvider).watchGroup(id);
});

final seriesForGroupProvider = StreamProvider.autoDispose.family<List<TrainingSeries>, String>((ref, groupId) {
  ref.watch(currentUidProvider);
  return ref.watch(trainingsRepositoryProvider).watchSeries(groupId);
});
