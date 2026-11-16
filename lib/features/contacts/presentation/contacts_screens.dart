import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../groups/presentation/groups_providers.dart';
import '../domain/contact.dart';

/// Scoped contacts of one group. Re-fetched when the user or the group
/// changes, so ended memberships / coach assignments drop out at once.
final groupContactsProvider = FutureProvider.autoDispose.family<List<GroupContact>, String>((ref, groupId) {
  ref.watch(currentUidProvider);
  // Group changes (members, coaches, status) refetch the projection.
  ref.watch(groupsByIdProvider.select((m) => m[groupId]));
  return ref.watch(contactsRepositoryProvider).groupContacts(groupId);
});

String relationLabel(BuildContext context, GuardianRelation r) {
  final l = context.l10n;
  return switch (r) {
    GuardianRelation.mother => l.relationMother,
    GuardianRelation.father => l.relationFather,
    GuardianRelation.guardian => l.relationGuardian,
    GuardianRelation.grandparent => l.relationGrandparent,
    GuardianRelation.other => l.relationOther,
  };
}

/// One contact with a call button. The call starts only on the user's tap.
class ContactCard extends StatelessWidget {
  const ContactCard({super.key, required this.contact, this.forChildId});

  final GroupContact contact;

  /// When set, the relation shown is the one to this child.
  final String? forChildId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final kids = forChildId == null ? contact.children : contact.children.where((c) => c.id == forChildId).toList();
    final relation = kids.map((c) => c.relation).whereType<GuardianRelation>().firstOrNull;
    final subtitle = contact.isCoach
        ? l.roleCoach
        : [
            if (relation != null) relationLabel(context, relation),
            if (forChildId == null && kids.isNotEmpty) l.contactParentOf(kids.map((c) => c.firstName).join(', ')),
          ].join(' · ');
    final phone = contact.phone;
    return AppCard(
      key: Key('contact-${contact.uid}'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: [
          InitialsAvatar(name: contact.name, size: 44),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name, style: t.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(
                  phone == null ? l.contactNoPhone : Validators.formatPhone(phone),
                  key: Key('contact-phone-${contact.uid}'),
                  style: t.bodyMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ),
          ),
          if (phone != null)
            IconButton.filledTonal(
              key: Key('call-${contact.uid}'),
              tooltip: l.contactCallName(contact.name),
              onPressed: () => callPhone(phone),
              icon: const Icon(Icons.call_rounded),
            ),
        ],
      ),
    );
  }
}

/// Coach: guardians of [childId] in [groupId] (roster, student details).
class GuardianContactsSection extends ConsumerWidget {
  const GuardianContactsSection({super.key, required this.groupId, required this.childId});

  final String groupId;
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(groupContactsProvider(groupId));
    return contacts.when(
      loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.sm), child: LinearProgressIndicator()),
      error: (e, _) =>
          ErrorView(error: e, compact: true, onRetry: () => ref.invalidate(groupContactsProvider(groupId))),
      data: (all) {
        final mine = all.where((c) => !c.isCoach && c.children.any((k) => k.id == childId)).toList();
        if (mine.isEmpty) return Text(context.l10n.contactsEmpty, style: Theme.of(context).textTheme.bodySmall);
        return Column(
          key: Key('guardians-$childId'),
          children: [
            for (final c in mine)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: ContactCard(contact: c, forChildId: childId),
              ),
          ],
        );
      },
    );
  }
}

/// `/group/:groupId/contacts[?childId=]` — coach: parents/guardians;
/// parent: the group's coach(es).
class GroupContactsScreen extends ConsumerWidget {
  const GroupContactsScreen({super.key, required this.groupId, this.childId});

  final String groupId;
  final String? childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(currentUserProvider);
    final group = ref.watch(groupsByIdProvider)[groupId];
    final isParent = me?.isParent ?? false;
    final contacts = ref.watch(groupContactsProvider(groupId));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          [isParent ? l.contactsCoachTitle : l.contactsParentsTitle, if (group != null) group.name].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: AsyncView<List<GroupContact>>(
        value: contacts,
        onRetry: () => ref.invalidate(groupContactsProvider(groupId)),
        data: (all) {
          final list = childId == null
              ? all
              : all.where((c) => c.isCoach || c.children.any((k) => k.id == childId)).toList();
          return ConstrainedContent(
            maxWidth: Breakpoints.readable,
            child: ListView(
              key: const Key('contacts-list'),
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                DemoBanner(text: isParent ? l.contactPrivacyParent : l.contactPrivacyCoach),
                const SizedBox(height: AppSpacing.sm),
                if (list.isEmpty) EmptyState(icon: Icons.contact_phone_outlined, title: l.contactsEmpty),
                for (final c in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: ContactCard(contact: c, forChildId: childId),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
