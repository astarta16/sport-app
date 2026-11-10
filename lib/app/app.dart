import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/authentication/presentation/session_providers.dart';
import '../l10n/app_localizations.dart';
import 'di.dart';
import 'router.dart';
import 'settings.dart';

class SportParentApp extends ConsumerWidget {
  const SportParentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    // Register the device for push after each sign-in (no-op in demo mode).
    ref.listen(currentUidProvider, (prev, next) {
      if (next != null && next != prev) {
        ref.read(notificationsRepositoryProvider).registerDevice().catchError((Object _) {});
      }
    });
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
