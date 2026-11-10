import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../parent/presentation/parent_context.dart';
import '../../sports/presentation/sports_providers.dart';
import '../domain/child.dart';

/// Add a child to the parent's account (spec §4.2): name, birth date, sports.
class ChildFormScreen extends ConsumerStatefulWidget {
  const ChildFormScreen({super.key});

  @override
  ConsumerState<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends ConsumerState<ChildFormScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  DateTime? _birth;
  final _sports = <String>{};
  bool _photoConsent = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final now = ref.read(clockProvider)();
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    final birthErr = Validators.birthDate(_birth, now);
    if (birthErr != null) return setState(() => _error = validationText(context, birthErr));
    if (_sports.isEmpty) return setState(() => _error = l.validationSportRequired);
    setState(() => _saving = true);
    try {
      final child = await ref
          .read(childrenRepositoryProvider)
          .addChild(
            ChildDraft(
              firstName: _first.text,
              lastName: _last.text,
              birthDate: _birth!,
              sportIds: _sports.toList(),
              photoConsent: _photoConsent,
            ),
          );
      await ref.read(selectionContextProvider.notifier).selectChild(child.id);
      if (mounted) {
        showAppSnack(context, l.childSaved);
        context.pop();
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sports = ref.watch(sportsProvider);
    final f = Fmt.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.addChild)),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              TextFormField(
                key: const Key('child-first-name'),
                controller: _first,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l.firstName),
                validator: (v) => validationText(context, Validators.name(v)),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('child-last-name'),
                controller: _last,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l.lastName),
                validator: (v) => validationText(context, Validators.name(v)),
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                key: const Key('child-birth-date'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                leading: const Icon(Icons.cake_rounded),
                title: Text(l.birthDateLabel),
                subtitle: Text(_birth == null ? '—' : f.fullDate(_birth!)),
                onTap: () async {
                  final now = ref.read(clockProvider)();
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _birth ?? DateTime(now.year - 9),
                    firstDate: DateTime(now.year - 18),
                    lastDate: now,
                    initialEntryMode: DatePickerEntryMode.calendarOnly,
                  );
                  if (d != null) setState(() => _birth = d);
                },
              ),
              SectionHeader(l.sportsLabel),
              AsyncView(
                value: sports,
                compact: true,
                loading: const Skeleton(height: 90),
                data: (list) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in list)
                      FilterChip(
                        key: Key('child-sport-${s.id}'),
                        avatar: Icon(SportVisuals.icon(s.icon), size: 18, color: SportVisuals.color(s.icon)),
                        label: Text(s.name),
                        selected: _sports.contains(s.id),
                        onSelected: (v) => setState(() => v ? _sports.add(s.id) : _sports.remove(s.id)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _photoConsent,
                onChanged: (v) => setState(() => _photoConsent = v),
                title: Text(l.photoConsentLabel),
                subtitle: Text(l.photoConsentHelp),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                ),
              const SizedBox(height: AppSpacing.lg),
              LoadingButton(key: const Key('save-child'), label: l.save, loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
