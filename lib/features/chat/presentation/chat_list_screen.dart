import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import 'chat_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    final groups = ref.watch(myGroupsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.chatGroups)),
      body: user != null && !user.canUseChat
          ? EmptyState(icon: Icons.lock_rounded, title: l.chatNotAllowed)
          : AsyncView<List<Group>>(
              value: groups,
              onRetry: () => ref.invalidate(myGroupsProvider),
              data: (list) {
                if (list.isEmpty) return EmptyState(icon: Icons.forum_outlined, title: l.noChats);
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    DemoBanner(text: l.chatPrivacyNote),
                    const SizedBox(height: AppSpacing.md),
                    for (final g in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: _ChatTile(group: g),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatMessagesProvider(group.id)).value ?? const [];
    final last = messages.isEmpty ? null : messages.last;
    final f = Fmt.of(context);
    return AppCard(
      key: Key('chat-tile-${group.id}'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: () => context.push(Routes.chat(group.id)),
      child: Row(
        children: [
          SportBadge(sportKey: group.sportId, size: 48),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  last == null
                      ? context.l10n.chatEmpty
                      : '${last.senderName.split(' ').first}: ${last.text.isEmpty ? '📷' : last.text}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (last != null) Text(f.time(last.createdAt), style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
