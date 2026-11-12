import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../domain/receipts.dart';
import 'chat_providers.dart';

/// `/chat/:groupId/receipts/:messageId` — the sending coach sees, per
/// parent in the creation-time snapshot: not seen / seen / acknowledged
/// with the server times. Updates in real time.
class ReceiptDetailsScreen extends ConsumerWidget {
  const ReceiptDetailsScreen({super.key, required this.groupId, required this.messageId});

  final String groupId;
  final String messageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final statuses = ref.watch(recipientStatusesProvider((groupId, messageId)));
    final receipt = ref.watch(sentReceiptsProvider(groupId)).value?[messageId];
    return Scaffold(
      appBar: AppBar(title: Text(l.receiptsTitle)),
      body: AsyncView<List<RecipientStatus>>(
        value: statuses,
        onRetry: () => ref.invalidate(recipientStatusesProvider((groupId, messageId))),
        data: (list) {
          final total = list.length;
          final seen = list.where((s) => s.state != ReceiptState.notSeen).length;
          final acked = list.where((s) => s.state == ReceiptState.acknowledged).length;
          final requiresAck = receipt?.requiresAck ?? acked > 0;
          int rank(RecipientStatus s) => switch (s.state) {
            ReceiptState.acknowledged => 0,
            ReceiptState.seen => 1,
            ReceiptState.notSeen => 2,
          };
          final sorted = [...list]
            ..sort((a, b) => rank(a) != rank(b) ? rank(a).compareTo(rank(b)) : a.name.compareTo(b.name));
          return ConstrainedContent(
            maxWidth: Breakpoints.readable,
            child: ListView(
              key: const Key('receipt-list'),
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusPill(
                      key: const Key('receipt-seen-count'),
                      label: l.receiptSeenShort(seen, total),
                      color: AppColors.blue,
                    ),
                    if (requiresAck)
                      StatusPill(
                        key: const Key('receipt-ack-count'),
                        label: l.receiptAckShort(acked, total),
                        color: AppColors.success,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l.receiptPrivacy, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                for (final s in sorted) _Row(status: s, showAck: requiresAck),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.status, required this.showAck});

  final RecipientStatus status;
  final bool showAck;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final t = Theme.of(context).textTheme;
    final (label, color, icon) = switch (status.state) {
      ReceiptState.acknowledged => (l.receiptAcknowledged, AppColors.success, Icons.task_alt_rounded),
      ReceiptState.seen => (l.receiptSeen, AppColors.blue, Icons.done_all_rounded),
      ReceiptState.notSeen => (l.receiptNotSeen, AppColors.neutral, Icons.remove_done_rounded),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        key: Key('receipt-row-${status.uid}'),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Row(
          children: [
            InitialsAvatar(name: status.name, size: 40),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status.name, style: t.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (status.readAt != null) Text(l.receiptSeenAt(f.dateTime(status.readAt!)), style: t.bodySmall),
                  if (showAck && status.ackAt != null)
                    Text(l.receiptAckAt(f.dateTime(status.ackAt!)), style: t.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                label,
                key: Key('receipt-state-${status.uid}'),
                style: t.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w800),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
