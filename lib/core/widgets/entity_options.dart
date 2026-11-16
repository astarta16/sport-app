import 'package:flutter/material.dart';

import '../../features/admin/domain/admin_models.dart';
import '../../features/children/domain/child.dart';
import '../../features/groups/domain/group.dart';
import '../../features/organizations/domain/organization.dart';
import '../../features/organizations/domain/scheduling.dart';
import '../../features/sports/domain/sport.dart';
import '../../features/sports/presentation/sport_label.dart';
import '../l10n/l10n.dart';
import 'app_picker.dart';
import 'app_widgets.dart';

/// Option builders for [AppPickerField] / [showAppPicker] — one place that
/// decides how a sport, coach, group, room, student or organization is
/// presented in every selector (v1.9 design system).
///
/// Builders only format what the caller passes; callers pass entities that
/// are already scoped to the current, authorized organization.

/// Sports by stable id (never duplicated by language), sorted by localized
/// name, with icon. [allowedIds] restricts to the organization's sports.
List<AppPickerOption<String>> sportOptions(BuildContext context, Iterable<Sport> sports, {Set<String>? allowedIds}) {
  // One option per stable id; names from duplicate records are merged so a
  // sport is never listed twice and every language stays searchable.
  final byId = <String, Sport>{};
  final names = <String, Set<String>>{};
  for (final s in sports) {
    if (!s.active || (allowedIds != null && !allowedIds.contains(s.id))) continue;
    byId.putIfAbsent(s.id, () => s);
    (names[s.id] ??= {}).addAll([s.name, ...s.names.values]);
  }
  final list = [
    for (final s in byId.values)
      AppPickerOption<String>(
        value: s.id,
        label: s.label(context),
        leading: SportBadge(sportKey: s.icon, size: 36),
        // Every language's name is searchable (a Russian speaker can type
        // "Волейбол" in a Georgian UI).
        searchText: '${s.id} ${names[s.id]!.join(' ')}',
      ),
  ];
  list.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  return list;
}

/// Coaches of the current organization with their sports and group count.
List<AppPickerOption<String>> coachOptions(
  BuildContext context,
  Iterable<CoachSummary> coaches, {
  required String Function(String sportId) sportName,
  Map<String, String> busyReason = const {},
}) {
  final l = context.l10n;
  final list = [
    for (final c in coaches)
      AppPickerOption<String>(
        value: c.id,
        label: c.fullName,
        subtitle: [
          if (c.sportIds.isNotEmpty) c.sportIds.map(sportName).join(', '),
          l.groupsCount(c.groupCount),
        ].join(' · '),
        leading: InitialsAvatar(name: c.fullName, size: 36),
        disabledReason: busyReason[c.id],
      ),
  ];
  list.sort((a, b) => a.label.compareTo(b.label));
  return list;
}

/// Groups with sport, coaches, size and schedule summary.
List<AppPickerOption<String>> groupOptions(
  BuildContext context,
  Iterable<Group> groups, {
  required String Function(String sportId) sportName,
  String Function(String coachId)? coachName,
  String? Function(String sportId)? sportIconOf,
}) {
  final l = context.l10n;
  final list = [
    for (final g in groups)
      AppPickerOption<String>(
        value: g.id,
        label: g.name,
        subtitle: [
          sportName(g.sportId),
          if (coachName != null && g.coachIds.isNotEmpty) g.coachIds.map(coachName).join(', '),
          l.groupMembers(g.memberChildIds.length),
          if ((g.scheduleNote ?? '').isNotEmpty) g.scheduleNote!,
        ].join(' · '),
        leading: SportBadge(sportKey: sportIconOf?.call(g.sportId) ?? g.sportId, size: 36),
        searchText: sportName(g.sportId),
      ),
  ];
  list.sort((a, b) => a.label.compareTo(b.label));
  return list;
}

