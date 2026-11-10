import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../clubs/presentation/clubs_providers.dart';
import '../../sports/presentation/sports_providers.dart';
import '../domain/access_policy.dart';
import '../domain/app_user.dart';

/// Registration flow (spec §4.1): role → required fields + sports → consent.
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  int _step = 0;
  UserRole? _role;
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _sports = <String>{};
  final _clubs = <String>{};
  bool _dataConsent = false;
  bool _smsConsent = true;
  bool _loading = false;
  String? _stepError;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  void _next() {
    setState(() => _stepError = null);
    if (_step == 0 && _role == null) return;
    if (_step == 1) {
      if (!_form.currentState!.validate()) return;
      if (_sports.isEmpty) return setState(() => _stepError = context.l10n.validationSportRequired);
      if (_role == UserRole.coach && _clubs.isEmpty) {
        return setState(() => _stepError = context.l10n.validationClubRequired);
      }
    }
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (!_dataConsent) return setState(() => _stepError = context.l10n.validationConsentRequired);
    setState(() => _loading = true);
    await runGuarded(
      context,
      () => ref
          .read(authRepositoryProvider)
          .completeRegistration(
            RegistrationData(
              role: _role!,
              firstName: _first.text,
              lastName: _last.text,
              sportIds: _sports.toList(),
              clubIds: _clubs.toList(),
              dataConsent: _dataConsent,
              smsConsent: _role == UserRole.parent && _smsConsent,
            ),
          ),
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _step > 0 ? BackButton(onPressed: () => setState(() => _step--)) : null,
          title: Text(l.registerTitle),
          actions: [TextButton(onPressed: () => ref.read(authRepositoryProvider).signOut(), child: Text(l.signOut))],
        ),
        body: ConstrainedContent(
          maxWidth: Breakpoints.readable,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: AppSpacing.page,
                  child: Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: i <= _step
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l.stepOf(_step + 1, 3), style: t.bodySmall),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: SingleChildScrollView(
                      key: ValueKey(_step),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: switch (_step) {
                        0 => _roleStep(context),
                        1 => _detailsStep(context),
                        _ => _consentStep(context),
                      },
                    ),
                  ),
                ),
                if (_stepError != null)
                  Padding(
                    padding: AppSpacing.page,
                    child: Text(_stepError!, style: t.bodyMedium?.copyWith(color: AppColors.danger)),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: LoadingButton(
                    label: _step == 2 ? l.finishRegistration : l.continueLabel,
                    loading: _loading,
                    onPressed: _step == 0 && _role == null ? null : _next,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleStep(BuildContext context) {
    final l = context.l10n;
    Widget option(UserRole role, IconData icon, String title, String desc) {
      final enabled = AccessPolicy.canSelfRegisterAs(role);
      final selected = _role == role;
      final scheme = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: AppCard(
            onTap: enabled ? () => setState(() => _role = role) : null,
            color: selected ? scheme.primaryContainer : null,
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selected ? scheme.primary : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: selected ? Colors.white : scheme.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                          if (!enabled) ...[
                            const SizedBox(width: 8),
                            StatusPill(label: l.soon, color: AppColors.neutral, dense: true),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(desc, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_circle_rounded, color: scheme.primary),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.chooseRole, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.lg),
        option(UserRole.parent, Icons.family_restroom_rounded, l.roleParent, l.roleParentDesc),
        option(UserRole.coach, Icons.sports_rounded, l.roleCoach, l.roleCoachDesc),
        option(UserRole.child, Icons.child_care_rounded, l.roleChild, l.roleChildDesc),
      ],
    );
  }

  Widget _detailsStep(BuildContext context) {
    final l = context.l10n;
    final sports = ref.watch(sportsProvider);
    final clubs = ref.watch(clubsProvider);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _first,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l.firstName),
            validator: (v) => validationText(context, Validators.name(v)),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _last,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l.lastName),
            validator: (v) => validationText(context, Validators.name(v)),
          ),
          SectionHeader(l.sportsLabel),
          AsyncView(
            value: sports,
            compact: true,
            loading: const Skeleton(height: 90),
            data: (list) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in list)
                  FilterChip(
                    avatar: Icon(SportVisuals.icon(s.icon), size: 18, color: SportVisuals.color(s.icon)),
                    label: Text(s.name),
                    selected: _sports.contains(s.id),
                    onSelected: (v) => setState(() => v ? _sports.add(s.id) : _sports.remove(s.id)),
                  ),
              ],
            ),
          ),
          if (_role == UserRole.coach) ...[
            SectionHeader(l.clubsLabel),
            AsyncView(
              value: clubs,
              compact: true,
              loading: const Skeleton(height: 120),
              data: (list) => Column(
                children: [
                  for (final c in list.where((c) => _sports.isEmpty || c.sportIds.any(_sports.contains)))
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _clubs.contains(c.id),
                      title: Text(c.name),
                      subtitle: Text(c.address),
                      onChanged: (v) => setState(() => v == true ? _clubs.add(c.id) : _clubs.remove(c.id)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _consentStep(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.privacyTitle, style: t.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(l.consentDataDetails, style: t.bodyMedium)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CheckboxListTile(
          key: const Key('consent-data'),
          contentPadding: EdgeInsets.zero,
          value: _dataConsent,
          onChanged: (v) => setState(() => _dataConsent = v ?? false),
          title: Text(l.consentData, style: t.titleSmall),
        ),
        if (_role == UserRole.parent)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _smsConsent,
            onChanged: (v) => setState(() => _smsConsent = v ?? false),
            title: Text(l.consentSms, style: t.bodyMedium),
          ),
      ],
    );
  }
}
