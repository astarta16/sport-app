import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

/// One selectable entity (sport, coach, group, room, student, organization…).
///
/// [searchText] is matched case-insensitively in addition to [label] and
/// [subtitle]; [disabledReason] keeps an option visible but unselectable
/// (e.g. a room that is busy at the chosen time) instead of hiding it.
class AppPickerOption<T> {
  const AppPickerOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
    this.trailing,
    this.searchText = '',
    this.disabledReason,
    this.group,
  });

  final T value;
  final String label;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final String searchText;
  final String? disabledReason;

  /// Optional section header ("Suggested", "Other rooms"…).
  final String? group;

  bool get enabled => disabledReason == null;

  bool matches(String q) {
    if (q.isEmpty) return true;
    final s = '$label ${subtitle ?? ''} $searchText'.toLowerCase();
    return q.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).every(s.contains);
  }
}

/// Recently chosen values per picker (session memory; never persisted, so
/// nothing tenant-scoped leaks across accounts or organizations).
class _Recents {
  static final _map = <String, List<Object?>>{};

  static List<Object?> of(String id) => _map[id] ?? const [];

  static void add(String id, Object? v) {
    final l = [v, ...of(id).where((x) => x != v)];
    _map[id] = l.take(3).toList();
  }

  static void clear() => _map.clear();
}

/// Clears picker recents (called on sign-out / organization switch).
void clearPickerRecents() => _Recents.clear();

/// Single-choice searchable picker. Bottom sheet on phones, dialog on wide
/// windows. Returns the chosen value or null when dismissed.
Future<T?> showAppPicker<T>(
  BuildContext context, {
  required String title,
  required List<AppPickerOption<T>> options,
  T? selected,
  String? recentsId,
  String? emptyText,
}) async {
  final r = await _show<Set<T>>(
    context,
    _PickerBody<T>(
      title: title,
      options: options,
      initial: {?selected},
      multi: false,
      recentsId: recentsId,
      emptyText: emptyText,
    ),
  );
  if (r == null || r.isEmpty) return null;
  if (recentsId != null) _Recents.add(recentsId, r.first);
  return r.first;
}

/// Multi-choice searchable picker with selected chips, select all / clear
/// all and a result count. Returns the new selection or null when dismissed.
Future<Set<T>?> showAppMultiPicker<T>(
  BuildContext context, {
  required String title,
  required List<AppPickerOption<T>> options,
  Set<T> selected = const {},
  String? emptyText,
}) => _show<Set<T>>(
  context,
  _PickerBody<T>(title: title, options: options, initial: selected, multi: true, emptyText: emptyText),
);

Future<R?> _show<R>(BuildContext context, Widget body) {
  final wide = MediaQuery.sizeOf(context).width >= 700;
  if (wide) {
    return showDialog<R>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640), child: body),
      ),
    );
  }
  return showModalBottomSheet<R>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FractionallySizedBox(heightFactor: .88, child: body),
  );
}

class _PickerBody<T> extends StatefulWidget {
  const _PickerBody({
    required this.title,
    required this.options,
    required this.initial,
    required this.multi,
    this.recentsId,
    this.emptyText,
  });

  final String title;
  final List<AppPickerOption<T>> options;
  final Set<T> initial;
  final bool multi;
  final String? recentsId;
  final String? emptyText;

  @override
  State<_PickerBody<T>> createState() => _PickerBodyState<T>();
}

class _PickerBodyState<T> extends State<_PickerBody<T>> {
  late final Set<T> _sel = {...widget.initial};
  final _query = TextEditingController();
  final _search = FocusNode();
  int _cursor = 0;

