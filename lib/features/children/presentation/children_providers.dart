import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../authentication/presentation/session_providers.dart';
import '../domain/child.dart';

final myChildrenProvider = StreamProvider<List<Child>>((ref) {
  if (ref.watch(currentUidProvider) == null) return Stream.value(const []);
  return ref.watch(childrenRepositoryProvider).watchMyChildren();
});

final childProvider = StreamProvider.autoDispose.family<Child?, String>((ref, id) {
  ref.watch(currentUidProvider);
  return ref.watch(childrenRepositoryProvider).watchChild(id);
});

final groupMembersProvider = StreamProvider.autoDispose.family<List<Child>, String>((ref, groupId) {
  ref.watch(currentUidProvider);
  return ref.watch(childrenRepositoryProvider).watchGroupMembers(groupId);
});
