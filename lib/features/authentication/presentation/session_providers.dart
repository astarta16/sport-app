import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../domain/app_user.dart';

final authSessionProvider = StreamProvider<AuthSession?>((ref) => ref.watch(authRepositoryProvider).watchSession());

final currentUserProvider = Provider<AppUser?>((ref) => ref.watch(authSessionProvider).value?.user);

/// Rebuild key for user-scoped streams: changes only when the uid changes.
final currentUidProvider = Provider<String?>((ref) => ref.watch(currentUserProvider.select((u) => u?.id)));

final publicProfileProvider = FutureProvider.autoDispose.family<PublicProfile?, String>((ref, uid) {
  ref.watch(currentUidProvider);
  return ref.watch(userDirectoryRepositoryProvider).profile(uid);
});

final sessionRoleProvider = Provider<UserRole?>((ref) => ref.watch(currentUserProvider.select((u) => u?.role)));
