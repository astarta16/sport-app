import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../core/errors/app_exception.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_picker.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/entity_options.dart';
import '../../core/widgets/unsaved_changes_guard.dart';
import '../../features/admin/domain/admin_models.dart';
import '../../features/authentication/domain/app_user.dart';
import '../../features/clubs/presentation/clubs_providers.dart';
import '../../features/groups/domain/group.dart';
import '../../features/organizations/domain/organization.dart';
import '../../features/organizations/presentation/org_providers.dart';
import '../../features/sports/presentation/sport_label.dart';
import '../../features/sports/presentation/sports_providers.dart';
import 'admin_providers.dart';

/// v1.9.1 — an organization admin creates and runs their own groups:
/// sport/program → name & ages → coaches → capacity → review.
Future<void> showGroupWizard(BuildContext context, WidgetRef ref, String orgId) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _GroupWizard(orgId: orgId),
);

class _GroupWizard extends ConsumerStatefulWidget {
  const _GroupWizard({required this.orgId});

  final String orgId;

  @override
  ConsumerState<_GroupWizard> createState() => _GroupWizardState();
}

class _GroupWizardState extends ConsumerState<_GroupWizard> {
  int _step = 0;
  String? _programId;
  String? _sportId;
  final _name = TextEditingController();
  final _note = TextEditingController();
  final _capacity = TextEditingController();
  RangeValues _ages = const RangeValues(6, 12);
  Set<String> _coaches = {};
  final _tried = <int>{};
  bool _busy = false;
  String? _error;

  bool get _dirty => _sportId != null || _name.text.isNotEmpty || _coaches.isNotEmpty;

  int? get _cap => _capacity.text.trim().isEmpty ? null : int.tryParse(_capacity.text.trim());

  String? _stepError(int step) {
    final l = context.l10n;
    return switch (step) {
      0 => _sportId == null ? l.a191ChooseSport : null,
      1 => _name.text.trim().length < 2 ? l.validationGroupNameRequired : null,
      2 => _coaches.isEmpty ? l.a191ChooseCoach : null,
      3 =>
        _capacity.text.trim().isNotEmpty && (_cap == null || _cap! < 1 || _cap! > 500) ? l.a191ErrGroupCapacity : null,
      _ => null,
    };
  }

  void _next() {
    final e = _stepError(_step);
    if (e != null) {
      setState(() {
        _tried.add(_step);
        _error = e;
      });
      return;
    }
    setState(() {
      _error = null;
      _step++;
    });
  }

