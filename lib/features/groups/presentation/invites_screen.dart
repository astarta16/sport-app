import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../domain/group.dart';
import 'groups_providers.dart';

/// Parent's group invitations (v1.1 §2). On accept the parent chooses which
/// of their children the invitation is for — picking an existing child
/// prevents a duplicate record. Nothing is linked automatically.
class InvitesScreen extends ConsumerWidget {
  const InvitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final invites = ref.watch(myInvitesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.invitesTitle)),
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: AsyncView<List<GroupInvite>>(
          value: invites,
          data: (list) {
            final open = list.where((i) => i.status == InviteStatus.sent).toList();
            if (open.isEmpty) return EmptyState(icon: Icons.mark_email_read_outlined, title: l.invitesEmpty);
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [for (final i in open) _InviteCard(invite: i)],
            );
          },
        ),
      ),
    );
  }
}

class _InviteCard extends ConsumerWidget {
  const _InviteCard({required this.invite});

  final GroupInvite invite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        key: Key('invite-card-${invite.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.group_add_rounded, color: AppColors.blue),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l.inviteFrom(invite.childName, invite.groupName),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.xs,
              children: [
                TextButton(
                  key: Key('invite-decline-${invite.id}'),
                  onPressed: () => runGuarded(
                    context,
                    () => ref.read(groupsRepositoryProvider).respondInvite(invite.id, accept: false),
                    success: l.inviteDeclined,
                  ),
                  child: Text(l.decline),
                ),
                FilledButton(
                  key: Key('invite-accept-${invite.id}'),
                  onPressed: () => _accept(context, ref),
                  child: Text(l.accept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final mine = ref.read(myChildrenProvider).value ?? const <Child>[];
    // Suggest children with the same first name first, but always let the
    // parent decide explicitly.
    final sorted = [...mine]
      ..sort(
        (a, b) =>
            (a.firstName == invite.childFirstName ? 0 : 1).compareTo(b.firstName == invite.childFirstName ? 0 : 1),
      );
    String? choice =
        sorted.where((c) => c.firstName == invite.childFirstName).firstOrNull?.id ??
        (invite.childId == null ? sorted.firstOrNull?.id : '');
    var consent = false;
    final result = await showDialog<({String? linked, bool consent})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          key: const Key('invite-accept-dialog'),
          title: Text(l.inviteLinkTitle),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.inviteLinkHint, style: Theme.of(context).textTheme.bodySmall),
                  RadioGroup<String>(
                    groupValue: choice,
                    onChanged: (v) => setState(() => choice = v),
                    child: Column(
                      children: [
                        for (final c in sorted)
                          RadioListTile<String>(
                            key: Key('link-${c.id}'),
                            value: c.id,
                            title: Text(c.fullName),
                            subtitle: Text(Fmt.of(context).fullDate(c.birthDate)),
                          ),
                        if (invite.childId != null)
                          RadioListTile<String>(
                            key: const Key('link-new'),
                            value: '',
                            title: Text(l.inviteAsNew(invite.childName)),
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  CheckboxListTile(
                    key: const Key('invite-media-consent'),
                    value: consent,
                    onChanged: (v) => setState(() => consent = v ?? false),
                    title: Text(l.inviteMediaConsent),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
            FilledButton(
              key: const Key('invite-confirm'),
              onPressed: choice == null ? null : () => Navigator.pop(context, (linked: choice, consent: consent)),
              child: Text(l.accept),
            ),
          ],
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    await runGuarded(
      context,
      () => ref
          .read(groupsRepositoryProvider)
          .respondInvite(
            invite.id,
            accept: true,
            linkedChildId: (result.linked ?? '').isEmpty ? null : result.linked,
            mediaConsent: result.consent,
          ),
      success: l.inviteAccepted,
    );
  }
}
