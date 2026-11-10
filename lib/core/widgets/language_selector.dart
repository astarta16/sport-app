import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../app/settings.dart';
import '../../features/authentication/presentation/session_providers.dart';
import '../l10n/l10n.dart';
import 'app_widgets.dart';

/// Georgian (default), English and Russian. Switches immediately, persists
/// locally (independent of the device language) and mirrors the choice to
/// `users/{uid}.locale` so push/SMS/inbox text uses it too.
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  static const options = [('ka', 'ქართული'), ('en', 'English'), ('ru', 'Русский')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final current = ref.watch(appSettingsProvider).locale.languageCode;
    return AppCard(
      key: const Key('language-selector'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RadioGroup<String>(
        groupValue: current,
        onChanged: (code) async {
          if (code == null || code == current) return;
          await ref.read(appSettingsProvider.notifier).setLocale(Locale(code));
          if (ref.read(currentUidProvider) != null) {
            // Best effort: offline the local choice still applies.
            ref.read(authRepositoryProvider).updateLocale(code).catchError((_) {});
          }
        },
        child: Column(
          children: [
            for (final (code, name) in options)
              RadioListTile<String>(key: Key('lang-$code'), value: code, title: Text(name)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(l.languageHint, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
