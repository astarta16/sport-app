import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../features/authentication/presentation/session_providers.dart';
import '../../features/chat/presentation/chat_providers.dart';
import '../../features/notifications/presentation/notifications_providers.dart';
import '../../features/organizations/presentation/feature_gate.dart';
import '../../features/organizations/domain/organization.dart';
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
    final user = ref.watch(currentUserProvider);
    final chatUnread = ref.watch(totalChatUnreadProvider);
    final unread = ref.watch(unreadCountProvider);
    final children = [
      if ((user?.canUseChat ?? false) && ref.watch(featureOnProvider(OrgModule.communication)))
        IconButton(
          key: const Key('chat-button'),
          tooltip: l.chatTooltip,
          onPressed: () => context.push(Routes.chats),
          icon: Badge(
            isLabelVisible: chatUnread > 0,
            label: Text('$chatUnread'),
            child: Icon(Icons.chat_bubble_outline_rounded, size: iconSize),
          ),
        ),
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