  Future<void> _create() async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final g = await ref
          .read(groupsRepositoryProvider)
          .createGroup(
            GroupDraft(
              clubId: widget.orgId,
              sportId: _sportId!,
              name: _name.text.trim(),
              ageMin: _ages.start.round(),
              ageMax: _ages.end.round(),
              scheduleNote: _note.text.trim().isEmpty ? null : _note.text.trim(),
              coachIds: _coaches.toList(),
              capacity: _cap,
            ),
          );
      // Keep the program's group list in step (programs are optional).
      final programs = ref.read(programsProvider(widget.orgId)).value ?? const <SportsProgram>[];
      final p = programs.where((x) => x.id == _programId).firstOrNull;
      if (p != null) {
        await ref.read(organizationsRepositoryProvider).upsertProgram(p.copyWith(groupIds: [...p.groupIds, g.id]));
      }
      if (!mounted) return;
      Navigator.pop(context);
      showAppSnack(context, l.a191GroupCreated(g.name));
    } catch (e) {
      // Input is kept; the admin can fix and retry.
      if (mounted) setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final club = ref.watch(clubsByIdProvider)[widget.orgId];
    final sportsById = ref.watch(sportsByIdProvider);
    final sports = ref.watch(sportsProvider).value ?? const [];
    String sportName(String id) => sportsById[id]?.label(context) ?? id;
    final programs = (ref.watch(programsProvider(widget.orgId)).value ?? const <SportsProgram>[])
        .where((p) => p.status == ProgramStatus.active)
        .toList();
    final coaches = (ref.watch(adminCoachesProvider).value ?? const <CoachSummary>[])
        .where((c) => c.clubIds.contains(widget.orgId) && c.status == CoachStatus.approved)
        .toList();
    String? err(int s) => _tried.contains(s) ? _stepError(s) : null;
    final steps = [l.a191StepSport, l.a191StepName, l.a191StepCoach, l.a191StepCapacity, l.wizReview];
    final body = switch (_step) {
      0 => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (programs.isNotEmpty) ...[
            AppPickerField<String>(
              key: const Key('gw-program'),
              label: l.a191FromProgram,
              helperText: l.a191FromProgramHint,
              icon: Icons.sports_handball_rounded,
              value: _programId,
              options: [
                for (final p in programs)
                  AppPickerOption(
                    value: p.id,
                    label: p.name,
                    subtitle: '${sportName(p.sportId)} · ${p.ageMin}–${p.ageMax}',
                  ),
              ],
              onChanged: (id) => setState(() {
                final p = programs.firstWhere((x) => x.id == id);
                _programId = id;
                _sportId = p.sportId;
                _ages = RangeValues(p.ageMin.toDouble().clamp(3, 18), p.ageMax.toDouble().clamp(3, 18));
                if (_coaches.isEmpty) _coaches = p.coachIds.where((c) => coaches.any((x) => x.id == c)).toSet();
                if (_capacity.text.isEmpty && p.capacity > 0) _capacity.text = '${p.capacity}';
                if (_note.text.isEmpty) _note.text = p.scheduleNote;
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          SportsPickerField(
            sports: sports,
            allowedIds: club == null || club.sportIds.isEmpty ? null : club.sportIds.toSet(),
            value: _sportId ?? '',
            required: true,
            errorText: err(0),
            onChanged: (v) => setState(() => _sportId = v),
          ),
        ],
      ),
      1 => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('gw-name'),
            controller: _name,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: '${l.a191GroupName} *',
              hintText: l.a191GroupNameHint,
              errorText: err(1),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l.a191Ages(_ages.start.round(), _ages.end.round()), style: Theme.of(context).textTheme.titleSmall),
          RangeSlider(
            key: const Key('gw-ages'),
            min: 3,
            max: 18,
            divisions: 15,
            labels: RangeLabels('${_ages.start.round()}', '${_ages.end.round()}'),
            values: _ages,
            onChanged: (v) => setState(() => _ages = v),
          ),
        ],
      ),
      2 => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (coaches.isEmpty)
            AppFeedbackBanner(
              key: const Key('gw-no-coaches'),
              tone: FeedbackTone.warning,
              message: l.a191NoCoachesYet,
              actionLabel: l.featureOffOpenSettings,
              onAction: () {
                Navigator.pop(context);
                context.go('/org-settings');
              },
            )
          else
            AppPickerField<String>.multi(
              key: const Key('gw-coaches'),
              label: l.a191Coaches,
              icon: Icons.sports_rounded,
              required: true,
              errorText: err(2),
              values: _coaches,
              options: coachOptions(context, coaches, sportName: sportName),
              onChangedMulti: (v) => setState(() => _coaches = v),
            ),
        ],
      ),
      3 => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('gw-capacity'),
            controller: _capacity,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l.a191Capacity, helperText: l.a191CapacityHint, errorText: err(3)),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const Key('gw-note'),
            controller: _note,
            decoration: InputDecoration(labelText: l.a191ScheduleNote, hintText: l.a191ScheduleNoteHint),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l.a191RoomLater, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      _ => Column(
        key: const Key('gw-review'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (label, value, step) in [
            (
              l.a191StepSport,
              [
                ?programs.where((p) => p.id == _programId).firstOrNull?.name,
                if (_sportId != null) sportName(_sportId!),
              ].join(' · '),
              0,
            ),
            (l.a191GroupName, '${_name.text.trim()} · ${l.a191Ages(_ages.start.round(), _ages.end.round())}', 1),
            (l.a191Coaches, coaches.where((c) => _coaches.contains(c.id)).map((c) => c.fullName).join(', '), 2),
            (l.a191Capacity, _cap == null ? l.a191NoLimit : '$_cap', 3),
          ])
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(label, style: Theme.of(context).textTheme.labelLarge),
              subtitle: Text(value.isEmpty ? '—' : value),
              trailing: TextButton(onPressed: () => setState(() => _step = step), child: Text(l.edit)),
            ),
          Text(l.a191AfterCreate, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    };
    return UnsavedChangesGuard(
      dirty: _dirty && !_busy,
      child: AlertDialog(
        key: const Key('group-wizard'),
        title: Text(l.newGroup),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppStepHeader(steps: steps, current: _step, onStep: (i) => setState(() => _step = i)),
                const SizedBox(height: AppSpacing.md),
                body,
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppFeedbackBanner(key: const Key('gw-error'), tone: FeedbackTone.error, message: _error!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    if (!_dirty || await confirmDiscard(context)) {
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
            child: Text(l.cancel),
          ),
          if (_step > 0) TextButton(onPressed: _busy ? null : () => setState(() => _step--), child: Text(l.back)),
          if (_step < 4)
            FilledButton(key: const Key('gw-next'), onPressed: _next, child: Text(l.next))
          else
            FilledButton(
              key: const Key('gw-create'),
              onPressed: _busy ? null : _create,
              child: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.a191CreateGroup),
            ),
        ],
      ),
    );
  }
}

