import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../core/errors/app_exception.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../features/sports/domain/sport.dart';
import '../../core/widgets/entity_options.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/language_selector.dart';
import '../../features/admin/domain/admin_models.dart';
import '../../features/authentication/presentation/session_providers.dart';
import '../../features/clubs/presentation/clubs_providers.dart';
import '../../features/organizations/domain/organization.dart';
import '../../features/organizations/domain/platform.dart';
import '../../features/organizations/domain/repositories.dart';
import '../../features/organizations/presentation/org_providers.dart';
import '../../features/sports/presentation/sport_label.dart';
import '../../features/sports/presentation/sports_providers.dart';
import '../widgets.dart';
import 'admin_providers.dart';
import 'v17_pages.dart';

// ───────────────────────────────────────────────────────────── providers

final platformStatsProvider = StreamProvider.autoDispose<PlatformStats>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(platformRepositoryProvider).watchStats();
});

final packagesProvider = StreamProvider.autoDispose<List<SubscriptionPackage>>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(platformRepositoryProvider).watchPackages();
});

final templatesProvider = StreamProvider.autoDispose<List<OrgTemplate>>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(platformRepositoryProvider).watchTemplates();
});

final invitationsProvider = StreamProvider.autoDispose.family<List<OrgInvitation>, String?>((ref, orgId) {
  ref.watch(currentUidProvider);
  return ref.watch(platformRepositoryProvider).watchInvitations(orgId: orgId);
});

final configHistoryProvider = StreamProvider.autoDispose.family<List<ConfigHistoryEntry>, String>((ref, orgId) {
  ref.watch(currentUidProvider);
  return ref.watch(platformRepositoryProvider).watchHistory(orgId);
});

final orgUsageProvider = FutureProvider.autoDispose.family<OrgUsage, String>((ref, orgId) {
  ref.watch(orgConfigProvider(orgId));
  return ref.watch(platformRepositoryProvider).usage(orgId);
});

// ────────────────────────────────────────────────────────────── labels

String featureLabel(BuildContext context, OrgModule m) => moduleLabel(context, m);

/// v1.9.1: what each feature does, in plain words (no technical ids).
String featureDescription(BuildContext context, OrgModule m) {
  final l = context.l10n;
  return switch (m) {
    OrgModule.trainings => l.featDesc_trainings,
    OrgModule.matches => l.featDesc_matches,
    OrgModule.attendance => l.featDesc_attendance,
    OrgModule.communication => l.featDesc_communication,
    OrgModule.studentAccounts => l.featDesc_studentAccounts,
    OrgModule.brainAcademy => l.featDesc_brainAcademy,
    OrgModule.trainingPlans => l.featDesc_trainingPlans,
    OrgModule.payments => l.featDesc_payments,
    OrgModule.medicalCertificates => l.featDesc_medicalCertificates,
    OrgModule.media => l.featDesc_media,
    OrgModule.leaderboards => l.featDesc_leaderboards,
    OrgModule.roomScheduling => l.featDesc_roomScheduling,
    OrgModule.notifications => l.featDesc_notifications,
    OrgModule.parentRsvp => l.featDesc_parentRsvp,
    OrgModule.messageAcks => l.featDesc_messageAcks,
    OrgModule.coachChallenges => l.featDesc_coachChallenges,
    OrgModule.paymentReceipts => l.featDesc_paymentReceipts,
    OrgModule.paymentVerification => l.featDesc_paymentVerification,
    OrgModule.paymentReminders => l.featDesc_paymentReminders,
    OrgModule.facilities => l.featDesc_facilities,
    OrgModule.reports => l.featDesc_reports,
    OrgModule.dataExports => l.featDesc_dataExports,
  };
}

String categoryLabel(BuildContext context, FeatureCategory c) {
  final l = context.l10n;
  return switch (c) {
    FeatureCategory.core => l.featCatCore,
    FeatureCategory.communication => l.featCatCommunication,
    FeatureCategory.learning => l.featCatLearning,
    FeatureCategory.finance => l.featCatFinance,
    FeatureCategory.facilities => l.featCatFacilities,
    FeatureCategory.administration => l.featCatAdministration,
  };
}

String subscriptionLabel(BuildContext context, SubscriptionStatus s) {
  final l = context.l10n;
  return switch (s) {
    SubscriptionStatus.trial => l.subTrial,
    SubscriptionStatus.active => l.subActive,
    SubscriptionStatus.pastDue => l.subPastDue,
    SubscriptionStatus.suspended => l.subSuspended,
    SubscriptionStatus.cancelled => l.subCancelled,
    SubscriptionStatus.expired => l.subExpired,
  };
}

Color subscriptionColor(SubscriptionStatus s) => switch (s) {
  SubscriptionStatus.trial => AppColors.blue,
  SubscriptionStatus.active => AppColors.success,
  SubscriptionStatus.pastDue => AppColors.warning,
  _ => AppColors.danger,
};

String rolloutLabel(BuildContext context, RolloutState s) {
  final l = context.l10n;
  return switch (s) {
    RolloutState.enabled => l.rolloutEnabled,
    RolloutState.disabled => l.rolloutDisabled,
    RolloutState.trial => l.rolloutTrial,
    RolloutState.scheduled => l.rolloutScheduled,
  };
}

String blockLabel(BuildContext context, EntitlementBlock? b) {
  final l = context.l10n;
  return switch (b) {
    null => l.effOn,
    EntitlementBlock.orgInactive => l.effOrgInactive,
    EntitlementBlock.provisioning => l.effProvisioning,
    EntitlementBlock.readOnly => l.effReadOnly,
    EntitlementBlock.notInPackage => l.effNotInPackage,
    EntitlementBlock.notEntitled => l.effNotEntitled,
    EntitlementBlock.rolloutOff => l.effRolloutOff,
    EntitlementBlock.disabledByOrg => l.effDisabledByOrg,
    EntitlementBlock.dependencyMissing => l.effDependencyMissing,
  };
}

String orgTypeLabel(BuildContext context, OrgType t) {
  final l = context.l10n;
  return switch (t) {
    OrgType.sportsSchool => l.orgTypeSchool,
    OrgType.club => l.orgTypeClub,
    OrgType.academy => l.orgTypeAcademy,
    OrgType.independentCoach => l.orgTypeIndependent,
    OrgType.other => l.orgTypeOther,
  };
}

String fundingLabel(BuildContext context, FundingType f) {
  final l = context.l10n;
  return switch (f) {
    FundingType.government => l.fundGovernment,
    FundingType.private => l.fundPrivate,
    FundingType.nonprofit => l.fundNonprofit,
    FundingType.mixed => l.fundMixed,
    FundingType.other => l.fundOther,
  };
}

String invitationLabel(BuildContext context, InvitationStatus s) {
  final l = context.l10n;
  return switch (s) {
    InvitationStatus.pending => l.invPending,
    InvitationStatus.accepted => l.invAccepted,
    InvitationStatus.rejected => l.invRejected,
    InvitationStatus.revoked => l.invRevoked,
    InvitationStatus.expired => l.invExpired,
  };
}

String alertLabel(BuildContext context, AlertKind k) {
  final l = context.l10n;
  return switch (k) {
    AlertKind.overLimit => l.alertOverLimit,
    AlertKind.trialEnding => l.alertTrialEnding,
    AlertKind.pastDue => l.alertPastDue,
    AlertKind.readOnly => l.alertReadOnly,
    AlertKind.provisioningStuck => l.alertProvisioning,
    AlertKind.invitationExpiring => l.alertInvitationExpiring,
  };
}

/// Localized validation / conflict text for platform operations.
String platformErrorText(BuildContext context, Object e) {
  final l = context.l10n;
  if (e is ConfigConflictException) return l.configConflict(e.currentVersion);
  if (e is ValidationException) {
    final code = e.code;
    if (code.startsWith('notInPackage:')) return l.errNotInPackage;
    return switch (code) {
      'featureDependencies' => l.errFeatureDependencies,
      'changeReason' => l.errChangeReason,
      'orgName' => l.errOrgName,
      'orgAddress' || 'orgCity' => l.errOrgAddress,
      'orgEmail' => l.errOrgEmail,
      'orgPhone' => l.errOrgPhone,
      'orgSports' => l.errOrgSports,
      'orgAdminMissing' => l.errOrgAdmin,
      'brandContrast' => l.errBrandContrast,
      'invitationExpired' => l.errInvitationExpired,
      'invitationClosed' => l.errInvitationClosed,
      'rolloutDate' => l.errRolloutDate,
      'limitStudents' || 'limitCoaches' || 'limitGroups' || 'limitRooms' => l.errLimitReached,
      _ => errorText(context, e),
    };
  }
  return errorText(context, e);
}

Future<bool> runPlatform(BuildContext context, Future<void> Function() action, {String? success}) async {
  try {
    await action();
    if (context.mounted && success != null) showAppSnack(context, success);
    return true;
  } catch (e) {
    if (context.mounted) showAppSnack(context, platformErrorText(context, e), error: true);
    return false;
  }
}

Future<String?> askChangeReason(BuildContext context, {String? title}) => showDialog<String>(
  context: context,
  builder: (_) => _ChangeReasonDialog(title: title),
);

class _ChangeReasonDialog extends StatefulWidget {
  const _ChangeReasonDialog({this.title});

  final String? title;

  @override
  State<_ChangeReasonDialog> createState() => _ChangeReasonDialogState();
}

class _ChangeReasonDialogState extends State<_ChangeReasonDialog> {
  final _c = TextEditingController();
  String? _error;

