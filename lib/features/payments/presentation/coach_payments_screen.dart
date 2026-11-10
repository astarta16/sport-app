import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config.dart';
import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../groups/presentation/groups_providers.dart';
import '../domain/payment.dart';
import 'parent_payments_screen.dart';
import 'payments_providers.dart';

/// Coach/admin payment management for a group (spec §14): manual status,
/// one-off charges, recurring plans, reminder job and SMS log.
class CoachPaymentsScreen extends ConsumerWidget {
  const CoachPaymentsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final group = ref.watch(groupsByIdProvider)[groupId];
    final payments = ref.watch(groupPaymentsProvider(groupId));
    final plans = ref.watch(groupPlansProvider(groupId)).value ?? const <PaymentPlan>[];
    final now = ref.watch(clockProvider)();
    final demo = ref.watch(appModeProvider) == AppMode.demo;
    final repo = ref.read(paymentsRepositoryProvider);
    final f = Fmt.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${l.paymentsTitle} · ${group?.name ?? ''}')),
      body: ConstrainedContent(
        maxWidth: 960,
        child: AsyncView<List<Payment>>(
          value: payments,
          onRetry: () => ref.invalidate(groupPaymentsProvider(groupId)),
          data: (list) {
            final pending = list.where((p) => p.status == PaymentStatus.pending).toList()
              ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
            final rest = list.where((p) => p.status != PaymentStatus.pending).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('charge-group'),
                      onPressed: () => _charge(context, ref),
                      icon: const Icon(Icons.add_card_rounded),
                      label: Text(l.chargeGroup),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _plan(context, ref),
                      icon: const Icon(Icons.autorenew_rounded),
                      label: Text(l.createPlan),
                    ),
                  ],
                ),
                if (plans.isNotEmpty) ...[
                  SectionHeader(l.recurringPlans),
                  for (final p in plans)
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: ListTile(
                        leading: const Icon(Icons.event_repeat_rounded),
                        title: Text(l.everyMonthOn(f.money(p.amount).replaceAll(' ₾', ''), p.dayOfMonth)),
                        subtitle: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            onPressed: () async {
                              final n = await repo.generateRecurring(p.id, year: now.year, month: now.month);
                              if (context.mounted) showAppSnack(context, l.generated(n));
                            },
                            child: Text(l.generateThisMonth),
                          ),
                        ),
                      ),
                    ),
                ],
                SectionHeader(l.paymentPending),
                if (pending.isEmpty)
                  AppCard(
                    child: EmptyState(compact: true, icon: Icons.check_circle_outline_rounded, title: l.allPaid),
                  ),
                for (final p in pending)
                  PaymentRow(
                    payment: p,
                    now: now,
                    actions: Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            key: Key('mark-paid-${p.id}'),
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                            onPressed: () => runGuarded(
                              context,
                              () => repo.setStatus(p.id, PaymentStatus.paid),
                              success: l.paymentUpdated,
                            ),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(l.markPaid),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        TextButton(
                          onPressed: () => runGuarded(
                            context,
                            () => repo.setStatus(p.id, PaymentStatus.cancelled),
                            success: l.paymentUpdated,
                          ),
                          child: Text(l.cancelPayment),
                        ),
                      ],
                    ),
                  ),
                if (rest.isNotEmpty) ...[
                  SectionHeader(l.paymentHistory),
                  for (final p in rest)
                    PaymentRow(
                      payment: p,
                      now: now,
                      actions: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => runGuarded(
                            context,
                            () => repo.setStatus(p.id, PaymentStatus.pending),
                            success: l.paymentUpdated,
                          ),
                          child: Text(l.markPending),
                        ),
                      ),
                    ),
                ],
                if (demo) ...[
                  SectionHeader(l.smsLog),
                  DemoBanner(text: l.smsMockNote),
                  const SizedBox(height: AppSpacing.sm),
                  LoadingButton(
                    key: const Key('run-reminders'),
                    label: l.runReminders,
                    icon: Icons.sms_rounded,
                    onPressed: () async {
                      try {
                        final r = await repo.runReminderJob(ref.read(clockProvider)());
                        if (context.mounted) showAppSnack(context, l.remindersReport(r.sent, r.skipped));
                      } catch (e) {
                        if (context.mounted) showAppSnack(context, errorText(context, e), error: true);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _SmsLog(),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _charge(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final amount = TextEditingController(text: '80');
    DateTime due = ref.read(clockProvider)().add(const Duration(days: 10));
    final ok = await showAdaptiveSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.chargeGroup, style: Theme.of(context).textTheme.titleLarge),
              Text(l.chargeGroupHint, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: InputDecoration(labelText: l.amountLabel),
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_rounded),
                title: Text(l.dueOn(Fmt.of(context).dayMonth(due))),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: due,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => due = d);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              LoadingButton(label: l.confirm, onPressed: () => Navigator.pop(context, true)),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final n = await ref
          .read(paymentsRepositoryProvider)
          .chargeGroup(groupId: groupId, amount: num.tryParse(amount.text) ?? 0, dueDate: due);
      if (context.mounted) showAppSnack(context, l.chargeCreated(n));
    } catch (e) {
      if (context.mounted) showAppSnack(context, errorText(context, e), error: true);
    }
  }

  Future<void> _plan(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final amount = TextEditingController(text: '80');
    final day = TextEditingController(text: '1');
    final ok = await showAdaptiveSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.recurringPlans, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.amountLabel),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: day,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.dayOfMonthLabel),
            ),
            const SizedBox(height: AppSpacing.md),
            LoadingButton(label: l.createPlan, onPressed: () => Navigator.pop(context, true)),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    await runGuarded(
      context,
      () => ref
          .read(paymentsRepositoryProvider)
          .createPlan(
            groupId: groupId,
            amount: num.tryParse(amount.text) ?? 0,
            dayOfMonth: int.tryParse(day.text) ?? 0,
          ),
      success: l.paymentUpdated,
    );
  }
}

class _SmsLog extends ConsumerWidget {
  const _SmsLog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(smsLogProvider).value ?? const <SmsLogEntry>[];
    if (log.isEmpty) return const SizedBox.shrink();
    final f = Fmt.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (final e in log.take(10))
            ListTile(
              key: Key('sms-${e.id}'),
              leading: Icon(
                e.status == 'sent'
                    ? Icons.mark_chat_read_rounded
                    : (e.status == 'failed' ? Icons.error_rounded : Icons.skip_next_rounded),
                color: e.status == 'sent' ? AppColors.success : AppColors.warning,
              ),
              title: Text(e.text, style: Theme.of(context).textTheme.bodySmall),
              subtitle: Text('${e.kind.toUpperCase()} · ${e.maskedPhone} · ${e.status} · ${f.time(e.at)}'),
            ),
        ],
      ),
    );
  }
}
