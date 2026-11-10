import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/form_fields.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../clubs/presentation/clubs_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../sports/presentation/sports_providers.dart';
import '../../trainings/domain/series.dart';
import '../../trainings/presentation/series_form_screen.dart';

/// Top of the coach's group page: invite code, add-child entry points,
/// recurring schedules and sent invitations (v1.1 §2, v1.2).
class GroupManagementHeader extends ConsumerWidget {
  const GroupManagementHeader({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final group = ref.watch(groupsByIdProvider)[groupId];
    if (group == null) return const SizedBox.shrink();
    final series = ref.watch(seriesForGroupProvider(groupId)).value ?? const <TrainingSeries>[];
    final active = series.where((s) => s.status == SeriesStatus.active).toList();
    final invites = ref.watch(groupInvitesProvider(groupId)).value ?? const <GroupInvite>[];
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          key: const Key('group-code-card'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.groupCode, style: t.labelMedium),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      group.inviteCode.isEmpty ? '—' : group.inviteCode,
                      key: const Key('group-code'),
                      style: t.headlineMedium?.copyWith(letterSpacing: 6, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    tooltip: l.copy,
                    onPressed: group.inviteCode.isEmpty
                        ? null
                        : () async {
                            await Clipboard.setData(
                              ClipboardData(text: l.groupCodeShareText(group.name, group.inviteCode)),
                            );
                            if (context.mounted) showAppSnack(context, l.copied);
                          },
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
              Text(l.groupCodeHint, style: t.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  FilledButton.icon(
                    key: const Key('invite-child'),
                    onPressed: () => context.push(Routes.inviteChild(groupId)),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(l.addChildToGroup),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push(Routes.newSeries(groupId)),
                    icon: const Icon(Icons.event_repeat_rounded),
                    label: Text(l.addSeries),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push(Routes.newMatch(groupId)),
                    icon: const Icon(Icons.emoji_events_rounded),
                    label: Text(l.addMatch),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push(Routes.groupPayments(groupId)),
                    icon: const Icon(Icons.payments_rounded),
                    label: Text(l.paymentsTitle),
                  ),
                ],
              ),
            ],
          ),
        ),
        SectionHeader(l.seriesTitle),
        if (active.isEmpty)
          Text(l.seriesNone, style: t.bodySmall)
        else
          for (final s in active)
            AppCard(
              key: Key('series-${s.id}'),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.event_repeat_rounded),
                title: Text(seriesSummary(context, s)),
                subtitle: Text(
                  [
                    Fmt.of(context).dayMonth(s.startDate.toDateTime()),
                    if (s.endDate != null) Fmt.of(context).dayMonth(s.endDate!.toDateTime()),
                  ].join(' – '),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    final today = LocalDate.tbilisi(ref.read(clockProvider)());
                    if (v == 'edit') {
                      context.push(Routes.editSeries(s.id, today.toString()));
                    } else if (v == 'end') {
                      final ok = await confirmDialog(
                        context,
                        title: l.seriesEndAction,
                        message: l.seriesEndConfirm,
                        confirmLabel: l.seriesEndAction,
                        destructive: true,
                      );
                      if (ok && context.mounted) {
                        await runGuarded(
                          context,
                          () => ref.read(trainingsRepositoryProvider).endSeries(s.id, lastDate: today),
                          success: l.seriesEnded,
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(l.seriesEdit)),
                    PopupMenuItem(value: 'end', child: Text(l.seriesEndAction)),
                  ],
                ),
              ),
            ),
        if (invites.isNotEmpty) ...[
          SectionHeader(l.invitesSent),
          for (final i in invites.take(10))
            ListTile(
              key: Key('invite-${i.id}'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline_rounded),
              title: Text(i.childName),
              subtitle: Text(Validators.maskPhone(i.phone)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusPill(label: _inviteStatus(context, i.status), color: _inviteColor(i.status), dense: true),
                  if (i.status == InviteStatus.sent)
                    IconButton(
                      tooltip: l.inviteRevoke,
                      onPressed: () => runGuarded(context, () => ref.read(groupsRepositoryProvider).revokeInvite(i.id)),
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
            ),
        ],
        SectionHeader(l.roster),
      ],
    );
  }
}