  void _submit() {
    final v = _c.text.trim();
    // v1.9: explain why nothing happens instead of ignoring the tap.
    if (v.length < 3) return setState(() => _error = context.l10n.errChangeReason);
    Navigator.pop(context, v);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.title ?? l.changeReasonTitle),
      content: TextField(
        key: const Key('change-reason'),
        controller: _c,
        autofocus: true,
        maxLength: 300,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(hintText: l.changeReasonHint, errorText: _error),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(key: const Key('change-reason-ok'), onPressed: _submit, child: Text(l.save)),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────── overview

class PlatformOverviewPage extends ConsumerWidget {
  const PlatformOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final audit = ref.watch(adminAuditProvider).value ?? const <AuditEntry>[];
    return AdminSection(
      title: l.platformOverview,
      subtitle: l.platformOverviewSubtitle,
      child: AsyncView<PlatformStats>(
        value: ref.watch(platformStatsProvider),
        data: (s) => Column(
          key: const Key('platform-overview'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (s.synthetic)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: StatusPill(label: l.syntheticData, color: AppColors.warning, icon: Icons.science_rounded),
              ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (label, value, icon) in [
                  (l.statOrganizations, s.organizations, Icons.domain_rounded),
                  (l.orgStatusActive, s.active, Icons.check_circle_rounded),
                  (l.orgStatusSuspended, s.suspended, Icons.pause_circle_rounded),
                  (l.subTrial, s.trial, Icons.hourglass_top_rounded),
                  (l.statUsers, s.users, Icons.people_rounded),
                  (l.orgCoaches, s.coaches, Icons.sports_rounded),
                  (l.statStudents, s.students, Icons.child_care_rounded),
                  (l.statParents, s.parents, Icons.family_restroom_rounded),
                ])
                  SizedBox(
                    width: 200,
                    child: StatCard(label: label, value: value, icon: icon),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l.featureAdoption, style: Theme.of(context).textTheme.titleMedium),
            for (final d in FeatureCatalog.defs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(width: 220, child: Text(featureLabel(context, d.module), overflow: TextOverflow.ellipsis)),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: s.organizations == 0 ? 0 : (s.adoption[d.module] ?? 0) / s.organizations,
                        minHeight: 8,
                      ),
                    ),
                    SizedBox(width: 48, child: Text('  ${s.adoption[d.module] ?? 0}')),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(l.subscriptionsTitle, style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in s.bySubscription.entries)
                  if (e.value > 0)
                    StatusPill(
                      label: '${subscriptionLabel(context, e.key)}: ${e.value}',
                      color: subscriptionColor(e.key),
                    ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l.operationalAlerts, style: Theme.of(context).textTheme.titleMedium),
            if (s.alerts.isEmpty) Text(l.noAlerts),
            for (final a in s.alerts)
              ListTile(
                key: Key('alert-${a.kind.name}-${a.orgId}'),
                dense: true,
                leading: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                title: Text('${alertLabel(context, a.kind)} · ${orgName(context, ref, a.orgId)}'),
                subtitle: a.detail.isEmpty ? null : Text(a.detail),
                onTap: () => context.go('/organizations/${a.orgId}'),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(l.recentAdminActions, style: Theme.of(context).textTheme.titleMedium),
            for (final e in audit.take(8))
              ListTile(
                dense: true,
                leading: const Icon(Icons.history_rounded),
                title: Text(e.action),
                subtitle: Text('${e.actorName} · ${Fmt.of(context).dateTime(e.at)}'),
              ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────── organization directory

class OrgDirectoryPage extends ConsumerWidget {
  const OrgDirectoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final packages = {for (final p in ref.watch(packagesProvider).value ?? const <SubscriptionPackage>[]) p.id: p};
    final clubs = ref.watch(clubsByIdProvider);
    final locale = Localizations.localeOf(context).languageCode;
    return AdminSection(
      title: l.adminNavOrganizations,
      subtitle: l.orgPlatformSubtitle,
      actions: [
        FilledButton.icon(
          key: const Key('org-new'),
          onPressed: () => showProvisionDialog(context, ref),
          icon: const Icon(Icons.add_business_rounded),
          label: Text(l.orgNew),
        ),
      ],
      child: AsyncView<List<OrgConfig>>(
        value: ref.watch(orgConfigsProvider),
        data: (list) => AdminTable<OrgConfig>(
          rows: list,
          searchText: (c) => '${orgName(context, ref, c.orgId)} ${c.profile.legalName} ${c.profile.city}',
          filters: [
            (l.adminFilterAll, (_) => true),
            (l.orgStatusActive, (c) => c.isActive),
            (l.orgStatusSuspended, (c) => !c.isActive),
            (l.subTrial, (c) => c.subscription.status == SubscriptionStatus.trial),
            (l.fundGovernment, (c) => c.profile.funding == FundingType.government),
            (l.fundPrivate, (c) => c.profile.funding == FundingType.private),
          ],
          columns: [
            AdminColumn(
              l.adminColName,
              (c) => InkWell(
                key: Key('org-open-${c.orgId}'),
                onTap: () => context.go('/organizations/${c.orgId}'),
                child: Text(
                  orgName(context, ref, c.orgId),
                  key: Key('org-row-${c.orgId}'),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.blue),
                ),
              ),
              flex: 3,
              sortKey: (c) => orgName(context, ref, c.orgId),
            ),
            AdminColumn(l.orgTypeLabel, (c) => Text(orgTypeLabel(context, c.profile.type)), flex: 2),
            AdminColumn(l.orgFunding, (c) => Text(fundingLabel(context, c.profile.funding)), flex: 2),
            AdminColumn(
              l.packageLabel,
              (c) => Text(packages[c.packageId]?.nameFor(locale) ?? c.packageId),
              flex: 2,
              sortKey: (c) => c.packageId,
            ),
            AdminColumn(
              l.subscriptionLabel,
              (c) => Align(
                alignment: Alignment.centerLeft,
                child: StatusPill(
                  label: subscriptionLabel(context, c.subscription.status),
                  color: subscriptionColor(c.subscription.status),
                  dense: true,
                ),
              ),
              flex: 2,
            ),
            AdminColumn(
              l.adminColStatus,
              (c) => Text(orgStatusLabel(context, c.status)),
              sortKey: (c) => c.status.index,
            ),
            AdminColumn(
              l.orgModulesOn,
              (c) => Text('${EntitlementResolver.effectiveModules(c, DateTime.now()).length}'),
            ),
            AdminColumn(l.orgAdmins, (c) => Text('${clubs[c.orgId]?.adminIds.length ?? 0}')),
            AdminColumn(
              '',
              (c) => Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    key: Key('org-manage-${c.orgId}'),
                    tooltip: l.orgManage,
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: () => showOrgPlatformDialog(context, ref, c),
                  ),
                  IconButton(
                    key: Key('org-admins-${c.orgId}'),
                    tooltip: l.orgAssignAdmin,
                    icon: const Icon(Icons.admin_panel_settings_rounded),
                    onPressed: () => showOrgAdminDialog(context, ref, c.orgId),
                  ),
                  IconButton(
                    key: Key('org-health-${c.orgId}'),
                    tooltip: l.orgHealth,
                    icon: const Icon(Icons.monitor_heart_rounded),
                    onPressed: () => showOrgHealthDialog(context, ref, c),
                  ),
                ],
              ),
              flex: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Provisioning wizard: profile → package & template → features → admin.
Future<void> showProvisionDialog(BuildContext context, WidgetRef ref) =>
    showDialog<void>(context: context, builder: (_) => const _ProvisionDialog());

class _ProvisionDialog extends ConsumerStatefulWidget {
  const _ProvisionDialog();

  @override
  ConsumerState<_ProvisionDialog> createState() => _ProvisionDialogState();
}

class _ProvisionDialogState extends ConsumerState<_ProvisionDialog> {
  int _step = 0;
  final _ka = TextEditingController();
  final _en = TextEditingController();
  final _ru = TextEditingController();
  final _legal = TextEditingController();
  final _reg = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _logo = TextEditingController();
  final _desc = TextEditingController();
  final _adminPhone = TextEditingController();
  final _adminEmail = TextEditingController();
  var _type = OrgType.club;
  var _funding = FundingType.private;
  var _tz = OrgTimeZones.tbilisi;
  var _lang = 'ka';
  var _packageId = SubscriptionPackage.professionalId;
  String? _templateId;
  Set<OrgModule> _modules = {};
  var _subStatus = SubscriptionStatus.active;
  var _color = 0xFF1D4ED8;
  final _sports = <String>{};
  String? _error;
  // v1.9: steps whose "Next" was pressed show their field errors inline.
  final _tried = <int>{};

  static const _stepCodes = <int, Set<String>>{
    0: {'orgName', 'orgAddress', 'orgCity', 'orgEmail', 'orgPhone', 'orgSports', 'brandContrast'},
    2: {'featureDependencies'},
    3: {'orgAdminMissing'},
  };

  List<String> _codes(int step) => [
    for (final c in ProvisionRequest.validate(_request))
      if (_stepCodes[step]?.contains(c) ?? false) c,
  ];

  String? _err(int step, String code) => _tried.contains(step) && _codes(step).contains(code)
      ? platformErrorText(context, ValidationException(code))
      : null;
  bool _busy = false;

  void _applyTemplate(OrgTemplate? t, List<SubscriptionPackage> pkgs) {
    setState(() {
      _templateId = t?.id;
      if (t != null) {
        _packageId = t.packageId;
        _type = t.type;
        _funding = t.funding;
        _modules = {...t.modules};
      } else {
        final p = pkgs.where((x) => x.id == _packageId).firstOrNull;
        _modules = p == null ? {} : p.modules.difference(FeatureCatalog.restricted);
      }
    });
  }

  ProvisionRequest get _request => ProvisionRequest(
    names: {
      if (_ka.text.trim().isNotEmpty) 'ka': _ka.text.trim(),
      if (_en.text.trim().isNotEmpty) 'en': _en.text.trim(),
      if (_ru.text.trim().isNotEmpty) 'ru': _ru.text.trim(),
    },
    legalName: _legal.text.trim(),
    type: _type,
    funding: _funding,
    registrationId: _reg.text.trim().isEmpty ? null : _reg.text.trim(),
    address: _address.text,
    city: _city.text,
    contactEmail: _email.text,
    contactPhone: _phone.text,
    logoUrl: _logo.text.trim().isEmpty ? null : _logo.text.trim(),
    description: _desc.text.trim(),
    primaryColor: _color,
    sportIds: _sports.toList(),
    timezone: _tz,
    defaultLanguage: _lang,
    packageId: _packageId,
    templateId: _templateId,
    modules: _modules,
    subscription: SubscriptionInfo(status: _subStatus),
    adminPhone: _adminPhone.text.trim().isEmpty ? null : _adminPhone.text.trim(),
    adminEmail: _adminEmail.text.trim().isEmpty ? null : _adminEmail.text.trim(),
  );

  Future<void> _submit() async {
    final l = context.l10n;
    final errors = ProvisionRequest.validate(_request);
    if (errors.isNotEmpty) {
      final step = [0, 2, 3].firstWhere((s) => _codes(s).isNotEmpty, orElse: () => _step);
      setState(() {
        _tried.add(step);
        _step = step;
        _error = platformErrorText(context, ValidationException(errors.first));
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ref.read(platformRepositoryProvider).provisionOrganization(_request);
      if (!mounted) return;
      Navigator.pop(context);
      await showInvitationTokenDialog(context, r.token, title: l.orgProvisioned);
    } catch (e) {
      if (mounted) setState(() => _error = platformErrorText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _review(BuildContext context, SubscriptionPackage? pkg, List<OrgTemplate> tpls, List<Sport> sports) {
    final l = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final r = _request;
    Widget row(String label, String value, int step) => ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: Theme.of(context).textTheme.labelLarge),
      subtitle: Text(value.isEmpty ? '—' : value),
      trailing: TextButton(onPressed: () => setState(() => _step = step), child: Text(l.edit)),
    );
    return Column(
      key: const Key('provision-review'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(l.adminColName, r.names.values.join(' / '), 0),
        row(l.orgLegalName, r.legalName, 0),
        row(l.orgTypeLabel, '${orgTypeLabel(context, r.type)} · ${fundingLabel(context, r.funding)}', 0),
        row(l.orgCity, '${r.city} · ${r.address}', 0),
        row(
          l.sportsLabel,
          [
            for (final s in sports)
              if (_sports.contains(s.id)) s.label(context),
          ].join(', '),
          0,
        ),
        row(
          l.packageLabel,
          [
            pkg?.nameFor(locale) ?? _packageId,
            if (_templateId != null) tpls.where((t) => t.id == _templateId).firstOrNull?.nameFor(locale) ?? '',
            subscriptionLabel(context, _subStatus),
          ].where((x) => x.isNotEmpty).join(' · '),
          1,
        ),
        row(l.initialFeatures, _modules.map((m) => featureLabel(context, m)).join(', '), 2),
        row(l.inviteAdmin, [?r.adminPhone, ?r.adminEmail].join(' · '), 3),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final pkgs = ref.watch(packagesProvider).value ?? const <SubscriptionPackage>[];
    final tpls = (ref.watch(templatesProvider).value ?? const <OrgTemplate>[]).where((t) => !t.archived).toList();
    final sports = ref.watch(sportsProvider).value ?? const [];
    final pkg = pkgs.where((p) => p.id == _packageId).firstOrNull;
    final missing = FeatureCatalog.missing(_modules);
    Widget field(String key, TextEditingController c, String label, {double width = 260, String? error}) => SizedBox(
      width: width,
      child: TextField(
        key: Key(key),
        controller: c,
        onChanged: (_) => _tried.isEmpty ? null : setState(() {}),
        decoration: InputDecoration(labelText: label, errorText: error),
      ),
    );
    final steps = <Widget>[
      // 1. profile
      Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          field('prov-name-ka', _ka, '${l.orgNameKa} *', error: _err(0, 'orgName')),
          field('prov-name-en', _en, l.orgNameEn),
          field('prov-name-ru', _ru, l.orgNameRu),
          field('prov-legal', _legal, '${l.orgLegalName} *', error: _err(0, 'orgName')),
          field('prov-reg', _reg, l.orgRegistrationId),
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<OrgType>(
              initialValue: _type,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.orgTypeLabel),
              items: [
                for (final t in OrgType.values) DropdownMenuItem(value: t, child: Text(orgTypeLabel(context, t))),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
          ),
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<FundingType>(
              key: const Key('prov-funding'),
              initialValue: _funding,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.orgFunding),
              items: [
                for (final f in FundingType.values) DropdownMenuItem(value: f, child: Text(fundingLabel(context, f))),
              ],
              onChanged: (v) => setState(() => _funding = v ?? _funding),
            ),
          ),
          field('prov-address', _address, '${l.adminColAddress} *', error: _err(0, 'orgAddress')),
          field('prov-city', _city, '${l.orgCity} *', error: _err(0, 'orgCity')),
          field('prov-email', _email, '${l.orgContactEmail} *', error: _err(0, 'orgEmail')),
          field('prov-phone', _phone, '${l.orgContactPhone} *', error: _err(0, 'orgPhone')),
          field('prov-logo', _logo, l.orgLogoUrl, width: 532),
          field('prov-desc', _desc, l.orgDescription, width: 532),
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<String>(
              initialValue: _tz,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.orgTimezone),
              items: [for (final z in OrgTimeZones.offsets.keys) DropdownMenuItem(value: z, child: Text(z))],
              onChanged: (v) => setState(() => _tz = v ?? _tz),
            ),
          ),
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<String>(
              initialValue: _lang,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.orgDefaultLanguage),
              items: [
                for (final (code, name) in LanguageSelector.options) DropdownMenuItem(value: code, child: Text(name)),
              ],
              onChanged: (v) => setState(() => _lang = v ?? _lang),
            ),
          ),
          SizedBox(
            width: 532,
            child: SportsPickerField.multi(
              sports: sports,
              values: _sports,
              required: true,
              errorText: _err(0, 'orgSports'),
              onChangedMulti: (v) => setState(() {
                _sports
                  ..clear()
                  ..addAll(v);
              }),
            ),
          ),
          _ColorPick(value: _color, onChanged: (c) => setState(() => _color = c)),
        ],
      ),
      // 2. package & template
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String?>(
            key: const Key('prov-template'),
            initialValue: _templateId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.templateLabel),
            items: [
              DropdownMenuItem(value: null, child: Text(l.none)),
              for (final t in tpls) DropdownMenuItem(value: t.id, child: Text(t.nameFor(locale))),
            ],
            onChanged: (v) => _applyTemplate(tpls.where((t) => t.id == v).firstOrNull, pkgs),
          ),
          Text(l.fundingNote, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            key: const Key('prov-package'),
            initialValue: pkgs.any((p) => p.id == _packageId) ? _packageId : null,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.packageLabel),
            items: [
              for (final p in pkgs.where((p) => !p.archived))
                DropdownMenuItem(value: p.id, child: Text(p.nameFor(locale))),
            ],
            onChanged: (v) => setState(() {
              _packageId = v ?? _packageId;
              final p = pkgs.where((x) => x.id == _packageId).firstOrNull;
              if (p != null && !p.custom) _modules = _modules.intersection(p.modules);
            }),
          ),
          DropdownButtonFormField<SubscriptionStatus>(
            initialValue: _subStatus,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.subscriptionLabel),
            items: [
              for (final s in [SubscriptionStatus.trial, SubscriptionStatus.active])
                DropdownMenuItem(value: s, child: Text(subscriptionLabel(context, s))),
            ],
            onChanged: (v) => setState(() => _subStatus = v ?? _subStatus),
          ),
        ],
      ),
      // 3. features
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.initialFeatures, style: Theme.of(context).textTheme.titleSmall),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final d in FeatureCatalog.defs)
                FilterChip(
                  key: Key('prov-feature-${d.module.name}'),
                  label: Text(featureLabel(context, d.module)),
                  selected: _modules.contains(d.module),
                  onSelected: pkg != null && !pkg.includes(d.module)
                      ? null
                      : (v) => setState(() => v ? _modules.add(d.module) : _modules.remove(d.module)),
                ),
            ],
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.missingDependencies(missing.keys.map((m) => featureLabel(context, m)).join(', ')),
              style: const TextStyle(color: AppColors.danger),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('prov-add-deps'),
                onPressed: () => setState(() => _modules = FeatureCatalog.withDependencies(_modules)),
                child: Text(l.addDependencies),
              ),
            ),
          ],
        ],
      ),
      // 4. admin
      Wrap(
        spacing: 12,
        children: [
          field('prov-admin-phone', _adminPhone, l.adminPhoneLabel, error: _err(3, 'orgAdminMissing')),
          field('prov-admin-email', _adminEmail, l.adminEmailLabel),
          Text(l.invitationNote, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      // 5. review (v1.9): everything at a glance before anything is created.
      _review(context, pkg, tpls, sports),
    ];
    final stepNames = [l.wizBasics, l.wizPackage, l.wizFeatures, l.wizAdmin, l.wizReview];
    return AlertDialog(
      key: const Key('provision-dialog'),
      title: Text(l.orgNew),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppStepHeader(steps: stepNames, current: _step, onStep: (i) => setState(() => _step = i)),
              const SizedBox(height: AppSpacing.md),
              steps[_step],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    _error!,
                    key: const Key('provision-error'),
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        if (_step > 0) TextButton(onPressed: () => setState(() => _step--), child: Text(l.back)),
        if (_step < 4)
          FilledButton(
            key: const Key('provision-next'),
            onPressed: () {
              if (_step == 1 && _modules.isEmpty) {
                _applyTemplate(tpls.where((t) => t.id == _templateId).firstOrNull, pkgs);
              }
              // v1.9: validate this step before moving on.
              if (_codes(_step).isNotEmpty) {
                setState(() {
                  _tried.add(_step);
                  _error = l.wizFixErrors;
                });
                return;
              }
              setState(() {
                _error = null;
                _step++;
              });
            },
            child: Text(l.next),
          )
        else
          FilledButton(
            key: const Key('provision-create'),
            onPressed: _busy ? null : _submit,
            child: Text(l.orgCreateButton),
          ),
      ],
    );
  }
}

