import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_picker.dart';
import '../../core/widgets/entity_options.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/visuals.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/language_selector.dart';
import '../../features/admin/domain/admin_models.dart';
import '../../features/attendance/domain/attendance.dart';
import '../../features/attendance/presentation/attendance_widgets.dart';
import '../../features/authentication/presentation/session_providers.dart';
import '../../features/brain_academy/domain/brain_models.dart';
import '../../features/brain_academy/presentation/brain_providers.dart';
import '../../features/clubs/presentation/clubs_providers.dart';
import '../../features/organizations/domain/organization.dart';
import '../../features/organizations/domain/repositories.dart';
import '../../features/organizations/domain/scheduling.dart';
import '../../features/organizations/presentation/org_providers.dart';
import '../../features/sports/presentation/sport_label.dart';
import '../../features/sports/presentation/sports_providers.dart';
import '../widgets.dart';
import 'admin_providers.dart';

/// Formats instants in the organization's wall-clock time (not the
/// browser's), so the calendar is correct from any computer.
extension OrgFmt on Fmt {
  String wt(DateTime d, String tz) => time(OrgTimeZones.wall(d, tz));
  String wd(DateTime d, String tz) => weekdayDayMonth(OrgTimeZones.wall(d, tz));
  String wdm(DateTime d, String tz) => dayMonth(OrgTimeZones.wall(d, tz));
}

// ─────────────────────────────────────────────────────────────── context

/// The tenant an admin is working on. Organization admins can only pick
/// their own organizations; the platform admin can pick any. The server
/// re-checks every request regardless of this selection.
class AdminOrgNotifier extends Notifier<String?> {
  @override
  String? build() {
    final me = ref.watch(currentUserProvider);
    if (me == null) return null;
    final allowed = adminOrgIds(ref);
    if (allowed.isEmpty) return null;
    return allowed.contains('org-tianeti') ? 'org-tianeti' : allowed.first;
  }

  void select(String id) => state = id;
}

final adminOrgProvider = NotifierProvider<AdminOrgNotifier, String?>(AdminOrgNotifier.new);

List<String> adminOrgIds(Ref ref) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  if (me.isPlatformAdmin) {
    final clubs = ref.watch(adminClubsProvider).value ?? const <ClubOverview>[];
    return [for (final c in clubs) c.club.id]..sort();
  }
  return [...me.adminClubIds]..sort();
}

final adminOrgIdsProvider = Provider.autoDispose<List<String>>(adminOrgIds);

String orgName(BuildContext context, WidgetRef ref, String orgId) {
  final cfg = ref.watch(orgConfigProvider(orgId)).value;
  final club = ref.watch(clubsByIdProvider)[orgId];
  return cfg?.branding.nameFor(Localizations.localeOf(context).languageCode, fallback: club?.name ?? orgId) ??
      club?.name ??
      orgId;
}

