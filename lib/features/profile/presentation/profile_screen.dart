import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config.dart';
import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/services/network_status.dart';
import '../../media/domain/media_post.dart';
import '../../media/presentation/media_providers.dart';
import '../../media/presentation/media_screens.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../../clubs/presentation/clubs_providers.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../sports/presentation/sport_label.dart';
import '../../organizations/presentation/feature_gate.dart';
import '../../organizations/domain/organization.dart';
import '../../sports/presentation/sports_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider);
    final demo = ref.watch(appModeProvider) == AppMode.demo;
    final now = ref.watch(clockProvider)();
    if (user == null) return const Scaffold(body: SkeletonList());
    final children = ref.watch(myChildrenProvider).value ?? const <Child>[];
    final groups = ref.watch(myGroupsProvider).value ?? const [];
    final clubs = ref.watch(clubsByIdProvider);
    final sports = ref.watch(sportsByIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.navProfile)),
      body: LayoutBuilder(
        builder: (context, c) {
          final left = <Widget>[
            AppCard(
              gradient: AppColors.nightGradient,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  UserAvatar(name: user.fullName, photoPath: user.photoPath, size: 64),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName, style: t.titleLarge?.copyWith(color: Colors.white)),
                        Text(Validators.formatPhone(user.phone), style: t.bodyMedium?.copyWith(color: Colors.white70)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: [
                            StatusPill(
                              label: user.isCoach ? l.roleCoach : l.roleParent,
                              color: AppColors.volt,
                              dense: true,
                            ),
                            if (user.isApprovedCoach)
                              StatusPill(
                                label: l.approvedCoach,
                                color: AppColors.volt,
                                icon: Icons.verified_rounded,
                                dense: true,
                              ),
                            if (demo) StatusPill(label: l.modeDemo, color: Colors.white, dense: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l.editProfile,
                    onPressed: () => _editProfile(context, ref, user.firstName, user.lastName),
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            if (user.isParent) ...[
              SectionHeader(l.myChildren, actionLabel: l.addChild, onAction: () => context.push(Routes.newChild)),
              if (children.isEmpty)
                AppCard(
                  child: EmptyState(compact: true, icon: Icons.child_care_rounded, title: l.noChildrenTitle),
                )
              else
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    children: [
                      for (final c in children)
                        ListTile(
                          key: Key('profile-child-${c.id}'),
                          leading: InitialsAvatar(name: c.fullName, size: 42),
                          title: Text(c.fullName, style: t.titleSmall),
                          subtitle: Text(
                            '${l.yearsOld(c.ageOn(now))} · ${c.sportIds.map((s) => sports[s]?.label(context) ?? s).join(', ')}',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push(Routes.child(c.id)),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              if (ref.watch(featureOnProvider(OrgModule.payments)))
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet_rounded),
                    title: Text(l.paymentsTitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.payments),
                  ),
                ),
            ],
            if (user.isCoach) ...[
              SectionHeader(l.groupsLabel, actionLabel: l.newGroup, onAction: () => context.push(Routes.newGroup)),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    for (final g in groups)
                      ListTile(
                        leading: SportBadge(sportKey: g.sportId, size: 40),
                        title: Text(g.name),
                        subtitle: Text('${clubs[g.clubId]?.name ?? ''} · ${l.groupMembers(g.memberChildIds.length)}'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(Routes.roster(g.id)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (ref.watch(featureOnProvider(OrgModule.trainingPlans)))
                AppCard(
                  key: const Key('profile-plans'),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  onTap: () => context.push(Routes.plans),
                  child: ListTile(
                    leading: const Icon(Icons.assignment_rounded),
                    title: Text(l.plansTitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              if (ref.watch(featureOnProvider(OrgModule.media))) ...[
                SectionHeader(l.mediaTitle, actionLabel: l.addMedia, onAction: () => context.push(Routes.newMedia)),
                _CoachMedia(coachId: user.id),
              ],
            ],
          ];
          final right = <Widget>[
            SectionHeader(l.settingsTitle),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: Text(l.notificationSettings),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.notificationSettings),
                  ),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: Text(l.settingsTitle),
                    subtitle: Text('${l.themeLabel} · ${l.languageLabel}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.settings),
                  ),
                  ListTile(
                    key: const Key('open-privacy'),
                    leading: const Icon(Icons.shield_outlined),
                    title: Text(l.privacyTitle),
                    subtitle: Text(l.privacyBody, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.privacy),
                  ),
                  ListTile(
                    key: const Key('open-account'),
                    leading: const Icon(Icons.manage_accounts_rounded),
                    title: Text(l.accountTitle),
                    subtitle: Text(
                      '${l.consentsTitle} · ${l.dataExport} · ${l.deleteAccount}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.account),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (demo)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _DemoSwitcher(currentUid: user.id),
              ),
            OutlinedButton.icon(
              key: const Key('sign-out'),
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              icon: const Icon(Icons.logout_rounded),
              label: Text(l.signOut),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(child: Text(l.aboutVersion(AppConfig.version, AppConfig.environment.name), style: t.labelSmall)),
          ];
          const pad = EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl);
          if (c.maxWidth < Breakpoints.expanded) {
            return ConstrainedContent(
              child: ListView(padding: pad, children: [...left, ...right]),
            );
          }
          return SingleChildScrollView(
            padding: pad,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Breakpoints.dashboard),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: left),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      flex: 2,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref, String first, String last) async {
    final l = context.l10n;
    final f = TextEditingController(text: first);
    final s = TextEditingController(text: last);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.editProfile),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: f,
              decoration: InputDecoration(labelText: l.firstName),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: s,
              decoration: InputDecoration(labelText: l.lastName),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.save)),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await runGuarded(
        context,
        () => ref.read(authRepositoryProvider).updateProfile(firstName: f.text, lastName: s.text),
        success: l.childSaved,
      );
    }
  }
}

class _DemoSwitcher extends ConsumerWidget {
  const _DemoSwitcher({required this.currentUid});

  final String currentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final accounts = ref.watch(authRepositoryProvider).demoAccounts.where((a) => a.uid != currentUid).toList();
    return AppCard(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(l.switchDemoAccount, style: Theme.of(context).textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (ref.watch(demoBackendProvider) case final db?)
            SwitchListTile(
              key: const Key('demo-offline'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.demoOffline),
              subtitle: Text(l.demoOfflineHint),
              value: ref.watch(networkOnlineProvider).value == false,
              onChanged: db.setOffline,
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in accounts)
                ActionChip(
                  key: Key('switch-${a.uid}'),
                  avatar: Icon(
                    a.uid == 'coach-4'
                        ? Icons.hourglass_top_rounded
                        : (a.role.name == 'coach' ? Icons.sports_rounded : Icons.family_restroom_rounded),
                    size: 18,
                  ),
                  label: Text(a.label),
                  onPressed: () => ref.read(authRepositoryProvider).signInAsDemo(a.uid),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoachMedia extends ConsumerWidget {
  const _CoachMedia({required this.coachId});

  final String coachId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final posts = ref.watch(coachMediaProvider(coachId)).value ?? const <MediaPost>[];
    if (posts.isEmpty) {
      return AppCard(
        child: EmptyState(compact: true, icon: Icons.photo_library_outlined, title: l.mediaEmpty),
      );
    }
    return GridView.count(
      key: const Key('coach-media-grid'),
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: [for (final p in posts.take(9)) MediaPostTile(post: p)],
    );
  }
}
