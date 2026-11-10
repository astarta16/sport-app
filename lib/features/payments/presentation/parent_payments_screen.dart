import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../children/presentation/children_providers.dart';
import '../../sports/presentation/sports_providers.dart';
import '../domain/payment.dart';
import 'payments_providers.dart';

class ParentPaymentsScreen extends ConsumerWidget {
  const ParentPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final payments = ref.watch(myPaymentsProvider);
    final now = ref.watch(clockProvider)();
    return Scaffold(
      appBar: AppBar(title: Text(l.paymentsTitle)),
      body: AsyncView<List<Payment>>(
        value: payments,
        onRetry: () => ref.invalidate(myPaymentsProvider),
        data: (list) {
          if (list.isEmpty) return EmptyState(icon: Icons.receipt_long_rounded, title: l.noPayments);
          final pending = list.where((p) => p.status == PaymentStatus.pending).toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
          final history = list.where((p) => p.status != PaymentStatus.pending).toList();
          final f = Fmt.of(context);
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
            children: [
              AppCard(
                gradient: AppColors.nightGradient,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.totalDue, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                    Text(
                      f.money(pendingTotal(list)),
                      key: const Key('total-due'),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white),
                    ),
                    if (pending.isNotEmpty)
                      Text(
                        l.nextDue(f.dayMonth(pending.first.dueDate)),
                        style: const TextStyle(color: AppColors.volt, fontWeight: FontWeight.w700),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l.reminderSchedule,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              if (pending.isNotEmpty) ...[
                SectionHeader(l.paymentPending),
                for (final p in pending) PaymentRow(payment: p, now: now),
              ],
              if (history.isNotEmpty) ...[
                SectionHeader(l.paymentHistory),
                for (final p in history) PaymentRow(payment: p, now: now),
              ],
            ],
          );
        },
      ),
    );
  }
}

class PaymentRow extends ConsumerWidget {
  const PaymentRow({super.key, required this.payment, required this.now, this.actions});

  final Payment payment;
  final DateTime now;
  final Widget? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final sport = ref.watch(sportsByIdProvider)[payment.sportId];
    final child = ref.watch(childProvider(payment.childId)).value;
    final v = StatusVisual.payment(context, payment, now);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        key: Key('payment-${payment.id}'),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Row(
              children: [
                SportBadge(sportKey: payment.sportId, size: 42),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${child?.firstName ?? ''} · ${sport?.name ?? payment.sportId}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        payment.status == PaymentStatus.paid && payment.paidAt != null
                            ? l.paidOn(f.dayMonth(payment.paidAt!))
                            : l.dueOn(f.dayMonth(payment.dueDate)),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(f.money(payment.amount), style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      StatusPill.of(v, dense: true),
                    ],
                  ),
                ),
              ],
            ),
            if (actions != null) ...[const SizedBox(height: AppSpacing.xs), actions!],
          ],
        ),
      ),
    );
  }
}