class _ColorPick extends StatelessWidget {
  const _ColorPick({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const colors = [
    0xFF1D4ED8,
    0xFF0F766E,
    0xFF7C2D12,
    0xFF7C3AED,
    0xFFBE123C,
    0xFF15803D,
    0xFF0F172A,
    0xFFFACC15,
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(context.l10n.orgBrandColor),
      for (final c in colors)
        InkWell(
          key: Key('brand-color-${c.toRadixString(16)}'),
          onTap: () => onChanged(c),
          child: CircleAvatar(
            radius: 13,
            backgroundColor: Color(c),
            child: c == value ? Icon(Icons.check_rounded, size: 16, color: Color(BrandContrast.onColor(c))) : null,
          ),
        ),
      if (!BrandContrast.acceptable(value))
        Text(context.l10n.errBrandContrast, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
    ],
  );
}

Future<void> showInvitationTokenDialog(BuildContext context, String token, {String? title}) {
  final l = context.l10n;
  final link = 'https://admin.sportparent.example/invite?token=$token';
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('invitation-token-dialog'),
      title: Text(title ?? l.invitationCreated),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.invitationLinkNote),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(link, key: const Key('invitation-link')),
          const SizedBox(height: AppSpacing.xs),
          Text(l.invitationTokenLabel, style: Theme.of(context).textTheme.labelSmall),
          SelectableText(token, key: const Key('invitation-token')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: link)),
          child: Text(l.copyLink),
        ),
        FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.close)),
      ],
    ),
  );
}