/// Tenant selector shown on every organization-scoped page.
class AdminOrgPicker extends ConsumerWidget {
  const AdminOrgPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(adminOrgIdsProvider);
    final current = ref.watch(adminOrgProvider);
    if (ids.isEmpty || current == null) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: OutlinedButton.icon(
        key: const Key('admin-org-picker'),
        onPressed: ids.length < 2 ? null : () => pickAdminOrg(context, ref),
        icon: const Icon(Icons.apartment_rounded),
        label: Text(orgName(context, ref, current), overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Searchable organization switch for every organization-scoped admin page.
Future<void> pickAdminOrg(BuildContext context, WidgetRef ref) async {
  final ids = ref.read(adminOrgIdsProvider);
  final current = ref.read(adminOrgProvider);
  final v = await showAppPicker<String>(
    context,
    title: context.l10n.adminSwitchOrg,
    selected: current,
    recentsId: 'admin-org',
    options: [
      for (final id in ids)
        AppPickerOption(
          value: id,
          label: orgName(context, ref, id),
          leading: CircleAvatar(
            radius: 12,
            backgroundColor: Color(ref.read(orgConfigProvider(id)).value?.branding.primaryColor ?? 0xFF2F6BFF),
          ),
          searchText: id,
        ),
    ],
  );
  if (v != null) ref.read(adminOrgProvider.notifier).select(v);
}

Widget _needsOrg(BuildContext context) =>
    EmptyState(icon: Icons.apartment_rounded, title: context.l10n.orgNoneSelected);

String moduleLabel(BuildContext context, OrgModule m) {
  final l = context.l10n;
  return switch (m) {
    OrgModule.trainings => l.moduleTrainings,
    OrgModule.matches => l.moduleMatches,
    OrgModule.attendance => l.moduleAttendance,
    OrgModule.communication => l.moduleCommunication,
    OrgModule.studentAccounts => l.moduleStudentAccounts,
    OrgModule.brainAcademy => l.moduleBrainAcademy,
    OrgModule.trainingPlans => l.moduleTrainingPlans,
    OrgModule.payments => l.modulePayments,
    OrgModule.medicalCertificates => l.moduleMedical,
    OrgModule.media => l.moduleMedia,
    OrgModule.leaderboards => l.moduleLeaderboards,
    OrgModule.roomScheduling => l.moduleRoomScheduling,
    OrgModule.notifications => l.moduleNotifications,
    OrgModule.parentRsvp => l.moduleParentRsvp,
    OrgModule.messageAcks => l.moduleMessageAcks,
    OrgModule.coachChallenges => l.moduleCoachChallenges,
    OrgModule.paymentReceipts => l.modulePaymentReceipts,
    OrgModule.paymentVerification => l.modulePaymentVerification,
    OrgModule.paymentReminders => l.modulePaymentReminders,
    OrgModule.facilities => l.moduleFacilities,
    OrgModule.reports => l.moduleReports,
    OrgModule.dataExports => l.moduleDataExports,
  };
}

String planLabel(BuildContext context, OrgPlan p) => switch (p) {
  OrgPlan.free => context.l10n.planFree,
  OrgPlan.standard => context.l10n.planStandard,
  OrgPlan.premium => context.l10n.planPremium,
};

String orgStatusLabel(BuildContext context, OrgStatus s) => switch (s) {
  OrgStatus.active => context.l10n.orgStatusActive,
  OrgStatus.suspended => context.l10n.orgStatusSuspended,
  OrgStatus.deactivated => context.l10n.orgStatusDeactivated,
};

Color orgStatusColor(OrgStatus s) => switch (s) {
  OrgStatus.active => AppColors.success,
  OrgStatus.suspended => AppColors.warning,
  OrgStatus.deactivated => AppColors.danger,
};

// ───────────────────────────────────────────────────── platform: tenants

/// Platform Super Admin: every organization, its plan, status, modules,
/// limits, administrators and operational health.
class OrganizationsPage extends ConsumerWidget {
  const OrganizationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final configs = ref.watch(orgConfigsProvider);
    final clubs = ref.watch(clubsByIdProvider);
    return AdminSection(
      title: l.adminNavOrganizations,
      subtitle: l.orgPlatformSubtitle,
      actions: [
        FilledButton.icon(
          key: const Key('org-new'),
          onPressed: () => showCreateOrgDialog(context, ref),
          icon: const Icon(Icons.add_business_rounded),
          label: Text(l.orgNew),
        ),
      ],
      child: AsyncView<List<OrgConfig>>(
        value: configs,
        data: (list) => AdminTable<OrgConfig>(
          rows: list,
          searchText: (c) => orgName(context, ref, c.orgId),
          filters: [
            (l.adminFilterAll, (_) => true),
            (l.orgStatusActive, (c) => c.status == OrgStatus.active),
            (l.orgStatusSuspended, (c) => c.status != OrgStatus.active),
          ],
          columns: [
            AdminColumn(
              l.adminColName,
              (c) => Text(
                orgName(context, ref, c.orgId),
                key: Key('org-row-${c.orgId}'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              flex: 3,
              sortKey: (c) => orgName(context, ref, c.orgId),
            ),
            AdminColumn(l.orgPlan, (c) => Text(planLabel(context, c.plan))),
            AdminColumn(
              l.adminColStatus,
              (c) => Align(
                alignment: Alignment.centerLeft,
                child: StatusPill(
                  label: orgStatusLabel(context, c.status),
                  color: orgStatusColor(c.status),
                  dense: true,
                ),
              ),
            ),
            AdminColumn(
              l.orgModulesOn,
              (c) => Text('${OrgModule.values.where(c.isEnabled).length}/${OrgModule.values.length}'),
            ),
            AdminColumn(l.orgAdmins, (c) => Text('${clubs[c.orgId]?.adminIds.length ?? 0}')),
            AdminColumn(
              '',
              (c) => Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    key: Key('org-manage-${c.orgId}'),
                    tooltip: l.orgManage,
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: () => showOrgPlatformDialog(context, ref, c),
                  ),
                  IconButton(
                    key: Key('org-admins-${c.orgId}'),
                    tooltip: l.orgAssignAdmin,
                    icon: const Icon(Icons.admin_panel_settings_rounded),
                    onPressed: () => showOrgAdminDialog(context, ref, c.orgId),
                  ),
                  IconButton(
                    key: Key('org-health-${c.orgId}'),
                    tooltip: l.orgHealth,
                    icon: const Icon(Icons.monitor_heart_rounded),
                    onPressed: () => showOrgHealthDialog(context, ref, c),
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

Future<void> showCreateOrgDialog(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final ka = TextEditingController();
  final en = TextEditingController();
  final ru = TextEditingController();
  final address = TextEditingController();
  final lat = TextEditingController(text: '42.1089');
  final lng = TextEditingController(text: '44.9690');
  var plan = OrgPlan.standard;
  var color = 0xFF0F766E;
  final sports = <String>{};
  final allSports = ref.read(sportsProvider).value ?? const [];
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => AlertDialog(
        title: Text(l.orgNew),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('org-name-ka'),
                  controller: ka,
                  decoration: InputDecoration(labelText: l.orgNameKa),
                ),
                TextField(
                  key: const Key('org-name-en'),
                  controller: en,
                  decoration: InputDecoration(labelText: l.orgNameEn),
                ),
                TextField(
                  controller: ru,
                  decoration: InputDecoration(labelText: l.orgNameRu),
                ),
                TextField(
                  key: const Key('org-address'),
                  controller: address,
                  decoration: InputDecoration(labelText: l.adminColAddress),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: lat,
                        decoration: const InputDecoration(labelText: 'Lat'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: lng,
                        decoration: const InputDecoration(labelText: 'Lng'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<OrgPlan>(
                  isExpanded: true,
                  key: const Key('org-plan'),
                  initialValue: plan,
                  decoration: InputDecoration(labelText: l.orgPlan),
                  items: [
                    for (final p in OrgPlan.values) DropdownMenuItem(value: p, child: Text(planLabel(context, p))),
                  ],
                  onChanged: (p) => set(() => plan = p ?? plan),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ColorRow(value: color, onChanged: (c) => set(() => color = c)),
                const SizedBox(height: AppSpacing.sm),
                Consumer(
                  builder: (context, ref, _) => Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in ref.watch(sportsProvider).value ?? allSports)
                        FilterChip(
                          key: Key('org-sport-${s.id}'),
                          label: Text(s.label(context)),
                          selected: sports.contains(s.id),
                          onSelected: (v) => set(() => v ? sports.add(s.id) : sports.remove(s.id)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          FilledButton(
            key: const Key('org-create'),
            onPressed: () async {
              final ok = await runGuarded(
                context,
                () => ref
                    .read(organizationsRepositoryProvider)
                    .createOrganization(
                      club: ClubDraft(
                        name: ka.text.trim(),
                        address: address.text.trim(),
                        lat: double.tryParse(lat.text) ?? 42.1089,
                        lng: double.tryParse(lng.text) ?? 44.9690,
                        sportIds: sports.toList(),
                      ),
                      plan: plan,
                      branding: OrgBranding(
                        names: {
                          'ka': ka.text.trim(),
                          if (en.text.trim().isNotEmpty) 'en': en.text.trim(),
                          if (ru.text.trim().isNotEmpty) 'ru': ru.text.trim(),
                        },
                        primaryColor: color,
                        address: address.text.trim(),
                      ),
                    ),
                success: l.orgCreated,
              );
              if (ok && context.mounted) Navigator.pop(context);
            },
            child: Text(l.save),
          ),
        ],
      ),
    ),
  );
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const colors = [0xFF1D4ED8, 0xFF0F766E, 0xFF7C2D12, 0xFF7C3AED, 0xFFBE123C, 0xFF15803D, 0xFF0F172A];

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(context.l10n.orgBrandColor),
      const SizedBox(width: AppSpacing.sm),
      for (final c in colors)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: InkWell(
            key: Key('org-color-${c.toRadixString(16)}'),
            onTap: () => onChanged(c),
            child: CircleAvatar(
              radius: 13,
              backgroundColor: Color(c),
              child: c == value ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
            ),
          ),
        ),
    ],
  );
}

/// Platform-only settings: status, plan, allowed modules and limits.
Future<void> showOrgPlatformDialog(BuildContext context, WidgetRef ref, OrgConfig cfg) async {
  final l = context.l10n;
  var status = cfg.status;
  var plan = cfg.plan;
  final allowed = {...cfg.allowedModules};
  final students = TextEditingController(text: '${cfg.limits.maxStudents}');
  final coaches = TextEditingController(text: '${cfg.limits.maxCoaches}');
  final rooms = TextEditingController(text: '${cfg.limits.maxRooms}');
  final groups = TextEditingController(text: '${cfg.limits.maxGroups}');
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => AlertDialog(
        title: Text('${l.orgManage} · ${orgName(context, ref, cfg.orgId)}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<OrgStatus>(
                  isExpanded: true,
                  key: const Key('org-status'),
                  initialValue: status,
                  decoration: InputDecoration(labelText: l.adminColStatus),
                  items: [
                    for (final s in OrgStatus.values)
                      DropdownMenuItem(value: s, child: Text(orgStatusLabel(context, s))),
                  ],
                  onChanged: (s) => set(() => status = s ?? status),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l.orgStatusHelp, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<OrgPlan>(
                  isExpanded: true,
                  initialValue: plan,
                  decoration: InputDecoration(labelText: l.orgPlan),
                  items: [
                    for (final p in OrgPlan.values) DropdownMenuItem(value: p, child: Text(planLabel(context, p))),
                  ],
                  onChanged: (p) => set(() {
                    plan = p ?? plan;
                    allowed
                      ..clear()
                      ..addAll(plan.defaultModules);
                  }),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l.orgAllowedModules, style: Theme.of(context).textTheme.titleSmall),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in OrgModule.values)
                      FilterChip(
                        key: Key('org-allow-${m.name}'),
                        label: Text(moduleLabel(context, m)),
                        avatar: restrictedModules.contains(m) ? const Icon(Icons.lock_rounded, size: 16) : null,
                        selected: allowed.contains(m),
                        onSelected: (v) => set(() => v ? allowed.add(m) : allowed.remove(m)),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l.orgLimits, style: Theme.of(context).textTheme.titleSmall),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (label, c) in [
                      (l.orgLimitStudents, students),
                      (l.orgLimitCoaches, coaches),
                      (l.orgLimitRooms, rooms),
                      (l.orgLimitGroups, groups),
                    ])
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: c,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: label),
                        ),
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
            key: const Key('org-platform-save'),
            onPressed: () async {
              int n(TextEditingController c, int d) => int.tryParse(c.text) ?? d;
              final ok = await runGuarded(
                context,
                () => ref
                    .read(organizationsRepositoryProvider)
                    .updatePlatformSettings(
                      cfg.orgId,
                      status: status,
                      plan: plan,
                      allowedModules: allowed,
                      limits: OrgLimits(
                        maxStudents: n(students, cfg.limits.maxStudents),
                        maxCoaches: n(coaches, cfg.limits.maxCoaches),
                        maxRooms: n(rooms, cfg.limits.maxRooms),
                        maxGroups: n(groups, cfg.limits.maxGroups),
                      ),
                    ),
                success: l.orgSaved,
              );
              if (ok && context.mounted) Navigator.pop(context);
            },
            child: Text(l.save),
          ),
        ],
      ),
    ),
  );
}

Future<void> showOrgAdminDialog(BuildContext context, WidgetRef ref, String orgId) async {
  final l = context.l10n;
  final coaches = ref.read(adminCoachesProvider).value ?? const <CoachSummary>[];
  final admins = ref.read(adminAdminsProvider).value ?? const [];
  final candidates = <String, String>{
    for (final c in coaches) c.id: '${c.firstName} ${c.lastName}',
    for (final a in admins)
      if (!a.isPlatformAdmin) a.id: a.fullName,
  };
  final manual = TextEditingController();
  String? pick;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => AlertDialog(
        title: Text('${l.orgAssignAdmin} · ${orgName(context, ref, orgId)}'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('org-admin-pick'),
                isExpanded: true,
                initialValue: pick,
                decoration: InputDecoration(labelText: l.orgPickUser),
                items: [for (final e in candidates.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => set(() => pick = v),
              ),
              TextField(
                key: const Key('org-admin-uid'),
                controller: manual,
                decoration: InputDecoration(labelText: l.orgUserId),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l.orgAdminHelp, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('org-admin-remove'),
            onPressed: () async {
              final uid = manual.text.trim().isNotEmpty ? manual.text.trim() : pick;
              if (uid == null) return;
              final ok = await runGuarded(
                context,
                () => ref.read(organizationsRepositoryProvider).setOrgAdmin(orgId, uid, admin: false),
                success: l.orgSaved,
              );
              if (ok && context.mounted) Navigator.pop(context);
            },
            child: Text(l.orgRemoveAdmin),
          ),
          FilledButton(
            key: const Key('org-admin-assign'),
            onPressed: () async {
              final uid = manual.text.trim().isNotEmpty ? manual.text.trim() : pick;
              if (uid == null) return;
              final ok = await runGuarded(
                context,
                () => ref.read(organizationsRepositoryProvider).setOrgAdmin(orgId, uid, admin: true),
                success: l.orgAdminAssigned,
              );
              if (ok && context.mounted) Navigator.pop(context);
            },
            child: Text(l.orgAssignAdmin),
          ),
        ],
      ),
    ),
  );
}

Future<void> showOrgHealthDialog(BuildContext context, WidgetRef ref, OrgConfig cfg) async {
  final l = context.l10n;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${l.orgHealth} · ${orgName(context, ref, cfg.orgId)}'),
      content: FutureBuilder<TenantHealth>(
        future: ref.read(organizationsRepositoryProvider).health(cfg.orgId),
        builder: (context, snap) {
          final h = snap.data;
          if (h == null) return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
          final over = h.overLimits(cfg.limits);
          return Column(
            key: const Key('org-health'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l.orgLimitStudents}: ${h.students} / ${cfg.limits.maxStudents}'),
              Text('${l.orgLimitCoaches}: ${h.coaches} / ${cfg.limits.maxCoaches}'),
              Text('${l.orgLimitGroups}: ${h.groups} / ${cfg.limits.maxGroups}'),
              Text('${l.orgLimitRooms}: ${h.rooms} / ${cfg.limits.maxRooms}'),
              Text('${l.orgUpcomingEvents}: ${h.upcomingEvents}'),
              Text('${l.orgBookingsWeek}: ${h.bookingsThisWeek}'),
              Text('${l.orgBrainPlays}: ${h.brainPlays7d}'),
              if (over.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l.orgOverLimit, style: const TextStyle(color: AppColors.danger)),
                ),
            ],
          );
        },
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close))],
    ),
  );
}

// ───────────────────────────────────────────────── organization settings

/// Organization admin: branding, enabled modules (within what the platform
/// allows), language, time zone, booking buffer, leaderboard and coaches.
class OrgSettingsPage extends ConsumerWidget {
  const OrgSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final org = ref.watch(adminOrgProvider);
    return AdminSection(
      title: l.adminNavOrgSettings,
      actions: const [AdminOrgPicker()],
      child: org == null
          ? _needsOrg(context)
          : AsyncView<OrgConfig>(
              value: ref.watch(orgConfigProvider(org)),
              data: (cfg) => _OrgSettingsForm(key: ValueKey('${cfg.orgId}-${cfg.updatedAt}'), cfg: cfg),
            ),
    );
  }
}

class _OrgSettingsForm extends ConsumerStatefulWidget {
  const _OrgSettingsForm({super.key, required this.cfg});

  final OrgConfig cfg;

  @override
  ConsumerState<_OrgSettingsForm> createState() => _OrgSettingsFormState();
}

class _OrgSettingsFormState extends ConsumerState<_OrgSettingsForm> {
  late final _ka = TextEditingController(text: widget.cfg.branding.names['ka'] ?? '');
  late final _en = TextEditingController(text: widget.cfg.branding.names['en'] ?? '');
  late final _ru = TextEditingController(text: widget.cfg.branding.names['ru'] ?? '');
  late final _desc = TextEditingController(text: widget.cfg.branding.description);
  late final _phone = TextEditingController(text: widget.cfg.branding.contactPhone ?? '');
  late final _email = TextEditingController(text: widget.cfg.branding.contactEmail ?? '');
  late final _address = TextEditingController(text: widget.cfg.branding.address);
  late final _logo = TextEditingController(text: widget.cfg.branding.logoUrl ?? '');
  late int _color = widget.cfg.branding.primaryColor;
  late final Set<OrgModule> _enabled = {...widget.cfg.enabledModules};
  late String _lang = widget.cfg.defaultLanguage;
  late String _tz = widget.cfg.timezone;
  late int _buffer = widget.cfg.bookingBufferMin;
  late LeaderboardSettings _lb = widget.cfg.leaderboard;

