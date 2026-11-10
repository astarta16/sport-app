import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/media_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../data/demo_account_repository.dart';
import '../domain/account_request.dart';

final myAccountRequestsProvider = StreamProvider.autoDispose<List<AccountRequest>>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(accountRepositoryProvider).watchMyRequests();
});

/// Account lifecycle (v1.2): photo, consents, data export, deletion with an
/// impact preview, retention explanation.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: SkeletonList());
    final kids = ref.watch(myChildrenProvider).value ?? const <Child>[];
    final requests = ref.watch(myAccountRequestsProvider).value ?? const <AccountRequest>[];
    final f = Fmt.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.accountTitle)),
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppCard(
              child: Row(
                children: [
                  UserAvatar(name: user.fullName, photoPath: user.photoPath, size: 64),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(l.profilePhoto, style: Theme.of(context).textTheme.titleSmall)),
                  PopupMenuButton<String>(
                    key: const Key('photo-menu'),
                    tooltip: l.profilePhotoChange,
                    onSelected: (v) async {
                      if (v == 'remove') {
                        await runGuarded(context, () => ref.read(authRepositoryProvider).removePhoto());
                        return;
                      }
                      final p = await MediaPicker.pickAvatar(camera: v == 'camera');
                      if (p == null || !context.mounted) return;
                      await runGuarded(
                        context,
                        () => ref.read(authRepositoryProvider).updatePhoto(p.bytes),
                        success: l.profilePhotoUpdated,
                      );
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'camera', child: Text(l.mediaTakePhoto)),
                      PopupMenuItem(value: 'gallery', child: Text(l.mediaFromGallery)),
                      if (user.photoPath != null) PopupMenuItem(value: 'remove', child: Text(l.profilePhotoRemove)),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.edit_rounded, color: AppColors.blue),
                    ),
                  ),
                ],
              ),
            ),
            SectionHeader(l.consentsTitle),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: [
                  if (user.dataConsentAt != null)
                    ListTile(
                      leading: const Icon(Icons.verified_user_rounded),
                      title: Text(l.consentDataGiven(f.fullDate(user.dataConsentAt!))),
                    ),
                  if (user.isParent)
                    SwitchListTile(
                      key: const Key('consent-sms'),
                      secondary: const Icon(Icons.sms_rounded),
                      title: Text(l.consentSmsToggle),
                      value: user.smsConsentAt != null,
                      onChanged: (v) => runGuarded(context, () => ref.read(authRepositoryProvider).updateSmsConsent(v)),
                    ),
                  for (final c in kids)
                    SwitchListTile(
                      key: Key('consent-media-${c.id}'),
                      secondary: const Icon(Icons.photo_camera_front_rounded),
                      title: Text(l.consentMedia(c.firstName)),
                      subtitle: c.mediaConsentAt == null ? null : Text(f.fullDate(c.mediaConsentAt!)),
                      value: c.photoConsent,
                      onChanged: (v) =>
                          runGuarded(context, () => ref.read(childrenRepositoryProvider).setMediaConsent(c.id, v)),
                    ),
                ],
              ),
            ),
            SectionHeader(l.dataExport),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.dataExportHint, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    key: const Key('export-request'),
                    onPressed: () => runGuarded(
                      context,
                      () => ref.read(accountRepositoryProvider).requestExport(),
                      success: l.dataExportRequested,
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: Text(l.dataExport),
                  ),
                ],
              ),
            ),
            if (requests.isNotEmpty) ...[
              SectionHeader(l.accountRequests),
              for (final r in requests)
                ListTile(
                  key: Key('account-request-${r.id}'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    r.type == AccountRequestType.export ? Icons.download_rounded : Icons.delete_outline_rounded,
                  ),
                  title: Text(r.type == AccountRequestType.export ? l.dataExport : l.deleteAccount),
                  subtitle: Text(f.dateTime(r.createdAt)),
                  trailing: StatusPill(label: _status(context, r.status), color: AppColors.blue, dense: true),
                  onTap: r.status == AccountRequestStatus.done && r.type == AccountRequestType.export
                      ? () => _showExport(context, ref, r)
                      : null,
                ),
            ],
            SectionHeader(l.retentionTitle),
            Text(l.retentionBody, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              key: const Key('delete-account'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: () => _delete(context, ref),
              icon: const Icon(Icons.delete_forever_rounded),
              label: Text(l.deleteAccount),
            ),
          ],
        ),
      ),
    );
  }

  static String _status(BuildContext context, AccountRequestStatus s) {
    final l = context.l10n;
    return switch (s) {
      AccountRequestStatus.pending => l.requestStatusPending,
      AccountRequestStatus.processing => l.requestStatusProcessing,
      AccountRequestStatus.done => l.requestStatusDone,
      AccountRequestStatus.rejected => l.requestStatusRejected,
    };
  }

  /// Demo shows the generated JSON; production opens a short-lived signed URL.
  Future<void> _showExport(BuildContext context, WidgetRef ref, AccountRequest r) async {
    final repo = ref.read(accountRepositoryProvider);
    final content = repo is DemoAccountRepository ? repo.exportContent(r) : null;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.dataExportReady),
        content: SizedBox(
          width: 520,
          height: 360,
          child: SingleChildScrollView(
            child: SelectableText(content ?? r.resultPath ?? '', style: const TextStyle(fontSize: 11)),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.close))],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    DeletionImpact impact;
    try {
      impact = await ref.read(accountRepositoryProvider).deletionImpact();
    } catch (e) {
      if (context.mounted) showAppSnack(context, errorText(context, e), error: true);
      return;
    }
    if (!context.mounted) return;
    final ok = await confirmDialog(
      context,
      title: l.deleteImpactTitle,
      message: [
        l.deleteAccountConfirm,
        if (impact.deletedChildren.isNotEmpty) l.deleteImpactDeleted(impact.deletedChildren.join(', ')),
        if (impact.unlinkedChildren.isNotEmpty) l.deleteImpactUnlinked(impact.unlinkedChildren.join(', ')),
        l.deleteImpactPayments,
      ].join('\n\n'),
      confirmLabel: l.delete,
      destructive: true,
    );
    if (ok && context.mounted) {
      await runGuarded(context, () => ref.read(accountRepositoryProvider).requestDeletion());
    }
  }
}

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: SkeletonList());
    final p = user.privacy;
    return Scaffold(
      appBar: AppBar(title: Text(l.privacySettingsTitle)),
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(l.privacyBody, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('privacy-photo'),
                    title: Text(l.privacyPhotoVisible),
                    value: p.profilePhotoVisible,
                    onChanged: (v) => runGuarded(
                      context,
                      () => ref.read(authRepositoryProvider).updatePrivacy(p.copyWith(profilePhotoVisible: v)),
                    ),
                  ),
                  SwitchListTile(
                    key: const Key('privacy-analytics'),
                    title: Text(l.privacyAnalytics),
                    value: p.analyticsConsent,
                    onChanged: (v) => runGuarded(
                      context,
                      () => ref.read(authRepositoryProvider).updatePrivacy(p.copyWith(analyticsConsent: v)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Admin accounts are routed here in the mobile app: administration lives in
/// the separate web dashboard (`lib/main_admin.dart`).
class AdminUseWebScreen extends ConsumerWidget {
  const AdminUseWebScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: ScrollableFill(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings_rounded, size: 64, color: AppColors.blue),
              const SizedBox(height: AppSpacing.md),
              Text(l.adminUseWeb, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
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
