import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config.dart';
import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/media_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/form_fields.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../trainings/domain/series.dart';
import '../../trainings/domain/training.dart';
import '../domain/training_plan.dart';
import 'plan_widgets.dart';
import 'plans_providers.dart';

/// Coach creates/edits a training plan: type, groups, period, exercises with
/// photos/videos/PDFs/links, reorder; save draft or publish.
class PlanEditorScreen extends ConsumerStatefulWidget {
  const PlanEditorScreen({super.key, this.planId, this.groupId});

  final String? planId;
  final String? groupId;

  @override
  ConsumerState<PlanEditorScreen> createState() => _PlanEditorScreenState();
}

class _PlanEditorScreenState extends ConsumerState<PlanEditorScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  PlanType _type = PlanType.weekly;
  final _groups = <String>{};
  DateTime? _start;
  DateTime? _end;
  final _exercises = <Exercise>[];
  final _files = <String, PhotoUpload>{};
  bool _init = false;
  bool _saving = false;
  List<String> _errors = const [];

  @override
  void initState() {
    super.initState();
    if (widget.groupId != null) _groups.add(widget.groupId!);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _initFrom(TrainingPlan p) {
    if (_init) return;
    _init = true;
    _title.text = p.title;
    _description.text = p.description;
    _type = p.type;
    _groups
      ..clear()
      ..addAll(p.groupIds);
    _start = p.startDate.toDateTime();
    _end = p.endDate?.toDateTime();
    _exercises.addAll(p.exercises);
  }

  PlanDraft _draft() => PlanDraft(
    title: _title.text,
    description: _description.text,
    type: _type,
    groupIds: _groups.toList(),
    startDate: LocalDate.fromDateTime(_start ?? ref.read(clockProvider)()),
    endDate: _end == null ? null : LocalDate.fromDateTime(_end!),
    exercises: List.of(_exercises),
    newFiles: Map.of(_files),
  );

  Future<void> _save({required bool publish}) async {
    final l = context.l10n;
    final d = _draft();
    final errors = PlanDraft.validate(d, publishing: publish);
    setState(() => _errors = errors.map((e) => e.startsWith('validation') ? e : _code(e)).toList());
    if (errors.isNotEmpty) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(trainingPlansRepositoryProvider);
      final plan = await repo.save(d, planId: widget.planId);
      if (publish) await repo.setStatus(plan.id, PlanStatus.published);
      if (!mounted) return;
      showAppSnack(context, publish ? l.planPublished : l.planSaved);
      context.pushReplacement(Routes.plan(plan.id));
    } catch (e) {
      if (mounted) showAppSnack(context, errorText(context, e), error: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  static String _code(String e) => switch (e) {
    'planTitle' => 'planTitle',
    _ => e,
  };

  Future<void> _editExercise({Exercise? existing, int? index}) async {
    final result = await Navigator.of(context).push<(Exercise, Map<String, PhotoUpload>)>(
      MaterialPageRoute(
        builder: (_) => ExerciseEditorScreen(exercise: existing, files: _files),
      ),
    );
    if (result == null) return;
    setState(() {
      _files.addAll(result.$2);
      if (index == null) {
        _exercises.add(result.$1);
      } else {
        _exercises[index] = result.$1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    if (widget.planId != null) {
      final async = ref.watch(planProvider(widget.planId!));
      final p = async.value;
      if (p != null) _initFrom(p);
      if (!_init) {
        return Scaffold(
          appBar: AppBar(title: Text(l.planEdit)),
          body: async.hasError
              ? ErrorView(error: async.error!, onRetry: () => ref.invalidate(planProvider(widget.planId!)))
              : async.hasValue
              ? EmptyState(icon: Icons.assignment_late_rounded, title: l.itemGoneTitle, body: l.itemGoneBody)
              : const SkeletonList(),
        );
      }
    }
    final me = ref.watch(currentUserProvider);
    final groups = (ref.watch(myGroupsProvider).value ?? const <Group>[])
        .where((g) => g.hasCoach(me?.id ?? ''))
        .toList();
    final now = ref.watch(clockProvider)();
    return Scaffold(
      appBar: AppBar(title: Text(widget.planId == null ? l.planNew : l.planEdit)),
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextField(
              key: const Key('plan-title'),
              controller: _title,
              maxLength: 120,
              decoration: InputDecoration(labelText: l.planTitleLabel),
            ),
            TextField(
              key: const Key('plan-description'),
              controller: _description,
              maxLength: 4000,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(labelText: l.planDescription),
            ),
            SectionHeader(l.planType),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in PlanType.values)
                  ChoiceChip(
                    key: Key('plan-type-${t.name}'),
                    label: Text(planTypeLabel(context, t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            SectionHeader(l.planGroups),
            for (final g in groups)
              CheckboxListTile(
                key: Key('plan-group-${g.id}'),
                contentPadding: EdgeInsets.zero,
                value: _groups.contains(g.id),
                onChanged: (v) => setState(() => v == true ? _groups.add(g.id) : _groups.remove(g.id)),
                title: Text(g.name),
              ),
            Row(
              children: [
                Expanded(
                  child: PickerField(
                    key: const Key('plan-start'),
                    icon: Icons.event_rounded,
                    label: '${l.planStart}: ${f.dayMonthShort(_start ?? now)}',
                    filled: true,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _start ?? now,
                        firstDate: now.subtract(const Duration(days: 365)),
                        lastDate: now.add(const Duration(days: 730)),
                      );
                      if (d != null) setState(() => _start = d);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PickerField(
                    key: const Key('plan-end'),
                    icon: Icons.event_busy_rounded,
                    label: _end == null ? l.planEnd : '${l.planEnd}: ${f.dayMonthShort(_end!)}',
                    filled: _end != null,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _end ?? (_start ?? now).add(const Duration(days: 30)),
                        firstDate: _start ?? now.subtract(const Duration(days: 365)),
                        lastDate: now.add(const Duration(days: 730)),
                      );
                      setState(() => _end = d);
                    },
                  ),
                ),
              ],
            ),
            SectionHeader(l.planExercises, actionLabel: l.planAddExercise, onAction: () => _editExercise()),
            if (_exercises.isEmpty) Text(l.planNoExercises, style: Theme.of(context).textTheme.bodySmall),
            for (var i = 0; i < _exercises.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: AppCard(
                  key: Key('plan-ex-$i'),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(_exercises[i].name),
                    subtitle: Text('${_exercises[i].media.length} · ${l.exerciseMedia}'),
                    onTap: () => _editExercise(existing: _exercises[i], index: i),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          key: Key('plan-ex-up-$i'),
                          tooltip: l.exerciseMoveUp,
                          onPressed: i == 0
                              ? null
                              : () => setState(() => _exercises.insert(i - 1, _exercises.removeAt(i))),
                          icon: const Icon(Icons.arrow_upward_rounded),
                        ),
                        IconButton(
                          tooltip: l.exerciseMoveDown,
                          onPressed: i == _exercises.length - 1
                              ? null
                              : () => setState(() => _exercises.insert(i + 1, _exercises.removeAt(i))),
                          icon: const Icon(Icons.arrow_downward_rounded),
                        ),
                        IconButton(
                          tooltip: l.exerciseRemove,
                          onPressed: () => setState(() => _exercises.removeAt(i)),
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('plan-add-exercise'),
                onPressed: () => _editExercise(),
                icon: const Icon(Icons.add_rounded),
                label: Text(l.planAddExercise),
              ),
            ),
            FormErrors(errors: _errors.map(_toValidation).toList()),
            const SizedBox(height: AppSpacing.md),
            Text(l.planDraftsOnlyCoach, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('plan-save-draft'),
                    onPressed: _saving ? null : () => _save(publish: false),
                    child: Text(l.planSaveDraft),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    key: const Key('plan-publish'),
                    onPressed: _saving ? null : () => _save(publish: true),
                    child: Text(l.planPublish),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _toValidation(String e) => switch (e) {
    'planTitle' => 'planTitle',
    'planGroups' => 'planGroups',
    'planDates' => 'planDates',
    'planExercises' => 'planExercises',
    'exerciseName' => 'exerciseName',
    'link' => 'link',
    'tooManyExercises' => 'tooManyExercises',
    'tooManyMedia' => 'tooManyMedia',
    _ => e,
  };
}

/// One exercise with media: camera photo/video, gallery, file (PDF), link.
class ExerciseEditorScreen extends StatefulWidget {
  const ExerciseEditorScreen({super.key, this.exercise, required this.files});

  final Exercise? exercise;
  final Map<String, PhotoUpload> files;

  @override
  State<ExerciseEditorScreen> createState() => _ExerciseEditorScreenState();
}

class _ExerciseEditorScreenState extends State<ExerciseEditorScreen> {
  late final _name = TextEditingController(text: widget.exercise?.name);
  late final _desc = TextEditingController(text: widget.exercise?.description);
  late final _instr = TextEditingController(text: widget.exercise?.instructions);
  late final _dur = TextEditingController(text: widget.exercise?.durationMin?.toString());
  late final _reps = TextEditingController(text: widget.exercise?.reps?.toString());
  late final _sets = TextEditingController(text: widget.exercise?.sets?.toString());
  late final _rest = TextEditingController(text: widget.exercise?.restSec?.toString());
  late final _media = <ExerciseMedia>[...?widget.exercise?.media];
  final _newFiles = <String, PhotoUpload>{};
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _desc, _instr, _dur, _reps, _sets, _rest]) {
      c.dispose();
    }
    super.dispose();
  }

  String _newId() => 'm-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _add(Future<PhotoUpload?> Function() pick, MediaKind kind) async {
    final f = await pick();
    if (f == null || !mounted) return;
    final k = f.mimeType == 'application/pdf'
        ? MediaKind.pdf
        : (f.mimeType.startsWith('video/') ? MediaKind.video : kind);
    final id = _newId();
    setState(() {
      _newFiles[id] = f;
      _media.add(ExerciseMedia(id: id, kind: k, name: f.fileName));
    });
  }

  Future<void> _addLink() async {
    final l = context.l10n;
    final c = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.exerciseAddLink),
        content: TextField(
          key: const Key('link-field'),
          controller: c,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(hintText: l.exerciseLinkHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          FilledButton(
            key: const Key('link-ok'),
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: Text(l.actionAdd),
          ),
        ],
      ),
    );
    if (url == null || url.isEmpty || !mounted) return;
    if (!PlanDraft.isSafeLink(url)) {
      setState(() => _error = l.exerciseLinkInvalid);
      return;
    }
    setState(() {
      _error = null;
      _media.add(ExerciseMedia(id: _newId(), kind: MediaKind.link, url: url, name: Uri.parse(url).host));
    });
  }

  void _done() {
    final l = context.l10n;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = l.validationExerciseName);
      return;
    }
    int? n(TextEditingController c) => int.tryParse(c.text.trim());
    final e = Exercise(
      id: widget.exercise?.id ?? 'ex-${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      description: _desc.text.trim(),
      instructions: _instr.text.trim(),
      durationMin: n(_dur),
      reps: n(_reps),
      sets: n(_sets),
      restSec: n(_rest),
      media: _media,
    );
    Navigator.pop(context, (e, _newFiles));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final demo = AppConfig.isDemo;
    Widget num(TextEditingController c, String label, Key key) => Expanded(
      child: TextField(
        key: key,
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise == null ? l.planAddExercise : l.exerciseName),
        actions: [TextButton(key: const Key('exercise-done'), onPressed: _done, child: Text(l.done))],
      ),
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextField(
              key: const Key('exercise-name'),
              controller: _name,
              maxLength: 120,
              decoration: InputDecoration(labelText: l.exerciseName),
            ),
            TextField(
              controller: _desc,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(labelText: l.exerciseDescription),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              key: const Key('exercise-instructions'),
              controller: _instr,
              maxLines: 5,
              minLines: 2,
              decoration: InputDecoration(labelText: l.exerciseInstructions),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                num(_dur, l.exerciseDuration, const Key('ex-dur')),
                const SizedBox(width: 8),
                num(_reps, l.exerciseReps, const Key('ex-reps')),
              ],
            ),
            Row(
              children: [
                num(_sets, l.exerciseSets, const Key('ex-sets')),
                const SizedBox(width: 8),
                num(_rest, l.exerciseRest, const Key('ex-rest')),
              ],
            ),
            SectionHeader(l.exerciseMedia),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.photo_camera_rounded, size: 18),
                  label: Text(l.mediaTakePhoto),
                  onPressed: () => _add(MediaPicker.takePhoto, MediaKind.photo),
                ),
                ActionChip(
                  avatar: const Icon(Icons.videocam_rounded, size: 18),
                  label: Text(l.mediaRecordVideo),
                  onPressed: () => _add(() => MediaPicker.pickVideo(camera: true), MediaKind.video),
                ),
                ActionChip(
                  avatar: const Icon(Icons.photo_library_rounded, size: 18),
                  label: Text(l.mediaFromGallery),
                  onPressed: () => _add(MediaPicker.pickOnePhoto, MediaKind.photo),
                ),
                ActionChip(
                  avatar: const Icon(Icons.attach_file_rounded, size: 18),
                  label: Text(l.certChooseFile),
                  onPressed: () => _add(MediaPicker.pickDocument, MediaKind.pdf),
                ),
                ActionChip(
                  key: const Key('exercise-add-link'),
                  avatar: const Icon(Icons.link_rounded, size: 18),
                  label: Text(l.exerciseAddLink),
                  onPressed: _addLink,
                ),
                if (demo)
                  ActionChip(
                    key: const Key('exercise-demo-photo'),
                    avatar: const Icon(Icons.science_rounded, size: 18),
                    label: Text(l.demoBadge),
                    onPressed: () => _add(
                      () async => PhotoUpload(
                        bytes: Uint8List.fromList(List.filled(2048, 9)),
                        fileName: 'demo.jpg',
                        mimeType: 'image/jpeg',
                      ),
                      MediaKind.photo,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in _media)
                  ExerciseMediaTile(
                    planId: '',
                    media: m,
                    localBytes: (_newFiles[m.id] ?? widget.files[m.id])?.bytes,
                    onRemove: () => setState(() {
                      _media.remove(m);
                      _newFiles.remove(m.id);
                    }),
                  ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: _done, child: Text(l.done)),
          ],
        ),
      ),
    );
  }
}
