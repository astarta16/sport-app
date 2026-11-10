import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/widgets/app_widgets.dart';

final mediaBytesProvider = FutureProvider.family<Uint8List?, String>((ref, refPath) {
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
