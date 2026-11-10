import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../groups/presentation/groups_providers.dart';
import '../domain/media_post.dart';

/// Private bytes, re-fetched per signed-in user; access is re-checked by
/// the backend (membership-based), so a revoked parent gets an error.
final mediaBytesProvider = FutureProvider.autoDispose.family<Uint8List?, String>((ref, refPath) {
  ref.watch(currentUidProvider);
  if (refPath.startsWith('demo://')) return Future.value(null);
  return ref.watch(mediaRepositoryProvider).load(refPath);
});

/// A training/chat photo that resolves its private bytes via [MediaRepository].
class MediaPhoto extends ConsumerWidget {
  const MediaPhoto({super.key, required this.refPath, this.sportKey = 'football', this.size});

  final String refPath;
  final String sportKey;
  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(mediaBytesProvider(refPath)).value;
    return TrainingPhoto(url: refPath, bytes: bytes, sportKey: sportKey, size: size);
  }
}

/// Coach media posts visible to the user (their groups).
final mediaFeedProvider = StreamProvider<List<MediaPost>>((ref) async* {
  if (ref.watch(currentUidProvider) == null) {
    yield const [];
    return;
  }
  final groups = await ref.watch(myGroupsProvider.future);
  final ids = groups.map((g) => g.id).toList()..sort();
  yield* ref.watch(mediaPostsRepositoryProvider).watchForGroups(ids);
});

final coachMediaProvider = StreamProvider.autoDispose.family<List<MediaPost>, String>((ref, coachId) {
  ref.watch(currentUidProvider);
  return ref.watch(mediaPostsRepositoryProvider).watchByCoach(coachId);
});
