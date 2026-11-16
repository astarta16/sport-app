import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../authentication/domain/access_policy.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../domain/medical_certificate.dart';
import '../../sports/presentation/sports_providers.dart';
import 'certificate_actions.dart';
import '../../sports/presentation/sport_label.dart';
import 'certificates_providers.dart';

class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    final child = ref.watch(childProvider(childId)).value;
    final certs = ref.watch(childCertificatesProvider(childId));
    final now = ref.watch(clockProvider)();
    final isParent = user != null && child != null && AccessPolicy.isParentOf(user, child);
    return Scaffold(
      appBar: AppBar(title: Text(l.certificatesTitle)),
      floatingActionButton: isParent
          ? FloatingActionButton.extended(
              key: const Key('upload-certificate'),
              onPressed: () => context.push(Routes.uploadCertificate(childId)),
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(l.uploadCertificate),
            )
          : null,
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: AsyncView<List<MedicalCertificate>>(
          value: certs,
          onRetry: () => ref.invalidate(childCertificatesProvider(childId)),
          data: (list) {
            final status = CertificatePolicy.childStatus(list, now);
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 120),
              children: [
                _StatusHero(child: child, status: status, latest: CertificatePolicy.current(list), now: now),
                const SizedBox(height: AppSpacing.sm),
                DemoBanner(text: l.certRemindersNote),
                SectionHeader(l.certificatesTitle),
                if (list.isEmpty)
                  AppCard(
                    child: EmptyState(compact: true, icon: Icons.description_outlined, title: l.noCertificates),
                  )
                else
                  for (final c in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _CertificateCard(
                        cert: c,
                        canDelete: isParent,
                        now: now,
                        isCurrent: CertificatePolicy.current(list, sportId: c.sportId)?.id == c.id,
                      ),
                    ),
                if (isParent) _AccessLog(childId: childId),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.child, required this.status, required this.latest, required this.now});

  final Child? child;
  final CertificateStatus status;
  final MedicalCertificate? latest;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final v = StatusVisual.certificate(context, status);
    final days = latest == null ? null : TbilisiTime.daysBetween(now, latest!.validUntil);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: v.color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(v.icon, color: v.color, size: 34),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child?.fullName ?? '', style: t.titleMedium),
                const SizedBox(height: 4),
                StatusPill.of(v),
                if (days != null) ...[
                  const SizedBox(height: 4),
                  Text(days >= 0 ? l.certExpiresIn(days) : l.certExpiredAgo(-days), style: t.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateCard extends ConsumerWidget {
  const _CertificateCard({required this.cert, required this.canDelete, required this.now, required this.isCurrent});

  final MedicalCertificate cert;
  final bool canDelete;
  final DateTime now;
  final bool isCurrent;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.deleteCertificate,
      message: l.deleteCertificateConfirm,
      confirmLabel: l.delete,
      destructive: true,
    );
    if (ok && context.mounted) {
      await runGuarded(context, () => ref.read(certificatesRepositoryProvider).delete(cert.id), success: l.certDeleted);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final v = StatusVisual.certificate(context, cert.statusOn(now));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                cert.mimeType == 'application/pdf' ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(l.validUntil(f.fullDate(cert.validUntil)), style: Theme.of(context).textTheme.titleSmall),
              ),
              if (cert.isReplaced)
                StatusPill(label: l.certReplaced, color: AppColors.neutral, dense: true)
              else
                StatusPill.of(v, dense: true),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l.issuedOn(f.fullDate(cert.issuedAt)), style: Theme.of(context).textTheme.bodySmall),
              Text(
                l.certAppliesTo(
                  cert.sportId == null
                      ? l.certAllSports
                      : (ref.watch(sportsByIdProvider)[cert.sportId]?.label(context) ?? cert.sportId!),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (isCurrent)
                StatusPill(key: Key('current-${cert.id}'), label: l.certCurrent, color: AppColors.blue, dense: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OutlinedButton.icon(
                key: Key('open-cert-${cert.id}'),
                onPressed: () => previewCertificate(context, ref, cert),
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: Text(l.certPreview),
              ),
              OutlinedButton.icon(
                key: Key('download-cert-${cert.id}'),
                onPressed: () => downloadCertificate(context, ref, cert),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(l.certDownload),
              ),
              if (canDelete && !cert.isReplaced)
                OutlinedButton.icon(
                  key: Key('replace-cert-${cert.id}'),
                  onPressed: () => context.push('${Routes.uploadCertificate(cert.childId)}?replace=${cert.id}'),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text(l.certReplace),
                ),
              if (canDelete)
                IconButton.outlined(
                  tooltip: l.deleteCertificate,
                  color: AppColors.danger,
                  onPressed: () => _delete(context, ref),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccessLog extends ConsumerWidget {
  const _AccessLog({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final log = ref.watch(certificateAccessLogProvider(childId)).value ?? const [];
    if (log.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l.accessLog),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              for (final e in log.take(10))
                ListTile(
                  dense: true,
                  leading: Icon(switch (e.action) {
                    'open' => Icons.visibility_rounded,
                    'download' => Icons.download_rounded,
                    'denied' => Icons.block_rounded,
                    _ => Icons.delete_outline_rounded,
                  }),
                  title: Text(switch (e.action) {
                    'open' => l.certAccessView(e.userName, f.dateTime(e.at)),
                    'download' => l.certAccessDownload(e.userName, f.dateTime(e.at)),
                    'denied' => l.accessLogDenied(e.userName),
                    _ => l.accessLogDelete(e.userName),
                  }),
                  subtitle: Text(f.dateTime(e.at)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
