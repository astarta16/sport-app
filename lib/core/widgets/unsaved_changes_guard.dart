import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// Asks before throwing away typed input (v1.9.1, M25). "Stay" is the
/// default (autofocused); "Discard" is the destructive choice.
///
/// Returns true when the user chose to discard the changes.
Future<bool> confirmDiscard(BuildContext context) async {
  final l = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('unsaved-dialog'),
      title: Text(l.m191UnsavedTitle),
      content: Text(l.m191UnsavedBody),
      actions: [
        TextButton(
          key: const Key('unsaved-discard'),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.m191Discard),
        ),
        FilledButton(
          key: const Key('unsaved-stay'),
          autofocus: true,
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.m191Stay),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Blocks back navigation (system back, app bar back, swipe) while [dirty]
/// and asks first; "Discard" then leaves the screen. Forms set [dirty] to
/// false once a save succeeded, so leaving after saving is never blocked.
/// Nothing is saved automatically.
class UnsavedChangesGuard extends StatelessWidget {
  const UnsavedChangesGuard({super.key, required this.dirty, required this.child});

  final bool dirty;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !dirty,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      final navigator = Navigator.of(context);
      if (await confirmDiscard(context)) navigator.pop(result);
    },
    child: child,
  );
}
