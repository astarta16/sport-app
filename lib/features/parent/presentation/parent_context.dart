import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../authentication/domain/app_user.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';

/// Resolved dashboard selection for a parent.
class ParentSelection {
  const ParentSelection({required this.children, this.child, this.sportId, this.group});

  final List<Child> children;
  final Child? child;
  final String? sportId;
  final Group? group;

  bool get hasChildren => children.isNotEmpty;
}

/// Remembers the last child / sport / group (spec §5 `lastContext`, §6.1).
///
/// Persisted twice: locally (SharedPreferences, instant restore and offline)
/// and on the user document (restores across devices).
class SelectionContextController extends Notifier<UserContext> {
  static String _key(String uid) => 'lastContext.$uid';

  @override
  UserContext build() {
    final user = ref.watch(currentUserProvider.select((u) => u?.id == null ? null : (u!.id, u.lastContext)));
    if (user == null) return const UserContext();
    final (uid, remote) = user;
    final raw = ref.read(sharedPreferencesProvider).getString(_key(uid));
    if (raw != null) {
      try {
        return UserContext.fromMap(jsonDecode(raw));
      } catch (_) {}
    }
    return remote;
  }

  Future<void> update(UserContext next) async {
    if (next == state) return;
    state = next;
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref.read(sharedPreferencesProvider).setString(_key(uid), jsonEncode(next.toMap()));
    try {
      await ref.read(authRepositoryProvider).updateLastContext(next);
    } catch (_) {
      // Offline: the local copy is enough; it syncs on the next change.
    }
  }

  Future<void> selectChild(String childId) => update(UserContext(childId: childId));

  Future<void> selectSport(String sportId) => update(UserContext(childId: state.childId, sportId: sportId));

  Future<void> selectGroup(String groupId) => update(state.copyWith(groupId: groupId));
}

final selectionContextProvider = NotifierProvider<SelectionContextController, UserContext>(
  SelectionContextController.new,
);

/// Pure resolution of the stored context against current data, falling back
/// to sensible defaults when a stored id no longer exists.
ParentSelection resolveParentSelection(UserContext ctx, List<Child> children, List<Group> groups) {
  if (children.isEmpty) return ParentSelection(children: children);
  // No (valid) stored child: prefer one that already trains in a group.
  final child =
      children.where((c) => c.id == ctx.childId).firstOrNull ??
      children.where((c) => groups.any((g) => g.hasChild(c.id))).firstOrNull ??
      children.first;
  final sports = child.sportIds;
  final sportId = sports.contains(ctx.sportId) ? ctx.sportId : (sports.isEmpty ? null : sports.first);
  final childGroups = groups.where((g) => g.hasChild(child.id) && g.sportId == sportId).toList();
  final group = childGroups.where((g) => g.id == ctx.groupId).firstOrNull ?? childGroups.firstOrNull;
  return ParentSelection(children: children, child: child, sportId: sportId, group: group);
}

final parentSelectionProvider = Provider<AsyncValue<ParentSelection>>((ref) {
  final children = ref.watch(myChildrenProvider);
  final groups = ref.watch(myGroupsProvider);
  final ctx = ref.watch(selectionContextProvider);
  if (children is AsyncError) return AsyncError(children.error!, children.stackTrace!);
  if (groups is AsyncError) return AsyncError(groups.error!, groups.stackTrace!);
  final c = children.value;
  final g = groups.value;
  if (c == null || g == null) return const AsyncLoading();
  return AsyncData(resolveParentSelection(ctx, c, g));
});
