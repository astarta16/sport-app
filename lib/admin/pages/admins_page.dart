import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/app_widgets.dart';
import '../../features/admin/domain/admin_models.dart';
import '../../features/authentication/domain/app_user.dart';
import '../../features/authentication/presentation/session_providers.dart';
import '../../features/clubs/presentation/clubs_providers.dart';
import '../widgets.dart';
import 'admin_providers.dart';

/// Platform admins manage admin roles (custom claims, set server-side).
class AdminsPage extends ConsumerWidget {
  const AdminsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(currentUserProvider);
    final admins = ref.watch(adminAdminsProvider);
    final coaches = ref.watch(adminCoachesProvider).value ?? const <CoachSummary>[];
    final clubs = ref.watch(clubsByIdProvider);
    return AdminSection(
      title: l.adminNavAdmins,
      subtitle: l.adminGrantHint,
      actions: [
        PopupMenuButton<String>(
          key: const Key('make-club-admin'),
          tooltip: l.adminMakeClubAdmin,
          itemBuilder: (_) => [
            for (final c in coaches.where((c) => c.clubIds.isNotEmpty))
              PopupMenuItem(
                value: c.id,
                child: Text('${c.fullName} → ${c.clubIds.map((x) => clubs[x]?.name ?? x).join(', ')}'),
              ),
          ],
          onSelected: (uid) {
            final c = coaches.firstWhere((x) => x.id == uid);
            runGuarded(
              context,
              () => ref.read(adminRepositoryProvider).setAdminRole(uid, AdminRole.club, clubIds: c.clubIds),
              success: l.adminRoleUpdated,
            );
          },
          child: Chip(avatar: const Icon(Icons.person_add_alt_rounded), label: Text(l.adminMakeClubAdmin)),
        ),
      ],
      child: AsyncView<List<AppUser>>(
        value: admins,
        data: (list) => AdminTable<AppUser>(
          rows: list,
          searchText: (u) => u.fullName,
          columns: [
            AdminColumn(
              l.adminColName,
              (u) => Text(u.fullName, key: Key('admin-row-${u.id}')),
              flex: 2,
              sortKey: (u) => u.fullName,
            ),
            AdminColumn(
              l.adminColStatus,
              (u) => Text(u.isPlatformAdmin ? l.adminRolePlatform : l.adminRoleClub),
              flex: 2,
            ),
            AdminColumn(
              l.adminColClubs,
              (u) => Text(u.adminClubIds.map((x) => clubs[x]?.name ?? x).join(', ')),
              flex: 3,
            ),
            AdminColumn(
              l.adminColActions,
              (u) => u.id == me?.id
                  ? const SizedBox.shrink()
                  : TextButton(
                      key: Key('remove-admin-${u.id}'),
                      onPressed: () => runGuarded(
                        context,
                        () => ref.read(adminRepositoryProvider).setAdminRole(u.id, null),
                        success: l.adminRoleUpdated,
                      ),
                      child: Text(l.adminRemoveAdmin),
                    ),
              flex: 2,
            ),
          ],
        ),
      ),
    );
  }
}
