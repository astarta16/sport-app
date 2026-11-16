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
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../medical_certificates/domain/medical_certificate.dart';
import '../../medical_certificates/presentation/certificates_providers.dart';
import 'coach_home_screen.dart';
import 'group_management.dart';
import '../../organizations/presentation/org_widgets.dart';
import '../../organizations/domain/organization.dart';
import '../../contacts/presentation/contacts_screens.dart';

/// Group roster with certificate status, parents (phone visible to the
/// group's coach only) and member management.
class GroupRosterScreen extends ConsumerWidget {
  const GroupRosterScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final group = ref.watch(groupsByIdProvider)[groupId];
    final members = ref.watch(groupMembersProvider(groupId));
    final now = ref.watch(clockProvider)();
    final certs =
        ref.watch(certificatesForChildrenProvider(childrenKey(group?.memberChildIds ?? const []))).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: Text(group?.name ?? l.roster),
        actions: [
          if (ref.watch(moduleOnForGroupProvider((groupId, OrgModule.coachChallenges))))
            IconButton(
              key: const Key('group-challenges'),
              tooltip: l.coachChallengesTitle,
              onPressed: () => context.push('/group/$groupId/challenges'),
              icon: const Icon(Icons.psychology_rounded),
            ),
        ],
      ),
      body: AsyncView<List<Child>>(
        value: members,
        onRetry: () => ref.invalidate(groupMembersProvider(groupId)),
        data: (list) {
          final header = GroupManagementHeader(groupId: groupId);
          if (list.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                header,
                EmptyState(icon: Icons.group_off_rounded, title: l.roster, body: l.noGroupsInClub),
              ],
            );
          }
          Widget card(int i) {
            final c = list[i];
            final mine = certs.where((x) => x.childId == c.id).toList();
            final status = CertificatePolicy.childStatus(mine, now);
            return AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: Key('roster-${c.id}'),
                  leading: InitialsAvatar(name: c.fullName, size: 40),
                  title: Text(c.fullName, style: Theme.of(context).textTheme.titleSmall),
                  subtitle: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(l.yearsOld(c.ageOn(now))),
                      if (!c.photoConsent) const Icon(Icons.no_photography_rounded, size: 16, color: AppColors.warning),
                    ],
                  ),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: StatusPill.of(StatusVisual.certificate(context, status), dense: true),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                  children: [
                    if (mine.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Icon(Icons.description_rounded),
                            Text(l.validUntil(Fmt.of(context).numericDate(mine.first.validUntil))),
                            TextButton(
                              onPressed: () => context.push(Routes.certificates(c.id)),
                              child: Text(l.viewCertificate),
                            ),
                          ],
                        ),
                      ),
                    GuardianContactsSection(groupId: groupId, childId: c.id),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: AppSpacing.xs,
                      children: [
                        TextButton.icon(
                          key: Key('roster-profile-${c.id}'),
                          onPressed: () => context.push('/student/${c.id}'),
                          icon: const Icon(Icons.badge_rounded),
                          label: Text(l.studentProfileOpen),
                        ),
                        TextButton.icon(
                          key: Key('roster-progress-${c.id}'),
                          onPressed: () => context.push(Routes.progress(c.id)),
                          icon: const Icon(Icons.insights_rounded),
                          label: Text(l.progressShort),
                        ),
                        TextButton.icon(
                          key: Key('roster-remove-${c.id}'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                          onPressed: () async {
                            final ok = await confirmDialog(
                              context,
                              title: l.removeFromGroup,
                              message: l.removeFromGroupConfirm(c.fullName),
                              confirmLabel: l.removeFromGroup,
                              destructive: true,
                            );
                            if (ok && context.mounted) {
                              await runGuarded(
                                context,
                                () => ref.read(groupsRepositoryProvider).removeMember(groupId, c.id),
                              );
                            }
                          },
                          icon: const Icon(Icons.person_remove_rounded),
                          label: Text(l.removeFromGroup),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          // Phone: one column. Tablet: cards in a responsive grid.
          return LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth < Breakpoints.medium) {
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: list.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, i) => i == 0 ? header : card(i - 1),
                );
              }
              return SingleChildScrollView(
                key: const Key('roster-grid'),
                padding: EdgeInsets.all(context.pagePadding),
                child: ConstrainedContent(
                  maxWidth: Breakpoints.dashboard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const SizedBox(height: AppSpacing.sm),
                      ResponsiveGrid(
                        minItemWidth: 340,
                        maxColumns: 3,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [for (var i = 0; i < list.length; i++) card(i)],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Re-exported for the roster preview on the coach home.
typedef CoachRosterRow = RosterRow;