  Future<void> _save() => runGuarded(
    context,
    () => ref
        .read(organizationsRepositoryProvider)
        .updateOrgSettings(
          widget.cfg.orgId,
          enabledModules: _enabled,
          branding: widget.cfg.branding.copyWith(
            names: {
              if (_ka.text.trim().isNotEmpty) 'ka': _ka.text.trim(),
              if (_en.text.trim().isNotEmpty) 'en': _en.text.trim(),
              if (_ru.text.trim().isNotEmpty) 'ru': _ru.text.trim(),
            },
            primaryColor: _color,
            description: _desc.text.trim(),
            contactPhone: _phone.text.trim(),
            contactEmail: _email.text.trim(),
            address: _address.text.trim(),
            logoUrl: _logo.text.trim().isEmpty ? null : _logo.text.trim(),
          ),
          defaultLanguage: _lang,
          timezone: _tz,
          bookingBufferMin: _buffer,
          leaderboard: _lb,
        ),
    success: context.l10n.orgSaved,
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cfg = widget.cfg;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!cfg.isActive)
          AppCard(
            key: const Key('org-inactive-banner'),
            color: AppColors.danger.withValues(alpha: .08),
            child: Text(l.orgInactiveBanner(orgStatusLabel(context, cfg.status))),
          ),
        Text(l.orgBranding, style: t.titleMedium),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final (k, c, label) in [('ka', _ka, l.orgNameKa), ('en', _en, l.orgNameEn), ('ru', _ru, l.orgNameRu)])
              SizedBox(
                width: 260,
                child: TextField(
                  key: Key('org-set-name-$k'),
                  controller: c,
                  decoration: InputDecoration(labelText: label),
                ),
              ),
            SizedBox(
              width: 260,
              child: TextField(
                controller: _phone,
                decoration: InputDecoration(labelText: l.orgContactPhone),
              ),
            ),
            SizedBox(
              width: 260,
              child: TextField(
                controller: _email,
                decoration: InputDecoration(labelText: l.orgContactEmail),
              ),
            ),
            SizedBox(
              width: 260,
              child: TextField(
                controller: _address,
                decoration: InputDecoration(labelText: l.adminColAddress),
              ),
            ),
            SizedBox(
              width: 532,
              child: TextField(
                controller: _desc,
                decoration: InputDecoration(labelText: l.orgDescription),
              ),
            ),
            SizedBox(
              width: 532,
              child: TextField(
                controller: _logo,
                decoration: InputDecoration(labelText: l.orgLogoUrl),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _ColorRow(value: _color, onChanged: (c) => setState(() => _color = c)),
        const SizedBox(height: AppSpacing.lg),
        Text(l.orgModules, style: t.titleMedium),
        Text(l.orgModulesHelp, style: t.bodySmall),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final m in OrgModule.values)
              FilterChip(
                key: Key('org-module-${m.name}'),
                label: Text(moduleLabel(context, m)),
                avatar: cfg.allowedModules.contains(m) ? null : const Icon(Icons.lock_rounded, size: 16),
                selected: _enabled.contains(m),
                onSelected: cfg.canOrgAdminToggle(m)
                    ? (v) => setState(() => v ? _enabled.add(m) : _enabled.remove(m))
                    : null,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _lang,
                decoration: InputDecoration(labelText: l.orgDefaultLanguage),
                // Language names in their own script (same list as the app's selector).
                items: [
                  for (final (code, name) in LanguageSelector.options) DropdownMenuItem(value: code, child: Text(name)),
                ],
                onChanged: (v) => setState(() => _lang = v ?? _lang),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _tz,
                decoration: InputDecoration(labelText: l.orgTimezone),
                items: [for (final z in OrgTimeZones.offsets.keys) DropdownMenuItem(value: z, child: Text(z))],
                onChanged: (v) => setState(() => _tz = v ?? _tz),
              ),
            ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                key: const Key('org-buffer'),
                initialValue: _buffer,
                decoration: InputDecoration(labelText: l.orgBookingBuffer),
                items: [
                  for (final m in ({0, 5, 10, 15, 30, _buffer}.toList()..sort()))
                    DropdownMenuItem(value: m, child: Text(l.minutesShort(m))),
                ],
                onChanged: (v) => setState(() => _buffer = v ?? _buffer),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l.orgLeaderboardSettings, style: t.titleMedium),
        if (!cfg.allowedModules.contains(OrgModule.leaderboards))
          Text(l.orgLeaderboardNotAllowed, style: t.bodySmall?.copyWith(color: AppColors.warning))
        else ...[
          SwitchListTile(
            key: const Key('org-lb-enabled'),
            contentPadding: EdgeInsets.zero,
            value: _lb.enabled,
            title: Text(l.orgLeaderboardEnable),
            subtitle: Text(l.orgLeaderboardPrivacy),
            onChanged: (v) => setState(() {
              _lb = _lb.copyWith(enabled: v);
              if (v) _enabled.add(OrgModule.leaderboards);
            }),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in LeaderboardPeriod.values)
                FilterChip(
                  label: Text(leaderboardPeriodName(context, p)),
                  selected: _lb.periods.contains(p),
                  onSelected: (v) => setState(
                    () => _lb = _lb.copyWith(periods: v ? {..._lb.periods, p} : ({..._lb.periods}..remove(p))),
                  ),
                ),
              const SizedBox(width: 12),
              for (final g in BrainGame.values)
                FilterChip(
                  label: Text(gameName(context, g)),
                  selected: _lb.games.isEmpty || _lb.games.contains(g),
                  onSelected: (v) {
                    final cur = _lb.games.isEmpty ? BrainGame.values.toSet() : {..._lb.games};
                    v ? cur.add(g) : cur.remove(g);
                    setState(() => _lb = _lb.copyWith(games: cur.length == BrainGame.values.length ? {} : cur));
                  },
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _lb.byAgeBand,
            title: Text(l.orgLeaderboardByAge),
            onChanged: (v) => setState(() => _lb = _lb.copyWith(byAgeBand: v)),
          ),
          Row(
            children: [
              Text(l.orgLeaderboardMin),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _lb.minParticipants,
                items: [
                  for (final n in ({2, 3, 5, 8, 10, _lb.minParticipants}.toList()..sort()))
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: (v) => setState(() => _lb = _lb.copyWith(minParticipants: v)),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const Key('org-settings-save'),
            onPressed: cfg.isActive ? _save : null,
            icon: const Icon(Icons.save_rounded),
            label: Text(l.save),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _OrgCoaches(orgId: cfg.orgId),
      ],
    );
  }
}

String leaderboardPeriodName(BuildContext context, LeaderboardPeriod p) => switch (p) {
  LeaderboardPeriod.week => context.l10n.leaderboardWeek,
  LeaderboardPeriod.month => context.l10n.leaderboardMonth,
  LeaderboardPeriod.allTime => context.l10n.leaderboardAllTime,
};

