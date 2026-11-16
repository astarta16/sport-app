import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/top_bar_actions.dart';
import '../core/l10n/l10n.dart';
import '../core/layout/responsive.dart';
import '../core/theme/app_theme.dart';
import '../features/authentication/presentation/splash_screen.dart';
import '../features/organizations/presentation/feature_gate.dart';
import '../features/organizations/domain/organization.dart';
import '../features/chat/presentation/chat_providers.dart';
import '../features/authentication/presentation/session_providers.dart';

/// v1.9 role-specific navigation (docs/ux-v1.9-navigation.md):
/// * Parent: Home · Calendar · Messages · Children · More
/// * Coach: Home · Schedule · Groups · Messages · More
/// Messages is left out (not shown disabled) when chat is off for every
/// organization of the user; branch indexes are mapped accordingly.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    final coach = user?.isCoach ?? false;
    final chatOn = (user?.canUseChat ?? false) && ref.watch(featureOnProvider(OrgModule.communication));
    final chatUnread = chatOn ? ref.watch(totalChatUnreadProvider) : 0;
    Widget messagesIcon(IconData i) =>
        Badge(isLabelVisible: chatUnread > 0, label: Text('$chatUnread'), child: Icon(i));
    // (branch index, icon, selected icon, label)
    final all = coach
        ? [
            (0, const Icon(Icons.home_outlined), const Icon(Icons.home_rounded), l.navHome),
            (1, const Icon(Icons.calendar_month_outlined), const Icon(Icons.calendar_month_rounded), l.navSchedule),
            (2, const Icon(Icons.groups_outlined), const Icon(Icons.groups_rounded), l.navGroups),
            (
              3,
              messagesIcon(Icons.chat_bubble_outline_rounded),
              messagesIcon(Icons.chat_bubble_rounded),
              l.navMessages,
            ),
            (4, const Icon(Icons.menu_rounded), const Icon(Icons.menu_open_rounded), l.navMore),
          ]
        : [
            (0, const Icon(Icons.home_outlined), const Icon(Icons.home_rounded), l.navHome),
            (1, const Icon(Icons.calendar_month_outlined), const Icon(Icons.calendar_month_rounded), l.navCalendar),
            (
              2,
              messagesIcon(Icons.chat_bubble_outline_rounded),
              messagesIcon(Icons.chat_bubble_rounded),
              l.navMessages,
            ),
            (3, const Icon(Icons.child_care_outlined), const Icon(Icons.child_care_rounded), l.navChildren),
            (4, const Icon(Icons.menu_rounded), const Icon(Icons.menu_open_rounded), l.navMore),
          ];
    final messagesBranch = coach ? 3 : 2;
    final items = [
      for (final i in all)
        if (chatOn || i.$1 != messagesBranch) i,
    ];
    final current = items.indexWhere((i) => i.$1 == navigationShell.currentIndex);
    final selectedIndex = current < 0 ? 0 : current;
    void go(int i) {
      final b = items[i].$1;
      navigationShell.goBranch(b, initialLocation: b == navigationShell.currentIndex);
    }

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
            selectedIndex: selectedIndex,
            onDestinationSelected: go,
            destinations: [
              for (final (_, icon, selected, label) in items)
                NavigationDestination(icon: icon, selectedIcon: selected, label: label),
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
                        selectedIndex: selectedIndex,
                        onDestinationSelected: go,
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
                          for (final (_, icon, selected, label) in items)
                            NavigationRailDestination(
                              icon: icon,
                              selectedIcon: selected,
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
