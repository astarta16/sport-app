import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config.dart';
import '../../app/di.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../features/authentication/presentation/splash_screen.dart';
import '../../features/demo/data/demo_seed.dart';

class AdminLoginPage extends ConsumerStatefulWidget {
  const AdminLoginPage({super.key});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  String? _verificationId;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _step() async {
    setState(() => _busy = true);
    final repo = ref.read(authRepositoryProvider);
    try {
      if (_verificationId == null) {
        final id = await repo.sendCode(_phone.text);
        setState(() => _verificationId = id);
      } else {
        await repo.verifyCode(_verificationId!, _code.text);
      }
    } catch (e) {
      if (mounted) showAppSnack(context, errorText(context, e), error: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = ref.watch(authRepositoryProvider);
    final demo = ref.watch(appModeProvider) == AppMode.demo;
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BrandMark(size: 56)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l.adminSignInTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l.adminSignInBody, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.lg),
                  if (demo) ...[
                    Text(l.adminDemoAccounts, style: Theme.of(context).textTheme.titleSmall),
                    for (final a in repo.demoAdminAccounts)
                      ListTile(
                        key: Key('admin-demo-${a.uid}'),
                        leading: const Icon(Icons.admin_panel_settings_rounded),
                        title: Text(a.label),
                        subtitle: Text(a.uid == DemoIds.platformAdmin ? l.adminRolePlatform : l.adminRoleClub),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => repo.signInAsDemo(a.uid),
                      ),
                    ListTile(
                      key: const Key('admin-demo-parent'),
                      leading: const Icon(Icons.block_rounded),
                      title: Text(l.adminDemoTryParent),
                      onTap: () => repo.signInAsDemo(DemoIds.parent),
                    ),
                  ] else ...[
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: l.adminPhone, prefixText: '+995 '),
                    ),
                    if (_verificationId != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 6),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    LoadingButton(label: l.adminPhoneSignIn, loading: _busy, onPressed: _step),
                    const SizedBox(height: AppSpacing.sm),
                    Text(l.adminFirebaseLoginNote, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Signed in, but not an administrator: clear permission-denied state.
class AdminDeniedPage extends ConsumerWidget {
  const AdminDeniedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            key: const Key('admin-denied'),
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 56, color: AppColors.danger),
              const SizedBox(height: AppSpacing.md),
              Text(l.adminNotAdminTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(l.adminNotAdminBody, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: Text(l.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
