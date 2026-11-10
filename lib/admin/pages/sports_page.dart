import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/visuals.dart';
import '../../features/authentication/presentation/session_providers.dart';
import '../../features/sports/domain/sport.dart';
import '../../features/sports/presentation/sports_providers.dart';
import '../widgets.dart';
import 'admin_providers.dart';

/// Sports catalog (v1.1 §6): stored in the database, platform admins edit.
class SportsPage extends ConsumerWidget {
  const SportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final platform = ref.watch(currentUserProvider)?.isPlatformAdmin ?? false;
    final sports = ref.watch(adminSportsProvider);
    return AdminSection(
      title: l.adminNavSports,
      subtitle: platform ? null : l.adminReadOnly,
      actions: [
        if (platform)
          FilledButton.icon(
            key: const Key('admin-new-sport'),
            onPressed: () => showSportDialog(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.adminNewSport),
          ),
      ],
      child: AsyncView<List<Sport>>(
        value: sports,
        data: (list) => AdminTable<Sport>(
          rows: list,
          pageSize: 15,
          searchText: (s) => s.name,
          filters: [
            (l.adminFilterAll, (_) => true),
            for (final c in SportCategory.values) (sportCategoryLabel(context, c), (s) => s.category == c),
          ],
          columns: [
            AdminColumn(
              l.adminColName,
              (s) => Row(
                children: [
                  Icon(SportVisuals.icon(s.icon), size: 18, color: SportVisuals.color(s.icon)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      s.name,
                      key: Key('sport-row-${s.id}'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              flex: 3,
              sortKey: (s) => s.name,
            ),
            AdminColumn(l.adminColCategory, (s) => Text(sportCategoryLabel(context, s.category)), flex: 2),
            AdminColumn(l.adminColAgeMin, (s) => Text(s.ageMin?.toString() ?? '—'), sortKey: (s) => s.ageMin ?? 0),
            AdminColumn(
              l.adminColCert,
              (s) => Icon(s.requiresMedicalCert ? Icons.check_rounded : Icons.remove_rounded, size: 18),
            ),
            AdminColumn(
              l.adminColActive,
              (s) => Align(
                alignment: Alignment.centerLeft,
                child: StatusPill(
                  label: s.active ? l.adminColActive : l.adminArchived,
                  color: s.active ? AppColors.success : AppColors.neutral,
                  dense: true,
                ),
              ),
            ),
            AdminColumn(
              l.adminColActions,
              (s) => platform
                  ? IconButton(
                      key: Key('edit-sport-${s.id}'),
                      onPressed: () => showSportDialog(context, ref, sport: s),
                      icon: const Icon(Icons.edit_rounded),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showSportDialog(BuildContext context, WidgetRef ref, {Sport? sport}) async {
  final l = context.l10n;
  final id = TextEditingController(text: sport?.id);
  final name = TextEditingController(text: sport?.name);
  final age = TextEditingController(text: sport?.ageMin?.toString() ?? '');
  final order = TextEditingController(text: '${sport?.order ?? 100}');
  var category = sport?.category ?? SportCategory.team;
  var cert = sport?.requiresMedicalCert ?? false;
  var active = sport?.active ?? true;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        key: const Key('sport-dialog'),
        title: Text(sport == null ? l.adminNewSport : l.adminEditSport),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sport == null)
                  TextField(
                    key: const Key('sport-id'),
                    controller: id,
                    decoration: InputDecoration(labelText: l.adminSportId),
                  ),
                TextField(
                  key: const Key('sport-name'),
                  controller: name,
                  decoration: InputDecoration(labelText: l.adminColName),
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<SportCategory>(
                  segments: [
                    for (final c in SportCategory.values)
                      ButtonSegment(value: c, label: Text(sportCategoryLabel(context, c))),
                  ],
                  selected: {category},
                  onSelectionChanged: (s) => setState(() {
                    category = s.first;
                    if (category == SportCategory.combat) cert = true;
                  }),
                ),
                TextField(
                  key: const Key('sport-age'),
                  controller: age,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.adminColAgeMin),
                ),
                TextField(
                  controller: order,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.adminSportOrder),
                ),
                SwitchListTile(
                  title: Text(l.sportRequiresCert),
                  value: cert,
                  onChanged: (v) => setState(() => cert = v),
                ),
                SwitchListTile(
                  key: const Key('sport-active'),
                  title: Text(l.adminColActive),
                  value: active,
                  onChanged: (v) => setState(() => active = v),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          FilledButton(
            key: const Key('sport-save'),
            onPressed: () async {
              final sid = (sport?.id ?? id.text.trim().toLowerCase()).replaceAll(RegExp(r'[^a-z0-9_-]'), '');
              if (sid.isEmpty) return;
              final s = Sport(
                id: sid,
                name: name.text.trim(),
                icon: sport?.icon ?? sid,
                category: category,
                ageMin: int.tryParse(age.text),
                requiresMedicalCert: cert,
                active: active,
                order: int.tryParse(order.text) ?? 100,
              );
              final ok = await runGuarded(
                context,
                () => ref.read(adminRepositoryProvider).upsertSport(s),
                success: l.adminSaved,
              );
              if (ok) ref.invalidate(sportsProvider);
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
