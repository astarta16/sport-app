import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config.dart';
import '../../../app/settings.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(appSettingsProvider);
    final ctrl = ref.read(appSettingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SectionHeader(l.themeLabel, padding: const EdgeInsets.only(bottom: AppSpacing.sm)),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto_rounded),
                  label: Text(l.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_rounded),
                  label: Text(l.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_rounded),
                  label: Text(l.themeDark),
                ),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) => ctrl.setThemeMode(v.first),
            ),
            SectionHeader(l.languageLabel),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ka', label: Text('ქართული')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {s.locale.languageCode},
              onSelectionChanged: (v) => ctrl.setLocale(Locale(v.first)),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(l.appVersion(AppConfig.version)),
                subtitle: Text(AppConfig.isDemo ? l.modeDemo : l.modeFirebase),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
