import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/top_bar_actions.dart';
import '../core/l10n/l10n.dart';
import '../core/layout/responsive.dart';
import '../core/theme/app_theme.dart';
import '../features/authentication/presentation/splash_screen.dart';

/// Home · Calendar · Map · Profile (v1.1 §10 — chat moved to the top bar).
///
/// * compact (< 600): bottom [NavigationBar] — the original phone design.
/// * medium / expanded (600–1199): [NavigationRail] with labels.
/// * large (≥ 1200): extended rail acting as a sidebar.
///
/// The choice follows the window width, so iPad Split View / Stage Manager
/// resizing switches layouts live.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _go(int i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = [
      (Icons.home_outlined, Icons.home_rounded, l.navHome),
      (Icons.calendar_month_outlined, Icons.calendar_month_rounded, l.navCalendar),
      (Icons.map_outlined, Icons.map_rounded, l.navMap),
      (Icons.person_outline_rounded, Icons.person_rounded, l.navProfile),
    ];
    final size = context.windowSize;
    final scheme = Theme.of(context).colorScheme;

    if (size.isCompact) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outline)),
          ),
          child: NavigationBar(
            key: const Key('bottom-nav'),
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _go,
            destinations: [
              for (final (icon, selected, label) in items)
                NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
            ],
          ),
        ),
      );
    }

    final extended = size == WindowSize.large;
    return Scaffold(
      body: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(right: BorderSide(color: scheme.outline)),
            ),
            child: SafeArea(
              right: false,
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        key: const Key('nav-rail'),
                        extended: extended,
                        minExtendedWidth: 232,
                        backgroundColor: Colors.transparent,
                        selectedIndex: navigationShell.currentIndex,
                        onDestinationSelected: _go,
                        labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                        groupAlignment: -0.85,
                        leading: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
                          child: extended
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const BrandMark(size: 40),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(l.appName, style: Theme.of(context).textTheme.titleLarge),
                                  ],
                                )
                              : const BrandMark(size: 40),
                        ),
                        trailing: const Padding(
                          padding: EdgeInsets.only(top: AppSpacing.lg),
                          child: TopBarActions(key: Key('rail-actions'), iconSize: 24, vertical: true),
                        ),
                        destinations: [
                          for (final (icon, selected, label) in items)
                            NavigationRailDestination(
                              icon: Icon(icon),
                              selectedIcon: Icon(selected),
                              label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            // Content panes keep their own SafeArea for the top inset;
            // the left inset is consumed by the rail.
            child: MediaQuery.removePadding(context: context, removeLeft: true, child: navigationShell),
          ),
        ],
      ),
    );
  }
}
