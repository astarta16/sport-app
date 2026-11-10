import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/services/media_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../children/presentation/children_providers.dart';
import '../../clubs/domain/club.dart';
import '../../clubs/presentation/clubs_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import '../domain/training.dart';
import 'trainings_providers.dart';

/// Create / edit form (spec §6.2): date & time, venue, duration, focus,
/// description, optional photos with consent check.
class TrainingFormScreen extends ConsumerStatefulWidget {
  const TrainingFormScreen({super.key, this.groupId, this.trainingId});

  final String? groupId;
  final String? trainingId;

  bool get isEdit => trainingId != null;

  @override
  ConsumerState<TrainingFormScreen> createState() => _TrainingFormScreenState();
}

class _TrainingFormScreenState extends ConsumerState<TrainingFormScreen> {
  static const _durations = [45, 60, 75, 90, 120];

  String? _groupId;
  DateTime? _date;
  TimeOfDay? _time;
  String? _venueId;
  int _duration = 90;
  final _focus = <TrainingFocus>{};
  final _description = TextEditingController();
  final _photos = <PhotoUpload>[];
  bool _consentConfirmed = false;
  bool _saving = false;
  bool _initialized = false;
  List<String> _errors = const [];

  @override
  void initState() {
    super.initState();
    _groupId = widget.groupId;
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _initFrom(Training t) {
    if (_initialized) return;
    _initialized = true;
    _groupId = t.groupId;
    _date = DateUtils.dateOnly(t.startAt);
    _time = TimeOfDay.fromDateTime(t.startAt);
    _venueId = t.venueId;
    _duration = t.durationMin;
    _focus.addAll(t.focus);
    _description.text = t.description;
  }

  DateTime? get _start => _date == null || _time == null
      ? null
      : DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);

