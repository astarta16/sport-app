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
import '../../attendance/presentation/attendance_providers.dart';
import '../../authentication/domain/access_policy.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../clubs/domain/club.dart';
import '../../clubs/presentation/clubs_providers.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../medical_certificates/domain/medical_certificate.dart';
import '../../medical_certificates/presentation/certificates_providers.dart';
import '../../sports/presentation/sports_providers.dart';
import '../../trainings/domain/training.dart';
import '../../trainings/presentation/training_widgets.dart';
import '../../trainings/presentation/trainings_providers.dart';
import '../domain/child.dart';
import '../../sports/presentation/sport_label.dart';
import '../../organizations/presentation/org_widgets.dart';
import '../../organizations/presentation/feature_gate.dart';
import '../../organizations/domain/organization.dart';
import 'children_providers.dart';

class ChildProfileScreen extends ConsumerWidget {
  const ChildProfileScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final child = ref.watch(childProvider(childId));
    return Scaffold(
      appBar: AppBar(title: Text(l.childProfile)),
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: AsyncView<Child?>(
          value: child,
          data: (c) => c == null ? EmptyState(icon: Icons.search_off_rounded, title: l.errorNotFound) : _Body(child: c),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final t = Theme.of(context).textTheme;
    final now = ref.watch(clockProvider)();
    final user = ref.watch(currentUserProvider);
    final canEdit = user != null && AccessPolicy.canEditChild(user, child);
    final sports = ref.watch(sportsByIdProvider);
    final groups = ref.watch(groupsByIdProvider);
    final clubs = ref.watch(clubsByIdProvider);
    final certs = ref.watch(childCertificatesProvider(child.id)).value ?? const <MedicalCertificate>[];
    final status = StatusVisual.certificate(context, CertificatePolicy.childStatus(certs, now));
    final requests = (ref.watch(myMembershipRequestsProvider).value ?? const <MembershipRequest>[])
        .where((r) => r.childId == child.id && r.status == RequestStatus.pending)
        .toList();
    final history =
        (ref.watch(myTrainingsProvider).value ?? const <Training>[])
            .where((tr) => child.groupIds.contains(tr.groupId) && tr.startAt.isBefore(now))
            .toList()
          ..sort((a, b) => b.startAt.compareTo(a.startAt));

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              InitialsAvatar(name: child.fullName, size: 64),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.fullName, style: t.titleLarge),
                    Text('${l.yearsOld(child.ageOn(now))} · ${f.fullDate(child.birthDate)}', style: t.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (canEdit) ...[
          const SizedBox(height: AppSpacing.sm),
          _ProgressTile(childId: child.id),
          const SizedBox(height: AppSpacing.xs),
          if (ref.watch(featureOnProvider(OrgModule.trainingPlans)))
            AppCard(
              key: const Key('child-plans-tile'),
              padding: const EdgeInsets.symmetric(vertical: 2),
              onTap: () => context.push('${Routes.plans}?childId=${child.id}'),
              child: ListTile(
                leading: const Icon(Icons.assignment_rounded, color: AppColors.blue),
                title: Text(l.plansTitle),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
        ],
        SectionHeader(l.sportsLabel),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in child.sportIds)
              Chip(
                avatar: Icon(SportVisuals.icon(s), size: 18, color: SportVisuals.color(s)),
                label: Text(sports[s]?.label(context) ?? s),
              ),
          ],
        ),
        SectionHeader(l.groupsLabel),
        if (child.groupIds.isEmpty && requests.isEmpty)
          AppCard(
            child: EmptyState(
              compact: true,
              icon: Icons.groups_outlined,
              title: l.notInGroup,
              actionLabel: l.findClub,
              onAction: () => context.go(Routes.parentMap),
            ),
          ),
        for (final gid in child.groupIds)
          if (groups[gid] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  leading: SportBadge(sportKey: groups[gid]!.sportId, size: 40),
                  title: Text(groups[gid]!.name),
                  subtitle: Text(clubs[groups[gid]!.clubId]?.name ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: Key('contact-coach-$gid'),
                        tooltip: l.contactCoachAction,
                        onPressed: () => context.push('/group/$gid/contacts'),
                        icon: const Icon(Icons.contact_phone_rounded),
                      ),
                      if (canEdit)
                        IconButton(
                          key: Key('leave-$gid'),
                          tooltip: l.leaveGroup,
                          icon: const Icon(Icons.logout_rounded),
                          onPressed: () async {
                            final ok = await confirmDialog(
                              context,
                              title: l.leaveGroup,
                              message: l.leaveGroupConfirm(child.firstName, groups[gid]!.name),
                              confirmLabel: l.leaveGroup,
                              destructive: true,
                            );
                            if (ok && context.mounted) {
                              await runGuarded(
                                context,
                                () => ref.read(groupsRepositoryProvider).leaveGroup(groupId: gid, childId: child.id),
                                success: l.leftGroup,
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
        if (canEdit)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('join-by-code'),
              onPressed: () => showJoinByCodeDialog(context, ref, child),
              icon: const Icon(Icons.vpn_key_rounded),
              label: Text(l.joinGroup),
            ),
          ),
        for (final r in requests)
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: ListTile(
              leading: const Icon(Icons.hourglass_top_rounded),
              title: Text(clubs[r.clubId]?.name ?? ''),
              trailing: StatusPill(label: l.requestPending, color: AppColors.warning, dense: true),
            ),
          ),
        if (ref.watch(featureOnProvider(OrgModule.medicalCertificates))) SectionHeader(l.medicalStatus),
        if (ref.watch(featureOnProvider(OrgModule.medicalCertificates)))
          AppCard(
            onTap: () => context.push(Routes.certificates(child.id)),
            child: Row(
              children: [
                Icon(status.icon, color: status.color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(l.certificatesTitle, style: t.titleSmall)),
                StatusPill.of(status, dense: true),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        if (canEdit) LeaderboardConsentSection(child: child),
        if (canEdit) ...[
          SectionHeader(l.privacyTitle),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                SwitchListTile(
                  key: const Key('media-consent'),
                  value: child.photoConsent,
                  title: Text(l.photoConsentLabel),
                  subtitle: Text(
                    child.mediaConsentAt == null
                        ? l.photoConsentHelp
                        : '${l.photoConsentHelp}\n${Fmt.of(context).fullDate(child.mediaConsentAt!)}',
                  ),
                  onChanged: (v) =>
                      runGuarded(context, () => ref.read(childrenRepositoryProvider).setMediaConsent(child.id, v)),
                ),
                ListTile(
                  enabled: false,
                  leading: const Icon(Icons.phone_iphone_rounded),
                  title: Text(l.ownAccountTitle),
                  subtitle: Text(l.ownAccountDisabled),
                  trailing: StatusPill(label: l.soon, color: AppColors.neutral, dense: true),
                ),
              ],
            ),
          ),
        ],
        SectionHeader(l.trainingHistory),
        if (history.isEmpty)
          AppCard(
            child: EmptyState(compact: true, icon: Icons.history_rounded, title: l.noTrainingsDay),
          )
        else
          for (final tr in history.take(8))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: TrainingTile(training: tr, group: groups[tr.groupId]),
            ),
        if (canEdit) ...[
          const SizedBox(height: AppSpacing.lg),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                title: l.removeChild,
                message: l.removeChildConfirm(child.firstName),
                confirmLabel: l.delete,
                destructive: true,
              );
              if (ok && context.mounted) {
                final done = await runGuarded(
                  context,
                  () => ref.read(childrenRepositoryProvider).removeChild(child.id),
                );
                if (done && context.mounted) context.popOrHome();
              }
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(l.removeChild),
          ),
        ],
      ],
    );
  }
}