String _inviteStatus(BuildContext context, InviteStatus s) {
  final l = context.l10n;
  return switch (s) {
    InviteStatus.sent => l.inviteStatusSent,
    InviteStatus.accepted => l.inviteStatusAccepted,
    InviteStatus.declined => l.inviteStatusDeclined,
    InviteStatus.revoked => l.inviteStatusRevoked,
  };
}

Color _inviteColor(InviteStatus s) => switch (s) {
  InviteStatus.sent => AppColors.blue,
  InviteStatus.accepted => AppColors.success,
  InviteStatus.declined || InviteStatus.revoked => AppColors.neutral,
};

/// Coach adds a child: by search (registered child → parent invitation) or
/// manually (pending child, parent invited by phone). Never links anything
/// automatically; the parent confirms.
class InviteChildScreen extends ConsumerStatefulWidget {
  const InviteChildScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<InviteChildScreen> createState() => _InviteChildScreenState();
}

class _InviteChildScreenState extends ConsumerState<InviteChildScreen> {
  final _query = TextEditingController();
  List<ChildSearchResult> _results = const [];
  bool _searching = false;
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  DateTime? _birth;
  bool _saving = false;
  List<String> _errors = const [];

  @override
  void dispose() {
    for (final c in [_query, _first, _last, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _searching = true);
    try {
      final r = await ref.read(groupsRepositoryProvider).searchChildren(_query.text, groupId: widget.groupId);
      if (mounted) setState(() => _results = r);
    } catch (e) {
      if (mounted) showAppSnack(context, errorText(context, e), error: true);
    }
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _inviteManual() async {
    final l = context.l10n;
    final errors = [
      ?Validators.name(_first.text),
      ?Validators.name(_last.text),
      ?Validators.phone(_phone.text),
      if (_birth == null) 'required',
    ];
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    setState(() => _saving = true);
    final ok = await runGuarded(
      context,
      () => ref
          .read(groupsRepositoryProvider)
          .invitePendingChild(
            groupId: widget.groupId,
            child: PendingChildDraft(
              firstName: _first.text,
              lastName: _last.text,
              birthDate: _birth!,
              parentPhone: _phone.text,
            ),
          ),
      success: l.inviteSent,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = ref.watch(clockProvider)();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.addChildTitle),
          bottom: TabBar(
            tabs: [
              Tab(key: const Key('tab-search'), text: l.addChildBySearch),
              Tab(key: const Key('tab-manual'), text: l.addChildManual),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ConstrainedContent(
              maxWidth: Breakpoints.readable,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(l.addChildSearchNote, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const Key('child-search'),
                    controller: _query,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: l.addChildSearchHint,
                      suffixIcon: IconButton(onPressed: _search, icon: const Icon(Icons.search_rounded)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_searching) const LinearProgressIndicator(),
                  if (!_searching && _results.isEmpty && _query.text.length >= 2) Text(l.noSearchResults),
                  for (final r in _results)
                    ListTile(
                      key: Key('search-${r.childId}'),
                      leading: InitialsAvatar(name: r.fullName, size: 36),
                      title: Text(r.fullName),
                      subtitle: Text(l.birthYearShort(r.birthYear)),
                      trailing: FilledButton.tonal(
                        key: Key('invite-${r.childId}'),
                        onPressed: () async {
                          final ok = await runGuarded(
                            context,
                            () => ref
                                .read(groupsRepositoryProvider)
                                .inviteExistingChild(groupId: widget.groupId, childId: r.childId),
                            success: l.inviteSent,
                          );
                          if (ok && context.mounted) context.pop();
                        },
                        child: Text(l.send),
                      ),
                    ),
                ],
              ),
            ),
            ConstrainedContent(
              maxWidth: Breakpoints.readable,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(l.addChildManualNote, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const Key('pending-first'),
                    controller: _first,
                    decoration: InputDecoration(labelText: l.firstName),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    key: const Key('pending-last'),
                    controller: _last,
                    decoration: InputDecoration(labelText: l.lastName),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  PickerField(
                    key: const Key('pending-birth'),
                    icon: Icons.cake_rounded,
                    label: _birth == null ? l.birthDateLabel : Fmt.of(context).fullDate(_birth!),
                    filled: _birth != null,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _birth ?? DateTime(now.year - 9),
                        firstDate: DateTime(now.year - 18),
                        lastDate: DateTime(now.year - 3),
                      );
                      if (d != null) setState(() => _birth = d);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    key: const Key('pending-phone'),
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: l.parentPhone, prefixText: '+995 '),
                  ),
                  FormErrors(errors: _errors),
                  const SizedBox(height: AppSpacing.md),
                  LoadingButton(
                    key: const Key('pending-invite'),
                    label: l.send,
                    loading: _saving,
                    onPressed: _inviteManual,
                    icon: Icons.send_rounded,
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

/// Coach creates a group in one of their clubs (v1.1 §2).
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  String? _clubId;
  String? _sportId;
  final _name = TextEditingController();
  RangeValues _ages = const RangeValues(8, 10);
  bool _saving = false;
  List<String> _errors = const [];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final draft = GroupDraft(
      clubId: _clubId ?? '',
      sportId: _sportId ?? '',
      name: _name.text,
      ageMin: _ages.start.round(),
      ageMax: _ages.end.round(),
    );
    final errors = [
      if (_clubId == null) 'clubRequired',
      if (_sportId == null) 'sportRequired',
      ...GroupDraft.validate(draft),
    ];
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    setState(() => _saving = true);
    try {
      final g = await ref.read(groupsRepositoryProvider).createGroup(draft);
      if (!mounted) return;
      showAppSnack(context, l.groupCreated(g.inviteCode));
      context.pushReplacement(Routes.roster(g.id));
    } catch (e) {
      if (mounted) showAppSnack(context, errorText(context, e), error: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final me = ref.watch(currentUserProvider);
    final clubs = (ref.watch(clubsProvider).value ?? const [])
        .where((c) => me?.clubIds.contains(c.id) ?? false)
        .toList();
    final sports = ref.watch(sportsProvider).value ?? const [];
    final club = clubs.where((c) => c.id == _clubId).firstOrNull ?? (clubs.length == 1 ? clubs.first : null);
    _clubId ??= club?.id;
    final clubSports = sports.where((s) => club == null || club.sportIds.contains(s.id)).toList();
    return Scaffold(
      appBar: AppBar(title: Text(l.newGroup)),
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SectionHeader(l.groupClub),
            DropdownButtonFormField<String>(
              initialValue: _clubId,
              isExpanded: true,
              items: [for (final c in clubs) DropdownMenuItem(value: c.id, child: Text(c.name))],
              onChanged: (v) => setState(() {
                _clubId = v;
                _sportId = null;
              }),
            ),
            SectionHeader(l.groupSport),
            DropdownButtonFormField<String>(
              key: const Key('group-sport'),
              initialValue: clubSports.any((s) => s.id == _sportId) ? _sportId : null,
              isExpanded: true,
              items: [for (final s in clubSports) DropdownMenuItem(value: s.id, child: Text(s.name))],
              onChanged: (v) => setState(() => _sportId = v),
            ),
            SectionHeader(l.groupName),
            TextField(key: const Key('group-name'), controller: _name, maxLength: 60),
            SectionHeader('${l.groupAgeFrom} ${_ages.start.round()} · ${l.groupAgeTo} ${_ages.end.round()}'),
            RangeSlider(
              values: _ages,
              min: 3,
              max: 18,
              divisions: 15,
              labels: RangeLabels('${_ages.start.round()}', '${_ages.end.round()}'),
              onChanged: (v) => setState(() => _ages = v),
            ),
            FormErrors(errors: _errors),
            const SizedBox(height: AppSpacing.md),
            LoadingButton(
              key: const Key('group-create'),
              label: l.create,
              loading: _saving,
              onPressed: _save,
              icon: Icons.group_add_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
