import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../authentication/presentation/session_providers.dart';
import '../domain/notification_models.dart';

/// Per-category opt-outs (spec §9 "user can disable each type") plus the
/// SMS payment-reminder toggle (spec §14.5).
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: SkeletonList());
    final prefs = user.notificationPrefs;
    final types = [
      NotificationType.newTraining,
      NotificationType.trainingChanged,
      NotificationType.trainingReminder,
      NotificationType.chatMessage,
      NotificationType.newPhotos,
      if (user.isParent) ...[
        NotificationType.certificateExpiry,
        NotificationType.paymentReminder,
        NotificationType.paymentSms,
      ],
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.notificationSettings)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(l.notificationSettingsHint, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                for (final t in types)
                  SwitchListTile(
                    key: Key('pref-${t.name}'),
                    secondary: Icon(notificationIcon(t)),
                    title: Text(notificationTitle(context, t)),
                    value: prefs.isEnabled(t),
                    onChanged: (v) => runGuarded(
                      context,
                      () => ref.read(authRepositoryProvider).updateNotificationPrefs(prefs.toggle(t, v)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