  // Long lists get a search box; very short ones are simply listed.
  bool get _searchable => widget.options.length > 6;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() => _cursor = 0));
  }

  @override
  void dispose() {
    _query.dispose();
    _search.dispose();
    super.dispose();
  }

  List<AppPickerOption<T>> get _visible {
    final q = _query.text.trim();
    final list = widget.options.where((o) => o.matches(q)).toList();
    if (q.isEmpty && widget.recentsId != null && !widget.multi) {
      final rec = _Recents.of(widget.recentsId!);
      list.sort((a, b) {
        final ia = rec.indexOf(a.value), ib = rec.indexOf(b.value);
        return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
      });
    }
    return list;
  }

  void _choose(AppPickerOption<T> o) {
    if (!o.enabled) return;
    if (widget.multi) {
      setState(() => _sel.contains(o.value) ? _sel.remove(o.value) : _sel.add(o.value));
    } else {
      Navigator.pop(context, {o.value});
    }
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final v = _visible;
    if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _cursor = (_cursor + 1).clamp(0, v.isEmpty ? 0 : v.length - 1));
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _cursor = (_cursor - 1).clamp(0, v.isEmpty ? 0 : v.length - 1));
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.enter && v.isNotEmpty) {
      _choose(v[_cursor.clamp(0, v.length - 1)]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final visible = _visible;
    final enabledVisible = visible.where((o) => o.enabled).map((o) => o.value).toSet();
    final byValue = {for (final o in widget.options) o.value: o};
    final wide = MediaQuery.sizeOf(context).width >= 700;
    String? lastGroup;
    return Focus(
      onKeyEvent: _onKey,
      child: Column(
        key: const Key('app-picker'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, wide ? AppSpacing.lg : 0, AppSpacing.xs, AppSpacing.xs),
            child: Row(
              children: [
                Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                  tooltip: l.close,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          if (_searchable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                key: const Key('app-picker-search'),
                controller: _query,
                focusNode: _search,
                autofocus: wide,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => visible.isNotEmpty ? _choose(visible[_cursor.clamp(0, visible.length - 1)]) : null,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: l.pickerSearchHint,
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l.pickerClearSearch,
                          onPressed: _query.clear,
                          icon: const Icon(Icons.clear_rounded),
                        ),
                ),
              ),
            ),
          if (widget.multi)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.pickerSelectedCount(_sel.length),
                      key: const Key('app-picker-count'),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  TextButton(
                    key: const Key('app-picker-select-all'),
                    onPressed: enabledVisible.isEmpty ? null : () => setState(() => _sel.addAll(enabledVisible)),
                    child: Text(l.pickerSelectAll),
                  ),
                  TextButton(
                    key: const Key('app-picker-clear'),
                    onPressed: _sel.isEmpty ? null : () => setState(_sel.clear),
                    child: Text(l.pickerClearAll),
                  ),
                ],
              ),
            ),
          if (widget.multi && _sel.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  for (final v in _sel)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InputChip(
                        label: Text(byValue[v]?.label ?? '$v'),
                        onDeleted: () => setState(() => _sel.remove(v)),
                        deleteButtonTooltipMessage: l.pickerRemove,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        _query.text.isEmpty ? (widget.emptyText ?? l.pickerNoOptions) : l.pickerNoResults(_query.text),
                        key: const Key('app-picker-empty'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    itemCount: visible.length,
                    itemBuilder: (context, i) {
                      final o = visible[i];
                      final selected = _sel.contains(o.value);
                      final header = o.group != null && o.group != lastGroup ? o.group : null;
                      lastGroup = o.group;
                      final tile = ListTile(
                        key: Key('app-picker-option-${o.value}'),
                        enabled: o.enabled,
                        selected: selected || (i == _cursor && wide),
                        selectedTileColor: selected ? scheme.primaryContainer : scheme.surfaceContainer,
                        minTileHeight: AppA11y.minTouchTarget + 8,
                        leading: o.leading,
                        title: Text(o.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: o.subtitle == null && o.disabledReason == null
                            ? null
                            : Text(
                                [?o.subtitle, ?o.disabledReason].join(' · '),
                                style: TextStyle(color: o.enabled ? null : AppColors.danger),
                              ),
                        trailing: widget.multi
                            ? Checkbox(value: selected, onChanged: o.enabled ? (_) => _choose(o) : null)
                            : (selected ? Icon(Icons.check_circle_rounded, color: scheme.primary) : o.trailing),
                        onTap: () => _choose(o),
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (header != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 4),
                              child: Text(header, style: Theme.of(context).textTheme.labelLarge),
                            ),
                          Semantics(selected: selected, child: tile),
                        ],
                      );
                    },
                  ),
          ),
          if (widget.multi)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: FilledButton(
                  key: const Key('app-picker-done'),
                  onPressed: () => Navigator.pop(context, _sel),
                  child: Text(l.pickerDone(_sel.length)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Form field showing the current selection; opens [showAppPicker] /
/// [showAppMultiPicker]. Use for long or entity lists instead of a
/// dropdown. For 2–4 fixed choices use [AppChoiceGroup].
class AppPickerField<T> extends StatelessWidget {
  const AppPickerField({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.icon,
    this.required = false,
    this.errorText,
    this.helperText,
    this.recentsId,
    this.emptyText,
    this.enabled = true,
  }) : values = null,
       onChangedMulti = null;

  const AppPickerField.multi({
    super.key,
    required this.label,
    required this.options,
    required Set<T> this.values,
    required ValueChanged<Set<T>> this.onChangedMulti,
    this.icon,
    this.required = false,
    this.errorText,
    this.helperText,
    this.emptyText,
    this.enabled = true,
  }) : value = null,
       onChanged = null,
       recentsId = null;

  final String label;
  final List<AppPickerOption<T>> options;
  final T? value;
  final Set<T>? values;
  final ValueChanged<T>? onChanged;
  final ValueChanged<Set<T>>? onChangedMulti;
  final IconData? icon;
  final bool required;
  final String? errorText;
  final String? helperText;
  final String? recentsId;
  final String? emptyText;
  final bool enabled;

  bool get _multi => values != null;

  Future<void> _open(BuildContext context) async {
    if (_multi) {
      final r = await showAppMultiPicker<T>(
        context,
        title: label,
        options: options,
        selected: values!,
        emptyText: emptyText,
      );
      if (r != null) onChangedMulti!(r);
    } else {
      final r = await showAppPicker<T>(
        context,
        title: label,
        options: options,
        selected: value,
        recentsId: recentsId,
        emptyText: emptyText,
      );
      if (r != null) onChanged!(r);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final byValue = {for (final o in options) o.value: o};
    final current = _multi ? null : byValue[value];
    final chosen = _multi ? [for (final v in values!) ?byValue[v]] : const <AppPickerOption<Never>>[];
    final empty = _multi ? chosen.isEmpty : current == null;
    return Semantics(
      button: true,
      label: '$label${required ? ' *' : ''}',
      value: _multi ? chosen.map((o) => o.label).join(', ') : current?.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? () => _open(context) : null,
        child: InputDecorator(
          isEmpty: empty,
          decoration: InputDecoration(
            labelText: required ? '$label *' : label,
            prefixIcon: icon == null ? null : Icon(icon),
            suffixIcon: const Icon(Icons.unfold_more_rounded),
            errorText: errorText,
            helperText: helperText,
            enabled: enabled,
          ),
          child: empty
              ? Text(l.pickerChoose, style: TextStyle(color: scheme.onSurfaceVariant))
              : _multi
              ? Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final o in chosen.take(6)) Chip(label: Text(o.label), visualDensity: VisualDensity.compact),
                    if (chosen.length > 6) Chip(label: Text('+${chosen.length - 6}')),
                  ],
                )
              : Row(
                  children: [
                    if (current!.leading != null) ...[
                      SizedBox(width: 28, height: 28, child: FittedBox(child: current.leading)),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        current.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// 2–4 fixed choices shown at once (segmented control / radio cards)
/// instead of a dropdown. Labels wrap, so long Georgian / Russian text is
/// never clipped.
class AppChoiceGroup<T> extends StatelessWidget {
  const AppChoiceGroup({
    super.key,
    required this.choices,
    required this.value,
    required this.onChanged,
    this.label,
    this.keyPrefix,
  });

  final List<(T, String, IconData?)> choices;
  final T value;
  final ValueChanged<T>? onChanged;
  final String? label;
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label!, style: Theme.of(context).textTheme.labelLarge),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (v, text, icon) in choices)
              Semantics(
                inMutuallyExclusiveGroup: true,
                selected: v == value,
                child: ChoiceChip(
                  key: keyPrefix == null ? null : Key('$keyPrefix-${v is Enum ? v.name : v}'),
                  avatar: icon == null
                      ? null
                      : Icon(icon, size: 18, color: v == value ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
                  label: Text(text),
                  selected: v == value,
                  onSelected: onChanged == null ? null : (_) => onChanged!(v),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
