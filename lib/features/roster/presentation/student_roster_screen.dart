import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/visuals.dart';
import '../../attendance/domain/attendance.dart';
import '../../attendance/presentation/attendance_providers.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../children/presentation/children_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../medical_certificates/domain/medical_certificate.dart';
import '../../medical_certificates/presentation/certificate_actions.dart';
import '../../medical_certificates/presentation/certificates_providers.dart';
import '../domain/roster.dart';
import 'export_sheet.dart';

/// Coach student roster (v1.3): only the coach's own groups; search, sort,
/// filter, attendance rate, certificate status/expiry with audited view and
/// download, student detail, exports.
class StudentRosterScreen extends ConsumerStatefulWidget {
  const StudentRosterScreen({super.key, this.groupId});

  final String? groupId;

  @override
  ConsumerState<StudentRosterScreen> createState() => _StudentRosterScreenState();
}

class _StudentRosterScreenState extends ConsumerState<StudentRosterScreen> {
  String? _groupId;
  RosterQuery _query = const RosterQuery();

  @override
  void initState() {
    super.initState();
    _groupId = widget.groupId;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final me = ref.watch(currentUserProvider);
    final groups = (ref.watch(myGroupsProvider).value ?? const <Group>[])
        .where((g) => g.hasCoach(me?.id ?? ''))
        .toList();
    final group = groups.where((g) => g.id == _groupId).firstOrNull ?? groups.firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.rosterTitle),
        actions: [
          if (group != null)
            IconButton(
              key: const Key('roster-export'),
              tooltip: l.exportTitle,
              onPressed: () => showExportSheet(context, ref, group: group),
              icon: const Icon(Icons.ios_share_rounded),
            ),
        ],
      ),
      body: group == null
          ? EmptyState(icon: Icons.groups_rounded, title: l.noGroupsCoach)
          : ConstrainedContent(
              maxWidth: Breakpoints.dashboard,
              child: Column(
                children: [
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
                      children: [
                        for (final g in groups)
                          Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
                            child: ChoiceChip(
                              key: Key('roster-group-${g.id}'),
                              label: Text(g.name),
                              selected: g.id == group.id,
                              onSelected: (_) => setState(() => _groupId = g.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: TextField(
                      key: const Key('roster-search'),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: l.rosterSearch,
                      ),
                      onChanged: (v) =>
                          setState(() => _query = RosterQuery(search: v, sort: _query.sort, filter: _query.filter)),
                    ),
                  ),
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
                      children: [
                        PopupMenuButton<RosterSort>(
                          key: const Key('roster-sort'),
                          initialValue: _query.sort,
                          onSelected: (s) => setState(
                            () => _query = RosterQuery(search: _query.search, sort: s, filter: _query.filter),
                          ),
                          itemBuilder: (_) => [
                            for (final s in RosterSort.values)
                              PopupMenuItem(value: s, child: Text(_sortLabel(context, s))),
                          ],
                          child: Chip(
                            avatar: const Icon(Icons.sort_rounded, size: 18),
                            label: Text(_sortLabel(context, _query.sort)),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        for (final f in RosterFilter.values) ...[
                          ChoiceChip(
                            key: Key('roster-filter-${f.name}'),
                            label: Text(_filterLabel(context, f)),
                            selected: _query.filter == f,
                            onSelected: (_) => setState(
                              () => _query = RosterQuery(search: _query.search, sort: _query.sort, filter: f),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: _RosterList(group: group, query: _query),
                  ),
                ],
              ),
            ),
    );
  }

  static String _sortLabel(BuildContext context, RosterSort s) {
    final l = context.l10n;
    return switch (s) {
      RosterSort.name => l.rosterSortName,
      RosterSort.age => l.rosterSortAge,
      RosterSort.attendance => l.rosterSortAttendance,
      RosterSort.certificate => l.rosterSortCert,
    };
  }

  static String _filterLabel(BuildContext context, RosterFilter f) {
    final l = context.l10n;
    return switch (f) {
      RosterFilter.all => l.rosterFilterAll,
      RosterFilter.certIssues => l.rosterFilterCertIssues,
      RosterFilter.lowAttendance => l.rosterFilterLowAttendance,
    };
  }
}

/// Roster rows for one group, built from data the coach may read.
final rosterProvider = Provider.autoDispose.family<AsyncValue<List<RosterEntry>>, Group>((ref, g) {
  final members = ref.watch(groupMembersProvider(g.id));
  final certs = ref.watch(certificatesForChildrenProvider(childrenKey(g.memberChildIds)));
  final att = ref.watch(attendanceForGroupProvider(g.id));
  final starts = ref.watch(trainingStartsProvider);
  final now = ref.watch(clockProvider)();
  if (members.hasError) return AsyncError(members.error!, members.stackTrace!);
  final m = members.value;
  if (m == null) return const AsyncLoading();
  return AsyncData(
    buildRoster(
      members: m,
      groupId: g.id,
      groupName: g.name,
      sportId: g.sportId,
      certs: certs.value ?? const <MedicalCertificate>[],
      attendance: att.value ?? const <AttendanceRecord>[],
      trainingStarts: starts,
      now: now,
    ),
  );
});

class _RosterList extends ConsumerWidget {
  const _RosterList({required this.group, required this.query});

  final Group group;
  final RosterQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return AsyncView<List<RosterEntry>>(
      value: ref.watch(rosterProvider(group)),
      data: (all) {
        final rows = query.apply(all);
        if (rows.isEmpty) return EmptyState(icon: Icons.person_search_rounded, title: l.rosterEmptyFilter);
        // Lazy list: rows are built only when scrolled into view.
        return ListView.builder(
          key: const Key('roster-list'),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xxl),
          itemCount: rows.length + 1,
          itemBuilder: (context, i) => i == 0
              ? Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(l.rosterCount(rows.length), style: Theme.of(context).textTheme.labelMedium),
                )
              : Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _RosterRow(entry: rows[i - 1]),
                ),
        );
      },
    );
  }
}

class _RosterRow extends ConsumerWidget {
  const _RosterRow({required this.entry});

  final RosterEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final c = entry.child;
    final v = StatusVisual.certificate(context, entry.certStatus);
    final cert = entry.cert;
    return AppCard(
      key: Key('student-${c.id}'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: () => context.push('/student/${c.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              UserAvatar(name: c.fullName, photoPath: c.photoPath, size: 44),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.fullName,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${entry.groupName} · ${l.yearsOld(entry.age)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('roster-contacts-${c.id}'),
                tooltip: l.contactParentsAction,
                onPressed: () => context.push('/group/${entry.groupId}/contacts?childId=${c.id}'),
                icon: const Icon(Icons.contact_phone_rounded),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusPill(
                label: entry.attendanceRate == null
                    ? l.rosterNoAttendance
                    : l.rosterAttendanceRate((entry.attendanceRate! * 100).round()),
                color: entry.attendanceRate == null
                    ? AppColors.neutral
                    : (entry.attendanceRate! >= RosterQuery.lowAttendance ? AppColors.success : AppColors.warning),
                dense: true,
              ),
              StatusPill.of(v, dense: true),
              if (cert != null)
                Text(l.certExpiresOn(f.numericDate(cert.validUntil)), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          if (cert != null)
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                TextButton.icon(
                  key: Key('roster-view-cert-${c.id}'),
                  onPressed: () => previewCertificate(context, ref, cert),
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: Text(l.certPreview),
                ),
                TextButton.icon(
                  key: Key('roster-download-cert-${c.id}'),
                  onPressed: () => downloadCertificate(context, ref, cert),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(l.certDownload),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
