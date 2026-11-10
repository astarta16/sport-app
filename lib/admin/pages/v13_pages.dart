import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/language_selector.dart';
import '../../features/admin/domain/admin_models.dart';
import '../../features/authentication/presentation/session_providers.dart';
import '../../features/clubs/presentation/clubs_providers.dart';
import '../../features/payments/domain/payment_proof.dart';
import '../../features/payments/presentation/payment_proof_screens.dart';
import '../widgets.dart';
import 'admin_providers.dart';

final adminComplianceProvider = FutureProvider.autoDispose<List<GroupCompliance>>((ref) {
  ref.watch(currentUidProvider);
  ref.watch(adminGroupsProvider);
  return ref.watch(adminRepositoryProvider).compliance();
});

final adminAttendanceProvider = FutureProvider.autoDispose.family<List<GroupAttendanceRow>, DateTime>((ref, month) {
  ref.watch(currentUidProvider);
  return ref.watch(adminRepositoryProvider).attendanceReport(year: month.year, month: month.month);
});

final adminPlansProvider = StreamProvider.autoDispose<List<PlanOverview>>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(adminRepositoryProvider).watchPlans();
});

/// Certificate compliance — counts only, never documents or child names.
class CompliancePage extends ConsumerWidget {
  const CompliancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final clubs = ref.watch(clubsByIdProvider);
    Widget n(int v, Color c) => Text(
      '$v',
      style: TextStyle(color: v == 0 ? null : c, fontWeight: FontWeight.w800),
    );
    return AdminSection(
      title: l.adminNavCompliance,
      subtitle: l.adminComplianceNote,
      child: AsyncView<List<GroupCompliance>>(
        value: ref.watch(adminComplianceProvider),
        data: (rows) => AdminTable<GroupCompliance>(
          rows: rows,
          searchText: (r) => '${r.groupName} ${clubs[r.clubId]?.name ?? ''}',
          filters: [
            (l.adminFilterAll, (_) => true),
            (l.rosterFilterCertIssues, (r) => r.expired + r.missing + r.expiring > 0),
          ],
          columns: [
            AdminColumn(
              l.adminColName,
              (r) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.groupName,
                    key: Key('compliance-${r.groupId}'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(clubs[r.clubId]?.name ?? '', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              flex: 3,
              sortKey: (r) => r.groupName,
            ),
            AdminColumn(l.adminColValid, (r) => n(r.valid, AppColors.success), sortKey: (r) => r.valid),
            AdminColumn(l.adminColExpiring, (r) => n(r.expiring, AppColors.warning), sortKey: (r) => r.expiring),
            AdminColumn(l.adminColExpired, (r) => n(r.expired, AppColors.danger), sortKey: (r) => r.expired),
            AdminColumn(l.adminColMissing, (r) => n(r.missing, AppColors.danger), sortKey: (r) => r.missing),
          ],
        ),
      ),
    );
  }
}

class AttendanceReportPage extends ConsumerStatefulWidget {
  const AttendanceReportPage({super.key});

  @override
  ConsumerState<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends ConsumerState<AttendanceReportPage> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final now = ref.watch(clockProvider)();
    final clubs = ref.watch(clubsByIdProvider);
    return AdminSection(
      title: l.adminNavAttendance,
      subtitle: l.adminRosterNote,
      actions: [
        DropdownButton<DateTime>(
          key: const Key('admin-att-month'),
          value: _month,
          items: [
            for (var i = 0; i < 6; i++)
              DropdownMenuItem(
                value: DateTime(now.year, now.month - i),
                child: Text(f.monthYear(DateTime(now.year, now.month - i))),
              ),
          ],
          onChanged: (v) => setState(() => _month = v ?? _month),
        ),
      ],
      child: AsyncView<List<GroupAttendanceRow>>(
        value: ref.watch(adminAttendanceProvider(_month)),
        data: (rows) => AdminTable<GroupAttendanceRow>(
          rows: rows,
          searchText: (r) => '${r.groupName} ${clubs[r.clubId]?.name ?? ''}',
          columns: [
            AdminColumn(
              l.adminColName,
              (r) => Text(r.groupName, key: Key('att-report-${r.groupId}')),
              flex: 3,
              sortKey: (r) => r.groupName,
            ),
            AdminColumn(l.adminStatClubs, (r) => Text(clubs[r.clubId]?.name ?? ''), flex: 3),
            AdminColumn(l.adminColMembers, (r) => Text('${r.members}'), sortKey: (r) => r.members),
            AdminColumn(l.adminColSessions, (r) => Text('${r.sessions}'), sortKey: (r) => r.sessions),
            AdminColumn(
              l.adminColRate,
              (r) => Text(r.rate == null ? '—' : '${(r.rate! * 100).round()}%'),
              sortKey: (r) => r.rate ?? -1,
            ),
          ],
        ),
      ),
    );
  }
}

