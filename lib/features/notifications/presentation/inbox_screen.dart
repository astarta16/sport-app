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
import '../domain/notification_models.dart';
import 'notifications_providers.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final inbox = ref.watch(inboxProvider);
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
            onPressed: () => ref.read(notificationsRepositoryProvider).markAllRead(),
            child: Text(l.markAllRead),
          ),
        ],
      ),
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: AsyncView<List<AppNotification>>(
          value: inbox,
          data: (list) {
            if (list.isEmpty) return EmptyState(icon: Icons.notifications_off_outlined, title: l.notificationsEmpty);
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (demo) ...[DemoBanner(text: l.pushDemoNote), const SizedBox(height: AppSpacing.sm)],
                for (final n in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: AppCard(
                      color: n.read ? null : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.45),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      onTap: () {
                        ref.read(notificationsRepositoryProvider).markRead(n.id);
                        if (n.route != null) context.push(n.route!);
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(notificationIcon(n.type), color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notificationTitle(context, n.type), style: Theme.of(context).textTheme.titleSmall),
                                Text(notificationBody(context, n), style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Text(
                            Fmt.of(context).dayMonthShort(n.createdAt),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          if (!n.read) ...[
                            const SizedBox(width: 6),
                            const CircleAvatar(radius: 4, backgroundColor: AppColors.blue),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