class _ProgressTile extends ConsumerWidget {
  const _ProgressTile({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final stats = ref.watch(childStatsProvider(childId)).value;
    final month = stats?.monthOf(ref.watch(clockProvider)());
    return AppCard(
      key: const Key('child-progress-tile'),
      onTap: () => context.push(Routes.progress(childId)),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, color: AppColors.blue),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.progressTitle, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  [
                    if (stats != null) '${l.progressTrainings}: ${stats.totalPresent}',
                    if (month?.rate != null) l.attendanceTileValue((month!.rate! * 100).round()),
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

/// Parent enters a group code for this child → request the coach approves.
Future<void> showJoinByCodeDialog(BuildContext context, WidgetRef ref, Child child) async {
  final l = context.l10n;
  final code = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.joinGroup),
      content: TextField(
        key: const Key('join-code-field'),
        controller: code,
        autofocus: true,
        maxLength: 6,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(labelText: l.joinGroupCodeLabel),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(
          key: const Key('join-code-submit'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.send),
        ),
      ],
    ),
  );
  final text = code.text;
  // Controllers of dialogs are left to GC: disposing right after pop races
  // the exit animation, which still builds the TextField.
  if (ok != true || !context.mounted) return;
  try {
    final name = await ref.read(groupsRepositoryProvider).joinByCode(code: text, childId: child.id);
    if (context.mounted) showAppSnack(context, l.joinGroupSent(name));
  } catch (e) {
    if (context.mounted) showAppSnack(context, errorText(context, e), error: true);
  }
}