  Future<void> _save() async {
    final l = context.l10n;
    final start = _start;
    final draft = TrainingDraft(
      groupId: _groupId ?? '',
      venueId: _venueId ?? '',
      startAt: start ?? DateTime.fromMillisecondsSinceEpoch(0),
      durationMin: _duration,
      focus: _focus.toList(),
      description: _description.text,
      newPhotos: _photos,
      photoConsentConfirmed: _consentConfirmed,
    );
    final errors = [
      if (_groupId == null) 'required',
      if (start == null) 'required',
      ...TrainingValidator.validate(draft, now: ref.read(clockProvider)(), isEdit: widget.isEdit),
    ];
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    setState(() => _saving = true);
    final repo = ref.read(trainingsRepositoryProvider);
    final ok = await runGuarded(
      context,
      () => widget.isEdit ? repo.update(widget.trainingId!, draft) : repo.create(draft),
      success: l.trainingSaved,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (widget.isEdit) {
      final existing = ref.watch(trainingProvider(widget.trainingId!));
      if (existing.value != null) _initFrom(existing.value!);
      if (!_initialized) {
        return Scaffold(
          appBar: AppBar(title: Text(l.editTraining)),
          body: const SkeletonList(),
        );
      }
    }
    final groups = ref.watch(myGroupsProvider).value ?? const <Group>[];
    final group = groups.where((g) => g.id == _groupId).firstOrNull ?? (groups.length == 1 ? groups.first : null);
    _groupId ??= group?.id;
    final venues = ref.watch(venuesProvider).value ?? const <Venue>[];
    final groupVenues = group == null
        ? const <Venue>[]
        : (venues.where((v) => v.clubId == group.clubId || v.sportIds.contains(group.sportId)).toList()
            ..sort((a, b) => (a.clubId == group.clubId ? 0 : 1).compareTo(b.clubId == group.clubId ? 0 : 1)));
    final f = Fmt.of(context);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? l.editTraining : l.newTraining)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
          children: [
            if (!widget.isEdit && groups.length > 1) ...[
              SectionHeader(l.groupLabel),
              DropdownButtonFormField<String>(
                initialValue: _groupId,
                isExpanded: true,
                items: [for (final g in groups) DropdownMenuItem(value: g.id, child: Text(g.name))],
                onChanged: (v) => setState(() {
                  _groupId = v;
                  _venueId = null;
                }),
              ),
            ],
            SectionHeader(l.dateLabel),
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    key: const Key('training-date'),
                    icon: Icons.calendar_today_rounded,
                    label: _date == null ? l.dateLabel : f.weekdayDayMonth(_date!),
                    filled: _date != null,
                    onTap: () async {
                      final now = ref.read(clockProvider)();
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date ?? now,
                        firstDate: widget.isEdit ? now.subtract(const Duration(days: 60)) : DateUtils.dateOnly(now),
                        lastDate: now.add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => _date = d);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 120,
                  child: _PickerField(
                    key: const Key('training-time'),
                    icon: Icons.schedule_rounded,
                    label: _time == null ? l.timeLabel : _time!.format(context),
                    filled: _time != null,
                    onTap: () async {
                      final tm = await showTimePicker(
                        context: context,
                        initialTime: _time ?? const TimeOfDay(hour: 17, minute: 0),
                      );
                      if (tm != null) setState(() => _time = tm);
                    },
                  ),
                ),
              ],
            ),
            SectionHeader(l.venueLabel),
            DropdownButtonFormField<String>(
              key: const Key('training-venue'),
              initialValue: groupVenues.any((v) => v.id == _venueId) ? _venueId : null,
              isExpanded: true,
              hint: Text(l.selectVenue),
              items: [
                for (final v in groupVenues)
                  DropdownMenuItem(
                    value: v.id,
                    child: Row(
                      children: [
                        Icon(venueTypeIcon(v.type), size: 18, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(child: Text(v.name, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _venueId = v),
            ),
            SectionHeader(l.durationLabel),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in _durations)
                  ChoiceChip(
                    label: Text(l.durationMinutes(d)),
                    selected: _duration == d,
                    onSelected: (_) => setState(() => _duration = d),
                  ),
              ],
            ),
            Slider(
              value: _duration.toDouble().clamp(15, 180),
              min: 15,
              max: 180,
              divisions: 33,
              label: l.durationMinutes(_duration),
              onChanged: (v) => setState(() => _duration = v.round()),
            ),
            SectionHeader(l.trainingFocus),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final fo in TrainingFocus.values)
                  FilterChip(
                    key: Key('focus-${fo.name}'),
                    avatar: Icon(focusIcon(fo), size: 18),
                    label: Text(focusLabel(context, fo)),
                    selected: _focus.contains(fo),
                    onSelected: (v) => setState(() => v ? _focus.add(fo) : _focus.remove(fo)),
                  ),
              ],
            ),
            SectionHeader(l.trainingDescription),
            TextField(
              key: const Key('training-description'),
              controller: _description,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l.descriptionHint),
            ),
            SectionHeader(
              l.trainingPhotos,
              actionLabel: l.addPhotos,
              onAction: () async {
                final picked = await MediaPicker.pickPhotos();
                if (picked.isNotEmpty) setState(() => _photos.addAll(picked));
              },
            ),
            if (_photos.isNotEmpty) ...[
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          Uint8List.fromList(_photos[i].bytes),
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: InkWell(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: const CircleAvatar(radius: 11, child: Icon(Icons.close, size: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (group != null) _ConsentPanel(groupId: group.id),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _consentConfirmed,
                onChanged: (v) => setState(() => _consentConfirmed = v ?? false),
                title: Text(l.photoConsentConfirm, style: t.bodyMedium),
              ),
            ],
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              for (final e in _errors.toSet())
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(validationText(context, e) ?? e, style: const TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.lg),
            LoadingButton(
              key: const Key('save-training'),
              label: l.saveTraining,
              icon: Icons.check_rounded,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({super.key, required this.icon, required this.label, required this.onTap, required this.filled});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: const InputDecoration(),
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: filled ? scheme.onSurface : scheme.onSurfaceVariant,
                  fontWeight: filled ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lists group members whose parents did not consent to photos.
class _ConsentPanel extends ConsumerWidget {
  const _ConsentPanel({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final members = ref.watch(groupMembersProvider(groupId)).value ?? const [];
    final missing = members.where((c) => !c.photoConsent).map((c) => c.fullName).toList();
    final ok = missing.isEmpty;
    final color = ok ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ok ? Icons.verified_user_rounded : Icons.no_photography_rounded, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(ok ? l.photoConsentAllGiven : l.photoConsentMissing(missing.join(', ')))),
        ],
      ),
    );
  }
}
