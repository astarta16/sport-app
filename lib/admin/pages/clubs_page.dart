import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../features/admin/domain/admin_models.dart';
import '../../features/authentication/presentation/session_providers.dart';
import '../../features/clubs/domain/club.dart';
import '../../features/clubs/presentation/clubs_providers.dart';
import '../../features/sports/domain/sport.dart';
import '../widgets.dart';
import 'admin_providers.dart';
import 'v18_pages.dart';

/// Clubs: platform admins create/archive; club admins edit their own clubs.
class ClubsPage extends ConsumerWidget {
  const ClubsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(currentUserProvider);
    final clubs = ref.watch(adminClubsProvider);
    return AdminSection(
      title: l.adminNavClubs,
      actions: [
        if (me?.isPlatformAdmin ?? false)
          FilledButton.icon(
            key: const Key('admin-new-club'),
            // v1.9.1: one way to create an organization — the provisioning
            // wizard (configuration, package and administrator included).
            onPressed: () => showProvisionDialog(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.adminNewClub),
          ),
      ],
      child: AsyncView<List<ClubOverview>>(
        value: clubs,
        data: (list) => AdminTable<ClubOverview>(
          rows: list,
          searchText: (c) => '${c.club.name} ${c.club.address}',
          filters: [(l.adminFilterAll, (_) => true), (l.adminArchived, (c) => c.club.archived)],
          columns: [
            AdminColumn(
              l.adminColName,
              (c) => Text(
                c.club.name,
                key: Key('club-row-${c.club.id}'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              flex: 3,
              sortKey: (c) => c.club.name,
            ),
            AdminColumn(l.adminColAddress, (c) => Text(c.club.address), flex: 3),
            AdminColumn(l.adminColGroups, (c) => Text('${c.groups}'), sortKey: (c) => c.groups),
            AdminColumn(l.adminColMembers, (c) => Text('${c.members}'), sortKey: (c) => c.members),
            AdminColumn(l.adminStatCoaches, (c) => Text('${c.coaches}')),
            AdminColumn(
              l.adminColStatus,
              (c) => Align(
                alignment: Alignment.centerLeft,
                child: c.club.archived
                    ? StatusPill(label: l.adminArchived, color: AppColors.neutral, dense: true)
                    : const SizedBox.shrink(),
              ),
            ),
            AdminColumn(
              l.adminColActions,
              (c) => Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    key: Key('edit-club-${c.club.id}'),
                    tooltip: l.adminEditClub,
                    onPressed: () => showClubDialog(context, ref, club: c.club),
                    icon: const Icon(Icons.edit_rounded),
                  ),
                  if (me?.isPlatformAdmin ?? false)
                    IconButton(
                      key: Key('archive-club-${c.club.id}'),
                      tooltip: c.club.archived ? l.adminRestore : l.adminArchive,
                      onPressed: () async {
                        final ok = await confirmDialog(
                          context,
                          title: c.club.archived ? l.adminRestore : l.adminArchive,
                          message: c.club.name,
                          confirmLabel: c.club.archived ? l.adminRestore : l.adminArchive,
                          destructive: !c.club.archived,
                        );
                        if (ok && context.mounted) {
                          await runGuarded(
                            context,
                            () => ref.read(adminRepositoryProvider).archiveClub(c.club.id, archived: !c.club.archived),
                            success: l.adminSaved,
                          );
                        }
                      },
                      icon: Icon(c.club.archived ? Icons.unarchive_rounded : Icons.archive_rounded),
                    ),
                ],
              ),
              flex: 2,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showClubDialog(BuildContext context, WidgetRef ref, {Club? club}) async {
  final l = context.l10n;
  final name = TextEditingController(text: club?.name);
  final address = TextEditingController(text: club?.address);
  final phone = TextEditingController(text: club?.phone);
  final desc = TextEditingController(text: club?.description);
  final lat = TextEditingController(text: '${club?.location.latitude ?? 41.7151}');
  final lng = TextEditingController(text: '${club?.location.longitude ?? 44.8271}');
  final sports = <String>{...?club?.sportIds};
  final all = await ref.read(sportsRepositoryProvider).sports();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        key: const Key('club-dialog'),
        title: Text(club == null ? l.adminNewClub : l.adminEditClub),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('club-name'),
                  controller: name,
                  decoration: InputDecoration(labelText: l.adminColName),
                ),
                TextField(
                  key: const Key('club-address'),
                  controller: address,
                  decoration: InputDecoration(labelText: l.adminColAddress),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: lat,
                        decoration: InputDecoration(labelText: l.adminLat),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: lng,
                        decoration: InputDecoration(labelText: l.adminLng),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: phone,
                  decoration: InputDecoration(labelText: l.adminPhone),
                ),
                TextField(
                  controller: desc,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: l.adminDescription),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final Sport s in all)
                      FilterChip(
                        key: Key('club-sport-${s.id}'),
                        label: Text(s.name),
                        selected: sports.contains(s.id),
                        onSelected: (v) => setState(() => v ? sports.add(s.id) : sports.remove(s.id)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          FilledButton(
            key: const Key('club-save'),
            onPressed: () async {
              final draft = ClubDraft(
                name: name.text,
                address: address.text,
                lat: double.tryParse(lat.text) ?? 0,
                lng: double.tryParse(lng.text) ?? 0,
                sportIds: sports.toList(),
                phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
                description: desc.text.trim().isEmpty ? null : desc.text.trim(),
              );
              final ok = await runGuarded(
                context,
                () => ref.read(adminRepositoryProvider).upsertClub(draft, clubId: club?.id),
                success: l.adminSaved,
              );
              if (ok) ref.invalidate(clubsProvider);
              if (ok && context.mounted) Navigator.pop(context);
            },
            child: Text(l.save),
          ),
        ],
      ),
    ),
  );
  // Controllers of dialogs are left to GC: disposing right after pop races
  // the exit animation, which still builds the TextField.
}
