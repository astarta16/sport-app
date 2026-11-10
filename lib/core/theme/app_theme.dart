import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Brand palette — "night pitch" navy, electric blue and a volt accent.
class AppColors {
  AppColors._();

  static const navy = Color(0xFF0B1530);
  static const navySoft = Color(0xFF16213F);
  static const blue = Color(0xFF2F6BFF);
  static const blueDeep = Color(0xFF1D4ED8);
  static const volt = Color(0xFFD4FF3A);
  static const coral = Color(0xFFFF5A5F);

  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const neutral = Color(0xFF8A94A6);

  static const lightBg = Color(0xFFF4F6FB);
  static const lightSurface = Colors.white;
  static const lightBorder = Color(0xFFE4E8F1);
  static const darkBg = Color(0xFF070D1F);
  static const darkSurface = Color(0xFF111A33);
  static const darkBorder = Color(0xFF1E2A4A);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D4ED8), Color(0xFF2F6BFF), Color(0xFF5B8CFF)],
  );

  static const nightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1530), Color(0xFF1A2B5F)],
  );
}

/// 4-pt spacing scale and radii.
class AppSpacing {
  AppSpacing._();

  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const page = EdgeInsets.symmetric(horizontal: 20);

  static const radiusSm = 12.0;
  static const radius = 20.0;
  static const radiusLg = 28.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final scheme = ColorScheme(
      brightness: b,
      primary: dark ? const Color(0xFF6F98FF) : AppColors.blue,
      onPrimary: Colors.white,
      primaryContainer: dark ? const Color(0xFF1B2D63) : const Color(0xFFE3EBFF),
      onPrimaryContainer: dark ? const Color(0xFFDCE6FF) : AppColors.blueDeep,
      secondary: AppColors.volt,
      onSecondary: AppColors.navy,
      secondaryContainer: dark ? const Color(0xFF2B3410) : const Color(0xFFF2FFC2),
      onSecondaryContainer: dark ? AppColors.volt : const Color(0xFF3D4A00),
      tertiary: AppColors.coral,
      onTertiary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: dark ? AppColors.darkSurface : AppColors.lightSurface,
      onSurface: dark ? const Color(0xFFEAF0FF) : AppColors.navy,
      onSurfaceVariant: dark ? const Color(0xFF9AA7C7) : const Color(0xFF5B6680),
      surfaceContainerLowest: dark ? AppColors.darkBg : AppColors.lightBg,
      surfaceContainerLow: dark ? const Color(0xFF0D1530) : const Color(0xFFF8F9FD),
      surfaceContainer: dark ? const Color(0xFF151F3C) : const Color(0xFFF0F3FA),
      surfaceContainerHigh: dark ? const Color(0xFF1A2546) : const Color(0xFFEAEEF7),
      surfaceContainerHighest: dark ? const Color(0xFF212D52) : const Color(0xFFE3E8F3),
      outline: dark ? AppColors.darkBorder : AppColors.lightBorder,
      outlineVariant: dark ? const Color(0xFF18223F) : const Color(0xFFEEF1F7),
      shadow: Colors.black,
      inverseSurface: dark ? Colors.white : AppColors.navy,
      onInverseSurface: dark ? AppColors.navy : Colors.white,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: b);
    final text = base.textTheme.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    final textTheme = text.copyWith(
      displaySmall: text.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.4),
      bodySmall: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.35),
    );

    final radius = BorderRadius.circular(AppSpacing.radiusSm + 4);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 54),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textTheme.titleSmall,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.titleSmall,
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(textStyle: textTheme.labelLarge)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF0E1731) : const Color(0xFFF6F8FC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        side: BorderSide(color: scheme.outline),
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => textTheme.labelSmall?.copyWith(
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
            color: s.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.w600),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        iconColor: scheme.onSurfaceVariant,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