// ───────────────────────────────────────────────── organization detail

class OrgDetailPage extends ConsumerWidget {
  const OrgDetailPage({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tabs = [
      l.tabOverview,
      l.tabAdmins,
      l.tabFeatures,
      l.tabSubscription,
      l.tabBranding,
      l.tabUsage,
      l.tabAudit,
      l.tabSettings,
    ];
    return AsyncView<OrgConfig>(
      value: ref.watch(orgConfigProvider(orgId)),
      data: (cfg) => DefaultTabController(
        length: tabs.length,
        child: Column(
          key: Key('org-detail-$orgId'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('org-detail-back'),
                    onPressed: () => context.go('/organizations'),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  CircleAvatar(backgroundColor: Color(cfg.branding.primaryColor), radius: 12),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(orgName(context, ref, orgId), style: Theme.of(context).textTheme.headlineSmall)),
                  Text('v${cfg.version}', key: const Key('org-config-version')),
                ],
              ),
            ),
            TabBar(isScrollable: true, tabs: [for (final t in tabs) Tab(text: t)]),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(cfg: cfg),
                  _AdminsTab(cfg: cfg),
                  FeaturesEditor(key: ValueKey('features-${cfg.orgId}-${cfg.version}'), cfg: cfg),
                  _SubscriptionTab(key: ValueKey('sub-${cfg.version}'), cfg: cfg),
                  _BrandingTab(cfg: cfg),
                  _UsageTab(cfg: cfg),
                  _HistoryTab(orgId: orgId),
                  _SettingsTab(cfg: cfg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _pad(List<Widget> children) => ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: children);

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.cfg});

  final OrgConfig cfg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    return _pad([
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          StatusPill(label: orgStatusLabel(context, cfg.status), color: orgStatusColor(cfg.status)),
          StatusPill(
            label: subscriptionLabel(context, cfg.subscription.status),
            color: subscriptionColor(cfg.subscription.status),
          ),
          StatusPill(label: orgTypeLabel(context, cfg.profile.type), color: AppColors.blue),
          StatusPill(label: fundingLabel(context, cfg.profile.funding), color: AppColors.neutral),
          if (cfg.provisioning != ProvisioningState.ready)
            StatusPill(label: l.effProvisioning, color: AppColors.warning),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      Text('${l.orgLegalName}: ${cfg.profile.legalName}'),
      Text('${l.orgCity}: ${cfg.profile.city}'),
      Text('${l.orgContactEmail}: ${cfg.branding.contactEmail ?? '—'}'),
      Text('${l.orgContactPhone}: ${cfg.branding.contactPhone ?? '—'}'),
      Text('${l.packageLabel}: ${cfg.packageId}'),
      if (cfg.subscription.endAt != null) Text('${l.subscriptionEnds}: ${f.fullDate(cfg.subscription.endAt!)}'),
      Text('${l.lastChange}: v${cfg.version} · ${cfg.updatedBy ?? '—'} · ${cfg.changeReason ?? ''}'),
      const SizedBox(height: AppSpacing.md),
      Text(l.orgModulesOn, style: Theme.of(context).textTheme.titleSmall),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final m in EntitlementResolver.effectiveModules(cfg, DateTime.now()))
            Chip(label: Text(featureLabel(context, m))),
        ],
      ),
    ]);
  }
}

class _AdminsTab extends ConsumerStatefulWidget {
  const _AdminsTab({required this.cfg});

  final OrgConfig cfg;

  @override
  ConsumerState<_AdminsTab> createState() => _AdminsTabState();
}

class _AdminsTabState extends ConsumerState<_AdminsTab> {
  // v1.9: kept in state — typed input survives stream rebuilds.
  final phone = TextEditingController();
  final email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    phone.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.cfg;
    final l = context.l10n;
    final club = ref.watch(clubsByIdProvider)[cfg.orgId];
    final invites = ref.watch(invitationsProvider(cfg.orgId)).value ?? const <OrgInvitation>[];
    return _pad([
      Text(l.orgAdmins, style: Theme.of(context).textTheme.titleMedium),
      for (final a in club?.adminIds ?? const <String>[])
        ListTile(
          key: Key('org-admin-$a'),
          leading: const Icon(Icons.admin_panel_settings_rounded),
          title: Consumer(builder: (context, ref, _) => Text(ref.watch(publicProfileProvider(a)).value?.fullName ?? a)),
          trailing: TextButton(
            key: Key('org-admin-remove-$a'),
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                title: l.orgRemoveAdmin,
                message: l.confirmRemoveAdminBody,
                confirmLabel: l.orgRemoveAdmin,
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              await runPlatform(
                context,
                () => ref.read(organizationsRepositoryProvider).setOrgAdmin(cfg.orgId, a, admin: false),
                success: l.adminRemovedSnack,
              );
            },
            child: Text(l.orgRemoveAdmin),
          ),
        ),
      const Divider(),
      Text(l.inviteAdmin, style: Theme.of(context).textTheme.titleMedium),
      Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          SizedBox(
            width: 240,
            child: TextField(
              key: const Key('invite-phone'),
              controller: phone,
              decoration: InputDecoration(labelText: l.adminPhoneLabel),
            ),
          ),
          SizedBox(
            width: 240,
            child: TextField(
              key: const Key('invite-email'),
              controller: email,
              decoration: InputDecoration(labelText: l.adminEmailLabel),
            ),
          ),
          FilledButton.icon(
            key: const Key('invite-send'),
            onPressed: _busy
                ? null
                : () async {
                    if (phone.text.trim().isEmpty && email.text.trim().isEmpty) {
                      showAppSnack(context, l.errOrgAdmin, error: true);
                      return;
                    }
                    setState(() => _busy = true);
                    try {
                      final r = await ref
                          .read(platformRepositoryProvider)
                          .inviteAdmin(
                            cfg.orgId,
                            phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
                            email: email.text.trim().isEmpty ? null : email.text.trim(),
                          );
                      phone.clear();
                      email.clear();
                      if (context.mounted) await showInvitationTokenDialog(context, r.token);
                    } catch (e) {
                      if (context.mounted) showAppSnack(context, platformErrorText(context, e), error: true);
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
            icon: const Icon(Icons.send_rounded),
            label: Text(l.inviteAdmin),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      InvitationsTable(invitations: invites),
    ]);
  }
}

class InvitationsTable extends ConsumerWidget {
  const InvitationsTable({super.key, required this.invitations});

  final List<OrgInvitation> invitations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    return AdminTable<OrgInvitation>(
      rows: invitations,
      searchText: (i) => '${i.phone ?? ''} ${i.email ?? ''} ${orgName(context, ref, i.orgId)}',
      columns: [
        AdminColumn(l.orgLabel, (i) => Text(orgName(context, ref, i.orgId)), flex: 2),
        AdminColumn(l.inviteRecipient, (i) => Text(i.phone ?? i.email ?? ''), flex: 2),
        AdminColumn(l.adminColStatus, (i) => Text(invitationLabel(context, i.status), key: Key('inv-status-${i.id}'))),
        AdminColumn(l.inviteExpires, (i) => Text(f.dateTime(i.expiresAt))),
        AdminColumn(
          '',
          (i) => Wrap(
            children: [
              if (i.status == InvitationStatus.pending || i.status == InvitationStatus.expired)
                IconButton(
                  key: Key('inv-resend-${i.id}'),
                  tooltip: l.inviteResend,
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () async {
                    try {
                      final r = await ref.read(platformRepositoryProvider).resendInvitation(i.id);
                      if (context.mounted) await showInvitationTokenDialog(context, r.token);
                    } catch (e) {
                      if (context.mounted) showAppSnack(context, platformErrorText(context, e), error: true);
                    }
                  },
                ),
              if (i.status == InvitationStatus.pending)
                IconButton(
                  key: Key('inv-revoke-${i.id}'),
                  tooltip: l.inviteRevoke,
                  icon: const Icon(Icons.block_rounded, color: AppColors.danger),
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      title: l.inviteRevoke,
                      message: l.confirmRevokeBody,
                      confirmLabel: l.inviteRevoke,
                      destructive: true,
                    );
                    if (!ok || !context.mounted) return;
                    await runPlatform(
                      context,
                      () => ref.read(platformRepositoryProvider).revokeInvitation(i.id),
                      success: l.invitationRevokedSnack,
                    );
                  },
                ),
            ],
          ),
          flex: 2,
        ),
      ],
    );
  }
}

/// Features tab: level-1 entitlements and rollout for one organization,
/// with dependency validation, preview, reason and version conflict handling.
class FeaturesEditor extends ConsumerStatefulWidget {
  const FeaturesEditor({super.key, required this.cfg});

  final OrgConfig cfg;

  @override
  ConsumerState<FeaturesEditor> createState() => _FeaturesEditorState();
}

class _FeaturesEditorState extends ConsumerState<FeaturesEditor> {
  late Set<OrgModule> _allowed = {...widget.cfg.allowedModules};
  late Map<OrgModule, FeatureRollout> _rollout = {...widget.cfg.rollout};
  String _query = '';
  FeatureCategory? _category;

  bool get _dirty =>
      _allowed.length != widget.cfg.allowedModules.length ||
      !_allowed.containsAll(widget.cfg.allowedModules) ||
      _rollout.length != widget.cfg.rollout.length ||
      _rollout.entries.any((e) => widget.cfg.rollout[e.key]?.state != e.value.state);

