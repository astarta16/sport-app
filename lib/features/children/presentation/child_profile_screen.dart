import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
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
      body: AsyncView<Child?>(
        value: child,
        data: (c) => c == null ? EmptyState(icon: Icons.search_off_rounded, title: l.errorNotFound) : _Body(child: c),
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
        SectionHeader(l.sportsLabel),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in child.sportIds)
              Chip(
                avatar: Icon(SportVisuals.icon(s), size: 18, color: SportVisuals.color(s)),
                label: Text(sports[s]?.name ?? s),
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
                ),
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
        SectionHeader(l.medicalStatus),
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
        if (canEdit) ...[
          SectionHeader(l.privacyTitle),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                SwitchListTile(
                  value: child.photoConsent,
                  title: Text(l.photoConsentLabel),
                  subtitle: Text(l.photoConsentHelp),
                  onChanged: (v) => runGuarded(
                    context,
                    () => ref.read(childrenRepositoryProvider).updateChild(child.copyWith(photoConsent: v)),
                  ),
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
                if (done && context.mounted) context.pop();
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