class PlansOversightPage extends ConsumerWidget {
  const PlansOversightPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    return AdminSection(
      title: l.adminNavPlans,
      child: AsyncView<List<PlanOverview>>(
        value: ref.watch(adminPlansProvider),
        data: (rows) => AdminTable<PlanOverview>(
          rows: rows,
          searchText: (p) => '${p.title} ${p.coachName} ${p.groupNames.join(' ')}',
          filters: [
            (l.adminFilterAll, (_) => true),
            (l.planStatusPublished, (p) => p.statusName == 'published'),
            (l.planStatusDraft, (p) => p.statusName == 'draft'),
          ],
          columns: [
            AdminColumn(
              l.planTitleLabel,
              (p) => Text(p.title, key: Key('admin-plan-${p.planId}')),
              flex: 3,
              sortKey: (p) => p.title,
            ),
            AdminColumn(l.adminColPlanType, (p) => Text(p.typeName), flex: 2),
            AdminColumn(l.adminColStatus, (p) => Text(p.statusName), flex: 2),
            AdminColumn(l.adminColGroups, (p) => Text(p.groupNames.join(', ')), flex: 3),
            AdminColumn(l.adminColCoach, (p) => Text(p.coachName), flex: 2),
            AdminColumn(l.planExercises, (p) => Text('${p.exercises}')),
            AdminColumn(l.planStart, (p) => Text(f.numericDate(p.startDate)), flex: 2, sortKey: (p) => p.startDate),
          ],
        ),
      ),
    );
  }
}

/// Club admins verify payment proofs for their clubs (receipts open via a
/// short-lived audited link).
class PaymentQueuePage extends ConsumerWidget {
  const PaymentQueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return AdminSection(
      title: l.adminNavPayments,
      subtitle: l.adminPaymentQueueNote,
      child: AsyncView<List<PaymentProof>>(
        value: ref.watch(reviewQueueProvider),
        data: (list) => list.isEmpty
            ? AppCard(
                child: EmptyState(compact: true, icon: Icons.task_alt_rounded, title: l.payReviewEmpty),
              )
            : Column(
                children: [
                  for (final p in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ProofReviewCard(proof: p),
                    ),
                ],
              ),
      ),
    );
  }
}

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AdminSection(
      title: l.adminNavSettings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(l.adminLanguage),
          const SizedBox(width: 480, child: LanguageSelector()),
        ],
      ),
    );
  }
}

/// Assign payment reviewers for a group (club admin / platform admin).
Future<void> showReviewersDialog(BuildContext context, WidgetRef ref, GroupOverview g) async {
  final l = context.l10n;
  final coaches = {for (final c in ref.read(adminCoachesProvider).value ?? const <CoachSummary>[]) c.id: c.fullName};
  final selected = {...g.group.paymentManagerIds};
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        key: const Key('reviewers-dialog'),
        title: Text(l.adminSetReviewers),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final id in g.group.coachIds)
                CheckboxListTile(
                  key: Key('reviewer-$id'),
                  value: selected.contains(id),
                  onChanged: (v) => setState(() => v == true ? selected.add(id) : selected.remove(id)),
                  title: Text(coaches[id] ?? id),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(
            key: const Key('reviewers-save'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.save),
          ),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  await runGuarded(
    context,
    () => ref.read(adminRepositoryProvider).setPaymentManagers(g.group.id, selected.toList()),
    success: l.adminSaved,
  );
}
