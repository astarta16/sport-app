import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../services/network_status.dart';
import '../theme/app_theme.dart';

/// Thin banner shown app-wide while offline: cached data stays visible,
/// writes fail with a clear error (never a fake success).
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(networkOnlineProvider).value == false;
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: offline
              ? Material(
                  key: const Key('offline-banner'),
                  color: AppColors.warning,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 18, color: AppColors.navy),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              context.l10n.offlineBanner,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.navy),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Expanded(
          child: offline ? MediaQuery.removePadding(context: context, removeTop: true, child: child) : child,
        ),
      ],
    );
  }
}