class _OrgCoaches extends ConsumerWidget {
  const _OrgCoaches({required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final coaches = ref.watch(adminCoachesProvider).value ?? const <CoachSummary>[];
    final inOrg = coaches.where((c) => c.clubIds.contains(orgId)).toList();
    final others = coaches.where((c) => !c.clubIds.contains(orgId) && c.status.name == 'approved').toList();
    return Column(
      key: const Key('org-coaches'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.orgCoaches, style: Theme.of(context).textTheme.titleMedium),
        for (final c in inOrg)
          ListTile(
            key: Key('org-coach-${c.id}'),
            contentPadding: EdgeInsets.zero,
            leading: InitialsAvatar(name: '${c.firstName} ${c.lastName}', size: 32),
            title: Text('${c.firstName} ${c.lastName}'),
            trailing: TextButton(
              // v1.9: confirmed, with a result message.
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  title: l.orgRemoveCoach,
                  message: l.confirmRemoveCoachBody(c.fullName),
                  confirmLabel: l.orgRemoveCoach,
                  destructive: true,
                );
                if (!ok || !context.mounted) return;
                await runGuarded(
                  context,
                  () => ref.read(organizationsRepositoryProvider).setOrgCoach(orgId, c.id, member: false),
                  success: l.coachRemovedSnack,
                );
              },
              child: Text(l.orgRemoveCoach),
            ),
          ),
        if (others.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            // v1.9: searchable — name, sports and group count tell
            // namesakes apart; only approved coaches are offered.
            child: OutlinedButton.icon(
              key: const Key('org-add-coach'),
              icon: const Icon(Icons.person_add_rounded),
              label: Text(l.orgAddCoach),
              onPressed: () async {
                final sports = ref.read(sportsByIdProvider);
                final id = await showAppPicker<String>(
                  context,
                  title: l.orgAddCoach,
                  options: coachOptions(context, others, sportName: (s) => sports[s]?.label(context) ?? s),
                );
                if (id == null || !context.mounted) return;
                await runGuarded(
                  context,
                  () => ref.read(organizationsRepositoryProvider).setOrgCoach(orgId, id, member: true),
                  success: l.coachAddedSnack,
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────── programs

class ProgramsPage extends ConsumerWidget {
  const ProgramsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final org = ref.watch(adminOrgProvider);
    final sports = ref.watch(sportsByIdProvider);
    return AdminSection(
      title: l.adminNavPrograms,
      actions: [
        const AdminOrgPicker(),
        if (org != null)
          FilledButton.icon(
            key: const Key('program-new'),
            onPressed: () => showProgramDialog(context, ref, org),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.programNew),
          ),
      ],
      child: org == null
          ? _needsOrg(context)
          : AsyncView<List<SportsProgram>>(
              value: ref.watch(programsProvider(org)),
              data: (list) => AdminTable<SportsProgram>(
                rows: list,
                searchText: (p) => p.name,
                columns: [
                  AdminColumn(
                    l.adminColName,
                    (p) => Text(
                      p.name,
                      key: Key('program-row-${p.id}'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    flex: 3,
                    sortKey: (p) => p.name,
                  ),
                  AdminColumn(l.adminColSport, (p) => Text(sports[p.sportId]?.label(context) ?? p.sportId), flex: 2),
                  AdminColumn(l.programAges, (p) => Text('${p.ageMin}–${p.ageMax}')),
                  AdminColumn(l.programCapacity, (p) => Text('${p.capacity}')),
                  AdminColumn(l.adminColGroups, (p) => Text('${p.groupIds.length}')),
                  AdminColumn(l.adminColStatus, (p) => Text(programStatusLabel(context, p.status))),
                  AdminColumn(
                    '',
                    (p) => IconButton(
                      key: Key('program-edit-${p.id}'),
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () => showProgramDialog(context, ref, org, existing: p),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

String programStatusLabel(BuildContext context, ProgramStatus s) => switch (s) {
  ProgramStatus.active => context.l10n.orgStatusActive,
  ProgramStatus.paused => context.l10n.programPaused,
  ProgramStatus.archived => context.l10n.adminArchived,
};

Future<void> showProgramDialog(BuildContext context, WidgetRef ref, String orgId, {SportsProgram? existing}) async {
  final l = context.l10n;
  final club = ref.read(clubsByIdProvider)[orgId];
  final sports = ref.read(sportsByIdProvider);
  final groups = (ref.read(adminGroupsProvider).value ?? const <GroupOverview>[])
      .where((g) => g.group.clubId == orgId)
      .map((g) => g.group)
      .toList();
  final coaches = (ref.read(adminCoachesProvider).value ?? const <CoachSummary>[])
      .where((c) => c.clubIds.contains(orgId))
      .toList();
  final rooms = ref.read(roomsProvider(orgId)).value ?? const <Room>[];
  final name = TextEditingController(text: existing?.name ?? '');
  final desc = TextEditingController(text: existing?.description ?? '');
  final note = TextEditingController(text: existing?.scheduleNote ?? '');
  var sport = existing?.sportId ?? (club?.sportIds.firstOrNull ?? '');
  var ageMin = existing?.ageMin ?? 8;
  var ageMax = existing?.ageMax ?? 12;
  var capacity = existing?.capacity ?? 20;
  var status = existing?.status ?? ProgramStatus.active;
  String? room = existing?.roomId;
  final selCoaches = {...?existing?.coachIds};
  final selGroups = {...?existing?.groupIds};
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => AlertDialog(
        title: Text(existing == null ? l.programNew : l.edit),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: const Key('program-name'),
                  controller: name,
                  decoration: InputDecoration(labelText: l.adminColName),
                ),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  key: const Key('program-sport'),
                  initialValue: sport.isEmpty ? null : sport,
                  decoration: InputDecoration(labelText: l.adminColSport),
                  items: [
                    for (final s in club?.sportIds ?? const <String>[])
                      DropdownMenuItem(value: s, child: Text(sports[s]?.label(context) ?? s)),
                  ],
                  onChanged: (v) => set(() => sport = v ?? sport),
                ),
                TextField(
                  controller: desc,
                  decoration: InputDecoration(labelText: l.orgDescription),
                ),
                TextField(
                  controller: note,
                  decoration: InputDecoration(labelText: l.programScheduleNote),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('${l.programAges}: $ageMin–$ageMax'),
                RangeSlider(
                  min: 4,
                  max: 18,
                  divisions: 14,
                  values: RangeValues(ageMin.toDouble(), ageMax.toDouble()),
                  onChanged: (v) => set(() {
                    ageMin = v.start.round();
                    ageMax = v.end.round();
                  }),
                ),
                Text('${l.programCapacity}: $capacity'),
                Slider(
                  min: 4,
                  max: 60,
                  divisions: 56,
                  value: capacity.toDouble().clamp(4, 60),
                  onChanged: (v) => set(() => capacity = v.round()),
                ),
                DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: room,
                  decoration: InputDecoration(labelText: l.roomLabel),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l.none)),
                    for (final r in rooms) DropdownMenuItem(value: r.id, child: Text(r.name)),
                  ],
                  onChanged: (v) => set(() => room = v),
                ),
                DropdownButtonFormField<ProgramStatus>(
                  isExpanded: true,
                  initialValue: status,
                  decoration: InputDecoration(labelText: l.adminColStatus),
                  items: [
                    for (final s in ProgramStatus.values)
                      DropdownMenuItem(value: s, child: Text(programStatusLabel(context, s))),
                  ],
                  onChanged: (v) => set(() => status = v ?? status),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l.orgCoaches, style: Theme.of(context).textTheme.titleSmall),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final c in coaches)
                      FilterChip(
                        label: Text('${c.firstName} ${c.lastName}'),
                        selected: selCoaches.contains(c.id),
                        onSelected: (v) => set(() => v ? selCoaches.add(c.id) : selCoaches.remove(c.id)),
                      ),
                  ],
                ),
                Text(l.adminColGroups, style: Theme.of(context).textTheme.titleSmall),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final g in groups)
                      FilterChip(
                        label: Text(g.name),
                        selected: selGroups.contains(g.id),
                        onSelected: (v) => set(() => v ? selGroups.add(g.id) : selGroups.remove(g.id)),
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
            key: const Key('program-save'),
            onPressed: () async {
              final p = SportsProgram(
                id: existing?.id ?? '',
                orgId: orgId,
                sportId: sport,
                name: name.text.trim(),
                description: desc.text.trim(),
                ageMin: ageMin,
                ageMax: ageMax,
                coachIds: selCoaches.toList(),
                groupIds: selGroups.toList(),
                roomId: room,
                scheduleNote: note.text.trim(),
                capacity: capacity,
                status: status,
              );
              final ok = await runGuarded(
                context,
                () => ref.read(organizationsRepositoryProvider).upsertProgram(p),
                success: l.orgSaved,
              );
              if (ok && context.mounted) Navigator.pop(context);
            },
            child: Text(l.save),
          ),
        ],
      ),
    ),
  );
}

// ────────────────────────────────────────────────────────────────── rooms

class RoomsPage extends ConsumerWidget {
  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final org = ref.watch(adminOrgProvider);
    final sports = ref.watch(sportsByIdProvider);
    final cfg = org == null ? null : ref.watch(orgConfigProvider(org)).value;
    final enabled = cfg?.isEnabled(OrgModule.roomScheduling) ?? false;
    return AdminSection(
      title: l.adminNavRooms,
      actions: [
        const AdminOrgPicker(),
        if (org != null && enabled)
          FilledButton.icon(
            key: const Key('room-new'),
            onPressed: () => showRoomDialog(context, ref, org),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.roomNew),
          ),
      ],
      child: org == null
          ? _needsOrg(context)
          : !enabled
          ? EmptyState(icon: Icons.lock_rounded, title: l.moduleDisabledTitle, body: l.moduleDisabledRooms)
          : AsyncView<List<Room>>(
              value: ref.watch(roomsProvider(org)),
              data: (list) => AdminTable<Room>(
                rows: list,
                searchText: (r) => r.name,
                filters: [
                  (l.adminFilterAll, (_) => true),
                  (l.roomStatusActive, (r) => r.status == RoomStatus.active),
                  (l.roomStatusUnavailable, (r) => r.status == RoomStatus.unavailable),
                  (l.adminArchived, (r) => r.status == RoomStatus.archived),
                ],
                columns: [
                  AdminColumn(
                    l.adminColName,
                    (r) => Text(
                      r.name,
                      key: Key('room-row-${r.id}'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    flex: 2,
                    sortKey: (r) => r.name,
                  ),
                  AdminColumn(l.roomCapacity, (r) => Text('${r.capacity}')),
                  AdminColumn(
                    l.adminColSport,
                    (r) => Text(
                      r.sportIds.isEmpty
                          ? l.roomAnySport
                          : r.sportIds.map((s) => sports[s]?.label(context) ?? s).join(', '),
                    ),
                    flex: 3,
                  ),
                  AdminColumn(l.roomHours, (r) => Text(_hoursText(r.hours))),
                  AdminColumn(l.adminColStatus, (r) => Text(roomStatusLabel(context, r.status))),
                  AdminColumn(
                    '',
                    (r) => Wrap(
                      children: [
                        IconButton(
                          key: Key('room-edit-${r.id}'),
                          icon: const Icon(Icons.edit_rounded),
                          onPressed: () => showRoomDialog(context, ref, org, existing: r),
                        ),
                        IconButton(
                          key: Key('room-maintenance-${r.id}'),
                          tooltip: l.roomMaintenance,
                          icon: const Icon(Icons.build_rounded),
                          onPressed: () =>
                              showBookingDialog(context, ref, orgId: org, roomId: r.id, kind: BookingKind.maintenance),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

String _hm(int min) => '${(min ~/ 60).toString().padLeft(2, '0')}:${(min % 60).toString().padLeft(2, '0')}';

String _hoursText(OperatingHours h) {
  final v = h.byWeekday.values.toSet();
  if (v.length == 1) return '${_hm(v.first.$1)}–${_hm(v.first.$2)}';
  return '${h.byWeekday.length}d';
}

String roomStatusLabel(BuildContext context, RoomStatus s) => switch (s) {
  RoomStatus.active => context.l10n.roomStatusActive,
  RoomStatus.unavailable => context.l10n.roomStatusUnavailable,
  RoomStatus.archived => context.l10n.adminArchived,
};

Future<void> showRoomDialog(BuildContext context, WidgetRef ref, String orgId, {Room? existing}) => showDialog<void>(
  context: context,
  builder: (_) => _RoomDialog(orgId: orgId, existing: existing),
);

class _RoomDialog extends ConsumerStatefulWidget {
  const _RoomDialog({required this.orgId, this.existing});

  final String orgId;
  final Room? existing;

  @override
  ConsumerState<_RoomDialog> createState() => _RoomDialogState();
}

class _RoomDialogState extends ConsumerState<_RoomDialog> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  late final _capacity = TextEditingController(text: '${widget.existing?.capacity ?? 30}');
  late var _status = widget.existing?.status ?? RoomStatus.active;
  late final _sel = {...?widget.existing?.sportIds};
  // Per-weekday hours are kept as they are; only days the admin edits
  // change (v1.8 wrote the first day's hours to all seven days).
  late final Map<int, (int, int)?> _hours = {
    for (var d = 1; d <= 7; d++) d: (widget.existing?.hours ?? OperatingHours.standard).byWeekday[d],
  };
  late bool _same = _hours.values.toSet().length <= 1;
  bool _busy = false;
  bool _tried = false;

  String? get _nameError => _tried && _name.text.trim().isEmpty ? context.l10n.errRequiredField : null;
  int? get _cap => int.tryParse(_capacity.text.trim());
  String? get _capError => _tried && (_cap == null || _cap! < 1 || _cap! > 2000) ? context.l10n.errCapacity : null;

  Future<void> _editHours(int? day) async {
    final cur = (day == null ? _hours.values.whereType<(int, int)>().firstOrNull : _hours[day]) ?? (480, 1320);
    final from = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: cur.$1 ~/ 60, minute: cur.$1 % 60),
      helpText: context.l10n.roomOpensAt,
    );
    if (from == null || !mounted) return;
    final to = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: cur.$2 ~/ 60 % 24, minute: cur.$2 % 60),
      helpText: context.l10n.roomClosesAt,
    );
    if (to == null) return;
    var range = (from.hour * 60 + from.minute, to.hour * 60 + to.minute);
    if (range.$2 <= range.$1) range = (range.$1, 1440);
    setState(() {
      if (day == null) {
        for (var d = 1; d <= 7; d++) {
          if (_hours[d] != null || _same) _hours[d] = range;
        }
      } else {
        _hours[day] = range;
      }
    });
  }

  Future<void> _save() async {
    final l = context.l10n;
    setState(() => _tried = true);
    if (_nameError != null || _capError != null) return;
    setState(() => _busy = true);
    final r = Room(
      id: widget.existing?.id ?? '',
      orgId: widget.orgId,
      name: _name.text.trim(),
      capacity: _cap!,
      sportIds: _sel.toList(),
      hours: OperatingHours({
        for (final e in _hours.entries)
          if (e.value != null) e.key: e.value!,
      }),
      status: _status,
      venueId: widget.existing?.venueId,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    final ok = await runGuarded(
      context,
      () => ref.read(schedulingRepositoryProvider).upsertRoom(r),
      success: widget.existing == null ? l.roomCreated : l.orgSaved,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final club = ref.watch(clubsByIdProvider)[widget.orgId];
    final sports = ref.watch(sportsByIdProvider);
    String range((int, int)? h) => h == null ? l.roomClosed : '${_hm(h.$1)}–${_hm(h.$2 % 1440)}';
    return AlertDialog(
      title: Text(widget.existing == null ? l.roomNew : l.roomEdit),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppFormSection(
                title: l.formBasics,
                children: [
                  TextField(
                    key: const Key('room-name'),
                    controller: _name,
                    autofocus: widget.existing == null,
                    onChanged: (_) => _tried ? setState(() {}) : null,
                    decoration: InputDecoration(labelText: '${l.adminColName} *', errorText: _nameError),
                  ),
                  TextField(
                    key: const Key('room-capacity'),
                    controller: _capacity,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _tried ? setState(() {}) : null,
                    decoration: InputDecoration(
                      labelText: '${l.roomCapacity} *',
                      helperText: l.roomCapacityHint,
                      errorText: _capError,
                    ),
                  ),
                  AppChoiceGroup<RoomStatus>(
                    label: l.adminColStatus,
                    keyPrefix: 'room-status',
                    value: _status,
                    choices: [for (final s in RoomStatus.values) (s, roomStatusLabel(context, s), null)],
                    onChanged: (v) => setState(() => _status = v),
                  ),
                ],
              ),
              AppFormSection(
                title: l.roomHours,
                children: [
                  SwitchListTile(
                    key: const Key('room-same-hours'),
                    contentPadding: EdgeInsets.zero,
                    value: _same,
                    title: Text(l.roomSameHours),
                    onChanged: (v) => setState(() => _same = v),
                  ),
                  if (_same)
                    OutlinedButton.icon(
                      key: const Key('room-hours-all'),
                      onPressed: () => _editHours(null),
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text(range(_hours.values.whereType<(int, int)>().firstOrNull)),
                    )
                  else
                    for (var d = 1; d <= 7; d++)
                      Row(
                        children: [
                          SizedBox(width: 56, child: Text(weekdayShortName(context, d))),
                          Checkbox(
                            value: _hours[d] != null,
                            onChanged: (v) => setState(() => _hours[d] = v! ? (480, 1320) : null),
                          ),
                          Expanded(
                            child: TextButton(
                              key: Key('room-hours-$d'),
                              onPressed: _hours[d] == null ? null : () => _editHours(d),
                              child: Align(alignment: Alignment.centerLeft, child: Text(range(_hours[d]))),
                            ),
                          ),
                        ],
                      ),
                ],
              ),
              AppFormSection(
                title: l.roomSports,
                hint: l.roomSportsHint,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in club?.sportIds ?? const <String>[])
                        FilterChip(
                          avatar: Icon(SportVisuals.icon(sports[s]?.icon ?? s), size: 16),
                          label: Text(sports[s]?.label(context) ?? s),
                          selected: _sel.contains(s),
                          onSelected: (v) => setState(() => v ? _sel.add(s) : _sel.remove(s)),
                        ),
                    ],
                  ),
                  TextField(
                    controller: _note,
                    decoration: InputDecoration(labelText: l.roomNote),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          key: const Key('room-save'),
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.existing == null ? l.roomCreate : l.saveChanges),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────── calendar

/// Interactive room calendar: day view with one column per room, week view
/// with one column per day; coach / sport filters; free-slot taps create
/// bookings; booking chips can be dragged to another slot or room. Every
/// change goes through the server-validated repository — dragging never
/// bypasses conflict detection.
class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  DateTime? _day;
  bool _week = false;
  String? _coach;
  String? _sport;
  String? _roomFilter;

  static const _hourHeight = 48.0;
  static const _firstHour = 7;
  static const _lastHour = 23;

  DateTime _today(String tz) {
    final w = OrgTimeZones.wall(ref.read(clockProvider)(), tz);
    return DateTime.utc(w.year, w.month, w.day);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final org = ref.watch(adminOrgProvider);
    if (org == null) {
      return AdminSection(title: l.adminNavSchedule, actions: const [AdminOrgPicker()], child: _needsOrg(context));
    }
    // v1.9: explicit loading and error states (no bare spinner, no
    // misleading empty "all free" grid while data loads or fails).
    final cfgAsync = ref.watch(orgConfigProvider(org));
    final cfg = cfgAsync.value;
    if (cfg == null) {
      return AdminSection(
        title: l.adminNavSchedule,
        actions: const [AdminOrgPicker()],
        child: cfgAsync.hasError
            ? ErrorView(error: cfgAsync.error!, onRetry: () => ref.invalidate(orgConfigProvider(org)))
            : const SkeletonList(count: 4),
      );
    }
    if (!cfg.isEnabled(OrgModule.roomScheduling)) {
      return AdminSection(
        title: l.adminNavSchedule,
        actions: const [AdminOrgPicker()],
        child: EmptyState(icon: Icons.lock_rounded, title: l.moduleDisabledTitle, body: l.moduleDisabledRooms),
      );
    }
    final tz = cfg.timezone;
    final day = _day ?? _today(tz);
    final start = _week ? day.subtract(Duration(days: day.weekday - 1)) : day;
    final days = _week ? 7 : 1;
    final from = OrgTimeZones.instant(tz, start.year, start.month, start.day);
    final to = from.add(Duration(days: days));
    final roomsAsync = ref.watch(roomsProvider(org));
    final bookingsAsync = ref.watch(bookingsProvider((org, from, to)));
    final failed = roomsAsync.hasError ? roomsAsync : (bookingsAsync.hasError ? bookingsAsync : null);
    if (failed != null && !(roomsAsync.hasValue && bookingsAsync.hasValue)) {
      return AdminSection(
        title: l.adminNavSchedule,
        actions: const [AdminOrgPicker()],
        child: ErrorView(
          error: failed.error!,
          onRetry: () => ref
            ..invalidate(roomsProvider(org))
            ..invalidate(bookingsProvider((org, from, to))),
        ),
      );
    }
    if (!roomsAsync.hasValue || !bookingsAsync.hasValue) {
      return AdminSection(
        title: l.adminNavSchedule,
        actions: const [AdminOrgPicker()],
        child: const SkeletonList(count: 4),
      );
    }
    final rooms = roomsAsync.value!.where((r) => r.status != RoomStatus.archived).toList();
    final all = bookingsAsync.value!;
    for (final b in all) {
      _bookingIndex[b.id] = b;
    }
    for (final r in rooms) {
      _roomIndex[r.id] = r;
    }
    final bookings = all
        .where(
          (b) =>
              b.isActive &&
              (_coach == null || b.coachId == _coach) &&
              (_sport == null || b.sportId == _sport) &&
              (_roomFilter == null || b.roomId == _roomFilter),
        )
        .toList();
    final coaches = (ref.watch(adminCoachesProvider).value ?? const <CoachSummary>[])
        .where((c) => c.clubIds.contains(org))
        .toList();
    final sportsById = ref.watch(sportsByIdProvider);
    final club = ref.watch(clubsByIdProvider)[org];
    final f = Fmt.of(context);
    final columns = _week ? [for (var i = 0; i < 7; i++) start.add(Duration(days: i))] : const <DateTime>[];
    return AdminSection(
      title: l.adminNavSchedule,
      subtitle: l.scheduleSubtitle(tz),
      actions: [
        const AdminOrgPicker(),
        FilledButton.icon(
          key: const Key('booking-new'),
          onPressed: rooms.isEmpty ? null : () => showBookingDialog(context, ref, orgId: org),
          icon: const Icon(Icons.add_rounded),
          label: Text(l.bookingNew),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<bool>(
                key: const Key('schedule-view'),
                segments: [
                  ButtonSegment(value: false, label: Text(l.scheduleDay)),
                  ButtonSegment(value: true, label: Text(l.scheduleWeek)),
                ],
                selected: {_week},
                onSelectionChanged: (s) => setState(() => _week = s.first),
              ),
              IconButton(
                key: const Key('schedule-prev'),
                onPressed: () => setState(() => _day = day.subtract(Duration(days: days))),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              TextButton(
                key: const Key('schedule-today'),
                onPressed: () => setState(() => _day = null),
                child: Text(l.today),
              ),
              IconButton(
                key: const Key('schedule-next'),
                onPressed: () => setState(() => _day = day.add(Duration(days: days))),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              Text(
                _week ? '${f.wdm(from, tz)} – ${f.wdm(to.subtract(const Duration(days: 1)), tz)}' : f.wd(from, tz),
                key: const Key('schedule-range'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              DropdownButton<String?>(
                key: const Key('schedule-coach-filter'),
                value: _coach,
                hint: Text(l.scheduleAllCoaches),
                items: [
                  DropdownMenuItem(value: null, child: Text(l.scheduleAllCoaches)),
                  for (final c in coaches) DropdownMenuItem(value: c.id, child: Text('${c.firstName} ${c.lastName}')),
                ],
                onChanged: (v) => setState(() => _coach = v),
              ),
              DropdownButton<String?>(
                key: const Key('schedule-sport-filter'),
                value: _sport,
                hint: Text(l.scheduleAllSports),
                items: [
                  DropdownMenuItem(value: null, child: Text(l.scheduleAllSports)),
                  for (final s in club?.sportIds ?? const <String>[])
                    DropdownMenuItem(value: s, child: Text(sportsById[s]?.label(context) ?? s)),
                ],
                onChanged: (v) => setState(() => _sport = v),
              ),
              if (_week)
                DropdownButton<String?>(
                  key: const Key('schedule-room-filter'),
                  value: _roomFilter,
                  hint: Text(l.scheduleAllRooms),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l.scheduleAllRooms)),
                    for (final r in rooms) DropdownMenuItem(value: r.id, child: Text(r.name)),
                  ],
                  onChanged: (v) => setState(() => _roomFilter = v),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const _Legend(),
          const SizedBox(height: AppSpacing.xs),
          if (rooms.isEmpty)
            EmptyState(icon: Icons.meeting_room_rounded, title: l.roomNone)
          else
            SizedBox(
              height: (_lastHour - _firstHour) * _hourHeight + 40,
              child: LayoutBuilder(
                builder: (context, c) {
                  final n = _week ? 7 : rooms.length;
                  final colWidth = ((c.maxWidth - 56) / n).clamp(130.0, 400.0);
                  final grid = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _HourAxis(first: _firstHour, last: _lastHour, hourHeight: _hourHeight),
                      for (var i = 0; i < n; i++)
                        SizedBox(
                          width: colWidth,
                          child: _week
                              ? _column(
                                  key: Key('schedule-col-day-$i'),
                                  header: f.weekdayDayMonth(columns[i]),
                                  dayStart: OrgTimeZones.instant(tz, columns[i].year, columns[i].month, columns[i].day),
                                  bookings: bookings,
                                  room: _roomFilter == null ? null : rooms.firstWhere((r) => r.id == _roomFilter),
                                  rooms: rooms,
                                  orgId: org,
                                  tz: tz,
                                )
                              : _column(
                                  key: Key('schedule-col-${rooms[i].id}'),
                                  header: '${rooms[i].name} · ${rooms[i].capacity}',
                                  dayStart: from,
                                  bookings: bookings.where((b) => b.roomId == rooms[i].id).toList(),
                                  room: rooms[i],
                                  rooms: rooms,
                                  orgId: org,
                                  tz: tz,
                                ),
                        ),
                    ],
                  );
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(child: grid),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _column({
    required Key key,
    required String header,
    required DateTime dayStart,
    required List<Booking> bookings,
    required Room? room,
    required List<Room> rooms,
    required String orgId,
    required String tz,
  }) {
    final dayEnd = dayStart.add(const Duration(days: 1));
    final top = dayStart.add(const Duration(hours: _firstHour));
    final inDay = bookings.where((b) => b.startAt.isBefore(dayEnd) && b.endAt.isAfter(dayStart)).toList();
    final busyMin = inDay.fold<int>(0, (a, b) => a + b.duration.inMinutes);
    double y(DateTime t) => t.difference(top).inMinutes / 60 * _hourHeight;
    final now = ref.watch(clockProvider)();
    return Column(
      key: key,
      children: [
        Container(
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Text(
            '$header\n${context.l10n.scheduleBusy(busyMin ~/ 60, busyMin % 60)}',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        SizedBox(
          height: (_lastHour - _firstHour) * _hourHeight,
          child: Stack(
            children: [
              // Free 30-minute slots: tap to create, drop to move.
              for (var s = 0; s < (_lastHour - _firstHour) * 2; s++)
                Positioned(
                  top: s * _hourHeight / 2,
                  left: 0,
                  right: 0,
                  height: _hourHeight / 2,
                  child: DragTarget<Booking>(
                    onAcceptWithDetails: (d) =>
                        _move(d.data, top.add(Duration(minutes: s * 30)), room?.id ?? d.data.roomId),
                    builder: (context, cand, _) => InkWell(
                      key: Key('slot-${room?.id ?? 'all'}-${dayStart.toIso8601String()}-$s'),
                      onTap: () => showBookingDialog(
                        context,
                        ref,
                        orgId: orgId,
                        roomId: room?.id ?? rooms.first.id,
                        start: top.add(Duration(minutes: s * 30)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cand.isNotEmpty ? AppColors.blue.withValues(alpha: .15) : null,
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).dividerColor.withValues(alpha: s.isEven ? .6 : .25),
                            ),
                            left: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .4)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // v1.9: current-time line ("now"), beneath bookings.
              if (!now.isBefore(top) && now.isBefore(top.add(const Duration(hours: _lastHour - _firstHour))))
                Positioned(
                  top: y(now),
                  left: 0,
                  right: 0,
                  height: 2,
                  child: IgnorePointer(
                    child: Container(key: const Key('schedule-now-line'), color: AppColors.danger),
                  ),
                ),
              for (final b in inDay)
                Positioned(
                  top: y(b.startAt).clamp(0, (_lastHour - _firstHour) * _hourHeight),
                  left: 2,
                  right: 2,
                  height: (b.duration.inMinutes / 60 * _hourHeight - 2).clamp(14, 2000),
                  child: Draggable<Booking>(
                    data: b,
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        width: 140,
                        height: 40,
                        child: _BookingChip(booking: b, rooms: rooms, showRoom: true, tz: tz),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: .3,
                      child: _BookingChip(booking: b, rooms: rooms, showRoom: _week, tz: tz),
                    ),
                    child: InkWell(
                      key: Key('booking-${b.id}'),
                      onTap: () => showBookingDialog(context, ref, orgId: orgId, existing: b),
                      child: _BookingChip(booking: b, rooms: rooms, showRoom: _week, tz: tz),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _move(Booking b, DateTime start, String roomId) async {
    final moved = b.copyWith(startAt: start, endAt: start.add(b.duration), roomId: roomId);
    try {
      await ref.read(schedulingRepositoryProvider).updateBooking(moved);
      if (mounted) showAppSnack(context, context.l10n.bookingMoved);
    } on BookingRejected catch (e) {
      if (mounted) {
        final choice = await showConflictDialog(
          context,
          ref,
          e,
          ref.read(orgConfigProvider(b.orgId)).value?.timezone ?? OrgTimeZones.tbilisi,
        );
        if (choice != null && mounted) await _move(b, choice.start ?? start, choice.roomId ?? roomId);
      }
    } catch (e) {
      if (mounted) await runGuarded(context, () => Future<void>.error(e));
    }
  }
}

class _HourAxis extends StatelessWidget {
  const _HourAxis({required this.first, required this.last, required this.hourHeight});

  final int first;
  final int last;
  final double hourHeight;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 56,
    child: Column(
      children: [
        const SizedBox(height: 40),
        for (var h = first; h < last; h++)
          SizedBox(
            height: hourHeight,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(_hm(h * 60), style: Theme.of(context).textTheme.labelSmall),
              ),
            ),
          ),
      ],
    ),
  );
}

Color bookingColor(BookingKind k) => switch (k) {
  BookingKind.training => AppColors.blue,
  BookingKind.match => const Color(0xFF15803D),
  BookingKind.event => const Color(0xFF7C3AED),
  BookingKind.maintenance => const Color(0xFF6B7280),
};

String bookingKindLabel(BuildContext context, BookingKind k) => switch (k) {
  BookingKind.training => context.l10n.bookingKindTraining,
  BookingKind.match => context.l10n.bookingKindMatch,
  BookingKind.event => context.l10n.bookingKindEvent,
  BookingKind.maintenance => context.l10n.bookingKindMaintenance,
};

class _BookingChip extends StatelessWidget {
  const _BookingChip({required this.booking, required this.rooms, required this.showRoom, required this.tz});

  final String tz;
  final Booking booking;
  final List<Room> rooms;
  final bool showRoom;

  @override
  Widget build(BuildContext context) {
    final c = bookingColor(booking.kind);
    final f = Fmt.of(context);
    final room = rooms.where((r) => r.id == booking.roomId).firstOrNull?.name ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: c, width: 4)),
      ),
      child: Text(
        '${f.wt(booking.startAt, tz)} ${booking.title.isEmpty ? bookingKindLabel(context, booking.kind) : booking.title}'
        '${showRoom ? ' · $room' : ''}${booking.seriesId != null ? ' ↻' : ''}',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: 4,
    children: [
      for (final k in BookingKind.values)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, color: bookingColor(k)),
            const SizedBox(width: 4),
            Text(bookingKindLabel(context, k), style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor)),
          ),
          const SizedBox(width: 4),
          Text(context.l10n.scheduleFree, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    ],
  );
}

String conflictText(BuildContext context, ConflictCode c) {
  final l = context.l10n;
  return switch (c) {
    ConflictCode.invalidRange => l.conflictInvalidRange,
    ConflictCode.tooLong => l.conflictTooLong,
    ConflictCode.roomNotBookable => l.conflictRoomNotBookable,
    ConflictCode.outsideHours => l.conflictOutsideHours,
    ConflictCode.overCapacity => l.conflictOverCapacity,
    ConflictCode.roomOverlap => l.conflictRoomOverlap,
    ConflictCode.maintenance => l.conflictMaintenance,
    ConflictCode.coachOverlap => l.conflictCoachOverlap,
    ConflictCode.groupOverlap => l.conflictGroupOverlap,
    ConflictCode.wrongTenant => l.conflictWrongTenant,
  };
}

/// Bookings and rooms the calendar has shown in this session, so conflicts
/// can name the session that is in the way (ids come from the server).
final _bookingIndex = <String, Booking>{};
final _roomIndex = <String, Room>{};

/// One conflict in plain words: what, which session, where and when.
String conflictLine(BuildContext context, BookingConflict c, String tz) {
  final f = Fmt.of(context);
  final other = c.otherId == null ? null : _bookingIndex[c.otherId];
  final room = other == null ? null : _roomIndex[other.roomId];
  return [
    conflictText(context, c.code),
    if (other != null) '«${other.title}»${room == null ? '' : ' · ${room.name}'}',
    if (c.start != null) '${f.wd(c.start!, tz)} ${f.wt(c.start!, tz)}–${f.wt(c.end!, tz)}',
  ].join(' — ');
}

/// A choice offered by [showConflictDialog].
typedef ConflictChoice = ({DateTime? start, String? roomId});

/// v1.9: explains a rejected move (which session, which room, when) and
/// lets the admin pick a suggested free time or room directly. Returns the
/// choice, or null when closed. The server still re-checks every choice.
Future<ConflictChoice?> showConflictDialog(BuildContext context, WidgetRef ref, BookingRejected e, String tz) {
  final l = context.l10n;
  final f = Fmt.of(context);
  return showDialog<ConflictChoice>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('booking-conflict-dialog'),
      icon: const Icon(Icons.event_busy_rounded, color: AppColors.danger),
      title: Text(l.bookingRejected),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final c in e.conflicts)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${conflictLine(context, c, tz)}', key: Key('conflict-line-${c.code.name}')),
              ),
            if (e.alternatives.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l.bookingPickTime, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final a in e.alternatives)
                    ActionChip(
                      key: Key('conflict-alt-${a.millisecondsSinceEpoch}'),
                      avatar: const Icon(Icons.schedule_rounded, size: 16),
                      label: Text('${f.wd(a, tz)} ${f.wt(a, tz)}'),
                      onPressed: () => Navigator.pop<ConflictChoice>(context, (start: a, roomId: null)),
                    ),
                ],
              ),
            ],
            if (e.freeRooms.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l.bookingPickRoom, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final r in e.freeRooms)
                    ActionChip(
                      key: Key('conflict-room-${r.id}'),
                      avatar: const Icon(Icons.meeting_room_rounded, size: 16),
                      label: Text('${r.name} · ${l.roomCapacity} ${r.capacity}'),
                      onPressed: () => Navigator.pop<ConflictChoice>(context, (start: null, roomId: r.id)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.bookingKeepAsIs))],
    ),
  );
}

/// Create / edit a booking (one-time or weekly), with live conflict
/// warnings, server rejection reasons, suggested free times and rooms.
Future<void> showBookingDialog(
  BuildContext context,
  WidgetRef ref, {
  required String orgId,
  Booking? existing,
  String? roomId,
  DateTime? start,
  BookingKind kind = BookingKind.training,
}) => showDialog<void>(
  context: context,
  builder: (_) => _BookingDialog(orgId: orgId, existing: existing, roomId: roomId, start: start, kind: kind),
);

class _BookingDialog extends ConsumerStatefulWidget {
  const _BookingDialog({required this.orgId, this.existing, this.roomId, this.start, required this.kind});

  final String orgId;
  final Booking? existing;
  final String? roomId;
  final DateTime? start;
  final BookingKind kind;

  @override
  ConsumerState<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends ConsumerState<_BookingDialog> {
  late final OrgConfig _cfg = ref.read(orgConfigProvider(widget.orgId)).value ?? OrgConfig.legacy(widget.orgId);
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late BookingKind _kind = widget.existing?.kind ?? widget.kind;
  late String? _room = widget.existing?.roomId ?? widget.roomId;
  late String? _group = widget.existing?.groupId;
  late String? _coach = widget.existing?.coachId;
  late String? _program = widget.existing?.programId;
  late DateTime _date;
  late int _startMin;
  late int _duration = widget.existing?.duration.inMinutes ?? 90;
  int? _attendees;
  bool _recurring = false;
  final Set<int> _weekdays = {};
  late DateTime _until;
  bool _allowGroupOverlap = false;
  List<BookingConflict> _conflicts = const [];
  BookingRejected? _rejected;
  bool _busy = false;

  String get _tz => _cfg.timezone;

  @override
  void initState() {
    super.initState();
    final s = widget.existing?.startAt ?? widget.start ?? ref.read(clockProvider)().add(const Duration(days: 1));
    final w = OrgTimeZones.wall(s, _tz);
    _date = DateTime.utc(w.year, w.month, w.day);
    _startMin = widget.existing == null && widget.start == null ? 16 * 60 : w.hour * 60 + w.minute;
    _weekdays.add(_date.weekday);
    _until = _date.add(const Duration(days: 56));
    _attendees = widget.existing?.expectedAttendees;
    WidgetsBinding.instance.addPostFrameCallback((_) => _preview());
  }

  DateTime get _startAt =>
      OrgTimeZones.instant(_tz, _date.year, _date.month, _date.day, _startMin ~/ 60, _startMin % 60);

  Booking? get _draft {
    final room = _room;
    if (room == null) return null;
    final group = _group == null
        ? null
        : ref.read(adminGroupsProvider).value?.where((g) => g.group.id == _group).firstOrNull;
    return Booking(
      id: widget.existing?.id ?? '',
      orgId: widget.orgId,
      roomId: room,
      kind: _kind,
      startAt: _startAt,
      endAt: _startAt.add(Duration(minutes: _duration)),
      title: _title.text.trim(),
      coachId: _kind == BookingKind.maintenance ? null : _coach,
      groupId: _kind == BookingKind.maintenance ? null : _group,
      programId: _program,
      sportId: group?.group.sportId,
      expectedAttendees: _attendees ?? (group?.memberCount),
      seriesId: widget.existing?.seriesId,
      eventId: widget.existing?.eventId,
    );
  }

  Future<void> _preview() async {
    final d = _draft;
    if (d == null) return;
    try {
      final c = await ref
          .read(schedulingRepositoryProvider)
          .preview(d, ignoreIds: {if (widget.existing != null) widget.existing!.id});
      if (mounted) setState(() => _conflicts = c);
    } catch (_) {
      // Preview is advisory only.
    }
  }

  void _changed(VoidCallback f) {
    setState(() {
      f();
      _rejected = null;
    });
    _preview();
  }

  Future<void> _save({SeriesEditScope scope = SeriesEditScope.thisOccurrence}) async {
    final d = _draft;
    if (d == null) return;
    final l = context.l10n;
    setState(() => _busy = true);
    final repo = ref.read(schedulingRepositoryProvider);
    try {
      if (widget.existing == null && _recurring) {
        final rule = WeeklyRule(
          weekdays: _weekdays,
          startMinute: _startMin,
          durationMin: _duration,
          from: _date,
          until: _until,
        );
        await repo.createRecurring(d, rule, allowGroupOverlap: _allowGroupOverlap);
      } else if (widget.existing == null) {
        await repo.createBooking(d, allowGroupOverlap: _allowGroupOverlap);
      } else if (scope == SeriesEditScope.thisAndFuture) {
        await repo.updateSeriesFrom(d, startMinute: _startMin, durationMin: _duration, roomId: _room);
      } else {
        await repo.updateBooking(d, allowGroupOverlap: _allowGroupOverlap);
      }
      if (!mounted) return;
      showAppSnack(context, l.bookingSaved);
      Navigator.pop(context);
    } on BookingRejected catch (e) {
      if (mounted) setState(() => _rejected = e);
    } catch (e) {
      if (mounted) await runGuarded(context, () => Future<void>.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(SeriesEditScope scope) async {
    final ok = await runGuarded(
      context,
      () => ref.read(schedulingRepositoryProvider).cancelBooking(widget.existing!, scope: scope),
      success: context.l10n.bookingCancelled,
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final rooms = (ref.watch(roomsProvider(widget.orgId)).value ?? const <Room>[])
        .where((r) => r.status != RoomStatus.archived)
        .toList();
    final groups = (ref.watch(adminGroupsProvider).value ?? const <GroupOverview>[])
        .where((g) => g.group.clubId == widget.orgId)
        .toList();
    final coaches = (ref.watch(adminCoachesProvider).value ?? const <CoachSummary>[])
        .where((c) => c.clubIds.contains(widget.orgId))
        .toList();
    final programs = ref.watch(programsProvider(widget.orgId)).value ?? const <SportsProgram>[];
    final sportsById = ref.watch(sportsByIdProvider);
    String sportName(String id) => sportsById[id]?.label(context) ?? id;
    // v1.9: rooms already taken at the chosen time are shown (not hidden)
    // with the session that occupies them; the server still decides.
    final startAt = _startAt;
    final endAt = startAt.add(Duration(minutes: _duration));
    final busy = <String, String>{
      for (final b in _bookingIndex.values)
        if (b.orgId == widget.orgId &&
            b.isActive &&
            b.id != widget.existing?.id &&
            b.startAt.isBefore(endAt) &&
            b.endAt.isAfter(startAt))
          b.roomId: l.roomBusyWith(b.title, '${f.wt(b.startAt, _tz)}–${f.wt(b.endAt, _tz)}'),
    };
    final shown = _rejected?.conflicts ?? _conflicts;
    final blocked = ConflictChecker.isBlocked(shown);
    final groupWarning = shown.any((c) => c.code == ConflictCode.groupOverlap);
    final inSeries = widget.existing?.seriesId != null;
    return AlertDialog(
      key: const Key('booking-dialog'),
      title: Text(widget.existing == null ? l.bookingNew : l.bookingEdit),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  SizedBox(
                    width: 250,
                    child: DropdownButtonFormField<BookingKind>(
                      isExpanded: true,
                      key: const Key('booking-kind'),
                      initialValue: _kind,
                      decoration: InputDecoration(labelText: l.bookingKind),
                      items: [
                        for (final k in BookingKind.values)
                          DropdownMenuItem(value: k, child: Text(bookingKindLabel(context, k))),
                      ],
                      onChanged: (v) => _changed(() => _kind = v ?? _kind),
                    ),
                  ),
                  SizedBox(
                    width: 250,
                    child: AppPickerField<String>(
                      key: const Key('booking-room'),
                      label: l.roomLabel,
                      icon: Icons.meeting_room_rounded,
                      required: true,
                      value: _room,
                      options: roomOptions(context, rooms, sportName: sportName, busy: busy),
                      onChanged: (v) => _changed(() => _room = v),
                    ),
                  ),
                  SizedBox(
                    width: 512,
                    child: TextField(
                      key: const Key('booking-title'),
                      controller: _title,
                      decoration: InputDecoration(labelText: l.bookingTitle),
                    ),
                  ),
                  if (_kind != BookingKind.maintenance) ...[
                    SizedBox(
                      width: 250,
                      child: AppPickerField<String>(
                        key: const Key('booking-group'),
                        label: l.bookingGroup,
                        icon: Icons.groups_rounded,
                        value: _group ?? '',
                        options: [
                          AppPickerOption(value: '', label: l.none),
                          ...groupOptions(
                            context,
                            groups.map((g) => g.group),
                            sportName: sportName,
                            coachName: (id) => coaches.where((c) => c.id == id).firstOrNull?.fullName ?? '',
                            sportIconOf: (id) => sportsById[id]?.icon,
                          ),
                        ],
                        onChanged: (v) => _changed(() {
                          _group = v.isEmpty ? null : v;
                          final g = groups.where((x) => x.group.id == v).firstOrNull;
                          if (g != null && _coach == null && g.group.coachIds.isNotEmpty) {
                            _coach = g.group.coachIds.first;
                          }
                        }),
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: AppPickerField<String>(
                        key: const Key('booking-coach'),
                        label: l.bookingCoach,
                        icon: Icons.sports_rounded,
                        value: _coach ?? '',
                        options: [
                          AppPickerOption(value: '', label: l.none),
                          ...coachOptions(context, coaches, sportName: sportName),
                        ],
                        onChanged: (v) => _changed(() => _coach = v.isEmpty ? null : v),
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: AppPickerField<String>(
                        key: const Key('booking-program'),
                        label: l.adminNavPrograms,
                        icon: Icons.sports_handball_rounded,
                        value: _program ?? '',
                        options: [
                          AppPickerOption(value: '', label: l.none),
                          for (final p in programs)
                            AppPickerOption(value: p.id, label: p.name, subtitle: sportName(p.sportId)),
                        ],
                        onChanged: (v) => _changed(() => _program = v.isEmpty ? null : v),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    key: const Key('booking-date'),
                    icon: const Icon(Icons.event_rounded),
                    label: Text(f.wd(_startAt, _tz)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime(_date.year, _date.month, _date.day),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) _changed(() => _date = DateTime.utc(d.year, d.month, d.day));
                    },
                  ),
                  DropdownButton<int>(
                    key: const Key('booking-start'),
                    value: _startMin,
                    items: [
                      // The current value is always listed (an existing booking may start
                      // off the 15-minute grid or before 06:00).
                      for (final m in ({for (var m = 6 * 60; m <= 23 * 60; m += 15) m, _startMin}.toList()..sort()))
                        DropdownMenuItem(value: m, child: Text(_hm(m))),
                    ],
                    onChanged: (v) => _changed(() => _startMin = v ?? _startMin),
                  ),
                  DropdownButton<int>(
                    key: const Key('booking-duration'),
                    value: _duration,
                    items: [
                      for (final m in ({30, 45, 60, 75, 90, 105, 120, 150, 180, 240, _duration}.toList()..sort()))
                        DropdownMenuItem(value: m, child: Text(l.minutesShort(m))),
                    ],
                    onChanged: (v) => _changed(() => _duration = v ?? _duration),
                  ),
                  Text('→ ${_hm((_startMin + _duration) % 1440)}${_startMin + _duration >= 1440 ? ' (+1)' : ''}'),
                ],
              ),
              if (widget.existing == null) ...[
                SwitchListTile(
                  key: const Key('booking-recurring'),
                  contentPadding: EdgeInsets.zero,
                  value: _recurring,
                  title: Text(l.bookingRecurring),
                  onChanged: (v) => _changed(() => _recurring = v),
                ),
                if (_recurring) ...[
                  Wrap(
                    spacing: 4,
                    children: [
                      for (var d = 1; d <= 7; d++)
                        FilterChip(
                          key: Key('booking-weekday-$d'),
                          label: Text(f.weekdayShort(DateTime.utc(2024, 1, d))),
                          selected: _weekdays.contains(d),
                          onSelected: (v) => _changed(() => v ? _weekdays.add(d) : _weekdays.remove(d)),
                        ),
                    ],
                  ),
                  TextButton.icon(
                    key: const Key('booking-until'),
                    icon: const Icon(Icons.event_repeat_rounded),
                    label: Text(l.bookingUntil(f.dayMonth(_until))),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime(_until.year, _until.month, _until.day),
                        firstDate: DateTime(_date.year, _date.month, _date.day),
                        lastDate: DateTime(
                          _date.year,
                          _date.month,
                          _date.day,
                        ).add(const Duration(days: WeeklyRule.maxWeeks * 7)),
                      );
                      if (d != null) _changed(() => _until = DateTime.utc(d.year, d.month, d.day));
                    },
                  ),
                  Text(l.bookingSeriesNote(WeeklyRule.maxWeeks), style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
              if (shown.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  key: const Key('booking-conflicts'),
                  color: (blocked ? AppColors.danger : AppColors.warning).withValues(alpha: .08),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _rejected != null ? l.bookingRejected : l.bookingConflictsFound,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      for (final c in shown)
                        Text('• ${conflictLine(context, c, _tz)}', key: Key('conflict-${c.code.name}')),
                      if (_rejected?.alternatives.isNotEmpty ?? false) ...[
                        const SizedBox(height: 6),
                        Text(l.bookingTryInstead),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (final a in _rejected!.alternatives)
                              ActionChip(
                                key: Key('booking-alt-${a.millisecondsSinceEpoch}'),
                                // The date is shown: a suggestion may be on another day.
                                label: Text('${f.wd(a, _tz)} ${f.wt(a, _tz)}'),
                                onPressed: () => _changed(() {
                                  final w = OrgTimeZones.wall(a, _tz);
                                  _date = DateTime.utc(w.year, w.month, w.day);
                                  _startMin = w.hour * 60 + w.minute;
                                }),
                              ),
                          ],
                        ),
                      ],
                      if (_rejected?.freeRooms.isNotEmpty ?? false)
                        Wrap(
                          spacing: 6,
                          children: [
                            for (final r in _rejected!.freeRooms)
                              ActionChip(
                                key: Key('booking-free-room-${r.id}'),
                                avatar: const Icon(Icons.meeting_room_rounded, size: 16),
                                label: Text(r.name),
                                onPressed: () => _changed(() => _room = r.id),
                              ),
                          ],
                        ),
                      if (groupWarning && !blocked)
                        CheckboxListTile(
                          key: const Key('booking-allow-group'),
                          contentPadding: EdgeInsets.zero,
                          value: _allowGroupOverlap,
                          title: Text(l.bookingAllowGroupOverlap),
                          onChanged: (v) => setState(() => _allowGroupOverlap = v ?? false),
                        ),
                    ],
                  ),
                ),
              ],
              if (widget.existing != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      key: const Key('booking-cancel-one'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                      onPressed: () => _cancel(SeriesEditScope.thisOccurrence),
                      child: Text(inSeries ? l.bookingCancelOccurrence : l.bookingCancel),
                    ),
                    if (inSeries)
                      OutlinedButton(
                        key: const Key('booking-cancel-future'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                        onPressed: () => _cancel(SeriesEditScope.thisAndFuture),
                        child: Text(l.bookingCancelFuture),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close)),
        if (inSeries)
          OutlinedButton(
            key: const Key('booking-save-future'),
            onPressed: _busy ? null : () => _save(scope: SeriesEditScope.thisAndFuture),
            child: Text(l.bookingSaveFuture),
          ),
        FilledButton(
          key: const Key('booking-save'),
          onPressed: _busy || _room == null || (blocked && _rejected == null && _conflicts.isNotEmpty) ? null : _save,
          child: Text(inSeries ? l.bookingSaveOccurrence : l.save),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────── reports

class OrgReportsPage extends ConsumerStatefulWidget {
  const OrgReportsPage({super.key});

  @override
  ConsumerState<OrgReportsPage> createState() => _OrgReportsPageState();
}

class _OrgReportsPageState extends ConsumerState<OrgReportsPage> {
  int _tab = 0;
  int _days = 14;
  String? _group;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final org = ref.watch(adminOrgProvider);
    final now = ref.watch(clockProvider)();
    final repo = ref.watch(organizationsRepositoryProvider);
    final f = Fmt.of(context);
    final groups = (ref.watch(adminGroupsProvider).value ?? const <GroupOverview>[])
        .where((g) => g.group.clubId == org)
        .toList();
    final tz = org == null
        ? OrgTimeZones.tbilisi
        : ref.watch(orgConfigProvider(org)).value?.timezone ?? OrgTimeZones.tbilisi;
    return AdminSection(
      title: l.adminNavReports,
      actions: const [AdminOrgPicker()],
      child: org == null
          ? _needsOrg(context)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SegmentedButton<int>(
                      key: const Key('reports-tabs'),
                      segments: [
                        ButtonSegment(value: 0, label: Text(l.reportRsvp)),
                        ButtonSegment(value: 1, label: Text(l.reportAttendance)),
                        ButtonSegment(value: 2, label: Text(l.reportBrain)),
                      ],
                      selected: {_tab},
                      onSelectionChanged: (s) => setState(() => _tab = s.first),
                    ),
                    if (_tab < 2)
                      DropdownButton<int>(
                        value: _days,
                        items: [
                          for (final d in const [7, 14, 30, 90])
                            DropdownMenuItem(value: d, child: Text(l.reportDays(d))),
                        ],
                        onChanged: (v) => setState(() => _days = v ?? _days),
                      ),
                    if (_tab == 1)
                      DropdownButton<String?>(
                        key: const Key('report-group'),
                        value: _group,
                        hint: Text(l.reportAllGroups),
                        items: [
                          DropdownMenuItem(value: null, child: Text(l.reportAllGroups)),
                          for (final g in groups) DropdownMenuItem(value: g.group.id, child: Text(g.group.name)),
                        ],
                        onChanged: (v) => setState(() => _group = v),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                switch (_tab) {
                  0 => FutureBuilder<List<EventRsvpRow>>(
                    key: ValueKey('rsvp-$org-$_days'),
                    future: repo.rsvpReport(
                      org,
                      from: now,
                      to: now.add(Duration(days: _days)),
                    ),
                    builder: (context, s) => _report(
                      s,
                      (rows) => AdminTable<EventRsvpRow>(
                        rows: rows,
                        searchText: (r) => r.groupName,
                        columns: [
                          AdminColumn(
                            l.reportWhen,
                            (r) => Text(
                              '${f.wd(r.startAt, tz)} ${f.wt(r.startAt, tz)}',
                              key: Key('rsvp-row-${r.eventId}'),
                            ),
                            flex: 2,
                            sortKey: (r) => r.startAt,
                          ),
                          AdminColumn(l.adminColGroups, (r) => Text(r.groupName), flex: 2),
                          for (final st in RsvpState.values)
                            AdminColumn(rsvpStateLabel(context, st), (r) => Text('${r.counts[st] ?? 0}')),
                        ],
                      ),
                    ),
                  ),
                  1 => FutureBuilder<List<EventAttendanceRow>>(
                    key: ValueKey('att-$org-$_days-$_group'),
                    future: repo.attendanceReport(
                      org,
                      from: now.subtract(Duration(days: _days)),
                      to: now,
                      groupId: _group,
                    ),
                    builder: (context, s) => _report(
                      s,
                      (rows) => AdminTable<EventAttendanceRow>(
                        rows: rows,
                        searchText: (r) => r.groupName,
                        columns: [
                          AdminColumn(
                            l.reportWhen,
                            (r) =>
                                Text('${f.wd(r.startAt, tz)} ${f.wt(r.startAt, tz)}', key: Key('att-row-${r.eventId}')),
                            flex: 2,
                            sortKey: (r) => r.startAt,
                          ),
                          AdminColumn(l.adminColGroups, (r) => Text(r.groupName), flex: 2),
                          AdminColumn(l.attendancePresent, (r) => Text('${r.present}')),
                          AdminColumn(l.attendanceAbsent, (r) => Text('${r.absent}')),
                          AdminColumn(l.attendanceExcused, (r) => Text('${r.excused}')),
                          AdminColumn(l.attendanceNotMarked, (r) => Text('${r.unmarked}')),
                        ],
                      ),
                    ),
                  ),
                  _ => FutureBuilder<List<BrainSummaryRow>>(
                    key: ValueKey('brain-$org'),
                    future: repo.brainSummary(org),
                    builder: (context, s) => _report(
                      s,
                      (rows) => AdminTable<BrainSummaryRow>(
                        rows: rows,
                        searchText: (r) => r.displayName,
                        columns: [
                          AdminColumn(
                            l.adminColName,
                            (r) => Text(r.displayName, key: Key('brain-row-${r.childId}')),
                            flex: 2,
                          ),
                          AdminColumn(l.adminColGroups, (r) => Text(r.groupNames.join(', ')), flex: 3),
                          AdminColumn(l.pointsTotal, (r) => Text('${r.points}'), sortKey: (r) => r.points),
                          AdminColumn(l.pointsGamesCompleted, (r) => Text('${r.gamesCompleted}')),
                          AdminColumn(
                            l.reportLastPlayed,
                            (r) => Text(r.lastPlayed == null ? '—' : f.wdm(r.lastPlayed!, tz)),
                          ),
                        ],
                      ),
                    ),
                  ),
                },
              ],
            ),
    );
  }

  Widget _report<T>(AsyncSnapshot<List<T>> s, Widget Function(List<T>) table) {
    if (s.hasError) return ErrorView(error: s.error!);
    if (!s.hasData) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return table(s.data!);
  }
}
