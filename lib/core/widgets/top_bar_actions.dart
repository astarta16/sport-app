import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../features/notifications/presentation/notifications_providers.dart';
import '../l10n/l10n.dart';

/// Chat icon (v1.1 §4: moved from the bottom bar to the top bar) and the
/// notification bell, both with unread badges. Child accounts never get the
/// chat icon.
class TopBarActions extends ConsumerWidget {
  const TopBarActions({super.key, this.iconSize = 26, this.vertical = false});

  final double iconSize;
  final bool vertical;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final unread = ref.watch(unreadCountProvider);
    final children = [
      IconButton(
        key: const Key('notifications-button'),
        tooltip: l.notificationsTitle,
        onPressed: () => context.push(Routes.notifications),
        icon: Badge(
          isLabelVisible: unread > 0,
          label: Text('$unread'),
          child: Icon(Icons.notifications_none_rounded, size: iconSize),
        ),
      ),
    ];
    return vertical
        ? Column(mainAxisSize: MainAxisSize.min, children: children)
        : Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}
