import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Window size classes based on the *available window width* (not the
/// device), so iPad Split View, Slide Over and Stage Manager windows get the
/// layout that fits them. Thresholds follow Material 3 window classes.
enum WindowSize {
  /// < 600 — phones (portrait and most landscape), narrow iPad multitasking.
  compact,

  /// 600–839 — iPad mini portrait, half-screen Split View, large phone landscape.
  medium,

  /// 840–1199 — iPad portrait (Air/Pro), iPad mini landscape.
  expanded,

  /// ≥ 1200 — iPad Air/Pro landscape, large Stage Manager windows.
  large;

  static WindowSize forWidth(double width) {
    if (width < Breakpoints.medium) return compact;
    if (width < Breakpoints.expanded) return medium;
    if (width < Breakpoints.large) return expanded;
    return large;
  }

  bool get isCompact => this == compact;

  /// Medium and up: tablet-style navigation and multi-column content.
  bool get isTabletLayout => this != compact;

  /// Expanded and up: room for master-detail panes side by side.
  bool get hasRoomForDetailPane => index >= expanded.index;

  bool operator >=(WindowSize other) => index >= other.index;
}

class Breakpoints {
  Breakpoints._();

  static const double medium = 600;
  static const double expanded = 840;
  static const double large = 1200;

  /// Max readable width for single-column content (forms, details, settings).
  static const double readable = 720;

  /// Max width for dashboards / wide grids.
  static const double dashboard = 1240;

  /// Width of the master list in master-detail layouts.
  static const double masterPane = 360;
}

extension ResponsiveContext on BuildContext {
  WindowSize get windowSize => WindowSize.forWidth(MediaQuery.sizeOf(this).width);

  bool get isTabletLayout => windowSize.isTabletLayout;

  /// Pick a value per size class; larger classes fall back to the nearest
  /// smaller one that was provided.
  T responsive<T>({required T compact, T? medium, T? expanded, T? large}) => switch (windowSize) {
    WindowSize.compact => compact,
    WindowSize.medium => medium ?? compact,
    WindowSize.expanded => expanded ?? medium ?? compact,
    WindowSize.large => large ?? expanded ?? medium ?? compact,
  };

  /// Horizontal page padding that grows with the window.
  double get pagePadding => responsive(compact: AppSpacing.lg, medium: AppSpacing.xl, expanded: AppSpacing.xxl);
}

/// Same as [ResponsiveContext] but for a given constraint width (use inside
/// [LayoutBuilder] where the pane may be narrower than the window).
WindowSize windowSizeFor(BoxConstraints c) => WindowSize.forWidth(c.maxWidth);

/// Centers [child] and caps its width — avoids stretched content on iPad.
class ConstrainedContent extends StatelessWidget {
  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.readable,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Sliver equivalent of [ConstrainedContent] via symmetric padding.
class SliverConstrained extends StatelessWidget {
  const SliverConstrained({
    super.key,
    required this.sliver,
    this.maxWidth = Breakpoints.readable,
    this.minPadding = 20,
  });

  final Widget sliver;
  final double maxWidth;
  final double minPadding;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, c) {
        final extra = ((c.crossAxisExtent - maxWidth) / 2).clamp(0.0, double.infinity);
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: extra + minPadding),
          sliver: sliver,
        );
      },
    );
  }
}

/// Lays children out in a grid whose column count adapts to the available
/// width; each row's items share equal width and natural height.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 300,
    this.maxColumns = 4,
    this.spacing = AppSpacing.md,
    this.runSpacing = AppSpacing.md,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;
  final double runSpacing;

  static int columnsFor(double width, {double minItemWidth = 300, int maxColumns = 4, double spacing = AppSpacing.md}) {
    final cols = ((width + spacing) / (minItemWidth + spacing)).floor();
    return cols.clamp(1, maxColumns);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = columnsFor(c.maxWidth, minItemWidth: minItemWidth, maxColumns: maxColumns, spacing: spacing);
        if (cols == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: runSpacing), children[i]],
            ],
          );
        }
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += cols) {
          final slice = children.sublist(i, (i + cols).clamp(0, children.length));
          // Top-aligned (no IntrinsicHeight: it breaks LayoutBuilder children).
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < cols; j++) ...[
                  if (j > 0) SizedBox(width: spacing),
                  Expanded(child: j < slice.length ? slice[j] : const SizedBox.shrink()),
                ],
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[if (i > 0) SizedBox(height: runSpacing), rows[i]],
          ],
        );
      },
    );
  }
}

/// Two side-by-side columns when wide enough, otherwise stacked.
class AdaptiveColumns extends StatelessWidget {
  const AdaptiveColumns({
    super.key,
    required this.primary,
    required this.secondary,
    this.breakpoint = Breakpoints.expanded,
    this.primaryFlex = 3,
    this.secondaryFlex = 2,
    this.gap = AppSpacing.lg,
  });

  final List<Widget> primary;
  final List<Widget> secondary;
  final double breakpoint;
  final int primaryFlex;
  final int secondaryFlex;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < breakpoint) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...primary, ...secondary]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: primaryFlex,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: primary),
            ),
            SizedBox(width: gap),
            Expanded(
              flex: secondaryFlex,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: secondary),
            ),
          ],
        );
      },
    );
  }
}

/// Master-detail scaffold: on wide windows shows [master] and [detail] side
/// by side (detail falls back to [emptyDetail]); on narrow windows shows only
/// the master (callers push the detail route instead).
class MasterDetailLayout extends StatelessWidget {
  const MasterDetailLayout({
    super.key,
    required this.master,
    required this.detail,
    required this.emptyDetail,
    this.masterWidth = Breakpoints.masterPane,
    this.breakpoint = Breakpoints.expanded,
  });

  final Widget master;
  final Widget? detail;
  final Widget emptyDetail;
  final double masterWidth;
  final double breakpoint;

  static bool isSplit(BuildContext context, {double breakpoint = Breakpoints.expanded}) =>
      MediaQuery.sizeOf(context).width >= breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < breakpoint) return master;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: masterWidth, child: master),
            VerticalDivider(width: 1, color: Theme.of(context).colorScheme.outline),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(key: ValueKey(detail?.key ?? detail.runtimeType), child: detail ?? emptyDetail),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Bottom sheet on phones, centered dialog with a capped width on tablets.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  double maxDialogWidth = 520,
}) {
  if (!context.isTabletLayout) {
    return showModalBottomSheet<T>(context: context, isScrollControlled: isScrollControlled, builder: builder);
  }
  return showDialog<T>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxDialogWidth, maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: SingleChildScrollView(child: builder(context)),
        ),
      ),
    ),
  );
}

/// Vertically centered body that still scrolls when the window is short
/// (phone landscape, Split View). Children must not use [Spacer].
class ScrollableFill extends StatelessWidget {
  const ScrollableFill({super.key, required this.child, this.maxWidth = 560, this.padding = EdgeInsets.zero});

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: (c.maxHeight - padding.vertical).clamp(0, double.infinity)),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
