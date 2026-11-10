import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../children/presentation/children_providers.dart';
import '../../sports/presentation/sports_providers.dart';
import '../domain/payment.dart';
import '../domain/payment_proof.dart';
import 'payments_providers.dart';

class ParentPaymentsScreen extends ConsumerStatefulWidget {
  const ParentPaymentsScreen({super.key});

  @override
  ConsumerState<ParentPaymentsScreen> createState() => _ParentPaymentsScreenState();
}

class _ParentPaymentsScreenState extends ConsumerState<ParentPaymentsScreen> {
  String? _childId;
  String? _sportId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final payments = ref.watch(myPaymentsProvider);
    final kids = ref.watch(myChildrenProvider).value ?? const [];
    final sports = ref.watch(sportsByIdProvider);
    final now = ref.watch(clockProvider)();
    return Scaffold(
      appBar: AppBar(title: Text(l.paymentsTitle)),
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: AsyncView<List<Payment>>(
          value: payments,
          onRetry: () => ref.invalidate(myPaymentsProvider),
          data: (all) {
            if (all.isEmpty) return EmptyState(icon: Icons.receipt_long_rounded, title: l.noPayments);
            final sportIds = {for (final p in all) p.sportId}.toList();
            final list = all
                .where(
                  (p) => (_childId == null || p.childId == _childId) && (_sportId == null || p.sportId == _sportId),
                )
                .toList();
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
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in kids)
                      FilterChip(
                        key: Key('pay-filter-child-${c.id}'),
                        label: Text(c.firstName),
                        selected: _childId == c.id,
                        onSelected: (v) => setState(() => _childId = v ? c.id : null),
                      ),
                    for (final s in sportIds)
                      FilterChip(
                        key: Key('pay-filter-sport-$s'),
                        avatar: Icon(SportVisuals.icon(s), size: 16),
                        label: Text(sports[s]?.name ?? s),
                        selected: _sportId == s,
                        onSelected: (v) => setState(() => _sportId = v ? s : null),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                DemoBanner(text: l.paymentsNoOnline),
                if (pending.isNotEmpty) ...[
                  SectionHeader(l.paymentPending),
                  for (final p in pending)
                    PaymentRow(
                      payment: p,
                      now: now,
                      actions: Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonalIcon(
                          key: Key('submit-proof-${p.id}'),
                          onPressed: () => context.push(Routes.paymentProof(p.id)),
                          icon: Icon(
                            p.verification.state == VerificationState.none
                                ? Icons.receipt_long_rounded
                                : Icons.visibility_rounded,
                          ),
                          label: Text(switch (p.verification.state) {
                            VerificationState.none => l.payProofAction,
                            VerificationState.rejected => l.payResubmit,
                            _ => l.payViewReceipt,
                          }),
                        ),
                      ),
                    ),
                ],
                if (history.isNotEmpty) ...[
                  SectionHeader(l.paymentHistory),
                  for (final p in history) PaymentRow(payment: p, now: now),
                ],
              ],
            );
          },
        ),
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
                      _StatePill(payment: payment, fallback: v),
                    ],
                  ),
                ),
              ],
            ),
            if (payment.status == PaymentStatus.pending && payment.verification.state == VerificationState.rejected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l.payRejectedReason(payment.verification.rejectionReason ?? ''),
                  key: Key('rejected-reason-${payment.id}'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ),
            if (actions != null) ...[const SizedBox(height: AppSpacing.xs), actions!],
          ],
        ),
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.payment, required this.fallback});

  final Payment payment;
  final StatusVisual fallback;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return switch (displayStateOf(payment)) {
      PaymentDisplayState.proofSubmitted => StatusPill(
        key: Key('state-${payment.id}'),
        label: l.payStateAwaiting,
        color: AppColors.blue,
        dense: true,
      ),
      PaymentDisplayState.underReview => StatusPill(
        key: Key('state-${payment.id}'),
        label: l.payStateUnderReview,
        color: AppColors.blue,
        dense: true,
      ),
      PaymentDisplayState.rejected => StatusPill(
        key: Key('state-${payment.id}'),
        label: l.payStateRejected,
        color: AppColors.danger,
        dense: true,
      ),
      _ => StatusPill.of(fallback, dense: true),
    };
  }
}