/// Edit name, coaches, ages and capacity of a group (organization admin).
Future<void> showGroupEditDialog(BuildContext context, WidgetRef ref, Group g) => showDialog<void>(
  context: context,
  builder: (_) => _GroupEditDialog(group: g),
);

class _GroupEditDialog extends ConsumerStatefulWidget {
  const _GroupEditDialog({required this.group});

  final Group group;

  @override
  ConsumerState<_GroupEditDialog> createState() => _GroupEditDialogState();
}

class _GroupEditDialogState extends ConsumerState<_GroupEditDialog> {
  late final _name = TextEditingController(text: widget.group.name);
  late final _capacity = TextEditingController(text: widget.group.capacity?.toString() ?? '');
  late RangeValues _ages = RangeValues(
    widget.group.ageMin.toDouble().clamp(3, 18),
    widget.group.ageMax.toDouble().clamp(3, 18),
  );
  late Set<String> _coaches = {...widget.group.coachIds};
  bool _busy = false;
  String? _error;

  bool get _dirty =>
      _name.text.trim() != widget.group.name ||
      _capacity.text.trim() != (widget.group.capacity?.toString() ?? '') ||
      _ages.start.round() != widget.group.ageMin ||
      _ages.end.round() != widget.group.ageMax ||
      _coaches.length != widget.group.coachIds.length ||
      !_coaches.containsAll(widget.group.coachIds);