  Future<void> _save() async {
    final l = context.l10n;
    final missing = FeatureCatalog.missing(_allowed);
    if (missing.isNotEmpty) {
      final add = await confirmDialog(
        context,
        title: l.missingDependencies(missing.keys.map((m) => featureLabel(context, m)).join(', ')),
        message: l.addDependenciesConfirm(
          FeatureCatalog.withDependencies(_allowed)
              .difference(_allowed)
              .map((m) => featureLabel(context, m))
              .join(', '),
        ),
        confirmLabel: l.addDependencies,
      );
      if (!add) return;
      setState(() => _allowed = FeatureCatalog.withDependencies(_allowed));
    }
    if (!mounted) return;
    final changes = [
      for (final m in OrgModule.values)
        if (_allowed.contains(m) != widget.cfg.allowedModules.contains(m))
          '${_allowed.contains(m) ? '+' : '−'} ${featureLabel(context, m)}',
    ];
    final reason = await askChangeReason(context, title: '${l.changePreview}: ${changes.join(', ')}');
    if (reason == null || !mounted) return;
    try {
      await ref
          .read(platformRepositoryProvider)
          .updateEntitlements(
            widget.cfg.orgId,
            expectedVersion: widget.cfg.version,
            allowed: _allowed,
            rollout: _rollout,
            reason: reason,
          );
      if (mounted) showAppSnack(context, l.orgSaved);
    } on ConfigConflictException catch (e) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            key: const Key('config-conflict'),
            title: Text(l.configConflictTitle),
            content: Text(l.configConflict(e.currentVersion)),
            actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.close))],
          ),
        );
      }
    } catch (e) {
      if (mounted) showAppSnack(context, platformErrorText(context, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cfg = widget.cfg;
    final locale = Localizations.localeOf(context).languageCode;
    final pkg = (ref.watch(packagesProvider).value ?? const <SubscriptionPackage>[])
        .where((p) => p.id == cfg.packageId)
        .firstOrNull;
    final now = DateTime.now();
    final draft = cfg.copyWith(allowedModules: _allowed, rollout: _rollout);
    final history = ref.watch(configHistoryProvider(cfg.orgId)).value ?? const <ConfigHistoryEntry>[];
    final defs = FeatureCatalog.defs
        .where((d) => _category == null || d.category == _category)
        .where((d) => _query.isEmpty || featureLabel(context, d.module).toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final missing = FeatureCatalog.missing(_allowed);
    return PopScope(
      canPop: !_dirty,
      child: Column(
        key: const Key('features-editor'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    key: const Key('features-search'),
                    decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: l.adminSearch),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                ChoiceChip(
                  label: Text(l.adminFilterAll),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                for (final c in FeatureCategory.values)
                  ChoiceChip(
                    key: Key('features-cat-${c.name}'),
                    label: Text(categoryLabel(context, c)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                PopupMenuButton<String>(
                  key: const Key('features-preset'),
                  tooltip: l.bulkPresets,
                  itemBuilder: (_) => [
                    for (final p in ref.read(packagesProvider).value ?? const <SubscriptionPackage>[])
                      PopupMenuItem(value: 'pkg:${p.id}', child: Text('${l.packageLabel}: ${p.nameFor(locale)}')),
                    for (final t in ref.read(templatesProvider).value ?? const <OrgTemplate>[])
                      PopupMenuItem(value: 'tpl:${t.id}', child: Text('${l.templateLabel}: ${t.nameFor(locale)}')),
                  ],
                  onSelected: (v) {
                    final id = v.substring(4);
                    setState(() {
                      if (v.startsWith('pkg:')) {
                        final p = (ref.read(packagesProvider).value ?? const []).firstWhere((x) => x.id == id);
                        _allowed = pkg == null ? {...p.modules} : p.modules.where(pkg.includes).toSet();
                      } else {
                        final t = (ref.read(templatesProvider).value ?? const []).firstWhere((x) => x.id == id);
                        _allowed = pkg == null ? {...t.modules} : t.modules.where(pkg.includes).toSet();
                      }
                    });
                  },
                  child: Chip(avatar: const Icon(Icons.auto_awesome_rounded), label: Text(l.bulkPresets)),
                ),
              ],
            ),
          ),
          if (missing.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                l.missingDependencies(missing.keys.map((m) => featureLabel(context, m)).join(', ')),
                key: const Key('features-missing'),
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
              children: [
                // v1.9: the four levels are different things — say which is which.
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: AppFeedbackBanner(key: const Key('features-legend'), message: l.featLegend),
                ),
                for (final d in defs)
                  _FeatureRow(
                    def: d,
                    entitled: _allowed.contains(d.module),
                    inPackage: pkg?.includes(d.module) ?? true,
                    orgEnabled: cfg.enabledModules.contains(d.module),
                    rollout: _rollout[d.module],
                    effective: EntitlementResolver.blockOf(draft, d.module, now, package: pkg),
                    lastChange: history
                        .where(
                          (h) => h.changes.any((c) => c.endsWith(':${d.module.name}') || c.endsWith(d.module.name)),
                        )
                        .firstOrNull,
                    onEntitled: (v) => setState(() => v ? _allowed.add(d.module) : _allowed.remove(d.module)),
                    onRollout: (r) => setState(() => r == null ? _rollout.remove(d.module) : _rollout[d.module] = r),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                if (_dirty)
                  Expanded(
                    child: Text(
                      l.unsavedChanges,
                      key: const Key('features-dirty'),
                      style: const TextStyle(color: AppColors.warning),
                    ),
                  )
                else
                  const Spacer(),
                TextButton(
                  key: const Key('features-cancel'),
                  onPressed: _dirty
                      ? () => setState(() {
                          _allowed = {...widget.cfg.allowedModules};
                          _rollout = {...widget.cfg.rollout};
                        })
                      : null,
                  child: Text(l.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: const Key('features-save'),
                  onPressed: _dirty ? _save : null,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(l.save),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.def,
    required this.entitled,
    required this.inPackage,
    required this.rollout,
    required this.effective,
    required this.lastChange,
    required this.onEntitled,
    required this.onRollout,
    this.orgEnabled = true,
  });

  final FeatureDef def;
  final bool entitled;
  final bool inPackage;

  /// Level 2 — the organization's own switch (shown, not edited here).
  final bool orgEnabled;
  final FeatureRollout? rollout;
  final EntitlementBlock? effective;
  final ConfigHistoryEntry? lastChange;
  final ValueChanged<bool> onEntitled;
  final ValueChanged<FeatureRollout?> onRollout;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final deps = def.requires.map((g) => g.map((m) => featureLabel(context, m)).join(' / ')).join(' + ');
    return AppCard(
      key: Key('feature-${def.module.name}'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(featureLabel(context, def.module), style: Theme.of(context).textTheme.titleSmall),
                    ),
                    if (def.restricted)
                      const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.lock_rounded, size: 14)),
                  ],
                ),
                Text(featureDescription(context, def.module), style: Theme.of(context).textTheme.bodySmall),
                Text(categoryLabel(context, def.category), style: Theme.of(context).textTheme.labelSmall),
                if (deps.isNotEmpty) Text('${l.requiresLabel}: $deps', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          StatusPill(
            label: inPackage ? l.inPackage : l.effNotInPackage,
            color: inPackage ? AppColors.success : AppColors.neutral,
            dense: true,
          ),
          StatusPill(
            key: Key('feature-org-${def.module.name}'),
            label: orgEnabled ? l.featOrgOn : l.featOrgOff,
            color: orgEnabled ? AppColors.blue : AppColors.neutral,
            icon: Icons.apartment_rounded,
            dense: true,
          ),
          StatusPill(
            key: Key('feature-effective-${def.module.name}'),
            label: blockLabel(context, effective),
            color: effective == null ? AppColors.success : AppColors.warning,
            dense: true,
          ),
          DropdownButton<RolloutState>(
            key: Key('feature-rollout-${def.module.name}'),
            value: rollout?.state ?? RolloutState.enabled,
            items: [
              for (final s in RolloutState.values) DropdownMenuItem(value: s, child: Text(rolloutLabel(context, s))),
            ],
            onChanged: !entitled
                ? null
                : (s) async {
                    if (s == null || s == RolloutState.enabled) return onRollout(null);
                    if (s == RolloutState.disabled) return onRollout(const FeatureRollout(RolloutState.disabled));
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 14)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d == null) return;
                    onRollout(s == RolloutState.trial ? FeatureRollout(s, until: d) : FeatureRollout(s, at: d));
                  },
          ),
          if (rollout?.until != null) Text('${l.rolloutUntil} ${f.dayMonth(rollout!.until!)}'),
          if (rollout?.at != null) Text('${l.rolloutFrom} ${f.dayMonth(rollout!.at!)}'),
          if (lastChange != null)
            Text('${l.lastChange}: v${lastChange!.version}', style: Theme.of(context).textTheme.bodySmall),
          Switch(
            key: Key('feature-toggle-${def.module.name}'),
            value: entitled,
            onChanged: inPackage ? onEntitled : null,
          ),
        ],
      ),
    );
  }
}

class _SubscriptionTab extends ConsumerStatefulWidget {
  const _SubscriptionTab({super.key, required this.cfg});

  final OrgConfig cfg;

  @override
  ConsumerState<_SubscriptionTab> createState() => _SubscriptionTabState();
}

class _SubscriptionTabState extends ConsumerState<_SubscriptionTab> {
  late String _pkg = widget.cfg.packageId;
  late SubscriptionStatus _status = widget.cfg.subscription.status;
  late DateTime? _end = widget.cfg.subscription.endAt;
  late int _grace = widget.cfg.subscription.graceDays;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final pkgs = ref.watch(packagesProvider).value ?? const <SubscriptionPackage>[];
    final access = SubscriptionInfo(status: _status, endAt: _end, graceDays: _grace).accessAt(DateTime.now());
    return _pad([
      DropdownButtonFormField<String>(
        key: const Key('sub-package'),
        initialValue: pkgs.any((p) => p.id == _pkg) ? _pkg : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: l.packageLabel),
        items: [for (final p in pkgs) DropdownMenuItem(value: p.id, child: Text(p.nameFor(locale)))],
        onChanged: (v) => setState(() => _pkg = v ?? _pkg),
      ),
      DropdownButtonFormField<SubscriptionStatus>(
        key: const Key('sub-status'),
        initialValue: _status,
        isExpanded: true,
        decoration: InputDecoration(labelText: l.subscriptionLabel),
        items: [
          for (final s in SubscriptionStatus.values)
            DropdownMenuItem(value: s, child: Text(subscriptionLabel(context, s))),
        ],
        onChanged: (v) => setState(() => _status = v ?? _status),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l.subscriptionEnds),
        subtitle: Text(_end == null ? '—' : f.fullDate(_end!)),
        trailing: const Icon(Icons.event_rounded),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: _end ?? DateTime.now(),
            firstDate: DateTime(2024),
            lastDate: DateTime(2035),
          );
          if (d != null) setState(() => _end = d);
        },
      ),
      Text('${l.graceDays}: $_grace'),
      Slider(value: _grace.toDouble(), max: 90, divisions: 90, onChanged: (v) => setState(() => _grace = v.round())),
      StatusPill(
        key: const Key('sub-access'),
        label: access == AccessMode.full ? l.accessFull : l.accessReadOnly,
        color: access == AccessMode.full ? AppColors.success : AppColors.danger,
      ),
      Text(l.subscriptionPolicyNote, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: AppSpacing.md),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          key: const Key('sub-save'),
          icon: const Icon(Icons.save_rounded),
          label: Text(l.save),
          onPressed: () async {
            final reason = await askChangeReason(context);
            if (reason == null || !context.mounted) return;
            await runPlatform(
              context,
              () => ref
                  .read(platformRepositoryProvider)
                  .updateSubscription(
                    widget.cfg.orgId,
                    expectedVersion: widget.cfg.version,
                    packageId: _pkg,
                    subscription: widget.cfg.subscription.copyWith(status: _status, endAt: _end, graceDays: _grace),
                    reason: reason,
                  ),
              success: l.orgSaved,
            );
          },
        ),
      ),
    ]);
  }
}

