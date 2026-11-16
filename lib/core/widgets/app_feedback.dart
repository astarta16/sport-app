import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

enum FeedbackTone { info, success, warning, error }

/// Inline, persistent feedback (unlike a snackbar it stays until resolved):
/// unsaved changes, partial failures, disabled features, read-only access.
class AppFeedbackBanner extends StatelessWidget {
  const AppFeedbackBanner({
    super.key,
    required this.message,
    this.tone = FeedbackTone.info,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? title;
  final FeedbackTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  static Color colorOf(FeedbackTone t) => switch (t) {
    FeedbackTone.info => AppStatusColors.info,
    FeedbackTone.success => AppColors.success,
    FeedbackTone.warning => AppColors.warning,
    FeedbackTone.error => AppColors.danger,
  };

  static IconData iconOf(FeedbackTone t) => switch (t) {
    FeedbackTone.info => Icons.info_rounded,
    FeedbackTone.success => Icons.check_circle_rounded,
    FeedbackTone.warning => Icons.warning_amber_rounded,
    FeedbackTone.error => Icons.error_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final c = colorOf(tone);
    return Semantics(
      liveRegion: tone == FeedbackTone.error || tone == FeedbackTone.success,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: c.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: c.withValues(alpha: .45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconOf(tone), color: c, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) Text(title!, style: Theme.of(context).textTheme.titleSmall),
                  Text(message),
                ],
              ),
            ),
            if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}

/// Progress header of a step wizard: numbered steps, current step and
/// completed ones; a step can be revisited by tapping it (data is kept).
class AppStepHeader extends StatelessWidget {
  const AppStepHeader({super.key, required this.steps, required this.current, this.onStep});

  final List<String> steps;
  final int current;
  final ValueChanged<int>? onStep;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    return Semantics(
      label: l.wizardStepOf(current + 1, steps.length, steps[current]),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < steps.length; i++)
            ExcludeSemantics(
              child: InkWell(
                key: Key('wizard-step-$i'),
                borderRadius: BorderRadius.circular(40),
                onTap: onStep == null || i > current ? null : () => onStep!(i),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: i == current ? scheme.primaryContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: i == current ? scheme.primary : scheme.outline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: i < current
                            ? AppColors.success
                            : (i == current ? scheme.primary : scheme.surfaceContainerHigh),
                        child: i < current
                            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: i == current ? Colors.white : scheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                      const SizedBox(width: 6),
                      Text(steps[i], style: TextStyle(fontWeight: i == current ? FontWeight.w800 : FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Titled group of related form fields with an optional hint.
class AppFormSection extends StatelessWidget {
  const AppFormSection({super.key, required this.title, required this.children, this.hint});

  final String title;
  final String? hint;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(hint!, style: Theme.of(context).textTheme.bodySmall),
          ),
        const SizedBox(height: AppSpacing.xs),
        ...children.expand((w) => [w, const SizedBox(height: AppSpacing.sm)]).take(children.length * 2 - 1),
      ],
    ),
  );
}
