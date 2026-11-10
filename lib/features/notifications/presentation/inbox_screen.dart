import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config.dart';
import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../authentication/domain/app_user.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../parent/presentation/parent_context.dart';
import '../domain/notification_models.dart';
import 'notifications_providers.dart';

/// Notification center (v1.2): categories, read/unread, mark all, deep links
/// that switch to the right child / sport / group, pagination.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  static const _page = 20;
  NotificationCategory? _category;
  int _limit = _page;

  Future<void> _open(AppNotification n) async {
    ref.read(notificationsRepositoryProvider).markRead(n.id).catchError((_) {});
    await openNotificationTarget(context, ref, n);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final inbox = ref.watch(inboxPageProvider((limit: _limit, category: _category)));
    final demo = ref.watch(appModeProvider) == AppMode.demo;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.notificationsTitle),
        actions: [
          IconButton(
            tooltip: l.notificationSettings,
            onPressed: () => context.push(Routes.notificationSettings),
            icon: const Icon(Icons.tune_rounded),
          ),
          TextButton(
            key: const Key('mark-all-read'),
            onPressed: () => runGuarded(context, () => ref.read(notificationsRepositoryProvider).markAllRead()),
            child: Text(l.markAllRead),
          ),
        ],
      ),
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                children: [
                  ChoiceChip(
                    key: const Key('inbox-cat-all'),
                    label: Text(l.all),
                    selected: _category == null,
                    onSelected: (_) => setState(() {
                      _category = null;
                      _limit = _page;
                    }),
                  ),
                  for (final c in NotificationCategory.values) ...[
                    const SizedBox(width: AppSpacing.xs),
                    ChoiceChip(
                      key: Key('inbox-cat-${c.name}'),
                      avatar: Icon(notificationCategoryIcon(c), size: 16),
                      label: Text(notificationCategoryLabel(context, c)),
                      selected: _category == c,
                      onSelected: (_) => setState(() {
                        _category = c;
                        _limit = _page;
                      }),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: AsyncView<List<AppNotification>>(
                value: inbox,
                onRetry: () => ref.invalidate(inboxPageProvider),
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyState(
                      icon: Icons.notifications_off_outlined,
                      title: _category == null ? l.notificationsEmpty : l.notificationsEmptyCategory,
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    children: [
                      if (demo) ...[DemoBanner(text: l.pushDemoNote), const SizedBox(height: AppSpacing.sm)],
                      for (final n in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: NotificationTile(notification: n, onTap: () => _open(n)),
                        ),
                      if (list.length >= _limit)
                        Center(
                          child: TextButton.icon(
                            key: const Key('inbox-load-more'),
                            onPressed: () => setState(() => _limit += _page),
                            icon: const Icon(Icons.expand_more_rounded),
                            label: Text(l.loadMore),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      key: Key('ntf-${n.id}'),
      color: n.read ? null : scheme.primaryContainer.withValues(alpha: 0.45),
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Icon(notificationIcon(n.type), color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notificationTitle(context, n.type),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: n.read ? null : FontWeight.w800),
                ),
                Text(
                  notificationBody(context, n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(Fmt.of(context).dayMonthShort(n.createdAt), style: Theme.of(context).textTheme.labelSmall),
          if (!n.read) ...[const SizedBox(width: 6), const CircleAvatar(radius: 4, backgroundColor: AppColors.blue)],
        ],
      ),
    );
  }
}

/// Switches the dashboard context (child / sport / group) the notification
/// is about, then opens its route. Access is re-checked by the target
/// screen's repository, so a stale or forged route shows "no access".
Future<void> openNotificationTarget(BuildContext context, WidgetRef ref, AppNotification n) async {
  final ctx = ref.read(selectionContextProvider.notifier);
  final group = n.groupId == null ? null : ref.read(groupsByIdProvider)[n.groupId];
  final role = ref.read(sessionRoleProvider);
  if (role == UserRole.parent && n.childId != null) {
    await ctx.update(
      ref.read(selectionContextProvider).copyWith(childId: n.childId, sportId: group?.sportId, groupId: group?.id),
    );
  } else if (role == UserRole.coach && group != null) {
    await ctx.selectGroup(group.id);
  }
  if (!context.mounted) return;
  if (n.route != null) context.push(n.route!);
}