/// Rooms with capacity and sports; [busy] marks rooms occupied at the
/// chosen time (shown, not hidden, so the admin understands why).
List<AppPickerOption<String>> roomOptions(
  BuildContext context,
  Iterable<Room> rooms, {
  required String Function(String sportId) sportName,
  Map<String, String> busy = const {},
}) {
  final l = context.l10n;
  final list = [
    for (final r in rooms)
      if (r.status != RoomStatus.archived)
        AppPickerOption<String>(
          value: r.id,
          label: r.name,
          subtitle: [
            '${l.roomCapacity}: ${r.capacity}',
            if (r.sportIds.isNotEmpty) r.sportIds.map(sportName).join(', '),
          ].join(' · '),
          leading: const Icon(Icons.meeting_room_rounded),
          disabledReason: busy[r.id],
          group: busy.isEmpty ? null : (busy.containsKey(r.id) ? l.pickerGroupBusy : l.pickerGroupFree),
        ),
  ];
  // Free rooms first, then by name.
  list.sort((a, b) {
    final f = (a.enabled ? 0 : 1).compareTo(b.enabled ? 0 : 1);
    return f != 0 ? f : a.label.compareTo(b.label);
  });
  return list;
}

/// Students (children) with birth year and groups so equal names can be
/// told apart.
List<AppPickerOption<String>> studentOptions(
  BuildContext context,
  Iterable<Child> children, {
  Map<String, List<String>> groupNames = const {},
}) {
  final l = context.l10n;
  final list = [
    for (final c in children)
      AppPickerOption<String>(
        value: c.id,
        label: '${c.firstName} ${c.lastName}',
        subtitle: [l.birthYearShort(c.birthDate.year), ...?groupNames[c.id]].join(' · '),
        leading: InitialsAvatar(name: '${c.firstName} ${c.lastName}', size: 36),
      ),
  ];
  list.sort((a, b) => a.label.compareTo(b.label));
  return list;
}

/// Organizations with the user's role and the active marker.
List<AppPickerOption<String?>> organizationOptions(
  BuildContext context,
  Iterable<OrgConfig> orgs, {
  required String Function(OrgConfig c) name,
  required String Function(String orgId) roleOf,
  String? active,
  bool includeAll = false,
}) {
  final l = context.l10n;
  return [
    if (includeAll)
      AppPickerOption<String?>(
        value: null,
        label: l.orgAllAcademies,
        leading: const Icon(Icons.apps_rounded),
        trailing: active == null ? const Icon(Icons.check_rounded) : null,
      ),
    for (final c in orgs)
      AppPickerOption<String?>(
        value: c.orgId,
        label: name(c),
        subtitle: roleOf(c.orgId),
        leading: CircleAvatar(radius: 14, backgroundColor: Color(c.branding.primaryColor)),
      ),
  ];
}

/// Reusable sports selector (single or multiple) on stable sport ids:
/// icons, localized names, search in every language, optional restriction
/// to the organization's sports.
class SportsPickerField extends StatelessWidget {
  const SportsPickerField({
    super.key,
    required this.sports,
    required String this.value,
    required ValueChanged<String> this.onChanged,
    this.allowedIds,
    this.label,
    this.required = false,
    this.errorText,
  }) : values = null,
       onChangedMulti = null;

  const SportsPickerField.multi({
    super.key,
    required this.sports,
    required Set<String> this.values,
    required ValueChanged<Set<String>> this.onChangedMulti,
    this.allowedIds,
    this.label,
    this.required = false,
    this.errorText,
  }) : value = null,
       onChanged = null;

  final Iterable<Sport> sports;
  final Set<String>? allowedIds;
  final String? value;
  final Set<String>? values;
  final ValueChanged<String>? onChanged;
  final ValueChanged<Set<String>>? onChangedMulti;
  final String? label;
  final bool required;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final options = sportOptions(context, sports, allowedIds: allowedIds);
    final text = label ?? (values != null ? context.l10n.sportsLabel : context.l10n.a191StepSport);
    if (values != null) {
      return AppPickerField<String>.multi(
        key: const Key('sports-picker'),
        label: text,
        icon: Icons.sports_rounded,
        options: options,
        values: values!,
        onChangedMulti: onChangedMulti!,
        required: required,
        errorText: errorText,
      );
    }
    return AppPickerField<String>(
      key: const Key('sports-picker'),
      label: text,
      icon: Icons.sports_rounded,
      options: options,
      value: (value ?? '').isEmpty ? null : value,
      onChanged: onChanged!,
      required: required,
      errorText: errorText,
      recentsId: 'sports',
    );
  }
}
