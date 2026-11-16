import 'package:flutter/material.dart';

/// v1.9 design tokens that complement [AppColors] / [AppSpacing] in
/// `app_theme.dart` (colour, spacing and radii live there).
///
/// Documented in docs/ux-v1.9-design-system.md.

/// Motion: short, purposeful, and disabled when the platform asks for
/// reduced motion (iOS "Reduce Motion", Android "Remove animations").
class AppMotion {
  AppMotion._();

  static const fast = Duration(milliseconds: 120);
  static const medium = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 320);
  static const emphasized = Curves.easeOutCubic;
  static const standard = Curves.easeInOut;

  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d], or zero when reduced motion is requested.
  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}

/// Elevation as soft shadows (cards stay flat with a 1-px outline; only
/// floating surfaces — sheets, menus, sticky bars — use these).
class AppElevation {
  AppElevation._();

  static List<BoxShadow> level1(BuildContext context) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? .35 : .06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> level2(BuildContext context) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? .45 : .10),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}

/// Accessibility sizes (WCAG 2.2 target size; Material 48 dp).
class AppA11y {
  AppA11y._();

  static const minTouchTarget = 48.0;

  /// Visible keyboard focus ring for custom tappable surfaces.
  static const focusRingWidth = 2.0;
}

/// Semantic status colours beyond success / warning / danger in
/// [AppColors]; used by badges and banners.
class AppStatusColors {
  AppStatusColors._();

  static const info = Color(0xFF0EA5E9);
}
