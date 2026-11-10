import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config.dart';
import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../domain/app_user.dart';
import 'splash_screen.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final phone = Validators.normalizePhone(_phone.text);
      final vid = await ref.read(authRepositoryProvider).sendCode(phone);
      if (mounted) context.push(Uri(path: Routes.otp, queryParameters: {'vid': vid, 'phone': phone}).toString());
    } catch (e) {
      if (mounted) showAppSnack(context, errorText(context, e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final repo = ref.watch(authRepositoryProvider);
    final demo = ref.watch(appModeProvider) == AppMode.demo;
    return Scaffold(
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandMark(size: 56),
                  const SizedBox(height: AppSpacing.xl),
                  Text(l.phoneTitle, style: t.headlineMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l.phoneSubtitle, style: t.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.xl),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                      LengthLimitingTextInputFormatter(17),
                    ],
                    style: t.titleMedium,
                    decoration: InputDecoration(
                      labelText: l.phoneLabel,
                      hintText: '5XX XX XX XX',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: Text('🇬🇪  +995', style: t.titleMedium),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    ),
                    validator: (v) => validationText(context, Validators.phone(v)),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LoadingButton(label: l.sendCode, loading: _loading, onPressed: _submit, icon: Icons.sms_rounded),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.push(Routes.explore),
                      icon: const Icon(Icons.map_outlined),
                      label: Text(l.guestBrowse),
                    ),
                  ),
                  if (demo) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _DemoAccounts(accounts: repo.demoAccounts.map((a) => (a.uid, a.label, a.role, a.phone)).toList()),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(l.termsNote, style: t.bodySmall, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoAccounts extends ConsumerWidget {
  const _DemoAccounts({required this.accounts});

  final List<(String, String, UserRole, String)> accounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return AppCard(
      gradient: AppColors.nightGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.volt, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  l.demoBadge,
                  style: t.labelSmall?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(l.demoAccountsTitle, style: t.titleMedium?.copyWith(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l.demoAccountsSubtitle, style: t.bodySmall?.copyWith(color: Colors.white70)),
          const SizedBox(height: AppSpacing.sm),
          for (final (uid, label, role, phone) in accounts)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Material(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: ListTile(
                  key: Key('demo-login-$uid'),
                  leading: InitialsAvatar(name: label, size: 38),
                  title: Text(label, style: t.titleSmall?.copyWith(color: Colors.white)),
                  subtitle: Text(
                    '${uid == 'coach-4' ? l.demoPendingCoach : (role == UserRole.coach ? l.roleCoach : l.roleParent)} · ${Validators.formatPhone(phone)}',
                    style: t.bodySmall?.copyWith(color: Colors.white60),
                  ),
                  trailing: const Icon(Icons.arrow_forward_rounded, color: AppColors.volt),
                  onTap: () => runGuarded(context, () => ref.read(authRepositoryProvider).signInAsDemo(uid)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
