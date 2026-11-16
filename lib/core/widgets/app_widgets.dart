import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../services/error_reporter.dart';
import '../theme/app_theme.dart';
import 'visuals.dart';

/// Card with border, optional gradient and a subtle press-scale animation.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.gradient,
    this.color,
    this.radius = AppSpacing.radius,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? color;

  /// Emphasized outline (e.g. "still to do"); defaults to the theme outline.
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = BorderRadius.circular(radius);
    final content = Ink(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? scheme.surface) : null,
        gradient: gradient,
        borderRadius: border,
        border: gradient == null
            ? Border.all(color: borderColor ?? scheme.outline, width: borderColor == null ? 1 : 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    return Pressable(
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, borderRadius: border, child: content),
      ),
    );
  }
}

/// Micro-interaction: scales down slightly while pressed.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction, this.padding});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          ),
          if (actionLabel != null)
            // Natural width, but never more than ~45 % of narrow rows.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: TextButton(
                onPressed: onAction,
                child: Text(actionLabel!, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color, this.icon, this.dense = false});

  factory StatusPill.of(StatusVisual v, {bool dense = false}) =>
      StatusPill(label: v.label, color: v.color, icon: v.icon, dense: dense);

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: dense ? 13 : 15, color: color), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.size = 44, this.color, this.selected = false});

  final String name;
  final double size;
  final Color? color;
  final bool selected;

  static const _palette = [
    Color(0xFF2F6BFF),
    Color(0xFF16A34A),
    Color(0xFFF97316),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFF0EA5E9),
    Color(0xFFDC2626),
  ];

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.take(2).map((p) => p.isEmpty ? '' : String.fromCharCode(p.runes.first)).join();
    final c = color ?? _palette[name.hashCode.abs() % _palette.length];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      padding: EdgeInsets.all(selected ? 2.5 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: selected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2.5) : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [c, Color.lerp(c, Colors.white, 0.3)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.36),
        ),
      ),
    );
  }
}

class SportBadge extends StatelessWidget {
  const SportBadge({super.key, required this.sportKey, this.size = 44});

  final String sportKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: SportVisuals.gradient(sportKey),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(SportVisuals.icon(sportKey), color: Colors.white, size: size * 0.55),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 56 : 88,
              height: compact ? 56 : 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [scheme.primaryContainer, scheme.secondaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(icon, size: compact ? 26 : 40, color: scheme.primary),
            ),
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
            Text(title, textAlign: TextAlign.center, style: compact ? t.titleSmall : t.titleLarge),
            if (body != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(onPressed: onAction, icon: const Icon(Icons.add_rounded), label: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmering placeholder block used for skeleton loading states.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height = 16, this.width, this.radius = 12});

  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHigh;
    final hi = scheme.surfaceContainerLow;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + 3 * _c.value, 0),
              end: Alignment(-0.5 + 3 * _c.value, 0),
              colors: [base, hi, base],
            ),
          ),
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.itemHeight = 84, this.padding = AppSpacing.page});

  final int count;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding.add(const EdgeInsets.symmetric(vertical: AppSpacing.md)),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => Skeleton(height: itemHeight, radius: AppSpacing.radius),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry, this.compact = false});

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Scrollable so the error never overflows short panes (phone landscape).
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: compact ? 28 : 44, color: scheme.error),
            const SizedBox(height: AppSpacing.sm),
            Text(context.l10n.errorTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(errorText(context, error), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders an [AsyncValue] with skeleton loading and a retryable error state.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.onRetry,
    this.compact = false,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) => data(value),
      AsyncError(:final error) => ErrorView(error: error, onRetry: onRetry, compact: compact),
      _ => loading ?? const SkeletonList(),
    };
  }
}

class LoadingButton extends StatelessWidget {
  const LoadingButton({super.key, required this.label, required this.onPressed, this.loading = false, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                    Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                  ],
                ),
        ),
      ),
    );
  }
}

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Icon(Icons.science_rounded, size: 18, color: scheme.onSecondaryContainer),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Demo photo tile: `demo://photo/...` renders a branded gradient, uploaded
/// demo photos (`demo-mem://`) render from memory, anything else from network.
class TrainingPhoto extends StatelessWidget {
  const TrainingPhoto({super.key, required this.url, this.bytes, this.sportKey = 'football', this.size});

  final String url;
  final Uint8List? bytes;
  final String sportKey;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusSm + 2);
    Widget child;
    final bytes = this.bytes;
    if (bytes != null) {
      child = Image.memory(bytes, fit: BoxFit.cover, errorBuilder: (_, _, _) => _placeholder(context));
    } else if (url.startsWith('http')) {
      child = Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => _placeholder(context));
    } else {
      child = _placeholder(context);
    }
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(width: size, height: size, child: child),
    );
  }

  Widget _placeholder(BuildContext context) {
    final seed = url.hashCode.abs();
    final c = SportVisuals.color(sportKey);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1 + (seed % 3) * 0.5, -1),
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(c, Colors.black, 0.35 + (seed % 4) * 0.05)!,
            Color.lerp(c, Colors.white, (seed % 5) * 0.06)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(SportVisuals.icon(sportKey), size: 70, color: Colors.white.withValues(alpha: 0.18)),
          ),
          Center(child: Icon(Icons.photo_camera_rounded, color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: error ? AppColors.coral : AppColors.volt,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
        FilledButton(
          key: const Key('confirm-ok'),
          style: destructive ? FilledButton.styleFrom(backgroundColor: AppColors.danger) : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Runs [action], showing a snackbar on success or a localized error.
Future<bool> runGuarded(BuildContext context, Future<void> Function() action, {String? success}) async {
  try {
    await action();
    if (context.mounted && success != null) showAppSnack(context, success);
    return true;
  } catch (e, st) {
    ErrorReporter.report(e, st, context: 'ui-action');
    if (context.mounted) showAppSnack(context, errorText(context, e), error: true);
    return false;
  }
}
