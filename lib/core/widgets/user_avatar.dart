import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/media/presentation/media_providers.dart';
import 'app_widgets.dart';

/// Profile photo from private storage (v1.1 §3) with initials fallback.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({super.key, required this.name, this.photoPath, this.size = 44});

  final String name;
  final String? photoPath;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = photoPath;
    final bytes = path == null ? null : ref.watch(mediaBytesProvider(path)).value;
    if (bytes == null) return InitialsAvatar(name: name, size: size);
    return ClipOval(
      child: Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => InitialsAvatar(name: name, size: size),
      ),
    );
  }
}
