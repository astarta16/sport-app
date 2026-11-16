import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/presentation/session_providers.dart';
import '../features/organizations/domain/organization.dart';
import '../features/organizations/presentation/org_providers.dart';
import 'pages/v17_pages.dart';

import '../core/l10n/l10n.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';

/// Page scaffold for admin sections: title, optional actions, content.
class AdminSection extends StatelessWidget {
  const AdminSection({super.key, required this.title, required this.child, this.actions = const [], this.subtitle});

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: AppSpacing.sm,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                if (subtitle != null) Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            Wrap(spacing: AppSpacing.xs, children: actions),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        child,
      ],
    );
  }
}

class AdminColumn<T> {
  const AdminColumn(this.label, this.cell, {this.flex = 1, this.sortKey});

  final String label;
  final Widget Function(T row) cell;
  final int flex;
  final Comparable<Object?> Function(T row)? sortKey;
}

/// Searchable, sortable, paginated table that collapses to cards on narrow
/// windows. Data comes already scoped by the repository (server rules).
class AdminTable<T> extends StatefulWidget {
  const AdminTable({
    super.key,
    required this.rows,
    required this.columns,
    required this.searchText,
    this.filters = const [],
    this.pageSize = 10,
  });

  final List<T> rows;
  final List<AdminColumn<T>> columns;
  final String Function(T row) searchText;

  /// (label, predicate) filter chips; the first is "all".
  final List<(String, bool Function(T row))> filters;
  final int pageSize;

  @override
  State<AdminTable<T>> createState() => _AdminTableState<T>();
}

