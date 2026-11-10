import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import 'chat_providers.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

/// Phone: list → pushes the chat room. Tablet (≥ 840): master-detail with the
/// conversation in the right pane.
class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String? _selectedGroupId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    final groups = ref.watch(myGroupsProvider);
    if (user != null && !user.canUseChat) {
      return Scaffold(
        appBar: AppBar(title: Text(l.chatGroups)),
        body: EmptyState(icon: Icons.lock_rounded, title: l.chatNotAllowed),
      );
    }
    final split = MasterDetailLayout.isSplit(context);
    final list = groups.value ?? const <Group>[];
    final selected = split ? (list.where((g) => g.id == _selectedGroupId).firstOrNull ?? list.firstOrNull) : null;

    final master = AsyncView<List<Group>>(
      value: groups,
      onRetry: () => ref.invalidate(myGroupsProvider),
      data: (list) {
        if (list.isEmpty) return EmptyState(icon: Icons.forum_outlined, title: l.chatsEmpty);
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            DemoBanner(text: l.chatPrivacyNote),
            const SizedBox(height: AppSpacing.md),
            for (final g in list)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _ChatTile(
                  group: g,
                  selected: g.id == selected?.id,
                  onTap: split ? () => setState(() => _selectedGroupId = g.id) : null,
                ),
              ),
          ],
        );
      },
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.chatsTitle)),
      body: MasterDetailLayout(
        master: master,
        detail: selected == null
            ? null
            : ChatRoomScreen(key: ValueKey('chat-${selected.id}'), groupId: selected.id, embedded: true),
        emptyDetail: EmptyState(icon: Icons.forum_outlined, title: l.noChats),
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({required this.group, this.selected = false, this.onTap});

  final Group group;
  final bool selected;

  /// Overrides navigation (tablet master-detail selects instead of pushing).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = (ref.watch(chatSummariesProvider).value ?? const [])
        .where((s) => s.groupId == group.id)
        .firstOrNull;
    final last = summary?.lastMessage;
    final unread = summary?.unread ?? 0;
    final f = Fmt.of(context);
    final l = context.l10n;
    final preview = switch (last) {
      null => l.chatEmpty,
      final m when m.hidden => l.messageHidden,
      final m when m.isSystem => systemMessageText(context, m),
      final m => '${m.senderName.split(' ').first}: ${m.text.isEmpty ? '📷' : m.text}',
    };
    return AppCard(
      key: Key('chat-tile-${group.id}'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      onTap: onTap ?? () => context.push(Routes.chat(group.id)),
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
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: unread > 0 ? FontWeight.w700 : null,
                    color: unread > 0 ? Theme.of(context).colorScheme.onSurface : null,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (last != null) Text(f.time(last.createdAt), style: Theme.of(context).textTheme.labelSmall),
              if (unread > 0) ...[
                const SizedBox(height: 4),
                Badge(key: Key('chat-unread-${group.id}'), label: Text('$unread'), largeSize: 20),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
