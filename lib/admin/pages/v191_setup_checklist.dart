import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../features/admin/domain/admin_models.dart';
import '../../features/authentication/presentation/session_providers.dart';
import '../../features/clubs/presentation/clubs_providers.dart';
import '../../features/organizations/domain/organization.dart';
import '../../features/organizations/domain/scheduling.dart';
import '../../features/organizations/presentation/org_providers.dart';
import 'admin_providers.dart';
import 'v17_pages.dart';

/// One step of the first-time organization setup.
class SetupStep {
  const SetupStep(this.id, this.label, this.done, this.route);

  final String id;
  final String label;
  final bool done;
  final String route;
}

/// v1.9.1: steps computed from SAVED data of the selected organization —
/// never a decorative checkbox. Steps for switched-off features are left
/// out (rooms need Facilities; sessions are always relevant).
List<SetupStep> computeSetupSteps({
  required AppLocalizationsLike l,
  required String orgId,
  required List<String> clubSports,
  required int coaches,
  required int rooms,
  required bool roomsOn,
  required int programs,
  required List<GroupOverview> groups,
}) {
  final mine = groups.where((g) => g.group.clubId == orgId && g.group.isActive).toList();
  return [
    SetupStep('sports', l.sports, clubSports.isNotEmpty, '/org-settings'),
    SetupStep('coaches', l.coaches, coaches > 0, '/org-settings'),
    if (roomsOn) SetupStep('rooms', l.rooms, rooms > 0, '/rooms'),
    SetupStep('programs', l.programs, programs > 0, '/programs'),
    SetupStep('groups', l.groups, mine.isNotEmpty, '/groups'),
    SetupStep('sessions', l.sessions, mine.any((g) => g.upcomingTrainings > 0), roomsOn ? '/schedule' : '/groups'),
    SetupStep('students', l.students, mine.any((g) => g.memberCount > 0), '/groups'),
  ];
}

/// Minimal label set so [computeSetupSteps] is testable without a widget tree.
class AppLocalizationsLike {
  const AppLocalizationsLike({
    required this.sports,
    required this.coaches,
    required this.rooms,
    required this.programs,
    required this.groups,
    required this.sessions,
    required this.students,
  });

  final String sports, coaches, rooms, programs, groups, sessions, students;
}

class OrgSetupChecklist extends ConsumerWidget {
  const OrgSetupChecklist({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(currentUserProvider);
    final orgId = ref.watch(adminOrgProvider);
    if (me == null || orgId == null) return const SizedBox.shrink();
    final cfg = ref.watch(orgConfigProvider(orgId)).value;
    final club = ref.watch(clubsByIdProvider)[orgId];
    final coaches = ref.watch(adminCoachesProvider).value;
    final rooms = ref.watch(roomsProvider(orgId)).value;
    final programs = ref.watch(programsProvider(orgId)).value;
    final groups = ref.watch(adminGroupsProvider).value;
    // Never show a guess: wait until everything it is computed from loaded.
    if (cfg == null || club == null || coaches == null || programs == null || groups == null) {
      return const SizedBox.shrink();
    }
    final roomsOn = cfg.isEnabled(OrgModule.facilities);
    final steps = computeSetupSteps(
      l: AppLocalizationsLike(
        sports: l.a191SetupSports,
        coaches: l.a191SetupCoaches,
        rooms: l.a191SetupRooms,
        programs: l.a191SetupPrograms,
        groups: l.a191SetupGroups,
        sessions: l.a191SetupSessions,
        students: l.a191SetupStudents,
      ),
      orgId: orgId,
      clubSports: club.sportIds,
      coaches: coaches.where((c) => c.clubIds.contains(orgId)).length,
      rooms: (rooms ?? const <Room>[]).where((r) => r.status != RoomStatus.archived).length,
      roomsOn: roomsOn,
      programs: programs.where((p) => p.status == ProgramStatus.active).length,
      groups: groups,
    );
    final done = steps.where((s) => s.done).length;
    if (done == steps.length) return const SizedBox.shrink();
    final next = steps.firstWhere((s) => !s.done);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        key: const Key('org-setup-checklist'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l.a191SetupTitle(orgName(context, ref, orgId)),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(l.a191SetupProgress(done, steps.length), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(value: done / steps.length, minHeight: 6),
            const SizedBox(height: AppSpacing.sm),
            for (final s in steps)
              ListTile(
                key: Key('setup-${s.id}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  s.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: s.done ? AppColors.success : Theme.of(context).colorScheme.onSurfaceVariant,
                  semanticLabel: s.done ? l.a191SetupDone : l.a191SetupTodo,
                ),
                title: Text(
                  s.label,
                  style: TextStyle(
                    fontWeight: s == next ? FontWeight.w800 : FontWeight.w500,
                    decoration: s.done ? TextDecoration.lineThrough : null,
                  ),
                ),
                trailing: s.done
                    ? null
                    : TextButton(
                        key: Key('setup-go-${s.id}'),
                        onPressed: () => context.go(s.route),
                        child: Text(s == next ? l.a191SetupStart : l.a191SetupOpen),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
