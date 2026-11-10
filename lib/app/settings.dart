import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'di.dart';

class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system, this.locale = const Locale('ka'), this.onboardingSeen = false});

  final ThemeMode themeMode;
  final Locale locale;
  final bool onboardingSeen;

  AppSettings copyWith({ThemeMode? themeMode, Locale? locale, bool? onboardingSeen}) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    locale: locale ?? this.locale,
    onboardingSeen: onboardingSeen ?? this.onboardingSeen,
  );
}

/// Device-local preferences (theme, language, onboarding) in SharedPreferences.
class AppSettingsController extends Notifier<AppSettings> {
  static const _kTheme = 'settings.theme';
  static const _kLocale = 'settings.locale';
  static const _kOnboarding = 'settings.onboardingSeen';

  @override
  AppSettings build() {
    final p = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere((m) => m.name == p.getString(_kTheme), orElse: () => ThemeMode.system),
      locale: Locale(p.getString(_kLocale) ?? 'ka'),
      onboardingSeen: p.getBool(_kOnboarding) ?? false,
    );
  }

  Future<void> setThemeMode(ThemeMode m) async {
    state = state.copyWith(themeMode: m);
    await ref.read(sharedPreferencesProvider).setString(_kTheme, m.name);
  }

  Future<void> setLocale(Locale l) async {
    state = state.copyWith(locale: l);
    await ref.read(sharedPreferencesProvider).setString(_kLocale, l.languageCode);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingSeen: true);
    await ref.read(sharedPreferencesProvider).setBool(_kOnboarding, true);
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsController, AppSettings>(AppSettingsController.new);
