import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config.dart';
import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../domain/app_user.dart';
import 'session_providers.dart';

class CoachPendingScreen extends ConsumerWidget {
  const CoachPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    final rejected = user?.coachStatus == CoachStatus.rejected;
    final demo = ref.watch(appModeProvider) == AppMode.demo;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              EmptyState(
                icon: rejected ? Icons.block_rounded : Icons.hourglass_top_rounded,
                title: rejected ? l.coachRejectedTitle : l.coachPendingTitle,
                body: rejected ? l.coachRejectedBody : l.coachPendingBody,
              ),
              const Spacer(),
              if (demo && user != null && !rejected) ...[
                DemoBanner(text: l.demoAccountsSubtitle),
                const SizedBox(height: AppSpacing.sm),
                LoadingButton(
                  label: l.coachPendingDemoApprove,
                  icon: Icons.verified_user_rounded,
                  onPressed: () => runGuarded(
                    context,
                    () => ref.read(userDirectoryRepositoryProvider).setCoachStatus(user.id, CoachStatus.approved),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              OutlinedButton(onPressed: () => ref.read(authRepositoryProvider).signOut(), child: Text(l.signOut)),
            ],
          ),
        ),
      ),
    );
  }
}

class ChildUnsupportedScreen extends ConsumerWidget {
  const ChildUnsupportedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              EmptyState(icon: Icons.child_care_rounded, title: l.roleChild, body: l.childAccountUnsupported),
              const Spacer(),
              OutlinedButton(onPressed: () => ref.read(authRepositoryProvider).signOut(), child: Text(l.signOut)),
            ],
          ),
        ),
      ),
    );
  }
}
