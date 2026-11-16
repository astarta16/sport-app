import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../brain_academy/domain/scoring.dart';
import '../../brain_academy/presentation/student_v17_widgets.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../../groups/presentation/groups_providers.dart';
import '../domain/coach_contact.dart';
import '../domain/organization.dart';
import 'org_providers.dart';

/// Active organization with its branding (name + colour). Users with
/// several memberships can switch; the choice only changes what is shown.
class OrgSwitcherChip extends ConsumerWidget {
  const OrgSwitcherChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(myMembershipsProvider).value ?? const <OrgMembership>[];
    final active = ref.watch(activeOrgProvider);
    if (active == null) return const SizedBox.shrink();
    final cfg = ref.watch(orgConfigProvider(active)).value;
    final locale = Localizations.localeOf(context).languageCode;
    final name = cfg?.branding.nameFor(locale, fallback: active) ?? active;
    final color = Color(cfg?.branding.primaryColor ?? 0xFF1D4ED8);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: ActionChip(
        key: const Key('org-switcher'),
        avatar: CircleAvatar(backgroundColor: color, radius: 8),
        label: Text(name, overflow: TextOverflow.ellipsis),
        side: BorderSide(color: color.withValues(alpha: .5)),
        onPressed: memberships.length < 2 ? null : () => _pick(context, ref, memberships, active),
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, List<OrgMembership> ms, String active) async {
    final l = context.l10n;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(l.orgSwitchTitle, style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final m in ms)
              Consumer(
                builder: (context, ref, _) {
                  final cfg = ref.watch(orgConfigProvider(m.orgId)).value;
                  final locale = Localizations.localeOf(context).languageCode;
                  return ListTile(
                    key: Key('org-option-${m.orgId}'),
                    leading: CircleAvatar(backgroundColor: Color(cfg?.branding.primaryColor ?? 0xFF1D4ED8), radius: 10),
                    title: Text(cfg?.branding.nameFor(locale, fallback: m.orgId) ?? m.orgId),
                    trailing: m.orgId == active ? const Icon(Icons.check_rounded) : null,
                    onTap: () => Navigator.pop(context, m.orgId),
                  );
                },
              ),
          ],
        ),
      ),
    );
    if (chosen != null) ref.read(activeOrgProvider.notifier).select(chosen);
  }
}

/// Parent: a child asked to contact a coach. The parent opens the existing
/// parent–coach chat (phone numbers stay protected) and marks it done.
class ParentContactRequestsBanner extends ConsumerWidget {
  const ParentContactRequestsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final open = (ref.watch(parentContactRequestsProvider).value ?? const <CoachContactRequest>[])
        .where((r) => r.status == ContactRequestStatus.open)
        .toList();
    if (open.isEmpty) return const SizedBox.shrink();
    final children = {for (final c in ref.watch(myChildrenProvider).value ?? const <Child>[]) c.id: c};
    return Column(
      children: [
        for (final r in open)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: AppCard(
              key: Key('parent-contact-${r.id}'),
              color: AppColors.blue.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.contactRequestFromChild(
                      children[r.childId]?.firstName ?? '',
                      ref.watch(publicProfileProvider(r.coachId)).value?.firstName ?? '',
                    ),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(contactTopicLabel(context, r.topic), style: Theme.of(context).textTheme.bodySmall),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      FilledButton.tonalIcon(
                        key: Key('parent-contact-chat-${r.id}'),
                        onPressed: () => context.push(Routes.chat(r.groupId)),
                        icon: const Icon(Icons.chat_rounded),
                        label: Text(l.contactOpenChat),
                      ),
                      TextButton(
                        key: Key('parent-contact-done-${r.id}'),
                        onPressed: () =>
                            runGuarded(context, () => ref.read(coachContactRepositoryProvider).markHandled(r.id)),
                        child: Text(l.contactDone),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Guardian consent for the Brain Academy leaderboard of each organization
/// the child belongs to (only where the organization has enabled it).
class LeaderboardConsentSection extends ConsumerWidget {
  const LeaderboardConsentSection({super.key, required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final groups = ref.watch(groupsByIdProvider);
    final orgs = {for (final g in child.groupIds) ?groups[g]?.clubId}.toList()..sort();
    final enabled = [
      for (final o in orgs)
        if (ref.watch(orgConfigProvider(o)).value case final cfg? when cfg.leaderboardOn) cfg,
    ];
    if (enabled.isEmpty) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.leaderboardConsentTitle),
        Text(l.leaderboardConsentExplain, style: Theme.of(context).textTheme.bodySmall),
        for (final cfg in enabled)
          Builder(
            builder: (context) {
              final consent = ref.watch(leaderboardConsentProvider((cfg.orgId, child.id))).value;
              final granted = consent?.granted ?? false;
              final mode = consent?.mode ?? DisplayNameMode.pseudonym;
              Future<void> save(bool g, DisplayNameMode m) => runGuarded(
                context,
                () => ref.read(leaderboardRepositoryProvider).setConsent(cfg.orgId, child.id, granted: g, mode: m),
                success: g ? l.leaderboardConsentOn : l.leaderboardConsentOff,
              );
              return AppCard(
                key: Key('lb-consent-${cfg.orgId}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      key: Key('lb-consent-switch-${cfg.orgId}'),
                      contentPadding: EdgeInsets.zero,
                      value: granted,
                      title: Text(cfg.branding.nameFor(locale, fallback: cfg.orgId)),
                      subtitle: Text(granted ? (consent?.displayName ?? '') : l.leaderboardConsentOffHint),
                      onChanged: (v) => save(v, mode),
                    ),
                    if (granted)
                      SegmentedButton<DisplayNameMode>(
                        key: Key('lb-mode-${cfg.orgId}'),
                        segments: [
                          ButtonSegment(value: DisplayNameMode.pseudonym, label: Text(l.leaderboardModePseudonym)),
                          ButtonSegment(value: DisplayNameMode.firstNameInitial, label: Text(l.leaderboardModeInitial)),
                        ],
                        selected: {mode},
                        onSelectionChanged: (s) => save(true, s.first),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Whether [module] is enabled for the organization of [groupId]. Missing
/// configuration (legacy clubs) counts as the legacy defaults.
final moduleOnForGroupProvider = Provider.autoDispose.family<bool, (String, OrgModule)>((ref, k) {
  final g = ref.watch(groupsByIdProvider)[k.$1];
  if (g == null) return true;
  final cfg = ref.watch(orgConfigProvider(g.clubId)).value;
  return (cfg ?? OrgConfig.legacy(g.clubId)).isEnabled(k.$2);
});