class _BrandingTab extends StatelessWidget {
  const _BrandingTab({required this.cfg});

  final OrgConfig cfg;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final b = cfg.branding;
    final ratio = BrandContrast.ratio(b.primaryColor, 0xFFFFFFFF);
    return _pad([
      Container(
        key: const Key('branding-preview'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(b.primaryColor), Color(b.secondaryColor)]),
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
        child: Text(
          b.nameFor(Localizations.localeOf(context).languageCode, fallback: cfg.orgId),
          style: TextStyle(
            color: Color(BrandContrast.onColor(b.primaryColor)),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(l.contrastRatio(ratio.toStringAsFixed(1))),
      if (!BrandContrast.acceptable(b.primaryColor))
        Text(l.errBrandContrast, style: const TextStyle(color: AppColors.danger)),
      for (final e in b.names.entries) Text('${e.key}: ${e.value}'),
      Text(b.description),
      Text(l.brandingManagedByOrg, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class _UsageTab extends ConsumerWidget {
  const _UsageTab({required this.cfg});

  final OrgConfig cfg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final pkg = (ref.watch(packagesProvider).value ?? const <SubscriptionPackage>[])
        .where((p) => p.id == cfg.packageId)
        .firstOrNull;
    return AsyncView<OrgUsage>(
      value: ref.watch(orgUsageProvider(cfg.orgId)),
      data: (u) {
        Widget bar(String key, String label, int used, int max) => Padding(
          key: Key('usage-$key'),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$label: $used / $max'),
              LinearProgressIndicator(
                value: max == 0 ? 0 : (used / max).clamp(0, 1),
                minHeight: 8,
                color: used > max ? AppColors.danger : null,
              ),
            ],
          ),
        );
        return _pad([
          bar('students', l.orgLimitStudents, u.students, cfg.limits.maxStudents),
          bar('coaches', l.orgLimitCoaches, u.coaches, cfg.limits.maxCoaches),
          bar('groups', l.orgLimitGroups, u.groups, cfg.limits.maxGroups),
          bar('rooms', l.orgLimitRooms, u.rooms, cfg.limits.maxRooms),
          if (pkg != null) ...[
            bar('storage', l.limitStorage, u.storageMb, pkg.limits.storageMb),
            bar('notifications', l.limitNotifications, u.notificationsThisMonth, pkg.limits.notificationsPerMonth),
            bar('sms', l.limitSms, u.smsThisMonth, pkg.limits.smsPerMonth),
          ],
          Text(l.usageSyntheticNote, style: Theme.of(context).textTheme.bodySmall),
        ]);
      },
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final audit = (ref.watch(adminAuditProvider).value ?? const <AuditEntry>[])
        .where((a) => a.clubId == orgId)
        .toList();
    return AsyncView<List<ConfigHistoryEntry>>(
      value: ref.watch(configHistoryProvider(orgId)),
      data: (hist) => _pad([
        Text(l.configHistory, style: Theme.of(context).textTheme.titleMedium),
        for (final h in hist)
          ListTile(
            key: Key('history-v${h.version}'),
            dense: true,
            leading: CircleAvatar(radius: 16, child: Text('${h.version}', style: const TextStyle(fontSize: 11))),
            title: Text(h.reason),
            subtitle: Text('${f.dateTime(h.at)} · ${h.by} · ${h.changes.join(', ')}'),
          ),
        const Divider(),
        Text(l.adminNavAudit, style: Theme.of(context).textTheme.titleMedium),
        for (final a in audit.take(30))
          ListTile(dense: true, title: Text(a.action), subtitle: Text('${a.actorName} · ${f.dateTime(a.at)}')),
      ]),
    );
  }
}

class _SettingsTab extends ConsumerWidget {
  const _SettingsTab({required this.cfg});

  final OrgConfig cfg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final tpls = (ref.watch(templatesProvider).value ?? const <OrgTemplate>[]).where((t) => !t.archived).toList();
    return _pad([
      Text(l.adminColStatus, style: Theme.of(context).textTheme.titleMedium),
      Wrap(
        spacing: 8,
        children: [
          for (final s in OrgStatus.values)
            ChoiceChip(
              key: Key('org-set-status-${s.name}'),
              label: Text(orgStatusLabel(context, s)),
              selected: cfg.status == s,
              onSelected: cfg.status == s
                  ? null
                  : (_) async {
                      // v1.9: suspending / deactivating locks a whole tenant —
                      // always explained and confirmed first.
                      final ok = await confirmDialog(
                        context,
                        title: l.confirmOrgStatusTitle(orgStatusLabel(context, s)),
                        message: s == OrgStatus.active ? l.confirmOrgActivateBody : l.confirmOrgSuspendBody,
                        confirmLabel: orgStatusLabel(context, s),
                        destructive: s != OrgStatus.active,
                      );
                      if (!ok || !context.mounted) return;
                      await runPlatform(
                        context,
                        () => ref.read(organizationsRepositoryProvider).updatePlatformSettings(cfg.orgId, status: s),
                        success: l.orgSaved,
                      );
                    },
            ),
        ],
      ),
      Text(l.orgStatusHelp, style: Theme.of(context).textTheme.bodySmall),
      const Divider(),
      Text(l.applyTemplate, style: Theme.of(context).textTheme.titleMedium),
      Text(l.applyTemplateNote, style: Theme.of(context).textTheme.bodySmall),
      for (final t in tpls)
        ListTile(
          key: Key('apply-template-${t.id}'),
          title: Text(t.nameFor(locale)),
          trailing: const Icon(Icons.preview_rounded),
          onTap: () async {
            final changes = await ref.read(platformRepositoryProvider).previewTemplate(cfg.orgId, t.id);
            if (!context.mounted) return;
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                key: const Key('template-preview'),
                title: Text('${l.changePreview} · ${t.nameFor(locale)}'),
                content: SizedBox(
                  width: 480,
                  child: changes.isEmpty
                      ? Text(l.noChanges)
                      : ListView(
                          shrinkWrap: true,
                          children: [
                            for (final c in changes)
                              Text(
                                c.key.startsWith('module:')
                                    ? '${c.to == 'true' ? '+' : '−'} ${featureLabel(context, OrgModule.fromName(c.key.substring(7))!)}'
                                    : '${c.key}: ${c.from} → ${c.to}',
                              ),
                          ],
                        ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
                  FilledButton(
                    key: const Key('template-apply-confirm'),
                    onPressed: changes.isEmpty ? null : () => Navigator.pop(context, true),
                    child: Text(l.applyTemplate),
                  ),
                ],
              ),
            );
            if (ok != true || !context.mounted) return;
            final reason = await askChangeReason(context);
            if (reason == null || !context.mounted) return;
            await runPlatform(
              context,
              () => ref
                  .read(platformRepositoryProvider)
                  .applyTemplate(cfg.orgId, t.id, expectedVersion: cfg.version, reason: reason),
              success: l.orgSaved,
            );
          },
        ),
    ]);
  }
}

// ────────────────────────────────────────────── templates, catalog, packages

class TemplatesPage extends ConsumerWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    return AdminSection(
      title: l.adminNavTemplates,
      actions: [
        FilledButton.icon(
          key: const Key('template-new'),
          onPressed: () => showTemplateDialog(context, ref, null),
          icon: const Icon(Icons.add_rounded),
          label: Text(l.templateNew),
        ),
      ],
      child: AsyncView<List<OrgTemplate>>(
        value: ref.watch(templatesProvider),
        data: (list) => AdminTable<OrgTemplate>(
          rows: list,
          searchText: (t) => t.nameFor(locale),
          filters: [(l.adminFilterAll, (_) => true), (l.adminArchived, (t) => t.archived)],
          columns: [
            AdminColumn(l.adminColName, (t) => Text(t.nameFor(locale), key: Key('template-row-${t.id}')), flex: 3),
            AdminColumn(l.orgFunding, (t) => Text(fundingLabel(context, t.funding)), flex: 2),
            AdminColumn(l.packageLabel, (t) => Text(t.packageId), flex: 2),
            AdminColumn(l.orgModulesOn, (t) => Text('${t.modules.length}')),
            AdminColumn(
              '',
              (t) => Wrap(
                children: [
                  IconButton(
                    key: Key('template-edit-${t.id}'),
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () => showTemplateDialog(context, ref, t),
                  ),
                  IconButton(
                    key: Key('template-duplicate-${t.id}'),
                    tooltip: l.duplicate,
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () => runPlatform(
                      context,
                      () => ref.read(platformRepositoryProvider).duplicateTemplate(t.id),
                      success: l.orgSaved,
                    ),
                  ),
                  IconButton(
                    key: Key('template-archive-${t.id}'),
                    tooltip: t.archived ? l.restore : l.archive,
                    icon: Icon(t.archived ? Icons.unarchive_rounded : Icons.archive_rounded),
                    onPressed: () async {
                      if (!t.archived) {
                        final ok = await confirmDialog(
                          context,
                          title: l.archive,
                          message: l.confirmArchiveTemplateBody,
                          confirmLabel: l.archive,
                        );
                        if (!ok || !context.mounted) return;
                      }
                      await runPlatform(
                        context,
                        () => ref.read(platformRepositoryProvider).archiveTemplate(t.id, archived: !t.archived),
                        success: t.archived ? l.templateRestoredSnack : l.templateArchivedSnack,
                      );
                    },
                  ),
                ],
              ),
              flex: 2,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showTemplateDialog(BuildContext context, WidgetRef ref, OrgTemplate? existing) async {
  final l = context.l10n;
  final ka = TextEditingController(text: existing?.names['ka'] ?? '');
  final en = TextEditingController(text: existing?.names['en'] ?? '');
  final ru = TextEditingController(text: existing?.names['ru'] ?? '');
  var funding = existing?.funding ?? FundingType.private;
  var type = existing?.type ?? OrgType.club;
  var packageId = existing?.packageId ?? SubscriptionPackage.professionalId;
  final modules = {...?existing?.modules};
  final pkgs = ref.read(packagesProvider).value ?? const <SubscriptionPackage>[];
  final otherTemplates = (ref.read(templatesProvider).value ?? const <OrgTemplate>[]).where(
    (t) => t.id != existing?.id,
  );
  String? err;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => AlertDialog(
        title: Text(existing == null ? l.templateNew : l.edit),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('tpl-name-ka'),
                  controller: ka,
                  decoration: InputDecoration(labelText: l.orgNameKa),
                ),
                TextField(
                  key: const Key('tpl-name-en'),
                  controller: en,
                  decoration: InputDecoration(labelText: l.orgNameEn),
                ),
                TextField(
                  controller: ru,
                  decoration: InputDecoration(labelText: l.orgNameRu),
                ),
                DropdownButtonFormField<FundingType>(
                  initialValue: funding,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.orgFunding),
                  items: [
                    for (final f in FundingType.values)
                      DropdownMenuItem(value: f, child: Text(fundingLabel(context, f))),
                  ],
                  onChanged: (v) => set(() => funding = v ?? funding),
                ),
                DropdownButtonFormField<OrgType>(
                  initialValue: type,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.orgTypeLabel),
                  items: [
                    for (final t in OrgType.values) DropdownMenuItem(value: t, child: Text(orgTypeLabel(context, t))),
                  ],
                  onChanged: (v) => set(() => type = v ?? type),
                ),
                DropdownButtonFormField<String>(
                  initialValue: pkgs.any((p) => p.id == packageId) ? packageId : null,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.packageLabel),
                  items: [
                    for (final p in pkgs)
                      DropdownMenuItem(
                        value: p.id,
                        child: Text(p.nameFor(Localizations.localeOf(context).languageCode)),
                      ),
                  ],
                  onChanged: (v) => set(() => packageId = v ?? packageId),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final d in FeatureCatalog.defs)
                      FilterChip(
                        key: Key('tpl-feature-${d.module.name}'),
                        label: Text(featureLabel(context, d.module)),
                        selected: modules.contains(d.module),
                        onSelected: (v) => set(() => v ? modules.add(d.module) : modules.remove(d.module)),
                      ),
                  ],
                ),
                if (!FeatureCatalog.isValid(modules))
                  Text(
                    l.missingDependencies(
                      FeatureCatalog.missing(modules).keys.map((m) => featureLabel(context, m)).join(', '),
                    ),
                    style: const TextStyle(color: AppColors.danger),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          if (err != null)
            Text(
              err!,
              key: const Key('tpl-error'),
              style: const TextStyle(color: AppColors.danger),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          AsyncFilledButton(
            key: const Key('tpl-save'),
            label: existing == null ? l.templateNew : l.saveChanges,
            onPressed: () async {
              final names = [ka.text.trim(), en.text.trim(), ru.text.trim()].where((x) => x.isNotEmpty).toList();
              final problem = names.isEmpty
                  ? l.a191ErrNameRequired
                  : !FeatureCatalog.isValid(modules)
                  ? l.errFeatureDependencies
                  : otherTemplates.any(
                      (o) => o.names.values.any((v) => names.any((n) => n.toLowerCase() == v.toLowerCase())),
                    )
                  ? l.a191ErrDuplicateName
                  : null;
              set(() => err = problem);
              if (problem != null) return;
              final t = OrgTemplate(
                id: existing?.builtIn ?? false ? '' : existing?.id ?? '',
                names: {
                  if (ka.text.trim().isNotEmpty) 'ka': ka.text.trim(),
                  if (en.text.trim().isNotEmpty) 'en': en.text.trim(),
                  if (ru.text.trim().isNotEmpty) 'ru': ru.text.trim(),
                },
                modules: modules,
                funding: funding,
                type: type,
                packageId: packageId,
              );
              final ok = await runPlatform(
                context,
                () => ref.read(platformRepositoryProvider).upsertTemplate(t),
                success: l.orgSaved,
              );
              if (ok && context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

class FeatureCatalogPage extends ConsumerWidget {
  const FeatureCatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final stats = ref.watch(platformStatsProvider).value;
    return AdminSection(
      title: l.adminNavFeatureCatalog,
      subtitle: l.featureCatalogSubtitle,
      child: AdminTable<FeatureDef>(
        rows: FeatureCatalog.defs,
        searchText: (d) => '${featureLabel(context, d.module)} ${d.id}',
        filters: [
          (l.adminFilterAll, (_) => true),
          for (final c in FeatureCategory.values) (categoryLabel(context, c), (d) => d.category == c),
        ],
        columns: [
          AdminColumn(
            l.adminColName,
            (d) => Text(featureLabel(context, d.module), key: Key('catalog-${d.id}')),
            flex: 3,
          ),
          AdminColumn(l.a191FeatureWhat, (d) => Text(featureDescription(context, d.module)), flex: 4),
          AdminColumn(l.featCategory, (d) => Text(categoryLabel(context, d.category)), flex: 2),
          AdminColumn(
            l.requiresLabel,
            (d) => Text(d.requires.map((g) => g.map((m) => m.name).join(' / ')).join(' + ')),
            flex: 3,
          ),
          AdminColumn(
            l.restrictedLabel,
            (d) => Icon(d.restricted ? Icons.lock_rounded : Icons.lock_open_rounded, size: 18),
          ),
          AdminColumn(l.featureAdoption, (d) => Text('${stats?.adoption[d.module] ?? '—'}')),
        ],
      ),
    );
  }
}

class PackagesPage extends ConsumerWidget {
  const PackagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    return AdminSection(
      title: l.adminNavPackages,
      subtitle: l.packagesSubtitle,
      actions: [
        FilledButton.icon(
          key: const Key('package-new'),
          onPressed: () => showPackageDialog(context, ref, null),
          icon: const Icon(Icons.add_rounded),
          label: Text(l.packageNew),
        ),
      ],
      child: AsyncView<List<SubscriptionPackage>>(
        value: ref.watch(packagesProvider),
        data: (list) => AdminTable<SubscriptionPackage>(
          rows: list,
          searchText: (p) => p.nameFor(locale),
          columns: [
            AdminColumn(l.adminColName, (p) => Text(p.nameFor(locale), key: Key('package-row-${p.id}')), flex: 2),
            AdminColumn(l.orgModulesOn, (p) => Text(p.custom ? l.customLabel : '${p.modules.length}')),
            AdminColumn(l.orgLimitCoaches, (p) => Text('${p.limits.maxCoaches}')),
            AdminColumn(l.orgLimitStudents, (p) => Text('${p.limits.maxStudents}')),
            AdminColumn(l.orgLimitGroups, (p) => Text('${p.limits.maxGroups}')),
            AdminColumn(l.orgLimitRooms, (p) => Text('${p.limits.maxRooms}')),
            AdminColumn(l.limitStorage, (p) => Text('${p.limits.storageMb} MB')),
            AdminColumn(
              l.priceLabel,
              (p) => Text('${(p.price.amountMinor / 100).toStringAsFixed(2)} ${p.price.currency}/${p.price.period}'),
              flex: 2,
            ),
            AdminColumn(
              '',
              (p) => IconButton(
                key: Key('package-edit-${p.id}'),
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => showPackageDialog(context, ref, p),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showPackageDialog(BuildContext context, WidgetRef ref, SubscriptionPackage? existing) async {
  final l = context.l10n;
  final en = TextEditingController(text: existing?.names['en'] ?? '');
  final ka = TextEditingController(text: existing?.names['ka'] ?? '');
  final ru = TextEditingController(text: existing?.names['ru'] ?? '');
  final limits = existing?.limits ?? const PackageLimits(maxCoaches: 10, maxStudents: 100, maxGroups: 10, maxRooms: 2);
  final ctl = {
    'maxCoaches': TextEditingController(text: '${limits.maxCoaches}'),
    'maxStudents': TextEditingController(text: '${limits.maxStudents}'),
    'maxGroups': TextEditingController(text: '${limits.maxGroups}'),
    'maxRooms': TextEditingController(text: '${limits.maxRooms}'),
    'storageMb': TextEditingController(text: '${limits.storageMb}'),
    'mediaUploadMb': TextEditingController(text: '${limits.mediaUploadMb}'),
    'notificationsPerMonth': TextEditingController(text: '${limits.notificationsPerMonth}'),
    'smsPerMonth': TextEditingController(text: '${limits.smsPerMonth}'),
  };
  final price = TextEditingController(text: '${(existing?.price.amountMinor ?? 0) / 100}');
  final duration = TextEditingController(text: '${existing?.durationDays ?? 365}');
  final modules = {...?existing?.modules};
  var custom = existing?.custom ?? false;
  final otherPackages = (ref.read(packagesProvider).value ?? const <SubscriptionPackage>[]).where(
    (p) => p.id != existing?.id,
  );
  String? err;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => AlertDialog(
        title: Text(existing == null ? l.packageNew : l.edit),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('pkg-name-en'),
                  controller: en,
                  decoration: InputDecoration(labelText: l.orgNameEn),
                ),
                TextField(
                  controller: ka,
                  decoration: InputDecoration(labelText: l.orgNameKa),
                ),
                TextField(
                  controller: ru,
                  decoration: InputDecoration(labelText: l.orgNameRu),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final e in ctl.entries)
                      SizedBox(
                        width: 160,
                        child: TextField(
                          key: Key('pkg-${e.key}'),
                          controller: e.value,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: packageLimitLabel(context, e.key)),
                        ),
                      ),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: price,
                        decoration: InputDecoration(
                          labelText: '${l.priceLabel} (${existing?.price.currency ?? 'GEL'})',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: duration,
                        decoration: InputDecoration(labelText: l.durationDays),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: custom,
                  title: Text(l.customLabel),
                  subtitle: Text(l.customPackageNote),
                  onChanged: (v) => set(() => custom = v),
                ),
                if (!custom)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final d in FeatureCatalog.defs)
                        FilterChip(
                          label: Text(featureLabel(context, d.module)),
                          selected: modules.contains(d.module),
                          onSelected: (v) => set(() => v ? modules.add(d.module) : modules.remove(d.module)),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        actions: [
          if (err != null)
            Text(
              err!,
              key: const Key('pkg-error'),
              style: const TextStyle(color: AppColors.danger),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          AsyncFilledButton(
            key: const Key('pkg-save'),
            label: existing == null ? l.packageNew : l.saveChanges,
            onPressed: () async {
              // v1.9.1: numbers are validated instead of silently replaced.
              final bad = ctl.entries.where(
                (e) => int.tryParse(e.value.text.trim()) == null || int.parse(e.value.text.trim()) < 0,
              );
              final names = [en.text.trim(), ka.text.trim(), ru.text.trim()].where((x) => x.isNotEmpty).toList();
              final problem = names.isEmpty
                  ? l.a191ErrNameRequired
                  : bad.isNotEmpty || double.tryParse(price.text.trim()) == null
                  ? l.a191ErrNumbers
                  : otherPackages.any(
                      (o) => o.names.values.any((v) => names.any((x) => x.toLowerCase() == v.toLowerCase())),
                    )
                  ? l.a191ErrDuplicateName
                  : null;
              set(() => err = problem);
              if (problem != null) return;
              int n(String k, int d) => int.tryParse(ctl[k]!.text) ?? d;
              final p = SubscriptionPackage(
                id: existing?.id ?? '',
                names: {
                  if (en.text.trim().isNotEmpty) 'en': en.text.trim(),
                  if (ka.text.trim().isNotEmpty) 'ka': ka.text.trim(),
                  if (ru.text.trim().isNotEmpty) 'ru': ru.text.trim(),
                },
                modules: custom ? OrgModule.values.toSet() : modules,
                custom: custom,
                durationDays: int.tryParse(duration.text) ?? 365,
                price: PackagePrice(amountMinor: ((double.tryParse(price.text) ?? 0) * 100).round()),
                limits: PackageLimits(
                  maxCoaches: n('maxCoaches', 10),
                  maxStudents: n('maxStudents', 100),
                  maxGroups: n('maxGroups', 10),
                  maxRooms: n('maxRooms', 2),
                  storageMb: n('storageMb', 1024),
                  mediaUploadMb: n('mediaUploadMb', 50),
                  notificationsPerMonth: n('notificationsPerMonth', 5000),
                  smsPerMonth: n('smsPerMonth', 0),
                ),
              );
              final ok = await runPlatform(
                context,
                () => ref.read(platformRepositoryProvider).upsertPackage(p),
                success: l.orgSaved,
              );
              if (ok && context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

class SubscriptionsPage extends ConsumerWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final now = DateTime.now();
    return AdminSection(
      title: l.subscriptionsTitle,
      subtitle: l.subscriptionsSubtitle,
      child: AsyncView<List<OrgConfig>>(
        value: ref.watch(orgConfigsProvider),
        data: (list) => AdminTable<OrgConfig>(
          rows: list,
          searchText: (c) => orgName(context, ref, c.orgId),
          filters: [
            (l.adminFilterAll, (_) => true),
            for (final s in SubscriptionStatus.values)
              (subscriptionLabel(context, s), (c) => c.subscription.status == s),
          ],
          columns: [
            AdminColumn(
              l.adminColName,
              (c) => InkWell(
                onTap: () => context.go('/organizations/${c.orgId}'),
                child: Text(orgName(context, ref, c.orgId), key: Key('sub-row-${c.orgId}')),
              ),
              flex: 3,
            ),
            AdminColumn(l.packageLabel, (c) => Text(c.packageId), flex: 2),
            AdminColumn(
              l.subscriptionLabel,
              (c) => Align(
                alignment: Alignment.centerLeft,
                child: StatusPill(
                  label: subscriptionLabel(context, c.subscription.status),
                  color: subscriptionColor(c.subscription.status),
                  dense: true,
                ),
              ),
              flex: 2,
            ),
            AdminColumn(
              l.subscriptionEnds,
              (c) => Text(c.subscription.endAt == null ? '—' : f.fullDate(c.subscription.endAt!)),
              flex: 2,
            ),
            AdminColumn(
              l.accessLabel,
              (c) => Text(
                c.accessAt(now) == AccessMode.full
                    ? (c.subscription.inGrace(now) ? l.accessGrace : l.accessFull)
                    : l.accessReadOnly,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InvitationsPage extends ConsumerWidget {
  const InvitationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return AdminSection(
      title: l.adminNavInvitations,
      child: AsyncView<List<OrgInvitation>>(
        value: ref.watch(invitationsProvider(null)),
        data: (list) => InvitationsTable(invitations: list),
      ),
    );
  }
}

class SystemHealthPage extends ConsumerWidget {
  const SystemHealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final stats = ref.watch(platformStatsProvider).value;
    return AdminSection(
      title: l.adminNavHealth,
      actions: [const _RefreshButton()],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.healthJobs, style: Theme.of(context).textTheme.titleMedium),
          for (final (name, schedule) in [
            ('refreshEntitlements', '60 min'),
            ('sendPaymentReminders', l.healthDaily),
            ('generateRecurringPayments', l.healthDaily),
            ('certificateExpiryCheck', l.healthDaily),
            ('sendTrainingReminders', '15 min'),
            ('matchReminders', '15 min'),
          ])
            ListTile(
              dense: true,
              leading: const Icon(Icons.schedule_rounded),
              title: Text(name),
              subtitle: Text('$schedule · ${l.healthJobGated}'),
            ),
          const Divider(),
          Text(l.operationalAlerts, style: Theme.of(context).textTheme.titleMedium),
          if (stats == null || stats.alerts.isEmpty) Text(l.noAlerts),
          for (final a in stats?.alerts ?? const <PlatformAlert>[])
            ListTile(
              dense: true,
              leading: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              title: Text('${alertLabel(context, a.kind)} · ${orgName(context, ref, a.orgId)}'),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────── organization admin: members

class OrgMembersPage extends ConsumerWidget {
  const OrgMembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final org = ref.watch(adminOrgProvider);
    final groups = (ref.watch(adminGroupsProvider).value ?? const <GroupOverview>[])
        .where((g) => g.group.clubId == org)
        .toList();
    final coaches = (ref.watch(adminCoachesProvider).value ?? const <CoachSummary>[])
        .where((c) => c.clubIds.contains(org))
        .toList();
    final students = {for (final g in groups) ...g.group.memberChildIds};
    final guardians = {for (final g in groups) ...g.group.parentIds};
    return AdminSection(
      title: l.adminNavMembers,
      actions: const [AdminOrgPicker()],
      child: org == null
          ? EmptyState(icon: Icons.apartment_rounded, title: l.orgNoneSelected)
          : Column(
              key: const Key('org-members'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    SizedBox(
                      width: 200,
                      child: StatCard(label: l.orgCoaches, value: coaches.length, icon: Icons.sports_rounded),
                    ),
                    SizedBox(
                      width: 200,
                      child: StatCard(label: l.statStudents, value: students.length, icon: Icons.child_care_rounded),
                    ),
                    SizedBox(
                      width: 200,
                      child: StatCard(
                        label: l.statParents,
                        value: guardians.length,
                        icon: Icons.family_restroom_rounded,
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: StatCard(label: l.adminColGroups, value: groups.length, icon: Icons.groups_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l.adminColGroups, style: Theme.of(context).textTheme.titleMedium),
                for (final g in groups)
                  ListTile(
                    dense: true,
                    title: Text(g.group.name),
                    subtitle: Text('${g.coachNames.join(', ')} · ${l.groupMembers(g.memberCount)}'),
                  ),
                Text(l.membersPrivacyNote, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
    );
  }
}

/// Signed-in user without admin rights: accept / reject an invitation.
class InvitationAcceptCard extends ConsumerStatefulWidget {
  const InvitationAcceptCard({super.key, this.initialToken});

  final String? initialToken;

  @override
  ConsumerState<InvitationAcceptCard> createState() => _InvitationAcceptCardState();
}

class _InvitationAcceptCardState extends ConsumerState<InvitationAcceptCard> {
  late final _token = TextEditingController(text: widget.initialToken ?? '');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SizedBox(
      width: 420,
      child: AppCard(
        key: const Key('invitation-accept-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.haveInvitation, style: Theme.of(context).textTheme.titleSmall),
            TextField(
              key: const Key('invitation-token-input'),
              controller: _token,
              decoration: InputDecoration(hintText: l.invitationTokenLabel),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const Key('invitation-reject'),
                  onPressed: () => runPlatform(
                    context,
                    () => ref.read(platformRepositoryProvider).rejectInvitation(_token.text),
                    success: l.invitationRejectedSnack,
                  ),
                  child: Text(l.invitationRejectButton),
                ),
                FilledButton(
                  key: const Key('invitation-accept'),
                  onPressed: () => runPlatform(context, () async {
                    await ref.read(platformRepositoryProvider).acceptInvitation(_token.text);
                    // Claims changed: refresh the session so the admin UI opens.
                    ref.invalidate(authSessionProvider);
                  }, success: l.invitationAcceptedSnack),
                  child: Text(l.invitationAcceptButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RefreshButton extends ConsumerStatefulWidget {
  const _RefreshButton();

  @override
  ConsumerState<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends ConsumerState<_RefreshButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FilledButton.tonalIcon(
      key: const Key('health-refresh'),
      onPressed: _busy
          ? null
          : () async {
              setState(() => _busy = true);
              List<String> changed = const [];
              final ok = await runPlatform(context, () async {
                changed = await ref.read(platformRepositoryProvider).refreshEntitlements();
              });
              if (!mounted) return;
              setState(() => _busy = false);
              if (ok) showAppSnack(this.context, l.refreshDone(changed.length));
            },
      icon: _busy
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.sync_rounded),
      label: Text(l.runEntitlementRefresh),
    );
  }
}

/// v1.9.1: readable labels for package limits (no technical keys).
String packageLimitLabel(BuildContext context, String key) {
  final l = context.l10n;
  return switch (key) {
    'maxCoaches' => l.orgLimitCoaches,
    'maxStudents' => l.orgLimitStudents,
    'maxGroups' => l.orgLimitGroups,
    'maxRooms' => l.orgLimitRooms,
    'storageMb' => l.limitStorage,
    'mediaUploadMb' => l.a191LimitUploadMb,
    'notificationsPerMonth' => l.limitNotifications,
    'smsPerMonth' => l.limitSms,
    _ => key,
  };
}