  Future<void> _save() async {
    final l = context.l10n;
    final cap = _capacity.text.trim().isEmpty ? null : int.tryParse(_capacity.text.trim());
    if (_name.text.trim().length < 2) return setState(() => _error = l.validationGroupNameRequired);
    if (_capacity.text.trim().isNotEmpty && (cap == null || cap < 1 || cap > 500)) {
      return setState(() => _error = l.a191ErrGroupCapacity);
    }
    if (_coaches.isEmpty) return setState(() => _error = l.a191ChooseCoach);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateGroupDetails(
            widget.group.id,
            name: _name.text.trim(),
            coachIds: _coaches.toList(),
            ageMin: _ages.start.round(),
            ageMax: _ages.end.round(),
            capacity: cap,
            clearCapacity: cap == null && widget.group.capacity != null,
          );
      if (!mounted) return;
      Navigator.pop(context);
      showAppSnack(context, l.a191GroupSaved);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sportsById = ref.watch(sportsByIdProvider);
    final coaches = (ref.watch(adminCoachesProvider).value ?? const <CoachSummary>[])
        .where((c) => c.clubIds.contains(widget.group.clubId) && c.status == CoachStatus.approved)
        .toList();
    return UnsavedChangesGuard(
      dirty: _dirty && !_busy,
      child: AlertDialog(
        key: const Key('group-edit'),
        title: Text(l.a191EditGroup),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('ge-name'),
                  controller: _name,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(labelText: '${l.a191GroupName} *'),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppPickerField<String>.multi(
                  key: const Key('ge-coaches'),
                  label: l.a191Coaches,
                  required: true,
                  values: _coaches,
                  options: coachOptions(context, coaches, sportName: (s) => sportsById[s]?.label(context) ?? s),
                  onChangedMulti: (v) => setState(() => _coaches = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l.a191Ages(_ages.start.round(), _ages.end.round())),
                RangeSlider(min: 3, max: 18, divisions: 15, values: _ages, onChanged: (v) => setState(() => _ages = v)),
                TextField(
                  key: const Key('ge-capacity'),
                  controller: _capacity,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(labelText: l.a191Capacity, helperText: l.a191CapacityHint),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppFeedbackBanner(key: const Key('ge-error'), tone: FeedbackTone.error, message: _error!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    if (!_dirty || await confirmDiscard(context)) {
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('ge-save'),
            onPressed: _busy || !_dirty ? null : _save,
            child: Text(l.saveChanges),
          ),
        ],
      ),
    );
  }
}

/// Members of a group: minimal roster (remove with confirmation) and
/// guardian invitations — a child joins only when the guardian accepts.
Future<void> showGroupMembersDialog(BuildContext context, WidgetRef ref, Group g) => showDialog<void>(
  context: context,
  builder: (_) => _GroupMembersDialog(group: g),
);

final _rosterProvider = FutureProvider.autoDispose.family<List<AdminRosterEntry>, String>((ref, groupId) {
  ref.watch(adminGroupsProvider);
  return ref.watch(adminRepositoryProvider).groupRoster(groupId);
});

final _groupInvitesProvider = StreamProvider.autoDispose.family<List<GroupInvite>, String>(
  (ref, groupId) => ref.watch(groupsRepositoryProvider).watchGroupInvites(groupId),
);

class _GroupMembersDialog extends ConsumerStatefulWidget {
  const _GroupMembersDialog({required this.group});

  final Group group;

  @override
  ConsumerState<_GroupMembersDialog> createState() => _GroupMembersDialogState();
}

class _GroupMembersDialogState extends ConsumerState<_GroupMembersDialog> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  DateTime? _birth;
  bool _busy = false;
  String? _error;

  Future<void> _invite() async {
    final l = context.l10n;
    if (_first.text.trim().isEmpty || _phone.text.trim().isEmpty || _birth == null) {
      return setState(() => _error = l.a191InviteFieldsRequired);
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(groupsRepositoryProvider)
          .invitePendingChild(
            groupId: widget.group.id,
            child: PendingChildDraft(
              firstName: _first.text.trim(),
              lastName: _last.text.trim(),
              birthDate: _birth!,
              parentPhone: _phone.text.trim(),
            ),
          );
      if (!mounted) return;
      _first.clear();
      _last.clear();
      _phone.clear();
      setState(() => _birth = null);
      showAppSnack(context, l.a191InviteSent);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final g = widget.group;
    final invites = ref.watch(_groupInvitesProvider(g.id)).value ?? const <GroupInvite>[];
    return AlertDialog(
      key: const Key('group-members'),
      title: Text('${l.adminColMembers} · ${g.name}'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                g.capacity == null
                    ? l.a191MembersCount(g.memberChildIds.length)
                    : l.a191MembersOfCapacity(g.memberChildIds.length, g.capacity!),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(l.a191RosterPrivacy, style: Theme.of(context).textTheme.bodySmall),
              AsyncView<List<AdminRosterEntry>>(
                value: ref.watch(_rosterProvider(g.id)),
                compact: true,
                onRetry: () => ref.invalidate(_rosterProvider(g.id)),
                data: (rows) => rows.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Text(l.a191NoMembersYet),
                      )
                    : Column(
                        children: [
                          for (final r in rows)
                            ListTile(
                              key: Key('gm-row-${r.childId}'),
                              dense: true,
                              leading: InitialsAvatar(name: r.displayName, size: 32),
                              title: Text(r.displayName),
                              subtitle: Text(l.birthYearShort(r.birthYear)),
                              trailing: IconButton(
                                key: Key('gm-remove-${r.childId}'),
                                tooltip: l.a191RemoveFromGroup,
                                icon: const Icon(Icons.person_remove_rounded),
                                onPressed: () async {
                                  final ok = await confirmDialog(
                                    context,
                                    title: l.a191RemoveFromGroup,
                                    message: l.a191RemoveFromGroupBody(r.displayName, g.name),
                                    confirmLabel: l.a191RemoveFromGroup,
                                    destructive: true,
                                  );
                                  if (!ok || !context.mounted) return;
                                  final done = await runGuarded(
                                    context,
                                    () => ref.read(adminRepositoryProvider).removeGroupMember(g.id, r.childId),
                                    success: l.a191RemovedSnack,
                                  );
                                  if (done) ref.invalidate(_rosterProvider(g.id));
                                },
                              ),
                            ),
                        ],
                      ),
              ),
              const Divider(),
              AppFormSection(
                title: l.a191InviteGuardian,
                hint: l.a191InviteGuardianHint,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: 170,
                        child: TextField(
                          key: const Key('gm-first'),
                          controller: _first,
                          decoration: InputDecoration(labelText: '${l.firstName} *'),
                        ),
                      ),
                      SizedBox(
                        width: 170,
                        child: TextField(
                          key: const Key('gm-last'),
                          controller: _last,
                          decoration: InputDecoration(labelText: l.lastName),
                        ),
                      ),
                      SizedBox(
                        width: 170,
                        child: OutlinedButton.icon(
                          key: const Key('gm-birth'),
                          icon: const Icon(Icons.cake_rounded),
                          label: Text(_birth == null ? '${l.birthDate} *' : f.fullDate(_birth!)),
                          onPressed: () async {
                            final now = DateTime.now();
                            final d = await showDatePicker(
                              context: context,
                              initialDate: DateTime(now.year - 8),
                              firstDate: DateTime(now.year - 19),
                              lastDate: now,
                            );
                            if (d != null) setState(() => _birth = d);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        child: TextField(
                          key: const Key('gm-phone'),
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(labelText: '${l.a191GuardianPhone} *'),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null)
                    AppFeedbackBanner(key: const Key('gm-error'), tone: FeedbackTone.error, message: _error!),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      key: const Key('gm-invite'),
                      onPressed: _busy || g.isFull ? null : _invite,
                      icon: const Icon(Icons.send_rounded),
                      label: Text(g.isFull ? l.a191ErrGroupFull : l.a191SendInvite),
                    ),
                  ),
                ],
              ),
              if (invites.isNotEmpty) ...[
                Text(l.a191Invitations, style: Theme.of(context).textTheme.titleSmall),
                for (final i in invites)
                  ListTile(
                    key: Key('gm-invite-${i.id}'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${i.childFirstName} ${i.childLastName}'.trim()),
                    subtitle: Text(f.dateTime(i.createdAt)),
                    trailing: StatusPill(
                      label: switch (i.status) {
                        InviteStatus.sent => l.a191InviteWaiting,
                        InviteStatus.accepted => l.a191InviteAccepted,
                        InviteStatus.declined => l.a191InviteDeclined,
                        InviteStatus.revoked => l.a191InviteRevoked,
                      },
                      color: switch (i.status) {
                        InviteStatus.sent => AppColors.warning,
                        InviteStatus.accepted => AppColors.success,
                        _ => AppColors.neutral,
                      },
                      dense: true,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close))],
    );
  }
}

/// Validation codes from the group repositories, for tests and snackbars.
bool isGroupFull(Object e) => e is ValidationException && e.code == 'groupFull';