class _AdminTableState<T> extends State<AdminTable<T>> {
  String _q = '';
  final _search = TextEditingController();
  int _filter = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() => setState(() {
    _search.clear();
    _q = '';
    _filter = 0;
    _page = 0;
  });
  int _page = 0;
  int? _sort;
  bool _asc = true;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    var rows = widget.rows.where((r) => widget.searchText(r).toLowerCase().contains(_q.toLowerCase())).toList();
    if (widget.filters.isNotEmpty) rows = rows.where(widget.filters[_filter].$2).toList();
    final sortKey = _sort == null ? null : widget.columns[_sort!].sortKey;
    if (sortKey != null) {
      rows.sort((a, b) => _asc ? sortKey(a).compareTo(sortKey(b)) : sortKey(b).compareTo(sortKey(a)));
    }
    final total = rows.length;
    final pages = (total / widget.pageSize).ceil().clamp(1, 1 << 20);
    final page = _page.clamp(0, pages - 1);
    final slice = rows.skip(page * widget.pageSize).take(widget.pageSize).toList();
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    key: const Key('admin-search'),
                    controller: _search,
                    decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: l.adminSearch),
                    onChanged: (v) => setState(() {
                      _q = v;
                      _page = 0;
                    }),
                  ),
                ),
                for (var i = 0; i < widget.filters.length; i++)
                  ChoiceChip(
                    key: Key('admin-filter-$i'),
                    label: Text(widget.filters[i].$1),
                    selected: _filter == i,
                    onSelected: (_) => setState(() {
                      _filter = i;
                      _page = 0;
                    }),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          LayoutBuilder(
            builder: (context, c) {
              if (slice.isEmpty) {
                // v1.9: "nothing exists yet" is not the same as "nothing
                // matches your search" — the latter offers a way back.
                final filtered = widget.rows.isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Column(
                      key: Key(filtered ? 'admin-no-matches' : 'admin-empty'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(filtered ? Icons.search_off_rounded : Icons.inbox_rounded, size: 36),
                        const SizedBox(height: AppSpacing.xs),
                        Text(filtered ? l.adminNoMatches : l.adminEmpty, textAlign: TextAlign.center),
                        if (filtered)
                          TextButton.icon(
                            key: const Key('admin-clear-filters'),
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.filter_alt_off_rounded),
                            label: Text(l.adminClearFilters),
                          ),
                      ],
                    ),
                  ),
                );
              }
              if (c.maxWidth < 760) {
                // Narrow: each row as a card of label/value pairs.
                return Column(
                  children: [
                    for (final r in slice)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: scheme.outline)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final col in widget.columns)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 110,
                                      child: Text(col.label, style: Theme.of(context).textTheme.labelSmall),
                                    ),
                                    Expanded(child: col.cell(r)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              }
              return Column(
                children: [
                  Container(
                    color: scheme.surfaceContainerHigh,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        for (var i = 0; i < widget.columns.length; i++)
                          Expanded(
                            flex: widget.columns[i].flex,
                            // v1.9.1: sortable headers announce themselves and
                            // their order; InkWell is focusable and reacts to
                            // Enter / Space for keyboard users; sorting resets
                            // to the first page.
                            child: Semantics(
                              button: widget.columns[i].sortKey != null,
                              label: widget.columns[i].sortKey == null
                                  ? null
                                  : l.a191SortBy(widget.columns[i].label) +
                                        (_sort == i ? ' · ${_asc ? l.a191SortAsc : l.a191SortDesc}' : ''),
                              excludeSemantics: widget.columns[i].sortKey != null,
                              child: InkWell(
                                key: Key('admin-sort-$i'),
                                onTap: widget.columns[i].sortKey == null
                                    ? null
                                    : () => setState(() {
                                        _asc = _sort == i ? !_asc : true;
                                        _sort = i;
                                        _page = 0;
                                      }),
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.columns[i].label,
                                        style: Theme.of(context).textTheme.labelMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_sort == i)
                                      Icon(_asc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14)
                                    else if (widget.columns[i].sortKey != null)
                                      const Icon(Icons.unfold_more_rounded, size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  for (final r in slice)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: scheme.outline)),
                      ),
                      child: Row(
                        children: [
                          for (final col in widget.columns)
                            Expanded(
                              flex: col.flex,
                              child: Padding(padding: const EdgeInsets.only(right: 8), child: col.cell(r)),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  l.adminPageOf(
                    total == 0 ? 0 : page * widget.pageSize + 1,
                    page * widget.pageSize + slice.length,
                    total,
                  ),
                  key: const Key('admin-page-info'),
                ),
                IconButton(
                  key: const Key('admin-prev'),
                  tooltip: l.adminPrevPage,
                  onPressed: page > 0 ? () => setState(() => _page = page - 1) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  key: const Key('admin-next'),
                  tooltip: l.adminNextPage,
                  onPressed: page < pages - 1 ? () => setState(() => _page = page + 1) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Text input dialog with a minimum length (admin decisions need reasons).
Future<String?> askReason(BuildContext context, {required String title, int minLength = 5}) async {
  final l = context.l10n;
  final c = TextEditingController();
  String? error;
  final r = await showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: TextField(
            key: const Key('admin-reason'),
            controller: c,
            autofocus: true,
            maxLength: 300,
            maxLines: 3,
            decoration: InputDecoration(labelText: l.adminReasonTitle, errorText: error),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          FilledButton(
            key: const Key('admin-reason-ok'),
            onPressed: () {
              if (c.text.trim().length < minLength) {
                setState(() => error = l.validationReasonRequired);
                return;
              }
              Navigator.pop(context, c.text.trim());
            },
            child: Text(l.confirm),
          ),
        ],
      ),
    ),
  );
  // Controllers of dialogs are left to GC: disposing right after pop races
  // the exit animation, which still builds the TextField.
  return r;
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value, required this.icon, this.highlight = false});

  final String label;
  final int value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      color: highlight && value > 0 ? AppColors.warning.withValues(alpha: 0.12) : null,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                Text(label, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// v1.9: an organization page whose feature is off for the selected
/// organization explains why (and where to change it) instead of showing an
/// empty or broken page — also for direct links and old bookmarks.
class AdminFeatureGate extends ConsumerWidget {
  const AdminFeatureGate({super.key, required this.module, required this.child});

  final OrgModule module;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final orgId = ref.watch(adminOrgProvider);
    final cfg = orgId == null ? null : ref.watch(orgConfigProvider(orgId)).value;
    if (cfg == null || cfg.isEnabled(module, now: DateTime.now())) return child;
    final me = ref.watch(currentUserProvider);
    return Center(
      child: EmptyState(
        key: Key('feature-off-${module.name}'),
        icon: Icons.lock_rounded,
        title: l.featureOffTitle(moduleLabel(context, module)),
        body: me?.isPlatformAdmin ?? false ? l.featureOffBodyPlatform : l.featureOffBodyOrg,
        actionLabel: me?.isPlatformAdmin ?? false ? l.featureOffOpenOrg : l.featureOffOpenSettings,
        onAction: () => context.go(me?.isPlatformAdmin ?? false ? '/organizations/${cfg.orgId}' : '/org-settings'),
      ),
    );
  }
}
